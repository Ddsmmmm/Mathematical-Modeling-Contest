%% 清理工作区
clear; clc; close all;

%% 导入Excel数据
filename = '2026_MCM_Problem_C_Data.xlsx';
data = readtable(filename, 'Sheet', '2026_MCM_Problem_C_Data');

%% 提取伴舞列并统计
partner_column = data.ballroom_partner;

% 删除缺失值
valid_indices = ~ismissing(partner_column);
valid_partners = partner_column(valid_indices);

% 统计每个伴舞出现的次数
[unique_partners, ~, idx] = unique(valid_partners);
partner_counts = accumarray(idx, 1);  % 统计每个唯一值出现的次数

% 按出现次数降序排序
[partner_counts_sorted, sort_idx] = sort(partner_counts, 'descend');
unique_partners_sorted = unique_partners(sort_idx);

%% 创建结果表格
result_table = table(unique_partners_sorted, partner_counts_sorted, ...
    'VariableNames', {'Ballroom_Partner', 'Appearance_Count'});

%% 输出结果
fprintf('===== 伴舞出现次数统计 =====\n');
fprintf('总伴舞人数: %d\n', height(result_table));
fprintf('总出现次数: %d\n\n', sum(partner_counts_sorted));

% 显示前20名
top_n = min(20, height(result_table));
fprintf('出现次数最多的前%d名伴舞:\n', top_n);
disp(result_table(1:top_n, :));

% 显示所有结果（可选）
fprintf('\n全部伴舞统计结果:\n');
disp(result_table);

%% 保存结果到Excel文件
output_filename = 'ballroom_partner_counts.xlsx';
writetable(result_table, output_filename);
fprintf('\n统计结果已保存到: %s\n', output_filename);

%% 可视化结果（可选）
figure;
top_partners = result_table.Ballroom_Partner(1:10);
top_counts = result_table.Appearance_Count(1:10);

barh(top_counts);
set(gca, 'YTickLabel', top_partners);
xlabel('出现次数');
ylabel('伴舞姓名');
title('伴舞出现次数排名（前10名）');
grid on;

%% 统计概览
fprintf('\n===== 统计概览 =====\n');
fprintf('出现次数最多的伴舞: %s (%d次)\n', ...
    char(unique_partners_sorted(1)), partner_counts_sorted(1));
fprintf('出现次数最少的伴舞: %s (%d次)\n', ...
    char(unique_partners_sorted(end)), partner_counts_sorted(end));
fprintf('平均出现次数: %.2f次\n', mean(partner_counts_sorted));
fprintf('出现次数中位数: %.0f次\n', median(partner_counts_sorted));
fprintf('出现次数标准差: %.2f次\n', std(partner_counts_sorted));