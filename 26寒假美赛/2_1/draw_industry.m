%% 行业与排名关系分析 - 简化版
clear; clc; close all;

%% 1. 读取数据
filename = '地区行业分析.xlsx';
data = readtable(filename);

% 确保数据正确读取
disp('数据前几行：');
disp(head(data));

%% 2. 基本统计信息
% 获取所有行业类别
industries = unique(data.industry_category);
fprintf('\n共有 %d 个行业类别：\n', length(industries));
disp(industries);

% 各行业参赛者数量
industry_counts = groupsummary(data, 'industry_category');
industry_counts = sortrows(industry_counts, 'GroupCount', 'descend');

fprintf('\n各行业参赛者数量：\n');
disp(industry_counts(:, {'industry_category', 'GroupCount'}));

%% 3. 计算各行业排名统计
% 初始化统计表
industry_stats = table();
industry_stats.industry_category = industries;

% 计算统计指标
for i = 1:length(industries)
    industry = industries{i};
    idx = strcmp(data.industry_category, industry);
    industry_data = data.placement(idx);
    
    industry_stats.count(i) = sum(idx);
    industry_stats.mean_rank(i) = mean(industry_data);
    industry_stats.median_rank(i) = median(industry_data);
    industry_stats.std_rank(i) = std(industry_data);
    industry_stats.min_rank(i) = min(industry_data);
    industry_stats.max_rank(i) = max(industry_data);
    
    % 计算前3名数量
    industry_stats.top3_count(i) = sum(industry_data <= 3);
    industry_stats.top3_percent(i) = industry_stats.top3_count(i) / industry_stats.count(i) * 100;
end

% 按平均排名排序（数值越小越好）
industry_stats = sortrows(industry_stats, 'mean_rank', 'ascend');

%% 4. 显示统计结果
fprintf('\n各行业排名统计分析：\n');
fprintf('%-25s %-8s %-10s %-10s %-10s %-8s %-8s\n', ...
    '行业', '人数', '平均排名', '中位数', '标准差', '前3名', '前3%');

for i = 1:height(industry_stats)
    fprintf('%-25s %-8d %-10.2f %-10.1f %-10.2f %-8d %-8.2f\n', ...
        industry_stats.industry_category{i}, ...
        industry_stats.count(i), ...
        industry_stats.mean_rank(i), ...
        industry_stats.median_rank(i), ...
        industry_stats.std_rank(i), ...
        industry_stats.top3_count(i), ...
        industry_stats.top3_percent(i));
end

%% 5. 可视化1：各行业平均排名
figure('Position', [100, 100, 1000, 500]);

subplot(1, 2, 1);
bar(industry_stats.mean_rank);
set(gca, 'XTick', 1:height(industry_stats), ...
    'XTickLabel', industry_stats.industry_category);
xtickangle(45);
ylabel('平均排名');
title('各行业平均排名（越小越好）');
grid on;

% 添加数值标签
for i = 1:height(industry_stats)
    text(i, industry_stats.mean_rank(i) + 0.5, ...
        sprintf('%.1f', industry_stats.mean_rank(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 9);
end

%% 6. 可视化2：各行业前3名比例
subplot(1, 2, 2);
bar(industry_stats.top3_percent);
set(gca, 'XTick', 1:height(industry_stats), ...
    'XTickLabel', industry_stats.industry_category);
xtickangle(45);
ylabel('前3名比例 (%)');
title('各行业获得前3名的比例');
grid on;

% 添加数值标签
for i = 1:height(industry_stats)
    text(i, industry_stats.top3_percent(i) + 1, ...
        sprintf('%.1f%%', industry_stats.top3_percent(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 9);
end

%% 7. 可视化3：箱线图展示排名分布
figure('Position', [100, 100, 1200, 600]);
boxplot(data.placement, data.industry_category);
xtickangle(45);
ylabel('排名');
title('各行业排名分布箱线图（数值越小越好）');
grid on;

%% 8. 相关性分析
% 为每个行业分配数值
[~, ~, industry_num] = unique(data.industry_category);

% 计算行业与排名的相关系数
[corr_coef, p_value] = corr(industry_num, data.placement);

fprintf('\n相关性分析：\n');
fprintf('行业与排名的相关系数: %.4f\n', corr_coef);
fprintf('p值: %.6f\n', p_value);

if p_value < 0.05
    fprintf('结论：行业与排名之间存在显著相关性 (p < 0.05)\n');
else
    fprintf('结论：行业与排名之间没有显著相关性 (p >= 0.05)\n');
end

%% 9. Kruskal-Wallis检验
fprintf('\nKruskal-Wallis检验：\n');
[p_kw, tbl, stats] = kruskalwallis(data.placement, data.industry_category, 'off');

fprintf('Kruskal-Wallis检验 p值: %.6f\n', p_kw);
if p_kw < 0.05
    fprintf('结论：不同行业的排名存在显著差异 (p < 0.05)\n');
else
    fprintf('结论：不同行业的排名没有显著差异 (p >= 0.05)\n');
end

%% 10. 找出表现最佳和最差的行业
[best_avg_rank, best_idx] = min(industry_stats.mean_rank);
best_industry = industry_stats.industry_category{best_idx};

[worst_avg_rank, worst_idx] = max(industry_stats.mean_rank);
worst_industry = industry_stats.industry_category{worst_idx};

[best_top3_percent, best_top3_idx] = max(industry_stats.top3_percent);
best_top3_industry = industry_stats.industry_category{best_top3_idx};

fprintf('\n==================== 关键发现 ====================\n');
fprintf('表现最佳的行业（平均排名最低）: %s (%.2f)\n', best_industry, best_avg_rank);
fprintf('表现最差的行业（平均排名最高）: %s (%.2f)\n', worst_industry, worst_avg_rank);
fprintf('前3名比例最高的行业: %s (%.2f%%)\n', best_top3_industry, best_top3_percent);
fprintf('=================================================\n');

%% 11. 保存结果到Excel
output_filename = '行业排名分析结果_简化版.xlsx';
writetable(industry_stats, output_filename, 'Sheet', '行业排名统计');
fprintf('\n分析结果已保存到文件: %s\n', output_filename);

%% 12. 创建总结报告
fprintf('\n==================== 总结报告 ====================\n');
fprintf('总参赛人数: %d\n', height(data));
fprintf('行业类别数: %d\n', length(industries));
fprintf('总体平均排名: %.2f\n', mean(data.placement));
fprintf('总体中位数排名: %.1f\n', median(data.placement));
fprintf('==================================================\n');
