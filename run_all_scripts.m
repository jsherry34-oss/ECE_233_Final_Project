clear; close all; clc;

fprintf('ECE 233 Project 4: TTD Beam Training\n');

% add paths
addpath('scripts');

% create results directory
if ~exist('results', 'dir')
    mkdir('results');
end

% set random seed
rng(42);

%% Plot 1: Beam Patterns
run('run_plot1_beam_patterns.m');

%% Plot 2: RMSE vs SNR 
run('run_plot2_rmse_vs_snr.m');

%% Plot 3: RMSE vs Gain Error 
run('run_plot3_rmse_vs_gain_error.m');

%% Plot 4: RMSE vs Phase Error
run('run_plot4_rmse_vs_phase_error.m');

%% Plot 5: RMSE vs Delay Error
run('run_plot5_rmse_vs_delay_error.m');