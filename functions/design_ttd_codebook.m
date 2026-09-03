function [tau, phi] = design_ttd_codebook(params, R)
% Reference: [R-5, Proposition 1, Eq. 9]
%   τₙ = (n-1) * R / BW
%   φₙ = (n-1) * [sgn(ψ)*π - ψ]
%   where ψ = mod(2πR(fc - BW/2)/BW + π, 2π) - π

    % extract params
    NR = params.NR;
    fc = params.fc;
    BW = params.BW;

    n = 1:NR;

    % compute delay taps
    tau = (n-1) * (R / BW);

    % compute phase compensation factor
    psi = mod(2*pi*R*(fc - BW/2)/BW + pi, 2*pi) - pi;

    psi_sign = sign(psi);
    psi_sign(psi_sign == 0) = 1;

    % compute phase taps
    phi = (n-1) * (psi_sign*pi - psi);
end