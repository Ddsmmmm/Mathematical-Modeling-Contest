%% DWTS Season 2: Elimination Probability Heatmap (Optimized Standalone Script)
% This script creates a heatmap visualization of contestant elimination probabilities
% across weeks in Dancing With The Stars Season 2.
%
% Key improvements over original version:
% 1. Vectorized colormap generation (more efficient)
% 2. Better variable organization and naming
% 3. Reduced code duplication
% 4. Improved comments and documentation
% 5. More configurable parameters
% 6. Cleaner control flow

clear; clc; close all;

%% Configuration Parameters
CONFIG = struct();
CONFIG.figure_size = [100, 100, 800, 600];
CONFIG.n_colors = 64;
CONFIG.text_font_size = 10;
CONFIG.axis_font_size = 10;
CONFIG.title_font_size = 14;
CONFIG.label_font_size = 12;
CONFIG.colorbar_font_size = 11;
CONFIG.grid_alpha = 0.3;
CONFIG.grid_line_width = 0.5;
CONFIG.elimination_box_line_width = 2;

%% Data Definition
% Contestant names (ordered by elimination sequence)
contestants = {
    'Kenny Mayne'
    'Tatum O''Neal'
    'Giselle Fernandez'
    'Master P'
    'Tia Carrere'
    'George Hamilton'
    'Lisa Rinna'
    'Stacy Keibler'
    'Jerry Rice'
    'Drew Lachey'
};

% Week labels
weeks = {'Week 1', 'Week 2', 'Week 3', 'Week 4', 'Week 5', 'Week 6', 'Week 7'};

% Elimination probability matrix (rows: contestants, columns: weeks)
% Values are normalized and represent weekly elimination probabilities
% Zero values indicate the contestant was already eliminated
prob_matrix = [
    0.151, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000
    0.096, 0.185, 0.000, 0.000, 0.000, 0.000, 0.000
    0.101, 0.121, 0.208, 0.000, 0.000, 0.000, 0.000
    0.101, 0.115, 0.175, 0.221, 0.000, 0.000, 0.000
    0.124, 0.142, 0.167, 0.189, 0.238, 0.000, 0.000
    0.119, 0.130, 0.150, 0.170, 0.202, 0.265, 0.000
    0.119, 0.127, 0.138, 0.155, 0.180, 0.235, 0.327
    0.064, 0.068, 0.062, 0.075, 0.110, 0.145, 0.193
    0.064, 0.058, 0.050, 0.060, 0.090, 0.120, 0.240
    0.069, 0.054, 0.050, 0.130, 0.180, 0.235, 0.240
];

% Actual elimination events [contestant_index, week_index]
actual_eliminations = [
    1, 1;  % Kenny Mayne - Week 1
    2, 2;  % Tatum O'Neal - Week 2
    3, 3;  % Giselle Fernandez - Week 3
    4, 4;  % Master P - Week 4
    5, 5;  % Tia Carrere - Week 5
    6, 6;  % George Hamilton - Week 6
    7, 7;  % Lisa Rinna - Week 7
];

%% Create Figure and Heatmap
figure('Position', CONFIG.figure_size, 'Color', 'white');

% Display probability matrix
imagesc(prob_matrix);

%% Configure Colormap
% Create custom red-to-yellow gradient (vectorized for efficiency)
t = linspace(0, 1, CONFIG.n_colors)';
custom_colormap = [ones(CONFIG.n_colors, 1), t, zeros(CONFIG.n_colors, 1)];
colormap(custom_colormap);

% Add colorbar with descriptive label
cb = colorbar;
cb.Label.String = 'Elimination Probability';
cb.Label.FontSize = CONFIG.colorbar_font_size;
cb.Label.FontWeight = 'bold';

% Set color axis range
caxis([0, max(prob_matrix(:))]);

%% Add Cell Labels
[n_rows, n_cols] = size(prob_matrix);
max_prob = max(prob_matrix(:));
threshold = max_prob / 2;

for i = 1:n_rows
    for j = 1:n_cols
        if prob_matrix(i, j) > 0
            % Choose text color based on background intensity
            text_color = select_text_color(prob_matrix(i, j), threshold);
            
            % Display probability with 3 decimal places
            text(j, i, sprintf('%.3f', prob_matrix(i, j)), ...
                'HorizontalAlignment', 'center', ...
                'Color', text_color, ...
                'FontSize', CONFIG.text_font_size, ...
                'FontWeight', 'bold');
        else
            % Display dash for zero probabilities
            text(j, i, '-', ...
                'HorizontalAlignment', 'center', ...
                'Color', 'black', ...
                'FontSize', CONFIG.text_font_size);
        end
    end
end

%% Configure Axes and Labels
% X-axis (weeks)
set(gca, 'XTick', 1:length(weeks), 'XTickLabel', weeks);
xlabel('Week', 'FontSize', CONFIG.label_font_size, 'FontWeight', 'bold');

% Y-axis (contestants)
set(gca, 'YTick', 1:length(contestants), 'YTickLabel', contestants);
ylabel('Contestant', 'FontSize', CONFIG.label_font_size, 'FontWeight', 'bold');

% Title
title('DWTS Season 2: Elimination Probability Heatmap', ...
      'FontSize', CONFIG.title_font_size, 'FontWeight', 'bold');

% Grid configuration
grid on;
set(gca, 'GridColor', 'k', ...
         'GridAlpha', CONFIG.grid_alpha, ...
         'LineWidth', CONFIG.grid_line_width, ...
         'FontSize', CONFIG.axis_font_size, ...
         'TickLength', [0, 0]);

% Ensure square cells
axis equal tight;

%% Highlight Actual Eliminations
hold on;
for i = 1:size(actual_eliminations, 1)
    row = actual_eliminations(i, 1);
    col = actual_eliminations(i, 2);
    
    % Draw dashed rectangle around actual elimination cells
    rectangle('Position', [col-0.5, row-0.5, 1, 1], ...
              'EdgeColor', 'black', ...
              'LineWidth', CONFIG.elimination_box_line_width, ...
              'LineStyle', '--');
end
hold off;

%% Add Legend
text(0.5, length(contestants) + 1.5, ...
     'Black dashed boxes indicate actual eliminations', ...
     'FontSize', CONFIG.text_font_size, ...
     'Color', 'blue');

%% Helper Function
function color = select_text_color(value, threshold)
    % Select optimal text color based on background brightness
    % White text for dark backgrounds, black text for light backgrounds
    if value > threshold
        color = 'white';
    else
        color = 'black';
    end
end

%% Optional: Save Figure
% Uncomment to save the figure
% saveas(gcf, 'DWTS_Season2_Elimination_Probability_Heatmap_Optimized.png');
% print('DWTS_Season2_Elimination_Probability_Heatmap_Optimized', '-dpng', '-r300');
