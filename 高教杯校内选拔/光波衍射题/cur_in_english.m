%% Infrared Interferometric Thickness Measurement Model - Two-Beam Interference Thickness Inversion (Complete Preprocessing Version)
clear; clc; close all;

%% 1. Read data and filter 1000-4000 cm⁻¹ range
disp('Reading data and filtering 1000-4000 cm⁻¹ range...');
data1 = readmatrix('附件1.xlsx');
data2 = readmatrix('附件2.xlsx');

% Extract data
wavenumber1_raw = data1(:, 1);  % Wavenumber (cm^-1)
R_exp1_raw = data1(:, 2);       % Reflectivity (%)

wavenumber2_raw = data2(:, 1);  % Wavenumber (cm^-1)
R_exp2_raw = data2(:, 2);       % Reflectivity (%)

% Convert to decimal
R_exp1_raw = R_exp1_raw / 100;
R_exp2_raw = R_exp2_raw / 100;

% Parameters
n0 = 1;          % Air refractive index
n2 = 2.65;       % SiC substrate refractive index (from literature)
theta1_deg = 10; % Incidence angle 1 (degrees)
theta2_deg = 15; % Incidence angle 2 (degrees)
theta1 = deg2rad(theta1_deg);
theta2 = deg2rad(theta2_deg);

%% 2. First filter data in 1000-4000 cm⁻¹ range
disp('Filtering data (1000-4000 cm⁻¹)...');

% Filter data in 1000-4000 cm⁻¹ range
valid_idx1 = wavenumber1_raw >= 1000 & wavenumber1_raw <= 4000;
valid_idx2 = wavenumber2_raw >= 1000 & wavenumber2_raw <= 4000;

wavenumber1 = wavenumber1_raw(valid_idx1);
R_exp1_original = R_exp1_raw(valid_idx1);

wavenumber2 = wavenumber2_raw(valid_idx2);
R_exp2_original = R_exp2_raw(valid_idx2);

% Convert wavenumber to wavelength (μm)
lambda1 = 1e4 ./ wavenumber1;  % Wavelength (μm)
lambda2 = 1e4 ./ wavenumber2;  % Wavelength (μm)

fprintf('Data filtering results:\n');
fprintf('10° incidence angle data points: %d (original: %d)\n', length(wavenumber1), length(wavenumber1_raw));
fprintf('15° incidence angle data points: %d (original: %d)\n', length(wavenumber2), length(wavenumber2_raw));
fprintf('10° incidence angle wavenumber range: %.1f - %.1f cm⁻¹\n', min(wavenumber1), max(wavenumber1));
fprintf('15° incidence angle wavenumber range: %.1f - %.1f cm⁻¹\n\n', min(wavenumber2), max(wavenumber2));

%% 3. Data preprocessing: detrending, denoising, smoothing (on filtered data)
disp('Starting data preprocessing...');

% ===================== Step 1: Asymmetric Least Squares (AsLS) baseline correction =====================
disp('Performing AsLS baseline correction...');

% AsLS algorithm implementation
function baseline = asymmetric_least_squares(y, lambda, p, order)
    % y: original signal
    % lambda: smoothing parameter
    % p: asymmetry parameter (0<p<1)
    % order: difference order (usually 2)
    
    % Initialize weights
    w = ones(size(y));
    z = y;
    
    % Iterative solution
    max_iter = 20;
    tol = 1e-6;
    
    for iter = 1:max_iter
        % Construct difference matrix
        n = length(y);
        D = diff(speye(n), order);
        
        % Construct weight matrix
        W = spdiags(w, 0, n, n);
        
        % Solve least squares problem: (W + lambda*D'*D)z = W*y
        z_old = z;
        C = chol(W + lambda * (D' * D));
        z = C \ (C' \ (w .* y));
        
        % Update weights
        residual = y - z;
        w = zeros(size(y));
        w(residual > 0) = p;
        w(residual <= 0) = 1 - p;
        
        % Check convergence
        if norm(z - z_old) / norm(z_old) < tol
            break;
        end
    end
    
    baseline = z;
end

% Apply AsLS baseline correction
lambda_asls = 1e5;  % Smoothing parameter
p_asls = 0.001;     % Asymmetry parameter
order_asls = 2;     % Second-order difference

% Baseline correction for 10° data
baseline1 = asymmetric_least_squares(R_exp1_original, lambda_asls, p_asls, order_asls);
R_exp1_detrended = R_exp1_original - baseline1;

% Baseline correction for 15° data
baseline2 = asymmetric_least_squares(R_exp2_original, lambda_asls, p_asls, order_asls);
R_exp2_detrended = R_exp2_original - baseline2;

% ===================== Step 2: Hampel filtering for denoising =====================
disp('Performing Hampel filtering...');
window_size = 11;  % Window size
n_sigma = 3;       % Standard deviation multiplier

R_exp1_hampel = hampel(R_exp1_detrended, window_size, n_sigma);
R_exp2_hampel = hampel(R_exp2_detrended, window_size, n_sigma);

% ===================== Step 3: Savitzky-Golay smoothing =====================
disp('Performing Savitzky-Golay smoothing...');
sg_window = 21;      % Window width (odd)
sg_order = 3;        % Polynomial order

R_exp1_smooth = sgolayfilt(R_exp1_hampel, sg_order, sg_window);
R_exp2_smooth = sgolayfilt(R_exp2_hampel, sg_order, sg_window);

% Final preprocessed data
R_exp1_processed = R_exp1_smooth;
R_exp2_processed = R_exp2_smooth;

% Plot preprocessing process comparison
figure('Position', [100, 100, 1400, 800]);

% 10° data preprocessing process
subplot(2, 3, 1);
plot(wavenumber1, R_exp1_original, 'k-', 'LineWidth', 1, 'DisplayName', 'Original Data');
hold on;
plot(wavenumber1, baseline1, 'r--', 'LineWidth', 2, 'DisplayName', 'Baseline');
xlabel('Wavenumber (cm^{-1})');
ylabel('Reflectivity');
title('10° Data - Original Data and Baseline (1000-4000 cm⁻¹)');
legend('Location', 'best');
grid on;
xlim([min(wavenumber1), max(wavenumber1)]);

subplot(2, 3, 2);
plot(wavenumber1, R_exp1_detrended, 'b-', 'LineWidth', 1, 'DisplayName', 'Detrended');
hold on;
plot(wavenumber1, R_exp1_hampel, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Hampel Filtered');
xlabel('Wavenumber (cm^{-1})');
ylabel('Reflectivity');
title('10° Data - Detrending and Filtering (1000-4000 cm⁻¹)');
legend('Location', 'best');
grid on;
xlim([min(wavenumber1), max(wavenumber1)]);

subplot(2, 3, 3);
plot(wavenumber1, R_exp1_processed, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Final Processed');
hold on;
plot(wavenumber1, R_exp1_original, 'k:', 'LineWidth', 0.5, 'DisplayName', 'Original Reference');
xlabel('Wavenumber (cm^{-1})');
ylabel('Reflectivity');
title('10° Data - Final Processed Result (1000-4000 cm⁻¹)');
legend('Location', 'best');
grid on;
xlim([min(wavenumber1), max(wavenumber1)]);

% 15° data preprocessing process
subplot(2, 3, 4);
plot(wavenumber2, R_exp2_original, 'k-', 'LineWidth', 1, 'DisplayName', 'Original Data');
hold on;
plot(wavenumber2, baseline2, 'r--', 'LineWidth', 2, 'DisplayName', 'Baseline');
xlabel('Wavenumber (cm^{-1})');
ylabel('Reflectivity');
title('15° Data - Original Data and Baseline (1000-4000 cm⁻¹)');
legend('Location', 'best');
grid on;
xlim([min(wavenumber2), max(wavenumber2)]);

subplot(2, 3, 5);
plot(wavenumber2, R_exp2_detrended, 'b-', 'LineWidth', 1, 'DisplayName', 'Detrended');
hold on;
plot(wavenumber2, R_exp2_hampel, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Hampel Filtered');
xlabel('Wavenumber (cm^{-1})');
ylabel('Reflectivity');
title('15° Data - Detrending and Filtering (1000-4000 cm⁻¹)');
legend('Location', 'best');
grid on;
xlim([min(wavenumber2), max(wavenumber2)]);

subplot(2, 3, 6);
plot(wavenumber2, R_exp2_processed, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Final Processed');
hold on;
plot(wavenumber2, R_exp2_original, 'k:', 'LineWidth', 0.5, 'DisplayName', 'Original Reference');
xlabel('Wavenumber (cm^{-1})');
ylabel('Reflectivity');
title('15° Data - Final Processed Result (1000-4000 cm⁻¹)');
legend('Location', 'best');
grid on;
xlim([min(wavenumber2), max(wavenumber2)]);

% Use preprocessed data
R_exp1 = R_exp1_processed;
R_exp2 = R_exp2_processed;

%% 4. Sliding Window FFT Analysis (according to paper description)
disp('Performing sliding window FFT analysis...');

% Sliding window parameters
window_width = 300;  % Window width (cm⁻¹) - according to paper W=300cm⁻¹
step_size = 10;      % Step size (cm⁻¹)

% Perform sliding window FFT analysis for both angles
[center_positions1, main_freqs1, snr_vals1] = sliding_window_fft_analysis(...
    wavenumber1, R_exp1, window_width, step_size, theta1_deg);

[center_positions2, main_freqs2, snr_vals2] = sliding_window_fft_analysis(...
    wavenumber2, R_exp2, window_width, step_size, theta2_deg);

% Plot sliding window FFT analysis results
figure('Position', [100, 100, 1400, 600]);

% 10° data main frequency and SNR
subplot(2, 2, 1);
plot(center_positions1, main_freqs1, 'b-', 'LineWidth', 2);
xlabel('Window Center Wavenumber (cm^{-1})');
ylabel('Main Frequency (cm)');
title(sprintf('10° Data - Sliding Window Main Frequency (window width=%d cm⁻¹)', window_width));
grid on;
xlim([min(center_positions1), max(center_positions1)]);

subplot(2, 2, 2);
plot(center_positions1, snr_vals1, 'b-', 'LineWidth', 2);
xlabel('Window Center Wavenumber (cm^{-1})');
ylabel('SNR (dB)');
title(sprintf('10° Data - Sliding Window SNR (window width=%d cm⁻¹)', window_width));
grid on;
xlim([min(center_positions1), max(center_positions1)]);

% 15° data main frequency and SNR
subplot(2, 2, 3);
plot(center_positions2, main_freqs2, 'r-', 'LineWidth', 2);
xlabel('Window Center Wavenumber (cm^{-1})');
ylabel('Main Frequency (cm)');
title(sprintf('15° Data - Sliding Window Main Frequency (window width=%d cm⁻¹)', window_width));
grid on;
xlim([min(center_positions2), max(center_positions2)]);

subplot(2, 2, 4);
plot(center_positions2, snr_vals2, 'r-', 'LineWidth', 2);
xlabel('Window Center Wavenumber (cm^{-1})');
ylabel('SNR (dB)');
title(sprintf('15° Data - Sliding Window SNR (window width=%d cm⁻¹)', window_width));
grid on;
xlim([min(center_positions2), max(center_positions2)]);

%% 5. Automatic Band Selection (according to paper criteria)
disp('Performing automatic band selection...');

% Set band selection criteria
min_snr = 10;           % SNR > 10 dB
max_freq_diff = 0.10;   % Main frequency relative difference < 10%
min_cycles = 5;         % At least 5 fringe cycles
safety_margin = 20;     % Safety clipping boundary (cm⁻¹)

% Execute automatic band selection
[selected_bands, valid_center_positions] = auto_band_selection(...
    center_positions1, center_positions2, ...
    main_freqs1, main_freqs2, ...
    snr_vals1, snr_vals2, ...
    min_snr, max_freq_diff, min_cycles, safety_margin, window_width);

% Plot band selection results
figure('Position', [100, 100, 1200, 400]);

subplot(1, 2, 1);
hold on;
plot(center_positions1, snr_vals1, 'b-', 'LineWidth', 1.5, 'DisplayName', '10° SNR');
plot(center_positions2, snr_vals2, 'r-', 'LineWidth', 1.5, 'DisplayName', '15° SNR');

% Mark selected bands - fixed fill function error
if ~isempty(selected_bands)
    % Calculate maximum SNR
    max_snr = max([max(snr_vals1), max(snr_vals2)]);
    
    for i = 1:size(selected_bands, 1)
        band_start = selected_bands(i, 1);
        band_end = selected_bands(i, 2);
        
        % Use correct fill function parameters
        fill([band_start, band_end, band_end, band_start], ...
             [0, 0, max_snr, max_snr], ...
             'g', 'FaceAlpha', 0.2, 'EdgeColor', 'g', 'LineWidth', 1.5, ...
             'DisplayName', sprintf('Selected Band %d', i));
    end
end

xlabel('Wavenumber (cm^{-1})');
ylabel('SNR (dB)');
title('Band Selection Results - SNR (1000-4000 cm⁻¹)');
legend('Location', 'best');
grid on;
xlim([1000, 4000]);
ylim([0, max([max(snr_vals1), max(snr_vals2)]) * 1.1]);

subplot(1, 2, 2);
hold on;
plot(center_positions1, main_freqs1, 'b-', 'LineWidth', 1.5, 'DisplayName', '10° Main Freq');
plot(center_positions2, main_freqs2, 'r-', 'LineWidth', 1.5, 'DisplayName', '15° Main Freq');

% Mark selected bands - fixed fill function error
if ~isempty(selected_bands)
    % Calculate minimum and maximum main frequencies
    min_freq = min([min(main_freqs1), min(main_freqs2)]);
    max_freq = max([max(main_freqs1), max(main_freqs2)]);
    
    for i = 1:size(selected_bands, 1)
        band_start = selected_bands(i, 1);
        band_end = selected_bands(i, 2);
        
        % Use correct fill function parameters
        fill([band_start, band_end, band_end, band_start], ...
             [min_freq, min_freq, max_freq, max_freq], ...
             'g', 'FaceAlpha', 0.2, 'EdgeColor', 'g', 'LineWidth', 1.5, ...
             'DisplayName', sprintf('Selected Band %d', i));
    end
end

xlabel('Wavenumber (cm^{-1})');
ylabel('Main Frequency (cm)');
title('Band Selection Results - Main Frequency (1000-4000 cm⁻¹)');
legend('Location', 'best');
grid on;
xlim([1000, 4000]);
ylim([min_freq * 0.9, max_freq * 1.1]);

% Select best band (according to paper: highest average SNR and sufficient fringe cycles)
if ~isempty(selected_bands)
    % Calculate average SNR for each band
    band_snrs = zeros(size(selected_bands, 1), 1);
    band_cycles = zeros(size(selected_bands, 1), 1);
    
    for i = 1:size(selected_bands, 1)
        band_start = selected_bands(i, 1);
        band_end = selected_bands(i, 2);
        
        % Calculate average SNR
        idx1 = center_positions1 >= band_start & center_positions1 <= band_end;
        idx2 = center_positions2 >= band_start & center_positions2 <= band_end;
        
        band_snrs(i) = mean([snr_vals1(idx1); snr_vals2(idx2)]);
        
        % Calculate number of fringe cycles
        band_width = band_end - band_start;
        avg_freq = mean([main_freqs1(idx1); main_freqs2(idx2)]);
        band_cycles(i) = band_width * avg_freq;
    end
    
    % Select best band (high SNR and cycle count ≥ 5)
    valid_idx = band_cycles >= min_cycles;
    if any(valid_idx)
        valid_snrs = band_snrs(valid_idx);
        valid_bands = selected_bands(valid_idx, :);
        
        [~, best_idx] = max(valid_snrs);
        best_band = valid_bands(best_idx, :);
    else
        % If no band satisfies cycle count requirement, select band with highest SNR
        [~, best_idx] = max(band_snrs);
        best_band = selected_bands(best_idx, :);
    end
    
    % Apply safety clipping
    best_band(1) = best_band(1) + safety_margin;
    best_band(2) = best_band(2) - safety_margin;
    
    fprintf('Best band selection results:\n');
    fprintf('Band range: %.1f - %.1f cm⁻¹\n', best_band(1), best_band(2));
    fprintf('Band width: %.1f cm⁻¹\n', best_band(2) - best_band(1));
    fprintf('Average SNR: %.2f dB\n', band_snrs(best_idx));
    fprintf('Estimated fringe cycles: %.1f\n\n', band_cycles(best_idx));
    
    % Filter data within best band
    valid_idx1_band = wavenumber1 >= best_band(1) & wavenumber1 <= best_band(2);
    valid_idx2_band = wavenumber2 >= best_band(1) & wavenumber2 <= best_band(2);
    
    % If too few data points after filtering, use default range
    if sum(valid_idx1_band) < 50 || sum(valid_idx2_band) < 50
        fprintf('Warning: Insufficient data points in best band, using 2500-3700 cm⁻¹ range (from paper)\n');
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
    
    fprintf('Best band data statistics:\n');
    fprintf('10° data points: %d\n', length(wavenumber1_band));
    fprintf('15° data points: %d\n', length(wavenumber2_band));
else
    fprintf('Warning: No valid band found, using default range 2500-3700 cm⁻¹\n');
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

%% 6. FFT analysis within effective band to calculate initial thickness
disp('Performing FFT analysis within effective band to calculate initial thickness...');

% Perform FFT analysis for both angles
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
    
    % Apply Hann window
    L = length(R_exp_band);
    hann_window = hann(L);
    signal_windowed = R_exp_band .* hann_window;
    
    % Perform FFT
    Y = fft(signal_windowed);
    P2 = abs(Y/L);
    P1 = P2(1:floor(L/2)+1);
    P1(2:end-1) = 2*P1(2:end-1);
    
    % Calculate frequency axis
    Fs = 1 / (wavenumber_band(2) - wavenumber_band(1));
    f = Fs * (0:floor(L/2)) / L;
    
    % Find main frequency (ignore near-zero frequencies)
    search_range = 10:min(50, length(P1));
    [~, idx] = max(P1(search_range));
    f_main = f(search_range(idx));
    
    % Calculate fringe period
    delta_nu = 1 / f_main;
    
    % Calculate initial thickness
    % Formula: d0 = 1 / (2 * n_avg * cos(theta_t) * delta_nu)
    % where cos(theta_t) = sqrt(1 - (sin(theta)/n_avg)^2)
    
    % For SiC epitaxial layer, initial refractive index estimate
    n_avg_guess = 2.65;
    cos_theta_t = sqrt(1 - (sind(theta_deg)/n_avg_guess)^2);
    
    d_initial = 1e4 / (2 * n_avg_guess * cos_theta_t * delta_nu);  % Convert to μm
    
    d_initial_estimates(angle_idx) = d_initial;
    
    % Alternatively, infer refractive index from thickness
    refractive_estimates(angle_idx) = 1e4 / (2 * d_initial * cos_theta_t * delta_nu);
    
    fprintf('%s incidence angle:\n', angle_name);
    fprintf('  Main frequency: %.6f cm\n', f_main);
    fprintf('  Fringe period: %.2f cm⁻¹\n', delta_nu);
    fprintf('  Initial thickness estimate: %.1f μm\n', d_initial);
    fprintf('  Refractive index estimate: %.4f\n\n', refractive_estimates(angle_idx));
end

% Take average of both angles as initial thickness
d0 = mean(d_initial_estimates);
n1_initial = mean(refractive_estimates);

fprintf('Comprehensive initial estimates:\n');
fprintf('Initial thickness: %.1f μm\n', d0);
fprintf('Initial refractive index: %.4f\n\n', n1_initial);

%% 7. Define theoretical reflectivity model (same as original code)
% Cauchy refractive index model: n1(λ) = A + B/λ^2 (λ in μm)
% Reflectivity calculation function
function R = calc_reflectivity(lambda, theta, d, A, B, n0, n2)
    % Calculate epitaxial layer refractive index
    n1 = A + B ./ (lambda.^2);
    
    % Snell's law to calculate refraction angle
    sin_theta1 = n0 * sin(theta) ./ n1;
    % Avoid numerical issues
    sin_theta1(sin_theta1 > 1) = 1;
    sin_theta1(sin_theta1 < -1) = -1;
    theta1 = asin(sin_theta1);
    
    sin_theta2 = n1 .* sin(theta1) / n2;
    sin_theta2(sin_theta2 > 1) = 1;
    sin_theta2(sin_theta2 < -1) = -1;
    theta2 = asin(sin_theta2);
    
    % Calculate reflection coefficients (s-polarization)
    % Correction: ensure denominator is not zero
    denominator01 = n0*cos(theta) + n1.*cos(theta1);
    denominator12 = n1.*cos(theta1) + n2*cos(theta2);
    
    r01 = (n0*cos(theta) - n1.*cos(theta1)) ./ denominator01;
    r12 = (n1.*cos(theta1) - n2*cos(theta2)) ./ denominator12;
    
    % Calculate phase difference
    delta = (4 * pi * n1 .* d .* cos(theta1)) ./ lambda;
    
    % Calculate total reflectivity
    R = abs(r01 + r12 .* exp(1i * delta)).^2;
    
    % Ensure reflectivity is within reasonable range
    R = max(0, min(1, R));
end

%% 8. Define objective function (weighted least squares)
function [residuals, weights] = objective_func(params, lambda1, R_exp1, theta1, ...
                                                lambda2, R_exp2, theta2, n0, n2, use_weights)
    d = params(1);  % Thickness (μm)
    A = params(2);  % Cauchy parameter A
    B = params(3);  % Cauchy parameter B (μm^2)
    
    % Calculate theoretical reflectivity
    R_theory1 = calc_reflectivity(lambda1, theta1, d, A, B, n0, n2);
    R_theory2 = calc_reflectivity(lambda2, theta2, d, A, B, n0, n2);
    
    % Calculate residuals
    residuals1 = R_exp1 - R_theory1;
    residuals2 = R_exp2 - R_theory2;
    
    % Calculate weights (if enabled)
    weights1 = ones(size(residuals1));
    weights2 = ones(size(residuals2));
    
    if use_weights
        % Weight based on reflectivity magnitude (higher weight for middle values, lower for extremes)
        weights1 = 0.5 + 0.5 * cos(2*pi*(R_exp1 - 0.5));
        weights2 = 0.5 + 0.5 * cos(2*pi*(R_exp2 - 0.5));
        
        % Avoid zero weights
        weights1 = max(weights1, 0.1);
        weights2 = max(weights2, 0.1);
    end
    
    % Weighted residuals
    residuals = [residuals1 .* weights1; residuals2 .* weights2];
    
    % Return weights (for subsequent analysis)
    weights = [weights1; weights2];
end

%% 9. Parameter fitting (using best band data)
disp('Starting parameter fitting (using best band data)...');

% Use data from best band
lambda1 = lambda1_band;
R_exp1 = R_exp1_band;
wavenumber1 = wavenumber1_band;

lambda2 = lambda2_band;
R_exp2 = R_exp2_band;
wavenumber2 = wavenumber2_band;

% Initial parameter guesses
A0 = n1_initial;
B0 = 0.01;  % Initial B value guess
initial_params = [d0, A0, B0];

fprintf('Fitting parameter initialization:\n');
fprintf('Initial thickness: %.1f μm\n', d0);
fprintf('Initial A: %.4f\n', A0);
fprintf('Initial B: %.6f μm²\n\n', B0);

% Set parameter bounds
lb = [max(0.1, d0*0.5), 2.4, 0.001];   % Lower bounds
ub = [d0*2, 2.8, 0.05];                % Upper bounds

% Set fitting options
options = optimoptions('lsqnonlin', 'Display', 'iter', ...
                       'MaxFunctionEvaluations', 3000, ...
                       'MaxIterations', 500, ...
                       'FunctionTolerance', 1e-8, ...
                       'StepTolerance', 1e-8, ...
                       'Algorithm', 'trust-region-reflective');

% Define objective function (with weights)
obj_func = @(params) objective_func(params, lambda1, R_exp1, theta1, ...
                                    lambda2, R_exp2, theta2, n0, n2, true);

% Perform nonlinear least squares fitting
[params_opt, resnorm, residual, exitflag, output] = ...
    lsqnonlin(obj_func, initial_params, lb, ub, options);

% Extract fitting results
d_opt = params_opt(1);
A_opt = params_opt(2);
B_opt = params_opt(3);

fprintf('\nBest fitting results:\n');
fprintf('Optimized thickness: %.4f μm\n', d_opt);
fprintf('Cauchy parameter A: %.6f\n', A_opt);
fprintf('Cauchy parameter B: %.6f μm²\n', B_opt);
fprintf('Residual sum of squares: %.6f\n', resnorm);
fprintf('Number of iterations: %d\n', output.iterations);
fprintf('Exit flag: %d\n', exitflag);

%% 10. Calculate fitted reflectivity and plot comparison
disp('Calculating fitting results and plotting...');
% Calculate fitted reflectivity
R_fit1 = calc_reflectivity(lambda1, theta1, d_opt, A_opt, B_opt, n0, n2);
R_fit2 = calc_reflectivity(lambda2, theta2, d_opt, A_opt, B_opt, n0, n2);

% Calculate residuals
residual1 = R_exp1 - R_fit1;
residual2 = R_exp2 - R_fit2;

% Plot fitting results comparison
figure('Position', [100, 100, 1400, 600]);

% 10° incidence angle
subplot(2, 2, 1);
plot(wavenumber1, R_exp1, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Preprocessed Data');
hold on;
plot(wavenumber1, R_fit1, 'r--', 'LineWidth', 2, 'DisplayName', 'Fitted Result');
xlabel('Wavenumber (cm^{-1})');
ylabel('Reflectivity');
title(sprintf('10° Incidence Angle - Fitting Comparison (d=%.2f μm)', d_opt));
legend('Location', 'best');
grid on;
xlim([min(wavenumber1), max(wavenumber1)]);

% 15° incidence angle
subplot(2, 2, 2);
plot(wavenumber2, R_exp2, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Preprocessed Data');
hold on;
plot(wavenumber2, R_fit2, 'r--', 'LineWidth', 2, 'DisplayName', 'Fitted Result');
xlabel('Wavenumber (cm^{-1})');
ylabel('Reflectivity');
title(sprintf('15° Incidence Angle - Fitting Comparison (d=%.2f μm)', d_opt));
legend('Location', 'best');
grid on;
xlim([min(wavenumber2), max(wavenumber2)]);

% 10° incidence angle residuals
subplot(2, 2, 3);
plot(wavenumber1, residual1, 'k-', 'LineWidth', 1);
hold on;
plot(wavenumber1, zeros(size(wavenumber1)), 'r--', 'LineWidth', 1);
xlabel('Wavenumber (cm^{-1})');
ylabel('Residual');
title('10° Incidence Angle - Fitting Residuals');
grid on;
xlim([min(wavenumber1), max(wavenumber1)]);
% Auto-adjust y-axis range
residual_range1 = max(abs(residual1));
ylim([-1.5*residual_range1, 1.5*residual_range1]);

% 15° incidence angle residuals
subplot(2, 2, 4);
plot(wavenumber2, residual2, 'k-', 'LineWidth', 1);
hold on;
plot(wavenumber2, zeros(size(wavenumber2)), 'r--', 'LineWidth', 1);
xlabel('Wavenumber (cm^{-1})');
ylabel('Residual');
title('15° Incidence Angle - Fitting Residuals');
grid on;
xlim([min(wavenumber2), max(wavenumber2)]);
% Auto-adjust y-axis range
residual_range2 = max(abs(residual2));
ylim([-1.5*residual_range2, 1.5*residual_range2]);

%% 11. Model evaluation metrics (same as original code)
disp('Calculating model evaluation metrics...');

% Calculate coefficient of determination R²
SS_tot1 = sum((R_exp1 - mean(R_exp1)).^2);
SS_res1 = sum(residual1.^2);
R2_1 = 1 - SS_res1/SS_tot1;

SS_tot2 = sum((R_exp2 - mean(R_exp2)).^2);
SS_res2 = sum(residual2.^2);
R2_2 = 1 - SS_res2/SS_tot2;

% Calculate root mean square error (RMSE)
RMSE1 = sqrt(mean(residual1.^2));
RMSE2 = sqrt(mean(residual2.^2));

% Calculate mean absolute error (MAE)
MAE1 = mean(abs(residual1));
MAE2 = mean(abs(residual2));

% Calculate signal-to-noise ratio (SNR)
SNR1 = 10 * log10(var(R_exp1) / var(residual1));
SNR2 = 10 * log10(var(R_exp2) / var(residual2));

fprintf('\nModel evaluation metrics:\n');
fprintf('=============================================\n');
fprintf('10° incidence angle:\n');
fprintf('  Coefficient of determination R²: %.6f\n', R2_1);
fprintf('  Root mean square error RMSE: %.6f\n', RMSE1);
fprintf('  Mean absolute error MAE: %.6f\n', MAE1);
fprintf('  Signal-to-noise ratio SNR: %.2f dB\n', SNR1);
fprintf('  Residual standard deviation: %.6f\n', std(residual1));
fprintf('\n15° incidence angle:\n');
fprintf('  Coefficient of determination R²: %.6f\n', R2_2);
fprintf('  Root mean square error RMSE: %.6f\n', RMSE2);
fprintf('  Mean absolute error MAE: %.6f\n', MAE2);
fprintf('  Signal-to-noise ratio SNR: %.2f dB\n', SNR2);
fprintf('  Residual standard deviation: %.6f\n', std(residual2));
fprintf('\nOverall fitting quality:\n');
if R2_1 > 0.8 && R2_2 > 0.8
    fprintf('  ✓ Good fitting quality (R² > 0.8)\n');
elseif R2_1 > 0.6 && R2_2 > 0.6
    fprintf('  ⚠ Moderate fitting quality (0.6 < R² < 0.8)\n');
else
    fprintf('  ✗ Poor fitting quality (R² < 0.6), need to check model or data\n');
end

%% 12. Refractive index analysis
% Calculate refractive index
n1_vals = A_opt + B_opt ./ (lambda1.^2);

% Calculate average refractive index and range
n1_avg = mean(n1_vals);
n1_min = min(n1_vals);
n1_max = max(n1_vals);

fprintf('\nRefractive index analysis (%.0f-%.0f cm⁻¹):\n', best_band(1), best_band(2));
fprintf('Average refractive index: %.4f\n', n1_avg);
fprintf('Refractive index range: %.4f - %.4f\n', n1_min, n1_max);
fprintf('Refractive index variation amplitude: %.4f\n', n1_max - n1_min);

% Plot refractive index vs. wavelength
figure('Position', [100, 100, 1000, 400]);

subplot(1, 2, 1);
plot(lambda1, n1_vals, 'b-', 'LineWidth', 2);
xlabel('Wavelength (μm)');
ylabel('Refractive Index n_1');
title(sprintf('Epitaxial Layer Refractive Index (A=%.4f, B=%.6f)', A_opt, B_opt));
grid on;
xlim([min(lambda1), max(lambda1)]);

subplot(1, 2, 2);
plot(wavenumber1, n1_vals, 'r-', 'LineWidth', 2);
xlabel('Wavenumber (cm^{-1})');
ylabel('Refractive Index n_1');
title('Epitaxial Layer Refractive Index vs. Wavenumber');
grid on;
xlim([min(wavenumber1), max(wavenumber1)]);

%% 13. Thickness uncertainty analysis
% Simple thickness uncertainty estimation
fprintf('\nThickness uncertainty analysis:\n');

% Uncertainty based on residuals
d_uncertainty_res = d_opt * sqrt(mean([residual1.^2; residual2.^2]));

% Uncertainty based on refractive index variation
% Thickness change Δd due to refractive index change Δn: Δd ≈ -d * Δn/n
n_variation = std(n1_vals);
d_uncertainty_n = d_opt * n_variation / n1_avg;

% Combined uncertainty
d_uncertainty_total = sqrt(d_uncertainty_res^2 + d_uncertainty_n^2);

fprintf('Uncertainty based on residuals: ±%.4f μm\n', d_uncertainty_res);
fprintf('Uncertainty based on refractive index variation: ±%.4f μm\n', d_uncertainty_n);
fprintf('Combined uncertainty: ±%.4f μm\n', d_uncertainty_total);
fprintf('Relative uncertainty: %.2f%%\n', 100 * d_uncertainty_total / d_opt);

%% 14. Save results
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
results.preprocessing_methods = {'AsLS Baseline Correction', 'Hampel Filtering', 'Savitzky-Golay Smoothing'};

save('fitting_results_preprocessed.mat', 'results');

% Export key results to text file
fid = fopen('fitting_summary_preprocessed.txt', 'w');
fprintf(fid, 'Infrared Interferometric Thickness Measurement Model Fitting Results (Preprocessed Version)\n');
fprintf(fid, '===========================================\n\n');
fprintf(fid, 'Data processing flow:\n');
fprintf(fid, '1. Filter wavenumber range: 1000-4000 cm⁻¹\n');
fprintf(fid, '2. AsLS baseline correction (lambda=%.0e, p=%.3f, order=%d)\n', lambda_asls, p_asls, order_asls);
fprintf(fid, '3. Hampel filtering (window=%d, n_sigma=%d)\n', window_size, n_sigma);
fprintf(fid, '4. Savitzky-Golay smoothing (window=%d, order=%d)\n\n', sg_window, sg_order);
fprintf(fid, 'Best band selection: %.0f - %.0f cm⁻¹\n\n', best_band(1), best_band(2));
fprintf(fid, 'Fitted thickness: %.4f ± %.4f μm\n', d_opt, d_uncertainty_total);
fprintf(fid, 'Cauchy parameter A: %.6f\n', A_opt);
fprintf(fid, 'Cauchy parameter B: %.6f μm²\n', B_opt);
fprintf(fid, '\nModel evaluation:\n');
fprintf(fid, '10° incidence angle R²: %.6f, RMSE: %.6f\n', R2_1, RMSE1);
fprintf(fid, '15° incidence angle R²: %.6f, RMSE: %.6f\n', R2_2, RMSE2);
fprintf(fid, '\nRefractive index analysis:\n');
fprintf(fid, 'Average refractive index: %.4f\n', n1_avg);
fprintf(fid, 'Refractive index range: %.4f - %.4f\n', n1_min, n1_max);
fclose(fid);

fprintf('\nResults saved:\n');
fprintf('  Detailed results: fitting_results_preprocessed.mat\n');
fprintf('  Text summary: fitting_summary_preprocessed.txt\n');
fprintf('\nAnalysis complete!\n');

%% Auxiliary function definitions

% Sliding window FFT analysis function
function [center_positions, main_freqs, snr_vals] = sliding_window_fft_analysis(...
    wavenumber, signal, window_width, step_size, angle_deg)
    
    % Ensure wavenumber is monotonically increasing
    [wavenumber, sort_idx] = sort(wavenumber);
    signal = signal(sort_idx);
    
    % Calculate number of windows and center positions
    wavenumber_min = min(wavenumber);
    wavenumber_max = max(wavenumber);
    
    % Create window center positions
    center_positions = (wavenumber_min + window_width/2):step_size:(wavenumber_max - window_width/2);
    
    main_freqs = zeros(size(center_positions));
    snr_vals = zeros(size(center_positions));
    
    % Perform FFT analysis for each window
    for i = 1:length(center_positions)
        center = center_positions(i);
        window_start = center - window_width/2;
        window_end = center + window_width/2;
        
        % Extract data within window
        idx = wavenumber >= window_start & wavenumber <= window_end;
        
        if sum(idx) < 10  % Too few data points in window
            main_freqs(i) = NaN;
            snr_vals(i) = NaN;
            continue;
        end
        
        wavenumber_window = wavenumber(idx);
        signal_window = signal(idx);
        
        % Apply Hann window
        L = length(signal_window);
        hann_window = hann(L);
        signal_windowed = signal_window .* hann_window;
        
        % Perform FFT
        Y = fft(signal_windowed);
        P2 = abs(Y/L);
        P1 = P2(1:floor(L/2)+1);
        P1(2:end-1) = 2*P1(2:end-1);
        
        % Calculate frequency axis
        Fs = 1 / (wavenumber_window(2) - wavenumber_window(1));
        f = Fs * (0:floor(L/2)) / L;
        
        % Find main frequency (ignore near-zero frequencies)
        search_range = 10:min(50, length(P1));
        [max_val, idx_max] = max(P1(search_range));
        f_main = f(search_range(idx_max));
        
        % Calculate SNR
        % Main peak amplitude
        A_peak = max_val;
        
        % Estimate noise level (using bands near main peak)
        noise_band_width = 5;  % Number of frequency points
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
    
    % Remove NaN values
    valid_idx = ~isnan(main_freqs) & ~isnan(snr_vals);
    center_positions = center_positions(valid_idx);
    main_freqs = main_freqs(valid_idx);
    snr_vals = snr_vals(valid_idx);
    
    fprintf('Angle %d°: Number of analysis windows = %d\n', angle_deg, length(center_positions));
end

% Automatic band selection function
function [selected_bands, valid_center_positions] = auto_band_selection(...
    center_positions1, center_positions2, ...
    main_freqs1, main_freqs2, ...
    snr_vals1, snr_vals2, ...
    min_snr, max_freq_diff, min_cycles, safety_margin, window_width)
    
    % Find common center positions for both angles
    common_centers = intersect(round(center_positions1, 1), round(center_positions2, 1));
    
    selected_bands = [];
    valid_center_positions = [];
    
    if isempty(common_centers)
        fprintf('Warning: No common center positions for both angles\n');
        return;
    end
    
    % Check conditions at each common center position
    valid_flags = false(size(common_centers));
    
    for i = 1:length(common_centers)
        center = common_centers(i);
        
        % Find closest center position indices
        [~, idx1] = min(abs(center_positions1 - center));
        [~, idx2] = min(abs(center_positions2 - center));
        
        % Get corresponding values
        snr1 = snr_vals1(idx1);
        snr2 = snr_vals2(idx2);
        freq1 = main_freqs1(idx1);
        freq2 = main_freqs2(idx2);
        
        % Check conditions
        condition1 = (snr1 > min_snr) && (snr2 > min_snr);  % SNR condition
        condition2 = abs(freq1 - freq2) / mean([freq1, freq2]) < max_freq_diff;  % Frequency consistency condition
        
        valid_flags(i) = condition1 && condition2;
        
        if valid_flags(i)
            valid_center_positions = [valid_center_positions; center];
        end
    end
    
    % If no valid positions, return empty
    if isempty(valid_center_positions)
        fprintf('Warning: No windows satisfy selection conditions\n');
        return;
    end
    
    % Merge adjacent valid positions to form continuous intervals
    valid_center_positions = sort(valid_center_positions);
    gaps = diff(valid_center_positions);
    gap_threshold = 10 * 3;  % Maximum allowed gap
    
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
    
    % Adjust band boundaries
    for i = 1:size(bands, 1)
        bands(i, 1) = bands(i, 1) - window_width/2;
        bands(i, 2) = bands(i, 2) + window_width/2;
    end
    
    selected_bands = bands;
    
    fprintf('Found %d candidate bands\n', size(selected_bands, 1));
    for i = 1:size(selected_bands, 1)
        fprintf('  Band %d: %.1f - %.1f cm⁻¹ (width: %.1f cm⁻¹)\n', ...
            i, selected_bands(i, 1), selected_bands(i, 2), ...
            selected_bands(i, 2) - selected_bands(i, 1));
    end
end