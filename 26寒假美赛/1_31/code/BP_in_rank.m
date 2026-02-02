% Bristol Palin 排名与绘图（输出排名结果并保存）
% - 计算四种情景下 Bristol Palin 每周排名并绘图：
%   A) 排名合并法：简单淘汰 vs 末位两名中评委排名较差者淘汰（同图两条线）
%   B) 百分比合并法：简单淘汰 vs 末位两名中评委百分比较差者淘汰（同图两条线）
% - 将结果显示为表格并保存为 CSV/XLSX/MAT

clear; clc; close all;

% 数据定义
names = {'Jennifer Grey';'Kyle Massey';'Bristol Palin';'Brandy';'Kurt Warner';'Rick Fox';'Audrina Patridge';'Florence Henderson';'The Situation';'Margaret Cho';'Michael Bolton';'David Hasselhoff'};
num_contestants = 12;
weeks = 10;

% 粉丝投票数矩阵（行：名人，列：周）
fan_votes = [
1811320, 1759000, 1705000, 2261000, 1940000, 1871000, 2214000, 2565000, 2999000, 3924000;
1591190, 1478000, 1498000, 1480000, 1423000, 1774000, 1863000, 2310000, 2657000, 3278000;
1132080, 1344000, 1125000, 1077000, 1164000, 1505000, 1643000, 1762000, 2207000, 2798000;
1301890, 1155000, 1279000, 1454000, 1572000, 1742000, 1661000, 1924000, 2137000, 0;
955970, 1026000, 1089000, 915000, 1242000, 946000, 1416000, 1440000, 0, 0;
968550, 898000, 995000, 919000, 1087000, 1129000, 1203000, 0, 0, 0;
716980, 843000, 924000, 929000, 893000, 1032000, 0, 0, 0, 0;
566040, 580000, 592000, 589000, 679000, 0, 0, 0, 0, 0;
377360, 440000, 474000, 377000, 0, 0, 0, 0, 0, 0;
283020, 330000, 320000, 0, 0, 0, 0, 0, 0, 0;
201260, 147000, 0, 0, 0, 0, 0, 0, 0, 0;
94340, 0, 0, 0, 0, 0, 0, 0, 0, 0
];

% 评委总分矩阵（行：名人，列：周）
judge_scores = zeros(num_contestants, weeks);
judge_scores(1,:) = [24, 24, 24, 28, 25, 29, 36.5, 28.5, 30, 30];         % Jennifer Grey
judge_scores(2,:) = [23, 22, 23, 20, 20, 30, 33.5, 28, 29, 27.3332];     % Kyle Massey
judge_scores(3,:) = [18, 22, 19, 16, 18, 28, 32.5, 23.5, 26.5, 25.6666];  % Bristol Palin
judge_scores(4,:) = [23, 21, 24, 24, 27, 36, 36.5, 28.5, 28.5, 0];       % Brandy
judge_scores(5,:) = [19, 21, 23, 17, 24, 22, 35, 24, 0, 0];               % Kurt Warner
judge_scores(6,:) = [22, 21, 24, 19.5, 24, 30, 34.5, 0, 0, 0];           % Rick Fox
judge_scores(7,:) = [19, 23, 26, 23, 23, 32, 0, 0, 0, 0];                % Audrina
judge_scores(8,:) = [18, 19, 20, 17.5, 21, 0, 0, 0, 0, 0];               % Florence
judge_scores(9,:) = [15, 18, 20, 14, 0, 0, 0, 0, 0, 0];                  % The Situation
judge_scores(10,:) = [15, 18, 18, 0, 0, 0, 0, 0, 0, 0];                  % Margaret Cho
judge_scores(11,:) = [16, 12, 0, 0, 0, 0, 0, 0, 0, 0];                   % Michael Bolton
judge_scores(12,:) = [15, 0, 0, 0, 0, 0, 0, 0, 0, 0];                    % David Hasselhoff

% Bristol Palin 的索引
bp_idx = 3;

% 初始化结果（用 NaN 表示该周已不在比赛或无排名）
rank_rank_simple = NaN(1, weeks);      % 排名合并 - 简单淘汰
rank_rank_bottom2 = NaN(1, weeks);     % 排名合并 - 末位两名中评委较差淘汰
percent_simple = NaN(1, weeks);        % 百分比合并 - 简单淘汰
percent_bottom2 = NaN(1, weeks);       % 百分比合并 - 末位两名中评委百分比较差淘汰

% （可选）记录每周被淘汰者姓名，便于检查
elim_rank_simple = cell(1, weeks);
elim_rank_bottom2 = cell(1, weeks);
elim_percent_simple = cell(1, weeks);
elim_percent_bottom2 = cell(1, weeks);

%% 方法1: 排名合并，简单淘汰（每周淘汰综合最差一人）
remaining = 1:num_contestants;
for week = 1:weeks
    if isempty(remaining)
        break;
    end
    curr_judge = judge_scores(remaining, week);
    curr_fan = fan_votes(remaining, week);
    
    % 评委排名（分数高者名次靠前）
    [~, judge_rank_idx] = sort(curr_judge, 'descend');
    judge_rank = zeros(length(remaining),1);
    for i = 1:length(remaining)
        judge_rank(judge_rank_idx(i)) = i;
    end
    
    % 粉丝排名（票数高者名次靠前）
    [~, fan_rank_idx] = sort(curr_fan, 'descend');
    fan_rank = zeros(length(remaining),1);
    for i = 1:length(remaining)
        fan_rank(fan_rank_idx(i)) = i;
    end
    
    combined_rank = judge_rank + fan_rank; % 数值越小越好
    
    % 记录 Bristol 的当周排名（如果仍在比赛中）
    bp_pos = find(remaining == bp_idx);
    if isempty(bp_pos)
        rank_rank_simple(week) = NaN;
    else
        [~, order] = sort(combined_rank, 'ascend');
        rank_rank_simple(week) = find(order == bp_pos, 1);
    end
    
    % 淘汰（仅当剩余>1）
    if length(remaining) > 1
        maxv = max(combined_rank);
        candidates = find(combined_rank == maxv); % 并列时可能有多个
        if numel(candidates) > 1
            % 在并列者中按评委排名（数值越大评委越差）选最差者
            [~, worst_rel] = max(judge_rank(candidates));
            elim_rel = candidates(worst_rel);
        else
            elim_rel = candidates(1);
        end
        elim_global_idx = remaining(elim_rel);
        elim_rank_simple{week} = names{elim_global_idx};
        remaining(elim_rel) = [];
    else
        elim_rank_simple{week} = '';
    end
end

%% 方法2: 排名合并，末位两名中评委排名较差者淘汰
remaining = 1:num_contestants;
for week = 1:weeks
    if isempty(remaining)
        break;
    end
    curr_judge = judge_scores(remaining, week);
    curr_fan = fan_votes(remaining, week);
    
    [~, judge_rank_idx] = sort(curr_judge, 'descend');
    judge_rank = zeros(length(remaining),1);
    for i = 1:length(remaining)
        judge_rank(judge_rank_idx(i)) = i;
    end
    
    [~, fan_rank_idx] = sort(curr_fan, 'descend');
    fan_rank = zeros(length(remaining),1);
    for i = 1:length(remaining)
        fan_rank(fan_rank_idx(i)) = i;
    end
    
    combined_rank = judge_rank + fan_rank;
    
    bp_pos = find(remaining == bp_idx);
    if isempty(bp_pos)
        rank_rank_bottom2(week) = NaN;
    else
        [~, order] = sort(combined_rank, 'ascend');
        rank_rank_bottom2(week) = find(order == bp_pos, 1);
    end
    
    % 淘汰：取综合最差的最多两人，在两人中按评委排名差者淘汰
    if length(remaining) > 1
        [~, idx_desc] = sort(combined_rank, 'descend'); % 从差到好
        bottom_cnt = min(2, length(idx_desc));
        bottom_two_rel = idx_desc(1:bottom_cnt);
        if bottom_cnt == 1
            elim_rel = bottom_two_rel(1);
        else
            % 比较这两人的 judge_rank（数值越大评委越差）
            if judge_rank(bottom_two_rel(1)) > judge_rank(bottom_two_rel(2))
                elim_rel = bottom_two_rel(1);
            elseif judge_rank(bottom_two_rel(1)) < judge_rank(bottom_two_rel(2))
                elim_rel = bottom_two_rel(2);
            else
                elim_rel = bottom_two_rel(1);
            end
        end
        elim_global_idx = remaining(elim_rel);
        elim_rank_bottom2{week} = names{elim_global_idx};
        remaining(elim_rel) = [];
    else
        elim_rank_bottom2{week} = '';
    end
end

%% 方法3: 百分比合并，简单淘汰
remaining = 1:num_contestants;
for week = 1:weeks
    if isempty(remaining)
        break;
    end
    curr_judge = judge_scores(remaining, week);
    curr_fan = fan_votes(remaining, week);
    
    if sum(curr_judge) == 0
        judge_percent = zeros(size(curr_judge));
    else
        judge_percent = curr_judge / sum(curr_judge);
    end
    if sum(curr_fan) == 0
        fan_percent = zeros(size(curr_fan));
    else
        fan_percent = curr_fan / sum(curr_fan);
    end
    
    combined_percent = judge_percent + fan_percent; % 数值越大越好
    
    bp_pos = find(remaining == bp_idx);
    if isempty(bp_pos)
        percent_simple(week) = NaN;
    else
        [~, order] = sort(combined_percent, 'descend');
        percent_simple(week) = find(order == bp_pos, 1);
    end
    
    % 淘汰：综合百分比最小者（并列按 judge_percent 最小者）
    if length(remaining) > 1
        minv = min(combined_percent);
        candidates = find(combined_percent == minv);
        if numel(candidates) > 1
            [~, worst_rel] = min(judge_percent(candidates));
            elim_rel = candidates(worst_rel);
        else
            elim_rel = candidates(1);
        end
        elim_global_idx = remaining(elim_rel);
        elim_percent_simple{week} = names{elim_global_idx};
        remaining(elim_rel) = [];
    else
        elim_percent_simple{week} = '';
    end
end

%% 方法4: 百分比合并，末位两名中评委百分比较差者淘汰
remaining = 1:num_contestants;
for week = 1:weeks
    if isempty(remaining)
        break;
    end
    curr_judge = judge_scores(remaining, week);
    curr_fan = fan_votes(remaining, week);
    
    if sum(curr_judge) == 0
        judge_percent = zeros(size(curr_judge));
    else
        judge_percent = curr_judge / sum(curr_judge);
    end
    if sum(curr_fan) == 0
        fan_percent = zeros(size(curr_fan));
    else
        fan_percent = curr_fan / sum(curr_fan);
    end
    
    combined_percent = judge_percent + fan_percent;
    
    bp_pos = find(remaining == bp_idx);
    if isempty(bp_pos)
        percent_bottom2(week) = NaN;
    else
        [~, order] = sort(combined_percent, 'descend');
        percent_bottom2(week) = find(order == bp_pos, 1);
    end
    
    % 淘汰：综合百分比最小的两名中评委百分比较小者淘汰
    if length(remaining) > 1
        [~, idx_asc] = sort(combined_percent, 'ascend'); % 越小越差
        bottom_cnt = min(2, length(idx_asc));
        bottom_two_rel = idx_asc(1:bottom_cnt);
        if bottom_cnt == 1
            elim_rel = bottom_two_rel(1);
        else
            if judge_percent(bottom_two_rel(1)) < judge_percent(bottom_two_rel(2))
                elim_rel = bottom_two_rel(1);
            elseif judge_percent(bottom_two_rel(1)) > judge_percent(bottom_two_rel(2))
                elim_rel = bottom_two_rel(2);
            else
                elim_rel = bottom_two_rel(1);
            end
        end
        elim_global_idx = remaining(elim_rel);
        elim_percent_bottom2{week} = names{elim_global_idx};
        remaining(elim_rel) = [];
    else
        elim_percent_bottom2{week} = '';
    end
end

%% 准备并显示/保存结果表格
Weeks = (1:weeks)';
T_rank = table(Weeks, rank_rank_simple', rank_rank_bottom2', 'VariableNames', ...
    {'Week','Rank_Rank_Simple','Rank_Rank_Bottom2'});
T_percent = table(Weeks, percent_simple', percent_bottom2', 'VariableNames', ...
    {'Week','Rank_Percent_Simple','Rank_Percent_Bottom2'});

disp('--- 排名合并法（Rank combination） Bristol Palin 每周排名 ---');
disp(T_rank);
disp('--- 百分比合并法（Percent combination） Bristol Palin 每周排名 ---');
disp(T_percent);

% 保存结果
try
    writetable(T_rank, 'Bristol_Rank_Combination_Ranks.csv');
    writetable(T_percent, 'Bristol_Percent_Combination_Ranks.csv');
    writetable(T_rank, 'Bristol_Rank_Combination_Ranks.xlsx');
    writetable(T_percent, 'Bristol_Percent_Combination_Ranks.xlsx');
    save('Bristol_Rank_Results.mat', 'T_rank', 'T_percent', ...
         'elim_rank_simple', 'elim_rank_bottom2', 'elim_percent_simple', 'elim_percent_bottom2', ...
         'rank_rank_simple','rank_rank_bottom2','percent_simple','percent_bottom2');
    fprintf('结果已保存为 CSV/XLSX/MAT（工作目录下）。\n');
catch ME
    warning('保存文件时出错：%s', ME.message);
end

%% 绘图：排名合并法（两条折线）
figure('Name','Rank Combination - Bristol Palin','NumberTitle','off','Position',[100 100 900 450]);
plot(1:weeks, rank_rank_simple, '-o', 'LineWidth', 2, 'MarkerSize', 8); hold on;
plot(1:weeks, rank_rank_bottom2, '-s', 'LineWidth', 2, 'MarkerSize', 8);
xlabel('Week','FontSize',12); ylabel('Rank (lower is better)','FontSize',12);
title('Bristol Palin 排名 — 排名合并法','FontSize',14);
legend('Simple elimination (淘汰综合最差)','Bottom2 elimination (末位两名中评委较差者)','Location','best');
grid on;
xlim([1 weeks]);
% 设置 y 轴范围基于非 NaN 值
yvals = [rank_rank_simple(~isnan(rank_rank_simple)), rank_rank_bottom2(~isnan(rank_rank_bottom2))];
if isempty(yvals)
    ylim([0 1]);
else
    ylim([0 max(yvals)+1]);
end

%% 绘图：百分比合并法（两条折线）
figure('Name','Percent Combination - Bristol Palin','NumberTitle','off','Position',[150 150 900 450]);
plot(1:weeks, percent_simple, '-o', 'LineWidth', 2, 'MarkerSize', 8); hold on;
plot(1:weeks, percent_bottom2, '-s', 'LineWidth', 2, 'MarkerSize', 8);
xlabel('Week','FontSize',12); ylabel('Rank (lower is better)','FontSize',12);
title('Bristol Palin 排名 — 百分比合并法','FontSize',14);
legend('Simple elimination (淘汰综合百分比最低)','Bottom2 elimination (末位两名中评委百分比较差者)','Location','best');
grid on;
xlim([1 weeks]);
yvals2 = [percent_simple(~isnan(percent_simple)), percent_bottom2(~isnan(percent_bottom2))];
if isempty(yvals2)
    ylim([0 1]);
else
    ylim([0 max(yvals2)+1]);
end

% End of script