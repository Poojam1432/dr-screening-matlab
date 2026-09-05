function [enhanced, greenCh] = enhanceImage(img, fovMask)
% ENHANCEIMAGE  Adaptive enhancement pipeline for fundus images.
% - Illumination normalization (large-kernel background subtraction)
% - CLAHE on luminance channel
% - Denoising (edge-preserving)
% Also returns the contrast-enhanced green channel, which carries the
% most vessel/lesion contrast in fundus photography.

    img = im2double(img);

    % ---- Illumination normalization ----
    bg = imgaussfilt(img, 30);
    normImg = img - bg + 0.5;
    normImg = min(max(normImg, 0), 1);

    % ---- CLAHE on L channel (Lab space) preserves color for display ----
    lab = rgb2lab(normImg);
    L = lab(:,:,1) / 100;
    L_eq = adapthisteq(L, 'ClipLimit', 0.01, 'NumTiles', [8 8]);
    lab(:,:,1) = L_eq * 100;
    enhanced = lab2rgb(lab);
    enhanced = min(max(enhanced, 0), 1);

    % ---- Denoise (edge preserving) ----
    enhanced = imbilatfilt(enhanced, 0.02, 3);

    if nargin > 1 && ~isempty(fovMask)
        for c = 1:3
            ch = enhanced(:,:,c);
            ch(~fovMask) = 0;
            enhanced(:,:,c) = ch;
        end
    end

    % ---- Green channel, CLAHE-boosted, for segmentation stages ----
    green = enhanced(:,:,2);
    greenCh = adapthisteq(green, 'ClipLimit', 0.015, 'NumTiles', [8 8]);
end
