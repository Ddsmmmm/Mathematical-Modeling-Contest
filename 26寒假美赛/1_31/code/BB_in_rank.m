% %% 清除环境
% clear; clc; close all;
% 
% %% 第27赛季数据手动输入（粉丝投票和评委总分）
% % 选手顺序：
% % 1.Nikki Glaser, 2.Danelle Umstead, 3.Nancy McKeon, 4.John Schneider, 
% % 5.Mary Lou Retton, 6.Juan Pablo Di Pace, 7.DeMarcus Ware, 8.Tinashe, 
% % 9.Evanna Lynch, 10.Alexis Ren, 11.Milo Manheim, 12.Joe Amabile, 13.Bobby Bones
% 
% % 粉丝投票数（13行 x 9周）
% fanVotes = [
%     30036, 0, 0, 0, 0, 0, 0, 0, 0;
%     250253, 99965, 0, 0, 0, 0, 0, 0, 0;
%     350701, 349968, 50024, 0, 0, 0, 0, 0, 0;
%     450803, 449985, 500121, 550105, 549902, 549918, 300102, 0, 0;
%     550904, 549985, 600146, 650114, 649902, 299973, 0, 0, 0;
%     651006, 649985, 700170, 750124, 749902, 749918, 850234, 399978, 0;
%     751107, 749985, 800195, 850133, 849902, 849918, 399976, 0, 0;
%     851209, 849985, 900219, 250038, 0, 0, 0, 0, 0;
%     951310, 949985, 1000244, 1050152, 1349902, 1049918, 1150391, 1999890, 1999980;
%     1251412, 1149985, 1100268, 1150171, 1249902, 1149918, 1250391, 2099890, 1499985;
%     1251513, 1249985, 1200293, 1250190, 1349902, 1249918, 1350391, 2299878, 2499975;
%     1351615, 1249985, 1250317, 1300209, 1599902, 1299918, 1400391, 499972, 0;
%     1301936, 1599887, 1899807, 2149757, 1649687, 2799619, 3299323, 2499391, 3999998
% ];
% 
% % 评委总分（三个评委分数之和，13行 x 9周）
% % 注意：有些周有4个评委，但题目说明通常为3个评委，这里我们取前3个评委分数之和
% judgeScores = [
%     17.5, 0, 0, 0, 0, 0, 0, 0, 0;           % Nikki: 6+5.5+6=17.5
%     18, 18.5, 0, 0, 0, 0, 0, 0, 0;          % Danelle: 6+6+6=18; 6.5+6+6=18.5
%     19.5, 20.5, 22, 0, 0, 0, 0, 0, 0;       % Nancy: 6.5+6.5+6.5=19.5; 7+6.5+7=20.5; 8+7+7=22
%     18, 21.5, 21, 21, 24, 19, 27, 0, 0;     % John: 7+5+6=18; 7.5+6.5+7.5=21.5; 7+7+7=21; ...
%     20, 23, 24, 26, 25, 24, 0, 0, 0;        % Mary: 6.5+7+6.5=20; 8+7.5+7.5=23; 8+8+8=24; ...
%     22, 26, 30, 24, 29, 30, 28, 30, 0;      % Juan: 7+7+8=22; 9+8+9=26; 10+10+10=30; ...
%     23, 23.5, 26, 22, 26, 26, 26.5, 0, 0;   % DeMarcus: 8+7+8=23; 8+7.5+8=23.5; 9+8+9=26; ...
%     23, 26, 27, 26, 0, 0, 0, 0, 0;          % Tinashe: 8+7+8=23; 9+8+9=26; 9+9+9=27; ...
%     18, 24, 27, 24, 24, 29, 29.5, 29, 30;   % Evanna: 7+5+6=18; 8+8+8=24; 9+9+9=27; ...
%     22, 24.5, 26, 25, 29, 27, 27.5, 29, 28.5; % Alexis: 7+7.5+7.5=22; 8+8.5+8=24.5; ...
%     20, 26, 27, 29, 27, 30, 29, 27.5, 30;   % Milo: 7+6+7=20; 9+8+9=26; 9+9+9=27; ...
%     14, 17.5, 18, 15, 17, 22, 23.5, 23, 0;  % Joe: 5+4+5=14; 5.5+6+6=17.5; 6+6+6=18; ...
%     20, 19.5, 23, 20, 21, 22, 26.5, 22.5, 27 % Bobby: 7+6+7=20; 7+6+6.5=19.5; 8+7+8=23; ...
% ];
% 
% % 选手名字列表（用于调试）
% names = {
%     'Nikki Glaser', 'Danelle Umstead', 'Nancy McKeon', 'John Schneider', ...
%     'Mary Lou Retton', 'Juan Pablo Di Pace', 'DeMarcus Ware', 'Tinashe', ...
%     'Evanna Lynch', 'Alexis Ren', 'Milo Manheim', 'Joe Amabile', 'Bobby Bones'
% };
% 
% % Bobby Bones的索引
% bobbyIdx = 13;
% 
% %% 初始化结果存储
% numWeeks = 9;
% rankByRankMethod = zeros(1, numWeeks);
% rankByPercentMethod = zeros(1, numWeeks);
% 
% %% 每周计算排名
% for week = 1:numWeeks
%     % 1. 确定当周剩余选手（评委总分 > 0）
%     remainingIdx = judgeScores(:, week) > 0;
%     if ~any(remainingIdx)
%         break; % 如果所有选手都被淘汰，结束
%     end
% 
%     % 提取当周剩余选手的数据
%     currentJudgeScores = judgeScores(remainingIdx, week);
%     currentFanVotes = fanVotes(remainingIdx, week);
% 
%     % 2. 计算评委排名（分数越高排名数字越小）
%     [~, judgeRankOrder] = sort(currentJudgeScores, 'descend');
%     judgeRanks = zeros(size(currentJudgeScores));
%     judgeRanks(judgeRankOrder) = 1:length(currentJudgeScores);
% 
%     % 3. 计算粉丝投票排名（票数越高排名数字越小）
%     [~, fanRankOrder] = sort(currentFanVotes, 'descend');
%     fanRanks = zeros(size(currentFanVotes));
%     fanRanks(fanRankOrder) = 1:length(currentFanVotes);
% 
%     % 4. 排名合并法：综合排名 = 评委排名 + 粉丝排名（和越小排名越高）
%     combinedRank = judgeRanks + fanRanks;
%     [~, finalRankOrderByRank] = sort(combinedRank);
%     finalRanksByRank = zeros(size(combinedRank));
%     finalRanksByRank(finalRankOrderByRank) = 1:length(combinedRank);
% 
%     % 5. 百分比合并法
%     judgePercent = currentJudgeScores / sum(currentJudgeScores) * 100;
%     fanPercent = currentFanVotes / sum(currentFanVotes) * 100;
%     combinedPercent = judgePercent + fanPercent;
%     [~, finalRankOrderByPercent] = sort(combinedPercent, 'descend');
%     finalRanksByPercent = zeros(size(combinedPercent));
%     finalRanksByPercent(finalRankOrderByPercent) = 1:length(combinedPercent);
% 
%     % 6. 找到Bobby Bones在剩余选手中的位置
%     originalIdx = find(remainingIdx);
%     bobbyPos = find(originalIdx == bobbyIdx);
%     if ~isempty(bobbyPos)
%         rankByRankMethod(week) = finalRanksByRank(bobbyPos);
%         rankByPercentMethod(week) = finalRanksByPercent(bobbyPos);
%     else
%         % 如果Bobby Bones本周已被淘汰，则排名为NaN（不显示）
%         rankByRankMethod(week) = NaN;
%         rankByPercentMethod(week) = NaN;
%     end
% end
% 
% %% 绘制折线图
% weeks = 1:numWeeks;
% figure('Position', [100, 100, 850, 550]);
% plot(weeks, rankByRankMethod, '-o', 'LineWidth', 2.5, 'MarkerSize', 10, 'DisplayName', '排名合并法');
% hold on;
% plot(weeks, rankByPercentMethod, '-s', 'LineWidth', 2.5, 'MarkerSize', 10, 'DisplayName', '百分比合并法');
% hold off;
% 
% % 图表设置
% xlabel('Week', 'FontSize', 14, 'FontWeight', 'bold');
% ylabel('Rank (数字越小排名越高)', 'FontSize', 14, 'FontWeight', 'bold');
% title('第27赛季: Bobby Bones 每周排名变化 (两种合并方法)', 'FontSize', 16, 'FontWeight', 'bold');
% legend('Location', 'best', 'FontSize', 12);
% grid on;
% set(gca, 'YDir', 'reverse'); % 纵轴反向，使排名数字越小位置越高
% ylim([0, max([rankByRankMethod, rankByPercentMethod]) + 1]);
% xlim([0.5, numWeeks+0.5]);
% set(gca, 'XTick', 1:numWeeks);
% set(gca, 'FontSize', 12);
% 
% % 添加Bobby Bones最终结果标注
% text(numWeeks, rankByRankMethod(end), ' 冠军', 'FontSize', 10, 'Color', 'blue');
% text(numWeeks, rankByPercentMethod(end), ' 冠军', 'FontSize', 10, 'Color', 'red');
% 
% % 添加网格和背景色
% ax = gca;
% ax.GridColor = [0.3, 0.3, 0.3];
% ax.GridAlpha = 0.2;
% ax.MinorGridColor = [0.8, 0.8, 0.8];
% ax.MinorGridLineStyle = ':';
% 
% %% 输出排名数据
% fprintf('第27赛季 - Bobby Bones 每周排名\n');
% fprintf('Week\tRank by Rank\tRank by Percent\n');
% fprintf('----\t------------\t--------------\n');
% for week = 1:numWeeks
%     if isnan(rankByRankMethod(week))
%         fprintf('%d\t已淘汰\t\t已淘汰\n', week);
%     else
%         fprintf('%d\t%d\t\t%d\n', week, rankByRankMethod(week), rankByPercentMethod(week));
%     end
% end
% 
% % 计算平均排名
% validWeeksRank = rankByRankMethod(~isnan(rankByRankMethod));
% validWeeksPercent = rankByPercentMethod(~isnan(rankByPercentMethod));
% if ~isempty(validWeeksRank)
%     fprintf('\n平均排名 (排名合并法): %.2f\n', mean(validWeeksRank));
%     fprintf('平均排名 (百分比合并法): %.2f\n', mean(validWeeksPercent));
% end
% 
% %% 创建数据表格用于显示
% fprintf('\n详细排名数据:\n');
% T = table((1:numWeeks)', rankByRankMethod', rankByPercentMethod', ...
%     'VariableNames', {'Week', 'Rank_by_Rank', 'Rank_by_Percent'});
% disp(T);


%% 第27赛季数据
% 选手名单（按粉丝投票数表格顺序）
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
n = length(contestants);
weeks = 9;

% 粉丝投票数（13×9）
fan_votes = [
    30036,      0,      0,      0,      0,      0,      0,      0,      0;
    250253, 99965,      0,      0,      0,      0,      0,      0,      0;
    350701, 349968, 50024,      0,      0,      0,      0,      0,      0;
    450803, 449985, 500121, 550105, 549902, 549918, 300102,      0,      0;
    550904, 549985, 600146, 650114, 649902, 299973,      0,      0,      0;
    651006, 649985, 700170, 750124, 749902, 749918, 850234, 399978,      0;
    751107, 749985, 800195, 850133, 849902, 849918, 399976,      0,      0;
    851209, 849985, 900219, 250038,      0,      0,      0,      0,      0;
    951310, 949985, 1000244, 1050152, 1049902, 1049918, 1150391, 1999890, 1999980;
    1051412, 1049985, 1100268, 1150171, 1149902, 1149918, 1250391, 1999890, 1499985;
    1151513, 1149985, 1200293, 1250190, 1249902, 1249918, 1350391, 2099878, 2499975;
    1251615, 1249985, 1250317, 1300209, 1299902, 1299918, 1400391, 499972,  0;
    1701936, 1799887, 1899807, 2149757, 2449687, 2799619, 3299323, 2999391, 3999998
];

% 评委总分（13×9），已按选手顺序重新排列
judge_scores = [
    17.5, 0, 0, 0, 0, 0, 0, 0, 0;           % Nikki Glaser
    18, 18.5, 0, 0, 0, 0, 0, 0, 0;          % Danelle Umstead
    19.5, 20.5, 22, 0, 0, 0, 0, 0, 0;       % Nancy McKeon
    18, 21.5, 21, 21, 24, 19, 27, 0, 0;     % John Schneider
    20, 23, 24, 26, 25, 24, 0, 0, 0;        % Mary Lou Retton
    22, 26, 30, 24, 29, 30, 28, 30, 0;      % Juan Pablo Di Pace
    23, 23.5, 26, 22, 26, 26, 26.5, 0, 0;   % DeMarcus Ware
    23, 26, 27, 26, 0, 0, 0, 0, 0;          % Tinashe
    18, 24, 27, 24, 24, 29, 29.5, 29, 30;   % Evanna Lynch
    22.5, 24.5, 26, 25, 29, 27, 27.5, 29, 28.5; % Alexis Ren
    20, 26, 27, 29, 27, 30, 29, 27.5, 30;   % Milo Manheim
    14, 17.5, 18, 15, 17, 22, 23.5, 23, 0;  % Joe Amabile
    20, 19.5, 23, 20, 21, 22, 26.5, 22.5, 27  % Bobby Bones
];

% Bobby Bones的索引
bb_idx = 13;

%% 排名合并计分法模拟
% 情况1: 仅按排名合并计分法淘汰末位
remaining1 = true(n,1);
rank_method1 = zeros(weeks,1);

for w = 1:weeks
    % 当前剩余选手
    idx = remaining1;
    if sum(idx) == 0, break; end
    
    % 评委总分排名 (分数高 -> 排名数字小)
    [~, judge_rank] = sort(judge_scores(idx,w), 'descend');
    judge_rank_order = zeros(sum(idx),1);
    judge_rank_order(judge_rank) = 1:sum(idx);
    
    % 粉丝投票排名 (票数高 -> 排名数字小)
    [~, fan_rank] = sort(fan_votes(idx,w), 'descend');
    fan_rank_order = zeros(sum(idx),1);
    fan_rank_order(fan_rank) = 1:sum(idx);
    
    % 总排名 = 评委排名 + 粉丝排名
    total_rank = judge_rank_order + fan_rank_order;
    [~, final_order] = sort(total_rank);
    final_rank = zeros(sum(idx),1);
    final_rank(final_order) = 1:sum(idx);
    
    % Bobby Bones的排名
    temp_idx = find(idx);
    bb_pos = find(temp_idx == bb_idx);
    rank_method1(w) = final_rank(bb_pos);
    
    % 淘汰最后一名
    [~, eliminate] = max(total_rank);
    elim_idx = temp_idx(eliminate);
    remaining1(elim_idx) = false;
end

% 情况2: 排名合并计分法 + 淘汰末两位中评委排名较差者
remaining2 = true(n,1);
rank_method2 = zeros(weeks,1);

for w = 1:weeks
    idx = remaining2;
    if sum(idx) <= 2, break; end
    
    % 评委总分排名
    [~, judge_rank] = sort(judge_scores(idx,w), 'descend');
    judge_rank_order = zeros(sum(idx),1);
    judge_rank_order(judge_rank) = 1:sum(idx);
    
    % 粉丝投票排名
    [~, fan_rank] = sort(fan_votes(idx,w), 'descend');
    fan_rank_order = zeros(sum(idx),1);
    fan_rank_order(fan_rank) = 1:sum(idx);
    
    % 总排名
    total_rank = judge_rank_order + fan_rank_order;
    [~, final_order] = sort(total_rank);
    final_rank = zeros(sum(idx),1);
    final_rank(final_order) = 1:sum(idx);
    
    % Bobby Bones的排名
    temp_idx = find(idx);
    bb_pos = find(temp_idx == bb_idx);
    rank_method2(w) = final_rank(bb_pos);
    
    % 找出总排名最后两名
    [~, bottom2] = maxk(total_rank, 2); % 总排名数字最大的两个
    % 在这两人中淘汰评委排名较差者（评委排名数字较大）
    if judge_rank_order(bottom2(1)) > judge_rank_order(bottom2(2))
        elim_local = bottom2(1);
    else
        elim_local = bottom2(2);
    end
    elim_idx = temp_idx(elim_local);
    remaining2(elim_idx) = false;
end

%% 百分比合并计分法模拟
% 情况3: 仅按百分比合并法淘汰末位
remaining3 = true(n,1);
rank_percent1 = zeros(weeks,1);

for w = 1:weeks
    idx = remaining3;
    if sum(idx) == 0, break; end
    
    % 评委总分百分比
    judge_total = judge_scores(idx,w);
    judge_percent = judge_total / sum(judge_total);
    
    % 粉丝投票百分比
    fan_total = fan_votes(idx,w);
    fan_percent = fan_total / sum(fan_total);
    
    % 总百分比
    total_percent = judge_percent + fan_percent;
    [~, final_order] = sort(total_percent, 'descend');
    final_rank = zeros(sum(idx),1);
    final_rank(final_order) = 1:sum(idx);
    
    % Bobby Bones的排名
    temp_idx = find(idx);
    bb_pos = find(temp_idx == bb_idx);
    rank_percent1(w) = final_rank(bb_pos);
    
    % 淘汰总百分比最低者
    [~, eliminate] = min(total_percent);
    elim_idx = temp_idx(eliminate);
    remaining3(elim_idx) = false;
end

% 情况4: 百分比合并法 + 淘汰末两位中评委百分比较差者
remaining4 = true(n,1);
rank_percent2 = zeros(weeks,1);

for w = 1:weeks
    idx = remaining4;
    if sum(idx) <= 2, break; end
    
    % 评委总分百分比
    judge_total = judge_scores(idx,w);
    judge_percent = judge_total / sum(judge_total);
    
    % 粉丝投票百分比
    fan_total = fan_votes(idx,w);
    fan_percent = fan_total / sum(fan_total);
    
    % 总百分比
    total_percent = judge_percent + fan_percent;
    [~, final_order] = sort(total_percent, 'descend');
    final_rank = zeros(sum(idx),1);
    final_rank(final_order) = 1:sum(idx);
    
    % Bobby Bones的排名
    temp_idx = find(idx);
    bb_pos = find(temp_idx == bb_idx);
    rank_percent2(w) = final_rank(bb_pos);
    
    % 找出总百分比最后两名
    [~, bottom2] = mink(total_percent, 2);
    % 在这两人中淘汰评委百分比较低者
    if judge_percent(bottom2(1)) < judge_percent(bottom2(2))
        elim_local = bottom2(1);
    else
        elim_local = bottom2(2);
    end
    elim_idx = temp_idx(elim_local);
    remaining4(elim_idx) = false;
end

%% 绘制图形
figure(1);
plot(1:weeks, rank_method1, '-o', 'LineWidth', 2, 'DisplayName', '仅按排名合并计分法');
hold on;
plot(1:weeks, rank_method2, '-s', 'LineWidth', 2, 'DisplayName', '排名法+淘汰末两位评委较差者');
xlabel('Week');
ylabel('排名 (数字越小越好)');
title('Bobby Bones第27赛季排名变化 (排名合并计分法)');
legend('Location', 'best');
grid on;
set(gca, 'YDir', 'reverse'); % 排名数字小在上方
ylim([0 max([rank_method1; rank_method2])+1]);

figure(2);
plot(1:weeks, rank_percent1, '-o', 'LineWidth', 2, 'DisplayName', '仅按百分比合并法');
hold on;
plot(1:weeks, rank_percent2, '-s', 'LineWidth', 2, 'DisplayName', '百分比法+淘汰末两位评委较差者');
xlabel('Week');
ylabel('排名 (数字越小越好)');
title('Bobby Bones第27赛季排名变化 (百分比合并计分法)');
legend('Location', 'best');
grid on;
set(gca, 'YDir', 'reverse');
ylim([0 max([rank_percent1; rank_percent2])+1]);

%% 输出结果
fprintf('=== 排名合并计分法 ===\n');
fprintf('Week\t仅排名法\t排名法+评委淘汰\n');
for w = 1:weeks
    fprintf('%d\t%d\t\t%d\n', w, rank_method1(w), rank_method2(w));
end

fprintf('\n=== 百分比合并计分法 ===\n');
fprintf('Week\t仅百分比法\t百分比法+评委淘汰\n');
for w = 1:weeks
    fprintf('%d\t%d\t\t%d\n', w, rank_percent1(w), rank_percent2(w));
end%d名\n', rank_method4(end));