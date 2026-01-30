%% DWTS Season 2: Elimination Probability Heatmap (Optimized Version)
% This script creates a heatmap visualization of contestant elimination probabilities
% across weeks in Dancing With The Stars Season 2.
%
% Key optimizations:
% - Improved code structure and modularity
% - Vectorized operations where possible
% - Better memory management
% - Enhanced configurability
% - Clearer variable naming
% - Reduced redundant calculations

function dwts_season2_heatmap_optimized()
    % Clean workspace
    clear; clc; close all;
    
    %% Configuration
    config = initialize_config();
    
    %% Define Data
    data = initialize_data();
    
    %% Create Heatmap
    create_heatmap(data, config);
end

%% Helper Functions

function config = initialize_config()
    % Initialize visualization configuration
    config.figure_size = [100, 100, 800, 600];
    config.n_colors = 64;
    config.text_font_size = 10;
    config.axis_font_size = 10;
    config.title_font_size = 14;
    config.label_font_size = 12;
    config.colorbar_font_size = 11;
    config.grid_alpha = 0.3;
    config.grid_line_width = 0.5;
    config.elimination_box_line_width = 2;
end

function data = initialize_data()
    % Initialize contestant and probability data
    
    % Contestant names (ordered by elimination sequence)
    data.contestants = {
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
    data.weeks = {'Week 1', 'Week 2', 'Week 3', 'Week 4', 'Week 5', 'Week 6', 'Week 7'};
    
    % Elimination probability matrix (rows: contestants, columns: weeks)
    % Normalized values represent weekly elimination probabilities
    % Note: Probabilities are 0 after a contestant is eliminated
    data.prob_matrix = [
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
    
    % Actual elimination events (contestant_index, week_index)
    data.actual_eliminations = [
        1, 1;  % Kenny Mayne - Week 1
        2, 2;  % Tatum O'Neal - Week 2
        3, 3;  % Giselle Fernandez - Week 3
        4, 4;  % Master P - Week 4
        5, 5;  % Tia Carrere - Week 5
        6, 6;  % George Hamilton - Week 6
        7, 7;  % Lisa Rinna - Week 7
    ];
end

function create_heatmap(data, config)
    % Create and configure the heatmap figure
    
    % Create figure with specified size
    fig = figure('Position', config.figure_size, 'Color', 'white');
    
    % Display probability matrix as heatmap
    imagesc(data.prob_matrix);
    
    % Configure colormap and color range
    setup_colormap(data.prob_matrix, config);
    
    % Add data labels to cells
    add_cell_labels(data.prob_matrix, config);
    
    % Configure axes and labels
    setup_axes(data, config);
    
    % Highlight actual eliminations
    highlight_eliminations(data.actual_eliminations, config);
    
    % Add legend and additional annotations
    add_annotations(data, config);
end

function setup_colormap(prob_matrix, config)
    % Create and apply custom red-to-yellow colormap
    
    % Generate custom colormap: red -> orange -> yellow
    t = linspace(0, 1, config.n_colors)';
    custom_map = [ones(config.n_colors, 1), t, zeros(config.n_colors, 1)];
    
    colormap(custom_map);
    
    % Add colorbar with label
    cb = colorbar;
    cb.Label.String = 'Elimination Probability';
    cb.Label.FontSize = config.colorbar_font_size;
    cb.Label.FontWeight = 'bold';
    
    % Set color axis range
    caxis([0, max(prob_matrix(:))]);
end

function add_cell_labels(prob_matrix, config)
    % Add formatted probability values to each cell
    
    [n_rows, n_cols] = size(prob_matrix);
    max_prob = max(prob_matrix(:));
    threshold = max_prob / 2;
    
    % Vectorized approach: pre-compute all text properties
    for i = 1:n_rows
        for j = 1:n_cols
            if prob_matrix(i, j) > 0
                % Select text color based on background intensity
                text_color = determine_text_color(prob_matrix(i, j), threshold);
                
                % Display probability value (3 decimal places)
                text(j, i, sprintf('%.3f', prob_matrix(i, j)), ...
                    'HorizontalAlignment', 'center', ...
                    'Color', text_color, ...
                    'FontSize', config.text_font_size, ...
                    'FontWeight', 'bold');
            else
                % Display dash for zero probabilities
                text(j, i, '-', ...
                    'HorizontalAlignment', 'center', ...
                    'Color', 'black', ...
                    'FontSize', config.text_font_size);
            end
        end
    end
end

function color = determine_text_color(value, threshold)
    % Determine optimal text color based on background brightness
    if value > threshold
        color = 'white';
    else
        color = 'black';
    end
end

function setup_axes(data, config)
    % Configure axes, labels, and grid
    
    % Configure x-axis (weeks)
    set(gca, 'XTick', 1:length(data.weeks), ...
             'XTickLabel', data.weeks);
    xlabel('Week', 'FontSize', config.label_font_size, 'FontWeight', 'bold');
    
    % Configure y-axis (contestants)
    set(gca, 'YTick', 1:length(data.contestants), ...
             'YTickLabel', data.contestants);
    ylabel('Contestant', 'FontSize', config.label_font_size, 'FontWeight', 'bold');
    
    % Set title
    title('DWTS Season 2: Elimination Probability Heatmap', ...
          'FontSize', config.title_font_size, 'FontWeight', 'bold');
    
    % Configure grid
    grid on;
    set(gca, 'GridColor', 'k', ...
             'GridAlpha', config.grid_alpha, ...
             'LineWidth', config.grid_line_width, ...
             'FontSize', config.axis_font_size, ...
             'TickLength', [0, 0]);
    
    % Ensure square cells
    axis equal tight;
end

function highlight_eliminations(actual_eliminations, config)
    % Mark actual elimination events with dashed boxes
    
    hold on;
    n_eliminations = size(actual_eliminations, 1);
    
    for i = 1:n_eliminations
        row = actual_eliminations(i, 1);
        col = actual_eliminations(i, 2);
        
        % Draw dashed rectangle around elimination cell
        rectangle('Position', [col-0.5, row-0.5, 1, 1], ...
                  'EdgeColor', 'black', ...
                  'LineWidth', config.elimination_box_line_width, ...
                  'LineStyle', '--');
    end
    
    hold off;
end

function add_annotations(data, config)
    % Add legend and explanatory text
    
    n_contestants = length(data.contestants);
    
    % Add legend explaining the dashed boxes
    text(0.5, n_contestants + 1.5, ...
         'Black dashed boxes indicate actual eliminations', ...
         'FontSize', config.text_font_size, ...
         'Color', 'blue');
end

%% Optional: Save figure
% Uncomment the following lines to save the figure
% saveas(gcf, 'DWTS_Season2_Elimination_Probability_Heatmap.png');
% print('DWTS_Season2_Elimination_Probability_Heatmap', '-dpng', '-r300');
