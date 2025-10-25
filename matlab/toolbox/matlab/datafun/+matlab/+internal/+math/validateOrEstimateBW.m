function bw = validateOrEstimateBW(errPrefix, x, bw, d, support, sigma, N)
%VALIDATEORESTIMATEBW Validate or estimate a bandwidth for KDE
%   BW = VALIDATEORESTIMATEBW(ERRPREFIX, X, BW, D, SUPPORT) 
%   takes in a prefix for an error message ERRPREFIX, the sample data X, 
%   a bandwidth value BW, and the dimension of the data D. BW can be empty 
%   (indicating default behavior), a double/single vector with D elements, 
%   or one of 'normal-approx' or 'plug-in'. The named options compute a 
%   bandwidth value BW from X using Silverman's rule of thumb ('normal-approx') 
%   or the Sheather-Jones method ('plug-in'). These are only supported
%   for 1D/2D data. SUPPORT is a 2-element vector of lower and upper
%   support/bounds on the data. For 2D data, this argument is unused.
%
%   BW = VALIDATEORESTIMATEBW(ERRPREFIX, X, BW, D, SUPPORT, SIGMA, N) 
%   takes in a standard deviation estimate SIGMA for X, as well as the number
%   of observations N to use in computing the BW. This syntax is only relevant
%   when BW is 'normal-approx'.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2023-2024 The MathWorks, Inc.

noBW = isempty(bw);
if ~noBW && isfloat(bw)
    % Given a bandwidth value directly
    validateattributes(bw, {'double', 'single'}, {'nonnan', 'nonempty', 'real', 'positive'}, ...
        '', 'Bandwidth');

    % Scalar is allowed for d > 1, automatically expand it
    if isscalar(bw)
        bw = bw*ones(1,d);
    elseif numel(bw) ~= d
        if d == 1
            error(message([errPrefix, 'BandwidthNotScalar']))
        else
            % d > 1 only supported in SMLT
            error(message('stats:mvksdensity:BadBandwidth', d));
        end
    end
else
    if d > 2
        % Automatic bandwidth computation is only supported for 1D/2D data
        % d > 1 only supported in SMLT
        error(message('stats:mvksdensity:BadBandwidth', d))
    end
    % No bandwidth given, or specific option string given. Default to
    % 'normal-approx'
    if ~noBW
        bw = validatestring(bw, {'normal-approx', 'plug-in'}, '', 'Bandwidth');
    else
        bw = 'normal-approx';
    end

    if nargin < 6
        % Get a robust estimate of sigma
        sigma = median(abs(x - median(x,1,'omitmissing')),1,'omitmissing') / 0.6745;
        N = size(x, 1);
    end
    idx = sigma<=0;
    if any(idx)
        [minx, maxx] = bounds(x(:,idx), 1);
        sigma(idx) = max(maxx-minx,[],1);
    end
    if isequal(bw, 'normal-approx')
        if all(sigma>0)
            % Default window parameter is optimal for normal distribution
            % Silverman's rule
            bw = sigma * (4/((d+2)*N))^(1/(d+4));
        else
            bw = ones(1,d);
        end
    else
        % plug-in method. Unsupported for 2D data (which are only
        % supported in SMLT)
        if d == 2
            error(message('stats:mvksdensity:PlugInUnsupported'))
        end
        bw = matlab.internal.math.sheatherJonesBW(x, sigma, support);
    end
end
end
