close all;clc;clear;

%% 数据准备
% 年龄组（作为分类标签）
age_groups = {'16-25', '26-35', '36-45', '46-55', '56-65', '66-75', '76-85'};

% 粉丝得票率（百分比）
fan_vote_rate = [0.22, 0.16, 0.12, 0.11, 0.13, 0.12, 0.14] * 100; % 转换为百分比

% 评委平均分（10分制）
judge_avg_score = [8.2, 8.6, 8.3, 7.9, 8.1, 8.4, 7.7];

%   104  102  95  90  94  96  91


%% 创建图形窗口
figure('Position', [100, 100, 900, 500]);

%% 绘制双Y轴图形
% 第一个Y轴：粉丝得票率（百分比）
yyaxis left;
plot(1:length(age_groups), fan_vote_rate, 'b-o', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'b');
ylabel('粉丝得票率 (%)', 'FontSize', 12, 'FontWeight', 'bold');
ylim([0, max(fan_vote_rate)*1.1]); % 设置Y轴范围
grid on;

% 第二个Y轴：评委平均分
yyaxis right;
plot(1:length(age_groups), judge_avg_score, 'r-s', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'r');
ylabel('评委平均分 (转化为10分制)', 'FontSize', 12, 'FontWeight', 'bold');
ylim([7, 10]); % 设置Y轴范围

%% 图形美化
% 设置X轴
xlim([0.5, length(age_groups)+0.5]);
set(gca, 'XTick', 1:length(age_groups));
set(gca, 'XTickLabel', age_groups);
xlabel('年龄组', 'FontSize', 12, 'FontWeight', 'bold');

% 添加标题
title('不同年龄阶段参赛选手的粉丝得票率和评委平均分', 'FontSize', 14, 'FontWeight', 'bold');

% 添加图例
legend({'粉丝得票率', '评委平均分'}, 'Location', 'best', 'FontSize', 10);

% 添加网格
grid on;
box on;

% %% 在数据点上添加数值标签
% % 为粉丝得票率添加标签
% for i = 1:length(fan_vote_rate)
%     text(i, fan_vote_rate(i), sprintf('%.1f%%', fan_vote_rate(i)), ...
%         'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
%         'FontSize', 9, 'Color', 'b');
% end
% 
% % 为评委平均分添加标签
% for i = 1:length(judge_avg_score)
%     text(i, judge_avg_score(i), sprintf('%.1f', judge_avg_score(i)), ...
%         'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
%         'FontSize', 9, 'Color', 'r');
% end

%% 调整图形外观
set(gca, 'FontSize', 10, 'FontWeight', 'bold');
set(gcf, 'Color', 'w');

%% 保存图形
% saveas(gcf, 'age_group_performance.png');
% disp('图形已保存为 age_group_performance.png');