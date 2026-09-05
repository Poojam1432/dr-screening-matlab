# SIH26038 — Explainable DR Screening Pipeline (MATLAB)

## Run it (2 minutes)
```matlab
cd dr_screening
grading = mainPipeline('sample_fundus.jpg');   % any .jpg/.png fundus photo
```
Requires: Image Processing Toolbox, Computer Vision Toolbox (for `insertShape`).
Works with any public fundus dataset image (e.g. APTOS 2019, IDRiD, Messidor — all free to download for a demo/test set).

If you don't have a fundus image handy, search "fundus photo diabetic retinopathy sample" —
any clear retinal photo works to prove the pipeline runs end-to-end.

## What each file does
| File | Problem-statement ask it covers |
|---|---|
| `assessImageQuality.m` | (1) Quality assessment — blur (Laplacian variance), illumination, field-of-view coverage. Rejects ungradeable images with a specific recapture reason. |
| `enhanceImage.m` | (1) Adaptive enhancement — CLAHE, illumination normalization, denoising for borderline images. |
| `segmentRetinalStructures.m` | (2) Structure segmentation — optic disc localization, vessel segmentation, microaneurysm/exudate/hemorrhage detection, neovascularization proxy. |
| `gradeDRSeverity.m` | (3) Severity grading — ICDR 0–4 scale via an explicit rule set, with a plain-text reason for every grade. |
| `mainPipeline.m` | Orchestrates all of the above + produces the annotated 6-panel demo figure. |

## Why rule-based instead of a deep-learning classifier
The problem statement's title is literally "**Explainable** AI." A CNN grading DR end-to-end is
a black box you can't defend under evaluator questioning ("why did it say Grade 2?"). This pipeline
counts and localizes actual lesions (microaneurysms, hemorrhages, exudates) and grades from those
counts using the same 4-2-1-style logic ophthalmologists use — so every grade has a traceable,
inspectable reason, which is exactly what "explainable" is asking for, and it's also far faster to
get working and defensible in the time you have left today.

## Demo script (matches "Overall Verdict → walkthrough order: problem, solution, architecture, impact")
1. **Problem** (30 sec): 77M diabetic adults in India, DR causes preventable blindness, ~1 ophthalmologist per 100k rural population — screening bottleneck.
2. **Solution** (30 sec): Show `mainPipeline` running on 2 images — one that gets **rejected** (blurry/dark) with a specific recapture reason, one that gets **graded**. This directly answers the evaluator question "what happens when input data is poor" before they ask it.
3. **Architecture** (1 min): Walk the 6-panel figure left to right — raw → enhanced → segmentation input → vessels → lesion overlay → grade + explanation text.
4. **Impact** (30 sec): Every grade is auditable — point at the lesion overlay and the matching count in the explanation panel. No black box.

## Anticipated evaluator questions — answers to have ready
- **"Where's your training/test data from?"** → Say explicitly whether you used a public dataset (APTOS/IDRiD/Messidor) or your own demo set. Don't imply real deployment data if you didn't use it.
- **"Why this level of tech, not overkill?"** → Classical CV keeps it explainable and runs in real time on modest hardware — appropriate for rural/low-connectivity deployment, unlike a heavy DL model needing GPU inference.
- **"What happens when hardware/connectivity fails?"** → Pipeline runs fully offline/on-device once the image is captured; no network dependency in this repo. Say so.
- **"How does this hold up on real production-scale data?"** → Be honest: thresholds (`BLUR_THRESH`, lesion size cutoffs) are tuned on your demo set and would need calibration against a larger labeled dataset before clinical use — this is a screening triage aid, not a diagnostic replacement.

## If you have extra hours
- Swap the fixed thresholds in `assessImageQuality.m` / `segmentRetinalStructures.m` for values calibrated against a labeled batch of 20-30 sample images (compute mean/std of blur & lesion-topHat responses across known-good vs known-bad images).
- Wrap `mainPipeline` in a simple MATLAB App Designer UI: file picker → run button → shows the same 6-panel figure. Judges respond well to a clickable interface even if it's thin.
