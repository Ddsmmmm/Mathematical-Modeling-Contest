%% 读取和准备数据
clear; close all; clc;

% 读取主数据文件
data_main = readtable('广义分析.xlsx');
data_partner = readtable('ballroom_partner_counts.xlsx');

% 重命名列以方便处理
data_partner.Properties.VariableNames = {'ballroom_partner', 'Appearance_Count', 'experience_quantified'};

% 将舞伴数据合并到主数据中
[data_main, idx] = sortrows(data_main, 'ballroom_partner');
[data_partner, idx_p] = sortrows(data_partner, 'ballroom_partner');

% 合并舞伴经验数据
partner_experience = zeros(height(data_main), 1);
for i = 1:height(data_main)
    partner_name = data_main.ballroom_partner{i};
    partner_idx = find(strcmp(data_partner.ballroom_partner, partner_name));
    if ~isempty(partner_idx)
        partner_experience(i) = data_partner.experience_quantified(partner_idx);
    else
        % 如果没有找到舞伴经验数据，设为0或平均值
        partner_experience(i) = 0;
    end
end

% 准备回归变量
Y = data_main.placement;  % 排名（因变量）

% 年龄变量
X_age = data_main.celebrity_age_during_season;

% 行业变量 - 使用独热编码
unique_industries = unique(data_main.industry_category);
num_industries = length(unique_industries);
X_industry = zeros(height(data_main), num_industries);

for i = 1:height(data_main)
    ind_idx = find(strcmp(unique_industries, data_main.industry_category{i}));
    X_industry(i, ind_idx) = 1;
end

% 地区变量 - 使用独热编码
unique_regions = unique(data_main.region);
num_regions = length(unique_regions);
X_region = zeros(height(data_main), num_regions);

for i = 1:height(data_main)
    reg_idx = find(strcmp(unique_regions, data_main.region{i}));
    X_region(i, reg_idx) = 1;
end

% 舞伴经验变量
X_partner = partner_experience;

% 合并所有预测变量
% 注意：为了避免虚拟变量陷阱，我们需要从行业和地区变量中删除一列
X = [X_age, X_industry(:, 1:end-1), X_partner, X_region(:, 1:end-1)];

%% 标准化变量
% 对连续变量进行标准化（年龄和舞伴经验）
X_age_std = (X_age - mean(X_age)) / std(X_age);
X_partner_std = (X_partner - mean(X_partner)) / std(X_partner);

% 创建标准化后的X矩阵
X_std = [X_age_std, X_industry(:, 1:end-1), X_partner_std, X_region(:, 1:end-1)];

% 添加截距项
X_std = [ones(size(X_std, 1), 1), X_std];

%% 执行多元线性回归
% 使用最小二乘法
beta = (X_std' * X_std) \ (X_std' * Y);

% 或者使用内置的regress函数
% [beta, bint, r, rint, stats] = regress(Y, X_std);

%% 计算标准化系数（Beta系数）
% Beta系数可以直接解释为变量的重要性
% 对于已经标准化的变量，回归系数就是标准化系数

% 提取各项系数
intercept = beta(1);  % 截距
age_coef_std = beta(2);  % 年龄的标准化系数

% 行业系数的平均值（由于是分类变量，取平均效应）
industry_start_idx = 3;
industry_end_idx = industry_start_idx + num_industries - 2;
industry_coefs = beta(industry_start_idx:industry_end_idx);
industry_coef_std = mean(abs(industry_coefs)) * sign(mean(industry_coefs));

% 舞伴经验系数
partner_coef_std = beta(industry_end_idx + 1);

% 地区系数的平均值
region_start_idx = industry_end_idx + 2;
region_end_idx = region_start_idx + num_regions - 2;
region_coefs = beta(region_start_idx:region_end_idx);
region_coef_std = mean(abs(region_coefs)) * sign(mean(region_coefs));

%% 将系数标准化到[-1, 1]范围
% 找到所有系数中的最大值
all_coefs = [age_coef_std; industry_coef_std; partner_coef_std; region_coef_std];
max_abs_coef = max(abs(all_coefs));

% 如果最大值大于1，则进行缩放
if max_abs_coef > 0
    age_coef_norm = age_coef_std / max_abs_coef;
    industry_coef_norm = industry_coef_std / max_abs_coef;
    partner_coef_norm = partner_coef_std / max_abs_coef;
    region_coef_norm = region_coef_std / max_abs_coef;
else
    age_coef_norm = age_coef_std;
    industry_coef_norm = industry_coef_std;
    partner_coef_norm = partner_coef_std;
    region_coef_norm = region_coef_std;
end

%% 显示结果
fprintf('===== 多元线性回归结果 =====\n');
fprintf('模型: Y_rank = δ0 + δ1*年龄 + δ2*行业 + δ3*舞伴经验 + δ4*地区\n\n');

fprintf('原始回归系数:\n');
fprintf('δ0 (截距): %.4f\n', intercept);
fprintf('δ1 (年龄系数): %.4f\n', age_coef_std);
fprintf('δ2 (行业系数): %.4f\n', industry_coef_std);
fprintf('δ3 (舞伴系数): %.4f\n', partner_coef_std);
fprintf('δ4 (地区系数): %.4f\n', region_coef_std);

fprintf('\n标准化到[-1, 1]范围的系数:\n');
fprintf('δ1 (年龄系数): %.4f\n', age_coef_norm);
fprintf('δ2 (行业系数): %.4f\n', industry_coef_norm);
fprintf('δ3 (舞伴系数): %.4f\n', partner_coef_norm);
fprintf('δ4 (地区系数): %.4f\n', region_coef_norm);

fprintf('\n系数解释:\n');
fprintf('正值表示该因素对排名有下降作用(使排名数字变大，表现更差)\n');
fprintf('负值表示该因素对排名有提高作用(使排名数字变小，表现更好)\n');

%% 计算R²值评估模型拟合度
Y_pred = X_std * beta;
SS_res = sum((Y - Y_pred).^2);
SS_tot = sum((Y - mean(Y)).^2);
R_squared = 1 - SS_res/SS_tot;

fprintf('\n===== 模型评估 =====\n');
fprintf('R²值: %.4f\n', R_squared);
fprintf('解释方差比例: %.2f%%\n', R_squared * 100);

%% 可视化结果
figure('Position', [100, 100, 800, 600]);

% 子图1: 系数可视化
subplot(2,2,1);
coef_names = {'年龄', '行业', '舞伴经验', '地区'};
coef_values = [age_coef_norm, industry_coef_norm, partner_coef_norm, region_coef_norm];
bar(coef_values);
set(gca, 'XTickLabel', coef_names);
ylabel('标准化系数');
title('各因素对排名的影响系数');
grid on;

% 添加系数值标签
for i = 1:length(coef_values)
    if coef_values(i) >= 0
        text(i, coef_values(i)+0.02, sprintf('%.3f', coef_values(i)), ...
            'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    else
        text(i, coef_values(i)-0.02, sprintf('%.3f', coef_values(i)), ...
            'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    end
end
ylim([-1.1, 1.1]);

% 子图2: 实际vs预测排名
subplot(2,2,2);
scatter(Y, Y_pred, 50, 'filled');
hold on;
plot([min(Y), max(Y)], [min(Y), max(Y)], 'r--', 'LineWidth', 2);
xlabel('实际排名');
ylabel('预测排名');
title(sprintf('实际vs预测排名 (R²=%.3f)', R_squared));
grid on;
legend('数据点', '理想拟合线', 'Location', 'best');

% 子图3: 残差图
subplot(2,2,3);
residuals = Y - Y_pred;
scatter(Y_pred, residuals, 50, 'filled');
hold on;
plot([min(Y_pred), max(Y_pred)], [0, 0], 'r-', 'LineWidth', 2);
xlabel('预测排名');
ylabel('残差');
title('残差分析');
grid on;

% 子图4: 系数影响方向
subplot(2,2,4);
% 创建影响方向图
effects = zeros(4, 3); % 4个因素，3个类别
effects(1,:) = [sum(age_coef_norm>0), sum(age_coef_norm==0), sum(age_coef_norm<0)];
effects(2,:) = [sum(industry_coef_norm>0), sum(industry_coef_norm==0), sum(industry_coef_norm<0)];
effects(3,:) = [sum(partner_coef_norm>0), sum(partner_coef_norm==0), sum(partner_coef_norm<0)];
effects(4,:) = [sum(region_coef_norm>0), sum(region_coef_norm==0), sum(region_coef_norm<0)];

% 转换为百分比
effects_pct = effects ./ sum(effects, 2) * 100;

barh(effects_pct, 'stacked');
set(gca, 'YTickLabel', coef_names);
xlabel('百分比 (%)');
title('各因素影响方向分布');
legend({'正向影响', '无影响', '负向影响'}, 'Location', 'best');
grid on;

%% 保存结果到文件
results_table = table(...
    {'年龄系数'; '行业系数'; '舞伴系数'; '地区系数'}, ...
    [age_coef_norm; industry_coef_norm; partner_coef_norm; region_coef_norm], ...
    'VariableNames', {'因素', '标准化系数'});

writetable(results_table, '回归系数结果.csv');
fprintf('\n结果已保存到: 回归系数结果.csv\n');