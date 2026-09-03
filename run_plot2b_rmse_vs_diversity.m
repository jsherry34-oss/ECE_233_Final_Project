close all; clc;

% add paths
addpath('functions');
addpath('utils');

fprintf('Generating Plot 2b ...\n');

% initialize params
params = set_system_parameters();

% simulation params
R_values = [1, 2, 4, 8, 16];
SNR_values_dB = [-10, 0, 10];

%% Monte Carlo simulation
RMSE_results = zeros(length(SNR_values_dB), length(R_values));

for snr_idx = 1:length(SNR_values_dB)
    SNR_dB = SNR_values_dB(snr_idx);

    fprintf('\n--- SNR = %+3d dB ---\n', SNR_dB);

    for r_idx = 1:length(R_values)
        R = R_values(r_idx);

        fprintf('  R = %2d: ', R);

        % design TTD codebook for this R
        [tau, phi] = design_ttd_codebook(params, R);

        % compute subcarrier sets
        [M_sets, M_all] = compute_subcarrier_sets(params, R);

        % compute TTD AWVs for training subcarriers
        w_matrix = compute_ttd_awv(M_all, tau, phi, params);

        % build dictionary
        [B, angle_grid] = build_dictionary(params, R, tau, phi);

        % estimation errors
        errors = zeros(params.N_trials, 1);

        % monte carlo trials
        for trial = 1:params.N_trials
            % generate random channel with random AoA/AoD
            [H_subbands, theta_AoA, theta_AoD] = generate_channel(params, [-pi/3, pi/3]);

            % BS precoder
            v = array_response(theta_AoD(1), params.NT);

            % generate received signal
            Y = generate_received_signal(H_subbands, w_matrix, v, M_all, params, SNR_dB);

            % estimate AoA
            [theta_hat, ~] = estimate_angle(Y, M_sets, B, angle_grid, R, M_all);

            % compute error
            error_rad = theta_hat - theta_AoA(1);
            errors(trial) = error_rad;
        end

        % RMSE in degrees
        RMSE_results(snr_idx, r_idx) = sqrt(mean(errors.^2)) * 180/pi;

        fprintf('RMSE = %.3f deg\n', RMSE_results(snr_idx, r_idx));
    end
end

%% plot results
figure('Position', [100, 100, 800, 600]);

% Define colors and line styles for each SNR
colors = [0.8, 0.2, 0.2;    % Red for -20 dB
          0.9, 0.5, 0.1;    % Orange for -10 dB
          0.2, 0.6, 0.2;    % Green for 0 dB
          0.2, 0.4, 0.8;    % Blue for 10 dB
          0.5, 0.2, 0.7];   % Purple for 20 dB
line_styles = {'-o', '-s', '-^', '-d', '-v'};

hold on;
for snr_idx = 1:length(SNR_values_dB)
    plot(log2(R_values), RMSE_results(snr_idx, :), line_styles{snr_idx}, ...
         'Color', colors(snr_idx, :), ...
         'LineWidth', 2, ...
         'MarkerSize', 8, ...
         'MarkerFaceColor', colors(snr_idx, :), ...
         'DisplayName', sprintf('SNR = %+3d dB', SNR_values_dB(snr_idx)));
end

% Add resolution floor line (theoretical limit)
resolution_floor = sqrt((pi/params.Q)^2/12) * 180/pi;
plot([log2(min(R_values)), log2(max(R_values))], ...
     [resolution_floor, resolution_floor], ...
     '--k', 'LineWidth', 1.5, ...
     'DisplayName', sprintf('Resolution Floor (%.3f°)', resolution_floor));

hold off;

% formatting
set(gca, 'YScale', 'log');
xlabel('Diversity Order R', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('RMSE (degrees)', 'FontSize', 12, 'FontWeight', 'bold');
title('AoA Estimation RMSE vs. Diversity Order', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 10);
grid on;
set(gca, 'FontSize', 11);

xticks(log2(R_values));
xticklabels(arrayfun(@num2str, R_values, 'UniformOutput', false));

% save figure
if ~exist('results', 'dir')
    mkdir('results');
end

saveas(gcf, 'results/plot2b_rmse_vs_diversity.fig');
saveas(gcf, 'results/plot2b_rmse_vs_diversity.png');

%% print summary
fprintf('\n=== Summary Statistics ===\n');
fprintf('Resolution floor: %.3f degrees\n', resolution_floor);
fprintf('\nRMSE at SNR = 20 dB:\n');
for r_idx = 1:length(R_values)
    fprintf('  R = %2d: %.3f deg\n', R_values(r_idx), RMSE_results(end, r_idx));
end