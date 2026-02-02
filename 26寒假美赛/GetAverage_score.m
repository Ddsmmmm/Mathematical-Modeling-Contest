%% 读取Excel数据
filename = '2026_MCM_Problem_C_Data.xlsx';
data = readtable(filename, 'TextType', 'string');

%% 获取评分列的范围
% 查找评分列的起始位置（第一个包含'score'的列）
header = data.Properties.VariableNames;
score_cols = contains(header, 'score');

% 提取评分数据
scores = data{:, score_cols};

% 将字符串'N/A'转换为NaN
scores_str = string(scores); % 转换为字符串以便处理
scores_numeric = zeros(size(scores));

% 逐元素处理，将有效数字转换为数值，无效的设为NaN
for i = 1:size(scores, 1)
    for j = 1:size(scores, 2)
        val_str = scores_str(i, j);
        % 检查是否为空或'N/A'
        if ismissing(val_str) || strcmpi(val_str, 'N/A') || strcmp(val_str, '')
            scores_numeric(i, j) = NaN;
        else
            % 尝试转换为数值
            val_num = str2double(val_str);
            if isnan(val_num) || val_num == 0
                scores_numeric(i, j) = NaN;
            else
                scores_numeric(i, j) = val_num;
            end
        end
    end
end

%% 计算每个参赛者的有效评分均值
mean_scores = zeros(height(data), 1);

for i = 1:height(data)
    % 获取当前行的所有评分
    row_scores = scores_numeric(i, :);
    
    % 找出有效评分（非NaN且非0）
    valid_scores = row_scores(~isnan(row_scores) & row_scores ~= 0);
    
    % 计算均值
    if ~isempty(valid_scores)
        mean_scores(i) = mean(valid_scores);
    else
        mean_scores(i) = NaN; % 如果没有有效评分，设为NaN
    end
end

%% 创建结果表格
result_table = table();
result_table.celebrity_name = data.celebrity_name;
result_table.season = data.season;
result_table.mean_score = mean_scores;
result_table.placement = data.placement;
result_table.results = data.results;

% 可选：添加原始评分列（如果需要）
% 为了保持简洁，这里只保留基本信息，如果需要原始评分，可以取消注释下面的代码
% for j = 1:size(scores, 2)
%     result_table.(header{find(score_cols, 1) + j - 1}) = scores_numeric(:, j);
% end

%% 保存结果到Excel
output_filename = 'tem.xlsx';
writetable(result_table, output_filename);

%% 显示统计信息
fprintf('数据处理完成！\n');
fprintf('总参赛者人数: %d\n', height(data));
fprintf('已保存到文件: %s\n', output_filename);

% 按赛季显示统计信息
seasons = unique(data.season);
fprintf('\n各赛季统计信息:\n');
fprintf('%-10s %-15s %-15s %-15s\n', '赛季', '参赛者人数', '平均分', '标准差');
fprintf('%-10s %-15s %-15s %-15s\n', '----', '----------', '------', '------');

for s = 1:length(seasons)
    season_idx = data.season == seasons(s);
    season_scores = mean_scores(season_idx);
    valid_scores = season_scores(~isnan(season_scores));
    
    if ~isempty(valid_scores)
        fprintf('%-10d %-15d %-15.4f %-15.4f\n', ...
            seasons(s), sum(season_idx), mean(valid_scores), std(valid_scores));
    else
        fprintf('%-10d %-15d %-15s %-15s\n', ...
            seasons(s), sum(season_idx), '无有效数据', '无有效数据');
    end
end

% 显示前10名参赛者的结果
fprintf('\n前10名参赛者的平均分:\n');
for i = 1:min(10, height(result_table))
    if ~isnan(mean_scores(i))
        fprintf('%s (第%d季): %.4f\n', ...
            result_table.celebrity_name{i}, result_table.season(i), mean_scores(i));
    else
        fprintf('%s (第%d季): 无有效评分\n', ...
            result_table.celebrity_name{i}, result_table.season(i));
    end
end