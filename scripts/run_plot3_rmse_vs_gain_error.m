close all; clc;

% add paths
addpath('helper_functions');

fprintf('Generating Plot 3 ...\n');

% initialize params
params = set_system_parameters();

% simulation params
R = 4;
SNR_dB = 0;
sigma_A_range = 0:0.5:4.5;

sigma_P = 0;
sigma_T = 0;

%% setup
% design TTD codebook
[tau, phi] = design_ttd_codebook(params, R);

% compute subcarrier sets
[M_sets, M_all] = compute_subcarrier_sets(params, R);

% build dictionary
[B, angle_grid] = build_dictionary(params, R, tau, phi);

%% monte carlo simulation
RMSE_results = zeros(size(sigma_A_range));

fprintf('\n--- Fixed: SNR = 0 dB, R = 4 ---\n\n');

for sigma_idx = 1:length(sigma_A_range)
    sigma_A = sigma_A_range(sigma_idx);

    fprintf('σ_A = %.1f dB: ', sigma_A);

    % estimation errors
    errors = zeros(params.N_trials, 1);

    % monte carlo trials
    for trial = 1:params.N_trials
        % generate random channel
        [H_subbands, theta_AoA, theta_AoD] = generate_channel(params, [-pi/3, pi/3]);

        % BS precoder
        v = array_response(theta_AoD(1), params.NT);

        % apply impairments
        if sigma_A > 0
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

    % compute RMSE
    RMSE_deg = sqrt(mean(errors.^2)) * 180/pi;
    RMSE_results(sigma_idx) = RMSE_deg;

    fprintf('RMSE = %6.3f deg\n', RMSE_deg);
end

%% plot results
figure('Position', [100, 100, 900, 600]);

% plot RMSE vs gain error
semilogy(sigma_A_range, RMSE_results, 'r-*', ...
         'LineWidth', 2, 'MarkerSize', 10, 'MarkerFaceColor', 'r');

% formatting
grid on;
xlabel('Standard Deviation of Gain Error σ_A (dB)', 'FontSize', 14);
ylabel('RMSE (degrees)', 'FontSize', 14);
title('RMSE of Angle Estimation vs. Gain Error (SNR = 0 dB, R = 4)', 'FontSize', 16);
xlim([sigma_A_range(1), sigma_A_range(end)]);
ylim([0.1, 30]);

set(gca, 'FontSize', 12);
box on;

% save figure
saveas(gcf, 'results/plot3_rmse_vs_gain_error.fig');
saveas(gcf, 'results/plot3_rmse_vs_gain_error.png');

fprintf('\nPlot 3 saved to results/\n');
fprintf('  - plot3_rmse_vs_gain_error.fig\n');
fprintf('  - plot3_rmse_vs_gain_error.png\n\n');

%% print summary
fprintf('σ_A = 0.0 dB: RMSE = %6.3f deg\n', RMSE_results(1));
fprintf('σ_A = 2.0 dB: RMSE = %6.3f deg\n', RMSE_results(sigma_A_range == 2.0));
fprintf('σ_A = 2.5 dB: RMSE = %6.3f deg\n', RMSE_results(sigma_A_range == 2.5));
fprintf('σ_A = 4.5 dB: RMSE = %6.3f deg\n', RMSE_results(end));