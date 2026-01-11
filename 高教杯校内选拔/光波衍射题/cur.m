%% 红外干涉测厚模型 - 两光束干涉厚度反演（完整预处理+FFT分析版）
clear; clc; close all;

%% 1. 读取数据并筛选1000-4000 cm⁻¹范围
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
n2 = 2.65;       % SiC衬底折射率 (根据文献/论文简化)
theta1_deg = 10; % 入射角1 (度)
theta2_deg = 15; % 入射角2 (度)
theta1 = deg2rad(theta1_deg);
theta2 = deg2rad(theta2_deg);

%% 2. 筛选1000-4000 cm⁻¹范围的数据（论文：<1000整体舍弃，仅保留1000-4000）
valid_idx1 = wavenumber1_raw >= 1000 & wavenumber1_raw <= 4000;
valid_idx2 = wavenumber2_raw >= 1000 & wavenumber2_raw <= 4000;

wavenumber1 = wavenumber1_raw(valid_idx1);
R_exp1_original = R_exp1_raw(valid_idx1);

wavenumber2 = wavenumber2_raw(valid_idx2);
R_exp2_original = R_exp2_raw(valid_idx2);

% 波数转换为波长 (μm)（本脚本主要用波数域，保留以备扩展）
lambda1 = 1e4 ./ wavenumber1;
lambda2 = 1e4 ./ wavenumber2;

%% 3. 数据预处理：AsLS去基线 + Hampel去噪 + SG平滑
% AsLS算法实现
function baseline = asymmetric_least_squares(y, lambda, p, order)
    w = ones(size(y));
    z = y;
    max_iter = 20;
    tol = 1e-6;

    for iter = 1:max_iter
        n = length(y);
        D = diff(speye(n), order);
        W = spdiags(w, 0, n, n);
        z_old = z;
        C = chol(W + lambda * (D' * D));
        z = C \ (C' \ (w .* y));
        residual = y - z;
        w = zeros(size(y));
        w(residual > 0) = p;
        w(residual <= 0) = 1 - p;
        if norm(z - z_old) / max(norm(z_old), eps) < tol
            break;
        end
    end
    baseline = z;
end

% 应用AsLS基线校正
lambda_asls = 1e5;
p_asls = 0.001;
order_asls = 2;

baseline1 = asymmetric_least_squares(R_exp1_original, lambda_asls, p_asls, order_asls);
R_exp1_detrended = R_exp1_original - baseline1;

baseline2 = asymmetric_least_squares(R_exp2_original, lambda_asls, p_asls, order_asls);
R_exp2_detrended = R_exp2_original - baseline2;

% Hampel滤波去噪
window_size = 11;
n_sigma = 3;
R_exp1_hampel = hampel(R_exp1_detrended, window_size, n_sigma);
R_exp2_hampel = hampel(R_exp2_detrended, window_size, n_sigma);

% Savitzky-Golay平滑
sg_window = 21;
sg_order = 3;
R_exp1_smooth = sgolayfilt(R_exp1_hampel, sg_order, sg_window);
R_exp2_smooth = sgolayfilt(R_exp2_hampel, sg_order, sg_window);

% 最终预处理后的数据（论文中的残差信号 r[n]）
R_exp1_processed = R_exp1_smooth;
R_exp2_processed = R_exp2_smooth;

%% 4. 滑动窗口FFT分析（用于绘制图5/图6所需的f'与SNR）
% 参数设置（论文：W=300 cm^-1，覆盖1000-4000）
W = 300;                 % 窗口宽度 (cm^{-1})
step = 10;               % 滑动步长 (cm^{-1})：更像论文的展示密度

wavenumber_min = 1000;
wavenumber_max = 4000;

% 创建波数向量
wave1 = wavenumber1(:);
wave2 = wavenumber2(:);
data1 = R_exp1_processed(:);
data2 = R_exp2_processed(:);

% 初始化结果存储
window_centers = [];
freq_results_10 = [];    % f' (10°)
freq_results_15 = [];    % f' (15°)
snr_results_10 = [];
snr_results_15 = [];

% 主峰搜索频段（避免DC；论文主峰一般在~0.004附近）
f_low = 0.002;
f_high = 0.01;

% ===== SNR背景包络参数（用户要求：env_win=31）=====
env_win = 31;      % movmedian窗口（奇数更好）
guard_bins = 12 ;   % SNR噪声估计时排除主峰附近bin数

center_wave = wavenumber_min + W/2;

while center_wave <= wavenumber_max - W/2
    wave_start = center_wave - W/2;
    wave_end = center_wave + W/2;

    idx1 = wave1 >= wave_start & wave1 <= wave_end;
    idx2 = wave2 >= wave_start & wave2 <= wave_end;

    if sum(idx1) > 10 && sum(idx2) > 10
        wave_win1 = wave1(idx1);
        data_win1 = data1(idx1);
        wave_win2 = wave2(idx2);
        data_win2 = data2(idx2);

        if length(wave_win1) > 1
            wave_uniform1 = linspace(min(wave_win1), max(wave_win1), length(wave_win1));
            data_uniform1 = interp1(wave_win1, data_win1, wave_uniform1, 'linear');

            wave_uniform2 = linspace(min(wave_win2), max(wave_win2), length(wave_win2));
            data_uniform2 = interp1(wave_win2, data_win2, wave_uniform2, 'linear');

            % 滑窗阶段只去均值，不做detrend
            data_uniform1 = data_uniform1 - mean(data_uniform1);
            data_uniform2 = data_uniform2 - mean(data_uniform2);

            N1 = length(data_uniform1);
            N2 = length(data_uniform2);

            % Hann窗（论文：r[n]·w[n]）
            w1 = hann(N1).';
            w2 = hann(N2).';
            y1 = data_uniform1 .* w1;
            y2 = data_uniform2 .* w2;

            Y1 = fft(y1);
            Y2 = fft(y2);

            dv1 = mean(diff(wave_uniform1));
            dv2 = mean(diff(wave_uniform2));

            f1 = (0:N1-1) / (N1 * dv1);
            f2 = (0:N2-1) / (N2 * dv2);

            h1 = floor(N1/2);
            h2 = floor(N2/2);

            f1 = f1(1:h1);
            f2 = f2(1:h2);

            % 谱幅值归一化：A = |FFT| / sum(window)
            A1 = abs(Y1(1:h1)) / max(sum(w1), eps);
            A2 = abs(Y2(1:h2)) / max(sum(w2), eps);

            % 在指定频段内找主峰
            v1 = (f1 >= f_low) & (f1 <= f_high);
            v2 = (f2 >= f_low) & (f2 <= f_high);

            if any(v1)
                idx1v = find(v1);
                [~, loc1] = max(A1(v1));
                k1 = idx1v(loc1);
            else
                k1 = 1;
            end

            if any(v2)
                idx2v = find(v2);
                [~, loc2] = max(A2(v2));
                k2 = idx2v(loc2);
            else
                k2 = 1;
            end

            % f'：三点抛物线插值得到更平滑的频率（用于画图/后续）
            main_f1 = peak_interp_from_k(f1, A1, k1);
            main_f2 = peak_interp_from_k(f2, A2, k2);

            % ===== 关键：SNR采用“峰高相对谱包络”/“残差谱噪声RMS” =====
            env1 = movmedian(A1, env_win);
            env2 = movmedian(A2, env_win);
            
            A1_res = A1 - env1;   % 关键：不要 max(...,0)
            A2_res = A2 - env2;
            
            q_noise = 0.97;       % 可调：0.7~0.9，越大噪声越大->SNR越小
            snr1 = snr_residual_quantile(A1_res, k1, v1, guard_bins, q_noise);
            snr2 = snr_residual_quantile(A2_res, k2, v2, guard_bins, q_noise);
            window_centers(end+1) = center_wave;
            freq_results_10(end+1) = main_f1;
            freq_results_15(end+1) = main_f2;
            snr_results_10(end+1) = snr1;
            snr_results_15(end+1) = snr2;
        end
    end

    center_wave = center_wave + step;
end
function snr = snr_residual_quantile(Ares, kpeak, validMask, guard, q)
    % 折中稳健SNR：
    % peak = |Ares(kpeak)|
    % noise = quantile(|Ares(noise)|, q) within valid band excluding peak±guard
    Ares = Ares(:);
    N = numel(Ares);

    if kpeak < 1 || kpeak > N
        snr = 0; return;
    end

    idxBand = find(validMask);
    if isempty(idxBand)
        snr = 0; return;
    end

    % 峰值（用绝对残差）
    peak = abs(Ares(kpeak));

    % 噪声点：带内排除主峰±guard
    reject = (idxBand >= (kpeak-guard)) & (idxBand <= (kpeak+guard));
    idxNoise = idxBand(~reject);

    if numel(idxNoise) < 50
        idxNoise = [1:(kpeak-guard-1), (kpeak+guard+1):N]';
    end
    if isempty(idxNoise)
        snr = 0; return;
    end

    noise_samples = abs(Ares(idxNoise));
    noise_samples = noise_samples(isfinite(noise_samples));
    if numel(noise_samples) < 20
        snr = 0; return;
    end

    noise_level = quantile(noise_samples, q);
    snr = peak / max(noise_level, eps);
end
function f_peak = peak_interp_from_k(f, A, k)
    % 三点抛物线插值：返回更平滑的峰频率
    f = f(:); A = A(:);
    if k <= 1 || k >= numel(A)
        f_peak = f(k);
        return;
    end
    y1 = A(k-1); y2 = A(k); y3 = A(k+1);
    denom = (y1 - 2*y2 + y3);
    if abs(denom) < 1e-12
        f_peak = f(k);
        return;
    end
    delta = 0.5*(y1 - y3) / denom;
    df = f(2) - f(1);
    f_peak = f(k) + delta * df;
end

function snr = snr_peak_over_env(A, env, Ares, kpeak, validMask, guard)
    % SNR更贴论文：峰值取“超过背景包络的高度”，噪声取“残差谱”RMS
    A = A(:); env = env(:); Ares = Ares(:);
    N = numel(A);

    if kpeak < 1 || kpeak > N
        snr = 0; return;
    end

    idxBand = find(validMask);
    if isempty(idxBand)
        snr = 0; return;
    end

    peak_height = max(A(kpeak) - env(kpeak), 0);

    reject = (idxBand >= (kpeak-guard)) & (idxBand <= (kpeak+guard));
    idxNoise = idxBand(~reject);

    if numel(idxNoise) < 50
        idxNoise = [1:(kpeak-guard-1), (kpeak+guard+1):N];
        idxNoise = idxNoise(:);
    end
    if isempty(idxNoise)
        snr = 0; return;
    end

    noise_rms = sqrt(mean(Ares(idxNoise).^2));
    snr = peak_height / max(noise_rms, eps);
end

%% ===== 为了让展示更接近论文：对SNR做平滑（仅用于画图）=====
snr_plot_10 = movmean(snr_results_10, 9);
snr_plot_15 = movmean(snr_results_15, 9);

%% 5. 自动band选择（仍使用原始snr_results_*，避免平滑影响筛选逻辑）
good_windows = false(size(window_centers));

for i = 1:length(window_centers)
    cond1 = snr_results_10(i) >= 10 && snr_results_15(i) >= 10;

    if freq_results_10(i) > 0 && freq_results_15(i) > 0
        freq_diff = abs(freq_results_10(i) - freq_results_15(i));
        freq_mean = (freq_results_10(i) + freq_results_15(i)) / 2;
        cond2 = (freq_diff / freq_mean) <= 0.10;
    else
        cond2 = false;
    end

    good_windows(i) = cond1 && cond2;
end

% 合并相邻窗口并做15-20 cm^-1安全裁切
band_intervals = [];
if any(good_windows)
    idx = 1;
    while idx <= length(good_windows)
        if good_windows(idx)
            start_idx = idx;
            while idx <= length(good_windows) && good_windows(idx)
                idx = idx + 1;
            end
            end_idx = idx - 1;

            wave_start = window_centers(start_idx) - W/2;
            wave_end = window_centers(end_idx) + W/2;

            safety_margin = 15 + 5*rand();
            wave_start = wave_start + safety_margin;
            wave_end = wave_end - safety_margin;

            if wave_end > wave_start
                band_intervals(end+1, :) = [wave_start, wave_end];
            end
        else
            idx = idx + 1;
        end
    end
end

% ===== 论文约束：排除低波数端（1000 cm^-1 附近Reststrahlen边界影响）=====
MIN_BAND_START = 1500;
MIN_BAND_WIDTH = 800;

if ~isempty(band_intervals)
    band_intervals = band_intervals(band_intervals(:,1) >= MIN_BAND_START, :);
    widths = band_intervals(:,2) - band_intervals(:,1);
    band_intervals = band_intervals(widths >= MIN_BAND_WIDTH, :);
end

% 选择最佳区间
if ~isempty(band_intervals)
    band_metrics = zeros(size(band_intervals, 1), 3); % [avgSNR, cycles, width]
    for i = 1:size(band_intervals, 1)
        wave_start = band_intervals(i, 1);
        wave_end = band_intervals(i, 2);

        in_band = window_centers >= (wave_start + W/2) & window_centers <= (wave_end - W/2);
        in_band = in_band & good_windows;

        if ~any(in_band)
            band_metrics(i,:) = [0,0,wave_end-wave_start];
            continue;
        end

        avg_snr = mean([mean(snr_results_10(in_band)), mean(snr_results_15(in_band))]);
        avg_freq_10 = mean(freq_results_10(in_band));
        band_width = wave_end - wave_start;
        num_cycles = band_width * avg_freq_10;

        band_metrics(i, :) = [avg_snr, num_cycles, band_width];
    end

    valid_bands = (band_metrics(:,2) >= 5) & (band_metrics(:,3) >= MIN_BAND_WIDTH);
    if any(valid_bands)
        valid_intervals = band_intervals(valid_bands, :);
        valid_metrics = band_metrics(valid_bands, :);
        [~, best_idx] = max(valid_metrics(:, 1));
        selected_band = valid_intervals(best_idx, :);
    else
        [~, best_idx] = max(band_metrics(:, 1));
        selected_band = band_intervals(best_idx, :);
    end
else
    selected_band = [2500, 3700];
end

disp(['Selected band: [', num2str(selected_band(1)), ', ', num2str(selected_band(2)), '] cm^{-1}']);

%% 6. 在有效频段内进行FFT厚度反演（用于绘制图7）
valid_idx1 = wave1 >= selected_band(1) & wave1 <= selected_band(2);
valid_idx2 = wave2 >= selected_band(1) & wave2 <= selected_band(2);

wave_band1 = wave1(valid_idx1);
data_band1 = data1(valid_idx1);
wave_band2 = wave2(valid_idx2);
data_band2 = data2(valid_idx2);

N_points = max(length(wave_band1), length(wave_band2));
wave_uniform1 = linspace(min(wave_band1), max(wave_band1), N_points);
data_uniform1 = interp1(wave_band1, data_band1, wave_uniform1, 'spline');

wave_uniform2 = linspace(min(wave_band2), max(wave_band2), N_points);
data_uniform2 = interp1(wave_band2, data_band2, wave_uniform2, 'spline');

data_uniform1 = data_uniform1 - mean(data_uniform1);
data_uniform2 = data_uniform2 - mean(data_uniform2);

hann_window = hann(N_points)';
data_windowed1 = data_uniform1 .* hann_window;
data_windowed2 = data_uniform2 .* hann_window;

fft_result1 = fft(data_windowed1);
fft_result2 = fft(data_windowed2);

wave_spacing1 = mean(diff(wave_uniform1));
wave_spacing2 = mean(diff(wave_uniform2));

freq_axis1 = (0:N_points-1) / (N_points * wave_spacing1);
freq_axis2 = (0:N_points-1) / (N_points * wave_spacing2);

half_idx = floor(N_points/2);
freq_axis1 = freq_axis1(1:half_idx);
fft_mag1 = abs(fft_result1(1:half_idx));

freq_axis2 = freq_axis2(1:half_idx);
fft_mag2 = abs(fft_result2(1:half_idx));

validF1 = (freq_axis1 >= f_low) & (freq_axis1 <= f_high);
validF2 = (freq_axis2 >= f_low) & (freq_axis2 <= f_high);

[max_mag1, li1] = max(fft_mag1(validF1));
idxMap1 = find(validF1);
max_idx1 = idxMap1(li1);
main_freq1 = freq_axis1(max_idx1);

[max_mag2, li2] = max(fft_mag2(validF2));
idxMap2 = find(validF2);
max_idx2 = idxMap2(li2);
main_freq2 = freq_axis2(max_idx2);

if main_freq1 <= 0 || main_freq2 <= 0
    error('FFT 主频无效，请检查峰值搜索频段或数据质量。');
end

delta_v1 = 1 / main_freq1;
delta_v2 = 1 / main_freq2;

cos_theta_t1 = sqrt(1 - (sin(theta1) / n2)^2);
cos_theta_t2 = sqrt(1 - (sin(theta2) / n2)^2);

d0_10 = 1e4 / (2 * n2 * cos_theta_t1 * delta_v1);
d0_15 = 1e4 / (2 * n2 * cos_theta_t2 * delta_v2);

d0_avg = (d0_10 + d0_15) / 2;
relative_diff = abs(d0_10 - d0_15) / max(d0_avg, eps) * 100;

%% 7. 显示结果
disp('===== 厚度反演结果 =====');
disp(['10° 入射角厚度: ', num2str(d0_10, '%.3f'), ' μm']);
disp(['15° 入射角厚度: ', num2str(d0_15, '%.3f'), ' μm']);
disp(['平均厚度: ', num2str(d0_avg, '%.3f'), ' μm']);
disp(['相对差异: ', num2str(relative_diff, '%.2f'), ' %']);

%% 8. 绘图（按截图风格：图5/图6/图7）
PLOT_MIN = 1500;
PLOT_MAX = 3500;
plot_mask = (window_centers >= PLOT_MIN) & (window_centers <= PLOT_MAX);

figure('Name','Fig.5 全谱滑动窗FFT结果(1500-3500)','Position',[80, 80, 1100, 800]);

subplot(2,2,1);
plot(window_centers(plot_mask), freq_results_10(plot_mask), 'b-', 'LineWidth', 1.0);
grid on; xlim([PLOT_MIN PLOT_MAX]);
xlabel('\sigma_{center} (cm^{-1})');
ylabel('f'' (1/\Delta\nu) [cm]');
title('10° f'' vs center \sigma');

subplot(2,2,2);
plot(window_centers(plot_mask), snr_plot_10(plot_mask), 'b-', 'LineWidth', 1.0);
yline(10,'k--','LineWidth',1);
grid on; xlim([PLOT_MIN PLOT_MAX]);
xlabel('\sigma_{center} (cm^{-1})');
ylabel('SNR (smoothed for plot)');
title('10° SNR vs center \sigma');

subplot(2,2,3);
plot(window_centers(plot_mask), freq_results_15(plot_mask), 'b-', 'LineWidth', 1.0);
grid on; xlim([PLOT_MIN PLOT_MAX]);
xlabel('\sigma_{center} (cm^{-1})');
ylabel('f'' (1/\Delta\nu) [cm]');
title('15° f'' vs center \sigma');

subplot(2,2,4);
plot(window_centers(plot_mask), snr_plot_15(plot_mask), 'b-', 'LineWidth', 1.0);
yline(10,'k--','LineWidth',1);
grid on; xlim([PLOT_MIN PLOT_MAX]);
xlabel('\sigma_{center} (cm^{-1})');
ylabel('SNR (smoothed for plot)');
title('15° SNR vs center \sigma');

figure('Name','Fig.6 有效频段选择(1500-3500)','Position',[120, 120, 1100, 480]);
hold on; grid on;

plot(window_centers(plot_mask), snr_plot_10(plot_mask), '-', 'Color',[0 0.45 0.74], 'LineWidth', 1.2);
plot(window_centers(plot_mask), snr_plot_15(plot_mask), '-', 'Color',[0.85 0.33 0.10], 'LineWidth', 1.2);

yl = ylim;

for i = 1:size(band_intervals,1)
    x1 = max(band_intervals(i,1), PLOT_MIN);
    x2 = min(band_intervals(i,2), PLOT_MAX);
    if x2 > x1
        patch([x1 x2 x2 x1], [yl(1) yl(1) yl(2) yl(2)], ...
              [0.75 0.85 1.0], 'FaceAlpha', 0.25, 'EdgeColor','none');
    end
end

x1 = max(selected_band(1), PLOT_MIN);
x2 = min(selected_band(2), PLOT_MAX);
if x2 > x1
    patch([x1 x2 x2 x1], [yl(1) yl(1) yl(2) yl(2)], ...
          [0.2 0.6 0.9], 'FaceAlpha', 0.20, 'EdgeColor','none');
end

yline(10,'k--','LineWidth',1);
xlabel('Center \sigma (cm^{-1})');
ylabel('SNR (smoothed for plot)');
title('Band candidates & selected band');
legend({'SNR 10°','SNR 15°','band candidates','band used','SNR=10'},'Location','northwest');
xlim([PLOT_MIN PLOT_MAX]);

figure('Name','Fig.7 band内FFT频谱','Position',[160, 160, 1100, 420]);

subplot(1,2,1);
plot(freq_axis1, fft_mag1./max(fft_mag1), 'b-', 'LineWidth', 1.5); hold on; grid on;
xline(main_freq1, 'k--', 'LineWidth', 1.2);
xlim([0 0.02]);
xlabel('f (cm)');
ylabel('Normalized |Y(f)|');
title('10° FFT in band');
legend({ 'spectrum', sprintf('f''=%.5f', main_freq1)}, 'Location','northeast');

subplot(1,2,2);
plot(freq_axis2, fft_mag2./max(fft_mag2), 'b-', 'LineWidth', 1.5); hold on; grid on;
xline(main_freq2, 'k--', 'LineWidth', 1.2);
xlim([0 0.02]);
xlabel('f (cm)');
ylabel('Normalized |Y(f)|');
title('15° FFT in band');
legend({ 'spectrum', sprintf('f''=%.5f', main_freq2)}, 'Location','northeast');

%% 保存结果
save('thickness_estimation_results.mat', 'selected_band', 'd0_10', 'd0_15', 'd0_avg', 'relative_diff', ...
    'window_centers', 'freq_results_10', 'freq_results_15', 'snr_results_10', 'snr_results_15', 'band_intervals', ...
    'freq_axis1', 'fft_mag1', 'freq_axis2', 'fft_mag2', 'main_freq1', 'main_freq2', 'delta_v1', 'delta_v2', ...
    'snr_plot_10', 'snr_plot_15', 'env_win', 'guard_bins');
disp('结果已保存到 thickness_estimation_results.mat');