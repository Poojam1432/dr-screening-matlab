clc;
clear;
close all;

imageFile = 'test1.jpg';

fprintf('\n========================================\n');
fprintf(' DIABETIC RETINOPATHY SCREENING SYSTEM\n');
fprintf('========================================\n');

fprintf('\nTesting image: %s\n', imageFile);

mainPipeline(imageFile);

fprintf('\n========================================\n');
fprintf('           PIPELINE COMPLETED\n');
fprintf('========================================\n');