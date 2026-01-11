%% Infrared Interferometric Thickness Measurement Model - Two-beam Interference Thickness Inversion
clear; clc; close all;

%% 1. Read Data
data1 = readmatrix('附件1.xlsx');
data2 = readmatrix('附件2.xlsx');

% Extract data
wavenumber1 = data1(:, 1);  % Wavenumber (cm^-1)
R_exp1 = data1(:, 2)/100;   % Reflectance, convert to decimal

wavenumber2 = data2(:, 1);  % Wavenumber (cm^-1)
R_exp2 = data2(:, 2)/100;   % Reflectance, convert to decimal

% Parameter settings
n0 = 1;          % Air refractive index
n2 = 2.65;       % SiC substrate refractive index
theta1_deg = 10; % Incidence angle 1 (degrees)
theta2_deg = 15; % Incidence angle 2 (degrees)
theta1 = deg2rad(theta1_deg);
theta2 = deg2rad(theta2_deg);

% Convert wavenumber to wavelength (μm)
% λ (μm) = 10^4 / wavenumber (cm^-1)
lambda1 = 1e4 ./ wavenumber1;  % Wavelength (μm)
lambda2 = 1e4 ./ wavenumber2;  % Wavelength (μm)

%% 2. Preliminary Thickness Estimation via FFT Analysis
% Use first incidence angle data for estimation
figure('Position', [100, 100, 1200, 400]);

% Plot raw spectrum
subplot(1, 3, 1);
plot(wavenumber1, R_exp1, 'b-', 'LineWidth', 1.5);
xlabel('Wavenumber (cm^{-1})');
ylabel('Reflectance');
title('Raw Interference Spectrum (10°)');
grid on;

% FFT analysis
L = length(wavenumber1);
Fs = 1 / (wavenumber1(2) - wavenumber1(1));  % Sampling frequency (cm)

% Perform FFT
Y = fft(R_exp1 - mean(R_exp1));  % Remove DC component
P2 = abs(Y/L);
P1 = P2(1:floor(L/2)+1);
P1(2:end-1) = 2*P1(2:end-1);
f = Fs*(0:floor(L/2))/L;  % Frequency axis (cm^-1)

% Plot spectrum
subplot(1, 3, 2);
plot(f, P1, 'r-', 'LineWidth', 1.5);
xlabel('Frequency (cm^{-1})');
ylabel('Magnitude');
title('Spectrum Analysis');
grid on;
xlim([0, 0.1]);

% Find main frequency (ignore zero frequency)
[~, idx] = max(P1(2:end));
f_main = f(idx+1);  % Main frequency (cm^-1)
delta_nu = 1/f_main;  % Fringe period (cm)

% Preliminary thickness estimation
% Using approximate formula: d ≈ 1/(2Δν n1_avg)
% Assume average refractive index n1_avg = 2.6 (typical value)
n1_avg = 2.6;
d0 = 1e4 / (2 * n1_avg * delta_nu);  % Convert to μm

fprintf('Preliminary Estimation Results:\n');
fprintf('Main frequency: %.4f cm^{-1}\n', f_main);
fprintf('Fringe period: %.2f cm^{-1}\n', delta_nu);
fprintf('Preliminary thickness estimate: %.2f μm\n\n', d0);

%% 3. Define Theoretical Reflectance Model
% Cauchy refractive index model: n1(λ) = A + B/λ^2 (λ in μm)
% Reflectance calculation function
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
    r01 = (n0*cos(theta) - n1.*cos(theta1)) ./ ...
          (n0*cos(theta) + n1.*cos(theta1));
    r12 = (n1.*cos(theta1) - n2*cos(theta2)) ./ ...
          (n1.*cos(theta1) + n2*cos(theta2));
    
    % Calculate phase difference
    delta = (4 * pi * n1 .* d .* cos(theta1)) ./ lambda;
    
    % Calculate total reflectance
    R = abs(r01 + r12 .* exp(1i * delta)).^2;
end

%% 4. Define Objective Function (for Least Squares Fitting)
function residuals = objective_func(params, lambda1, R_exp1, theta1, ...
                                    lambda2, R_exp2, theta2, n0, n2)
    d = params(1);  % Thickness (μm)
    A = params(2);  % Cauchy parameter A
    B = params(3);  % Cauchy parameter B (μm^2)
    
    % Calculate theoretical reflectance
    R_theory1 = calc_reflectivity(lambda1, theta1, d, A, B, n0, n2);
    R_theory2 = calc_reflectivity(lambda2, theta2, d, A, B, n0, n2);
    
    % Calculate residuals (combined for both datasets)
    residuals = [R_exp1 - R_theory1; R_exp2 - R_theory2];
end

%% 5. Parameter Fitting (Nonlinear Least Squares)
% Initial parameter guesses
A0 = 2.6;    % Typical refractive index value
B0 = 0.01;   % Typical dispersion coefficient (μm^2)
initial_params = [d0, A0, B0];

% Set fitting options
options = optimoptions('lsqnonlin', 'Display', 'iter', ...
                       'MaxFunctionEvaluations', 5000, ...
                       'MaxIterations', 1000, ...
                       'FunctionTolerance', 1e-8, ...
                       'StepTolerance', 1e-8);

% Define anonymous function for lsqnonlin
obj_func = @(params) objective_func(params, lambda1, R_exp1, theta1, ...
                                     lambda2, R_exp2, theta2, n0, n2);

% Perform nonlinear least squares fitting
fprintf('Starting parameter fitting...\n');
tic;
[params_opt, resnorm, residual, exitflag, output] = ...
    lsqnonlin(obj_func, initial_params, [], [], options);
fitting_time = toc;

% Extract optimized parameters
d_opt = params_opt(1);
A_opt = params_opt(2);
B_opt = params_opt(3);

fprintf('\nFitting Results:\n');
fprintf('Optimized thickness: %.4f μm\n', d_opt);
fprintf('Cauchy parameter A: %.6f\n', A_opt);
fprintf('Cauchy parameter B: %.6f μm²\n', B_opt);
fprintf('Residual sum of squares: %.6f\n', resnorm);
fprintf('Fitting iterations: %d\n', output.iterations);
fprintf('Function evaluations: %d\n', output.funcCount);
fprintf('Exit flag: %d\n', exitflag);
fprintf('Fitting time: %.2f seconds\n', fitting_time);

%% 6. Calculate Fitted Reflectance and Plot Comparison
% Calculate fitted reflectance
R_fit1 = calc_reflectivity(lambda1, theta1, d_opt, A_opt, B_opt, n0, n2);
R_fit2 = calc_reflectivity(lambda2, theta2, d_opt, A_opt, B_opt, n0, n2);

% Plot fitting results comparison
figure('Position', [100, 100, 1200, 500]);

% 10° incidence angle
subplot(1, 2, 1);
plot(wavenumber1, R_exp1, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Experimental Data');
hold on;
plot(wavenumber1, R_fit1, 'r--', 'LineWidth', 2, 'DisplayName', 'Fitted Result');
xlabel('Wavenumber (cm^{-1})');
ylabel('Reflectance');
title(sprintf('10° Incidence Angle - Fitting Comparison (d=%.2f μm)', d_opt));
legend('Location', 'best');
grid on;
xlim([min(wavenumber1), max(wavenumber1)]);

% 15° incidence angle
subplot(1, 2, 2);
plot(wavenumber2, R_exp2, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Experimental Data');
hold on;
plot(wavenumber2, R_fit2, 'r--', 'LineWidth', 2, 'DisplayName', 'Fitted Result');
xlabel('Wavenumber (cm^{-1})');
ylabel('Reflectance');
title(sprintf('15° Incidence Angle - Fitting Comparison (d=%.2f μm)', d_opt));
legend('Location', 'best');
grid on;
xlim([min(wavenumber2), max(wavenumber2)]);

%% 7. Plot Residuals
figure('Position', [100, 100, 1200, 400]);

subplot(1, 2, 1);
residual1 = R_exp1 - R_fit1;
plot(wavenumber1, residual1, 'k-', 'LineWidth', 1);
hold on;
plot(wavenumber1, zeros(size(wavenumber1)), 'r--', 'LineWidth', 1);
xlabel('Wavenumber (cm^{-1})');
ylabel('Residual');
title('10° Incidence Angle - Fitting Residuals');
grid on;
xlim([min(wavenumber1), max(wavenumber1)]);
ylim([-0.1, 0.1]);

subplot(1, 2, 2);
residual2 = R_exp2 - R_fit2;
plot(wavenumber2, residual2, 'k-', 'LineWidth', 1);
hold on;
plot(wavenumber2, zeros(size(wavenumber2)), 'r--', 'LineWidth', 1);
xlabel('Wavenumber (cm^{-1})');
ylabel('Residual');
title('15° Incidence Angle - Fitting Residuals');
grid on;
xlim([min(wavenumber2), max(wavenumber2)]);
ylim([-0.1, 0.1]);

%% 8. Calculate and Display Refractive Index Variation with Wavelength
figure('Position', [100, 100, 800, 400]);

% Calculate refractive index
n1_vals = A_opt + B_opt ./ (lambda1.^2);

subplot(1, 2, 1);
plot(lambda1, n1_vals, 'b-', 'LineWidth', 2);
xlabel('Wavelength (μm)');
ylabel('Refractive Index n_1');
title('Epilayer Refractive Index vs Wavelength');
grid on;
xlim([min(lambda1), max(lambda1)]);

subplot(1, 2, 2);
plot(wavenumber1, n1_vals, 'b-', 'LineWidth', 2);
xlabel('Wavenumber (cm^{-1})');
ylabel('Refractive Index n_1');
title('Epilayer Refractive Index vs Wavenumber');
grid on;
xlim([min(wavenumber1), max(wavenumber1)]);

%% 9. Model Validation and Consistency Analysis
% Calculate thickness differences for both incidence angles (using same parameters)
fprintf('\nModel Consistency Analysis:\n');
fprintf('Using same parameters to fit both datasets, thickness: %.4f μm\n', d_opt);

% Calculate coefficient of determination R²
SS_tot1 = sum((R_exp1 - mean(R_exp1)).^2);
SS_res1 = sum(residual1.^2);
R2_1 = 1 - SS_res1/SS_tot1;

SS_tot2 = sum((R_exp2 - mean(R_exp2)).^2);
SS_res2 = sum(residual2.^2);
R2_2 = 1 - SS_res2/SS_tot2;

fprintf('10° incidence angle R²: %.6f\n', R2_1);
fprintf('15° incidence angle R²: %.6f\n', R2_2);

%% 10. Save Results
results = struct();
results.thickness = d_opt;
results.A = A_opt;
results.B = B_opt;
results.R2_10deg = R2_1;
results.R2_15deg = R2_2;
results.resnorm = resnorm;
results.initial_guess = [d0, A0, B0];

save('fitting_results.mat', 'results');
fprintf('\nResults saved to fitting_results.mat\n');