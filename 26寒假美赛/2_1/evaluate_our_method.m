% % 清除工作区
% clear; clc; close all;
% 
% % 第27赛季数据
% % 选手名单
% contestants = {
%     'Nikki Glaser', 'Danelle Umstead', 'Nancy McKeon', 'John Schneider',...
%     'Mary Lou Retton', 'Juan Pablo Di Pace', 'DeMarcus Ware', 'Tinashe',...
%     'Evanna Lynch', 'Alexis Ren', 'Milo Manheim', 'Joe Amabile', 'Bobby Bones'
% };
% 
% % 粉丝投票数据（第27赛季，Week1-Week9）
% fan_votes = [
%     30036, 0, 0, 0, 0, 0, 0, 0, 0;           % Nikki Glaser
%     250253, 99965, 0, 0, 0, 0, 0, 0, 0;      % Danelle Umstead
%     350701, 349968, 50024, 0, 0, 0, 0, 0, 0; % Nancy McKeon
%     450803, 449985, 500121, 550105, 549902, 549918, 300102, 0, 0; % John Schneider
%     550904, 549985, 600146, 650114, 649902, 299973, 0, 0, 0; % Mary Lou Retton
%     651006, 649985, 700170, 750124, 749902, 749918, 850234, 399978, 0; % Juan Pablo Di Pace
%     751107, 749985, 800195, 850133, 849902, 849918, 399976, 0, 0; % DeMarcus Ware
%     851209, 849985, 900219, 250038, 0, 0, 0, 0, 0; % Tinashe
%     951310, 949985, 1000244, 1050152, 1049902, 1049918, 1150391, 1999890, 1999980; % Evanna Lynch
%     1051412, 1049985, 1100268, 1150171, 1149902, 1149918, 1250391, 1999890, 1499985; % Alexis Ren
%     1151513, 1149985, 1200293, 1250190, 1249902, 1249918, 1350391, 2299878, 2499975; % Milo Manheim
%     1251615, 1249985, 1250317, 1300209, 1299902, 1299918, 1400391, 499972, 0; % Joe Amabile
%     1701936, 1799887, 1899807, 2149757, 2449687, 2799619, 3299323, 2799391, 3999998 % Bobby Bones
% ];
% 
% % 评委分数数据（第27赛季，Week1-Week9）
% % 每个选手每周的评委总分（假设每个评委分数1-10，取平均值）
% judge_scores = [
%     5.83, 0, 0, 0, 0, 0, 0, 0, 0;           % Nikki Glaser (平均分: (6+5.5+6)/3=5.83)
%     6.00, 6.17, 0, 0, 0, 0, 0, 0, 0;        % Danelle Umstead
%     6.50, 6.83, 7.33, 0, 0, 0, 0, 0, 0;     % Nancy McKeon
%     6.00, 7.17, 7.00, 7.00, 8.00, 6.33, 9.00, 0, 0; % John Schneider
%     6.67, 7.67, 8.00, 8.67, 8.33, 8.00, 0, 0, 0; % Mary Lou Retton
%     7.33, 8.67, 10.00, 8.00, 9.67, 10.00, 9.33, 10.00, 0; % Juan Pablo Di Pace
%     7.67, 7.83, 8.67, 7.33, 8.67, 8.67, 8.83, 0, 0; % DeMarcus Ware
%     7.67, 8.67, 9.00, 8.67, 0, 0, 0, 0, 0; % Tinashe
%     6.00, 8.00, 9.00, 8.00, 8.00, 9.67, 9.83, 9.67, 10.00; % Evanna Lynch
%     7.33, 8.17, 8.67, 8.33, 9.67, 9.00, 9.17, 9.67, 9.50; % Alexis Ren
%     6.67, 8.67, 9.00, 9.67, 9.00, 10.00, 9.67, 9.17, 10.00; % Milo Manheim
%     4.67, 5.83, 6.00, 5.00, 5.67, 7.33, 7.83, 7.67, 0; % Joe Amabile
%     6.67, 6.50, 7.67, 6.67, 7.00, 7.33, 8.83, 7.50, 9.00 % Bobby Bones
% ];
% 
% % 找到Bobby Bones的索引
% bobby_index = find(strcmp(contestants, 'Bobby Bones'));
% 
% % 初始化存储排名的数组
% num_weeks = size(fan_votes, 2);
% percentile_ranks = zeros(1, num_weeks);  % 百分比法排名
% our_method_ranks = zeros(1, num_weeks);  % our_method排名
% 
% % 遍历每一周
% for week = 1:num_weeks
%     % 获取本周有投票的选手索引（粉丝投票>0）
%     active_players = find(fan_votes(:, week) > 0);
% 
%     if isempty(active_players)
%         continue;
%     end
% 
%     num_active = length(active_players);
% 
%     % ==================== 方法1: 百分比合并法 ====================
%     judge_totals = zeros(num_active, 1);
%     fan_totals = zeros(num_active, 1);
% 
%     for i = 1:num_active
%         player_idx = active_players(i);
%         judge_totals(i) = judge_scores(player_idx, week);
%         fan_totals(i) = fan_votes(player_idx, week);
%     end
% 
%     % 计算百分比
%     if sum(judge_totals) > 0
%         judge_percent = judge_totals / sum(judge_totals) * 100;
%     else
%         judge_percent = zeros(num_active, 1);
%     end
% 
%     if sum(fan_totals) > 0
%         fan_percent = fan_totals / sum(fan_totals) * 100;
%     else
%         fan_percent = zeros(num_active, 1);
%     end
% 
%     % 合并百分比
%     combined_percent = judge_percent + fan_percent;
% 
%     % 计算排名（百分比越高排名越靠前，数字越小）
%     [~, sorted_indices] = sort(combined_percent, 'descend');
% 
%     % 找到Bobby Bones的排名
%     bobby_pos = find(active_players(sorted_indices) == bobby_index);
%     percentile_ranks(week) = bobby_pos;
% 
%     % ==================== 方法2: our_method ====================
%     % 步骤1: 评委标准化 (映射到[10,20]区间)
%     J_min = min(judge_totals);
%     J_max = max(judge_totals);
% 
%     if J_max == J_min
%         S_judge = 15 * ones(num_active, 1);  % 如果所有评委分数相同，设为15
%     else
%         S_judge = 10 + 10 * (judge_totals - J_min) / (J_max - J_min);
%     end
% 
%     % 步骤2: 粉丝段位Sigmoid映射
%     % 计算粉丝票数的百分位排名
%     [~, fan_rank_order] = sort(fan_totals, 'descend');
%     fan_ranks = zeros(num_active, 1);
% 
%     for i = 1:num_active
%         fan_ranks(fan_rank_order(i)) = i;
%     end
% 
%     P_i = (num_active - fan_ranks) / (num_active - 1);  % 百分位排名，范围[0,1]
% 
%     % 设置参数
%     K = 0.5;
%     a = 10;  % 竞争强度系数
% 
%     % 计算粉丝加成系数
%     T_fan = K ./ (1 + exp(-a * (P_i - 0.5)));
% 
%     % 计算最终得分
%     S_final = S_judge .* (1 + T_fan);
% 
%     % 计算排名（最终得分越高排名越靠前，数字越小）
%     [~, sorted_indices_our] = sort(S_final, 'descend');
% 
%     % 找到Bobby Bones的排名
%     bobby_pos_our = find(active_players(sorted_indices_our) == bobby_index);
%     our_method_ranks(week) = bobby_pos_our;
% end
% 
% % ==================== 绘制折线图 ====================
% weeks = 1:num_weeks;
% figure('Position', [100, 100, 900, 500]);
% 
% % 创建折线图
% plot(weeks, percentile_ranks, '-o', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', '百分比合并法');
% hold on;
% plot(weeks, our_method_ranks, '-s', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Our Method');
% 
% % 设置图形属性
% grid on;
% xlabel('Week', 'FontSize', 12, 'FontWeight', 'bold');
% ylabel('Rank (数字越小排名越高)', 'FontSize', 12, 'FontWeight', 'bold');
% title('第27赛季 Bobby Bones 每周排名变化对比', 'FontSize', 14, 'FontWeight', 'bold');
% legend('Location', 'best', 'FontSize', 10);
% 
% % 设置坐标轴
% set(gca, 'FontSize', 10);
% xlim([0.5, num_weeks + 0.5]);
% ylim([0, max([percentile_ranks, our_method_ranks]) + 1]);
% 
% % 反转Y轴，使排名数字越小位置越高（更符合视觉习惯）
% set(gca, 'YDir', 'reverse');
% 
% % 添加数据标签
% for i = 1:num_weeks
%     text(weeks(i), percentile_ranks(i) + 0.2, num2str(percentile_ranks(i)),...
%         'HorizontalAlignment', 'center', 'FontSize', 9);
%     text(weeks(i), our_method_ranks(i) - 0.2, num2str(our_method_ranks(i)),...
%         'HorizontalAlignment', 'center', 'FontSize', 9);
% end
% 
% % 添加背景色区分区域
% y_limits = ylim;
% for i = 1:2:num_weeks
%     if i < num_weeks
%         area_x = [i-0.5, i+0.5, i+0.5, i-0.5];
%         area_y = [y_limits(1), y_limits(1), y_limits(2), y_limits(2)];
%         fill(area_x, area_y, [0.95, 0.95, 0.95], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
%     end
% end
% 
% % 将图形重新置于顶层
% uistack(findobj(gca, 'Type', 'line'), 'top');
% 
% % 输出详细结果
% fprintf('=== 第27赛季 Bobby Bones 排名分析 ===\n');
% fprintf('Week\t百分比法排名\tOur Method排名\t差异\n');
% fprintf('----------------------------------------\n');
% for week = 1:num_weeks
%     fprintf('%d\t\t%d\t\t\t%d\t\t\t%d\n', week, percentile_ranks(week),...
%         our_method_ranks(week), our_method_ranks(week) - percentile_ranks(week));
% end
% 
% % 计算平均排名
% fprintf('\n平均排名:\n');
% fprintf('百分比法: %.2f\n', mean(percentile_ranks(percentile_ranks>0)));
% fprintf('Our Method: %.2f\n', mean(our_method_ranks(our_method_ranks>0)));


















%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



% 清除工作区
clear; clc; close all;

% 第2赛季数据
% 选手名单
contestants = {
    'Kenny Mayne', 'Tatum O''Neal', 'Giselle Fernandez', 'Master P',...
    'Tia Carrere', 'George Hamilton', 'Lisa Rinna', 'Stacy Keibler',...
    'Jerry Rice', 'Drew Lachey'
};

% 粉丝投票数据（第2赛季，Week1-Week8）
fan_votes = [
    181967, 0, 0, 0, 0, 0, 0, 0;                % Kenny Mayne
    363945, 222113, 0, 0, 0, 0, 0, 0;          % Tatum O'Neal
    545112, 888912, 277935, 0, 0, 0, 0, 0;     % Giselle Fernandez
    1817905, 1999956, 2222015, 356987, 0, 0, 0, 0; % Master P
    727083, 1555926, 1111028, 1786024, 476041, 0, 0, 0; % Tia Carrere
    1091107, 1332974, 1666963, 2499962, 2381082, 667041, 0, 0; % George Hamilton
    1273105, 1777963, 1389017, 1071043, 1905032, 2666987, 999986, 0; % Lisa Rinna
    1455093, 444011, 555987, 1429021, 952087, 1333028, 2999978, 1666974; % Stacy Keibler
    1635942, 1110973, 1944011, 2143025, 2857092, 3333024, 4000047, 5000033; % Jerry Rice
    908841, 667072, 833044, 714029, 1428912, 1999999, 2000119, 3332993 % Drew Lachey
];

% 评委分数数据（第2赛季，Week1-Week8）
% 每个选手每周的评委总分（3位评委的分数和）
judge_scores = [
    4.33, 0, 0, 0, 0, 0, 0, 0;                % Kenny Mayne (4+5+4)/3 = 4.33
    7.67, 5.67, 0, 0, 0, 0, 0, 0;            % Tatum O'Neal
    7.67, 8.00, 7.33, 0, 0, 0, 0, 0;         % Giselle Fernandez
    4.00, 5.33, 4.67, 2.67, 0, 0, 0, 0;      % Master P
    6.67, 7.33, 8.67, 8.33, 7.33, 0, 0, 0;   % Tia Carrere
    6.00, 7.33, 7.33, 7.00, 8.00, 7.67, 0, 0; % George Hamilton
    6.33, 6.67, 8.33, 8.67, 8.33, 9.00, 8.83, 0; % Lisa Rinna
    7.33, 9.67, 9.00, 8.67, 10.00, 10.00, 9.17, 9.56; % Stacy Keibler
    7.00, 7.67, 6.33, 8.00, 7.67, 7.67, 6.83, 8.89; % Jerry Rice
    8.00, 9.00, 9.00, 9.33, 9.00, 10.00, 9.17, 9.67 % Drew Lachey
];

% 找到Jerry Rice的索引
jerry_index = find(strcmp(contestants, 'Jerry Rice'));

% 初始化存储排名的数组
num_weeks = size(fan_votes, 2);
percentile_ranks = zeros(1, num_weeks);  % 百分比法排名
our_method_ranks = zeros(1, num_weeks);  % our_method排名

% 遍历每一周
for week = 1:num_weeks
    % 获取本周有投票的选手索引（粉丝投票>0）
    active_players = find(fan_votes(:, week) > 0);
    
    if isempty(active_players)
        continue;
    end
    
    num_active = length(active_players);
    
    % ==================== 方法1: 百分比合并法 ====================
    judge_totals = zeros(num_active, 1);
    fan_totals = zeros(num_active, 1);
    
    for i = 1:num_active
        player_idx = active_players(i);
        judge_totals(i) = judge_scores(player_idx, week);
        fan_totals(i) = fan_votes(player_idx, week);
    end
    
    % 计算百分比
    if sum(judge_totals) > 0
        judge_percent = judge_totals / sum(judge_totals) * 100;
    else
        judge_percent = zeros(num_active, 1);
    end
    
    if sum(fan_totals) > 0
        fan_percent = fan_totals / sum(fan_totals) * 100;
    else
        fan_percent = zeros(num_active, 1);
    end
    
    % 合并百分比
    combined_percent = judge_percent + fan_percent;
    
    % 计算排名（百分比越高排名越靠前，数字越小）
    [~, sorted_indices] = sort(combined_percent, 'descend');
    
    % 找到Jerry Rice的排名
    jerry_pos = find(active_players(sorted_indices) == jerry_index);
    percentile_ranks(week) = jerry_pos;
    
    % ==================== 方法2: our_method ====================
    % 步骤1: 评委标准化 (映射到[10,20]区间)
    J_min = min(judge_totals);
    J_max = max(judge_totals);
    
    if J_max == J_min
        S_judge = 15 * ones(num_active, 1);  % 如果所有评委分数相同，设为15
    else
        S_judge = 10 + 10 * (judge_totals - J_min) / (J_max - J_min);
    end
    
    % 步骤2: 粉丝段位Sigmoid映射
    % 计算粉丝票数的百分位排名
    [~, fan_rank_order] = sort(fan_totals, 'descend');
    fan_ranks = zeros(num_active, 1);
    
    for i = 1:num_active
        fan_ranks(fan_rank_order(i)) = i;
    end
    
    P_i = (num_active - fan_ranks) / (num_active - 1);  % 百分位排名，范围[0,1]
    
    % 设置参数
    K = 0.5;
    a = 10;  % 竞争强度系数
    
    % 计算粉丝加成系数
    T_fan = K ./ (1 + exp(-a * (P_i - 0.5)));
    
    % 计算最终得分
    S_final = S_judge .* (1 + T_fan);
    
    % 计算排名（最终得分越高排名越靠前，数字越小）
    [~, sorted_indices_our] = sort(S_final, 'descend');
    
    % 找到Jerry Rice的排名
    jerry_pos_our = find(active_players(sorted_indices_our) == jerry_index);
    our_method_ranks(week) = jerry_pos_our;
end

% ==================== 绘制折线图 ====================
weeks = 1:num_weeks;
figure('Position', [100, 100, 900, 500]);

% 创建折线图
plot(weeks, percentile_ranks, '-o', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', '百分比合并法');
hold on;
plot(weeks, our_method_ranks, '-s', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Our Method');

% 设置图形属性
grid on;
xlabel('Week', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Rank (数字越小排名越高)', 'FontSize', 12, 'FontWeight', 'bold');
title('第2赛季 Jerry Rice 每周排名变化对比', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 10);

% 设置坐标轴
set(gca, 'FontSize', 10);
xlim([0.5, num_weeks + 0.5]);
ylim([0, max([percentile_ranks, our_method_ranks]) + 1]);

% 反转Y轴，使排名数字越小位置越高（更符合视觉习惯）
set(gca, 'YDir', 'reverse');

% 添加数据标签
for i = 1:num_weeks
    if percentile_ranks(i) > 0
        text(weeks(i), percentile_ranks(i) + 0.2, num2str(percentile_ranks(i)),...
            'HorizontalAlignment', 'center', 'FontSize', 9);
    end
    if our_method_ranks(i) > 0
        text(weeks(i), our_method_ranks(i) - 0.2, num2str(our_method_ranks(i)),...
            'HorizontalAlignment', 'center', 'FontSize', 9);
    end
end

% 添加背景色区分区域
y_limits = ylim;
for i = 1:2:num_weeks
    if i < num_weeks
        area_x = [i-0.5, i+0.5, i+0.5, i-0.5];
        area_y = [y_limits(1), y_limits(1), y_limits(2), y_limits(2)];
        fill(area_x, area_y, [0.95, 0.95, 0.95], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
    end
end

% 将图形重新置于顶层
uistack(findobj(gca, 'Type', 'line'), 'top');

% 输出详细结果
fprintf('=== 第2赛季 Jerry Rice 排名分析 ===\n');
fprintf('Week\t百分比法排名\tOur Method排名\t差异\n');
fprintf('----------------------------------------\n');
for week = 1:num_weeks
    if percentile_ranks(week) > 0 && our_method_ranks(week) > 0
        fprintf('%d\t\t%d\t\t\t%d\t\t\t%d\n', week, percentile_ranks(week),...
            our_method_ranks(week), our_method_ranks(week) - percentile_ranks(week));
    else
        fprintf('%d\t\t-\t\t\t-\t\t\t-\n', week);
    end
end

% 计算平均排名（只计算有排名的周）
valid_weeks_percentile = percentile_ranks(percentile_ranks>0);
valid_weeks_our = our_method_ranks(our_method_ranks>0);

fprintf('\n平均排名:\n');
if ~isempty(valid_weeks_percentile)
    fprintf('百分比法: %.2f\n', mean(valid_weeks_percentile));
end
if ~isempty(valid_weeks_our)
    fprintf('Our Method: %.2f\n', mean(valid_weeks_our));
end

















