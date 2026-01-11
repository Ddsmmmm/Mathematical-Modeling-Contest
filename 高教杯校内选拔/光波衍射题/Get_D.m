%% 红外干涉测厚模型 - 两光束干涉厚度反演（使用1000-4000 cm⁻¹数据）
clear; clc; close all;

%% 1. 读取数据
data1 = readmatrix('附件1.xlsx');
data2 = readmatrix('附件2.xlsx');

% 提取数据
wavenumber1_raw = data1(:, 1);  % 原始波数 (cm^-1)
R_exp1_raw = data1(:, 2)/100;   % 原始反射率，转换为小数

wavenumber2_raw = data2(:, 1);  % 原始波数 (cm^-1)
R_exp2_raw = data2(:, 2)/100;   % 原始反射率，转换为小数

% 舍弃小于1000 cm⁻¹的波数段，只保留1000-4000 cm⁻¹数据
valid_idx1 = wavenumber1_raw >= 1000 & wavenumber1_raw <= 4000;
valid_idx2 = wavenumber2_raw >= 1000 & wavenumber2_raw <= 4000;

wavenumber1 = wavenumber1_raw(valid_idx1);
R_exp1 = R_exp1_raw(valid_idx1);

wavenumber2 = wavenumber2_raw(valid_idx2);
R_exp2 = R_exp2_raw(valid_idx2);

% 参数设置
n0 = 1;          % 空气折射率
n2 = 2.65;       % SiC衬底折射率
theta1_deg = 10; % 入射角1 (度)
theta2_deg = 15; % 入射角2 (度)
theta1 = deg2rad(theta1_deg);
theta2 = deg2rad(theta2_deg);

% 波数转换为波长 (μm)
% λ (μm) = 10^4 / wavenumber (cm^-1)
lambda1 = 1e4 ./ wavenumber1;  % 波长 (μm)
lambda2 = 1e4 ./ wavenumber2;  % 波长 (μm)

fprintf('数据筛选结果:\n');
fprintf('10°入射角数据点数: %d (原始: %d)\n', length(wavenumber1), length(wavenumber1_raw));
fprintf('15°入射角数据点数: %d (原始: %d)\n', length(wavenumber2), length(wavenumber2_raw));
fprintf('10°入射角波数范围: %.1f - %.1f cm⁻¹\n', min(wavenumber1), max(wavenumber1));
fprintf('15°入射角波数范围: %.1f - %.1f cm⁻¹\n\n', min(wavenumber2), max(wavenumber2));

%% 2. 绘制筛选前后的数据对比
figure('Position', [100, 100, 1200, 400]);

% 原始数据
subplot(1, 2, 1);
plot(wavenumber1_raw, R_exp1_raw, 'b-', 'LineWidth', 1, 'DisplayName', '原始数据');
hold on;
plot(wavenumber2_raw, R_exp2_raw, 'r-', 'LineWidth', 1, 'DisplayName', '原始数据(15°)');
xlabel('波数 (cm^{-1})');
ylabel('反射率');
title('原始干涉光谱 (全波段)');
legend('10°入射角', '15°入射角', 'Location', 'best');
grid on;
xlim([min(wavenumber1_raw), max(wavenumber1_raw)]);
% 标记筛选区域
xline(1000, 'k--', 'LineWidth', 1.5, 'DisplayName', '筛选边界 (1000 cm⁻¹)');
text(1000, max([R_exp1_raw; R_exp2_raw])*0.9, '筛选边界', 'HorizontalAlignment', 'right');

% 筛选后数据
subplot(1, 2, 2);
plot(wavenumber1, R_exp1, 'b-', 'LineWidth', 1.5, 'DisplayName', '筛选后数据(10°)');
hold on;
plot(wavenumber2, R_exp2, 'r-', 'LineWidth', 1.5, 'DisplayName', '筛选后数据(15°)');
xlabel('波数 (cm^{-1})');
ylabel('反射率');
title('筛选后干涉光谱 (1000-4000 cm⁻¹)');
legend('Location', 'best');
grid on;
xlim([min(wavenumber1), max(wavenumber1)]);

%% 3. 通过FFT分析初步估计厚度
% 使用第一个入射角的数据进行估计
figure('Position', [100, 100, 1200, 400]);

% 绘制原始光谱
subplot(1, 3, 1);
plot(wavenumber1, R_exp1, 'b-', 'LineWidth', 1.5);
xlabel('波数 (cm^{-1})');
ylabel('反射率');
title('筛选后干涉光谱 (10°, 1000-4000 cm⁻¹)');
grid on;

% FFT分析
L = length(wavenumber1);
Fs = 1 / (wavenumber1(2) - wavenumber1(1));  % 采样频率 (cm⁻¹)

% 进行FFT
Y = fft(R_exp1 - mean(R_exp1));  % 去除直流分量
P2 = abs(Y/L);
P1 = P2(1:floor(L/2)+1);
P1(2:end-1) = 2*P1(2:end-1);
f = Fs*(0:floor(L/2))/L;  % 频率轴 (cm)

% 绘制频谱
subplot(1, 3, 2);
plot(f, P1, 'r-', 'LineWidth', 1.5);
xlabel('频率 (cm)');
ylabel('幅度');
title('频谱分析 (筛选后数据)');
grid on;
xlim([0, 0.1]);

% 找到主频（忽略零频）
[~, idx] = max(P1(2:end));
f_main = f(idx+1);  % 主频 (cm)
delta_nu = 1/f_main;  % 条纹周期 (cm⁻¹)

% 初步估计厚度
% 使用近似公式: d ≈ 1/(2Δν n1_avg)
% 假设平均折射率 n1_avg = 2.6 (典型值)
n1_avg = 2.6;
d0 = 1e4 / (2 * n1_avg * delta_nu);  % 转换为μm单位

fprintf('初步估计结果 (基于筛选后数据):\n');
fprintf('主频: %.6f cm\n', f_main);
fprintf('条纹周期: %.4f cm⁻¹\n', delta_nu);
fprintf('初步估计厚度: %.2f μm\n\n', d0);

%% 4. 定义理论反射率模型
% Cauchy折射率模型: n1(λ) = A + B/λ^2 (λ in μm)
% 反射率计算函数
function R = calc_reflectivity(lambda, theta, d, A, B, n0, n2)
    % 计算外延层折射率
    n1 = A + B ./ (lambda.^2);
    
    % Snell定律计算折射角
    sin_theta1 = n0 * sin(theta) ./ n1;
    % 避免数值问题
    sin_theta1(sin_theta1 > 1) = 1;
    sin_theta1(sin_theta1 < -1) = -1;
    theta1 = asin(sin_theta1);
    
    sin_theta2 = n1 .* sin(theta1) / n2;
    sin_theta2(sin_theta2 > 1) = 1;
    sin_theta2(sin_theta2 < -1) = -1;
    theta2 = asin(sin_theta2);
    
    % 计算反射系数 (s偏振)
    r01 = (n0*cos(theta) - n1.*cos(theta1)) ./ ...
          (n0*cos(theta) + n1.*cos(theta1));
    r12 = (n1.*cos(theta1) - n2*cos(theta2)) ./ ...
          (n1.*cos(theta1) + n2*cos(theta2));
    
    % 计算相位差
    delta = (4 * pi * n1 .* d .* cos(theta1)) ./ lambda;
    
    % 计算总反射率
    R = abs(r01 + r12 .* exp(1i * delta)).^2;
end

%% 5. 定义目标函数（用于最小二乘拟合）
function residuals = objective_func(params, lambda1, R_exp1, theta1, ...
                                    lambda2, R_exp2, theta2, n0, n2)
    d = params(1);  % 厚度 (μm)
    A = params(2);  % Cauchy参数A
    B = params(3);  % Cauchy参数B (μm^2)
    
    % 计算理论反射率
    R_theory1 = calc_reflectivity(lambda1, theta1, d, A, B, n0, n2);
    R_theory2 = calc_reflectivity(lambda2, theta2, d, A, B, n0, n2);
    
    % 计算残差（两组数据联合）
    residuals = [R_exp1 - R_theory1; R_exp2 - R_theory2];
end

%% 6. 参数拟合（非线性最小二乘）
% 初始参数猜测
A0 = 2.6;    % 折射率典型值
B0 = 0.01;   % 色散系数典型值 (μm^2)
initial_params = [d0, A0, B0];

% 设置拟合选项
options = optimoptions('lsqnonlin', 'Display', 'iter', ...
                       'MaxFunctionEvaluations', 5000, ...
                       'MaxIterations', 1000, ...
                       'FunctionTolerance', 1e-8, ...
                       'StepTolerance', 1e-8);

% 定义匿名函数用于lsqnonlin
obj_func = @(params) objective_func(params, lambda1, R_exp1, theta1, ...
                                     lambda2, R_exp2, theta2, n0, n2);

% 进行非线性最小二乘拟合
fprintf('开始参数拟合 (使用1000-4000 cm⁻¹数据)...\n');
tic;
[params_opt, resnorm, residual, exitflag, output] = ...
    lsqnonlin(obj_func, initial_params, [], [], options);
fitting_time = toc;

% 提取优化参数
d_opt = params_opt(1);
A_opt = params_opt(2);
B_opt = params_opt(3);

fprintf('\n拟合结果 (使用1000-4000 cm⁻¹数据):\n');
fprintf('优化厚度: %.4f μm\n', d_opt);
fprintf('Cauchy参数 A: %.6f\n', A_opt);
fprintf('Cauchy参数 B: %.6f μm²\n', B_opt);
fprintf('残差平方和: %.6f\n', resnorm);
fprintf('拟合迭代次数: %d\n', output.iterations);
fprintf('函数调用次数: %d\n', output.funcCount);
fprintf('退出标志: %d\n', exitflag);
fprintf('拟合时间: %.2f 秒\n', fitting_time);

%% 7. 计算拟合反射率并绘制对比图
% 计算拟合的反射率
R_fit1 = calc_reflectivity(lambda1, theta1, d_opt, A_opt, B_opt, n0, n2);
R_fit2 = calc_reflectivity(lambda2, theta2, d_opt, A_opt, B_opt, n0, n2);

% 绘制拟合结果对比
figure('Position', [100, 100, 1200, 500]);

% 10°入射角
subplot(1, 2, 1);
plot(wavenumber1, R_exp1, 'b-', 'LineWidth', 1.5, 'DisplayName', '实验数据');
hold on;
plot(wavenumber1, R_fit1, 'r--', 'LineWidth', 2, 'DisplayName', '拟合结果');
xlabel('波数 (cm^{-1})');
ylabel('反射率');
title(sprintf('10°入射角 - 拟合对比 (d=%.2f μm, 1000-4000 cm⁻¹)', d_opt));
legend('Location', 'best');
grid on;
xlim([min(wavenumber1), max(wavenumber1)]);

% 15°入射角
subplot(1, 2, 2);
plot(wavenumber2, R_exp2, 'b-', 'LineWidth', 1.5, 'DisplayName', '实验数据');
hold on;
plot(wavenumber2, R_fit2, 'r--', 'LineWidth', 2, 'DisplayName', '拟合结果');
xlabel('波数 (cm^{-1})');
ylabel('反射率');
title(sprintf('15°入射角 - 拟合对比 (d=%.2f μm, 1000-4000 cm⁻¹)', d_opt));
legend('Location', 'best');
grid on;
xlim([min(wavenumber2), max(wavenumber2)]);

%% 8. 绘制残差图
figure('Position', [100, 100, 1200, 400]);

subplot(1, 2, 1);
residual1 = R_exp1 - R_fit1;
plot(wavenumber1, residual1, 'k-', 'LineWidth', 1);
hold on;
plot(wavenumber1, zeros(size(wavenumber1)), 'r--', 'LineWidth', 1);
xlabel('波数 (cm^{-1})');
ylabel('残差');
title('10°入射角 - 拟合残差 (1000-4000 cm⁻¹)');
grid on;
xlim([min(wavenumber1), max(wavenumber1)]);
% 调整y轴范围以适应残差
residual_range = max(abs(residual1));
ylim([-1.2*residual_range, 1.2*residual_range]);

subplot(1, 2, 2);
residual2 = R_exp2 - R_fit2;
plot(wavenumber2, residual2, 'k-', 'LineWidth', 1);
hold on;
plot(wavenumber2, zeros(size(wavenumber2)), 'r--', 'LineWidth', 1);
xlabel('波数 (cm^{-1})');
ylabel('残差');
title('15°入射角 - 拟合残差 (1000-4000 cm⁻¹)');
grid on;
xlim([min(wavenumber2), max(wavenumber2)]);
% 调整y轴范围以适应残差
residual_range2 = max(abs(residual2));
ylim([-1.2*residual_range2, 1.2*residual_range2]);

%% 9. 计算并显示折射率随波长的变化
figure('Position', [100, 100, 800, 400]);

% 计算折射率
n1_vals = A_opt + B_opt ./ (lambda1.^2);

% 计算平均折射率
n1_avg_calc = mean(n1_vals);
fprintf('\n折射率分析 (1000-4000 cm⁻¹):\n');
fprintf('平均折射率: %.4f\n', n1_avg_calc);
fprintf('折射率范围: %.4f - %.4f\n', min(n1_vals), max(n1_vals));

subplot(1, 2, 1);
plot(lambda1, n1_vals, 'b-', 'LineWidth', 2);
xlabel('波长 (μm)');
ylabel('折射率 n_1');
title('外延层折射率随波长变化 (1000-4000 cm⁻¹)');
grid on;
xlim([min(lambda1), max(lambda1)]);

subplot(1, 2, 2);
plot(wavenumber1, n1_vals, 'b-', 'LineWidth', 2);
xlabel('波数 (cm^{-1})');
ylabel('折射率 n_1');
title('外延层折射率随波数变化 (1000-4000 cm⁻¹)');
grid on;
xlim([min(wavenumber1), max(wavenumber1)]);

%% 10. 模型验证和一致性分析
fprintf('\n模型一致性分析 (使用1000-4000 cm⁻¹数据):\n');
fprintf('使用相同参数拟合两组数据，厚度: %.4f μm\n', d_opt);

% 计算决定系数 R²
SS_tot1 = sum((R_exp1 - mean(R_exp1)).^2);
SS_res1 = sum(residual1.^2);
R2_1 = 1 - SS_res1/SS_tot1;

SS_tot2 = sum((R_exp2 - mean(R_exp2)).^2);
SS_res2 = sum(residual2.^2);
R2_2 = 1 - SS_res2/SS_tot2;

fprintf('10°入射角决定系数 R²: %.6f\n', R2_1);
fprintf('15°入射角决定系数 R²: %.6f\n', R2_2);

% 计算均方根误差 (RMSE)
RMSE1 = sqrt(mean(residual1.^2));
RMSE2 = sqrt(mean(residual2.^2));
fprintf('10°入射角均方根误差 RMSE: %.6f\n', RMSE1);
fprintf('15°入射角均方根误差 RMSE: %.6f\n', RMSE2);

%% 11. 计算厚度精度和不确定度分析
% 基于FFT主频的厚度不确定度
delta_nu_uncertainty = 0.01 * delta_nu;  % 假设条纹周期有1%的不确定度
d_uncertainty_fft = (1e4 / (2 * n1_avg * delta_nu^2)) * delta_nu_uncertainty;

% 基于拟合残差的厚度不确定度
% 使用Jacobian矩阵的逆估计参数协方差矩阵
J = jacobianest(obj_func, params_opt);
cov_matrix = inv(J'*J) * (resnorm/(length(residual)-length(params_opt)));
d_uncertainty_fit = sqrt(cov_matrix(1,1));

fprintf('\n厚度不确定度分析:\n');
fprintf('基于FFT估计的厚度不确定度: ±%.4f μm\n', d_uncertainty_fft);
fprintf('基于拟合参数的厚度不确定度: ±%.4f μm\n', d_uncertainty_fit);
fprintf('最终厚度估计: %.4f ± %.4f μm\n', d_opt, d_uncertainty_fit);

%% 12. 保存结果
results = struct();
results.thickness = d_opt;
results.thickness_uncertainty = d_uncertainty_fit;
results.A = A_opt;
results.B = B_opt;
results.R2_10deg = R2_1;
results.R2_15deg = R2_2;
results.RMSE_10deg = RMSE1;
results.RMSE_15deg = RMSE2;
results.resnorm = resnorm;
results.initial_guess = [d0, A0, B0];
results.wavenumber_range = [1000, 4000];
results.data_points_10deg = length(wavenumber1);
results.data_points_15deg = length(wavenumber2);
results.n1_average = n1_avg_calc;

save('fitting_results_filtered.mat', 'results');
fprintf('\n结果已保存到 fitting_results_filtered.mat\n');

%% 13. 额外分析：比较不同波数范围的结果
% 为了展示舍弃低波数数据的重要性，我们可以绘制全波段和筛选后波段的对比
figure('Position', [100, 100, 1000, 800]);

% 计算全波段数据的理论反射率（使用拟合参数）
% 注意：这里我们只是用拟合参数计算理论值，不是重新拟合
lambda1_full = 1e4 ./ wavenumber1_raw;
lambda2_full = 1e4 ./ wavenumber2_raw;
R_fit1_full = calc_reflectivity(lambda1_full, theta1, d_opt, A_opt, B_opt, n0, n2);
R_fit2_full = calc_reflectivity(lambda2_full, theta2, d_opt, A_opt, B_opt, n0, n2);

% 绘制全波段对比
subplot(2, 2, 1);
plot(wavenumber1_raw, R_exp1_raw, 'b-', 'LineWidth', 1, 'DisplayName', '实验数据');
hold on;
plot(wavenumber1_raw, R_fit1_full, 'r--', 'LineWidth', 1.5, 'DisplayName', '拟合模型');
xlabel('波数 (cm^{-1})');
ylabel('反射率');
title('10°入射角 - 全波段数据与模型');
legend('Location', 'best');
grid on;
xlim([min(wavenumber1_raw), max(wavenumber1_raw)]);
xline(1000, 'k--', 'LineWidth', 1.5, 'DisplayName', '筛选边界');

subplot(2, 2, 2);
plot(wavenumber2_raw, R_exp2_raw, 'b-', 'LineWidth', 1, 'DisplayName', '实验数据');
hold on;
plot(wavenumber2_raw, R_fit2_full, 'r--', 'LineWidth', 1.5, 'DisplayName', '拟合模型');
xlabel('波数 (cm^{-1})');
ylabel('反射率');
title('15°入射角 - 全波段数据与模型');
legend('Location', 'best');
grid on;
xlim([min(wavenumber2_raw), max(wavenumber2_raw)]);
xline(1000, 'k--', 'LineWidth', 1.5, 'DisplayName', '筛选边界');

% 绘制筛选波段对比（放大查看）
subplot(2, 2, 3);
plot(wavenumber1, R_exp1, 'b-', 'LineWidth', 1.5, 'DisplayName', '实验数据');
hold on;
plot(wavenumber1, R_fit1, 'r--', 'LineWidth', 2, 'DisplayName', '拟合模型');
xlabel('波数 (cm^{-1})');
ylabel('反射率');
title('10°入射角 - 筛选波段(1000-4000 cm⁻¹)');
legend('Location', 'best');
grid on;
xlim([min(wavenumber1), max(wavenumber1)]);

subplot(2, 2, 4);
plot(wavenumber2, R_exp2, 'b-', 'LineWidth', 1.5, 'DisplayName', '实验数据');
hold on;
plot(wavenumber2, R_fit2, 'r--', 'LineWidth', 2, 'DisplayName', '拟合模型');
xlabel('波数 (cm^{-1})');
ylabel('反射率');
title('15°入射角 - 筛选波段(1000-4000 cm⁻¹)');
legend('Location', 'best');
grid on;
xlim([min(wavenumber2), max(wavenumber2)]);

fprintf('\n分析完成！\n');