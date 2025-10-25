function [f, xf, bw] = kde(a, NVArgs)
%KDE Compute one dimensional kernel density estimate
%   [F, XF] = KDE(A) computes an estimate of the probability density
%   function (PDF) of a double/single vector A using kernel density 
%   estimation (KDE). It returns the estimate in a double/single vector F, 
%   evaluated at the points in double/single vector XF. XF is an evenly 
%   spaced grid of max(100, round(sqrt(numel(x)))) points covering the range 
%   of A.
%
%   [F, XF, BW] = KDE(A) also returns the estimated bandwidth BW, a
%   double/single scalar, used to perform the kernel density estimate.
%
%   [__] = KDE(__, Bandwidth=BW) specifies the bandwidth to use in computing 
%   the kernel density estimate. Specify BW as a double or single scalar
%   > 0, or one of these names:
%       
%       "normal-approx" - (default) Computes a value from A using the 
%                         normal approximation method, sometimes referred 
%                         to as Silverman's rule of thumb.
%       "plug-in" - Computes a value from A using the plug-in method of 
%                   Sheather and Jones, as improved upon by Botev et al. (2010).
%       
%   [__] = KDE(__, Support=BOUNDS) specifies the support of the data and the 
%   estimated probability function. A must live within BOUNDS, and can never 
%   assume values outside of BOUNDS. The estimated PDF assumes value 0 
%   outside of BOUNDS. The estimate CDF assumes value 0 outside the left
%   bound and value 1 outside the right bound. Specify BOUNDS as a 
%   two-element double or single vector [L, U], such that L < U and A 
%   assumes values in (L, U), or specify BOUNDS as one of these names:
%   
%       "unbounded" - (default) A can assume any value in the range (-Inf, Inf).
%       "positive" - A is strictly > 0.
%       "nonnegative" - A is >= 0.
%       "negative" - A is strictly < 0.
%      
%   [__] = KDE(__, EvaluationPoints=PTS) specifies the points PTS at which 
%   to evaluate the probability function. Only one of NumPoints and 
%   EvaluationPoints can be given. PTS is a double/single vector, with a 
%   default value of NumPoints evenly spaced points to cover the range of A.
%
%   [__] = KDE(__, Kernel=KERNELFCN) specifies which kernel function to use. 
%   Specify KERNELFCN as a function handle or one of these names:
%   
%       "normal" - (default) Use the Normal distribution PDF as the kernel.
%       "box" - Use the box function as the kernel
%       "triangle" - Use the triangle function as the kernel
%       "parabolic" - Use the parabolic function, also sometimes called 
%                     Epanechnikov's function, as the kernel.
%
%   If KERNELFCN is a function handle, it must take in a vector or 2D matrix
%   containing distances between data values A and evaluation points PTS
%   and return a vector or 2D matrix of the same size, respectively.
%
%   [__] = KDE(__, NumPoints=NUMPTS) specifies the number of points to use 
%   to evaluate the probability function. Only one of NumPoints and 
%   EvaluationPoints can be given. NUMPTS is a double/single integer scalar 
%   > 0. The default value of NUMPTS is max(100, round(sqrt(numel(A)))).
%
%   [__] = KDE(__, ProbabilityFcn=FCN) specifies which probability function 
%   to compute. FCN takes values "pdf" (default) to compute the probability
%   density function (PDF), or "cdf" to compute the cumulative distribution 
%   function (CDF).
%
%   [__] = KDE(__, WEIGHT=WGT) specifies observation weights. WGT is a
%   nonnegative double/single vector with as many elements as A. KDE 
%   computes an estimate of the probability function by weighting A(i) with 
%   WGT(i). By default, all observations are weighted equally.
%
%   Example:
%       % Generate data with two modes at 3 and -2, estimate the PDF, and 
%       % plot it against a histogram
%       rng(0, "twister")
%       data = [randn(100, 1) + 3; randn(100, 1) - 2];
%       h = histogram(data, Normalization="pdf");
%       [f, x] = kde(data, EvaluationPoints=h.BinLimits(1):.1:h.BinLimits(2));
%       hold on
%       plot(x, f, LineWidth=2);
%
%   See also histcounts, histogram

% References:
%   [1] Z.I. Botev, J.F. Grotowski, and D.P. Kroese (2010), "Kernel Density
%       Estimation via Diffusion", Annals of Statistics, Volume 38, Number 5

%   Copyright 2023-2024 The MathWorks, Inc.
arguments
    a {mustBeFloat, mustBeReal, mustBeNonsparse}
    NVArgs.Bandwidth = "normal-approx"
    NVArgs.Support = "unbounded"
    NVArgs.EvaluationPoints {mustBeFloat, mustBeNonsparse, mustBeReal, mustBeVector} = zeros(0,1)
    NVArgs.Kernel = "normal"
    NVArgs.NumPoints(1,1) {mustBeFloat, mustBeInteger, mustBePositive, mustBeNonsparse} = max(100, round(sqrt(numel(a))))
    NVArgs.ProbabilityFcn(1,1) string = "pdf"
    NVArgs.Weight(:,1) {mustBeNonnegative, mustBeFloat, mustBeNonsparse, mustBeNonNan} = ones(numel(a), 1)
end

if isempty(a)
    a = castInputs(a, NVArgs.Weight, NVArgs.EvaluationPoints, NVArgs.Bandwidth);
    f = cast([], "like", a);
    xf = cast([], "like", a);
    bw = cast([], "like", a);
    return
end

% Parse args
[NVArgs, a, outSize, kernelInfo] = validateNVArgsAndSetDefaults(a, NVArgs);

% Cast inputs
[a, NVArgs.Weight, NVArgs.EvaluationPoints, NVArgs.Bandwidth] = castInputs(a, NVArgs.Weight, ...
    NVArgs.EvaluationPoints, NVArgs.Bandwidth);

% Remove out of bounds evaluation points to be put back in after the fact
[xi, inbounds, outUpper] = matlab.internal.math.areEvalPointsInBounds(NVArgs.EvaluationPoints(:), ...
    NVArgs.Support(1), NVArgs.Support(2));

% Compute KDE and reshape
fout = matlab.internal.math.univarKDE(a(:), xi, kernelInfo.IsCDF, ...
    NVArgs.Bandwidth, NVArgs.Weight, kernelInfo.Fcn, kernelInfo.Cutoff, NVArgs.Support);
f = zeros(outSize, "like", a);
f(inbounds) = fout;

if strcmpi(NVArgs.ProbabilityFcn, 'cdf')
    % Any points that are outside the upper bound have the CDF value set to
    % 1 instead of 0
    f(outUpper) = 1;
end

if nargout > 1
    xf = reshape(NVArgs.EvaluationPoints, outSize);
    bw = NVArgs.Bandwidth;
end
end

function [NVArgs, x, outSize, kernelInfo] = validateNVArgsAndSetDefaults(x, NVArgs)
% This helper takes in a struct of NV args and the data to perform KDE on.
% It validates the provided NV args and computes some defaults when
% relevant.
errPrefix = 'MATLAB:kde:';

if ~isvector(x)
    error(message('MATLAB:kde:DataNotVector'));
end

% Remove NaNs and determine output size. Do so before computing the
% bandwidth so NaN entries aren't considered
ptsNotGiven = isempty(NVArgs.EvaluationPoints);
% x and weight size are already verified. Remove rows with NaN x values
if numel(NVArgs.Weight) ~= numel(x)
    error(message('MATLAB:kde:WeightAndDataDiffSizes'))
end

badIdx = isnan(x);
x(badIdx) = [];
NVArgs.Weight(badIdx) = [];

% Determine orientation
if ptsNotGiven
    if isrow(x)
        outSize = [1, NVArgs.NumPoints];
    else
        outSize = [NVArgs.NumPoints, 1];
    end
else
    outSize = size(NVArgs.EvaluationPoints);
end

validateattributes(x, {'double', 'single'}, {'finite'}, '', 'x');
x = x(:);

% Weight already validated. Normalize and set to a row vector
NVArgs.Weight = (NVArgs.Weight(:)/sum(NVArgs.Weight))';

% Bounds
[minx, maxx] = bounds(x);
[L,U] = matlab.internal.math.validateKDESupport(errPrefix,NVArgs.Support,minx,maxx,1);
NVArgs.Support = [L U];

% Bandwidth
NVArgs.Bandwidth = matlab.internal.math.validateOrEstimateBW(errPrefix, x, ...
    NVArgs.Bandwidth, 1, [L U]);

% Function + Kernel
kernelInfo = matlab.internal.math.kernelinfo(errPrefix, NVArgs.ProbabilityFcn, ...
    NVArgs.Kernel, {'pdf', 'cdf'}, 'ProbabilityFcn');


% NumPoints is fully validated in the arguments block
% EvaluationPoints, if given, is fully validated in the arguments block.
% Populate a default otherwise. Extend it past the limits of the data to
% get a more full view of the PDF
if ptsNotGiven
    extraWidth = min(kernelInfo.Cutoff, 3) * NVArgs.Bandwidth;
    NVArgs.EvaluationPoints = linspace(max(minx-extraWidth, L), min(maxx+extraWidth, U), ...
        NVArgs.NumPoints);
end

end

function [x, weight, evalPts, bw] = castInputs(x, weight, evalPts, bw)
% This function casts inputs to the appropriate type, including
% gpuArray-ness. x, weight, evalPts, and bandwidth are the only args that could
% reasonably have a type impact on the output.
proto = x([]) + weight([]) + evalPts([]);
if isfloat(bw)
    % Bandwdith can be a string of an estimation method, in which case,
    % don't try to cast it
    proto = proto + bw([]);
    bw = cast(bw, "like", proto);
end
x = cast(x, "like", proto);
weight = cast(weight,  "like", proto);
evalPts = cast(evalPts,  "like", proto);
end
