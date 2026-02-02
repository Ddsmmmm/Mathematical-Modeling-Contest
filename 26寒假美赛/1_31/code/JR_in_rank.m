% clear;clc;close all;
% % Jerry Rice Weekly Ranking in Season 2 (MATLAB)
% weeks = 1:8;
% rank_method1 = [1, 4, 3, 2, 1, 1, 2, 3];  % 排名合并法
% rank_method2 = [1, 5, 4, 2, 1, 1, 2, 3];  % 百分比合并法
% 
% % 创建图形并设置大小（英寸）
% figure('Units','inches','Position',[1 1 10 6],'Color','w');
% 
% % 绘制两条曲线
% plot(weeks, rank_method1, '-o', 'LineWidth', 2, 'MarkerSize', 8);
% hold on;
% plot(weeks, rank_method2, '-s', 'LineWidth', 2, 'MarkerSize', 8);
% hold off;
% 
% % 标签与标题
% xlabel('Week', 'FontSize', 12);
% ylabel('Rank (lower is better)', 'FontSize', 12);
% title('Jerry Rice Weekly Ranking in Season 2', 'FontSize', 14);
% 
% % 图例
% legend({'Rank-based Method', 'Percent-based Method'}, 'FontSize', 12, 'Location', 'best');
% 
% % 网格、刻度与反转 y 轴（使第1名在顶部）
% grid on;
% set(gca, 'XTick', weeks, 'YTick', 1:5, 'YDir', 'reverse', 'FontSize', 12);
% 
% % 限制 x/y 范围（可选）
% xlim([min(weeks) max(weeks)]);
% ylim([1 5]);
% 
% % 调整绘图区边距（类似 tight_layout）
% outerpos = get(gca, 'OuterPosition');
% ti = get(gca, 'TightInset');
% left = outerpos(1) + ti(1);
% bottom = outerpos(2) + ti(2);
% ax_width = outerpos(3) - ti(1) - ti(3);
% ax_height = outerpos(4) - ti(2) - ti(4);
% set(gca, 'Position', [left bottom ax_width ax_height]);

% 清除环境
clear; clc; close all;

% -----------------------------
% Season 2 数据（仅用于 Jerry Rice 分析）
% -----------------------------
weeks = 1:8;

% 所有参赛者名称（顺序对应下面的数据行）
contestants = {
    'Kenny Mayne',
    'Tatum O''Neal',
    'Giselle Fernandez',
    'Master P',
    'Tia Carrere',
    'George Hamilton',
    'Lisa Rinna',
    'Stacy Keibler',
    'Jerry Rice',
    'Drew Lachey'
};

num_contestants = numel(contestants);

% 每周粉丝投票（每行对应一个参赛者，列对应周数 Week1..Week8）
all_fan_votes = [
    181967, 0, 0, 0, 0, 0, 0, 0;          % Kenny Mayne
    363945, 222113, 0, 0, 0, 0, 0, 0;     % Tatum O'Neal
    545112, 888912, 277935, 0, 0, 0, 0, 0;% Giselle Fernandez
    1817905, 1999956, 2222015, 356987, 0, 0, 0, 0; % Master P
    727083, 1555926, 1111028, 1786024, 476041, 0, 0, 0; % Tia Carrere
    1091107, 1332974, 1666963, 2499962, 2381082, 667041, 0, 0; % George Hamilton
    1273105, 1777963, 1389017, 1071043, 1905032, 2666987, 999986, 0; % Lisa Rinna
    1455093, 444011, 555987, 1429021, 952087, 1333028, 2999978, 1666974; % Stacy Keibler
    1635942, 1110973, 1944011, 2143025, 2857092, 3333024, 4000047, 5000033; % Jerry Rice
    908841, 667072, 833044, 714029, 1428912, 1999999, 2000119, 3332993 % Drew Lachey
];

% 每周评委总分（每行对应一个参赛者，列对应周数 Week1..Week8）
all_judge_scores = [
    13, 0, 0, 0, 0, 0, 0, 0;      % Kenny Mayne
    29, 17, 0, 0, 0, 0, 0, 0;     % Tatum O'Neal
    23, 24, 22, 0, 0, 0, 0, 0;    % Giselle Fernandez
    12, 16, 14, 8, 0, 0, 0, 0;    % Master P
    20, 22, 26, 25, 22, 0, 0, 0;  % Tia Carrere
    18, 22, 22, 21, 24, 23, 0, 0; % George Hamilton
    19, 20, 25, 26, 25, 27, 26.5, 0; % Lisa Rinna
    22, 29, 27, 26, 30, 30, 40, 30; % Stacy Keibler
    21, 23, 19, 24, 23, 23, 20.5, 26.6666; % Jerry Rice
    24, 27, 27, 28, 27, 30, 27.5, 29 % Drew Lachey
];

% 我们只关心 Jerry Rice 的排名变化（在每周剩余参赛者中的排名，1 为最好）
target_name = 'Jerry Rice';

% -----------------------------
% 辅助函数说明（实现逻辑）
% - 每种方法各运行两次模拟：
%   A) 基础版：按合并排名/合并百分比直接淘汰合并分最低（或合并百分比最低）
%   B) 评委选择版：先按合并排名/合并百分比找出末位两名，再在这两名中依据评委（或评委百分比）较差者被淘汰
% - 每周都记录 Jerry 在“当前剩余参赛者”中的名次（1..nRemaining）
% - 前 7 周执行淘汰，第 8 周为决赛（不再淘汰）
% -----------------------------

% 预分配用于存储结果
jerry_rank_method1_baseline = zeros(1, numel(weeks));
jerry_rank_method1_judgevariant = zeros(1, numel(weeks));
jerry_rank_method2_baseline = zeros(1, numel(weeks));
jerry_rank_method2_judgevariant = zeros(1, numel(weeks));

%% 方法1：排名合并计分法（rank-based）
% 模拟 A: 基础淘汰（每周淘汰合并排名最差者）
remaining = true(num_contestants,1);
for w = weeks
    % 当前剩余参赛者的票数和评分
    cur_votes = all_fan_votes(remaining, w);
    cur_judge = all_judge_scores(remaining, w);
    names_remaining = contestants(remaining);
    
    % 若只剩下参赛者少于1个，退出
    if isempty(cur_votes)
        jerry_rank_method1_baseline(w) = NaN;
        continue;
    end
    
    % 计算粉丝排名（1 为最高）
    [~, idx_fan] = sort(cur_votes, 'descend');
    fan_ranks = zeros(sum(remaining),1);
    fan_ranks(idx_fan) = 1:length(idx_fan);
    
    % 计算评委排名（1 为最高）
    [~, idx_judge] = sort(cur_judge, 'descend');
    judge_ranks = zeros(sum(remaining),1);
    judge_ranks(idx_judge) = 1:length(idx_judge);
    
    % 合并排名（数值越小越好）
    combined = fan_ranks + judge_ranks;
    
    % 计算当前 Jerry 的排名（在剩余参赛者中的名次）
    jerry_loc = find(strcmp(names_remaining, target_name), 1);
    if ~isempty(jerry_loc)
        % 将 combined 转换为名次（1 为最好）
        [~, order] = sort(combined, 'ascend');
        rank_vector = zeros(size(combined));
        rank_vector(order) = 1:length(order);
        jerry_rank_method1_baseline(w) = rank_vector(jerry_loc);
    else
        jerry_rank_method1_baseline(w) = NaN;
    end
    
    % 执行淘汰（前7周淘汰一名）
    if w < weeks(end) && sum(remaining) > 1
        % 找到合并排名最差（数值最大）的其中一个（若并列取第一个出现）
        worst_pos = find(combined == max(combined), 1, 'first');
        % 将全局索引标记为已淘汰
        global_indices = find(remaining);
        remaining(global_indices(worst_pos)) = false;
    end
end

% 模拟 B: 评委选择版（在合并排名末位两名中由评委决定淘汰）
remaining = true(num_contestants,1);
for w = weeks
    cur_votes = all_fan_votes(remaining, w);
    cur_judge = all_judge_scores(remaining, w);
    names_remaining = contestants(remaining);
    
    if isempty(cur_votes)
        jerry_rank_method1_judgevariant(w) = NaN;
        continue;
    end
    
    % 计算粉丝排名和评委排名（1 为最好）
    [~, idx_fan] = sort(cur_votes, 'descend');
    fan_ranks = zeros(sum(remaining),1);
    fan_ranks(idx_fan) = 1:length(idx_fan);
    
    [~, idx_judge] = sort(cur_judge, 'descend');
    judge_ranks = zeros(sum(remaining),1);
    judge_ranks(idx_judge) = 1:length(idx_judge);
    
    combined = fan_ranks + judge_ranks;
    
    % 记录 Jerry 排名
    jerry_loc = find(strcmp(names_remaining, target_name), 1);
    if ~isempty(jerry_loc)
        [~, order] = sort(combined, 'ascend');
        rank_vector = zeros(size(combined));
        rank_vector(order) = 1:length(order);
        jerry_rank_method1_judgevariant(w) = rank_vector(jerry_loc);
    else
        jerry_rank_method1_judgevariant(w) = NaN;
    end
    
    % 淘汰规则：找到合并排名最差的两名，再由评委排名（数字大为差）决定淘汰者
    if w < weeks(end) && sum(remaining) > 1
        % 从大到小排序取末位两名
        [~, sorted_desc] = sort(combined, 'descend'); % 从差到好
        bottom_two = sorted_desc(1:min(2, length(sorted_desc)));
        
        if numel(bottom_two) == 1
            to_elim_local = bottom_two(1);
        else
            % 在 bottom_two 中评委排名（数字越大越差）
            bottom_judge_ranks = judge_ranks(bottom_two);
            % 评委排名数字越大表示评委排序越靠后，取最大者淘汰
            [~, worst_idx_rel] = max(bottom_judge_ranks);
            to_elim_local = bottom_two(worst_idx_rel);
        end
        
        global_indices = find(remaining);
        remaining(global_indices(to_elim_local)) = false;
    end
end

%% 方法2：百分比合并法（percentage-based）
% 模拟 A: 基础淘汰（按合并百分比最低淘汰）
remaining = true(num_contestants,1);
for w = weeks
    cur_votes = all_fan_votes(remaining, w);
    cur_judge = all_judge_scores(remaining, w);
    names_remaining = contestants(remaining);
    
    if isempty(cur_votes)
        jerry_rank_method2_baseline(w) = NaN;
        continue;
    end
    
    % 计算百分比（占当前剩余参赛者总和的百分比）
    % 若总和为0（理论上不应发生），则用零避免除以0
    sum_votes = sum(cur_votes);
    sum_judge = sum(cur_judge);
    if sum_votes == 0, fan_pct = zeros(size(cur_votes)); else fan_pct = cur_votes / sum_votes * 100; end
    if sum_judge == 0, judge_pct = zeros(size(cur_judge)); else judge_pct = cur_judge / sum_judge * 100; end
    
    combined_pct = fan_pct + judge_pct; % 越大越好
    
    % 计算排名（1 为最好）
    [~, sorted_desc] = sort(combined_pct, 'descend');
    rank_vector = zeros(length(combined_pct),1);
    rank_vector(sorted_desc) = 1:length(sorted_desc);
    
    jerry_loc = find(strcmp(names_remaining, target_name), 1);
    if ~isempty(jerry_loc)
        jerry_rank_method2_baseline(w) = rank_vector(jerry_loc);
    else
        jerry_rank_method2_baseline(w) = NaN;
    end
    
    % 淘汰最低合并百分比者（前7周）
    if w < weeks(end) && sum(remaining) > 1
        % 找到合并百分比最小的其中一个
        [~, worst_local] = min(combined_pct);
        global_indices = find(remaining);
        remaining(global_indices(worst_local)) = false;
    end
end

% 模拟 B: 评委百分比较差者在 bottom two 中被淘汰（按百分比）
remaining = true(num_contestants,1);
for w = weeks
    cur_votes = all_fan_votes(remaining, w);
    cur_judge = all_judge_scores(remaining, w);
    names_remaining = contestants(remaining);
    
    if isempty(cur_votes)
        jerry_rank_method2_judgevariant(w) = NaN;
        continue;
    end
    
    sum_votes = sum(cur_votes);
    sum_judge = sum(cur_judge);
    if sum_votes == 0, fan_pct = zeros(size(cur_votes)); else fan_pct = cur_votes / sum_votes * 100; end
    if sum_judge == 0, judge_pct = zeros(size(cur_judge)); else judge_pct = cur_judge / sum_judge * 100; end
    
    combined_pct = fan_pct + judge_pct;
    
    % 排名（1 为最好）
    [~, sorted_desc] = sort(combined_pct, 'descend');
    rank_vector = zeros(length(combined_pct),1);
    rank_vector(sorted_desc) = 1:length(sorted_desc);
    
    jerry_loc = find(strcmp(names_remaining, target_name), 1);
    if ~isempty(jerry_loc)
        jerry_rank_method2_judgevariant(w) = rank_vector(jerry_loc);
    else
        jerry_rank_method2_judgevariant(w) = NaN;
    end
    
    % 淘汰规则：合并百分比最小的两名中，评委百分比较小（更差）者被淘汰
    if w < weeks(end) && sum(remaining) > 1
        [~, sorted_asc] = sort(combined_pct, 'ascend'); % ���小到大
        bottom_two = sorted_asc(1:min(2, length(sorted_asc)));
        
        if numel(bottom_two) == 1
            to_elim_local = bottom_two(1);
        else
            bottom_judge_pct = judge_pct(bottom_two);
            % 评委百分比越小表示评委更不支持，淘汰百分比更小者
            [~, worst_idx_rel] = min(bottom_judge_pct);
            to_elim_local = bottom_two(worst_idx_rel);
        end
        
        global_indices = find(remaining);
        remaining(global_indices(to_elim_local)) = false;
    end
end

%% 绘图：两幅图，每幅图对应1个方法，图上有两条折线（基础版 + 评委选择版）
% 为了视觉一致性，将纵轴范围设为 1..num_contestants，反转 Y 轴（1 在顶部）
ymin = 1;
ymax = num_contestants;

% 方法1 图
figure('Name','Rank-Based Method (Method 1)','NumberTitle','off','Color','w');
plot(weeks, jerry_rank_method1_baseline, '-o', 'LineWidth', 2, 'MarkerSize', 8); hold on;
plot(weeks, jerry_rank_method1_judgevariant, '--s', 'LineWidth', 2, 'MarkerSize', 8);
grid on;
xlabel('Week', 'FontSize', 12);
ylabel('Rank (lower is better)', 'FontSize', 12);
title('Jerry Rice Weekly Rank - Rank-Based Method', 'FontSize', 14);
legend({'Rank-based elimination', 'Rank-based + judge choice from bottom two'}, 'Location', 'best');
set(gca, 'XTick', weeks, 'YTick', ymin:1:ymax, 'YDir', 'reverse', 'FontSize', 11);
ylim([ymin ymax]);
xlim([weeks(1) weeks(end)]);
% 数据标签
for i = 1:length(weeks)
    if ~isnan(jerry_rank_method1_baseline(i))
        text(weeks(i), jerry_rank_method1_baseline(i), sprintf(' %d', jerry_rank_method1_baseline(i)), ...
            'VerticalAlignment','bottom','HorizontalAlignment','left','FontSize',9);
    end
    if ~isnan(jerry_rank_method1_judgevariant(i))
        text(weeks(i), jerry_rank_method1_judgevariant(i), sprintf(' %d', jerry_rank_method1_judgevariant(i)), ...
            'VerticalAlignment','top','HorizontalAlignment','right','FontSize',9);
    end
end
hold off;

% 方法2 图
figure('Name','Percentage-Based Method (Method 2)','NumberTitle','off','Color','w');
plot(weeks, jerry_rank_method2_baseline, '-o', 'LineWidth', 2, 'MarkerSize', 8); hold on;
plot(weeks, jerry_rank_method2_judgevariant, '--s', 'LineWidth', 2, 'MarkerSize', 8);
grid on;
xlabel('Week', 'FontSize', 12);
ylabel('Rank (lower is better)', 'FontSize', 12);
title('Jerry Rice Weekly Rank - Percentage-Based Method', 'FontSize', 14);
legend({'Percentage-based elimination', 'Percentage-based + judge choice from bottom two'}, 'Location', 'best');
set(gca, 'XTick', weeks, 'YTick', ymin:1:ymax, 'YDir', 'reverse', 'FontSize', 11);
ylim([ymin ymax]);
xlim([weeks(1) weeks(end)]);
% 数据标签
for i = 1:length(weeks)
    if ~isnan(jerry_rank_method2_baseline(i))
        text(weeks(i), jerry_rank_method2_baseline(i), sprintf(' %d', jerry_rank_method2_baseline(i)), ...
            'VerticalAlignment','bottom','HorizontalAlignment','left','FontSize',9);
    end
    if ~isnan(jerry_rank_method2_judgevariant(i))
        text(weeks(i), jerry_rank_method2_judgevariant(i), sprintf(' %d', jerry_rank_method2_judgevariant(i)), ...
            'VerticalAlignment','top','HorizontalAlignment','right','FontSize',9);
    end
end
hold off;

%% 控制台输出（可选）：打印每周 Jerry 的排名
fprintf('Week\tMethod1\tMethod1+Judge\tMethod2\tMethod2+Judge\n');
for w = weeks
    fprintf('%d\t\t%d\t\t%d\t\t%d\t\t%d\n', w, ...
        jerry_rank_method1_baseline(w), jerry_rank_method1_judgevariant(w), ...
        jerry_rank_method2_baseline(w), jerry_rank_method2_judgevariant(w));
end