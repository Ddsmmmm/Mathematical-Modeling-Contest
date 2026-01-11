%% 系统化分析：诊断和解决拟合问题
clear; clc; close all;

%% 1. 数据加载和基本检查
disp('=== 加载和分析数据 ===');
data1 = readmatrix('附件1.xlsx');
data2 = readmatrix('附件2.xlsx');

wavenumber1 = data1(:, 1);
R_exp1_raw = data1(:, 2);
wavenumber2 = data2(:, 1);
R_exp2_raw = data2(:, 2);

% 筛选1000-4000 cm⁻¹
idx1 = wavenumber1 >= 1000 & wavenumber1 <= 4000;
idx2 = wavenumber2 >= 1000 & wavenumber2 <= 4000;

wavenumber1 = wavenumber1(idx1);
R_exp1 = R_exp1_raw(idx1) / 100;
wavenumber2 = wavenumber2(idx2);
R_exp2 = R_exp2_raw(idx2) / 100;

lambda1 = 1e4 ./ wavenumber1;
lambda2 = 1e4 ./ wavenumber2;

% 基本参数
n0 = 1;
theta1 = deg2rad(10);
theta2 = deg2rad(15);

%% 2. 数据完整性检查
fprintf('数据统计:\n');
fprintf('10°数据点: %d, 范围: %.1f-%.1f cm⁻¹\n', length(wavenumber1), min(wavenumber1), max(wavenumber1));
fprintf('15°数据点: %d, 范围: %.1f-%.1f cm⁻¹\n', length(wavenumber2), min(wavenumber2), max(wavenumber2));
fprintf('反射率范围 - 10°: [%.4f, %.4f], 15°: [%.4f, %.4f]\n', ...
    min(R_exp1), max(R_exp1), min(R_exp2), max(R_exp2));

% 检查数据异常
if any(R_exp1 < 0) || any(R_exp1 > 1) || any(R_exp2 < 0) || any(R_exp2 > 1)
    warning('反射率数据超出理论范围 [0,1]！');
    R_exp1 = min(max(R_exp1, 0), 1);
    R_exp2 = min(max(R_exp2, 0), 1);
end

%% 3. 可视化数据特征分析
figure('Position', [50, 50, 1800, 900]);

% 原始数据
subplot(2, 3, 1);
plot(wavenumber1, R_exp1, 'b-', 'LineWidth', 1.5);
hold on;
plot(wavenumber2, R_exp2, 'r-', 'LineWidth', 1.5);
xlabel('波数 (cm^{-1})'); ylabel('反射率');
title('原始光谱数据'); grid on; legend('10°', '15°');

% 差值分析
subplot(2, 3, 2);
% 插值到相同波数网格
wavenumber_common = linspace(max(min(wavenumber1), min(wavenumber2)), ...
                             min(max(wavenumber1), max(wavenumber2)), 1000);
R1_interp = interp1(wavenumber1, R_exp1, wavenumber_common, 'spline');
R2_interp = interp1(wavenumber2, R_exp2, wavenumber_common, 'spline');
difference = R1_interp - R2_interp;
plot(wavenumber_common, difference, 'k-', 'LineWidth', 1.5);
xlabel('波数 (cm^{-1})'); ylabel('ΔR (10°-15°)');
title('两个角度数据差异'); grid on;
ylim([-0.1, 0.1]);

% FFT分析两个角度
subplot(2, 3, 3);
[L1, Fs1, f1, P1_1] = perform_fft_analysis(wavenumber1, R_exp1);
[L2, Fs2, f2, P1_2] = perform_fft_analysis(wavenumber2, R_exp2);

% 找到主频
[~, idx1] = max(P1_1(10:min(100, length(P1_1))));
[~, idx2] = max(P1_2(10:min(100, length(P1_2))));
f_main1 = f1(idx1+9);
f_main2 = f2(idx2+9);

% 估算厚度
n1_est = 2.6;
d_est_fft1 = 1e4 / (2 * n1_est * (1/f_main1));
d_est_fft2 = 1e4 / (2 * n1_est * (1/f_main2));

fprintf('\nFFT分析结果:\n');
fprintf('10°主频: %.6f cm, 估算厚度: %.2f μm\n', f_main1, d_est_fft1);
fprintf('15°主频: %.6f cm, 估算厚度: %.2f μm\n', f_main2, d_est_fft2);

% 绘制频谱
plot(f1(2:end), P1_1(2:end)/max(P1_1(2:end)), 'b-', 'LineWidth', 1.5);
hold on;
plot(f2(2:end), P1_2(2:end)/max(P1_2(2:end)), 'r-', 'LineWidth', 1.5);
plot(f_main1, P1_1(idx1+9)/max(P1_1(2:end)), 'bo', 'MarkerSize', 10, 'LineWidth', 2);
plot(f_main2, P1_2(idx2+9)/max(P1_2(2:end)), 'ro', 'MarkerSize', 10, 'LineWidth', 2);
xlabel('频率 (cm)'); ylabel('归一化幅度');
title('FFT频谱分析'); grid on; legend('10°', '15°');
xlim([0, 0.05]);

% 计算干涉条纹周期
subplot(2, 3, 4);
% 使用零交叉法估计条纹周期
[periods1, avg_period1] = estimate_fringe_period(wavenumber1, R_exp1);
[periods2, avg_period2] = estimate_fringe_period(wavenumber2, R_exp2);

% 计算厚度估计
d_est_period1 = 1e4 / (2 * n1_est * avg_period1);
d_est_period2 = 1e4 / (2 * n1_est * avg_period2);

fprintf('\n条纹周期分析:\n');
fprintf('10°平均条纹周期: %.2f cm⁻¹, 估算厚度: %.2f μm\n', avg_period1, d_est_period1);
fprintf('15°平均条纹周期: %.2f cm⁻¹, 估算厚度: %.2f μm\n', avg_period2, d_est_period2);

histogram(periods1, 20, 'FaceColor', 'b', 'EdgeColor', 'none', 'FaceAlpha', 0.6);
hold on;
histogram(periods2, 20, 'FaceColor', 'r', 'EdgeColor', 'none', 'FaceAlpha', 0.6);
xlabel('条纹周期 (cm^{-1})'); ylabel('频数');
title('干涉条纹周期分布'); legend('10°', '15°'); grid on;

% 相关性分析
subplot(2, 3, 5);
scatter(R_exp1, R_exp2, 20, 'filled', 'MarkerFaceAlpha', 0.5);
xlabel('10°反射率'); ylabel('15°反射率');
title('两个角度数据相关性');
grid on; axis equal;
xlim([0, 1]); ylim([0, 1]);

% 计算相关系数
correlation_coeff = corrcoef(R1_interp, R2_interp);
fprintf('\n两个角度数据相关系数: %.6f\n', correlation_coeff(1,2));

% 数据平滑度检查
subplot(2, 3, 6);
gradient1 = abs(gradient(R_exp1, wavenumber1));
gradient2 = abs(gradient(R_exp2, wavenumber2));
semilogy(wavenumber1, gradient1, 'b-', 'LineWidth', 1);
hold on;
semilogy(wavenumber2, gradient2, 'r-', 'LineWidth', 1);
xlabel('波数 (cm^{-1})'); ylabel('梯度绝对值');
title('数据平滑度分析'); grid on;
legend('10°', '15°');

%% 4. 构建一个更稳健的简化模型
% 基于观察，我们可能需要重新审视模型假设

% 方案1：基于干涉条纹周期的简单模型
fprintf('\n=== 基于条纹周期的简单估计 ===\n');

% 使用两个角度的平均周期
avg_period = mean([avg_period1, avg_period2]);
d_simple = 1e4 / (2 * n1_est * avg_period);

fprintf('平均条纹周期: %.2f cm⁻¹\n', avg_period);
fprintf('基于条纹周期的厚度估计: %.2f μm\n', d_simple);

% 方案2：尝试更简单的线性模型（用于诊断）
% 如果干涉模型完全失败，我们至少可以拟合一个基线

% 计算干涉条纹可见度
visibility1 = (max(R_exp1) - min(R_exp1)) / (max(R_exp1) + min(R_exp1));
visibility2 = (max(R_exp2) - min(R_exp2)) / (max(R_exp2) + min(R_exp2));
fprintf('干涉条纹可见度 - 10°: %.4f, 15°: %.4f\n', visibility1, visibility2);

%% 5. 尝试基于物理的简化拟合
% 如果复杂的Cauchy模型不工作，尝试固定折射率

n2_test = 2.65;  % SiC衬底
n1_test = 2.6;   % 固定外延层折射率

% 测试不同厚度
d_test_range = linspace(1, 20, 100);  % 1-20 μm
errors1 = zeros(size(d_test_range));
errors2 = zeros(size(d_test_range));

for i = 1:length(d_test_range)
    d_test = d_test_range(i);
    R_model1 = simple_interference_model(lambda1, theta1, d_test, n1_test, n2_test);
    R_model2 = simple_interference_model(lambda2, theta2, d_test, n1_test, n2_test);
    
    errors1(i) = mean((R_exp1 - R_model1).^2);
    errors2(i) = mean((R_exp2 - R_model2).^2);
end

% 找到最小误差的厚度
[~, idx_min1] = min(errors1);
[~, idx_min2] = min(errors2);
d_opt_simple1 = d_test_range(idx_min1);
d_opt_simple2 = d_test_range(idx_min2);

fprintf('\n简单模型分析:\n');
fprintf('10°数据最佳厚度: %.2f μm (MSE: %.6f)\n', d_opt_simple1, errors1(idx_min1));
fprintf('15°数据最佳厚度: %.2f μm (MSE: %.6f)\n', d_opt_simple2, errors2(idx_min2));

figure('Position', [50, 50, 1200, 400]);

subplot(1, 2, 1);
plot(d_test_range, errors1, 'b-', 'LineWidth', 1.5);
hold on;
plot(d_test_range, errors2, 'r-', 'LineWidth', 1.5);
plot(d_opt_simple1, errors1(idx_min1), 'bo', 'MarkerSize', 10, 'LineWidth', 2);
plot(d_opt_simple2, errors2(idx_min2), 'ro', 'MarkerSize', 10, 'LineWidth', 2);
xlabel('厚度 (μm)'); ylabel('均方误差 (MSE)');
title('简单模型误差曲线'); grid on; legend('10°', '15°');

subplot(1, 2, 2);
% 绘制最佳厚度对应的模型
R_best1 = simple_interference_model(lambda1, theta1, d_opt_simple1, n1_test, n2_test);
R_best2 = simple_interference_model(lambda2, theta2, d_opt_simple2, n1_test, n2_test);

plot(wavenumber1, R_exp1, 'b-', 'LineWidth', 1, 'DisplayName', '10°数据');
hold on;
plot(wavenumber1, R_best1, 'b--', 'LineWidth', 1.5, 'DisplayName', sprintf('10°模型(d=%.1fμm)', d_opt_simple1));
plot(wavenumber2, R_exp2, 'r-', 'LineWidth', 1, 'DisplayName', '15°数据');
plot(wavenumber2, R_best2, 'r--', 'LineWidth', 1.5, 'DisplayName', sprintf('15°模型(d=%.1fμm)', d_opt_simple2));
xlabel('波数 (cm^{-1})'); ylabel('反射率');
title('简单模型拟合结果'); grid on; legend('Location', 'best');

% 计算R²
SS_tot1 = sum((R_exp1 - mean(R_exp1)).^2);
SS_res1 = sum((R_exp1 - R_best1).^2);
R2_simple1 = 1 - SS_res1/SS_tot1;

SS_tot2 = sum((R_exp2 - mean(R_exp2)).^2);
SS_res2 = sum((R_exp2 - R_best2).^2);
R2_simple2 = 1 - SS_res2/SS_tot2;

fprintf('\n简单模型评估:\n');
fprintf('10° R²: %.6f\n', R2_simple1);
fprintf('15° R²: %.6f\n', R2_simple2);

%% 6. 尝试经验模型拟合
% 如果物理模型完全失败，尝试纯经验模型

fprintf('\n=== 尝试经验模型 ===\n');

% 使用傅里叶级数拟合
n_terms = 10;  % 傅里叶级数项数

% 10°数据
[fourier_fit1, gof1] = fit_fourier_series(wavenumber1, R_exp1, n_terms);
% 15°数据
[fourier_fit2, gof2] = fit_fourier_series(wavenumber2, R_exp2, n_terms);

fprintf('傅里叶级数拟合结果:\n');
fprintf('10° R²: %.6f\n', gof1.rsquare);
fprintf('15° R²: %.6f\n', gof2.rsquare);

% 提取主要频率成分
coeffs1 = fourier_fit1.coeffs;
coeffs2 = fourier_fit2.coeffs;

% 寻找主要频率（对应厚度）
freq_components1 = extract_main_frequencies(coeffs1, wavenumber1);
freq_components2 = extract_main_frequencies(coeffs2, wavenumber2);

fprintf('\n主要频率成分分析:\n');
fprintf('10°主要频率: %.6f cm (周期: %.2f cm⁻¹)\n', freq_components1(1), 1/freq_components1(1));
fprintf('15°主要频率: %.6f cm (周期: %.2f cm⁻¹)\n', freq_components2(1), 1/freq_components2(1));

% 基于主要频率估计厚度
d_fourier1 = 1e4 / (2 * n1_est * (1/freq_components1(1)));
d_fourier2 = 1e4 / (2 * n1_est * (1/freq_components2(1)));
fprintf('基于傅里叶分析的厚度估计: %.2f μm (10°), %.2f μm (15°)\n', d_fourier1, d_fourier2);

%% 7. 综合分析报告
fprintf('\n=== 综合分析报告 ===\n');
fprintf('1. 数据质量评估:\n');
fprintf('   - 两个角度数据相关系数: %.4f\n', correlation_coeff(1,2));
fprintf('   - 干涉条纹可见度: 10°=%.4f, 15°=%.4f\n', visibility1, visibility2);

fprintf('\n2. 厚度估计汇总:\n');
fprintf('   - FFT方法: %.2f μm (10°), %.2f μm (15°)\n', d_est_fft1, d_est_fft2);
fprintf('   - 条纹周期法: %.2f μm (10°), %.2f μm (15°)\n', d_est_period1, d_est_period2);
fprintf('   - 简单模型扫描: %.2f μm (10°), %.2f μm (15°)\n', d_opt_simple1, d_opt_simple2);
fprintf('   - 傅里叶分析: %.2f μm (10°), %.2f μm (15°)\n', d_fourier1, d_fourier2);

% 计算厚度估计的一致性
d_estimates = [d_est_fft1, d_est_fft2, d_est_period1, d_est_period2, ...
               d_opt_simple1, d_opt_simple2, d_fourier1, d_fourier2];
d_mean = mean(d_estimates);
d_std = std(d_estimates);
d_median = median(d_estimates);

fprintf('\n3. 厚度估计统计:\n');
fprintf('   - 平均值: %.2f μm\n', d_mean);
fprintf('   - 标准差: %.2f μm\n', d_std);
fprintf('   - 中位数: %.2f μm\n', d_median);
fprintf('   - 范围: [%.2f, %.2f] μm\n', min(d_estimates), max(d_estimates));
fprintf('   - 相对不确定度: ±%.1f%%\n', 100*d_std/d_mean);

fprintf('\n4. 建议:\n');
if d_std/d_mean > 0.2
    fprintf('   - 警告：厚度估计不一致，可能存在系统误差\n');
    fprintf('   - 建议：检查实验设置、数据校准和模型假设\n');
else
    fprintf('   - 厚度估计相对一致，可采用平均值 %.2f ± %.2f μm\n', d_mean, d_std);
end

if R2_simple1 < 0.3 || R2_simple2 < 0.3
    fprintf('   - 模型拟合效果差，建议:\n');
    fprintf('     1. 检查衬底折射率n2是否准确\n');
    fprintf('     2. 考虑外延层可能存在吸收\n');
    fprintf('     3. 界面可能不理想（粗糙度、界面层）\n');
    fprintf('     4. 实验数据可能需要重新校准\n');
end

%% 8. 保存结果
results = struct();
results.d_estimates = d_estimates;
results.d_mean = d_mean;
results.d_std = d_std;
results.d_median = d_median;
results.visibility = [visibility1, visibility2];
results.correlation_coeff = correlation_coeff(1,2);
results.R2_simple = [R2_simple1, R2_simple2];
results.R2_fourier = [gof1.rsquare, gof2.rsquare];

save('comprehensive_analysis_results.mat', 'results');

%% ========== 函数定义 ==========

% FFT分析函数
function [L, Fs, f, P1] = perform_fft_analysis(x, y)
    L = length(x);
    Fs = 1 / (x(2) - x(1));
    Y = fft(y - mean(y));
    P2 = abs(Y/L);
    P1 = P2(1:floor(L/2)+1);
    P1(2:end-1) = 2*P1(2:end-1);
    f = Fs*(0:floor(L/2))/L;
end

% 估计干涉条纹周期
function [periods, avg_period] = estimate_fringe_period(wavenumber, reflectance)
    % 寻找峰值
    [pks, locs] = findpeaks(reflectance, 'MinPeakProminence', 0.01);
    
    if length(locs) < 3
        % 如果没有足够峰值，使用零交叉法
        zero_crossings = find(diff(sign(reflectance - mean(reflectance))) ~= 0);
        locs = zero_crossings;
    end
    
    if length(locs) >= 2
        periods = diff(wavenumber(locs));
        avg_period = mean(periods);
    else
        periods = [];
        avg_period = NaN;
    end
end

% 简单干涉模型
function R = simple_interference_model(lambda, theta, d, n1, n2)
    n0 = 1;
    
    % Snell定律
    sin_theta1 = n0 * sin(theta) / n1;
    theta1 = asin(sin_theta1);
    
    % 反射系数
    r01 = (n0*cos(theta) - n1*cos(theta1)) / (n0*cos(theta) + n1*cos(theta1));
    r12 = (n1*cos(theta1) - n2*cos(theta1)) / (n1*cos(theta1) + n2*cos(theta1));
    
    % 相位差
    delta = 4 * pi * n1 * d * cos(theta1) ./ lambda;
    
    % 反射率
    R = abs(r01 + r12 .* exp(1i * delta)).^2;
    R = max(0, min(1, R));
end

% 傅里叶级数拟合
function [fitresult, gof] = fit_fourier_series(x, y, n_terms)
    % 准备拟合数据
    [xData, yData] = prepareCurveData(x, y);
    
    % 确保n_terms不超过MATLAB支持的8阶
    if n_terms > 8
        warning('MATLAB傅里叶级数最多支持8阶，已将阶数从%d调整为8', n_terms);
        n_terms = 8;
    end
    
    % 设置傅里叶拟合类型
    ft = fittype(sprintf('fourier%d', n_terms));
    
    % 排除异常点
    exclude = excludedata(xData, yData, 'Range', [0, 1]);
    
    % 拟合选项
    opts = fitoptions('Method', 'NonlinearLeastSquares');
    opts.Display = 'Off';
    opts.Exclude = exclude;
    
    % 进行拟合
    [fitresult, gof] = fit(xData, yData, ft, opts);
end

% 提取主要频率
function main_freqs = extract_main_frequencies(fitresult, x)
    % 从拟合结果提取系数
    coeff_values = coeffvalues(fitresult);
    
    % 系数结构：a0, a1, b1, a2, b2, ..., an, bn, w
    n_terms = (length(coeff_values) - 1) / 2;  % 正弦和余弦项数
    
    % 计算每个频率分量的幅度
    freqs = zeros(n_terms, 1);
    amplitudes = zeros(n_terms, 1);
    
    w = coeff_values(end);  % 获取频率参数
    
    for i = 1:n_terms
        a_idx = 1 + 2*(i-1) + 1;
        b_idx = a_idx + 1;
        
        amplitudes(i) = sqrt(coeff_values(a_idx)^2 + coeff_values(b_idx)^2);
        freqs(i) = i * w / (2*pi);  % 转换为cm⁻¹单位
    end
    
    % 按幅度排序
    [~, idx] = sort(amplitudes, 'descend');
    
    % 取前3个主要频率
    main_freqs = freqs(idx(1:min(3, length(idx))));
end