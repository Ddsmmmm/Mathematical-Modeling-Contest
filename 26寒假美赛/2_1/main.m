%% 清理环境
clear; clc; close all;

%% 第2赛季粉丝投票数据（从Excel中提取）
% 数据格式：每周粉丝投票数
% 选手顺序：Kenny Mayne, Tatum O'Neal, Giselle Fernandez, Master P, Tia Carrere, 
% George Hamilton, Lisa Rinna, Stacy Keibler, Jerry Rice, Drew Lachey

fan_votes = [
    181967   0       0       0       0       0       0       0       ;  % Kenny Mayne
    363945   222113  0       0       0       0       0       0       ;  % Tatum O'Neal
    545112   888912  277935  0       0       0       0       0       ;  % Giselle Fernandez
    1817905  1999956 2222015 356987  0       0       0       0       ;  % Master P
    727083   1555926 1111028 1786024 476041  0       0       0       ;  % Tia Carrere
    1091107  1332974 1666963 2499962 2381082 667041  0       0       ;  % George Hamilton
    1273105  1777963 1389017 1071043 1905032 2666987 999986  0       ;  % Lisa Rinna
    1455093  444011  555987  1429021 952087  1333028 2999978 1666974;  % Stacy Keibler
    1635942  1110973 1944011 2143025 2857092 3333024 4000047 5000033;  % Jerry Rice
    908841   667072  833044  714029  1428912 1999999 2000119 3332993   % Drew Lachey
];

%% 第2赛季评委打分数据（从Excel中提取）
% 数据格式：每周评委分（已汇总）
% 注意：这里我使用了原始数据中的总和，或者你可以使用平均值
judge_scores = [
    13   0   0   0   0   0   0   0   ;  % Kenny Mayne (4+5+4=13)
    23   17  0   0   0   0   0   0   ;  % Tatum O'Neal (7+8+8=23, 5+6+6=17)
    23   24  22  0   0   0   0   0   ;  % Giselle Fernandez
    12   16  14  8   0   0   0   0   ;  % Master P
    20   22  26  25  22  0   0   0   ;  % Tia Carrere
    18   22  22  21  24  23  0   0   ;  % George Hamilton
    19   20  25  26  25  27  26.5 0  ;  % Lisa Rinna
    22   29  27  26  30  30  27.5 28.6665; % Stacy Keibler
    21   23  19  24  23  23  20.5 26.6666; % Jerry Rice
    24   27  27  28  27  30  27.5 29     % Drew Lachey
];

contestant_names = {
    'Kenny Mayne', 'Tatum O''Neal', 'Giselle Fernandez', 'Master P', ...
    'Tia Carrere', 'George Hamilton', 'Lisa Rinna', 'Stacy Keibler', ...
    'Jerry Rice', 'Drew Lachey'
};

target_contestant = 9; % Jerry Rice (第9位选手)

weeks = 8;
rank_percentage = zeros(weeks, 1);  % 存储百分比法的排名
rank_our_method = zeros(weeks, 1);  % 存储our method的排名

%% 计算每周的排名
for week = 1:weeks
    % 找出本周仍在比赛的选手（投票数非0）
    active_contestants = find(fan_votes(:, week) > 0);
    
    % 提取本周活跃选手的数据
    week_fan_votes = fan_votes(active_contestants, week);
    week_judge_scores = judge_scores(active_contestants, week);
    
    n_active = length(active_contestants);
    
    % ===== 方法1：百分比合并法 =====
    judge_total = sum(week_judge_scores);
    fan_total = sum(week_fan_votes);
    
    judge_percentages = week_judge_scores / judge_total * 100;
    fan_percentages = week_fan_votes / fan_total * 100;
    
    combined_scores_percentage = judge_percentages + fan_percentages;
    
    % 计算排名（分数越高，排名数字越小）
    [~, sorted_idx_percentage] = sort(combined_scores_percentage, 'descend');
    
    % 找到目标选手的排名
    target_idx = find(active_contestants == target_contestant);
    rank_percentage(week) = find(sorted_idx_percentage == target_idx);
    
    % ===== 方法2：Our Method（阶梯式双轨制） =====
    % 1. 评委标准化 (Min-Max 映射到 [10, 20] 区间)
    J_min = min(week_judge_scores);
    J_max = max(week_judge_scores);
    
    if J_max == J_min
        S_judge = ones(n_active, 1) * 15; % 如果所有评委分相同，设为中间值
    else
        S_judge = 10 + 10 * (week_judge_scores - J_min) / (J_max - J_min);
    end
    
    % 2. 粉丝段位映射 (使用Sigmoid函数)
    % 首先计算百分位排名（投票数越高，百分位越高）
    [~, fan_rank_idx] = sort(week_fan_votes, 'descend'); % 降序排列
    fan_ranks = zeros(n_active, 1);
    fan_ranks(fan_rank_idx) = 1:n_active;
    
    % 计算百分位 P_i (0到1之间，1表示最高)
    P_i = (n_active - fan_ranks) / (n_active - 1);
    if n_active == 1
        P_i = 1; % 如果只有1个选手，百分位为1
    end
    
    % Sigmoid参数
    K = 0.5; % 最大加成上限
    s = 10;  % 竞争强度系数
    
    % 计算粉丝热度加成
    T_fan = K ./ (1 + exp(-s * (P_i - 0.5)));
    
    % 3. 最终得分
    S_final = S_judge .* (1 + T_fan);
    
    % 计算排名
    [~, sorted_idx_our_method] = sort(S_final, 'descend');
    
    % 找到目标选手的排名
    rank_our_method(week) = find(sorted_idx_our_method == target_idx);
end

%% 绘制排名变化图
figure('Position', [100, 100, 800, 500]);

% 只绘制选手参赛的周次
active_weeks = find(rank_percentage > 0);

% 绘制两条折线
plot(active_weeks, rank_percentage(active_weeks), 'b-o', ...
    'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'b', ...
    'DisplayName', '百分比合并法');
hold on;
plot(active_weeks, rank_our_method(active_weeks), 'r-s', ...
    'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'r', ...
    'DisplayName', 'Our Method');

% 设置图形属性
xlabel('Week', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Rank (数字越小排名越高)', 'FontSize', 12, 'FontWeight', 'bold');
title(sprintf('%s - 两种评分方法的排名变化', contestant_names{target_contestant}), ...
    'FontSize', 14, 'FontWeight', 'bold');

% 设置坐标轴
xlim([min(active_weeks)-0.5, max(active_weeks)+0.5]);
ylim([0, max([rank_percentage(active_weeks); rank_our_method(active_weeks)]) + 1]);
set(gca, 'YDir', 'reverse'); % Y轴反转，使得排名1在顶部
grid on;

% 添加图例
legend('Location', 'best');

% 在每个数据点添加数值标签
for i = 1:length(active_weeks)
    text(active_weeks(i), rank_percentage(active_weeks(i)), ...
        sprintf('%d', rank_percentage(active_weeks(i))), ...
        'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', ...
        'FontSize', 10, 'Color', 'b');
    
    text(active_weeks(i), rank_our_method(active_weeks(i)), ...
        sprintf('%d', rank_our_method(active_weeks(i))), ...
        'VerticalAlignment', 'top', 'HorizontalAlignment', 'center', ...
        'FontSize', 10, 'Color', 'r');
end

% 美化图形
set(gca, 'FontSize', 11);
set(gcf, 'Color', 'w');

%% 显示排名数据表格
fprintf('=== %s 排名数据 ===\n', contestant_names{target_contestant});
fprintf('Week\t百分比法\tOur Method\n');
for week = 1:weeks
    if rank_percentage(week) > 0
        fprintf('%d\t%d\t\t%d\n', week, rank_percentage(week), rank_our_method(week));
    end
end