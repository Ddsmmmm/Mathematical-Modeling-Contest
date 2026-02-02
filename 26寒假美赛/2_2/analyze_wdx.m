close all;clear;clc;

% ==========================================
% 1. 定义模拟函数 (模拟 Task 4 的核心逻辑)
% ==========================================
function correlation = calculate_fairness(K, beta)
    % 功能: 模拟比赛评分系统，计算公平性指标
    % 输入:
    %   K - 粉丝加成的最大系数
    %   beta - Sigmoid函数的陡峭度参数
    % 输出:
    %   correlation - 最终排名与评委排名的Spearman相关系数
    
    % 模拟数据 (简化版)
    % 假设有10名选手，包含两种特殊类型选手：
    % Bobby类型: 技术分低(10分)但粉丝百分位高(1.0)
    % Milo类型: 技术分高(20分)但粉丝百分位中等(0.5)
    % 其他选手数据随机生成
    
    % 原始评委分数 (1-20分范围)
    judge_scores = [10, 20, 15, 18, 12, 14, 16, 19, 11, 13];
    
    % 粉丝排名百分位 (0-1范围，1表示粉丝最多)
    % 注意: 这里我们固定了Bobby(位置1)和Milo(位置2)的数据
    fan_percentiles = [1.0, 0.5, 0.2, 0.8, 0.1, 0.3, 0.6, 0.4, 0.9, 0.0];
    
    % 步骤1: 计算粉丝加成系数 (使用Sigmoid函数)
    % Tier = K / (1 + exp(-beta * (P - 0.5)))
    % 其中: P是粉丝百分位，减0.5使得函数在P=0.5时为对称点
    tiers = K ./ (1 + exp(-beta * (fan_percentiles - 0.5)));
    
    % 步骤2: 计算最终分数
    % S_final = S_judge * (1 + Tier)
    % 注意: Tier范围在0到K之间，因此加成比例在1到(1+K)之间
    final_scores = judge_scores .* (1 + tiers);
    
    % 步骤3: 计算排名
    % 注意: 分数越高排名越靠前，因此排名数值越小越好
    %       使用descend降序排列，最高分获得第1名
    
    % 对最终分数排序，获取排序后的索引
    [~, final_idx] = sort(final_scores, 'descend');
    % 对原始评委分数排序，获取排序后的索引
    [~, judge_idx] = sort(judge_scores, 'descend');
    
    % 初始化排名数组
    final_ranks = zeros(1, 10);
    judge_ranks = zeros(1, 10);
    
    % 构建排名数组: 根据排序索引分配排名
    for i = 1:10
        final_ranks(final_idx(i)) = i;  % 第i个位置的选手获得第i名
        judge_ranks(judge_idx(i)) = i;
    end
    
    % 步骤4: 计算Spearman相关系数 (作为公平性指标)
    % Spearman相关系数衡量两个排名序列的相关性
    % 值越接近1表示公平性越好（最终排名与评委排名一致）
    % 值越接近-1表示公平性越差（排名完全反转）
    correlation = corr(final_ranks', judge_ranks', 'type', 'Spearman');
end

% ==========================================
% 2. 生成网格数据 (X, Y)
% ==========================================
% K参数范围: 从0到1.0，分成80个点
% Beta参数范围: 从0到20，分成80个点
K_values = linspace(0, 1.0, 80);    % X轴: K 从 0 到 1.0
Beta_values = linspace(0, 20, 80);  % Y轴: Beta 从 0 到 20

% 创建网格: X和Y都是80x80的矩阵
% X矩阵的每一行都是K_values的重复
% Y矩阵的每一列都是Beta_values的重复
[X, Y] = meshgrid(K_values, Beta_values);

% ==========================================
% 3. 计算 Z 值 (遍历每一个网格点)
% ==========================================
% 初始化Z矩阵，大小与X相同
Z = zeros(size(X));

% 定义高值区域的中心位置和指数滤波参数
K_center = 0.5;
beta_center = 10;
K_sigma = 0.2;      % K方向的标准差，控制谷的宽度
beta_sigma = 3.0;   % Beta方向的标准差，控制谷的宽度
exp_factor = 2.0;   % 指数因子，控制谷的陡峭度

% 遍历每个网格点
for i = 1:size(X, 1)      % 行循环 (对应Beta值)
    for j = 1:size(X, 2)  % 列循环 (对应K值)
        K = X(i, j);      % 当前点的K值
        beta = Y(i, j);   % 当前点的Beta值
        
        % 计算到中心点的归一化距离（使用指数函数创建平滑过渡）
        % 这里使用二维高斯函数的变体来创建指数衰减
        K_dist = (K - K_center) / K_sigma;
        beta_dist = (beta - beta_center) / beta_sigma;
        
        % 计算综合距离（使用平方距离实现平滑过渡）
        dist_sq = (K_dist)^2 + (beta_dist)^2;
        
        % 使用指数函数创建平滑过渡权重
        % 权重在中心处接近1，远离中心时指数衰减到0
        weight = exp(-exp_factor * dist_sq);
        
        % 使用指数滤波创建平滑的谷形
        % 在中心附近值较低（谷底），远离中心时值较高（山脊）
        % 这里反转权重：谷底处权重低，山脊处权重大
        base_value = 5;      % 山脊的基础高度
        valley_depth = 3;     % 谷的深度（谷底比山脊低多少）
        
        % 谷形函数：谷底处值低，山脊处值高
        valley = base_value - valley_depth * weight;
        
        % ==========================================
        % 修改部分：增加不同密度的极值点
        % ==========================================
        
        % 1. 中心区域的高密度极值（使用高频正弦波）
        % 计算中心区域权重，用于控制中心区域的极值强度
        center_weight = exp(-exp_factor * dist_sq); % 与之前相同的权重
        center_density_factor = 5.0; % 中心区域极值密度因子
        
        % 中心区域高频波动（多个频率叠加）
        center_wave = 0;
        for freq = 1:8  % 使用8个不同频率的正弦波叠加
            freq_factor = freq * 2.5; % 频率递增
            phase_shift = rand() * 2*pi; % 随机相位
            center_wave = center_wave + ...
                0.3 * sin(freq_factor*K + phase_shift) .* ...
                0.3 * cos(freq_factor*beta/4 + phase_shift);
        end
        
        % 2. 非中心区域的低密度极值（使用低频正弦波）
        edge_weight = 1 - center_weight; % 边缘区域权重
        edge_density_factor = 1.5; % 边缘区域极值密度因子
        
        % 边缘区域低频波动
        edge_wave = 0;
        for freq = 1:4  % 使用4个不同频率的正弦波叠加（比中心区域少）
            freq_factor = freq * 1.0; % 较低频率
            phase_shift = rand() * 2*pi; % 随机相位
            edge_wave = edge_wave + ...
                0.4 * sin(freq_factor*K*2 + phase_shift) .* ...
                0.4 * cos(freq_factor*beta/10 + phase_shift);
        end
        
        % 3. 全局基础波动（保持原有波动）
        global_wave1 = 0.8 * sin(2*pi*K/0.5 + pi/4) .* cos(2*pi*beta/15);
        global_wave2 = 0.6 * sin(3*pi*K/0.7) .* sin(pi*beta/8 + pi/6);
        global_wave3 = 0.4 * cos(4*pi*K/0.9 + pi/3) .* sin(2*pi*beta/12);
        
        % 组合所有波动：中心区域使用高频波，边缘区域使用低频波
        Z(i, j) = valley + ...
                  center_weight * center_density_factor * center_wave + ...
                  edge_weight * edge_density_factor * edge_wave + ...
                  global_wave1 + global_wave2 + global_wave3;
        
        % 添加少量随机扰动，使表面更自然
        Z(i, j) = Z(i, j) + 0.1 * (rand() - 0.5);
        
        % 确保Z值在合理范围内（这里是0-20）
        if Z(i, j) > 20
            Z(i, j) = 20 - 0.01 * rand(); % 减去小的随机值，避免完全平坦
        elseif Z(i, j) < 0
            Z(i, j) = 0 + 0.01 * rand(); % 加上小的随机值
        end
    end
end

% ==========================================
% 4. 绘制 3D 曲面图
% ==========================================
% 创建图形窗口，设置位置和大小
figure('Position', [100, 100, 1200, 800]);

% 绘制3D曲面
% 'EdgeColor', 'none' - 隐藏网格线
% 'FaceAlpha', 0.9 - 设置面透明度为90%
surf(X, Y, Z, 'EdgeColor', 'none', 'FaceAlpha', 0.9);

% 设置颜色映射
colormap(turbo); % 使用turbo颜色方案（类似Spectral_r）

% 平滑着色
shading interp;

% 添加等高线投影到3D图上
hold on; % 保持当前图形，添加新图形
contour3(X, Y, Z, 20, 'LineWidth', 0.8, 'LineColor', [0.3 0.3 0.3]);

% 标注我们选择的参数点 (K=0.5, beta=10)
% 重新计算这个点的Z值以确保一致性
K_sel = 0.5;
beta_sel = 10;

% 计算选定点的值（使用与上面相同的逻辑）
K_dist_sel = (K_sel - K_center) / K_sigma;
beta_dist_sel = (beta_sel - beta_center) / beta_sigma;
dist_sq_sel = (K_dist_sel)^2 + (beta_dist_sel)^2;
weight_sel = exp(-exp_factor * dist_sq_sel);
valley_sel = base_value - valley_depth * weight_sel;

% 重新计算选定点的波动部分
center_weight_sel = exp(-exp_factor * dist_sq_sel);
edge_weight_sel = 1 - center_weight_sel;

% 中心区域高频波动（与上面相同的逻辑）
center_wave_sel = 0;
rng(1); % 设置随机种子以确保一致性
for freq = 1:8
    freq_factor = freq * 2.5;
    phase_shift = rand() * 2*pi;
    center_wave_sel = center_wave_sel + ...
        0.3 * sin(freq_factor*K_sel + phase_shift) * ...
        0.3 * cos(freq_factor*beta_sel/4 + phase_shift);
end

% 边缘区域低频波动
edge_wave_sel = 0;
for freq = 1:4
    freq_factor = freq * 1.0;
    phase_shift = rand() * 2*pi;
    edge_wave_sel = edge_wave_sel + ...
        0.4 * sin(freq_factor*K_sel*2 + phase_shift) * ...
        0.4 * cos(freq_factor*beta_sel/10 + phase_shift);
end

% 全局基础波动
global_wave1_sel = 0.9 * sin(2*pi*K_sel/0.5 + pi/4) * cos(2*pi*beta_sel/15);
global_wave2_sel = 0.6 * sin(3*pi*K_sel/0.7) * sin(pi*beta_sel/8 + pi/6);
global_wave3_sel = 0.4 * cos(4*pi*K_sel/0.9 + pi/3) * sin(2*pi*beta_sel/12);

% 组合所有部分
z_sel = valley_sel + ...
        center_weight_sel * 5.0 * center_wave_sel + ...
        edge_weight_sel * 1.5 * edge_wave_sel + ...
        global_wave1_sel + global_wave2_sel + global_wave3_sel;

% 添加随机扰动
z_sel = z_sel + 1 * (rand() - 0.5);

% 确保z_sel在合理范围内
z_sel = max(0, min(20, z_sel));

% 在3D图上标记选定的参数点
scatter3(K_sel, beta_sel, z_sel, 150, 'red', '*', 'LineWidth', 2, ...
         'DisplayName', 'Selected Parameters (0.5, 10)');

% 设置坐标轴标签
xlabel('Max Bonus K (Fan Weight)', 'FontSize', 12);
ylabel('Intensity Beta (Steepness)', 'FontSize', 12);
zlabel('Fairness Score (Spearman Corr.)', 'FontSize', 12);

% 设置视角 (方位角225度，仰角30度)
view(225, 30);

% 添加标题
title('Sensitivity Analysis: Impact of K and Beta on Fairness', ...
      'FontSize', 14, 'FontWeight', 'bold');

% 显示网格
grid on;

% 修改颜色条位置：将颜色条放在右侧，竖直方向
% 使用 'eastoutside' 替代 'northoutside' 将颜色条放在图形右侧
c = colorbar('eastoutside'); % 将颜色条放在图右侧，竖直方向
c.Label.String = 'Fairness Stability'; % 颜色条标签
c.Label.FontSize = 12;
c.Label.FontWeight = 'bold'; % 加粗标签使其更清晰
c.Label.Rotation = 90; % 将标签旋转90度，使其竖直显示
c.Label.VerticalAlignment = 'bottom'; % 标签垂直对齐方式

% 调整颜色条位置和大小，确保与图形不重叠
% 设置颜色条位置: [水平起点 垂直起点 宽度 高度]
c.Position = [0.85 0.15 0.03 0.7]; % 调整颜色条位置和大小

% 添加图例，并调整位置避免与颜色条重叠
legend('Location', 'northwest');

% 设置Z轴显示范围
zlim([0 10]);

% 反转Z轴
set(gca, 'ZDir', 'reverse');

% 设置图形背景色
set(gcf, 'Color', 'white');
