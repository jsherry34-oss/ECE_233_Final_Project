close all; clc;

% add paths
addpath('helper_functions');

fprintf('Generating Plot 2 ...\n');

% initialize params
params = set_system_parameters();

% simulation params
R_values = [1, 2, 4];
SNR_range = -20:5:20;

%% monte carlo simulation

RMSE_results = zeros(length(R_values), length(SNR_range));

for r_idx = 1:length(R_values)
    R = R_values(r_idx);

    fprintf('\n--- Diversity Factor R = %d ---\n', R);

    % design TTD codebook for this R
    [tau, phi] = design_ttd_codebook(params, R);

    % compute subcarrier sets
    [M_sets, M_all] = compute_subcarrier_sets(params, R);

    % compute TTD AWVs for training subcarriers
    w_matrix = compute_ttd_awv(M_all, tau, phi, params);

    % build dictionary
    [B, angle_grid] = build_dictionary(params, R, tau, phi);

    for snr_idx = 1:length(SNR_range)
        SNR_dB = SNR_range(snr_idx);

        % estimation errors
        errors = zeros(params.N_trials, 1);

        if mod(snr_idx, 2) == 1
            fprintf('  SNR = %+3d dB: ', SNR_dB);
        end

        % monte Carlo trials
        for trial = 1:params.N_trials
            % generate random channel with random AoA/AoD
            [H_subbands, theta_AoA, theta_AoD] = generate_channel(params, [-pi/3, pi/3]);

            % BS precoder
            v = array_response(theta_AoD(1), params.NT);

            % generate received signal
            Y = generate_received_signal(H_subbands, w_matrix, v, M_all, params, SNR_dB);

            % estimate angle
            [theta_hat, ~] = estimate_angle(Y, M_sets, B, angle_grid, R, M_all);

            % compute error
            error_rad = theta_hat - theta_AoA(1);
            errors(trial) = error_rad;
        end

        % compute RMSE
        RMSE_deg = sqrt(mean(errors.^2)) * 180/pi;
        RMSE_results(r_idx, snr_idx) = RMSE_deg;

        if mod(snr_idx, 2) == 1
            fprintf('RMSE = %6.3f deg\n', RMSE_deg);
        end
    end
end

%% plot results
figure('Position', [100, 100, 900, 600]);

colors = {'b-o', 'r-s', 'g-d'};
markers = {'o', 's', 'd'};

for r_idx = 1:length(R_values)
    semilogy(SNR_range, RMSE_results(r_idx, :), colors{r_idx}, ...
             'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', colors{r_idx}(1));
    hold on;
end

% formatting
grid on;
xlabel('SNR (dB)', 'FontSize', 14);
ylabel('RMSE (degrees)', 'FontSize', 14);
title('RMSE of Angle Estimation vs. SNR (No Hardware Impairments)', 'FontSize', 16);
legend('R = 1', 'R = 2', 'R = 4', 'Location', 'southwest', 'FontSize', 12);
xlim([SNR_range(1), SNR_range(end)]);
ylim([0.01, 50]);

set(gca, 'FontSize', 12);
box on;

% add resolution floor line
resolution_floor = sqrt((pi/params.Q)^2 / 12) * 180/pi;
yline(resolution_floor, 'k--', 'LineWidth', 1.5, ...
      'Label', sprintf('Resolution Floor (%.3f°)', resolution_floor), ...
      'LabelHorizontalAlignment', 'left');

% save figure
saveas(gcf, 'results/plot2_rmse_vs_snr.fig');
saveas(gcf, 'results/plot2_rmse_vs_snr.png');

fprintf('\nPlot 2 saved to results/\n');
fprintf('  - plot2_rmse_vs_snr.fig\n');
fprintf('  - plot2_rmse_vs_snr.png\n\n');

%% print summary
fprintf('\n--- Summary ---\n');
for r_idx = 1:length(R_values)
    fprintf('R = %d:\n', R_values(r_idx));
    fprintf('  SNR = -20 dB: RMSE = %6.3f deg\n', RMSE_results(r_idx, 1));
    fprintf('  SNR =   0 dB: RMSE = %6.3f deg\n', RMSE_results(r_idx, 5));
    fprintf('  SNR = +20 dB: RMSE = %6.3f deg\n', RMSE_results(r_idx, end));
end
fprintf('Resolution floor: %.4f deg\n', resolution_floor);