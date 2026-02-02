% Billy Ray Cyrus — 第4赛季 每周排名绘图（修正版）
% 说明：
% - 针对之前出现所有 ranks 为 NaN 的问题做了多处鲁棒性改进：
%   1) 更稳健地处理 Excel 中的姓名（支持 char/string/missing/空）；
%   2) 规范并匹配评委列名（去空格/下划线/小写化），支持多种可能的列名格式如 "week1", "week 1", "wk1", "第1周" 等；
%   3) 若 judge_scores 完全缺失，则用 fan_votes 回退来判定参赛者最后表演周；
%   4) 更稳健地找到 Billy Ray Cyrus（忽略大小写与首尾空格）；
%   5) 淘汰逻辑在参赛者数 <=1 时不再尝试淘汰，避免索引错误。
% - 新增：输出 Billy 每周排名结果、保存为 CSV/XLSX/MAT，并打印各情景下的淘汰/存活信息。
%
% 使用方法：
% 1) 把本脚本放在与 rankofperson.xlsx 相同文件夹（或修改 filename 为完整路径）。
% 2) 在 MATLAB 中运行本脚本：run('billy_ray_ranking.m') 或 直接按 Run。

clear; clc; close all;

%% 参数（根据实际文件名/工作表名修改）
filename = 'rankofperson.xlsx';
sheet = '第4赛季';

%% 读取 Excel（readcell 返回混合类型 cell）
data = readcell(filename, 'Sheet', sheet);

%% 定位“粉丝投票”和“评委打分”区域（按原表格结构：标题，下两行是列名，第三行开始是数据）
idx_fan_title = find(cellfun(@(x) ischar(x) && strcmp(x, '第四赛季粉丝投票数') || (isstring(x) && x=="第四赛季粉丝投票数"), data(:)), 1);
if isempty(idx_fan_title)
    error('找不到标题 "第四赛季粉丝投票数"。请检查 Excel 内容与工作表名。');
end
idx_fan_header = idx_fan_title + 2;
idx_fan_start = idx_fan_header + 1;

% 找粉丝投票结束行（遇到“第四赛季评委打分”或空行）
idx_fan_end = idx_fan_start;
while idx_fan_end <= size(data,1) && ...
        ~( (ischar(data{idx_fan_end,1}) && strcmp(data{idx_fan_end,1}, '第四赛季评委打分')) ...
           || (isstring(data{idx_fan_end,1}) && data{idx_fan_end,1}=="第四赛季评委打分") )
    % 若第一列为空，也可能是表尾（但有时表中间有空行），这里以遇到评委标题为主要止点
    idx_fan_end = idx_fan_end + 1;
    if idx_fan_end > size(data,1), break; end
end
idx_fan_end = max(idx_fan_start, idx_fan_end - 1);

% 提取粉丝投票区域
fan_names_raw = data(idx_fan_start:idx_fan_end, 1);
% 假定粉丝投票列在后面若干列（尝试取最多 12 列以防超过10）
max_week_cols = 12;
fan_votes_raw = data(idx_fan_start:idx_fan_end, 2:min(1+max_week_cols, size(data,2)));

% 把 fan_votes 转为数值矩阵（NaN 表示缺失）
num_participants = size(fan_names_raw,1);
W_guess = size(fan_votes_raw,2);
fan_votes = NaN(num_participants, W_guess);
for i = 1:num_participants
    for j = 1:W_guess
        v = fan_votes_raw{i,j};
        if isnumeric(v)
            fan_votes(i,j) = v;
        elseif isstring(v) || ischar(v)
            vn = str2double(char(v));
            if ~isnan(vn)
                fan_votes(i,j) = vn;
            else
                fan_votes(i,j) = NaN;
            end
        else
            fan_votes(i,j) = NaN;
        end
    end
end

%% 提取评委打分区
idx_judge_title = find(cellfun(@(x) ischar(x) && strcmp(x, '第四赛季评委打分') || (isstring(x) && x=="第四赛季评委打分"), data(:)), 1);
if isempty(idx_judge_title)
    error('找不到标题 "第四赛季评委打分"。请检查 Excel 内容与工作表名。');
end
idx_judge_header = idx_judge_title + 2;
idx_judge_start = idx_judge_header + 1;

% 找评委数据结束行（向下到遇到空白首列或表尾）
idx_judge_end = size(data,1);
while idx_judge_end >= idx_judge_start && isempty(data{idx_judge_end,1})
    idx_judge_end = idx_judge_end - 1;
end
if idx_judge_end < idx_judge_start
    idx_judge_end = idx_judge_start - 1;
end

judge_data = data(idx_judge_start:idx_judge_end, :);
judge_names_raw = judge_data(:,1);

% 列名行（评委区）
col_names = data(idx_judge_header, :);
% 转为字符串并规范化（小写、移除空格/下划线/连字符）
col_names_str = string(col_names);
col_names_str(ismissing(col_names_str)) = "";
norm_col_names = lower(col_names_str);
% 去掉空格、下划线、连字符以便模糊匹配
norm_col_names = replace(norm_col_names, [" ", "_", "-"], "");

% 估计周数 W：优先使用 fan_votes 的列数
W = W_guess;

% 初始化 judge_scores 矩阵（按 judge_data 的行数）
num_judge_rows = size(judge_data,1);
judge_scores = NaN(num_judge_rows, W);

% 对每一周查找可能的评委列（支持多种列名格式）
for w = 1:W
    % 备选模式（均规范化后���配）
    patterns = {
        sprintf('week%dj', w), ...         % week1j (如果有_judge)
        sprintf('week%djudge', w), ...
        sprintf('week%d', w), ...
        sprintf('week%02d', w), ...
        sprintf('week%dd', w), ...
        sprintf('wk%d', w), ...
        sprintf('wk%02d', w), ...
        sprintf('第%d周', w), ...
        sprintf('第%dw', w) ...
        };
    % 也用带下划线的原始字符串方便匹配（先去除空格/下划线/连字符的 norm_col_names）
    col_inds = [];
    for p = 1:numel(patterns)
        pat = lower(patterns{p});
        pat_norm = replace(string(pat), [" ", "_", "-"], "");
        matches = contains(norm_col_names, pat_norm, 'IgnoreCase', true);
        if any(matches)
            col_inds = find(matches);
            break;
        end
    end
    % 若仍为空，尝试只匹配数字（例如列名中包含 '1' 且有 'judge' 字样）
    if isempty(col_inds)
        % 查找包含当前周数字且包含 judge 或 score 的列
        digit_matches = contains(norm_col_names, sprintf('%d', w));
        extra = contains(norm_col_names, 'judge') | contains(norm_col_names, 'score') | contains(norm_col_names, '评分');
        cand = find(digit_matches & extra);
        if ~isempty(cand)
            col_inds = cand;
        end
    end
    if isempty(col_inds)
        % 无匹配列，此周 judge_scores 保持 NaN（可能只有 fan_votes）
        continue;
    end
    % 累加该周所有匹配列（可能 1~4 ��）
    for i = 1:num_judge_rows
        total = 0;
        cnt = 0;
        for ci = 1:numel(col_inds)
            col = col_inds(ci);
            if col > size(judge_data,2), continue; end
            val = judge_data{i, col};
            if isnumeric(val) && ~isnan(val)
                total = total + val; cnt = cnt + 1;
            elseif isstring(val) || ischar(val)
                s = char(val);
                if isempty(strtrim(s)) || strcmpi(strtrim(s), 'N/A')
                    % 忽略
                else
                    nv = str2double(s);
                    if ~isnan(nv)
                        total = total + nv; cnt = cnt + 1;
                    end
                end
            end
        end
        if cnt > 0
            judge_scores(i,w) = total;
        else
            judge_scores(i,w) = NaN;
        end
    end
end

%% 将姓名统一转为 cell array of char（安全转换，兼容 missing/string/char）
toCharSafe = @(x) safeNameToChar(x);
fan_names = cell(size(fan_names_raw));
for k = 1:numel(fan_names_raw)
    fan_names{k} = toCharSafe(fan_names_raw{k});
end
judge_names = cell(size(judge_names_raw));
for k = 1:numel(judge_names_raw)
    judge_names{k} = toCharSafe(judge_names_raw{k});
end

% 去除首尾空格
fan_names = cellfun(@(s) strtrim(s), fan_names, 'UniformOutput', false);
judge_names = cellfun(@(s) strtrim(s), judge_names, 'UniformOutput', false);

% 取两组姓名的交集（保留 fan_names 的顺序）
[common, idx_fan, idx_judge] = intersect(fan_names, judge_names, 'stable');
if isempty(common)
    % 交集为空时尝试忽略大小写匹配
    [common_ci, idx_fan_ci, idx_judge_ci] = intersect(lower(fan_names), lower(judge_names), 'stable');
    if ~isempty(common_ci)
        common = common_ci;
        idx_fan = idx_fan_ci;
        idx_judge = idx_judge_ci;
    end
end
if isempty(common)
    % 如果还是为空，提示并退出（避免继续产生 NaN）
    error(['粉丝投票与评委打分区没有共同的参赛者姓名。', ...
        ' 请检查 Excel 中姓名列是否在预期行列，或有额外空单元格。']);
end

% 保留交集对应的行
fan_names = fan_names(idx_fan);
fan_votes = fan_votes(idx_fan, :);
judge_names = judge_names(idx_judge);
judge_scores = judge_scores(idx_judge, :);

%% 找到 Billy Ray Cyrus（忽略大小写、首尾空格）
billy_idx = find(strcmpi(strtrim(fan_names), 'Billy Ray Cyrus'), 1);
if isempty(billy_idx)
    % 尝试替代写法（如仅 'Billy' 或带中文），列出名字供诊断
    fprintf('未直接找到 "Billy Ray Cyrus"。前 20 个参赛者姓名：\n');
    disp(fan_names(1:min(20, numel(fan_names))));
    error('请确认 Excel 中的参赛者姓名是否为 "Billy Ray Cyrus"（或告诉我实际名字以便匹配）。');
end

%% 计算每位参赛者的最后表演周（优先使用 judge_scores，若均无则使用 fan_votes 回退）
n = numel(fan_names);
last_week = zeros(n,1);
for i = 1:n
    jpos = find(~isnan(judge_scores(i,:)) & judge_scores(i,:) ~= 0, 1, 'last');
    if ~isempty(jpos)
        last_week(i) = jpos;
    else
        % 回退：使用 fan_votes
        fpos = find(~isnan(fan_votes(i,:)) & fan_votes(i,:) ~= 0, 1, 'last');
        if ~isempty(fpos)
            last_week(i) = fpos;
        else
            last_week(i) = 0;
        end
    end
end

% 如果所有人 last_week 都是 0，说明数据读取仍有问题，提示并终止
if all(last_week == 0)
    error(['所有参赛者的最后表演周均检测为 0，可能 judge_votes 与 fan_votes 都为空或列匹配失败。', ...
           ' 请打印 col_names（脚本中变量 norm_col_names）并检查列标���。']);
end

%% 运行四种情景模拟并记录 Billy 每周在当周可参赛者中的排名
ranks_rank_basic    = simulate_method(judge_scores, fan_votes, last_week, billy_idx, 'rank', 'basic');
ranks_rank_variant  = simulate_method(judge_scores, fan_votes, last_week, billy_idx, 'rank', 'variant');
ranks_percent_basic = simulate_method(judge_scores, fan_votes, last_week, billy_idx, 'percent', 'basic');
ranks_percent_variant = simulate_method(judge_scores, fan_votes, last_week, billy_idx, 'percent', 'variant');

weeks = 1:W;

%% 输出并保存排名结果（表格、CSV、XLSX、MAT）
T = table(weeks', ranks_rank_basic', ranks_rank_variant', ranks_percent_basic', ranks_percent_variant', ...
    'VariableNames', {'Week','Rank_Rank_Basic','Rank_Rank_Variant','Rank_Percent_Basic','Rank_Percent_Variant'});
disp('Billy Ray Cyrus 每周排名（NaN 表示当周不在比赛或已淘汰）：');
disp(T);

% 保存
try
    writetable(T, 'billy_rankings.csv');
    fprintf('已保存 CSV: billy_rankings.csv\n');
catch ME
    warning('保存 CSV 失败：%s', ME.message);
end
try
    writetable(T, 'billy_rankings.xlsx');
    fprintf('已保存 Excel: billy_rankings.xlsx\n');
catch ME
    warning('保存 Excel 失败（可能无 Excel 支持）：%s', ME.message);
end

% 保存 MAT 文件以便后续分析
try
    save('billy_rankings.mat', 'T', 'ranks_rank_basic', 'ranks_rank_variant', 'ranks_percent_basic', 'ranks_percent_variant');
    fprintf('已保存 MAT: billy_rankings.mat\n');
catch ME
    warning('保存 MAT 失败：%s', ME.message);
end

% 打印各情景下 Billy 的“最后参赛周 / 淘汰或存活”信息
scenarios = {'rank/basic','rank/variant','percent/basic','percent/variant'};
ranks_all = {ranks_rank_basic, ranks_rank_variant, ranks_percent_basic, ranks_percent_variant};
for s = 1:numel(scenarios)
    rvec = ranks_all{s};
    last_nonNaN = find(~isnan(rvec), 1, 'last');
    if isempty(last_nonNaN)
        fprintf('情景 %s: Billy 未在任何周出现（所有周为 NaN）\n', scenarios{s});
    else
        if last_nonNaN < W
            fprintf('情景 %s: Billy 最后出现周为 %d（第 %d 周后被淘汰）\n', scenarios{s}, last_nonNaN, last_nonNaN);
        else
            fprintf('情景 %s: Billy 存活到最后（周 %d），最终当周排名为 %g\n', scenarios{s}, W, rvec(W));
        end
    end
end

%% 绘图：排名合并方法（两条折线）
figure('Position',[100 100 900 450]);
plot(weeks, ranks_rank_basic, '-o', 'LineWidth', 2, 'MarkerSize', 8); hold on;
plot(weeks, ranks_rank_variant, '-s', 'LineWidth', 2, 'MarkerSize', 8);
xlabel('Week','FontSize',12); ylabel('Rank (数字越小排名越高)','FontSize',12);
title('Billy Ray Cyrus 排名随周次变化 — 排名合并方法','FontSize',14);
legend('基本淘汰：淘汰综合排名最差','变体：末位两名中评委排名较差者淘汰','Location','best');
grid on; set(gca,'YDir','reverse'); xlim([1 W]);
ylim([1 max(1, max([ranks_rank_basic(~isnan(ranks_rank_basic)), ranks_rank_variant(~isnan(ranks_rank_variant))])) + 1]);

%% 绘图：百分比合并方法（两条折线）
figure('Position',[120 120 900 450]);
plot(weeks, ranks_percent_basic, '-o', 'LineWidth', 2, 'MarkerSize', 8); hold on;
plot(weeks, ranks_percent_variant, '-s', 'LineWidth', 2, 'MarkerSize', 8);
xlabel('Week','FontSize',12); ylabel('Rank (数字越小排名越高)','FontSize',12);
title('Billy Ray Cyrus 排名随周次变化 — 百分比合并方法','FontSize',14);
legend('基本淘汰：淘汰综合百分比最低','变体：末位两名中评委百分比较低者淘汰','Location','best');
grid on; set(gca,'YDir','reverse'); xlim([1 W]);
ylim([1 max(1, max([ranks_percent_basic(~isnan(ranks_percent_basic)), ranks_percent_variant(~isnan(ranks_percent_variant))])) + 1]);

%% ------ 本文件的辅助函数与本地函数 ------

function s = safeNameToChar(x)
    % 将 Excel 单元格中的姓名安全转换为 char，兼容 char/string/missing/numeric/空
    if isempty(x)
        s = '';
        return;
    end
    if ischar(x)
        s = x;
        return;
    end
    if isstring(x)
        if ismissing(x)
            s = '';
            return;
        else
            s = char(x);
            return;
        end
    end
    if isnumeric(x)
        % 可能为 NaN 或数字 id，转换为字符
        if isnan(x)
            s = '';
        else
            s = num2str(x);
        end
        return;
    end
    % 兜底
    try
        sx = string(x);
        if ismissing(sx)
            s = '';
        else
            s = char(sx);
        end
    catch
        s = '';
    end
end

function ranks = simulate_method(judge_scores, fan_votes, last_week, billy_idx, method, rule)
    % 对给定方法模拟每周淘汰并记录 Billy 的当周排名（1 为最好）
    n = size(judge_scores,1);
    W = size(judge_scores,2);
    eliminated = false(n,1);
    ranks = NaN(1,W);
    for w = 1:W
        available = find(~eliminated & last_week >= w);
        if isempty(available)
            % 本���无参赛者
            ranks(w) = NaN;
            continue;
        end
        J = zeros(numel(available),1);
        F = zeros(numel(available),1);
        % 若 judge_scores 列存在，取之；否则为 0
        for k = 1:numel(available)
            jj = available(k);
            if w <= size(judge_scores,2)
                valj = judge_scores(jj,w);
                if ~isnan(valj), J(k) = valj; else J(k)=0; end
            else
                J(k) = 0;
            end
            if w <= size(fan_votes,2)
                valf = fan_votes(jj,w);
                if ~isnan(valf), F(k) = valf; else F(k)=0; end
            else
                F(k) = 0;
            end
        end

        if strcmp(method, 'rank')
            % 评委排名（分数高优）
            [~, idxJ] = sort(J, 'descend');
            judge_rank = zeros(numel(available),1); judge_rank(idxJ) = 1:numel(available);
            % 粉丝排名
            [~, idxF] = sort(F, 'descend');
            fan_rank = zeros(numel(available),1); fan_rank(idxF) = 1:numel(available);
            combined = judge_rank + fan_rank; % 数值越小越好
            [~, order_comb] = sort(combined, 'ascend');

            % 记录 Billy 的排名（若 Billy 在 available 中）
            pos_billy = find(available == billy_idx, 1);
            if ~isempty(pos_billy)
                ranks(w) = find(order_comb == pos_billy);
            else
                ranks(w) = NaN;
            end

            % 淘汰操作（当可选人数>1 时）
            if numel(available) > 1
                if strcmp(rule, 'basic')
                    [~, worst] = max(combined); % combined 最大为最差
                    eliminated(available(worst)) = true;
                else
                    [~, desc_idx] = sort(combined, 'descend');
                    worst_two = desc_idx(1:min(2,numel(desc_idx)));
                    if numel(worst_two) == 1
                        elim = worst_two(1);
                    else
                        if judge_rank(worst_two(1)) > judge_rank(worst_two(2))
                            elim = worst_two(1);
                        elseif judge_rank(worst_two(1)) < judge_rank(worst_two(2))
                            elim = worst_two(2);
                        else
                            elim = worst_two(1);
                        end
                    end
                    eliminated(available(elim)) = true;
                end
            end

        elseif strcmp(method, 'percent')
            % 评委百分比与粉丝百分比
            if sum(J) == 0
                Pj = zeros(size(J));
            else
                Pj = J / sum(J);
            end
            if sum(F) == 0
                Pf = zeros(size(F));
            else
                Pf = F / sum(F);
            end
            combined = Pj + Pf; % 数值越大越好
            [~, order_comb] = sort(combined, 'descend');

            pos_billy = find(available == billy_idx, 1);
            if ~isempty(pos_billy)
                ranks(w) = find(order_comb == pos_billy);
            else
                ranks(w) = NaN;
            end

            if numel(available) > 1
                if strcmp(rule, 'basic')
                    [~, worst] = min(combined); % 最低百分比淘汰
                    eliminated(available(worst)) = true;
                else
                    [~, asc_idx] = sort(combined, 'ascend');
                    worst_two = asc_idx(1:min(2,numel(asc_idx)));
                    if numel(worst_two) == 1
                        elim = worst_two(1);
                    else
                        if Pj(worst_two(1)) < Pj(worst_two(2))
                            elim = worst_two(1);
                        elseif Pj(worst_two(1)) > Pj(worst_two(2))
                            elim = worst_two(2);
                        else
                            elim = worst_two(1);
                        end
                    end
                    eliminated(available(elim)) = true;
                end
            end
        else
            error('不支持的 method 参数: %s', method);
        end

        % 若 Billy 在本周被淘汰，则后续周 ranks 保持 NaN（这是默认行为）
        if eliminated(billy_idx)
            % continue 模拟以保持淘汰顺序一致，但 Billy 的 ranks 已为 NaN
        end
    end
end