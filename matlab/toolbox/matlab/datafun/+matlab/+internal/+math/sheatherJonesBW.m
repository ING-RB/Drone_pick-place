function bw = sheatherJonesBW(x, sd, support)
%SHEATHERJONESBW Compute Sheather-Jones estimate of the bandwidth
%   BW = SHEATHERJONESBW(X, SD, SUPPOR) computes the (improved)
%   Sheather-Jones bandwidth estimator derived in [1] for a double/single 
%   vector X with standard deviation SD, and support range SUPPORT. It 
%   returns a scalar bandwidth for X, BW.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

% References:
%   [1] Z.I. Botev, J.F. Grotowski, and D.P. Kroese (2010), "Kernel Density
%       Estimation via Diffusion", Annals of Statistics, Volume 38, Number 5

%   Copyright 2023 The MathWorks, Inc.

% Get intial non-parametric estimate of the probability. Botev uses 2^14 
% as the default grid size. 2^14 bins need 2^14+1 edges
n = 2^14 + 1;

% Get data bounds. Either compute some range for unbounded data using the 
% estimated standard deviation, or use the specific limits of the data
[minx, maxx] = bounds(x);
if isinf(support(1))
    lb = minx-sd;
else
    lb = support(1);
end

if isinf(support(2))
    ub = maxx + sd;
else
    ub = support(2);
end
edges = linspace(lb, ub, n);
numUniquePoints = numel(unique(x));
initProb = histcounts(x, edges)'/numUniquePoints;
initProb = initProb/sum(initProb);

% Using type 2 discrete cosine transformation results in faster evaluation
if isa(initProb, 'gpuArray')
    % gpuArray not supported by mldct
    initProb = gather(initProb);
end
tPDF = matlab.internal.math.transform.mldct(initProb);
tPDF=(tPDF(2:end)/2).^2;
I=(1:numel(tPDF))'.^2; 

% Pre-compute the non-f pieces of the formula for t*
% Only need 5 iterations (7:-1:2) to reach stable estimate.
l = 7;
iters = l-1:-1:2;
frac1 = (1+(1/2).^(iters+1/2))/3;
frac2 = fliplr(cumprod(3:2:(2*iters(1)-1))/(numUniquePoints*sqrt(pi/2)));
const = frac1.*frac2;

% Find the fixed point of:
%   t = xi * gamma[l](t);
% then transform the fixed point tStar to the bandwidth
opts = struct('Display', 'off');
try
    tStar = fzero(@(t) fixedPoint(t, const, numUniquePoints, I, tPDF), 0, opts);
    if isnan(tStar)
        % Couldn't find a 0
        % Instead, try to find the min value in the range [0, .1]. .1
        % corresponds to a bandwidth roughly 1/3 of the range of the data,
        % and is a safe upper bound for what the bandwidth reasonably
        % should be
        tStar = fminbnd(@(t) abs(fixedPoint(t, const, numUniquePoints, I, tPDF)), 0, .1, opts);
    end
catch
    % Couldn't find a 0, potentially encountered -Inf in evaluation
    % Find a min value instead in the range [0, .1] for the reasons
    % mentioned above
    tStar = fminbnd(@(t) abs(fixedPoint(t, const, numUniquePoints, I, tPDF)), 0, .1, opts);
end
bw = sqrt(tStar) * (edges(end)-edges(1));
end

function  out = fixedPoint(tLeft, const, numPoints, I, tPDF)
% This function computes the fixed point equation from Botev used to find t*
% It takes in tLeft, a guess for the LHS of the equation, const, the
% constant terms of the equation unrelated to f, numPoints, the number of
% data points, I, a vector of squares used in computing t*, and tPDF, the
% discrete guess of the PDF
l=7;
logI = log(I);
f=2*pi^(2*l)*sum(exp(l*logI+log(tPDF)-(I*pi^2*tLeft)));
ind = 1;
for i = l-1:-1:2
    tRight=(const(ind)/f)^(2/(3+2*i));
    f=2*pi^(2*i)*sum(exp(i*logI+log(tPDF)-(I*pi^2*tRight)));
    ind = ind+1;
end
out=tLeft-(2*numPoints*sqrt(pi)*f)^(-2/5);
end