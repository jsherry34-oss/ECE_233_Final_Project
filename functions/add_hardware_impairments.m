function w_impaired = add_hardware_impairments(~, m_indices, tau, phi, params, sigma_A, sigma_P, sigma_T)
% Reference: [R-5, Eq. 5, second equation - BB architecture]
%   [w_BB[m]]_n = α_n * exp(j*(2π*(f_m - fc)*τ̃_n + φ̃_n))

    % extract params
    NR = params.NR;
    fc = params.fc;
    BW = params.BW;
    Mtot = params.Mtot;

    %% generate impairments
    % gain error
    if sigma_A > 0
        gain_error_dB = sigma_A * randn(NR, 1);
        alpha = 10.^(gain_error_dB / 10);
    else
        alpha = ones(NR, 1);
    end

    % phase error
    if sigma_P > 0
        phi_tilde = phi(:) + sigma_P * randn(NR, 1);
    else
        phi_tilde = phi(:);
    end

    % delay error
    if sigma_T > 0
        tau_tilde = tau(:) + sigma_T * randn(NR, 1);
    else
        tau_tilde = tau(:);
    end

    % subcarrier frequencies
    f_m = fc - BW/2 + (m_indices - 1) * (BW / (Mtot - 1));

    % BB TTD architecture: phase includes (f_m - fc) term [R-5, Eq. 5]
    phase_term = 2*pi * (tau_tilde * (f_m - fc)) + phi_tilde;

    w_impaired = alpha .* exp(-1j * phase_term);
end