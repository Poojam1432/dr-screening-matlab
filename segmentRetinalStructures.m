function seg = segmentRetinalStructures(enhanced, greenCh, fovMask)
% SEGMENTRETINALSTRUCTURES  Extracts clinically relevant structures:
%   - Optic disc (localization)
%   - Vessel tree (segmentation)
%   - Microaneurysms (small dark round dots)
%   - Exudates (bright yellow-white deposits)
%   - Hemorrhages (larger dark irregular blots)
%   - Neovascularization proxy (abnormal vessel density near/around disc)
%
% All steps are classical image processing (morphology, top-hat filtering,
% region props) so every detection can be visualized and explained -
% no opaque model in the loop.

    if nargin < 3 || isempty(fovMask)
        fovMask = true(size(greenCh));
    end

    fovMask = imerode(fovMask, strel('disk', 3)); % avoid rim artifacts


    %% ---- Optic disc localization ----
    % Disc is the largest, brightest, most compact bright region.

    discCandidate = greenCh;
    discCandidate(~fovMask) = 0;

    thresh = prctile(discCandidate(fovMask), 99);

    discMask = discCandidate >= thresh;
    discMask = imclose(discMask, strel('disk', 8));
    discMask = bwareaopen(discMask, 50);

    discStats = regionprops(discMask, ...
        'Area', 'Centroid', 'EquivDiameter');

    if ~isempty(discStats)

        [~, idx] = max([discStats.Area]);

        discCenter = discStats(idx).Centroid;
        discRadius = discStats(idx).EquivDiameter / 2;

    else

        discCenter = [NaN NaN];
        discRadius = NaN;

    end


    % Mask used to EXCLUDE the disc from lesion detection
    % because the disc is bright and could otherwise become
    % a false "exudate".

    [xx, yy] = meshgrid(1:size(greenCh,2), ...
                        1:size(greenCh,1));

    if ~any(isnan(discCenter))

        discExclusion = ...
            ((xx-discCenter(1)).^2 + ...
             (yy-discCenter(2)).^2) <= ...
             (discRadius*1.6)^2;

    else

        discExclusion = false(size(greenCh));

    end


    %% ---- Vessel segmentation ----
    % Morphological top-hat filtering.
    % Vessels are dark, so image complement makes them bright.

    se = strel('disk', 8);

    vesselTopHat = ...
        imtophat(imcomplement(greenCh), se);

    vesselTopHat = ...
        adapthisteq(vesselTopHat, 'ClipLimit', 0.01);

    vesselMask = ...
        vesselTopHat > graythresh(vesselTopHat) * 1.0;

    vesselMask = bwareaopen(vesselMask, 30);

    vesselMask = vesselMask & fovMask;

    vesselDensity = ...
        nnz(vesselMask) / nnz(fovMask);


    %% ---- Microaneurysms ----
    % Tiny dark round dots, approximately 3-15 px diameter.

    seSmall = strel('disk', 3);

    maTopHat = ...
        imtophat(imcomplement(greenCh), seSmall);

    maMask = ...
        maTopHat > ...
        (mean(maTopHat(fovMask)) + ...
         3*std(maTopHat(fovMask)));

    maMask = ...
        maMask & fovMask & ...
        ~discExclusion & ...
        ~imdilate(vesselMask, strel('disk',2));

    maMask = bwareaopen(maMask, 2);

    maStats = regionprops(maMask, ...
        'Area', 'Centroid', 'Eccentricity');

    maStats = ...
        maStats([maStats.Area] <= 40 & ...
                [maStats.Eccentricity] < 0.9);


    %% ---- Hemorrhages ----
    % Larger dark irregular blots.
    %
    % IMPORTANT:
    % Use a separate larger-scale detector instead of maTopHat.
    % This reduces false hemorrhage detections caused by the
    % microaneurysm detector.

    seHem = strel('disk', 6);

    hemTopHat = ...
        imtophat(imcomplement(greenCh), seHem);

    hemThreshold = ...
        mean(hemTopHat(fovMask)) + ...
        2.5*std(hemTopHat(fovMask));

    hemMask = hemTopHat > hemThreshold;

    hemMask = ...
        hemMask & fovMask & ~discExclusion;

    % Remove very small objects.
    hemMask = bwareaopen(hemMask, 40);

    % Smooth fragmented regions.
    hemMask = imclose(hemMask, strel('disk', 2));

    hemStats = regionprops(hemMask, ...
        'Area', 'Centroid', 'Eccentricity');

    % Keep reasonably sized dark regions.
    hemStats = ...
        hemStats([hemStats.Area] > 40 & ...
                 [hemStats.Area] < 3000);


    %% ---- Exudates ----
    % Bright yellow-white deposits.

    seMed = strel('disk', 10);

    exuTopHat = ...
        imtophat(greenCh, seMed);

    exuMask = ...
        exuTopHat > ...
        (mean(exuTopHat(fovMask)) + ...
         2.5*std(exuTopHat(fovMask)));

    exuMask = ...
        exuMask & fovMask & ~discExclusion;

    exuMask = bwareaopen(exuMask, 10);

    exuStats = regionprops(exuMask, ...
        'Area', 'Centroid');


    %% ---- Neovascularization proxy ----
    % Heuristic:
    % Abnormal fine vessel density in a ring just outside the disc,
    % compared to global vessel density.
    %
    % This is only a proxy signal and should be reported as such.

    if ~any(isnan(discCenter))

        ringMask = ...
            ((xx-discCenter(1)).^2 + ...
             (yy-discCenter(2)).^2) <= ...
             (discRadius*3)^2 & ...
            ((xx-discCenter(1)).^2 + ...
             (yy-discCenter(2)).^2) > ...
             (discRadius*1.6)^2;

        ringMask = ringMask & fovMask;

        ringVesselDensity = ...
            nnz(vesselMask & ringMask) / ...
            max(nnz(ringMask),1);

        nvFlag = ...
            ringVesselDensity > ...
            (vesselDensity * 1.8) && ...
            ringVesselDensity > 0.15;

    else

        ringVesselDensity = NaN;
        nvFlag = false;

    end


    %% ---- Divide into 4 quadrants ----
    % Used for the severe-NPDR rule.

    [h, w] = size(greenCh);

    cx = w/2;
    cy = h/2;

    quadOf = @(pt) ...
        (pt(1)>=cx)*1 + ...
        (pt(2)>=cy)*2 + 1;

    hemQuadCounts = zeros(1,4);

    for i = 1:numel(hemStats)

        q = quadOf(hemStats(i).Centroid);

        hemQuadCounts(q) = ...
            hemQuadCounts(q) + 1;

    end

    quadrantsWithHeavyHem = ...
        sum(hemQuadCounts >= 20);


    %% ---- Output structure ----

    seg = struct( ...
        'discCenter', discCenter, ...
        'discRadius', discRadius, ...
        'discMask', discMask, ...
        'vesselMask', vesselMask, ...
        'vesselDensity', vesselDensity, ...
        'maMask', maMask, ...
        'maCount', numel(maStats), ...
        'maStats', maStats, ...
        'hemMask', hemMask, ...
        'hemCount', numel(hemStats), ...
        'hemStats', hemStats, ...
        'hemQuadCounts', hemQuadCounts, ...
        'quadrantsWithHeavyHem', quadrantsWithHeavyHem, ...
        'exuMask', exuMask, ...
        'exuCount', numel(exuStats), ...
        'exuStats', exuStats, ...
        'ringVesselDensity', ringVesselDensity, ...
        'nvFlag', nvFlag);

end