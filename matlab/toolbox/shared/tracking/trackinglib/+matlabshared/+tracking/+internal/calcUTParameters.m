function [c, Wmean, Wcov, OOM] = calcUTParameters(alpha,beta,kappa,n)
% calcUTParameters Calculate the values of the unscented transformation
% parameters.
%
% [c, Wmean, Wcov, OOM] = calcUTParameters(alpha, beta, kappa, n)
%
% Input arguments:
%   alpha:       (Scalar) Parameter to adjust the distribution of the sigma
%                points around the mean.
%   beta:        (Scalar) Parameter to adjust the distribution of the sigma
%                points around the mean.
%   kappa:       (Scalar) Parameter to adjust the distribution of the sigma
%                points around the mean.
%   n:           (Scalar) Number of parameters in the transformation. There 
%                are two cases:
%                   Case1) y = f(x)+v (Additive noise)
%                   Case2) y = f(x,v) (Non-additive noise)
%                For Case1, n=numel(x)
%                For Case2, n=numel(x)+numel(v)
%
% Output arguments:
%   c:           (Scalar) Weight needed for calculation of the sigma points
%   meanWeights: ([2 1] vector) The weights needed to calculate the
%                mean of the transformed sigma points. The first element is
%                used for the first transformed sigma point, the second
%                element is used for the transformed sigma points 2:2*n+1.
%   covWeights:  ([2 1] vector) The weights needed to calculate
%                the covariances Pyy and Pxy. The first element is
%                used for the first transformed sigma point, the second
%                element is used for the transformed sigma points 2:2*n+1.
%   OOM:         (Scalar) Order of magnitude associated with meanWeights and
%                covWeights, which is required for numerical stability of the
%                unscented transformation.

% Notes: 
% 1. Since this is an internal function, no validation is done at this
% level. Any additional input validation should be done in a function or
% object that use this function. 
% 2. The output type is determined by the type of alpha. This is required
% to allow single precision processing for the UnscentedKalmanFilter
% object. Only single or double precision are supported. 

%   Copyright 2016 The MathWorks, Inc.

%#codegen
%#ok<*EMCLS>
%#ok<*EMCA>
%#ok<*MCSUP>

% if alpha, n or kappa is of class single, c calculation ensures all else
% is also single
c     = alpha^2 * (n + kappa); 
Wmean = [1-n/c; % =lambda/c=lambda/(n+lambda) since lambda=c-n
         1/(2*c)];
Wcov  = [Wmean(1) + (1 - alpha^2 + beta);
         Wmean(2)];

if Wmean(1) ~= 0 %Note: when alpha = 1, Wmean(1) = 0
    OOM = Wmean(1);
    Wmean = Wmean / OOM;
    Wcov = Wcov / OOM;
else
    OOM = cast(1,'like', alpha);
end
end