function a = array_response(theta, N)
% Reference: [R-5, Section II]
%   [a(θ)]ₙ = N^(-1/2) * exp(j*(n-1)*π*sin(θ))
%   for n = 1, ..., N

    theta = theta(:).';  % force row vector

    n = (1:N).';

    % compute array response
    a = (1/sqrt(N)) * exp(1j * (n-1) * pi * sin(theta));
end