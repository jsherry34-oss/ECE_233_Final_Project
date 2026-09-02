function [theta_hat, p_hat] = estimate_angle(Y, M_sets, B, angle_grid, R, M_all)
% Reference: [R-5, Algorithm 1, Equations 15-16]
%   Algorithm Steps:
%     1. Compute direction powers (Eq. 15):
%        p̂_d = (1/R) * Σ_{m∈𝓜_d} |Y[m]|²
%    
%     2. Dictionary matching (Eq. 16):
%        q* = argmax_q [p̂^T * B[:,q] / ||B[:,q]||]
%        θ̂ = ξ_{q*}

    % # directions
    D = length(M_sets);
    Q = length(angle_grid);

    %% compute direction powers
    p_hat = zeros(D, 1);

    for d = 1:D
        subcarrier_indices = M_sets{d};
        [~, positions_in_Y] = ismember(subcarrier_indices, M_all);

        % sum power over R subcarriers for direction d
        power_sum = sum(abs(Y(positions_in_Y)).^2);

        % average power
        p_hat(d) = power_sum / R;
    end

    %% dictionary matching
    numerator = B' * p_hat;

    % norms of dictionary columns
    B_norms = sqrt(sum(B.^2, 1))';

    % avoid division by zero
    B_norms(B_norms < 1e-10) = 1e-10;

    % normalized correlation
    correlation = numerator ./ B_norms;

    % find angle with maximum correlation
    [~, q_star] = max(correlation);

    % estimated angle
    theta_hat = angle_grid(q_star);
end