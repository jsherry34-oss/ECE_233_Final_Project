close all; clc;

% add paths
addpath('functions');
addpath('utils');

fprintf('Generating Plot 1 ...\n');

% initialize params
params = set_system_parameters();

R = 4;

% design TTD codebook
[tau, phi] = design_ttd_codebook(params, R);

% build dictionary
[B, angle_grid] = build_dictionary(params, R, tau, phi);

% convert angle grid to degrees for plotting
angle_grid_deg = angle_grid * 180/pi;

%% plot beam patterns
figure('Position', [100, 100, 1000, 600]);

for d = 1:params.D
    plot(angle_grid_deg, B(d, :), 'LineWidth', 1.5);
    hold on;
end

% formatting
grid on;
xlabel('Angle (degrees)', 'FontSize', 14);
ylabel('Beam Gain |f_d^H a_R(\theta)|^2', 'FontSize', 14);
title('Beam Patterns of TTD Codebook (D = 32 beams)', 'FontSize', 16);
xlim([-90, 90]);
ylim([0, max(B(:)) * 1.1]);

% add legend for a few beams
legend_entries = {};
for d = 1:4:params.D
    legend_entries{end+1} = sprintf('Beam %d', d);
end

set(gca, 'FontSize', 12);
box on;

% add annotation
annotation('textbox', [0.15, 0.85, 0.3, 0.1], ...
           'String', sprintf('NR = %d antennas\nD = %d directions\nR = %d diversity', ...
                            params.NR, params.D, R), ...
           'FontSize', 11, ...
           'BackgroundColor', 'white', ...
           'EdgeColor', 'black');

% save figure
saveas(gcf, 'results/plot1_beam_patterns.fig');
saveas(gcf, 'results/plot1_beam_patterns.png');

fprintf('\nPlot 1 saved to results/\n');
fprintf('  - plot1_beam_patterns.fig\n');
fprintf('  - plot1_beam_patterns.png\n\n');