function [H_subbands, theta_AoA, theta_AoD, sigma_squared] = generate_channel(params, aoa_range)
% Reference: [R-5, Eq. 1, Eq. 2]
%   H[k] = Σ(l=1 to L) Gl[k] * aR(θ_l^(R)) * aT^H(θ_l^(T))
%   where Gl[k] ~ CN(0, σ_l²)

    % default AoA range
    if nargin < 2 || isempty(aoa_range)
        aoa_range = [-pi/3, pi/3];
    end

    % extract params
    NR = params.NR;
    NT = params.NT;
    L = params.L;
    Kc = params.Kc;
    sigma_squared = params.sigma_squared;
    fc = params.fc;  
    BW = params.BW;  

    % generate random AoA and AoD for each cluster
    theta_AoA = aoa_range(1) + (aoa_range(2) - aoa_range(1)) * rand(1, L);
    theta_AoD = aoa_range(1) + (aoa_range(2) - aoa_range(1)) * rand(1, L);

    % sort clusters by power
    [sigma_squared, ~] = sort(sigma_squared, 'descend');

    % initialize channel
    H_subbands = zeros(NR, NT, Kc);

    % compute array response vectors for all clusters
    aR_vectors = zeros(NR, L);  % receiver
    aT_vectors = zeros(NT, L);  % transmitter

    for l = 1:L
        aR_vectors(:, l) = array_response(theta_AoA(l), NR);
        aT_vectors(:, l) = array_response(theta_AoD(l), NT);
    end

    % generate ray delays for each cluster
    rays_per_cluster = params.rays_per_cluster;
    delay_spread = params.delay_spread;

    ray_delays = zeros(L, rays_per_cluster);
    for l = 1:L
        % uniformly distributed delays within the spread for each cluster
        ray_delays(l, :) = delay_spread * rand(1, rays_per_cluster);
    end

    % compute subcarrier frequencies for all Kc sub-bands
    subband_freqs = zeros(1, Kc);
    for k = 1:Kc
        % center frequency of k-th sub-band
        subband_freqs(k) = fc - BW/2 + (k - 0.5) * BW / Kc;
    end

    % generate channel for each sub-band
    for k = 1:Kc
        H_k = zeros(NR, NT);
        f_k = subband_freqs(k);

        % sum contributions from all clusters
        for l = 1:L
            Gl_k = 0;
            std_dev_per_ray = sqrt(sigma_squared(l) / rays_per_cluster / 2);

            for r = 1:rays_per_cluster
                % ray complex amplitude
                alpha_lr = std_dev_per_ray * (randn() + 1j*randn());

                % ray delay phase shift
                tau_lr = ray_delays(l, r);
                phase_shift = exp(-1j * 2*pi * f_k * tau_lr);

                % add ray contribution
                Gl_k = Gl_k + alpha_lr * phase_shift;
            end

            % add cluster contribution
            H_k = H_k + Gl_k * (aR_vectors(:, l) * aT_vectors(:, l)');
        end

        H_subbands(:, :, k) = H_k;
    end
end