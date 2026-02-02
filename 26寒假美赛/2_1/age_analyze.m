%% 分析年龄对最终排名的影响
clear; clc; close all;

% 读取Excel文件
filename = '2026_MCM_Problem_C_Data.xlsx';

% 使用readtable读取Excel文件
try
    % 尝试读取Excel文件
    data = readtable(filename);
    fprintf('成功读取Excel文件，共有 %d 行数据\n', height(data));
catch ME
    error('无法读取Excel文件: %s', ME.message);
end

% 检查必要的列是否存在
required_columns = {'celebrity_age_during_season', 'placement', 'season'};
missing_cols = setdiff(required_columns, data.Properties.VariableNames);
if ~isempty(missing_cols)
    error('缺少必要的列: %s', strjoin(missing_cols, ', '));
end

% 提取所需列的数据
age = data.celebrity_age_during_season;
placement = data.placement;
season = data.season;

% 确保数据是数值类型
age = double(age);
placement = double(placement);
season = double(season);

% 删除缺失值（NaN）
valid_idx = ~isnan(age) & ~isnan(placement) & ~isnan(season);
age = age(valid_idx);
placement = placement(valid_idx);
season = season(valid_idx);

fprintf('有效数据点数：%d\n', length(age));
fprintf('年龄范围：%.0f - %.0f 岁\n', min(age), max(age));
fprintf('排名范围：%.0f - %.0f\n', min(placement), max(placement));
fprintf('赛季数量：%d\n', length(unique(season)));

%% 分析1：原始排名与年龄的相关性
[r_pearson, p_pearson] = corr(age, placement, 'Type', 'Pearson');
[r_spearman, p_spearman] = corr(age, placement, 'Type', 'Spearman');

fprintf('=== 原始排名分析 ===\n');
fprintf('Pearson相关系数：%.4f (p=%.4f)\n', r_pearson, p_pearson);
fprintf('Spearman相关系数：%.4f (p=%.4f)\n', r_spearman, p_spearman);

% 线性回归
X = [ones(length(age),1), age];
[b, bint, ~, ~, stats] = regress(placement, X);
fprintf('回归模型：placement = %.4f + %.4f * age\n', b(1), b(2));
fprintf('年龄的回归系数：%.4f (95%% CI: [%.4f, %.4f])\n', b(2), bint(2,1), bint(2,2));
fprintf('R^2: %.4f\n', stats(1));

% 绘制原始排名与年龄的散点图及回归线
figure('Position', [100,100,800,600]);
scatter(age, placement, 20, 'filled', 'MarkerFaceAlpha',0.6);
hold on;
xlabel('年龄', 'FontSize',12);
ylabel('排名（数值越小表现越好）', 'FontSize',12);
title('年龄与原始排名的关系', 'FontSize',14);
grid on;
x_range = [min(age), max(age)];
y_fit = b(1) + b(2)*x_range;
plot(x_range, y_fit, 'r-', 'LineWidth',2);
legend('数据点', sprintf('回归线: y=%.3f+%.3fx', b(1), b(2)), 'Location','best');
text(0.05,0.95, sprintf('Pearson r = %.3f, p=%.3f', r_pearson, p_pearson), ...
    'Units','normalized', 'VerticalAlignment','top', 'FontSize',10);

%% 分析2：按赛季标准化排名
% 计算每个赛季的选手数量（最大排名）
unique_seasons = unique(season);
normalized_placement = zeros(size(placement));

for s = 1:length(unique_seasons)
    idx = (season == unique_seasons(s));
    max_plac = max(placement(idx));
    if max_plac > 1
        normalized_placement(idx) = (placement(idx) - 1) / (max_plac - 1);
    else
        normalized_placement(idx) = 0; % 如果只有一名选手
    end
end

% 标准化排名与年龄的相关性
[r_pearson_norm, p_pearson_norm] = corr(age, normalized_placement, 'Type', 'Pearson');
[r_spearman_norm, p_spearman_norm] = corr(age, normalized_placement, 'Type', 'Spearman');

fprintf('\n=== 标准化排名分析（按赛季）===\n');
fprintf('Pearson相关系数：%.4f (p=%.4f)\n', r_pearson_norm, p_pearson_norm);
fprintf('Spearman相关系数：%.4f (p=%.4f)\n', r_spearman_norm, p_spearman_norm);

% 线性回归
X = [ones(length(age),1), age];
[b_norm, bint_norm, ~, ~, stats_norm] = regress(normalized_placement, X);
fprintf('回归模型：normalized_placement = %.4f + %.4f * age\n', b_norm(1), b_norm(2));
fprintf('年龄的回归系数：%.4f (95%% CI: [%.4f, %.4f])\n', b_norm(2), bint_norm(2,1), bint_norm(2,2));
fprintf('R^2: %.4f\n', stats_norm(1));

% 绘制标准化排名与年龄的散点图及回归线
figure('Position', [100,100,800,600]);
scatter(age, normalized_placement, 20, 'filled', 'MarkerFaceAlpha',0.6);
hold on;
xlabel('年龄', 'FontSize',12);
ylabel('标准化排名（0=第一名，1=最后一名）', 'FontSize',12);
title('年龄与标准化排名的关系', 'FontSize',14);
grid on;
x_range = [min(age), max(age)];
y_fit_norm = b_norm(1) + b_norm(2)*x_range;
plot(x_range, y_fit_norm, 'r-', 'LineWidth',2);
legend('数据点', sprintf('回归线: y=%.3f+%.3fx', b_norm(1), b_norm(2)), 'Location','best');
text(0.05,0.95, sprintf('Pearson r = %.3f, p=%.3f', r_pearson_norm, p_pearson_norm), ...
    'Units','normalized', 'VerticalAlignment','top', 'FontSize',10);

%% 解释
% 根据相关系数和回归系数，判断年龄对排名的影响方向和强度。
% 如果回归系数为正，表明年龄越大，排名数字越大（表现越差）；
% 如果为负，则年龄越大，排名数字越小（表现越好）。
% 同时，p值小于0.05通常表示统计显著。

fprintf('\n=== 结论 ===\n');
if p_pearson_norm < 0.05
    if b_norm(2) > 0
        fprintf('年龄对排名有显著的正面影响（即年龄越大，排名越靠后，表现越差）。\n');
    else
        fprintf('年龄对排名有显著的负面影响（即年龄越大，排名越靠前，表现越好）。\n');
    end
    fprintf('影响强度：年龄每增加1岁，标准化排名增加 %.4f（即排名变差的程度）。\n', b_norm(2));
else
    fprintf('年龄对排名的影响在统计上不显著。\n');
end

%% 额外分析：分年龄段统计平均排名
% 将年龄分组
age_bins = [0, 20, 30, 40, 50, 60, 100];
age_labels = {'<20', '20-29', '30-39', '40-49', '50-59', '60+'};
age_group = discretize(age, age_bins);

% 计算每个年龄组的平均排名和平均标准化排名
fprintf('\n=== 分年龄段分析 ===\n');
for i = 1:length(age_labels)
    idx = (age_group == i);
    if any(idx)
        fprintf('年龄组 %s (n=%d): 平均年龄=%.1f, 平均排名=%.2f, 平均标准化排名=%.2f\n', ...
            age_labels{i}, sum(idx), mean(age(idx)), mean(placement(idx)), mean(normalized_placement(idx)));
    end
end

% 绘制年龄组与平均排名的条形图
figure('Position', [100,100,900,400]);
subplot(1,2,1);
mean_placement_by_age = grpstats(placement, age_group, 'mean');
bar(1:length(age_labels), mean_placement_by_age);
xlabel('年龄组', 'FontSize',12);
ylabel('平均排名', 'FontSize',12);
title('各年龄组平均排名', 'FontSize',14);
grid on;
xticks(1:length(age_labels));
xticklabels(age_labels);

subplot(1,2,2);
mean_norm_placement_by_age = grpstats(normalized_placement, age_group, 'mean');
bar(1:length(age_labels), mean_norm_placement_by_age);
xlabel('年龄组', 'FontSize',12);
ylabel('平均标准化排名', 'FontSize',12);
title('各年龄组平均标准化排名', 'FontSize',14);
grid on;
xticks(1:length(age_labels));
xticklabels(age_labels);