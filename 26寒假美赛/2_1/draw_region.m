%% 分析地区与最终位次关系，量化地区受欢迎程度
clc; clear; close all;

%% 1. 从Excel文件读取数据
fprintf('正在读取Excel文件...\n');

% 指定Excel文件名
excel_file = '广义分析.xlsx';  % 确保文件在当前目录下

% 检查文件是否存在
if ~exist(excel_file, 'file')
    error('文件 %s 不存在，请确保文件在当前目录下', excel_file);
end

% 读取Excel文件
try
    % 使用readtable函数读取Excel文件
    T = readtable(excel_file, 'Sheet', 'Sheet1');
    fprintf('成功读取文件: %s\n', excel_file);
    fprintf('数据表大小: %d 行 × %d 列\n', height(T), width(T));

    % 显示列名（用于调试）
    fprintf('列名: ');
    fprintf('%s, ', T.Properties.VariableNames{:});
    fprintf('\n');

catch ME
    error('读取Excel文件失败: %s', ME.message);
end

%% 2. 数据清理和预处理
fprintf('\n===== 数据清理和预处理 =====\n');

% 检查必要的列是否存在
required_cols = {'region', 'placement'};
for i = 1:length(required_cols)
    if ~any(strcmp(T.Properties.VariableNames, required_cols{i}))
        error('缺少必要的列: %s', required_cols{i});
    end
end

% 检查placement列是否为数值类型
if ~isnumeric(T.placement)
    fprintf('placement列不是数值类型，正在尝试转换...\n');
    T.placement = str2double(T.placement);
end

% 移除placement为空或无效的行
initial_rows = height(T);
T = T(~isnan(T.placement) & T.placement > 0, :);
removed_rows = initial_rows - height(T);
if removed_rows > 0
    fprintf('移除了 %d 行无效的placement数据\n', removed_rows);
end

% 检查region列的格式——将其统一为 cellstr（字符单元格），便于用 {} 索引
if iscellstr(T.region)
    % 已经是 cellstr，无需转换
    fprintf('region列是 cellstr 类型\n');
elseif isstring(T.region)
    T.region = cellstr(T.region);
    fprintf('region列已从 string 转换为 cellstr\n');
else
    % 如果region不是字符类型，尝试转换为 cellstr
    try
        T.region = cellstr(T.region);
        fprintf('region列已转换为 cellstr 类型\n');
    catch
        error('region列格式不正确，无法转换为字符单元格 (cellstr)');
    end
end

% 统计各地区数量
unique_regions = unique(T.region);
fprintf('发现 %d 个不同的地区:\n', length(unique_regions));
for i = 1:min(10, length(unique_regions))
    fprintf('  %s\n', unique_regions{i});
end
if length(unique_regions) > 10
    fprintf('  ... 和其他 %d 个地区\n', length(unique_regions)-10);
end

%% 3. 基本统计分析
fprintf('\n===== 基本统计信息 =====\n');
fprintf('有效记录数: %d\n', height(T));

% 查看各地区分布
region_counts = groupsummary(T, 'region');
fprintf('\n各地区参赛人数统计:\n');
disp(region_counts(:, {'region', 'GroupCount'}));

% 计算总览统计
total_participants = height(T);
fprintf('\n总体统计:\n');
fprintf('平均位次: %.2f\n', mean(T.placement));
fprintf('中位数位次: %.1f\n', median(T.placement));
fprintf('最佳位次: %d\n', min(T.placement));
fprintf('最差位次: %d\n', max(T.placement));

%% 4. 分析地区与最终位次的关系
% 计算每个地区的平均位次（位次越小越好，1表示冠军）
region_stats = grpstats(T, 'region', {'mean', 'std', 'min', 'max'}, 'DataVars', 'placement');

% grpstats 对不同输入形式可能返回不同结构，下面保证 median 和 count 为列向量
region_stats.median_placement = grpstats(T.placement, T.region, @median);
region_stats.count = grpstats(T.placement, T.region, @length);

% 计算位次的稳健统计量（排除极端值）
region_stats.trimmed_mean = zeros(height(region_stats), 1);
for i = 1:height(region_stats)
    region_name = region_stats.region{i};
    region_data = T.placement(strcmp(T.region, region_name));
    % 如果该地区没有数据，跳过
    if isempty(region_data)
        region_stats.trimmed_mean(i) = NaN;
    else
        % 计算去除最高10%和最低10%后的均值
        region_stats.trimmed_mean(i) = trimmean(region_data, 20);
    end
end

% 按平均位次排序（平均位次越低，整体表现越好）
if any(strcmp(region_stats.Properties.VariableNames, 'mean_placement'))
    region_stats = sortrows(region_stats, 'mean_placement');
else
    % 保险路径：若列名不同，尝试找到第一个 mean_* 列
    mean_cols = region_stats.Properties.VariableNames(contains(region_stats.Properties.VariableNames, 'mean'));
    if ~isempty(mean_cols)
        region_stats = sortrows(region_stats, mean_cols{1});
    end
end

fprintf('\n===== 各地区平均位次排名（越低越好）=====\n');
fprintf('排名 | 地区 | 平均位次 | 中位数 | 参赛人数 | 稳健均值\n');
fprintf('-----|------|----------|--------|----------|----------\n');

for i = 1:min(15, height(region_stats))  % 显示前15名
    fprintf('%4d. %-15s: %.2f (中位数:%.1f, 人数:%2d, 稳健:%.2f)\n', ...
            i, region_stats.region{i}, region_stats.mean_placement(i), ...
            region_stats.median_placement(i), region_stats.count(i), ...
            region_stats.trimmed_mean(i));
end

%% 5. 量化地区受欢迎程度 - 综合评分
fprintf('\n===== 计算各地区受欢迎程度 =====\n');

% 方法1: 基于位次的评分（位次越低，得分越高）
max_placement = max(T.placement);
min_placement = min(T.placement);
fprintf('位次范围: %d-%d\n', min_placement, max_placement);

% 处理所有位次相同的极端情况，避免除以零
if max_placement == min_placement
    placement_score = 100 * ones(height(T), 1);
    rank_score = 100 * ones(height(T), 1);
else
    % 标准化位次评分：将位次转换为0-100分的评分
    placement_score = 100 * (1 - (T.placement - min_placement) / (max_placement - min_placement));
    % 方法3: 基于排名的评分（逆序排名）
    rank_score = 100 * (1 - (T.placement - 1) / (max_placement - 1));
end

% 方法2: 基于获奖情况的评分（前3名得高分）
winner_score = zeros(height(T), 1);
winner_score(T.placement == 1) = 100;  % 冠军
winner_score(T.placement == 2) = 80;   % 亚军
winner_score(T.placement == 3) = 60;   % 季军
winner_score(T.placement >= 4 & T.placement <= 5) = 40;   % 4-5名
winner_score(T.placement >= 6 & T.placement <= 10) = 25;  % 6-10名
winner_score(T.placement >= 11 & T.placement <= 15) = 10; % 11-15名
winner_score(T.placement > 15) = 5;    % 16名以后

% 若 rank_score 未定义（极端情况），上面已处理
if ~exist('rank_score', 'var')
    rank_score = 100 * ones(height(T), 1);
end

% 综合评分（加权平均，可调整权重）
% 权重1: 标准化位次评分 (40%)
% 权重2: 获奖情况评分 (40%)
% 权重3: 排名评分 (20%)
weight1 = 0.4;
weight2 = 0.4;
weight3 = 0.2;
composite_score = weight1 * placement_score + weight2 * winner_score + weight3 * rank_score;

% 添加到表格
T.placement_score = placement_score;
T.winner_score = winner_score;
T.rank_score = rank_score;
T.composite_score = composite_score;

% 显示评分统计
fprintf('\n评分统计:\n');
fprintf('标准化位次评分: 均值=%.2f, 范围=[%.2f, %.2f]\n', ...
        mean(placement_score), min(placement_score), max(placement_score));
fprintf('获奖情况评分: 均值=%.2f, 范围=[%.2f, %.2f]\n', ...
        mean(winner_score), min(winner_score), max(winner_score));
fprintf('综合评分: 均值=%.2f, 范围=[%.2f, %.2f]\n', ...
        mean(composite_score), min(composite_score), max(composite_score));

%% 6. 计算各地区综合评分
region_popularity = grpstats(T, 'region', {'mean', 'std', 'median', 'min', 'max'}, 'DataVars', 'composite_score');
region_popularity.count = grpstats(T.composite_score, T.region, @length);

% 按综合评分排序（评分越高，越受欢迎）
if any(strcmp(region_popularity.Properties.VariableNames, 'mean_composite_score'))
    region_popularity = sortrows(region_popularity, 'mean_composite_score', 'descend');
else
    mean_cols = region_popularity.Properties.VariableNames(contains(region_popularity.Properties.VariableNames, 'mean'));
    if ~isempty(mean_cols)
        region_popularity = sortrows(region_popularity, mean_cols{1}, 'descend');
    end
end

fprintf('\n===== 各地区受欢迎程度排名（基于综合评分）=====\n');
fprintf('评分标准: 标准化位次(40%%) + 获奖情况(40%%) + 排名评分(20%%)\n');
fprintf('排名 | 地区 | 综合评分 | 中位数 | 参赛人数 | 标准差\n');
fprintf('-----|------|----------|--------|----------|--------\n');

for i = 1:min(15, height(region_popularity))
    fprintf('%4d. %-15s: %.1f分 (中位数:%.1f, 人数:%2d, 标准差:%.2f)\n', ...
            i, region_popularity.region{i}, region_popularity.mean_composite_score(i), ...
            region_popularity.median_composite_score(i), region_popularity.count(i), ...
            region_popularity.std_composite_score(i));
end

%% 7. 可视化结果
figure('Position', [100, 100, 1400, 600], 'Name', '地区与最终位次关系分析');

% 子图1: 各地区平均位次（水平条形图）
subplot(2, 3, 1);
barh(region_stats.mean_placement(end:-1:1));
set(gca, 'YTickLabel', region_stats.region(end:-1:1));
xlabel('平均位次（越低越好）');
title('各地区选手平均位次');
grid on;

% 子图2: 各地区受欢迎程度评分（水平条形图）
subplot(2, 3, 2);
barh(region_popularity.mean_composite_score(end:-1:1));
set(gca, 'YTickLabel', region_popularity.region(end:-1:1));
xlabel('综合评分（越高越受欢迎）');
title('各地区受欢迎程度评分');
grid on;

% 子图3: 各地区参赛人数分布（条形图）
subplot(2, 3, 3);
[~, idx] = sort(region_stats.count, 'descend');
bar(region_stats.count(idx));
set(gca, 'XTick', 1:length(idx));
set(gca, 'XTickLabel', region_stats.region(idx), 'XTickLabelRotation', 45);
ylabel('参赛人数');
title('各地区参赛人数分布');
grid on;

% 子图4: 平均位次 vs 参赛人数（散点图）
subplot(2, 3, 4);
scatter(region_stats.count, region_stats.mean_placement, 50, 'filled');
xlabel('参赛人数');
ylabel('平均位次');
title('参赛人数 vs 平均位次');
grid on;

% 添加地区标签
for i = 1:height(region_stats)
    text(region_stats.count(i), region_stats.mean_placement(i), ...
         region_stats.region{i}, 'FontSize', 8, 'HorizontalAlignment', 'center');
end

% 子图5: 综合评分分布（箱线图）
subplot(2, 3, 5);
boxplot_data = [];
group_labels = {};
for i = 1:min(8, height(region_popularity))  % 显示前8个地区
    region_name = region_popularity.region{i};
    region_scores = T.composite_score(strcmp(T.region, region_name));
    boxplot_data = [boxplot_data; region_scores];
    group_labels = [group_labels; repmat({region_name}, length(region_scores), 1)];
end
if ~isempty(boxplot_data)
    boxplot(boxplot_data, group_labels);
    set(gca, 'XTickLabelRotation', 45);
    ylabel('综合评分');
    title('各地区综合评分分布（前8名）');
    grid on;
else
    title('综合评分分布（无数据）');
end

% 子图6: 地区表现稳定性（标准差越小越稳定）
subplot(2, 3, 6);
stability_stats = grpstats(T, 'region', 'std', 'DataVars', 'placement');
[~, idx] = sort(stability_stats.std_placement);
bar(stability_stats.std_placement(idx));
set(gca, 'XTick', 1:length(idx));
set(gca, 'XTickLabel', stability_stats.region(idx), 'XTickLabelRotation', 45);
ylabel('位次标准差');
title('各地区表现稳定性（标准差越小越稳定）');
grid on;

% 调整图形
sgtitle('地区与最终位次关系综合分析', 'FontSize', 14, 'FontWeight', 'bold');

%% 8. 深入分析：地区在顶级名次中的表现
fprintf('\n===== 各地区在顶级名次中的表现 =====\n');

% 统计各地区获得不同名次的次数
nRegions = height(region_popularity);
top_counts = struct();
top_counts.champion = zeros(nRegions, 1);
top_counts.top3 = zeros(nRegions, 1);
top_counts.top5 = zeros(nRegions, 1);
top_counts.top10 = zeros(nRegions, 1);

for i = 1:nRegions
    region_name = region_popularity.region{i};
    region_data = T(strcmp(T.region, region_name), :);
    top_counts.champion(i) = sum(region_data.placement == 1);
    top_counts.top3(i) = sum(region_data.placement <= 3);
    top_counts.top5(i) = sum(region_data.placement <= 5);
    top_counts.top10(i) = sum(region_data.placement <= 10);
end

% 使用 ASCII 字段名以避免编码/标识符问题
region_top_performance = table(region_popularity.region, ...
                               top_counts.champion, top_counts.top3, ...
                               top_counts.top5, top_counts.top10, ...
                               region_popularity.mean_composite_score, ...
                               region_popularity.count, ...
                               'VariableNames', {'Region', 'ChampionCount', 'Top3Count', ...
                                                 'Top5Count', 'Top10Count', 'CompositeScore', 'ParticipantCount'});

% 计算效率指标（每参赛人数的获奖数），避免除以 0
region_top_performance.ChampionEfficiency = zeros(height(region_top_performance),1);
region_top_performance.Top3Efficiency = zeros(height(region_top_performance),1);
region_top_performance.Top5Efficiency = zeros(height(region_top_performance),1);

validIdx = region_top_performance.ParticipantCount > 0;
region_top_performance.ChampionEfficiency(validIdx) = region_top_performance.ChampionCount(validIdx) ./ region_top_performance.ParticipantCount(validIdx);
region_top_performance.Top3Efficiency(validIdx) = region_top_performance.Top3Count(validIdx) ./ region_top_performance.ParticipantCount(validIdx);
region_top_performance.Top5Efficiency(validIdx) = region_top_performance.Top5Count(validIdx) ./ region_top_performance.ParticipantCount(validIdx);

% 按综合评分排序
region_top_performance = sortrows(region_top_performance, 'CompositeScore', 'descend');

fprintf('\n各地区顶级表现统计:\n');
disp(region_top_performance);

%% 9. 相关性分析
fprintf('\n===== 相关性���析 =====\n');

% 计算参赛人数与平均位次的相关性
corr_count_placement = NaN;
if length(region_stats.count) == length(region_stats.mean_placement)
    corr_count_placement = corr(region_stats.count, region_stats.mean_placement);
end
fprintf('参赛人数与平均��次的相关系数: %.3f\n', corr_count_placement);

% 计算参赛人数与综合评分的相关性
corr_count_score = NaN;
if length(region_popularity.count) == length(region_popularity.mean_composite_score)
    corr_count_score = corr(region_popularity.count, region_popularity.mean_composite_score);
end
fprintf('参赛人数与综合评分的相关系数: %.3f\n', corr_count_score);

% 计算平均位次与综合评分的相关性
corr_placement_score = NaN;
if length(region_stats.mean_placement) == length(region_popularity.mean_composite_score)
    corr_placement_score = corr(region_stats.mean_placement, region_popularity.mean_composite_score);
end
fprintf('平均位次与综合评分的相关系数: %.3f\n', corr_placement_score);

%% 10. 输出详细结果到Excel文件
fprintf('\n===== 输出分析结果 =====\n');

% 创建输出文件名
output_file = '地区分析结果.xlsx';
fprintf('正在将分析结果保存到: %s\n', output_file);

try
    % 将主要结果写入不同的工作表（sheet 名称使用 ASCII 避免编码问题）
    writetable(region_stats, output_file, 'Sheet', 'region_stats');
    writetable(region_popularity, output_file, 'Sheet', 'region_popularity');
    writetable(region_top_performance, output_file, 'Sheet', 'region_top_performance');
    writetable(T, output_file, 'Sheet', 'raw_with_scores');

    fprintf('分析结果已成功保存到 %s\n', output_file);

    % 显示文件大小
    file_info = dir(output_file);
    fprintf('输出文件大小: %.2f KB\n', file_info.bytes/1024);

catch ME
    warning('保存Excel文件时出错: %s', ME.message);
    fprintf('尝试保存为CSV文件...\n');

    % 如果Excel保存失败，尝试保存为CSV（文件名使用 ASCII）
    writetable(region_stats, 'region_stats.csv');
    writetable(region_popularity, 'region_popularity.csv');
    writetable(region_top_performance, 'region_top_performance.csv');
    writetable(T, 'raw_with_scores.csv');
    fprintf('分析结果已保存为CSV文件\n');
end

%% 11. 生成综合报告
fprintf('\n===== 分析总结报告 =====\n');

% 找出表现最好的地区（存在多种可能的列名，做兼容判断）
[~, idx_best_score] = max(region_popularity.mean_composite_score);
[~, idx_best_placement] = min(region_stats.mean_placement);
[~, idx_most_champions] = max(region_top_performance.ChampionCount);
[~, idx_most_stable] = min(stability_stats.std_placement);
[~, idx_most_participants] = max(region_stats.count);

fprintf('1. 最受欢迎地区（综合评分最高）: %s (%.1f分)\n', ...
        region_popularity.region{idx_best_score}, region_popularity.mean_composite_score(idx_best_score));
fprintf('2. 平均位次最佳地区: %s (平均位次%.2f)\n', ...
        region_stats.region{idx_best_placement}, region_stats.mean_placement(idx_best_placement));
fprintf('3. 获得冠军最多地区: %s (%d次冠军)\n', ...
        region_top_performance.Region{idx_most_champions}, region_top_performance.ChampionCount(idx_most_champions));
fprintf('4. 表现最稳定地区: %s (位次标准差%.2f)\n', ...
        stability_stats.region{idx_most_stable}, stability_stats.std_placement(idx_most_stable));
fprintf('5. 参赛人数最多地区: %s (%d人)\n', ...
        region_stats.region{idx_most_participants}, region_stats.count(idx_most_participants));

% 冠军效率（避免除以 0 或 NaN）
if region_top_performance.ChampionEfficiency(1) > 0
    fprintf('6. 冠军效率最高地区: %s (每%.2f人获得1次冠军)\n', ...
            region_top_performance.Region{1}, 1/region_top_performance.ChampionEfficiency(1));
else
    fprintf('6. 冠军效率最高地区: %s (冠军效率为 %.4f)\n', ...
            region_top_performance.Region{1}, region_top_performance.ChampionEfficiency(1));
end

fprintf('\n===== 分析完成 =====\n');
fprintf('总分析时间: %s\n', datestr(now, 'HH:MM:SS'));
fprintf('分析记录数: %d\n', height(T));
fprintf('分析地区数: %d\n', height(region_stats));

