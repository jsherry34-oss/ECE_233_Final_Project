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

    theta_AoA = zeros(1, L);
    theta_AoD = zeros(1, L);
    
    % generate dominant path
    theta_AoA(1) = aoa_range(1) + (aoa_range(2) - aoa_range(1)) * rand();
    theta_AoD(1) = aoa_range(1) + (aoa_range(2) - aoa_range(1)) * rand();
    
    % generate weak paths with minimum 10-degree separation
    min_sep = 10 * pi / 180; 
    
    for l = 2:L
        valid_AoA = false;
        while ~valid_AoA
            cand = aoa_range(1) + (aoa_range(2) - aoa_range(1)) * rand();
            if min(abs(cand - theta_AoA(1:l-1))) > min_sep
                theta_AoA(l) = cand;
                valid_AoA = true;
            end
        end
        
        valid_AoD = false;
        while ~valid_AoD
            cand = aoa_range(1) + (aoa_range(2) - aoa_range(1)) * rand();
            if min(abs(cand - theta_AoD(1:l-1))) > min_sep
                theta_AoD(l) = cand;
                valid_AoD = true;
            end
        end
    end

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

    % generate channel for each sub-band
    for k = 1:Kc
        H_k = zeros(NR, NT);

        % sum contributions from all clusters
        for l = 1:L
            % Generate Gl[k] ~ CN(0, σ²l) directly
            % This ensures independence across sub-bands per Eq. 2
            std_dev = sqrt(sigma_squared(l) / 2);
            Gl_k = std_dev * (randn + 1j*randn);

            % add cluster contribution
            H_k = H_k + Gl_k * (aR_vectors(:, l) * aT_vectors(:, l)');
        end
        H_subbands(:, :, k) = H_k;
    end
end