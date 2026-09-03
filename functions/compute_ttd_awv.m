function w = compute_ttd_awv(m, tau, phi, params)
% Reference: [R-5, Eq. 4]
%   [w[m]]ₙ = exp[j*(2π*f_m*τₙ + φₙ)]
%   where f_m = fc - BW/2 + (m-1)*BW/(Mtot-1)

    % extract params
    fc = params.fc;
    BW = params.BW;
    Mtot = params.Mtot;

    m = m(:).';          % force row vector
    tau = tau(:);        % force column vector
    phi = phi(:);        % force column vector

    % compute subcarrier frequencies
    f_m = fc - BW/2 + (m - 1) * (BW / Mtot);

    % compute AWVs
    w = exp(-1j * (2*pi * (tau * f_m) + phi));
end