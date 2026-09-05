function reportFile = generateScreeningReport(grading, imagePath)
% GENERATESCREENINGREPORT
% Creates a simple text report from the DR screening result.

    % Get image name
    [~, imageName, ext] = fileparts(imagePath);

    % Create report filename
    reportFile = fullfile(pwd, ...
        ['DR_Report_' imageName '.txt']);

    % Open report file
    fid = fopen(reportFile, 'w');

    if fid == -1
        error('Could not create screening report.');
    end

    fprintf(fid, '============================================\n');
    fprintf(fid, '       DIABETIC RETINOPATHY SCREENING\n');
    fprintf(fid, '============================================\n\n');

    fprintf(fid, 'Image: %s%s\n', imageName, ext);
    fprintf(fid, 'Date: %s\n\n', datestr(now));

    % ------------------------------------------
    % QUALITY ASSESSMENT
    % ------------------------------------------

    fprintf(fid, '1. IMAGE QUALITY ASSESSMENT\n');
    fprintf(fid, '--------------------------------------------\n');

    if strcmp(grading.status, 'rejected')

        fprintf(fid, 'Status: REJECTED\n\n');
        fprintf(fid, 'Recapture is required because the image quality\n');
        fprintf(fid, 'is not suitable for reliable DR analysis.\n\n');

        if isfield(grading.qualityReport, 'feedback')
            fprintf(fid, 'Feedback:\n');

            for i = 1:numel(grading.qualityReport.feedback)
                fprintf(fid, '- %s\n', ...
                    grading.qualityReport.feedback{i});
            end
        end

        fprintf(fid, '\n============================================\n');
        fprintf(fid, 'End of Report\n');
        fprintf(fid, '============================================\n');

        fclose(fid);

        fprintf('\nReport created:\n%s\n', reportFile);
        return;
    end

    fprintf(fid, 'Status: PASSED\n\n');

    % ------------------------------------------
    % SEGMENTATION RESULTS
    % ------------------------------------------

    seg = grading.segmentation;

    fprintf(fid, '2. RETINAL ANALYSIS\n');
    fprintf(fid, '--------------------------------------------\n');

    fprintf(fid, 'Vessel Density       : %.3f\n', ...
        seg.vesselDensity);

    fprintf(fid, 'Microaneurysms       : %d\n', ...
        seg.maCount);

    fprintf(fid, 'Hemorrhages          : %d\n', ...
        seg.hemCount);

    fprintf(fid, 'Exudates             : %d\n', ...
        seg.exuCount);

    if isfield(seg, 'discRadius')
        fprintf(fid, 'Optic Disc Radius    : %.1f pixels\n', ...
            seg.discRadius);
    end

    fprintf(fid, '\n');

    % ------------------------------------------
    % GRADING RESULT
    % ------------------------------------------

    result = grading.gradeResult;

    fprintf(fid, '3. DR GRADING RESULT\n');
    fprintf(fid, '--------------------------------------------\n');

    fprintf(fid, 'Grade                 : %d\n', ...
        result.grade);

    fprintf(fid, 'Severity              : %s\n', ...
        result.label);

    fprintf(fid, '\nWhy this grade was given:\n');

    for i = 1:numel(result.explanation)
        fprintf(fid, '- %s\n', ...
            result.explanation{i});
    end

    % ------------------------------------------
    % RECOMMENDATION
    % ------------------------------------------

    fprintf(fid, '\n4. RECOMMENDATION\n');
    fprintf(fid, '--------------------------------------------\n');

    switch result.grade

        case 0
            fprintf(fid, ...
                'No significant diabetic retinopathy detected.\n');
            fprintf(fid, ...
                'Continue routine diabetic eye screening.\n');

        case 1
            fprintf(fid, ...
                'Mild diabetic retinopathy indicators detected.\n');
            fprintf(fid, ...
                'Clinical follow-up and regular eye screening are recommended.\n');

        case 2
            fprintf(fid, ...
                'Moderate diabetic retinopathy indicators detected.\n');
            fprintf(fid, ...
                'Referral to an ophthalmologist is recommended.\n');

        case 3
            fprintf(fid, ...
                'Severe diabetic retinopathy indicators detected.\n');
            fprintf(fid, ...
                'Prompt ophthalmic evaluation is recommended.\n');

        otherwise
            fprintf(fid, ...
                'Clinical evaluation is recommended.\n');
    end

    fprintf(fid, '\n');
    fprintf(fid, 'NOTE: This is a prototype screening system and\n');
    fprintf(fid, 'is not intended to replace clinical diagnosis.\n');

    fprintf(fid, '\n============================================\n');
    fprintf(fid, 'End of Report\n');
    fprintf(fid, '============================================\n');

    fclose(fid);

    fprintf('\n============================================\n');
    fprintf('Screening report created successfully!\n');
    fprintf('File: %s\n', reportFile);
    fprintf('============================================\n');

end