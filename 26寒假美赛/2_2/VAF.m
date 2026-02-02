% 清除环境
clear; clc; close all;

% 周次
week = 1:4;

% 百分比合并法下的排名（手动计算）
rank_percent = [6, 6, 5, 7];

% our_method下的排名（手动计算）
rank_our = [6, 4, 3, 5];

% 绘制折线图
figure;
plot(week, rank_percent, '-o', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Percentage Method');
hold on;
plot(week, rank_our, '-s', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Our Method');

% 图表设置
xlabel('Week', 'FontSize', 12);
ylabel('Rank (lower is better)', 'FontSize', 12);
title('Vivica A. Fox Ranking Each Week (Season 3)', 'FontSize', 14);
legend('Location', 'best');
grid on;

% 反转Y轴，使排名1显示在顶部
set(gca, 'YDir', 'reverse');

% 设置坐标轴范围
xlim([0.8, 4.2]);
ylim([0, 8]);

% 标注数据点
for i = 1:length(week)
    text(week(i), rank_percent(i), sprintf(' %d', rank_percent(i)), ...
        'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left', 'FontSize', 10);
    text(week(i), rank_our(i), sprintf(' %d', rank_our(i)), ...
        'VerticalAlignment', 'top', 'HorizontalAlignment', 'left', 'FontSize', 10);
end

% 输出图表
print('Vivica_Ranking.png', '-dpng');