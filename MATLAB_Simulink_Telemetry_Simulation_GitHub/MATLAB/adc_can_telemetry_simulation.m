%% ADC-to-CAN Telemetry Simulation
% STM32 CAN Telemetry Node Rev A
%
% Purpose:
% Simulate the sensor-processing path for the STM32 CAN Telemetry Node.
% The script models four analog inputs, converts ADC counts to voltages,
% applies basic filtering, and packs the values into the planned CAN payload.
%
% Project status:
% This is a MATLAB simulation and documentation aid.
% It does not claim physical PCB, ADC, or CAN bus validation.

clear;
clc;
close all;

%% Project constants

CAN_ID = hex2dec('100');
CAN_DLC = 8;

ADC_BITS = 12;
ADC_MAX_COUNT = 2^ADC_BITS - 1;
VREF = 3.3;

% Rev A analog front-end divider assumption:
% sensor input -> 10 kOhm top resistor -> ADC node -> 20 kOhm bottom resistor -> GND
R_TOP = 10e3;
R_BOTTOM = 20e3;
DIVIDER_RATIO = R_BOTTOM / (R_TOP + R_BOTTOM);

% Simulation timing
fs = 100;
dt = 1 / fs;
t_end = 10;
t = 0:dt:t_end;

% Moving average filter length
filter_window = 10;

%% Simulate four sensor-side analog input voltages

rng(7); % repeatable noise

ain1_sensor_v = 2.50 + 0.60*sin(2*pi*0.4*t) + 0.05*randn(size(t));
ain2_sensor_v = 1.80 + 0.40*sin(2*pi*0.7*t + 0.8) + 0.04*randn(size(t));
ain3_sensor_v = 3.20 + 0.50*sin(2*pi*0.2*t + 1.5) + 0.03*randn(size(t));
ain4_sensor_v = 0.80 + 0.25*sin(2*pi*1.0*t + 0.3) + 0.03*randn(size(t));

sensor_v = [ain1_sensor_v(:), ain2_sensor_v(:), ain3_sensor_v(:), ain4_sensor_v(:)];

% Clamp sensor-side voltage to a 0-5 V sensor range.
sensor_v = min(max(sensor_v, 0), 5.0);

%% Model resistor divider and ADC conversion

adc_pin_v = sensor_v * DIVIDER_RATIO;

% Clamp ADC pin voltage to the STM32 ADC input range.
adc_pin_v = min(max(adc_pin_v, 0), VREF);

adc_counts = round((adc_pin_v / VREF) * ADC_MAX_COUNT);
adc_counts = uint16(min(max(adc_counts, 0), ADC_MAX_COUNT));

%% Convert ADC counts back to voltages

adc_voltage_est = double(adc_counts) / ADC_MAX_COUNT * VREF;
sensor_voltage_est = adc_voltage_est / DIVIDER_RATIO;

%% Apply basic moving-average filtering

filtered_sensor_voltage = movmean(sensor_voltage_est, filter_window, 1);

%% Pack last sample into the planned CAN payload

last_adc_values = adc_counts(end, :);
can_payload = pack_adc_values_little_endian(last_adc_values);

fprintf('STM32 CAN Telemetry Node Rev A - MATLAB ADC/CAN Simulation\n');
fprintf('CAN ID: 0x%03X\n', CAN_ID);
fprintf('DLC: %d bytes\n\n', CAN_DLC);

fprintf('Last raw ADC values:\n');
fprintf('AIN1_RAW = %d\n', last_adc_values(1));
fprintf('AIN2_RAW = %d\n', last_adc_values(2));
fprintf('AIN3_RAW = %d\n', last_adc_values(3));
fprintf('AIN4_RAW = %d\n\n', last_adc_values(4));

fprintf('Packed CAN payload bytes, little-endian:\n');
fprintf('Byte 0-1: AIN1_RAW -> 0x%02X 0x%02X\n', can_payload(1), can_payload(2));
fprintf('Byte 2-3: AIN2_RAW -> 0x%02X 0x%02X\n', can_payload(3), can_payload(4));
fprintf('Byte 4-5: AIN3_RAW -> 0x%02X 0x%02X\n', can_payload(5), can_payload(6));
fprintf('Byte 6-7: AIN4_RAW -> 0x%02X 0x%02X\n', can_payload(7), can_payload(8));

%% Create output folder

script_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(script_dir);
plot_dir = fullfile(project_dir, 'plots');

if ~exist(plot_dir, 'dir')
    mkdir(plot_dir);
end

%% Plot raw ADC counts

figure;
plot(t, double(adc_counts(:,1)), 'LineWidth', 1.2);
hold on;
plot(t, double(adc_counts(:,2)), 'LineWidth', 1.2);
plot(t, double(adc_counts(:,3)), 'LineWidth', 1.2);
plot(t, double(adc_counts(:,4)), 'LineWidth', 1.2);
grid on;
xlabel('Time (s)');
ylabel('ADC Count');
title('Simulated Raw STM32 ADC Counts');
legend('AIN1 RAW', 'AIN2 RAW', 'AIN3 RAW', 'AIN4 RAW', 'Location', 'best');
saveas(gcf, fullfile(plot_dir, 'raw_adc_counts.png'));

%% Plot estimated sensor voltages before filtering

figure;
plot(t, sensor_voltage_est(:,1), 'LineWidth', 1.2);
hold on;
plot(t, sensor_voltage_est(:,2), 'LineWidth', 1.2);
plot(t, sensor_voltage_est(:,3), 'LineWidth', 1.2);
plot(t, sensor_voltage_est(:,4), 'LineWidth', 1.2);
grid on;
xlabel('Time (s)');
ylabel('Estimated Sensor Voltage (V)');
title('Estimated Sensor-Side Voltages from ADC Counts');
legend('AIN1', 'AIN2', 'AIN3', 'AIN4', 'Location', 'best');
saveas(gcf, fullfile(plot_dir, 'estimated_sensor_voltages.png'));

%% Plot filtered sensor voltages

figure;
plot(t, filtered_sensor_voltage(:,1), 'LineWidth', 1.5);
hold on;
plot(t, filtered_sensor_voltage(:,2), 'LineWidth', 1.5);
plot(t, filtered_sensor_voltage(:,3), 'LineWidth', 1.5);
plot(t, filtered_sensor_voltage(:,4), 'LineWidth', 1.5);
grid on;
xlabel('Time (s)');
ylabel('Filtered Sensor Voltage (V)');
title('Moving-Average Filtered Sensor Voltages');
legend('AIN1 filtered', 'AIN2 filtered', 'AIN3 filtered', 'AIN4 filtered', 'Location', 'best');
saveas(gcf, fullfile(plot_dir, 'filtered_sensor_voltages.png'));

%% Plot example CAN payload bytes

figure;
bar(0:7, double(can_payload));
grid on;
xlabel('CAN Payload Byte Index');
ylabel('Byte Value');
title(sprintf('Example CAN Payload for ID 0x%03X', CAN_ID));
xticks(0:7);
saveas(gcf, fullfile(plot_dir, 'example_can_payload_bytes.png'));

%% Save a CSV output for review

output_table = table( ...
    t(:), ...
    double(adc_counts(:,1)), double(adc_counts(:,2)), double(adc_counts(:,3)), double(adc_counts(:,4)), ...
    sensor_voltage_est(:,1), sensor_voltage_est(:,2), sensor_voltage_est(:,3), sensor_voltage_est(:,4), ...
    filtered_sensor_voltage(:,1), filtered_sensor_voltage(:,2), filtered_sensor_voltage(:,3), filtered_sensor_voltage(:,4), ...
    'VariableNames', { ...
    'time_s', ...
    'AIN1_RAW', 'AIN2_RAW', 'AIN3_RAW', 'AIN4_RAW', ...
    'AIN1_voltage_est', 'AIN2_voltage_est', 'AIN3_voltage_est', 'AIN4_voltage_est', ...
    'AIN1_filtered_v', 'AIN2_filtered_v', 'AIN3_filtered_v', 'AIN4_filtered_v'});

writetable(output_table, fullfile(plot_dir, 'telemetry_simulation_output.csv'));

fprintf('\nGenerated plots and CSV output in: %s\n', plot_dir);

%% Local helper function

function payload = pack_adc_values_little_endian(adc_values)
%PACK_ADC_VALUES_LITTLE_ENDIAN Pack four uint16 ADC values into 8 CAN bytes.
%
% Payload:
% Byte 0-1: AIN1_RAW
% Byte 2-3: AIN2_RAW
% Byte 4-5: AIN3_RAW
% Byte 6-7: AIN4_RAW

    payload = zeros(1, 8, 'uint8');

    for k = 1:4
        value = uint16(adc_values(k));
        low_byte = bitand(value, uint16(255));
        high_byte = bitshift(value, -8);

        payload(2*k - 1) = uint8(low_byte);
        payload(2*k) = uint8(high_byte);
    end
end
