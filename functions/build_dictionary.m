function [B, angle_grid] = build_dictionary(params, R, tau, phi)
% Reference: [R-5, Eq. 14 and Proposition 1]
%   [B]_{d,q} = |f_d^H * aR(ξ_q)|²
%   where f_d is the ACTUAL beam realized by TTD AWV w[m] for m ∈ M_d
%
% CRITICAL: The dictionary must use the ACTUAL frequency-dependent TTD beams,
% averaged over the R subcarriers in each direction, NOT simple DFT beams!

    % extract params
    D = params.D;       % # training directions
    Q = params.Q;       % dictionary size

    % uniform angle grid over [-π/2, π/2]
    angle_grid = linspace(-pi/2, pi/2, Q);

    % array responses for all angles in dictionary
    aR_dict = array_response(angle_grid, params.NR);

    % compute subcarrier sets for this R
    [M_sets, ~] = compute_subcarrier_sets(params, R);

    % initialize dictionary
    B = zeros(D, Q);

    % for each direction d, compute the average beam pattern over its R subcarriers
    for d = 1:D
        % get the R subcarriers for this direction
        m_indices = M_sets{d};

        % compute TTD AWVs for these subcarriers
        w_d = compute_ttd_awv(m_indices, tau, phi, params);

        % average the beam patterns over R subcarriers
        for r = 1:R
            w_r = w_d(:, r);
            inner_products = w_r' * aR_dict;  % 1 x Q
            B(d, :) = B(d, :) + abs(inner_products).^2;
        end

        % average over R subcarriers
        B(d, :) = B(d, :) / R;
    end
end