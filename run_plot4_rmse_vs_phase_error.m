close all; clc;

% add paths
addpath('functions');
addpath('utils');

fprintf('Generating Plot 4 ...\n');

% initialize params
params = set_system_parameters();

% simulation params
R = 4;
SNR_dB = 0;
sigma_P_range_deg = 0:5:50;

% convert to radians
sigma_P_range = sigma_P_range_deg * pi/180;

% no other impairments
sigma_A = 0;
sigma_T = 0;

%% setup
% design TTD codebook
[tau, phi] = design_ttd_codebook(params, R);

% compute subcarrier sets
[M_sets, M_all] = compute_subcarrier_sets(params, R);

% build dictionary
[B, angle_grid] = build_dictionary(params, R, tau, phi);

%% monte carlo simulation
RMSE_results = zeros(size(sigma_P_range));

fprintf('\n--- Fixed: SNR = 0 dB, R = 4 ---\n\n');

for sigma_idx = 1:length(sigma_P_range)
    sigma_P = sigma_P_range(sigma_idx);
    sigma_P_deg = sigma_P_range_deg(sigma_idx);

    fprintf('σ_P = %3.0f deg: ', sigma_P_deg);

    % estimation errors
    errors = zeros(params.N_trials, 1);

    % monte carlo trials
    for trial = 1:params.N_trials
        % generate random channel
        [H_subbands, theta_AoA, theta_AoD] = generate_channel(params, [-pi/3, pi/3]);

        % BS precoder
        v = array_response(theta_AoD(1), params.NT);

        % apply hardware impairments
        if sigma_P > 0
            w_matrix_impaired = add_hardware_impairments([], M_all, tau, phi, params, ...
                                                         sigma_A, sigma_P, sigma_T);
        else
            w_matrix_impaired = compute_ttd_awv(M_all, tau, phi, params);
        end

        % generate received signal
        Y = generate_received_signal(H_subbands, w_matrix_impaired, v, M_all, params, SNR_dB);

        % estimate angle
        [theta_hat, ~] = estimate_angle(Y, M_sets, B, angle_grid, R, M_all);

        % compute error
        error_rad = theta_hat - theta_AoA(1);
        errors(trial) = error_rad;
    end

    % RMSE in degrees
    RMSE_deg = sqrt(mean(errors.^2)) * 180/pi;
    RMSE_results(sigma_idx) = RMSE_deg;

    fprintf('RMSE = %6.3f deg\n', RMSE_deg);
end

%% plot results
figure('Position', [100, 100, 900, 600]);

% RMSE vs phase error
semilogy(sigma_P_range_deg, RMSE_results, 'r-d', ...
         'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'r');

% formatting
grid on;
xlabel('Standard Deviation of Phase Error σ_P (degrees)', 'FontSize', 14);
ylabel('RMSE (degrees)', 'FontSize', 14);
title('RMSE of Angle Estimation vs. Phase Error (SNR = 0 dB, R = 4)', 'FontSize', 16);
xlim([sigma_P_range_deg(1), sigma_P_range_deg(end)]);
ylim([0.1, 20]);

set(gca, 'FontSize', 12);
box on;

% add system parameters text box
annotation('textbox', [0.15, 0.80, 0.25, 0.12], ...
           'String', sprintf('SNR = 0 dB\nR = 4\nσ_A = 0 dB\nσ_T = 0 ps'), ...
           'FontSize', 11, ...
           'BackgroundColor', 'white', ...
           'EdgeColor', 'black');

% save figure
saveas(gcf, 'results/plot4_rmse_vs_phase_error.fig');
saveas(gcf, 'results/plot4_rmse_vs_phase_error.png');

fprintf('\nPlot 4 saved to results/\n');
fprintf('  - plot4_rmse_vs_phase_error.fig\n');
fprintf('  - plot4_rmse_vs_phase_error.png\n\n');

%% print summary
fprintf('σ_P =  0 deg: RMSE = %6.3f deg\n', RMSE_results(1));
fprintf('σ_P = 25 deg: RMSE = %6.3f deg\n', RMSE_results(sigma_P_range_deg == 25));
fprintf('σ_P = 30 deg: RMSE = %6.3f deg\n', RMSE_results(sigma_P_range_deg == 30));
fprintf('σ_P = 50 deg: RMSE = %6.3f deg\n', RMSE_results(end));