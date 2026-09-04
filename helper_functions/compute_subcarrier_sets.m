function [M_sets, M_all] = compute_subcarrier_sets(params, R)
% Reference: [R-5, Eq. 7]
%   𝓜_d = {m | m = 1 + (d-1)*⌊Mtot/(D*R)⌋ + (r-1)*Mtot/R, r = 1, ..., R}

    % extract params
    D = params.D;        
    Mtot = params.Mtot;   

    % initialize output
    M_sets = cell(D, 1);
    M_all = [];

    % compute subcarrier indices for each direction d
    for d = 1:D
        m_d = zeros(1, R);
        for r = 1:R
            m_d(r) = 1 + (d-1)*floor(Mtot/(D*R)) + (r-1)*(Mtot/R);
        end

        M_sets{d} = m_d;
        M_all = [M_all, m_d];
    end
end