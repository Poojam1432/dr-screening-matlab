function report = assessImageQuality(img)
% ASSESSIMAGEQUALITY  Grades a fundus image for gradeability.
% Checks: focus/blur, illumination, field-of-view coverage.
%
% report fields:
%   isAdequate   (logical)
%   blurScore    (double, higher = sharper)
%   isBlurry     (logical)
%   meanIllum    (0-255)
%   isPoorIllum  (logical)
%   fovRatio     (fraction of frame that is usable retina)
%   isPoorFOV    (logical)
%   feedback     (cellstr) - human readable reasons, used for recapture msg

    if size(img,3) == 3
        gray = rgb2gray(img);
    else
        gray = img;
    end
    gray = im2double(gray);

    feedback = {};

    % ---- 1. Focus / blur : variance of Laplacian ----
    lap = fspecial('laplacian', 0.2);
    lapResp = imfilter(gray, lap, 'replicate');
    blurScore = var(lapResp(:)) * 1e4;   % scaled for readable numbers
    BLUR_THRESH = 1.5;                   % tune against sample set
    isBlurry = blurScore < BLUR_THRESH;
    if isBlurry
        feedback{end+1} = sprintf('Image too blurry (sharpness score %.2f, need > %.2f).', blurScore, BLUR_THRESH);
    end

    % ---- 2. Illumination : mean brightness within FOV ----
    fovMask = gray > 0.06;               % crude retina-vs-black-border mask
    fovMask = imopen(fovMask, strel('disk', 5));
    if nnz(fovMask) == 0
        fovMask = true(size(gray));
    end
    meanIllum = mean(gray(fovMask)) * 255;
    isPoorIllum = meanIllum < 40 || meanIllum > 220;
    if isPoorIllum
        feedback{end+1} = sprintf('Poor illumination (mean intensity %.0f/255, need 40-220).', meanIllum);
    end

    % ---- 3. Field of view coverage ----
    fovRatio = nnz(fovMask) / numel(fovMask);
    isPoorFOV = fovRatio < 0.35;
    if isPoorFOV
        feedback{end+1} = sprintf('Insufficient field of view (%.0f%% of frame usable, need > 35%%).', fovRatio*100);
    end

    isAdequate = ~isBlurry && ~isPoorIllum && ~isPoorFOV;
    if isAdequate
        feedback{end+1} = 'Image passed all quality checks.';
    end

    report = struct('isAdequate', isAdequate, ...
                     'blurScore', blurScore, 'isBlurry', isBlurry, ...
                     'meanIllum', meanIllum, 'isPoorIllum', isPoorIllum, ...
                     'fovRatio', fovRatio, 'isPoorFOV', isPoorFOV, ...
                     'fovMask', fovMask, ...
                     'feedback', {feedback});
end
