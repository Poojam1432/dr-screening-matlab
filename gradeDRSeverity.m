function result = gradeDRSeverity(seg)
% GRADEDRSEVERITY  Maps segmented lesion evidence to the International
% Clinical DR Severity Scale (0-4) using an explicit, auditable rule set
% (a simplified 4-2-1 style rule). Every grade comes with the exact
% evidence that produced it - this IS the "explainable AI" layer:
% no black box, every decision traceable to a counted, visualized lesion.

    ma  = seg.maCount;
    hem = seg.hemCount;
    exu = seg.exuCount;
    heavyHemQuads = seg.quadrantsWithHeavyHem;
    nv  = seg.nvFlag;

    reasons = {};

    if nv
        grade = 4;
        label = 'Proliferative DR (PDR)';
        reasons{end+1} = sprintf('Abnormal vessel density near optic disc (%.2f vs global %.2f) suggests neovascularization.', ...
            seg.ringVesselDensity, seg.vesselDensity);
    elseif heavyHemQuads >= 2 || ma > 40
        grade = 3;
        label = 'Severe NPDR';
        reasons{end+1} = sprintf('%d quadrant(s) show >=20 hemorrhages, or microaneurysm count (%d) is very high.', heavyHemQuads, ma);
    elseif (ma > 5 || hem > 0 || exu > 0) && ~(ma <= 5 && hem == 0 && exu == 0)
        if ma > 20 || hem > 5 || exu > 10
            grade = 2;
            label = 'Moderate NPDR';
            reasons{end+1} = sprintf('Microaneurysms: %d, hemorrhages: %d, exudates: %d - more than mild, below severe thresholds.', ma, hem, exu);
        else
            grade = 1;
            label = 'Mild NPDR';
            reasons{end+1} = sprintf('Microaneurysms present (%d), hemorrhages: %d, exudates: %d - earliest visible signs only.', ma, hem, exu);
        end
    else
        grade = 0;
        label = 'No DR';
        reasons{end+1} = 'No microaneurysms, hemorrhages, or exudates detected above threshold.';
    end

    reasons{end+1} = sprintf('Vessel density in analyzed field: %.3f.', seg.vesselDensity);
    if ~isnan(seg.discRadius)
        reasons{end+1} = sprintf('Optic disc localized (radius ~%.0f px) and excluded from lesion counts.', seg.discRadius);
    else
        reasons{end+1} = 'Optic disc could not be confidently localized - grading confidence reduced.';
    end

    result = struct('grade', grade, 'label', label, 'explanation', {reasons}, ...
                     'maCount', ma, 'hemCount', hem, 'exuCount', exu, 'nvFlag', nv);
end
