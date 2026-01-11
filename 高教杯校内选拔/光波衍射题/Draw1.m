% Clear workspace and command window
clear; clc; close all;

% Read Excel files
data1 = readtable('附件1.xlsx');
data2 = readtable('附件2.xlsx');

% View table variable names
disp('10° variable names:');
disp(data1.Properties.VariableNames);
disp('15° variable names:');
disp(data2.Properties.VariableNames);

% Extract data using column indices
wavenumber1 = data1{:, 1};  % Column 1: Wavenumber
reflectance1 = data1{:, 2}; % Column 2: Reflectance

wavenumber2 = data2{:, 1};  % Column 1: Wavenumber
reflectance2 = data2{:, 2}; % Column 2: Reflectance

% Verify data ranges
fprintf('10° data range: Wavenumber %.2f-%.2f cm⁻¹, Reflectance %.2f-%.2f%%\n', ...
    min(wavenumber1), max(wavenumber1), min(reflectance1), max(reflectance1));
fprintf('15° data range: Wavenumber %.2f-%.2f cm⁻¹, Reflectance %.2f-%.2f%%\n', ...
    min(wavenumber2), max(wavenumber2), min(reflectance2), max(reflectance2));

% Create figure window
figure('Position', [100, 100, 1200, 600], 'Name', 'Reflectance Spectrum');

% First subplot: File 1 data
subplot(1, 2, 1);
plot(wavenumber1, reflectance1, 'b-', 'LineWidth', 1.5);
grid on;

% Set axes labels
xlabel('Wavenumber (cm^{-1})', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Reflectance (%)', 'FontSize', 12, 'FontWeight', 'bold');
title('10°: Reflectance Spectrum', 'FontSize', 14, 'FontWeight', 'bold');

% Set axis ranges
xlim([min(wavenumber1), max(wavenumber1)]);
% Set appropriate range for reflectance
ylim_ref1 = [min(reflectance1), max(reflectance1)*1.05];
if ylim_ref1(1) == ylim_ref1(2)  % If min equals max
    ylim_ref1(1) = ylim_ref1(1) - 0.1;
    ylim_ref1(2) = ylim_ref1(2) + 0.1;
end
ylim(ylim_ref1);

% Set grid and font
set(gca, 'FontSize', 11, 'FontName', 'Arial');
set(gca, 'GridLineStyle', '--', 'GridAlpha', 0.3);
box on;

% Second subplot: File 2 data
subplot(1, 2, 2);
plot(wavenumber2, reflectance2, 'r-', 'LineWidth', 1.5);
grid on;

% Set axes labels
xlabel('Wavenumber (cm^{-1})', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Reflectance (%)', 'FontSize', 12, 'FontWeight', 'bold');
title('15°: Reflectance Spectrum', 'FontSize', 14, 'FontWeight', 'bold');

% Set axis ranges
xlim([min(wavenumber2), max(wavenumber2)]);
% Set appropriate range for reflectance
ylim_ref2 = [min(reflectance2), max(reflectance2)*1.05];
if ylim_ref2(1) == ylim_ref2(2)  % If min equals max
    ylim_ref2(1) = ylim_ref2(1) - 0.1;
    ylim_ref2(2) = ylim_ref2(2) + 0.1;
end
ylim(ylim_ref2);

% Set grid and font
set(gca, 'FontSize', 11, 'FontName', 'Arial');
set(gca, 'GridLineStyle', '--', 'GridAlpha', 0.3);
box on;

% Add overall title
sgtitle('Reflectance Spectrum and Wavenumber', 'FontSize', 16, 'FontWeight', 'bold');

% Adjust subplot spacing
ha = findobj(gcf, 'type', 'axes');
set(ha, 'Box', 'on');
set(ha, 'TickDir', 'out');

% Optional: Save figure
% saveas(gcf, 'spectrum_plot.png');
% print(gcf, '-dpng', '-r300', 'spectrum_plot.png');

disp('Plotting complete!');