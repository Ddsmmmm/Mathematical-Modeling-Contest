% 第二赛季名次计算程序（修正版）
% 本脚本基于你提供的原始脚本进行修改，修正与增强点包括：
% - 修复 fprintf 表头与参数数量不匹配的问题（列对齐）
% - 使用动态 n_elims = n_weeks-1，避免 magic number
% - 把自定义 extractAfter 重命名为 local_extractAfter，避免与 MATLAB 内置冲突
% - 为淘汰/最终排名添加并列 (tie) 处理策略（明确的 tie-break）
%   - 排名制 (rank-based)：combined_ranks 最大者淘汰；并列时先比较 judge_ranks（越大越差），再比较 fan_ranks
%   - 百分比制 (percent-based)：combined_percent 最小者淘汰；并列时先比较 judge_percent（越小越差），再比较 fan_percent
% - 增加输入数据维度断言，增加浮点比较容差（tol）
% - 对输出宽度/分隔线长度统一到 100 列，提升可读性
% - 若需要，我在代码中添加了注释说明关键修改点
%
% 你可以直接运行此脚本（MATLAB R2015+ 应兼容；若你使用较新版本可以改回内置 extractAfter）

clear; clc; close all;

%% 1. 数据准备 - 第二赛季选手数据

% 选手名称（按粉丝投票表顺序）
contestants = {
    'Kenny Mayne', 'Tatum O''Neal', 'Giselle Fernandez', 'Master P', ...
    'Tia Carrere', 'George Hamilton', 'Lisa Rinna', 'Stacy Keibler', ...
    'Jerry Rice', 'Drew Lachey'
};

% 实际淘汰结果（用于验证）
actual_elimination = {
    'Week 1: Kenny Mayne',
    'Week 2: Tatum O''Neal', 
    'Week 3: Giselle Fernandez',
    'Week 4: Master P',
    'Week 5: Tia Carrere',
    'Week 6: George Hamilton',
    'Week 7: Lisa Rinna'
};

actual_final_ranking = {
    '1st: Drew Lachey',
    '2nd: Jerry Rice', 
    '3rd: Stacy Keibler',
    '4th: Lisa Rinna',
    '5th: George Hamilton',
    '6th: Tia Carrere',
    '7th: Master P',
    '8th: Giselle Fernandez',
    '9th: Tatum O''Neal',
    '10th: Kenny Mayne'
};

%% 2. 粉丝投票数据（从Excel表中获取）
% Week1-Week8的粉丝投票数
fan_votes = [
    181967, 0, 0, 0, 0, 0, 0, 0;               % Kenny Mayne
    363945, 222113, 0, 0, 0, 0, 0, 0;          % Tatum O'Neal
    545112, 888912, 277935, 0, 0, 0, 0, 0;     % Giselle Fernandez
    1817905, 1999956, 2222015, 356987, 0, 0, 0, 0; % Master P
    727083, 1555926, 1111028, 1786024, 476041, 0, 0, 0; % Tia Carrere
    1091107, 1332974, 1666963, 2499962, 2381082, 667041, 0, 0; % George Hamilton
    1273105, 1777963, 1389017, 1071043, 1905032, 2666987, 999986, 0; % Lisa Rinna
    1455093, 444011, 555987, 1429021, 952087, 1333028, 2999978, 1666974; % Stacy Keibler
    1635942, 1110973, 1944011, 2143025, 2857092, 3333024, 4000047, 5000033; % Jerry Rice
    908841, 667072, 833044, 714029, 1428912, 1999999, 2000119, 3332993  % Drew Lachey
];

%% 3. 评委打分数据
judge_scores = [
    13, 0, 0, 0, 0, 0, 0, 0;               % Kenny Mayne
    23, 17, 0, 0, 0, 0, 0, 0;              % Tatum O'Neal
    23, 24, 22, 0, 0, 0, 0, 0;             % Giselle Fernandez
    12, 16, 14, 8, 0, 0, 0, 0;             % Master P
    20, 22, 26, 25, 22, 0, 0, 0;           % Tia Carrere
    18, 22, 22, 21, 24, 23, 0, 0;          % George Hamilton
    19, 20, 25, 26, 25, 27, 26.5, 0;       % Lisa Rinna
    22, 29, 27, 26, 30, 30, 27.5, 28.6665; % Stacy Keibler
    21, 23, 19, 24, 23, 23, 20.5, 26.6666; % Jerry Rice
    24, 27, 27, 28, 27, 30, 27.5, 29       % Drew Lachey
];

n_contestants = length(contestants);
n_weeks = 8;
n_elims = n_weeks - 1;  % 每赛季前 n_weeks-1 周淘汰一人

% 容差（浮点并列判定）
tol = 1e-8;

% 数据维度检查（鲁棒性）
assert(size(judge_scores,1) == n_contestants && size(fan_votes,1) == n_contestants, ...
    'judge_scores / fan_votes 行数应与 contestants 数量一致');
assert(size(judge_scores,2) == n_weeks && size(fan_votes,2) == n_weeks, ...
    'judge_scores / fan_votes 列数应等于 n_weeks');

%% 4. 排名制计算方法（Seasons 1, 2, 28-34使用）
fprintf('==================== 排名制计算结果 ====================\n');
fprintf('(按排名和决定，排名和最小的选手获胜，最大的被淘汰)\n\n');

rank_based_eliminated = cell(n_elims, 1);  % 存储每周淘汰的选手
rank_based_active = true(n_contestants, 1);  % 标记选手是否还在比赛中
rank_based_final_ranking = cell(n_contestants, 1);

for week = 1:n_weeks
    % 找出本周还在比赛的选手
    active_idx = find(rank_based_active);
    
    if isempty(active_idx)
        break;
    end
    
    % 获取本周数据
    week_judge_scores = judge_scores(active_idx, week);
    week_fan_votes = fan_votes(active_idx, week);
    active_contestants = contestants(active_idx);
    
    % 计算评委排名（分数越高排名越好，排名数字越小）
    % 如果某些分数为 NaN/0，根据 sort 规则处理
    [~, judge_rank_idx] = sort(week_judge_scores, 'descend');
    judge_ranks = zeros(length(active_idx), 1);
    judge_ranks(judge_rank_idx) = 1:length(active_idx);
    
    % 计算粉丝排名（票数越高排名越好，排名数字越小）
    [~, fan_rank_idx] = sort(week_fan_votes, 'descend');
    fan_ranks = zeros(length(active_idx), 1);
    fan_ranks(fan_rank_idx) = 1:length(active_idx);
    
    % 计算综合排名（排名和）
    combined_ranks = judge_ranks + fan_ranks;
    
    % 显示本周结果（列数与格式化字符串保持一致）
    fprintf('Week %d 结果:\n', week);
    fprintf('%-25s %-12s %-12s %-12s %-12s %-12s\n', ...
        '选手', '评委分数', '评委排名', '粉丝票数', '粉丝排名', '综合排名');
    fprintf('%s\n', repmat('-', 1, 100));
    
    for i = 1:length(active_idx)
        fprintf('%-25s %-12.1f %-12d %-12d %-12d %-12d\n', ...
            active_contestants{i}, ...
            week_judge_scores(i), ...
            judge_ranks(i), ...
            week_fan_votes(i), ...
            fan_ranks(i), ...
            combined_ranks(i));
    end
    
    % 如果是第8周（决赛周），不淘汰，只排名
    if week == n_weeks
        fprintf('\n>>> 第8周为决赛周，不淘汰选手，最终排名如下:\n');
        
        % 根据综合排名确定最终名次（排名和最小的为冠军）
        % 为了处理并列，使用复合排序键：先 combined_ranks（升序），再 judge_ranks（升序），再 fan_ranks（升序）
        T = table(combined_ranks, judge_ranks, fan_ranks, (1:length(combined_ranks))', ...
            'VariableNames', {'combined','judge','fan','idx'});
        T = sortrows(T, {'combined','judge','fan'});  % 都越小越好
        final_order = T.idx;
        
        for i = 1:length(final_order)
            rank_text = '';
            if i == 1, rank_text = '冠军 (1st)';
            elseif i == 2, rank_text = '亚军 (2nd)';
            elseif i == 3, rank_text = '季军 (3rd)';
            else, rank_text = sprintf('第%d名', i);
            end
            
            rank_based_final_ranking{i} = sprintf('%s: %s', rank_text, active_contestants{final_order(i)});
            fprintf('%s\n', rank_based_final_ranking{i});
        end
    else
        % 找出综合排名最大的选手（表现最差）进行淘汰
        max_val = max(combined_ranks);
        % 并列候选
        cands = find(abs(combined_ranks - max_val) < tol | combined_ranks == max_val);
        if numel(cands) > 1
            % tie-break: 先看评委排名（judge_ranks），评委排名越大表示越差
            judge_vals = judge_ranks(cands);
            max_judge = max(judge_vals);
            cands_judge = cands(abs(judge_vals - max_judge) < tol | judge_vals == max_judge);
            if numel(cands_judge) == 1
                eliminate_idx = cands_judge(1);
            else
                % 再用粉丝排名（fan_ranks，越大越差）
                fan_vals = fan_ranks(cands_judge);
                max_fan = max(fan_vals);
                cands_fan = cands_judge(abs(fan_vals - max_fan) < tol | fan_vals == max_fan);
                % 若仍并列，则取第一个（或你可以定义其他规则）
                eliminate_idx = cands_fan(1);
            end
        else
            eliminate_idx = cands(1);
        end
        
        eliminated_contestant = active_contestants{eliminate_idx};
        
        fprintf('\n>>> 本周被淘汰: %s (综合排名: %d)\n', eliminated_contestant, max_val);
        
        % 标记该选手为淘汰
        original_idx = active_idx(eliminate_idx);
        rank_based_active(original_idx) = false;
        rank_based_eliminated{week} = sprintf('Week %d: %s', week, eliminated_contestant);
    end
    
    fprintf('\n%s\n\n', repmat('=', 1, 100));
end

%% 5. 百分比制计算方法（Seasons 3-27使用）
fprintf('\n\n==================== 百分比制计算结果 ====================\n');
fprintf('(按百分比和决定，百分比和最高的选手获胜，最低的被淘汰)\n\n');

percent_based_eliminated = cell(n_elims, 1);  % 存储每周淘汰的选手
percent_based_active = true(n_contestants, 1);  % 标记选手是否还在比赛中
percent_based_final_ranking = cell(n_contestants, 1);

for week = 1:n_weeks
    % 找出本周还在比赛的选手
    active_idx = find(percent_based_active);
    
    if isempty(active_idx)
        break;
    end
    
    % 获取本周数据
    week_judge_scores = judge_scores(active_idx, week);
    week_fan_votes = fan_votes(active_idx, week);
    active_contestants = contestants(active_idx);
    
    % 计算评委百分比（每个选手的分数占总分的比例）
    judge_total = sum(week_judge_scores);
    if judge_total > 0
        judge_percent = (week_judge_scores / judge_total) * 100;
    else
        judge_percent = zeros(size(week_judge_scores));
    end
    
    % 计算粉丝百分比（每个选手的票数占总票数的比例）
    fan_total = sum(week_fan_votes);
    if fan_total > 0
        fan_percent = (week_fan_votes / fan_total) * 100;
    else
        fan_percent = zeros(size(week_fan_votes));
    end
    
    % 计算综合百分比
    combined_percent = judge_percent + fan_percent;
    
    % 显示本周结果
    fprintf('Week %d 结果:\n', week);
    fprintf('%-25s %-12s %-14s %-12s %-14s %-14s\n', ...
        '选手', '评委分数', '评委百分比%', '粉丝票数', '粉丝百分比%', '综合百分比%');
    fprintf('%s\n', repmat('-', 1, 100));
    
    for i = 1:length(active_idx)
        fprintf('%-25s %-12.1f %-14.2f %-12d %-14.2f %-14.2f\n', ...
            active_contestants{i}, ...
            week_judge_scores(i), ...
            judge_percent(i), ...
            week_fan_votes(i), ...
            fan_percent(i), ...
            combined_percent(i));
    end
    
    % 如果是第8周（决赛周），不淘汰，只排名
    if week == n_weeks
        fprintf('\n>>> 第8周为决赛周，不淘汰选手，最终排名如下:\n');
        
        % 根据综合百分比确定最终名次（百分比和最高的为冠军）
        % 处理并列：先按 combined_percent 降序，再 judge_percent 降序，再 fan_percent 降序
        T = table(combined_percent, judge_percent, fan_percent, (1:length(combined_percent))', ...
            'VariableNames', {'combined','judge','fan','idx'});
        T = sortrows(T, {'combined','judge','fan'}, {'descend','descend','descend'});
        final_order = T.idx;
        
        for i = 1:length(final_order)
            rank_text = '';
            if i == 1, rank_text = '冠军 (1st)';
            elseif i == 2, rank_text = '亚军 (2nd)';
            elseif i == 3, rank_text = '季军 (3rd)';
            else, rank_text = sprintf('第%d名', i);
            end
            
            percent_based_final_ranking{i} = sprintf('%s: %s', rank_text, active_contestants{final_order(i)});
            fprintf('%s\n', percent_based_final_ranking{i});
        end
    else
        % 找出综合百分比最小的选手（表现最差）进行淘汰
        min_val = min(combined_percent);
        cands = find(abs(combined_percent - min_val) < tol | combined_percent == min_val);
        if numel(cands) > 1
            % tie-break: 先比较 judge_percent（越小越差）
            judge_vals = judge_percent(cands);
            min_judge = min(judge_vals);
            cands_judge = cands(abs(judge_vals - min_judge) < tol | judge_vals == min_judge);
            if numel(cands_judge) == 1
                eliminate_idx = cands_judge(1);
            else
                % 再比较 fan_percent（越小越差）
                fan_vals = fan_percent(cands_judge);
                min_fan = min(fan_vals);
                cands_fan = cands_judge(abs(fan_vals - min_fan) < tol | fan_vals == min_fan);
                eliminate_idx = cands_fan(1);
            end
        else
            eliminate_idx = cands(1);
        end
        
        eliminated_contestant = active_contestants{eliminate_idx};
        
        fprintf('\n>>> 本周被淘汰: %s (综合百分比: %.2f%%)\n', eliminated_contestant, min_val);
        
        % 标记该选手为淘汰
        original_idx = active_idx(eliminate_idx);
        percent_based_active(original_idx) = false;
        percent_based_eliminated{week} = sprintf('Week %d: %s', week, eliminated_contestant);
    end
    
    fprintf('\n%s\n\n', repmat('=', 1, 100));
end

%% 6. 结果对比
fprintf('\n\n==================== 结果对比 ====================\n');

fprintf('\n实际淘汰顺序:\n');
for i = 1:length(actual_elimination)
    fprintf('%s\n', actual_elimination{i});
end

fprintf('\n排名制淘汰顺序:\n');
for i = 1:length(rank_based_eliminated)
    if ~isempty(rank_based_eliminated{i})
        fprintf('%s\n', rank_based_eliminated{i});
    end
end

fprintf('\n百分比制淘汰顺序:\n');
for i = 1:length(percent_based_eliminated)
    if ~isempty(percent_based_eliminated{i})
        fprintf('%s\n', percent_based_eliminated{i});
    end
end

fprintf('\n实际最终排名:\n');
for i = 1:length(actual_final_ranking)
    fprintf('%s\n', actual_final_ranking{i});
end

fprintf('\n排名制最终排名:\n');
for i = 1:length(rank_based_final_ranking)
    if ~isempty(rank_based_final_ranking{i})
        fprintf('%s\n', rank_based_final_ranking{i});
    end
end

fprintf('\n百分比制最终排名:\n');
for i = 1:length(percent_based_final_ranking)
    if ~isempty(percent_based_final_ranking{i})
        fprintf('%s\n', percent_based_final_ranking{i});
    end
end

%% 7. 一致性分析
fprintf('\n\n==================== 一致性分析 ====================\n');

% 检查淘汰顺序是否匹配
rank_match_count = 0;
percent_match_count = 0;

for i = 1:length(actual_elimination)
    actual = actual_elimination{i};
    
    if i <= length(rank_based_eliminated) && ~isempty(rank_based_eliminated{i})
        rank_based = rank_based_eliminated{i};
        % 提取选手名字进行比较
        actual_name = local_extractAfter(actual, ': ');
        rank_name = local_extractAfter(rank_based, ': ');
        
        if strcmp(actual_name, rank_name)
            rank_match_count = rank_match_count + 1;
        end
    end
    
    if i <= length(percent_based_eliminated) && ~isempty(percent_based_eliminated{i})
        percent_based = percent_based_eliminated{i};
        percent_name = local_extractAfter(percent_based, ': ');
        actual_name = local_extractAfter(actual, ': ');
        
        if strcmp(actual_name, percent_name)
            percent_match_count = percent_match_count + 1;
        end
    end
end

fprintf('排名制与实际结果匹配度: %d/%d (%.1f%%)\n', ...
    rank_match_count, length(actual_elimination), ...
    rank_match_count/length(actual_elimination)*100);

fprintf('百分比制与实际结果匹配度: %d/%d (%.1f%%)\n', ...
    percent_match_count, length(actual_elimination), ...
    percent_match_count/length(actual_elimination)*100);

% 检查最终排名前三名是否匹配
actual_top3 = {'Drew Lachey', 'Jerry Rice', 'Stacy Keibler'};

% 提取排名制前三名
rank_top3 = cell(3, 1);
for i = 1:3
    if i <= length(rank_based_final_ranking) && ~isempty(rank_based_final_ranking{i})
        rank_str = rank_based_final_ranking{i};
        rank_top3{i} = local_extractAfter(rank_str, ': ');
    else
        rank_top3{i} = '';
    end
end

% 提取百分比制前三名
percent_top3 = cell(3, 1);
for i = 1:3
    if i <= length(percent_based_final_ranking) && ~isempty(percent_based_final_ranking{i})
        percent_str = percent_based_final_ranking{i};
        percent_top3{i} = local_extractAfter(percent_str, ': ');
    else
        percent_top3{i} = '';
    end
end

fprintf('\n最终排名前三名对比:\n');
fprintf('实际结果: 1. %s, 2. %s, 3. %s\n', actual_top3{1}, actual_top3{2}, actual_top3{3});
fprintf('排名制:   1. %s, 2. %s, 3. %s\n', rank_top3{1}, rank_top3{2}, rank_top3{3});
fprintf('百分比制: 1. %s, 2. %s, 3. %s\n', percent_top3{1}, percent_top3{2}, percent_top3{3});

%% 8. Jerry Rice案例分析（第二赛季争议选手）
fprintf('\n\n==================== Jerry Rice案例分析 ====================\n');
fprintf('Jerry Rice在第二赛季中获得亚军，尽管在5周中评委分数最低\n');

% 找出Jerry Rice的索引
jerry_idx = find(strcmp(contestants, 'Jerry Rice'));

fprintf('\nJerry Rice每周表现:\n');
fprintf('%-10s %-12s %-12s %-15s %-15s\n', 'Week', '评委分数', '评委排名', '粉丝票数', '粉丝排名');
fprintf('%s\n', repmat('-', 1, 70));

for week = 1:n_weeks
    % 模拟第week周时还在比赛的选手（基于实际淘汰顺序 actual_elimination）
    active_in_week = true(n_contestants, 1);
    
    for w = 1:week-1
        if w <= length(actual_elimination)
            elim_name = local_extractAfter(actual_elimination{w}, ': ');
            elim_idx = find(strcmp(contestants, elim_name));
            if ~isempty(elim_idx)
                active_in_week(elim_idx) = false;
            end
        end
    end
    
    % 获取本周数据
    week_judge = judge_scores(:, week);
    week_fan = fan_votes(:, week);
    
    % 计算本周排名（仅对 active 选手）
    active_idx = find(active_in_week);
    active_judge = week_judge(active_in_week);
    active_fan = week_fan(active_in_week);
    
    % 评委排名
    [~, judge_rank_idx] = sort(active_judge, 'descend');
    judge_ranks_curr = zeros(length(active_idx), 1);
    judge_ranks_curr(judge_rank_idx) = 1:length(active_idx);
    
    % 粉丝排名
    [~, fan_rank_idx] = sort(active_fan, 'descend');
    fan_ranks_curr = zeros(length(active_idx), 1);
    fan_ranks_curr(fan_rank_idx) = 1:length(active_idx);
    
    % 找到Jerry Rice在活跃选手中的位置
    jerry_active_pos = find(active_idx == jerry_idx);
    
    if ~isempty(jerry_active_pos)
        fprintf('%-10d %-12.1f %-12d %-15d %-15d\n', ...
            week, week_judge(jerry_idx), judge_ranks_curr(jerry_active_pos), ...
            week_fan(jerry_idx), fan_ranks_curr(jerry_active_pos));
    end
end

fprintf('\n分析: Jerry Rice的粉丝支持率很高，这解释了为什么他能进入决赛\n');
fprintf('尽管评委分数较低，但粉丝投票使他能够继续留在比赛中。\n');

%% 辅助函数
function result = local_extractAfter(str, pattern)
    % 从字符串中提取指定模式后的部分（兼容 char 向量）
    % 如果找不到 pattern，则返回原始字符串（trim 后）
    if isempty(str)
        result = '';
        return;
    end
    idx = strfind(str, pattern);
    if ~isempty(idx)
        result = strtrim(str(idx(1)+length(pattern):end));
    else
        result = strtrim(str);
    end
end


