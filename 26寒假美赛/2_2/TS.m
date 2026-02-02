%% 第27赛季 Tinashe 排名变化分析
clear; clc; close all;

%% 第27赛季数据 - 每周剩余参赛者信息
% 每周参赛者名单（第1-4周）
contestants_week1 = {'Nikki Glaser', 'Danelle Umstead', 'Nancy McKeon', 'John Schneider', ...
                    'Mary Lou Retton', 'Juan Pablo Di Pace', 'DeMarcus Ware', 'Tinashe', ...
                    'Evanna Lynch', 'Alexis Ren', 'Milo Manheim', 'Joe Amabile', 'Bobby Bones'};
contestants_week2 = {'Danelle Umstead', 'Nancy McKeon', 'John Schneider', 'Mary Lou Retton', ...
                    'Juan Pablo Di Pace', 'DeMarcus Ware', 'Tinashe', 'Evanna Lynch', ...
                    'Alexis Ren', 'Milo Manheim', 'Joe Amabile', 'Bobby Bones'};
contestants_week3 = {'Nancy McKeon', 'John Schneider', 'Mary Lou Retton', 'Juan Pablo Di Pace', ...
                    'DeMarcus Ware', 'Tinashe', 'Evanna Lynch', 'Alexis Ren', ...
                    'Milo Manheim', 'Joe Amabile', 'Bobby Bones'};
contestants_week4 = {'John Schneider', 'Mary Lou Retton', 'Juan Pablo Di Pace', 'DeMarcus Ware', ...
                    'Tinashe', 'Evanna Lynch', 'Alexis Ren', 'Milo Manheim', ...
                    'Joe Amabile', 'Bobby Bones'};

%% 每周粉丝投票数（原始数据，单位为个）
fan_votes_week1 = [30036, 250253, 350701, 450803, 550904, 651006, 751107, 851209, ...
                   951310, 1051412, 1151513, 1251615, 1701936];
fan_votes_week2 = [99965, 349968, 449985, 549985, 649985, 749985, 849985, 949985, ...
                   1049985, 1149985, 1249985, 1799887];
fan_votes_week3 = [50024, 500121, 600146, 700170, 800195, 900219, 1000244, 1100268, ...
                   1200293, 1250317, 1899807];
fan_votes_week4 = [550105, 650114, 750124, 850133, 250038, 1050152, 1150171, 1250190, ...
                   1300209, 2149757];

%% 每周评委总分（三位评委分数之和）
judge_scores_week1 = [17.5, 18, 19.5, 18, 20, 22, 23, 23, 18, 22, 20, 14, 20];
judge_scores_week2 = [18.5, 20.5, 21.5, 23, 26, 23.5, 26, 24, 24.5, 26, 17.5, 19.5];
judge_scores_week3 = [22, 21, 24, 30, 26, 27, 27, 26, 27, 18, 23];
judge_scores_week4 = [21, 26, 24, 22, 26, 24, 25, 29, 15, 20];

%% 方法1：百分比合并法计算每周排名
percentage_rankings = zeros(1, 4); % 存储Tinashe每周排名

for week = 1:4
    % 获取当前周数据
    if week == 1
        contestants = contestants_week1;
        fan_votes = fan_votes_week1;
        judge_scores = judge_scores_week1;
    elseif week == 2
        contestants = contestants_week2;
        fan_votes = fan_votes_week2;
        judge_scores = judge_scores_week2;
    elseif week == 3
        contestants = contestants_week3;
        fan_votes = fan_votes_week3;
        judge_scores = judge_scores_week3;
    else % week == 4
        contestants = contestants_week4;
        fan_votes = fan_votes_week4;
        judge_scores = judge_scores_week4;
    end
    
    % 查找Tinashe的索引
    tinashe_index = find(strcmp(contestants, 'Tinashe'));
    
    % 计算百分比
    judge_percent = judge_scores / sum(judge_scores);
    fan_percent = fan_votes / sum(fan_votes);
    
    % 计算综合百分比
    total_percent = judge_percent + fan_percent;
    
    % 按综合百分比降序排序（百分比越高排名越好）
    [~, sorted_indices] = sort(total_percent, 'descend');
    
    % 查找Tinashe的排名
    tinashe_rank = find(sorted_indices == tinashe_index);
    
    % 存储排名
    percentage_rankings(week) = tinashe_rank;
end

%% 方法2：阶梯式双轨制计算每周排名
our_method_rankings = zeros(1, 4); % 存储Tinashe每周排名

% 参数设置
K = 0.5; % 最大加成上限

for week = 1:4
    % 获取当前周数据
    if week == 1
        contestants = contestants_week1;
        fan_votes = fan_votes_week1;
        judge_scores = judge_scores_week1;
    elseif week == 2
        contestants = contestants_week2;
        fan_votes = fan_votes_week2;
        judge_scores = judge_scores_week2;
    elseif week == 3
        contestants = contestants_week3;
        fan_votes = fan_votes_week3;
        judge_scores = judge_scores_week3;
    else % week == 4
        contestants = contestants_week4;
        fan_votes = fan_votes_week4;
        judge_scores = judge_scores_week4;
    end
    
    % 查找Tinashe的索引
    tinashe_index = find(strcmp(contestants, 'Tinashe'));
    
    n = length(contestants);
    S_final = zeros(1, n);
    
    % 计算每个选手的最终得分
    for i = 1:n
        % 步骤1：评委标准化（映射到[10,20]区间）
        J_i = judge_scores(i);
        J_min = min(judge_scores);
        J_max = max(judge_scores);
        
        if J_max == J_min % 防止除以0
            S_judge = 15; % 取中间值
        else
            S_judge = 10 + 10 * (J_i - J_min) / (J_max - J_min);
        end
        
        % 步骤2：粉丝段位映射
        % 计算粉丝投票的排名百分位
        [~, fan_ranks] = sort(fan_votes, 'ascend');
        fan_rank = find(fan_ranks == i);
        P_i = (fan_rank - 1) / (n - 1);
        
        % Sigmoid函数计算热度加成系数
        T_fan = K / (1 + exp(-10 * (P_i - 0.5)));
        
        % 最终得分
        S_final(i) = S_judge * (1 + T_fan);
    end
    
    % 按最终得分降序排序（得分越高排名越好）
    [~, sorted_indices] = sort(S_final, 'descend');
    
    % 查找Tinashe的排名
    tinashe_rank = find(sorted_indices == tinashe_index);
    
    % 存储排名
    our_method_rankings(week) = tinashe_rank;
end

%% 绘制排名变化图
weeks = 1:4;
figure('Position', [100, 100, 800, 600]);

% 绘制两条折线
plot(weeks, percentage_rankings, 'b-o', 'LineWidth', 2, 'MarkerSize', 10, 'MarkerFaceColor', 'b');
hold on;
plot(weeks, our_method_rankings, 'r-s', 'LineWidth', 2, 'MarkerSize', 10, 'MarkerFaceColor', 'r');

% 设置图形属性
grid on;
xlabel('Week', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Rank (lower is better)', 'FontSize', 14, 'FontWeight', 'bold');
title('Season 27: Tinashe Weekly Ranking Comparison', 'FontSize', 16, 'FontWeight', 'bold');
legend({'Percentage Method', 'Our Method (Tiered Dual-Track)'}, 'FontSize', 12, 'Location', 'best');

% 设置坐标轴
xlim([0.8, 4.2]);
ylim([0, max([percentage_rankings, our_method_rankings]) + 1]);
set(gca, 'XTick', 1:4, 'FontSize', 12);
set(gca, 'YTick', 1:max([percentage_rankings, our_method_rankings]), 'FontSize', 12);

% 反转Y轴，使排名1在顶部（排名数字越小越靠上）
set(gca, 'YDir', 'reverse');

% 添加数据标签
for i = 1:4
    text(weeks(i), percentage_rankings(i), sprintf(' %d', percentage_rankings(i)), ...
        'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left', 'FontSize', 11);
    text(weeks(i), our_method_rankings(i), sprintf(' %d', our_method_rankings(i)), ...
        'VerticalAlignment', 'top', 'HorizontalAlignment', 'left', 'FontSize', 11);
end

% 添加淘汰标记（第4周被淘汰）
text(4.1, percentage_rankings(4), ' Eliminated', 'FontSize', 10, 'Color', 'b');
text(4.1, our_method_rankings(4), ' Eliminated', 'FontSize', 10, 'Color', 'r');

% 添加横线表示排名变化趋势
plot([weeks(3), weeks(4)], [percentage_rankings(3), percentage_rankings(4)], 'b--', 'LineWidth', 1, 'Alpha', 0.5);
plot([weeks(3), weeks(4)], [our_method_rankings(3), our_method_rankings(4)], 'r--', 'LineWidth', 1, 'Alpha', 0.5);

hold off;

%% 显示排名数据
fprintf('=== Season 27: Tinashe Weekly Rankings ===\n');
fprintf('Week\tPercentage Method\tOur Method\n');
for week = 1:4
    fprintf('%d\t\t%d\t\t\t%d\n', week, percentage_rankings(week), our_method_rankings(week));
end

% 计算平均排名（仅前4周）
avg_percentage = mean(percentage_rankings);
avg_our_method = mean(our_method_rankings);
fprintf('\nAverage Ranking (Weeks 1-4):\n');
fprintf('Percentage Method: %.2f\n', avg_percentage);
fprintf('Our Method: %.2f\n', avg_our_method);

% 分析排名变化
fprintf('\n=== Ranking Analysis ===\n');
fprintf('Ranking Trend:\n');
for week = 1:3
    if percentage_rankings(week+1) > percentage_rankings(week)
        fprintf('Week %d->%d: Percentage Method - Rank worsened (%d -> %d)\n', ...
            week, week+1, percentage_rankings(week), percentage_rankings(week+1));
    elseif percentage_rankings(week+1) < percentage_rankings(week)
        fprintf('Week %d->%d: Percentage Method - Rank improved (%d -> %d)\n', ...
            week, week+1, percentage_rankings(week), percentage_rankings(week+1));
    else
        fprintf('Week %d->%d: Percentage Method - Rank unchanged (%d)\n', ...
            week, week+1, percentage_rankings(week));
    end
end