% compute_season27_rankings.m
% 计算第27赛季（season 27）排名：排名制 (rank method) 与 百分比制 (percent method)
% 需要文件：2026_MCM_Problem_C_Data.csv（在当前工作目录或给出绝对路径）
clearvars; close all; clc;

% ---------------------------
% 1) 粉丝投票数（第27赛季），从你提供的数据硬编码进来
% 名单与每周票数（Week1..Week9）
names = { ...
    'Nikki Glaser'; ...
    'Danelle Umstead'; ...
    'Nancy McKeon'; ...
    'John Schneider'; ...
    'Mary Lou Retton'; ...
    'Juan Pablo Di Pace'; ...
    'DeMarcus Ware'; ...
    'Tinashe'; ...
    'Evanna Lynch'; ...
    'Alexis Ren'; ...
    'Milo Manheim'; ...
    'Joe Amabile'; ...
    'Bobby Bones' ...
    };

votes = [ ...
    30036,     0,       0,       0,       0,       0,       0,       0,       0;       % Nikki Glaser
    250253,  99965,     0,       0,       0,       0,       0,       0,       0;       % Danelle Umstead
    350701, 349968,  50024,      0,       0,       0,       0,       0,       0;       % Nancy McKeon
    450803, 449985, 500121, 550105, 549902, 549918, 300102,      0,       0;       % John Schneider
    550904, 549985, 600146, 650114, 649902, 299973,      0,      0,       0;       % Mary Lou Retton
    651006, 649985, 700170, 750124, 749902, 749918, 850234, 399978,      0;       % Juan Pablo Di Pace
    751107, 749985, 800195, 850133, 849902, 849918, 399976,      0,       0;       % DeMarcus Ware
    851209, 849985, 900219, 250038,      0,       0,       0,       0,       0;       % Tinashe
    951310, 949985,1000244,1050152,1049902,1049918,1150391,1999890,2199980;       % Evanna Lynch
   1051412,1049985,1100268,1150171,1149902,1149918,1250391,1999890,1299985;       % Alexis Ren
   1151513,1149985,1200293,1250190,1249902,1249918,1350391,2099878,2499975;       % Milo Manheim
   1251615,1249985,1250317,1300209,1299902,1299918,1400391, 499972,      0;       % Joe Amabile
   1701936,1799887,1899807,2149757,2449687,2799619,3299323,2999391,3999998        % Bobby Bones
    ];

% 计算粉丝总票数
fan_total = sum(votes, 2);

% ---------------------------
% 2) 从 CSV 读取评委分数并过滤 season == 27
csvfile = '2026_MCM_Problem_C_Data.csv';
if ~isfile(csvfile)
    error('找不到 CSV 文件：%s 。请把 2026_MCM_Problem_C_Data.csv 放在当前目录或修改路径。', csvfile);
end

% 读取表格，把 'N/A' 视为缺失值
opts = detectImportOptions(csvfile,'TreatAsMissing','N/A');
% 强制某些列读为 numeric（通常 detectImportOptions 会自动推断）
T = readtable(csvfile, opts);

% 检查 season 列是否存在并为数值
if ~any(strcmpi(T.Properties.VariableNames,'season'))
    error('CSV 中没有名为 ''season'' 的列。请确认 CSV 格式正确。');
end

% 找到 season==27 的所有行（但我们只关心我们在 names 列表中的选手）
season_idx = T.season == 27;

T27 = T(season_idx, :);

% 找到所有以 'week' 且包含 'judge' 的列名（例如 week1_judge1_score）
allVars = T27.Properties.VariableNames;
judgeCols = false(size(allVars));
for i=1:numel(allVars)
    v = allVars{i};
    if startsWith(v,'week','IgnoreCase',true) && contains(v,'judge','IgnoreCase',true)
        judgeCols(i) = true;
    end
end
judgeColNames = allVars(judgeCols);

if isempty(judgeColNames)
    error('没有在 CSV 中找到任何 judge 列（week*_judge*_score）。请确认 CSV 列名格式。');
end

% 将 judge 列转为 numeric matrix（如果表中已经是 numeric，则直接使用）
% 有可能某些列为 cell，因为存在 N/A 字符串。下面统一转换，非数值 -> NaN
judgeMat = nan(height(T27), numel(judgeColNames));
for j=1:numel(judgeColNames)
    col = T27.(judgeColNames{j});
    if isnumeric(col)
        judgeMat(:,j) = col;
    elseif iscell(col)
        % cell array: try to convert each cell to number
        for r=1:height(T27)
            val = col{r};
            if isnumeric(val)
                judgeMat(r,j) = val;
            elseif ischar(val) || isstring(val)
                num = str2double(strrep(string(val),"",""));
                judgeMat(r,j) = num;
            else
                judgeMat(r,j) = NaN;
            end
        end
    else
        % other types: try double conversion
        judgeMat(:,j) = double(col);
    end
end

% 计算每行（每位选手）评委总分：把所有 judge 列加起来，忽略 NaN
judge_total_allrows = sum(judgeMat, 2, 'omitnan');

% 把 table 中的 celebrity_name 列作为字符串 cell
if any(strcmpi(T27.Properties.VariableNames,'celebrity_name'))
    celebNamesInTable = string(T27.celebrity_name);
else
    error('CSV 中没有 celebrity_name 列。');
end

% ---------------------------
% 3) 对我们关注的第27赛季选手逐一匹配 CSV 中的行并提取 judge 总分
n = numel(names);
judge_total = zeros(n,1);
found = false(n,1);
for i=1:n
    nm = names{i};
    % 在 T27 中寻找完全匹配的 celebrity_name
    idx = find(strcmpi(strtrim(cellstr(celebNamesInTable)), strtrim(nm)), 1);
    if ~isempty(idx)
        judge_total(i) = judge_total_allrows(idx);
        found(i) = true;
    else
        % 尝试更宽松的匹配（部分匹配）
        idx2 = find(contains(lower(cellstr(celebNamesInTable)), lower(nm)));
        if ~isempty(idx2)
            idx = idx2(1);
            judge_total(i) = judge_total_allrows(idx);
            found(i) = true;
            fprintf('Warning: 对选手 "%s" 做了模糊匹配，匹配到 CSV 中的 "%s"\n', nm, char(celebNamesInTable(idx)));
        else
            % 若未找到，赋 0 并给出提示
            judge_total(i) = 0;
            found(i) = false;
            fprintf('Warning: 在 CSV(season27) 中未找到选手 "%s"，评委总分设为 0\n', nm);
        end
    end
end

% 如果某些选手未在 CSV 中找到，程序继续，但会提示
% ---------------------------
% 4) 排名制 (Rank method)
% 我们希望：名次 1 为最好（值越小越好），并对并列采用平均名次（tied ranks）
% 实现 tied rank（并列用平均名次）
functionRanks = @(x) tied_rank_desc(x);

judgeRank = functionRanks(judge_total);   % rank based on judge_total (higher -> better -> rank 1)
fanRank   = functionRanks(fan_total);     % rank based on fan_total (higher -> better -> rank 1)

combinedRankScore = judgeRank + fanRank; % 小分优先

[combinedRankSortedScore, idx_combRank] = sort(combinedRankScore, 'ascend');

% ---------------------------
% 5) 百分比制 (Percent method)
% 把 judge_total 转为占比（相对于所有选手 judge 总和）；把 fan_total 转为占比（相对于所有选手粉丝票总和）
% 合并占比：直接相加（等权）
total_judge_sum = sum(judge_total);
total_fan_sum = sum(fan_total);

% 若总和为 0（非常不可能），防止除零
if total_judge_sum == 0
    judge_percent = zeros(n,1);
else
    judge_percent = judge_total / total_judge_sum;
end
if total_fan_sum == 0
    fan_percent = zeros(n,1);
else
    fan_percent   = fan_total / total_fan_sum;
end

combined_percent = judge_percent + fan_percent; % 越大越好
[combinedPercentSorted, idx_combPercent] = sort(combined_percent, 'descend');

% ---------------------------
% 6) 输出结果（标准输出）
fprintf('\n=== 第27赛季：排名制 (Rank method) 汇总（judgeRank + fanRank，分数越小越好） ===\n');
fprintf('%3s | %-20s | %12s | %8s | %12s | %8s | %8s\n', 'Pos','Name','JudgeTotal','J_Rank','FanTotal','F_Rank','CombScore');
for r=1:n
    i = idx_combRank(r);
    fprintf('%3d | %-20s | %12.1f | %8.2f | %12.0f | %8.2f | %8.2f\n', ...
        r, names{i}, judge_total(i), judgeRank(i), fan_total(i), fanRank(i), combinedRankScore(i));
end

fprintf('\n=== 第27赛季：百分比制 (Percent method) 汇总（合并占比越大越好） ===\n');
fprintf('%3s | %-20s | %12s | %12s | %12s | %12s\n', 'Pos','Name','JudgeTotal','Judge%','FanTotal','Fan%');
for r=1:n
    i = idx_combPercent(r);
    fprintf('%3d | %-20s | %12.1f | %11.4f | %12.0f | %11.4f |  Comb%% = %6.4f\n', ...
        r, names{i}, judge_total(i), judge_percent(i), fan_total(i), fan_percent(i), combined_percent(i));
end

fprintf('\n(注：上表中 JudgeTotal、FanTotal 为该赛季累积值；Rank method 中 J_Rank/F_Rank 的并列名次使用平均名次。)\n\n');

% 如果需要也可以将结果保存为表格
T_rankMethod = table((1:n)', names, judge_total, judgeRank, fan_total, fanRank, combinedRankScore, ...
    'VariableNames', {'Pos_estimate','Name','JudgeTotal','JudgeRank','FanTotal','FanRank','CombRankScore'});
T_rankMethod = sortrows(T_rankMethod, 'CombRankScore','ascend');

T_percentMethod = table((1:n)', names, judge_total, judge_percent, fan_total, fan_percent, combined_percent, ...
    'VariableNames', {'Pos_estimate','Name','JudgeTotal','JudgePercent','FanTotal','FanPercent','CombPercent'});
T_percentMethod = sortrows(T_percentMethod, 'CombPercent','descend');

% 保存 CSV（可选）
writetable(T_rankMethod, 'season27_rankmethod_results.csv');
writetable(T_percentMethod, 'season27_percentmethod_results.csv');

fprintf('结果已写入 season27_rankmethod_results.csv 和 season27_percentmethod_results.csv（当前目录）。\n');

% ---------------------------
% --- 辅助函数：按值（越大越好）计算并列平均名次（例如 tiedrank 的降序版本）
function ranks = tied_rank_desc(vals)
    % 输入 vals 向量（数值），数值越大越好 -> 得到名次向量 ranks（1 为最好）
    % 并列时分配平均名次（例如两个并列第1名的都会给 1.5）
    v = vals(:);
    nloc = numel(v);
    % 处理 NaN：把 NaN 视为非常小（最差）
    nanmask = isnan(v);
    v(nanmask) = -Inf;
    % 对值排序（降序）
    [vs, idx] = sort(v, 'descend');
    ranks_tmp = nan(nloc,1);
    i = 1;
    while i <= nloc
        % 找出与 vs(i) 相等的群组（考虑浮点近似）
        sameIdx = find(abs(vs - vs(i)) < 1e-9);
        % sameIdx gives positions from 1..nloc; but we want contiguous group starting at i
        % find contiguous block:
        j = i;
        while j <= nloc && abs(vs(j) - vs(i)) < 1e-9
            j = j + 1;
        end
        block = i:(j-1);
        % average rank for this block (positions are 1-based)
        avgRank = mean(block);
        ranks_tmp(block) = avgRank;
        i = j;
    end
    % now put ranks_tmp back to original order
    ranks = nan(nloc,1);
    ranks(idx) = ranks_tmp;
    % values that were NaN originally should be assigned worst rank (max rank)
    if any(nanmask)
        maxRank = max(ranks(~isinf(ranks) & ~isnan(ranks)));
        % assign those NaNs to maxRank+1 (or to last ranks)
        ranks(nanmask) = maxRank + 1;
    end
end