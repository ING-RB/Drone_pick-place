function coeffs = fractalcoef(numpoles, alpha)
%

%   Copyright 2023 The MathWorks, Inc.

%#codegen

arguments
    numpoles (1,1) {mustBeFloat, mustBeInteger, mustBePositive} = 1;
    alpha (1,1) {mustBeFloat, mustBeInRange(alpha, 0, 2, "exclusive")} = 1;
end

one = cast(1, "like", numpoles);
two = cast(2, "like", numpoles);
alphaVal = cast(alpha, "like", numpoles);

% The poles are from equation 116 in the following paper: 
%   N. J. Kasdin, "Discrete simulation of colored noise and stochastic
%   processes and 1/f/sup /spl alpha// power law noise generation," in
%   Proceedings of the IEEE, vol. 83, no. 5, pp. 802-827, May 1995, doi:
%   10.1109/5.381848.
poles = one:numpoles;
poles = ( poles - one - alphaVal/two ) ./ poles;
poles = cumprod(poles);

coeffs = struct("Numerator", one, "Denominator", [one, poles]);
end
