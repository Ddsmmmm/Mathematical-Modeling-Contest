%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% DWTS Season 27 - Elimination Probability Heatmap (统一格式版)
clear; clc; close all;

%% 参赛者名单（与粉丝投票表顺序一致）
contestants = {
    'Nikki Glaser';
    'Danelle Umstead';
    'Nancy McKeon';
    'John Schneider';
    'Mary Lou Retton';
    'Juan Pablo Di Pace';
    'DeMarcus Ware';
    'Tinashe';
    'Evanna Lynch';
    'Alexis Ren';
    'Milo Manheim';
    'Joe Amabile';
    'Bobby Bones'
};

weeks_labels = {'Week 1', 'Week 2', 'Week 3', 'Week 4', 'Week 5', 'Week 6', 'Week 7', 'Week 8', 'Week 9'};

%% 从CSV文件中读取第27季的数据
filename = '2026_MCM_Problem_C_Data.csv';
opts = detectImportOptions(filename);
opts.VariableTypes(:) = {'char'}; % 全部读为字符串以处理N/A
dataTable = readtable(filename, opts);

% 提取第27季数据
season_col = str2double(dataTable.season);
season27_idx = find(season_col == 27);
names = dataTable.celebrity_name(season27_idx);

% 确保顺序与contestants列表一致
[~, idx_in_data] = ismember(contestants, names);
if any(idx_in_data == 0)
    error('有些参赛者在CSV中未找到');
end
season27_idx = season27_idx(idx_in_data);

num_contestants = length(contestants);
num_weeks = 9;

%% 提取评委评分
judge_scores = zeros(num_contestants, num_weeks);
for w = 1:num_weeks
    judge_cols = cell(1,4);
    for j = 1:4
        judge_cols{j} = sprintf('week%d_judge%d_score', w, j);
    end
    
    for c = 1:num_contestants
        row_idx = season27_idx(c);
        total_score = 0;
        count = 0;
        for j = 1:4
            col_name = judge_cols{j};
            if ismember(col_name, dataTable.Properties.VariableNames)
                val_str = dataTable.(col_name){row_idx};
                if ~isempty(val_str) && ~strcmpi(val_str, 'N/A')
                    val = str2double(val_str);
                    if ~isnan(val)
                        total_score = total_score + val;
                        count = count + 1;
                    end
                end
            end
        end
        judge_scores(c, w) = total_score;
    end
end

%% 粉丝投票数据
fan_votes = [
    30036, 0, 0, 0, 0, 0, 0, 0, 0;
    250253, 99965, 0, 0, 0, 0, 0, 0, 0;
    350701, 349968, 50024, 0, 0, 0, 0, 0, 0;
    450803, 449985, 500121, 550105, 549902, 549918, 300102, 0, 0;
    550904, 549985, 600146, 650114, 649902, 299973, 0, 0, 0;
    651006, 649985, 700170, 750124, 749902, 749918, 850234, 399978, 0;
    751107, 749985, 800195, 850133, 849902, 849918, 399976, 0, 0;
    851209, 849985, 900219, 250038, 0, 0, 0, 0, 0;
    951310, 949985, 1000244, 1050152, 1049902, 1049918, 1150391, 1999890, 1999980;
    1051412, 1049985, 1100268, 1150171, 1149902, 1149918, 1250391, 1999890, 1499985;
    1151513, 1149985, 1200293, 1250190, 1249902, 1249918, 1350391, 2099878, 2499975;
    1251615, 1249985, 1250317, 1300209, 1299902, 1299918, 1400391, 499972, 0;
    1701936, 1799887, 1899807, 2149757, 2449687, 2799619, 3299323, 2999391, 3999998
];

%% 计算淘汰概率
elimination_prob = zeros(num_contestants, num_weeks);
c_factor = 2; % softmax缩放因子

for w = 1:num_weeks
    active_idx = fan_votes(:, w) > 0;
    if sum(active_idx) == 0
        continue;
    end
    
    judge_active = judge_scores(active_idx, w);
    fan_active = fan_votes(active_idx, w);
    
    % 计算百分比
    total_judge = sum(judge_active);
    total_fan = sum(fan_active);
    
    if total_judge == 0
        judge_perc = zeros(size(judge_active));
    else
        judge_perc = judge_active / total_judge;
    end
    
    if total_fan == 0
        fan_perc = zeros(size(fan_active));
    else
        fan_perc = fan_active / total_fan;
    end
    
    combined = judge_perc + fan_perc;
    
    % softmax计算淘汰概率
    prob_active = exp(-c_factor * combined) / sum(exp(-c_factor * combined));
    
    elimination_prob(active_idx, w) = prob_active;
end

% 将0概率设为NaN（显示为白色）
display_mat = elimination_prob;
mask_no_data = (elimination_prob == 0);
display_mat(mask_no_data) = NaN;

%% 确定每周实际被淘汰的参赛者
% 根据粉丝投票数据：当选手从某周开始投票为0，则表示在前一周被淘汰
% 冠军(Bobby Bones)从未被淘汰
actual_eliminations = zeros(num_contestants, 2); % 记录实际淘汰的位置
elim_count = 0;

% 遍历每个选手
for i = 1:num_contestants
    % 找到第一个投票为0的周（除了第一周）
    for w = 2:num_weeks
        if fan_votes(i, w) == 0 && fan_votes(i, w-1) > 0
            % 该选手在第w-1周被淘汰
            elim_count = elim_count + 1;
            actual_eliminations(elim_count, 1) = i;
            actual_eliminations(elim_count, 2) = w-1;
            break;
        end
    end
end

% 特殊处理：Nikki Glaser在第1周被淘汰
elim_count = elim_count + 1;
actual_eliminations(elim_count, 1) = 1;
actual_eliminations(elim_count, 2) = 1;

% 只保留实际有淘汰记录的行
actual_eliminations = actual_eliminations(1:elim_count, :);

% 显示实际淘汰信息
fprintf('第27季实际淘汰情况:\n');
for i = 1:size(actual_eliminations, 1)
    row = actual_eliminations(i, 1);
    col = actual_eliminations(i, 2);
    fprintf('  %s 在第%d周被淘汰\n', contestants{row}, col);
end

%% 输入检查
[nR, nC] = size(elimination_prob);
assert(length(contestants) == nR, 'contestants数目与概率矩阵行数不一致');
assert(length(weeks_labels) == nC, 'weeks数目与概率矩阵列数不一致');

%% 自定义colormap（红→黄，与第一幅图一致）
n_colors = 256;
custom_map = [ones(n_colors,1), linspace(0,1,n_colors)', zeros(n_colors,1)];

%% 绘图（与第一幅图格式相同）
fig = figure('Position', [120, 120, 900, 620], 'Color', 'w');

% 使用imagesc，并利用AlphaData屏蔽NaN单元格
h = imagesc(display_mat, 'AlphaData', ~isnan(display_mat));
colormap(custom_map);
c = colorbar;

maxVal = max(elimination_prob(:));
caxis([0, maxVal]);
set(c, 'FontSize', 10);

% 强制坐标轴刻度颜色为黑色
set(gca, 'XColor', 'k', 'YColor', 'k');

% 坐标轴标签（颜色设为黑色）
xlabel('Week', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
ylabel('Contestant', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');

% 坐标轴标签设置
set(gca, 'XTick', 1:nC, 'XTickLabel', weeks_labels, 'TickLength', [0 0], 'FontSize', 10);
set(gca, 'YTick', 1:nR, 'YTickLabel', contestants);
set(gca, 'Layer', 'top'); % 确保网格/线在顶部可以看见

% 使单元格显示为正方形
axis equal tight;

% 标题（颜色设为黑色）
title('DWTS Season 27: Elimination Probability Heatmap', ...
    'FontSize', 14, 'FontWeight', 'bold', 'Color', 'k');

% 添加网格线（用线段绘制，能与imagesc配合更好）
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
        val = elimination_prob(i,j);
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

%% 标注实际被淘汰单元格（黑色虚线方框，与第一幅图相同）
for k = 1:size(actual_eliminations, 1)
    row = actual_eliminations(k,1);
    col = actual_eliminations(k,2);
    rectangle('Position', [col-0.5, row-0.5, 1, 1], ...
        'EdgeColor', 'k', 'LineStyle', '--', 'LineWidth', 1.8);
end

% 添加说明文本（放在图外，黑色，与第一幅图一致）
annotation('textbox', [0.02, 0.02, 0.4, 0.05], 'String', ...
    '', ...
    'EdgeColor', 'none', 'Color', 'k', 'FontSize', 10, 'FontWeight', 'normal');

% Colorbar标签与刻度文字设置为黑色
c.Label.String = 'Elimination Probability';
c.Label.FontSize = 11;
c.Label.FontWeight = 'bold';
c.Label.Color = 'k';
set(c, 'Color', 'k');

% 最后微调交互（防止标签被裁剪）
set(gca, 'Position', [0.12, 0.12, 0.78, 0.80]);