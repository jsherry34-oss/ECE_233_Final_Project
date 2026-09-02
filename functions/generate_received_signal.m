function Y = generate_received_signal(H_subbands, w_matrix, v, M_all, params, SNR_dB)
% Reference: [R-5, Eq. 3]
%   Y[m] = M^(-1/2) * w[m]^H * H[k] * v + w[m]^H * n[m]
%   where:
%     M: Number of training subcarriers
%     k: Sub-band index for subcarrier m
%     n[m] ~ CN(0, σ_N² * I_NR): Thermal noise

    % extract params
    NR = params.NR;
    Kc = params.Kc;
    Mtot = params.Mtot;
    sigma_squared = params.sigma_squared;

    % Number of training subcarriers
    M = length(M_all);

    % compute total channel power and noise power
    P_channel = sum(sigma_squared);
    SNR_linear = 10^(SNR_dB/10);

    % training pilot power normalization
    pilot_power = 1/sqrt(M);

    % noise power per antenna element
    sigma_N_squared = P_channel / (M * NR * SNR_linear);

    % generate received signal for each training subcarrier
    Y = zeros(1, M);

    for i = 1:M
        m = M_all(i);

        % map subcarrier index m to sub-band index k
        k = ceil((m * Kc) / Mtot);

        % get channel for this sub-band
        H_k = H_subbands(:, :, k);

        % get AWV for this subcarrier
        w_m = w_matrix(:, i);

        % signal component: M^(-1/2) * w[m]^H * H[k] * v
        signal = pilot_power * (w_m' * H_k * v);

        % noise component
        std_dev = sqrt(sigma_N_squared/2);
        n_m = std_dev * (randn(NR, 1) + 1j*randn(NR, 1));

        noise = w_m' * n_m;

        Y(i) = signal + noise;
    end
end