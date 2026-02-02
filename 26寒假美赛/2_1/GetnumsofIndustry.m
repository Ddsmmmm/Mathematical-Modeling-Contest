%% 读取Excel文件
filename = '2026_MCM_Problem_C_Data.xlsx';
data = readtable(filename, 'VariableNamingRule', 'preserve');

%% 提取行业信息（第3列：celebrity_industry）
if size(data, 2) >= 3
    % 获取行业列数据
    industries = data{:, 3};
    
    % 处理缺失值
    industries(cellfun(@(x) isempty(x) || (ischar(x) && isempty(strtrim(x))) || ...
        (isstring(x) && strlength(x)==0), industries)) = {'Unknown'};
    
    % 转换为字符串类型以便处理
    if iscell(industries)
        industries = string(industries);
    end
    
    %% 统计各行业人数
    % 获取唯一行业类别
    unique_industries = unique(industries);
    
    % 统计每个行业的人数
    industry_counts = zeros(length(unique_industries), 1);
    for i = 1:length(unique_industries)
        industry_counts(i) = sum(industries == unique_industries(i));
    end
    
    %% 按人数降序排序
    [industry_counts, idx] = sort(industry_counts, 'descend');
    unique_industries = unique_industries(idx);
    
    %% 显示结果
    fprintf('========== 参赛者行业统计结果 ==========\n');
    fprintf('总参赛人数: %d\n', length(industries));
    fprintf('不同行业数量: %d\n\n', length(unique_industries));
    fprintf('%-30s %s\n', '行业', '人数');
    fprintf('%s\n', repmat('-', 50, 1));
    
    for i = 1:length(unique_industries)
        fprintf('%-30s %d\n', unique_industries(i), industry_counts(i));
    end
    
    %% 创建饼图
    figure('Position', [100, 100, 1200, 600]);
    
    % 只显示前15个行业（如果有更多），其余合并为"其他"
    if length(unique_industries) > 15
        top_industries = unique_industries(1:15);
        top_counts = industry_counts(1:15);
        other_count = sum(industry_counts(16:end));
        
        pie_labels = [top_industries; "其他"];
        pie_data = [top_counts; other_count];
    else
        pie_labels = unique_industries;
        pie_data = industry_counts;
    end
    
    subplot(1, 2, 1);
    pie(pie_data);
    title('参赛者行业分布饼图', 'FontSize', 14);
    legend(pie_labels, 'Location', 'eastoutside', 'FontSize', 9);
    
    %% 创建条形图
    subplot(1, 2, 2);
    barh(industry_counts);
    set(gca, 'YTick', 1:length(unique_industries), 'YTickLabel', unique_industries);
    xlabel('人数', 'FontSize', 12);
    title('参赛者行业分布条形图', 'FontSize', 14);
    grid on;
    
    % 调整图形美观
    set(gca, 'FontSize', 10);
    ylabel('行业', 'FontSize', 12);
    
    %% 导出统计结果到Excel
    results_table = table(unique_industries, industry_counts, ...
        'VariableNames', {'行业', '人数'});
    
    output_filename = 'industry_statistics.xlsx';
    writetable(results_table, output_filename);
    fprintf('\n统计结果已保存到: %s\n', output_filename);
    
else
    error('Excel文件中没有找到行业信息列');
end

%% 额外统计：每个行业占比
total_participants = length(industries);
percentages = (industry_counts / total_participants) * 100;

fprintf('\n========== 行业占比统计 ==========\n');
fprintf('%-30s %-10s %s\n', '行业', '人数', '占比(%)');
fprintf('%s\n', repmat('-', 60, 1));

for i = 1:min(20, length(unique_industries))  % 显示前20个行业
    fprintf('%-30s %-10d %.2f%%\n', unique_industries(i), industry_counts(i), percentages(i));
end

if length(unique_industries) > 20
    fprintf('... 还有 %d 个其他行业\n', length(unique_industries) - 20);
end