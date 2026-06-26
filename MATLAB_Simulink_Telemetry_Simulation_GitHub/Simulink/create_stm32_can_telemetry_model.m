%% Create Simulink Model for STM32 CAN Telemetry Signal Path
% STM32 CAN Telemetry Node Rev A
%
% This script programmatically creates a Simulink model that supports the
% MATLAB ADC/CAN telemetry simulation.
%
% Model purpose:
% - Simulate four analog telemetry input signals
% - Apply resistor-divider scaling
% - Convert scaled voltages to approximate 12-bit ADC counts
% - Apply a first-order discrete low-pass filter to the ADC count estimates
% - Visualize raw and filtered telemetry channels
%
% This is a simulation model only. It does not claim physical hardware validation.

clear;
clc;

modelName = 'stm32_can_telemetry_filter_model';

if bdIsLoaded(modelName)
    close_system(modelName, 0);
end

new_system(modelName);
open_system(modelName);

%% Constants

VREF = 3.3;
ADC_MAX_COUNT = 4095;
DIVIDER_RATIO = 20e3 / (10e3 + 20e3); % Rev A 10k/20k divider
ADC_GAIN = ADC_MAX_COUNT / VREF;

%% Model settings

set_param(modelName, 'StopTime', '10');
set_param(modelName, 'Solver', 'FixedStepDiscrete');
set_param(modelName, 'FixedStep', '0.01');

%% Layout

x0 = 80;
y0 = 70;
rowGap = 90;

for ch = 1:4
    y = y0 + (ch-1)*rowGap;

    sourceName  = sprintf('AIN%d Sensor Input', ch);
    dividerName = sprintf('AIN%d Divider Scaling', ch);
    adcName     = sprintf('AIN%d ADC Count Conversion', ch);
    filterName  = sprintf('AIN%d Low-Pass Filtered ADC Estimate', ch);

    srcPath  = [modelName '/' sourceName];
    divPath  = [modelName '/' dividerName];
    adcPath  = [modelName '/' adcName];
    filtPath = [modelName '/' filterName];

    add_block('simulink/Sources/Sine Wave', srcPath, ...
        'Position', [x0 y x0+100 y+35]);

    set_param(srcPath, ...
        'Amplitude', num2str(0.35 + 0.05*ch), ...
        'Bias', num2str(1.0 + 0.45*ch), ...
        'Frequency', num2str(0.4 + 0.15*ch), ...
        'SampleTime', '0.01');

    add_block('simulink/Math Operations/Gain', divPath, ...
        'Gain', num2str(DIVIDER_RATIO), ...
        'Position', [x0+160 y x0+275 y+35]);

    add_block('simulink/Math Operations/Gain', adcPath, ...
        'Gain', num2str(ADC_GAIN), ...
        'Position', [x0+335 y x0+470 y+35]);

    % First-order discrete low-pass filter:
    %
    % Difference equation:
    % y[n] = 0.9*y[n-1] + 0.1*x[n]
    %
    % Transfer function:
    % H(z) = 0.1 / (1 - 0.9z^-1)
    add_block('simulink/Discrete/Discrete Transfer Fcn', filtPath, ...
        'Numerator', '[0.1]', ...
        'Denominator', '[1 -0.9]', ...
        'SampleTime', '0.01', ...
        'Position', [x0+540 y x0+730 y+45]);

    add_line(modelName, [sourceName '/1'], [dividerName '/1']);
    add_line(modelName, [dividerName '/1'], [adcName '/1']);
    add_line(modelName, [adcName '/1'], [filterName '/1']);
end

%% Mux and Scope blocks

add_block('simulink/Signal Routing/Mux', [modelName '/Raw ADC Mux'], ...
    'Inputs', '4', ...
    'Position', [900 95 940 355]);

add_block('simulink/Signal Routing/Mux', [modelName '/Filtered ADC Mux'], ...
    'Inputs', '4', ...
    'Position', [900 430 940 690]);

add_block('simulink/Sinks/Scope', [modelName '/Raw ADC Counts Scope'], ...
    'Position', [1020 150 1180 250]);

add_block('simulink/Sinks/Scope', [modelName '/Filtered ADC Counts Scope'], ...
    'Position', [1020 500 1180 600]);

for ch = 1:4
    adcName = sprintf('AIN%d ADC Count Conversion', ch);
    filterName = sprintf('AIN%d Low-Pass Filtered ADC Estimate', ch);

    add_line(modelName, [adcName '/1'], ['Raw ADC Mux/' num2str(ch)], 'autorouting', 'on');
    add_line(modelName, [filterName '/1'], ['Filtered ADC Mux/' num2str(ch)], 'autorouting', 'on');
end

add_line(modelName, 'Raw ADC Mux/1', 'Raw ADC Counts Scope/1');
add_line(modelName, 'Filtered ADC Mux/1', 'Filtered ADC Counts Scope/1');

%% Add note block

noteText = sprintf([ ...
    'STM32 CAN Telemetry Node Rev A\n', ...
    'Simulink model for planned telemetry signal path\n', ...
    'AIN1-AIN4 -> divider scaling -> ADC count estimate -> discrete low-pass filter\n', ...
    'MATLAB script also performs moving-average filtering and CAN payload packing.']);

Simulink.Annotation([modelName '/Model Notes'], noteText);

%% Save model

save_system(modelName, [modelName '.slx']);

fprintf('Created Simulink model: %s.slx\n', modelName);
fprintf('Open the model, run the simulation, and save screenshots to ../images/.\n');
