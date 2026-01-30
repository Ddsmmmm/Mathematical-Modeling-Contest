clc;close all;clear;

function results = buildDWTSSeasonMatrices(filename)
    % 读取CSV文件
    data = readtable(filename);

    % 获取所有赛季
    seasons = unique(data.season);

    % 提取所有评分列名
    score_columns = contains(data.Properties.VariableNames, 'week') & ...
                   contains(data.Properties.VariableNames, 'score');
    score_col_names = data.Properties.VariableNames(score_columns);

    % 存储结果
    results = struct();
    results.seasons = seasons;
    results.season_data = struct();

    % 为每个赛季创建矩阵
    for season_num = 1:length(seasons)
        season = seasons(season_num);

        % 筛选当前赛季数据
        season_data = data(data.season == season, :);
        names = season_data.celebrity_name;

        % 确定最大周数和评委数
        max_week = 0;
        judges_per_week = containers.Map;

        for i = 1:length(score_col_names)
            col_name = score_col_names{i};
            tokens = regexp(col_name, 'week(\d+)_judge(\d+)_score', 'tokens');
            if ~isempty(tokens)
                week_num = str2double(tokens{1}{1});
                judge_num = str2double(tokens{1}{2});

                max_week = max(max_week, week_num);

                week_key = sprintf('week%d', week_num);
                if isKey(judges_per_week, week_key)
                    judges_per_week(week_key) = max(judges_per_week(week_key), judge_num);
                else
                    judges_per_week(week_key) = judge_num;
                end
            end
        end

        % 计算总列数
        total_columns = 0;
        for week = 1:max_week
            week_key = sprintf('week%d', week);
            if isKey(judges_per_week, week_key)
                total_columns = total_columns + judges_per_week(week_key);
            end
        end

        % 创建得分矩阵
        n_contestants = height(season_data);
        score_matrix = zeros(n_contestants, total_columns);

        % 填充矩阵
        col_index = 1;
        for week = 1:max_week
            week_key = sprintf('week%d', week);

            if isKey(judges_per_week, week_key)
                n_judges = judges_per_week(week_key);

                for judge = 1:n_judges
                    col_name = sprintf('week%d_judge%d_score', week, judge);

                    if ismember(col_name, data.Properties.VariableNames)
                        scores = season_data.(col_name);

                        for i = 1:length(scores)
                            if isnumeric(scores(i))
                                score_matrix(i, col_index) = scores(i);
                            else
                                score_matrix(i, col_index) = NaN;
                            end
                        end
                    else
                        score_matrix(:, col_index) = NaN;
                    end

                    col_index = col_index + 1;
                end
            end
        end

        % 保存结果
        season_field = sprintf('season%d', season);
        results.season_data.(season_field).scores = score_matrix;
        results.season_data.(season_field).names = names;
        results.season_data.(season_field).max_week = max_week;
        results.season_data.(season_field).judges_per_week = judges_per_week;
        results.season_data.(season_field).total_columns = total_columns;
    end
end


function printDWTSSeason(results, season_to_print)
    season_field = sprintf('season%d', season_to_print);

    if ~isfield(results.season_data, season_field)
        fprintf('未找到赛季 %d 的数据。\n', season_to_print);
        return;
    end

    season_info = results.season_data.(season_field);

    score_matrix = season_info.scores;
    names = season_info.names;
    max_week = season_info.max_week;
    judges_per_week = season_info.judges_per_week;
    total_columns = season_info.total_columns;
    n_contestants = size(score_matrix, 1);

    fprintf('\n===================== 赛季 %d 详细数据 =====================\n', season_to_print);
    fprintf('选手总数: %d\n', n_contestants);
    fprintf('周数: %d\n', max_week);
    fprintf('总评分列数: %d\n\n', total_columns);

    for i = 1:n_contestants
        fprintf('选手 %d: %s\n', i, names{i});
        fprintf('得分: ');

        col_idx = 1;
        for week = 1:max_week
            week_key = sprintf('week%d', week);
            if isKey(judges_per_week, week_key)
                n_judges = judges_per_week(week_key);

                fprintf('第%d周: ', week);
                for judge = 1:n_judges
                    score = score_matrix(i, col_idx);
                    if isnan(score)
                        fprintf('NaN ');
                    else
                        fprintf('%.4f ', score);
                    end
                    col_idx = col_idx + 1;
                end
                fprintf('| ');
            end
        end
        fprintf('\n\n');
    end

    fprintf('\n赛季 %d 得分矩阵 (行=选手, 列=周×评委得分):\n', season_to_print);
    disp(score_matrix);
    fprintf('\n==========================================================\n\n');
end


results = buildDWTSSeasonMatrices('2026_MCM_Problem_C_Data.csv');
printDWTSSeason(results, 16);