function params = set_system_parameters()
    % RF parameters 
    params.fc = 60e9;           
    params.BW = 2e9;            
    params.Mtot = 4096;

    % array config 
    params.NT = 128;           
    params.NR = 16;             
    params.lambda = 3e8/params.fc; 
    params.d = params.lambda/2;

    % beam training parameters 
    params.D = 32;
    params.Q = 1024;

    % channel parameters 
    params.L = 3;              
    params.power_ratio_dB = 10; 
    params.Kc = 20;             

    % ray-based fading
    params.rays_per_cluster = 20;
    params.delay_spread = 10e-9;

    % monte carlo sim 
    params.N_trials = 1000;

    % ADC resolution 
    params.ADC_bits = 5;

    % Angular Grid 
    params.angle_range = [-pi/2, pi/2];
    params.angle_grid = linspace(-pi/2, pi/2, params.Q);

    % subcarrier spacing
    params.delta_f = params.BW / (params.Mtot - 1);

    % subcarrier frequencies
    params.f_subcarriers = params.fc - params.BW/2 + ...
                          (0:params.Mtot-1) * params.delta_f;

    % power allocation for clusters
    power_ratio_linear = 10^(params.power_ratio_dB/10);
    total_power = 1;

    params.sigma_squared = zeros(1, params.L);
    params.sigma_squared(1) = total_power / (1 + 2/power_ratio_linear);
    params.sigma_squared(2) = params.sigma_squared(1) / power_ratio_linear;
    params.sigma_squared(3) = params.sigma_squared(1) / power_ratio_linear;
end