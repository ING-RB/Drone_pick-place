function samples = truncatedGaussian(a, b, mu, sigma, varargin)
%This function is for internal use only. It may be removed in the future.

%TRUNCATEDGAUSSIAN Generate samples from a truncated Gaussian distribution
%
%   SAMPLES = truncatedGaussian(A,B,MU,SIGMA,N) Given a lower bound (A) and
%   an upper bound (B) the function returns N number of samples from a
%   Gaussian distribution with a mean (MU) and standard deviation (SIGMA).
%   This is based on inverse transform sampling
%
%   SAMPLES = truncatedGaussian(A,B,MU,SIGMA) Generates a single sample.
%
%   SAMPLES = truncatedGaussian(_, N, TYPENAME) Generates N number of
%   samples of type TYPENAME. By default the generated samples are of type
%   'double'.
%    
%#codegen

%   Copyright 2021 The MathWorks, Inc.

    narginchk(4,6);
    numsamples = 1;
    typename = 'double';
    if(nargin >= 5)
        numsamples = varargin{1};
    end
    if(nargin == 6)
        typename = varargin{2};
    end
    alpha = (a - mu) ./ sigma;
    beta = (b - mu) ./ sigma;
    Fa = Phi(alpha);
    Fb = Phi(beta);
    U = rand(numel(b), numsamples, typename);

    % p = Fa + U * (Fb - Fa)
    p = repmat(Fa, numsamples, 1) + U' .* repmat(Fb - Fa, numsamples, 1);
    z = Phiinv(p);

    % samples = mu + sigma * z
    samples = repmat(mu, numsamples, 1)+repmat(sigma, numsamples, 1).*z;
end

function y = Phi(x)
    %Phi CDF of a normal distribution
    y = erfc(-x / sqrt(2)) / 2;
end

function y = Phiinv(x)
    %Phiinv Inverse of the CDF of a normal distribution
    y = -sqrt(2) * erfcinv(2 * x);
end
