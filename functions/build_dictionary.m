function [B, angle_grid] = build_dictionary(params, R, tau, phi)
% Reference: [R-5, Eq. 14 and Proposition 1]
%   [B]_{d,q} = |f_d^H * aR(ξ_q)|²
%   where f_d is realized by TTD AWV w[m] for m ∈ M_d

    % extract parames
    D = params.D;       % # training directions
    Q = params.Q;       % dictionary size
    NR = params.NR;     % # receiver antennas

    % uniform angle grid over [-π/2, π/2]
    angle_grid = linspace(-pi/2, pi/2, Q);

    % array responses for all angles in dictionary
    aR_dict = array_response(angle_grid, NR);

    % get subcarrier mapping
    [M_sets, ~] = compute_subcarrier_sets(params, R);

    fd_matrix = zeros(NR, D);

    for d = 1:D
        subcarrier_idx = M_sets{d}(1);  % use first subcarrier since all should give same f_d
        w = compute_ttd_awv(subcarrier_idx, tau, phi, params);
        fd_matrix(:, d) = w;
    end

    % compute dictionary matrix
    inner_products = fd_matrix' * aR_dict;
    B = abs(inner_products).^2;
end