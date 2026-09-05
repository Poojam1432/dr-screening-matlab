function grading = mainPipeline(imagePath)
% MAINPIPELINE  End-to-end DR screening demo.
%   grading = mainPipeline('path/to/fundus_image.jpg')
%
% Runs: quality gate -> enhancement -> structure/lesion segmentation ->
% explainable severity grading -> annotated visualization + text report.
%
% If the image fails the quality gate, the pipeline stops and returns
% recapture feedback instead of a (meaningless) grade - this is one of
% the "real-world deployment challenges" the problem statement calls out.

    img = imread(imagePath);
    if size(img,3) == 1
        img = repmat(img, 1, 1, 3);
    end

    %% 1. Image Quality Assessment
    qReport = assessImageQuality(img);

    fig = figure('Name', 'DR Screening Pipeline', 'Position', [100 100 1400 800]);

    subplot(2,3,1); imshow(img); title('1. Input Image');

    if ~qReport.isAdequate
        subplot(2,3,2:3);
        axis off;
        msg = ['IMAGE REJECTED - RECAPTURE REQUIRED' newline newline strjoin(qReport.feedback, newline)];
        text(0.02, 0.6, msg, 'FontSize', 12, 'Color', 'r', 'FontWeight', 'bold');
        grading = struct('status', 'rejected', 'qualityReport', qReport);
        fprintf('=== QUALITY GATE: REJECTED ===\n');
        fprintf('%s\n', strjoin(qReport.feedback, '\n'));
        return;
    end

    %% 2. Enhancement (borderline images get adaptive CLAHE/denoise/normalize)
    [enhanced, greenCh] = enhanceImage(img, qReport.fovMask);
    subplot(2,3,2); imshow(enhanced); title('2. Enhanced (CLAHE + norm)');
    subplot(2,3,3); imshow(greenCh); title('3. Green channel (segmentation input)');

    %% 3. Retinal Structure Segmentation
    seg = segmentRetinalStructures(enhanced, greenCh, qReport.fovMask);

    subplot(2,3,4);
    imshow(seg.vesselMask); title(sprintf('4. Vessels (density %.3f)', seg.vesselDensity));

    subplot(2,3,5);
    overlay = enhanced;
    overlay = insertLesionOverlay(overlay, seg);
    imshow(overlay);
    title(sprintf('5. Lesions: MA=%d  Hem=%d  Exu=%d', seg.maCount, seg.hemCount, seg.exuCount));

    %% 4. DR Severity Grading (explainable)
    gradeResult = gradeDRSeverity(seg);

    subplot(2,3,6);
    axis off;
    reportText = [sprintf('GRADE %d: %s', gradeResult.grade, gradeResult.label) newline newline ...
                  'Why:' newline strjoin(strcat({'- '}, gradeResult.explanation), newline)];
    text(0.02, 0.9, reportText, 'FontSize', 10, 'VerticalAlignment', 'top', 'Interpreter', 'none');
    title('6. Explainable Grading Report');

    sgtitle(sprintf('DR Screening Result: Grade %d - %s', gradeResult.grade, gradeResult.label), ...
        'FontSize', 14, 'FontWeight', 'bold');

    fprintf('=== QUALITY GATE: PASSED ===\n');
    fprintf('=== SEGMENTATION SUMMARY ===\n');
    fprintf('Optic disc radius: %.1f px | Vessel density: %.3f\n', seg.discRadius, seg.vesselDensity);
    fprintf('Microaneurysms: %d | Hemorrhages: %d | Exudates: %d\n', seg.maCount, seg.hemCount, seg.exuCount);
    fprintf('=== GRADING RESULT ===\n');
    fprintf('Grade %d: %s\n', gradeResult.grade, gradeResult.label);
    fprintf('%s\n', strjoin(gradeResult.explanation, '\n'));

    grading = struct('status', 'graded', 'qualityReport', qReport, ...
        'segmentation', seg, 'gradeResult', gradeResult);

    % Generate screening report
    generateScreeningReport(grading, imagePath);

end

function overlay = insertLesionOverlay(overlay, seg)
    overlay = insertShape(im2uint8(overlay), 'circle', ...
        [seg.discCenter, seg.discRadius], 'Color', 'cyan', 'LineWidth', 2);
    for i = 1:numel(seg.maStats)
        overlay = insertShape(overlay, 'circle', [seg.maStats(i).Centroid, 4], 'Color', 'yellow', 'LineWidth', 1);
    end
    for i = 1:numel(seg.hemStats)
        overlay = insertShape(overlay, 'circle', [seg.hemStats(i).Centroid, 8], 'Color', 'red', 'LineWidth', 1);
    end
    for i = 1:numel(seg.exuStats)
        overlay = insertShape(overlay, 'circle', [seg.exuStats(i).Centroid, 6], 'Color', 'green', 'LineWidth', 1);
    end
    overlay = im2double(overlay);
end
