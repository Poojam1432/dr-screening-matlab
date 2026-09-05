function visualizeSegmentation(grading, imagePath)
%VISUALIZESEGMENTATION Show every segmentation mask plus a combined color overlay
%   visualizeSegmentation(grading, imagePath)
%
%   Example:
%       grading = mainPipeline('test1.jpg');
%       visualizeSegmentation(grading, 'test1.jpg');

img = imread(imagePath);
seg = grading.segmentation;

% ---- Figure 1: individual masks side by side ----
figure('Name', 'Full Segmentation View', 'NumberTitle', 'off');

subplot(2,3,1); imshow(img); title('Original');

if isfield(seg, 'discMask')
    subplot(2,3,2);
    imshow(seg.discMask);
    title(sprintf('Optic Disc (r=%.1fpx)', seg.discRadius));
end

if isfield(seg, 'vesselMask')
    subplot(2,3,3);
    imshow(seg.vesselMask);
    title(sprintf('Vessels (density %.3f)', seg.vesselDensity));
end

if isfield(seg, 'maMask')
    subplot(2,3,4);
    imshow(seg.maMask);
    title(sprintf('Microaneurysms (%d)', seg.maCount));
end

if isfield(seg, 'hemMask')
    subplot(2,3,5);
    imshow(seg.hemMask);
    title(sprintf('Hemorrhages (%d)', seg.hemCount));
end

if isfield(seg, 'exuMask')
    subplot(2,3,6);
    imshow(seg.exuMask);
    title(sprintf('Exudates (%d)', seg.exuCount));
end

% ---- Figure 2: combined color overlay on the original image ----
overlay = im2double(img);
if size(overlay, 3) == 1
    overlay = repmat(overlay, [1 1 3]);
end

if isfield(seg, 'vesselMask')
    overlay = applyColor(overlay, seg.vesselMask, [0 1 0]);   % green
end
if isfield(seg, 'hemMask')
    overlay = applyColor(overlay, seg.hemMask, [1 0 0]);      % red
end
if isfield(seg, 'exuMask')
    overlay = applyColor(overlay, seg.exuMask, [1 1 0]);      % yellow
end
if isfield(seg, 'maMask')
    overlay = applyColor(overlay, seg.maMask, [0 1 1]);       % cyan
end

figure('Name', 'Combined Overlay', 'NumberTitle', 'off');
imshow(overlay);
title('Vessels=green  Hemorrhages=red  Exudates=yellow  Microaneurysms=cyan');

end

function out = applyColor(base, mask, color)
%APPLYCOLOR Paint a binary mask onto an RGB image in the given color
mask = logical(mask);
out = base;
for c = 1:3
    channel = out(:,:,c);
    channel(mask) = color(c);
    out(:,:,c) = channel;
end
end