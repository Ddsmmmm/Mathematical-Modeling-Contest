% optimized_heatmap.m
% 优化版：DWTS Season 2 - Elimination Probability Heatmap
% 说明：保留原脚本功能并改进可读性、稳健性和部分性能
% 此版本：将所有文本颜色统一为黑色

clear; clc; close all;

%% 数据定义（保持不变）
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

weeks = {'Week 1', 'Week 2', 'Week 3', 'Week 4', 'Week 5', 'Week 6', 'Week 7'};

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

% 实际被淘汰的位置（保持注释说明）
actual_eliminations = [
    1, 1;  % Kenny Mayne 在 Week 1 被淘汰
    2, 2;  % Tatum O'Neal 在 Week 2 被淘汰
    3, 3;  % Giselle Fernandez 在 Week 3 被淘汰
    4, 4;  % Master P 在 Week 4 被淘汰
    5, 5;  % Tia Carrere 在 Week 5 被淘汰
    6, 6;  % George Hamilton 在 Week 6 被淘汰
    7, 7;  % Lisa Rinna 在 Week 7 被淘汰
];

%% 输入检查（可选）
[nR, nC] = size(prob_matrix);
assert(length(contestants) == nR, 'contestants 数目需要与 prob_matrix 的行数一致');
assert(length(weeks) == nC, 'weeks 数目需要与 prob_matrix 的列数一致');

%% 为“没有概率/已被淘汰后”的单元格使用 NaN（便于渲染透明/空白）
display_mat = prob_matrix;
mask_no_data = (display_mat == 0);
display_mat(mask_no_data) = NaN;

maxVal = max(prob_matrix(:));

%% 自定义 colormap（红 -> 黄，向量化）
n_colors = 256;
custom_map = [ ones(n_colors,1), linspace(0,1,n_colors)', zeros(n_colors,1) ];

%% 绘图
fig = figure('Position', [120, 120, 900, 620], 'Color', 'w');

% 使用 imagesc，并利用 AlphaData 屏蔽 NaN 单元格（看起来像空白）
h = imagesc(display_mat, 'AlphaData', ~isnan(display_mat));
colormap(custom_map);
c = colorbar;
caxis([0, maxVal]);
set(c, 'FontSize', 10);

% 强制坐标轴刻度颜色为黑色
set(gca, 'XColor', 'k', 'YColor', 'k');

% 坐标轴标签（颜色设为黑色）
xlabel('Week', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
ylabel('Contestant', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');

% 坐标轴标签设置
set(gca, 'XTick', 1:nC, 'XTickLabel', weeks, 'TickLength', [0 0], 'FontSize', 10);
set(gca, 'YTick', 1:nR, 'YTickLabel', contestants);
set(gca, 'Layer', 'top'); % 确保网格/线在顶部可以看见

% 使单元格显示为正方形
axis equal tight;

% 标题（颜色设为黑色）
title('DWTS Season 2: Elimination Probability Heatmap', ...
    'FontSize', 14, 'FontWeight', 'bold', 'Color', 'k');

% 添加网格线（用线段绘制，能与 imagesc 配合更好）
hold on;
% 绘制外框与内部网格
for xi = 0.5:(nC+0.5)
    plot([xi xi], [0.5 nR+0.5], 'k-', 'LineWidth', 0.5, 'Color', [0 0 0 0.15]);
end
for yi = 0.5:(nR+0.5)
    plot([0.5 nC+0.5], [yi yi], 'k-', 'LineWidth', 0.5, 'Color', [0 0 0 0.15]);
end

%% 在每个有数据的单元格上添加数值标签（固定为黑色）
for i = 1:nR
    for j = 1:nC
        val = prob_matrix(i,j);
        if val > 0
            text(j, i, sprintf('%.3f', val), ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', ...
                'Color', 'k', 'FontSize', 10, 'FontWeight', 'bold');
        else
            % 显示短横线表示无数据（黑色）
            text(j, i, '-', 'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', 'Color', 'k', 'FontSize', 10);
        end
    end
end

%% 标注实际被淘汰单元格（黑色虚线方框）
for k = 1:size(actual_eliminations, 1)
    row = actual_eliminations(k,1);
    col = actual_eliminations(k,2);
    rectangle('Position', [col-0.5, row-0.5, 1, 1], ...
        'EdgeColor', 'k', 'LineStyle', '--', 'LineWidth', 1.8);
end

% 添加说明文本（放在图外，黑色）
annotation('textbox', [0.02, 0.02, 0.4, 0.05], 'String', ...
    '', ...
    'EdgeColor', 'none', 'Color', 'k', 'FontSize', 10, 'FontWeight', 'normal');

% Colorbar 标签与刻度文字设置为黑色
c.Label.String = 'Elimination Probability';
c.Label.FontSize = 11;
c.Label.FontWeight = 'bold';
c.Label.Color = 'k';
set(c, 'Color', 'k');

% 最后微调交互（防止标签被裁剪）
set(gca, 'Position', [0.12, 0.12, 0.78, 0.80]);



