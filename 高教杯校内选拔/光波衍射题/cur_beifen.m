%% 红外干涉测厚模型 - 两光束干涉厚度反演（完整预处理版）
clear; clc; close all;

%% 1. 读取数据并筛选1000-4000 cm⁻¹范围
disp('读取数据并筛选1000-4000 cm⁻¹范围...');
data1 = readmatrix('附件1.xlsx');
data2 = readmatrix('附件2.xlsx');

% 提取数据
wavenumber1_raw = data1(:, 1);  % 波数 (cm^-1)
R_exp1_raw = data1(:, 2);       % 反射率 (%)

wavenumber2_raw = data2(:, 1);  % 波数 (cm^-1)
R_exp2_raw = data2(:, 2);       % 反射率 (%)

% 转换为小数
R_exp1_raw = R_exp1_raw / 100;
R_exp2_raw = R_exp2_raw / 100;

% 参数设置
n0 = 1;          % 空气折射率
n2 = 2.65;       % SiC衬底折射率 (根据文献)
theta1_deg = 10; % 入射角1 (度)
theta2_deg = 15; % 入射角2 (度)
theta1 = deg2rad(theta1_deg);
theta2 = deg2rad(theta2_deg);

%% 2. 首先筛选1000-4000 cm⁻¹范围的数据
disp('筛选数据 (1000-4000 cm⁻¹)...');

% 筛选1000-4000 cm⁻¹范围的数据
valid_idx1 = wavenumber1_raw >= 1000 & wavenumber1_raw <= 4000;
valid_idx2 = wavenumber2_raw >= 1000 & wavenumber2_raw <= 4000;

wavenumber1 = wavenumber1_raw(valid_idx1);
R_exp1_original = R_exp1_raw(valid_idx1);

wavenumber2 = wavenumber2_raw(valid_idx2);
R_exp2_original = R_exp2_raw(valid_idx2);

% 波数转换为波长 (μm)
lambda1 = 1e4 ./ wavenumber1;  % 波长 (μm)
lambda2 = 1e4 ./ wavenumber2;  % 波长 (μm)

%% 3. 数据预处理：去趋势化、去噪、平滑（对筛选后的数据）
disp('开始数据预处理...');

% ===================== 第一步：非对称最小二乘法(AsLS)基线校正 =====================
disp('进行AsLS基线校正...');

% AsLS算法实现
function baseline = asymmetric_least_squares(y, lambda, p, order)
    % y: 原始信号
    % lambda: 平滑参数
    % p: 不对称参数 (0<p<1)
    % order: 差分阶数 (通常为2)
    
    % 初始化权重
    w = ones(size(y));
    z = y;
    
    % 迭代求解
    max_iter = 20;
    tol = 1e-6;
    
    for iter = 1:max_iter
        % 构建差分矩阵
        n = length(y);
        D = diff(speye(n), order);
        
        % 构建权重矩阵
        W = spdiags(w, 0, n, n);
        
        % 求解最小二乘问题: (W + lambda*D'*D)z = W*y
        z_old = z;
        C = chol(W + lambda * (D' * D));
        z = C \ (C' \ (w .* y));
        
        % 更新权重
        residual = y - z;
        w = zeros(size(y));
        w(residual > 0) = p;
        w(residual <= 0) = 1 - p;
        
        % 检查收敛
        if norm(z - z_old) / norm(z_old) < tol
            break;
        end
    end
    
    baseline = z;
end

% 应用AsLS基线校正
lambda_asls = 1e5;  % 平滑参数
p_asls = 0.001;     % 不对称参数
order_asls = 2;     % 二阶差分

% 对10°数据进行基线校正
baseline1 = asymmetric_least_squares(R_exp1_original, lambda_asls, p_asls, order_asls);
R_exp1_detrended = R_exp1_original - baseline1;

% 对15°数据进行基线校正
baseline2 = asymmetric_least_squares(R_exp2_original, lambda_asls, p_asls, order_asls);
R_exp2_detrended = R_exp2_original - baseline2;

% ===================== 第二步：Hampel滤波去噪 =====================
disp('进行Hampel滤波去噪...');
window_size = 11;  % 窗口大小
n_sigma = 3;       % 标准差倍数

R_exp1_hampel = hampel(R_exp1_detrended, window_size, n_sigma);
R_exp2_hampel = hampel(R_exp2_detrended, window_size, n_sigma);

% ===================== 第三步：Savitzky-Golay平滑 =====================
disp('进行Savitzky-Golay平滑...');
sg_window = 21;      % 窗口宽度（奇数）
sg_order = 3;        % 多项式阶数

R_exp1_smooth = sgolayfilt(R_exp1_hampel, sg_order, sg_window);
R_exp2_smooth = sgolayfilt(R_exp2_hampel, sg_order, sg_window);

% 最终预处理后的数据
R_exp1_processed = R_exp1_smooth;
R_exp2_processed = R_exp2_smooth;

% 绘制预处理过程对比图
figure('Position', [100, 100, 1400, 800]);

% 10°数据预处理过程
subplot(2, 3, 1);
plot(wavenumber1, R_exp1_original, 'k-', 'LineWidth', 1, 'DisplayName', '原始数据');
hold on;
plot(wavenumber1, baseline1, 'r--', 'LineWidth', 2, 'DisplayName', '基线');
xlabel('波数 (cm^{-1})');
ylabel('反射率');
title('10°数据 - 原始数据与基线 (1000-4000 cm⁻¹)');
legend('Location', 'best');
grid on;
xlim([min(wavenumber1), max(wavenumber1)]);

subplot(2, 3, 2);
plot(wavenumber1, R_exp1_detrended, 'b-', 'LineWidth', 1, 'DisplayName', '去趋势');
hold on;
plot(wavenumber1, R_exp1_hampel, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Hampel滤波');
xlabel('波数 (cm^{-1})');
ylabel('反射率');
title('10°数据 - 去趋势与滤波 (1000-4000 cm⁻¹)');
legend('Location', 'best');
grid on;
xlim([min(wavenumber1), max(wavenumber1)]);

subplot(2, 3, 3);
plot(wavenumber1, R_exp1_processed, 'b-', 'LineWidth', 1.5, 'DisplayName', '最终处理');
hold on;
plot(wavenumber1, R_exp1_original, 'k:', 'LineWidth', 0.5, 'DisplayName', '原始参考');
xlabel('波数 (cm^{-1})');
ylabel('反射率');
title('10°数据 - 最终处理结果 (1000-4000 cm⁻¹)');
legend('Location', 'best');
grid on;
xlim([min(wavenumber1), max(wavenumber1)]);

% 15°数据预处理过程
subplot(2, 3, 4);
plot(wavenumber2, R_exp2_original, 'k-', 'LineWidth', 1, 'DisplayName', '原始数据');
hold on;
plot(wavenumber2, baseline2, 'r--', 'LineWidth', 2, 'DisplayName', '基线');
xlabel('波数 (cm^{-1})');
ylabel('反射率');
title('15°数据 - 原始数据与基线 (1000-4000 cm⁻¹)');
legend('Location', 'best');
grid on;
xlim([min(wavenumber2), max(wavenumber2)]);

subplot(2, 3, 5);
plot(wavenumber2, R_exp2_detrended, 'b-', 'LineWidth', 1, 'DisplayName', '去趋势');
hold on;
plot(wavenumber2, R_exp2_hampel, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Hampel滤波');
xlabel('波数 (cm^{-1})');
ylabel('反射率');
title('15°数据 - 去趋势与滤波 (1000-4000 cm⁻¹)');
legend('Location', 'best');
grid on;
xlim([min(wavenumber2), max(wavenumber2)]);

subplot(2, 3, 6);
plot(wavenumber2, R_exp2_processed, 'b-', 'LineWidth', 1.5, 'DisplayName', '最终处理');
hold on;
plot(wavenumber2, R_exp2_original, 'k:', 'LineWidth', 0.5, 'DisplayName', '原始参考');
xlabel('波数 (cm^{-1})');
ylabel('反射率');
title('15°数据 - 最终处理结果 (1000-4000 cm⁻¹)');
legend('Location', 'best');
grid on;
xlim([min(wavenumber2), max(wavenumber2)]);

% 使用预处理后的数据
R_exp1 = R_exp1_processed;
R_exp2 = R_exp2_processed;





















%% 4. 滑动窗口FFT分析（根据论文描述）
disp('进行滑动窗口FFT分析...');

% 滑动窗口参数
window_width = 300;  % 窗口宽度 (cm⁻¹) - 根据论文W=300cm⁻¹
step_size = 10;      % 步长 (cm⁻¹)

% 对两个角度分别进行滑动窗口FFT分析
[center_positions1, main_freqs1, snr_vals1] = sliding_window_fft_analysis(...
    wavenumber1, R_exp1, window_width, step_size, theta1_deg);

[center_positions2, main_freqs2, snr_vals2] = sliding_window_fft_analysis(...
    wavenumber2, R_exp2, window_width, step_size, theta2_deg);

% 绘制滑动窗口FFT分析结果
figure('Position', [100, 100, 1400, 600]);

% 10°数据主频和SNR
subplot(2, 2, 1);
plot(center_positions1, main_freqs1, 'b-', 'LineWidth', 2);
xlabel('窗口中心波数 (cm^{-1})');
ylabel('主频率 (cm)');
title(sprintf('10°数据 - 滑动窗口主频率 (窗口宽度=%d cm⁻¹)', window_width));
grid on;
xlim([min(center_positions1), max(center_positions1)]);

subplot(2, 2, 2);
plot(center_positions1, snr_vals1, 'b-', 'LineWidth', 2);
xlabel('窗口中心波数 (cm^{-1})');
ylabel('SNR (dB)');
title(sprintf('10°数据 - 滑动窗口SNR (窗口宽度=%d cm⁻¹)', window_width));
grid on;
xlim([min(center_positions1), max(center_positions1)]);

% 15°数据主频和SNR
subplot(2, 2, 3);
plot(center_positions2, main_freqs2, 'r-', 'LineWidth', 2);
xlabel('窗口中心波数 (cm^{-1})');
ylabel('主频率 (cm)');
title(sprintf('15°数据 - 滑动窗口主频率 (窗口宽度=%d cm⁻¹)', window_width));
grid on;
xlim([min(center_positions2), max(center_positions2)]);

subplot(2, 2, 4);
plot(center_positions2, snr_vals2, 'r-', 'LineWidth', 2);
xlabel('窗口中心波数 (cm^{-1})');
ylabel('SNR (dB)');
title(sprintf('15°数据 - 滑动窗口SNR (窗口宽度=%d cm⁻¹)', window_width));
grid on;
xlim([min(center_positions2), max(center_positions2)]);

%% 5. 自动频段选择（根据论文标准）
disp('进行自动频段选择...');

% 设置频段选择标准
min_snr = 10;           % SNR > 10 dB
max_freq_diff = 0.10;   % 主频相对差 < 10%
min_cycles = 5;         % 至少5个条纹周期
safety_margin = 20;     % 安全裁剪边界 (cm⁻¹)

% 执行自动频段选择
[selected_bands, valid_center_positions] = auto_band_selection(...
    center_positions1, center_positions2, ...
    main_freqs1, main_freqs2, ...
    snr_vals1, snr_vals2, ...
    min_snr, max_freq_diff, min_cycles, safety_margin, window_width);

% 绘制频段选择结果
figure('Position', [100, 100, 1200, 400]);

subplot(1, 2, 1);
hold on;
plot(center_positions1, snr_vals1, 'b-', 'LineWidth', 1.5, 'DisplayName', '10° SNR');
plot(center_positions2, snr_vals2, 'r-', 'LineWidth', 1.5, 'DisplayName', '15° SNR');

% 标记选中的频段 - 修复fill函数错误
if ~isempty(selected_bands)
    % 计算SNR的最大值
    max_snr = max([max(snr_vals1), max(snr_vals2)]);
    
    for i = 1:size(selected_bands, 1)
        band_start = selected_bands(i, 1);
        band_end = selected_bands(i, 2);
        
        % 使用正确的fill函数参数
        fill([band_start, band_end, band_end, band_start], ...
             [0, 0, max_snr, max_snr], ...
             'g', 'FaceAlpha', 0.2, 'EdgeColor', 'g', 'LineWidth', 1.5, ...
             'DisplayName', sprintf('选中频段 %d', i));
    end
end

xlabel('波数 (cm^{-1})');
ylabel('SNR (dB)');
title('频段选择结果 - SNR (1000-4000 cm⁻¹)');
legend('Location', 'best');
grid on;
xlim([1000, 4000]);
ylim([0, max([max(snr_vals1), max(snr_vals2)]) * 1.1]);

subplot(1, 2, 2);
hold on;
plot(center_positions1, main_freqs1, 'b-', 'LineWidth', 1.5, 'DisplayName', '10° 主频');
plot(center_positions2, main_freqs2, 'r-', 'LineWidth', 1.5, 'DisplayName', '15° 主频');

% 标记选中的频段 - 修复fill函数错误
if ~isempty(selected_bands)
    % 计算主频率的最小值和最大值
    min_freq = min([min(main_freqs1), min(main_freqs2)]);
    max_freq = max([max(main_freqs1), max(main_freqs2)]);
    
    for i = 1:size(selected_bands, 1)
        band_start = selected_bands(i, 1);
        band_end = selected_bands(i, 2);
        
        % 使用正确的fill函数参数
        fill([band_start, band_end, band_end, band_start], ...
             [min_freq, min_freq, max_freq, max_freq], ...
             'g', 'FaceAlpha', 0.2, 'EdgeColor', 'g', 'LineWidth', 1.5, ...
             'DisplayName', sprintf('选中频段 %d', i));
    end
end

xlabel('波数 (cm^{-1})');
ylabel('主频率 (cm)');
title('频段选择结果 - 主频率 (1000-4000 cm⁻¹)');
legend('Location', 'best');
grid on;
xlim([1000, 4000]);
ylim([min_freq * 0.9, max_freq * 1.1]);

% 选择最佳频段（根据论文：平均SNR最高且条纹周期充足）
if ~isempty(selected_bands)
    % 计算每个频段的平均SNR
    band_snrs = zeros(size(selected_bands, 1), 1);
    band_cycles = zeros(size(selected_bands, 1), 1);
    
    for i = 1:size(selected_bands, 1)
        band_start = selected_bands(i, 1);
        band_end = selected_bands(i, 2);
        
        % 计算平均SNR
        idx1 = center_positions1 >= band_start & center_positions1 <= band_end;
        idx2 = center_positions2 >= band_start & center_positions2 <= band_end;
        
        band_snrs(i) = mean([snr_vals1(idx1); snr_vals2(idx2)]);
        
        % 计算条纹周期数
        band_width = band_end - band_start;
        avg_freq = mean([main_freqs1(idx1); main_freqs2(idx2)]);
        band_cycles(i) = band_width * avg_freq;
    end
    
    % 选择最佳频段（SNR高且周期数≥5）
    valid_idx = band_cycles >= min_cycles;
    if any(valid_idx)
        valid_snrs = band_snrs(valid_idx);
        valid_bands = selected_bands(valid_idx, :);
        
        [~, best_idx] = max(valid_snrs);
        best_band = valid_bands(best_idx, :);
    else
        % 如果没有频段满足周期数要求，选择SNR最高的
        [~, best_idx] = max(band_snrs);
        best_band = selected_bands(best_idx, :);
    end
    
    % 应用安全裁剪
    best_band(1) = best_band(1) + safety_margin;
    best_band(2) = best_band(2) - safety_margin;
    
    fprintf('最佳频段选择结果:\n');
    fprintf('频段范围: %.1f - %.1f cm⁻¹\n', best_band(1), best_band(2));
    fprintf('频段宽度: %.1f cm⁻¹\n', best_band(2) - best_band(1));
    fprintf('平均SNR: %.2f dB\n', band_snrs(best_idx));
    fprintf('估计条纹周期数: %.1f\n\n', band_cycles(best_idx));
    
    % 筛选最佳频段内的数据
    valid_idx1_band = wavenumber1 >= best_band(1) & wavenumber1 <= best_band(2);
    valid_idx2_band = wavenumber2 >= best_band(1) & wavenumber2 <= best_band(2);
    
    % 如果筛选后数据点太少，使用原始范围
    if sum(valid_idx1_band) < 50 || sum(valid_idx2_band) < 50
        fprintf('警告：最佳频段内数据点不足，使用2500-3700 cm⁻¹范围（根据论文）\n');
        best_band = [2500, 3700];
        valid_idx1_band = wavenumber1 >= best_band(1) & wavenumber1 <= best_band(2);
        valid_idx2_band = wavenumber2 >= best_band(1) & wavenumber2 <= best_band(2);
    end
    
    wavenumber1_band = wavenumber1(valid_idx1_band);
    R_exp1_band = R_exp1(valid_idx1_band);
    lambda1_band = lambda1(valid_idx1_band);
    
    wavenumber2_band = wavenumber2(valid_idx2_band);
    R_exp2_band = R_exp2(valid_idx2_band);
    lambda2_band = lambda2(valid_idx2_band);
    
    fprintf('最佳频段数据统计:\n');
    fprintf('10°数据点数: %d\n', length(wavenumber1_band));
    fprintf('15°数据点数: %d\n', length(wavenumber2_band));
else
    fprintf('警告：未找到有效频段，使用默认范围2500-3700 cm⁻¹\n');
    best_band = [2500, 3700];
    valid_idx1_band = wavenumber1 >= best_band(1) & wavenumber1 <= best_band(2);
    valid_idx2_band = wavenumber2 >= best_band(1) & wavenumber2 <= best_band(2);
    
    wavenumber1_band = wavenumber1(valid_idx1_band);
    R_exp1_band = R_exp1(valid_idx1_band);
    lambda1_band = lambda1(valid_idx1_band);
    
    wavenumber2_band = wavenumber2(valid_idx2_band);
    R_exp2_band = R_exp2(valid_idx2_band);
    lambda2_band = lambda2(valid_idx2_band);
end

%% 6. 在有效频段内进行FFT分析，计算厚度初值
disp('在有效频段内进行FFT分析，计算厚度初值...');

% 对两个角度分别进行FFT分析
d_initial_estimates = zeros(2, 1);
refractive_estimates = zeros(2, 1);

for angle_idx = 1:2
    if angle_idx == 1
        wavenumber_band = wavenumber1_band;
        R_exp_band = R_exp1_band;
        theta_deg = theta1_deg;
        angle_name = '10°';
    else
        wavenumber_band = wavenumber2_band;
        R_exp_band = R_exp2_band;
        theta_deg = theta2_deg;
        angle_name = '15°';
    end
    
    % 应用Hann窗
    L = length(R_exp_band);
    hann_window = hann(L);
    signal_windowed = R_exp_band .* hann_window;
    
    % 进行FFT
    Y = fft(signal_windowed);
    P2 = abs(Y/L);
    P1 = P2(1:floor(L/2)+1);
    P1(2:end-1) = 2*P1(2:end-1);
    
    % 计算频率轴
    Fs = 1 / (wavenumber_band(2) - wavenumber_band(1));
    f = Fs * (0:floor(L/2)) / L;
    
    % 找到主频（忽略零频附近）
    search_range = 10:min(50, length(P1));
    [~, idx] = max(P1(search_range));
    f_main = f(search_range(idx));
    
    % 计算条纹周期
    delta_nu = 1 / f_main;
    
    % 计算厚度初值
    % 使用公式: d0 = 1 / (2 * n_avg * cos(theta_t) * delta_nu)
    % 其中 cos(theta_t) = sqrt(1 - (sin(theta)/n_avg)^2)
    
    % 对于SiC外延层，初始折射率估计
    n_avg_guess = 2.65;
    cos_theta_t = sqrt(1 - (sind(theta_deg)/n_avg_guess)^2);
    
    d_initial = 1e4 / (2 * n_avg_guess * cos_theta_t * delta_nu);  % 转换为μm
    
    d_initial_estimates(angle_idx) = d_initial;
    
    % 也可以从厚度反推折射率
    refractive_estimates(angle_idx) = 1e4 / (2 * d_initial * cos_theta_t * delta_nu);
    
    fprintf('%s入射角:\n', angle_name);
    fprintf('  主频率: %.6f cm\n', f_main);
    fprintf('  条纹周期: %.2f cm⁻¹\n', delta_nu);
    fprintf('  初始厚度估计: %.1f μm\n', d_initial);
    fprintf('  折射率估计: %.4f\n\n', refractive_estimates(angle_idx));
end

% 取两个角度的平均值作为初始厚度
d0 = mean(d_initial_estimates);
n1_initial = mean(refractive_estimates);

fprintf('综合初始估计:\n');
fprintf('初始厚度: %.1f μm\n', d0);
fprintf('初始折射率: %.4f\n\n', n1_initial);

%% 7. 定义理论反射率模型（与原始代码相同）
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
    % 修正：确保分母不为零
    denominator01 = n0*cos(theta) + n1.*cos(theta1);
    denominator12 = n1.*cos(theta1) + n2*cos(theta2);
    
    r01 = (n0*cos(theta) - n1.*cos(theta1)) ./ denominator01;
    r12 = (n1.*cos(theta1) - n2*cos(theta2)) ./ denominator12;
    
    % 计算相位差
    delta = (4 * pi * n1 .* d .* cos(theta1)) ./ lambda;
    
    % 计算总反射率
    R = abs(r01 + r12 .* exp(1i * delta)).^2;
    
    % 确保反射率在合理范围内
    R = max(0, min(1, R));
end

%% 8. 定义目标函数（加权最小二乘）
function [residuals, weights] = objective_func(params, lambda1, R_exp1, theta1, ...
                                                lambda2, R_exp2, theta2, n0, n2, use_weights)
    d = params(1);  % 厚度 (μm)
    A = params(2);  % Cauchy参数A
    B = params(3);  % Cauchy参数B (μm^2)
    
    % 计算理论反射率
    R_theory1 = calc_reflectivity(lambda1, theta1, d, A, B, n0, n2);
    R_theory2 = calc_reflectivity(lambda2, theta2, d, A, B, n0, n2);
    
    % 计算残差
    residuals1 = R_exp1 - R_theory1;
    residuals2 = R_exp2 - R_theory2;
    
    % 计算权重（如果启用）
    weights1 = ones(size(residuals1));
    weights2 = ones(size(residuals2));
    
    if use_weights
        % 基于反射率大小的权重（中间值权重高，两端权重低）
        weights1 = 0.5 + 0.5 * cos(2*pi*(R_exp1 - 0.5));
        weights2 = 0.5 + 0.5 * cos(2*pi*(R_exp2 - 0.5));
        
        % 避免权重为零
        weights1 = max(weights1, 0.1);
        weights2 = max(weights2, 0.1);
    end
    
    % 加权残差
    residuals = [residuals1 .* weights1; residuals2 .* weights2];
    
    % 返回权重（用于后续分析）
    weights = [weights1; weights2];
end

%% 9. 参数拟合（使用最佳频段数据）
disp('开始参数拟合（使用最佳频段数据）...');

% 使用最佳频段的数据
lambda1 = lambda1_band;
R_exp1 = R_exp1_band;
wavenumber1 = wavenumber1_band;

lambda2 = lambda2_band;
R_exp2 = R_exp2_band;
wavenumber2 = wavenumber2_band;

% 初始参数猜测
A0 = n1_initial;
B0 = 0.01;  % 初始B值猜测
initial_params = [d0, A0, B0];

fprintf('拟合参数初始化:\n');
fprintf('初始厚度: %.1f μm\n', d0);
fprintf('初始A: %.4f\n', A0);
fprintf('初始B: %.6f μm²\n\n', B0);

% 设置参数边界
lb = [max(0.1, d0*0.5), 2.4, 0.001];   % 下界
ub = [d0*2, 2.8, 0.05];                % 上界

% 设置拟合选项
options = optimoptions('lsqnonlin', 'Display', 'iter', ...
                       'MaxFunctionEvaluations', 3000, ...
                       'MaxIterations', 500, ...
                       'FunctionTolerance', 1e-8, ...
                       'StepTolerance', 1e-8, ...
                       'Algorithm', 'trust-region-reflective');

% 定义目标函数（带权重）
obj_func = @(params) objective_func(params, lambda1, R_exp1, theta1, ...
                                    lambda2, R_exp2, theta2, n0, n2, true);

% 进行非线性最小二乘拟合
[params_opt, resnorm, residual, exitflag, output] = ...
    lsqnonlin(obj_func, initial_params, lb, ub, options);

% 提取拟合结果
d_opt = params_opt(1);
A_opt = params_opt(2);
B_opt = params_opt(3);

fprintf('\n最佳拟合结果:\n');
fprintf('优化厚度: %.4f μm\n', d_opt);
fprintf('Cauchy参数 A: %.6f\n', A_opt);
fprintf('Cauchy参数 B: %.6f μm²\n', B_opt);
fprintf('残差平方和: %.6f\n', resnorm);
fprintf('迭代次数: %d\n', output.iterations);
fprintf('退出标志: %d\n', exitflag);

%% 10. 计算拟合反射率并绘制对比图
disp('计算拟合结果并绘制图表...');
% 计算拟合的反射率
R_fit1 = calc_reflectivity(lambda1, theta1, d_opt, A_opt, B_opt, n0, n2);
R_fit2 = calc_reflectivity(lambda2, theta2, d_opt, A_opt, B_opt, n0, n2);

% 计算残差
residual1 = R_exp1 - R_fit1;
residual2 = R_exp2 - R_fit2;

% 绘制拟合结果对比
figure('Position', [100, 100, 1400, 600]);

% 10°入射角
subplot(2, 2, 1);
plot(wavenumber1, R_exp1, 'b-', 'LineWidth', 1.5, 'DisplayName', '预处理数据');
hold on;
plot(wavenumber1, R_fit1, 'r--', 'LineWidth', 2, 'DisplayName', '拟合结果');
xlabel('波数 (cm^{-1})');
ylabel('反射率');
title(sprintf('10°入射角 - 拟合对比 (d=%.2f μm)', d_opt));
legend('Location', 'best');
grid on;
xlim([min(wavenumber1), max(wavenumber1)]);

% 15°入射角
subplot(2, 2, 2);
plot(wavenumber2, R_exp2, 'b-', 'LineWidth', 1.5, 'DisplayName', '预处理数据');
hold on;
plot(wavenumber2, R_fit2, 'r--', 'LineWidth', 2, 'DisplayName', '拟合结果');
xlabel('波数 (cm^{-1})');
ylabel('反射率');
title(sprintf('15°入射角 - 拟合对比 (d=%.2f μm)', d_opt));
legend('Location', 'best');
grid on;
xlim([min(wavenumber2), max(wavenumber2)]);

% 10°入射角残差
subplot(2, 2, 3);
plot(wavenumber1, residual1, 'k-', 'LineWidth', 1);
hold on;
plot(wavenumber1, zeros(size(wavenumber1)), 'r--', 'LineWidth', 1);
xlabel('波数 (cm^{-1})');
ylabel('残差');
title('10°入射角 - 拟合残差');
grid on;
xlim([min(wavenumber1), max(wavenumber1)]);
% 自动调整y轴范围
residual_range1 = max(abs(residual1));
ylim([-1.5*residual_range1, 1.5*residual_range1]);

% 15°入射角残差
subplot(2, 2, 4);
plot(wavenumber2, residual2, 'k-', 'LineWidth', 1);
hold on;
plot(wavenumber2, zeros(size(wavenumber2)), 'r--', 'LineWidth', 1);
xlabel('波数 (cm^{-1})');
ylabel('残差');
title('15°入射角 - 拟合残差');
grid on;
xlim([min(wavenumber2), max(wavenumber2)]);
% 自动调整y轴范围
residual_range2 = max(abs(residual2));
ylim([-1.5*residual_range2, 1.5*residual_range2]);

%% 11. 模型评估指标（与原始代码相同）
disp('计算模型评估指标...');

% 计算决定系数 R²
SS_tot1 = sum((R_exp1 - mean(R_exp1)).^2);
SS_res1 = sum(residual1.^2);
R2_1 = 1 - SS_res1/SS_tot1;

SS_tot2 = sum((R_exp2 - mean(R_exp2)).^2);
SS_res2 = sum(residual2.^2);
R2_2 = 1 - SS_res2/SS_tot2;

% 计算均方根误差 (RMSE)
RMSE1 = sqrt(mean(residual1.^2));
RMSE2 = sqrt(mean(residual2.^2));

% 计算平均绝对误差 (MAE)
MAE1 = mean(abs(residual1));
MAE2 = mean(abs(residual2));

% 计算信噪比 (SNR)
SNR1 = 10 * log10(var(R_exp1) / var(residual1));
SNR2 = 10 * log10(var(R_exp2) / var(residual2));

fprintf('\n模型评估指标:\n');
fprintf('=============================================\n');
fprintf('10°入射角:\n');
fprintf('  决定系数 R²: %.6f\n', R2_1);
fprintf('  均方根误差 RMSE: %.6f\n', RMSE1);
fprintf('  平均绝对误差 MAE: %.6f\n', MAE1);
fprintf('  信噪比 SNR: %.2f dB\n', SNR1);
fprintf('  残差标准差: %.6f\n', std(residual1));
fprintf('\n15°入射角:\n');
fprintf('  决定系数 R²: %.6f\n', R2_2);
fprintf('  均方根误差 RMSE: %.6f\n', RMSE2);
fprintf('  平均绝对误差 MAE: %.6f\n', MAE2);
fprintf('  信噪比 SNR: %.2f dB\n', SNR2);
fprintf('  残差标准差: %.6f\n', std(residual2));
fprintf('\n整体拟合质量:\n');
if R2_1 > 0.8 && R2_2 > 0.8
    fprintf('  ✓ 拟合效果良好 (R² > 0.8)\n');
elseif R2_1 > 0.6 && R2_2 > 0.6
    fprintf('  ⚠ 拟合效果一般 (0.6 < R² < 0.8)\n');
else
    fprintf('  ✗ 拟合效果较差 (R² < 0.6)，需要检查模型或数据\n');
end

%% 12. 折射率分析
% 计算折射率
n1_vals = A_opt + B_opt ./ (lambda1.^2);

% 计算平均折射率和范围
n1_avg = mean(n1_vals);
n1_min = min(n1_vals);
n1_max = max(n1_vals);

fprintf('\n折射率分析 (%.0f-%.0f cm⁻¹):\n', best_band(1), best_band(2));
fprintf('平均折射率: %.4f\n', n1_avg);
fprintf('折射率范围: %.4f - %.4f\n', n1_min, n1_max);
fprintf('折射率变化幅度: %.4f\n', n1_max - n1_min);

% 绘制折射率随波长的变化
figure('Position', [100, 100, 1000, 400]);

subplot(1, 2, 1);
plot(lambda1, n1_vals, 'b-', 'LineWidth', 2);
xlabel('波长 (μm)');
ylabel('折射率 n_1');
title(sprintf('外延层折射率 (A=%.4f, B=%.6f)', A_opt, B_opt));
grid on;
xlim([min(lambda1), max(lambda1)]);

subplot(1, 2, 2);
plot(wavenumber1, n1_vals, 'r-', 'LineWidth', 2);
xlabel('波数 (cm^{-1})');
ylabel('折射率 n_1');
title('外延层折射率随波数变化');
grid on;
xlim([min(wavenumber1), max(wavenumber1)]);

%% 13. 厚度不确定性分析
% 简单的厚度不确定度估计
fprintf('\n厚度不确定性分析:\n');

% 基于残差的标准不确定度
d_uncertainty_res = d_opt * sqrt(mean([residual1.^2; residual2.^2]));

% 基于折射率变化的不确定度
% 折射率变化Δn引起的厚度变化Δd ≈ -d * Δn/n
n_variation = std(n1_vals);
d_uncertainty_n = d_opt * n_variation / n1_avg;

% 合成不确定度
d_uncertainty_total = sqrt(d_uncertainty_res^2 + d_uncertainty_n^2);

fprintf('基于残差的不确定度: ±%.4f μm\n', d_uncertainty_res);
fprintf('基于折射率变化的不确定度: ±%.4f μm\n', d_uncertainty_n);
fprintf('合成不确定度: ±%.4f μm\n', d_uncertainty_total);
fprintf('相对不确定度: %.2f%%\n', 100 * d_uncertainty_total / d_opt);

%% 14. 保存结果
results = struct();
results.thickness = d_opt;
results.thickness_uncertainty = d_uncertainty_total;
results.A = A_opt;
results.B = B_opt;
results.R2_10deg = R2_1;
results.R2_15deg = R2_2;
results.RMSE_10deg = RMSE1;
results.RMSE_15deg = RMSE2;
results.MAE_10deg = MAE1;
results.MAE_15deg = MAE2;
results.SNR_10deg = SNR1;
results.SNR_15deg = SNR2;
results.n1_average = n1_avg;
results.n1_range = [n1_min, n1_max];
results.best_band = best_band;
results.wavenumber_range = [min(wavenumber1), max(wavenumber1)];
results.data_points = [length(wavenumber1), length(wavenumber2)];
results.preprocessing_methods = {'AsLS基线校正', 'Hampel滤波', 'Savitzky-Golay平滑'};

save('fitting_results_preprocessed.mat', 'results');

% 导出关键结果到文本文件
fid = fopen('fitting_summary_preprocessed.txt', 'w');
fprintf(fid, '红外干涉测厚模型拟合结果（预处理版）\n');
fprintf(fid, '===========================================\n\n');
fprintf(fid, '数据处理流程:\n');
fprintf(fid, '1. 筛选波数范围: 1000-4000 cm⁻¹\n');
fprintf(fid, '2. AsLS基线校正 (lambda=%.0e, p=%.3f, order=%d)\n', lambda_asls, p_asls, order_asls);
fprintf(fid, '3. Hampel滤波 (window=%d, n_sigma=%d)\n', window_size, n_sigma);
fprintf(fid, '4. Savitzky-Golay平滑 (window=%d, order=%d)\n\n', sg_window, sg_order);
fprintf(fid, '最佳频段选择: %.0f - %.0f cm⁻¹\n\n', best_band(1), best_band(2));
fprintf(fid, '拟合厚度: %.4f ± %.4f μm\n', d_opt, d_uncertainty_total);
fprintf(fid, 'Cauchy参数 A: %.6f\n', A_opt);
fprintf(fid, 'Cauchy参数 B: %.6f μm²\n', B_opt);
fprintf(fid, '\n模型评估:\n');
fprintf(fid, '10°入射角 R²: %.6f, RMSE: %.6f\n', R2_1, RMSE1);
fprintf(fid, '15°入射角 R²: %.6f, RMSE: %.6f\n', R2_2, RMSE2);
fprintf(fid, '\n折射率分析:\n');
fprintf(fid, '平均折射率: %.4f\n', n1_avg);
fprintf(fid, '折射率范围: %.4f - %.4f\n', n1_min, n1_max);
fclose(fid);

fprintf('\n结果已保存:\n');
fprintf('  详细结果: fitting_results_preprocessed.mat\n');
fprintf('  文本摘要: fitting_summary_preprocessed.txt\n');
fprintf('\n分析完成！\n');

%% 辅助函数定义

% 滑动窗口FFT分析函数
function [center_positions, main_freqs, snr_vals] = sliding_window_fft_analysis(...
    wavenumber, signal, window_width, step_size, angle_deg)
    
    % 确保波数是单调递增的
    [wavenumber, sort_idx] = sort(wavenumber);
    signal = signal(sort_idx);
    
    % 计算窗口数量和中心位置
    wavenumber_min = min(wavenumber);
    wavenumber_max = max(wavenumber);
    
    % 创建窗口中心位置
    center_positions = (wavenumber_min + window_width/2):step_size:(wavenumber_max - window_width/2);
    
    main_freqs = zeros(size(center_positions));
    snr_vals = zeros(size(center_positions));
    
    % 对每个窗口进行FFT分析
    for i = 1:length(center_positions)
        center = center_positions(i);
        window_start = center - window_width/2;
        window_end = center + window_width/2;
        
        % 提取窗口内数据
        idx = wavenumber >= window_start & wavenumber <= window_end;
        
        if sum(idx) < 10  % 窗口内数据点太少
            main_freqs(i) = NaN;
            snr_vals(i) = NaN;
            continue;
        end
        
        wavenumber_window = wavenumber(idx);
        signal_window = signal(idx);
        
        % 应用Hann窗
        L = length(signal_window);
        hann_window = hann(L);
        signal_windowed = signal_window .* hann_window;
        
        % 进行FFT
        Y = fft(signal_windowed);
        P2 = abs(Y/L);
        P1 = P2(1:floor(L/2)+1);
        P1(2:end-1) = 2*P1(2:end-1);
        
        % 计算频率轴
        Fs = 1 / (wavenumber_window(2) - wavenumber_window(1));
        f = Fs * (0:floor(L/2)) / L;
        
        % 找到主频（忽略零频附近）
        search_range = 10:min(50, length(P1));
        [max_val, idx_max] = max(P1(search_range));
        f_main = f(search_range(idx_max));
        
        % 计算SNR
        % 主峰幅值
        A_peak = max_val;
        
        % 估计噪声水平（使用主峰附近的邻带）
        noise_band_width = 5;  % 频率点数量
        noise_start = max(1, idx_max - noise_band_width);
        noise_end = min(length(P1), idx_max + noise_band_width);
        noise_indices = [noise_start:max(1, idx_max-10), min(length(P1), idx_max+10):noise_end];
        
        if isempty(noise_indices)
            noise_level = std(P1(10:end));
        else
            noise_level = std(P1(noise_indices));
        end
        
        SNR = A_peak / noise_level;
        SNR_db = 10 * log10(SNR);
        
        main_freqs(i) = f_main;
        snr_vals(i) = SNR_db;
    end
    
    % 移除NaN值
    valid_idx = ~isnan(main_freqs) & ~isnan(snr_vals);
    center_positions = center_positions(valid_idx);
    main_freqs = main_freqs(valid_idx);
    snr_vals = snr_vals(valid_idx);
    
    fprintf('角度 %d°: 分析窗口数 = %d\n', angle_deg, length(center_positions));
end

% 自动频段选择函数
function [selected_bands, valid_center_positions] = auto_band_selection(...
    center_positions1, center_positions2, ...
    main_freqs1, main_freqs2, ...
    snr_vals1, snr_vals2, ...
    min_snr, max_freq_diff, min_cycles, safety_margin, window_width)
    
    % 找到两个角度共有的中心位置
    common_centers = intersect(round(center_positions1, 1), round(center_positions2, 1));
    
    selected_bands = [];
    valid_center_positions = [];
    
    if isempty(common_centers)
        fprintf('警告：两个角度没有共同的中心位置\n');
        return;
    end
    
    % 在每个共同中心位置检查条件
    valid_flags = false(size(common_centers));
    
    for i = 1:length(common_centers)
        center = common_centers(i);
        
        % 找到最接近的中心位置索引
        [~, idx1] = min(abs(center_positions1 - center));
        [~, idx2] = min(abs(center_positions2 - center));
        
        % 获取对应值
        snr1 = snr_vals1(idx1);
        snr2 = snr_vals2(idx2);
        freq1 = main_freqs1(idx1);
        freq2 = main_freqs2(idx2);
        
        % 检查条件
        condition1 = (snr1 > min_snr) && (snr2 > min_snr);  % SNR条件
        condition2 = abs(freq1 - freq2) / mean([freq1, freq2]) < max_freq_diff;  % 频率一致性条件
        
        valid_flags(i) = condition1 && condition2;
        
        if valid_flags(i)
            valid_center_positions = [valid_center_positions; center];
        end
    end
    
    % 如果没有有效位置，返回空
    if isempty(valid_center_positions)
        fprintf('警告：没有窗口满足选择条件\n');
        return;
    end
    
    % 合并相邻的有效位置形成连续区间
    valid_center_positions = sort(valid_center_positions);
    gaps = diff(valid_center_positions);
    gap_threshold = 10 * 3;  % 允许的最大间隔
    
    bands = [];
    current_band = [valid_center_positions(1), valid_center_positions(1)];
    
    for i = 1:length(gaps)
        if gaps(i) <= gap_threshold
            current_band(2) = valid_center_positions(i+1);
        else
            bands = [bands; current_band];
            current_band = [valid_center_positions(i+1), valid_center_positions(i+1)];
        end
    end
    
    bands = [bands; current_band];
    
    % 调整频段边界
    for i = 1:size(bands, 1)
        bands(i, 1) = bands(i, 1) - window_width/2;
        bands(i, 2) = bands(i, 2) + window_width/2;
    end
    
    selected_bands = bands;
    
    fprintf('找到 %d 个候选频段\n', size(selected_bands, 1));
    for i = 1:size(selected_bands, 1)
        fprintf('  频段 %d: %.1f - %.1f cm⁻¹ (宽度: %.1f cm⁻¹)\n', ...
            i, selected_bands(i, 1), selected_bands(i, 2), ...
            selected_bands(i, 2) - selected_bands(i, 1));
    end
end