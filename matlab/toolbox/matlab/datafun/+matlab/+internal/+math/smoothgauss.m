function y = smoothgauss(x, winsz, dim, nanflag, t)
% SMOOTHGAUSS  Gaussian smoothing.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

% Copyright 2016-2022 The MathWorks, Inc.

    narginchk(5, 5);

    assert(size(x,dim) > 1, 'unexpected singleton dimension');
    
    % Use convolution if there are no sample points or uniform sample
    % points and the window is balanced (same extent on both sides)
    useUniform = (isempty(t) || isuniform(t)) && isscalar(winsz);
    
    if useUniform
        if ~isempty(t)
            % If sample points are uniformly spaced, ignore them and
            % compute the rescaled window size
            if isinteger(winsz) || isinteger(t)
                % Avoid rounding of the window size for integer values.
                % It is OK here if the class of the window size mismatches
                % the sample point class.
                winsz = double(winsz) / double(t(2) - t(1));
            else
                winsz = winsz / (t(2) - t(1));
            end
            t = [];
        end
    else
        % If convolution is not an option but there are no sample points,
        % create default sample points
        if isempty(t)
            t = 1:size(x,dim);
        end
    end

    % If all windows contain a single point or are empty, nothing to do
    if checkSinglePointWindow(t, winsz)
        if ~isfloat(x)
            y = double(x);
        else
            y = x;
        end
        return;
    end
    
    windowWidth = sum(winsz);
    sig = windowWidth/5;

    % Convert datetime/duration sample points
    if ~isempty(t) && (isduration(t) || isdatetime(t))
        winsz = milliseconds(winsz);
        sig = milliseconds(sig);
        if isduration(t)
            t = milliseconds(t);
        else
            t = datetimeToComplex(t);
        end
    end
    sig = double(sig);

    if useUniform
        y = uniformGaussianSmooth(x, winsz, dim, nanflag, sig);
    else
        y = matlab.internal.math.gaussianSmoothing(x, dim, t, winsz, ...
            char(nanflag), sig);
    end

end

%--------------------------------------------------------------------------
function y = uniformGaussianSmooth(x, winsz, dim, nanflag, sig)
% UNIFORMGAUSSIANSMOOTH  Gaussian smoothing for uniform data

    y = x;

    % Create the Gaussian filter
    winsz = double(winsz);
    winsz = min(fix(winsz), 2*size(x, dim));
    h = exp(-((1:winsz) - ceil(winsz/2)).^2/(2*sig^2));
    h = h(:) / sum(h);
    
    if dim ~= 1
        pind = [dim, 1:(dim-1), (dim+1):ndims(y)];
        y = permute(y, pind);
    end
    
    omittingNaN = nanflag == "omitnan";
    evenWindow = rem(length(h),2) == 0;

    % Keep track of indices of NaN inputs
    if omittingNaN && any(isnan(y(:)))
        nanInd = isnan(y);
        y(nanInd) = 0;
    else
        nanInd = false(size(y));
    end
    
    if evenWindow
        % Compensate for how even window sizes and 'same' interact.
        y = flip(y, 1);
        h = flip(h, 1);
        % Since the input is flipped, we have to mind how the NaN counting
        % is affected.
        if omittingNaN
            % Get the NaN locations correct.
            nanInd = flip(nanInd, 1);
        end
    end
    % Convolve with the filter
    y = convn(y, h, 'same');
    
    % Compensate for endpoints and NaN locations by computing the sum of
    % the filter coefficients contributing at each location
    halfwinsz = ceil(winsz / 2);
    sz = size(nanInd);
    sz(1) = halfwinsz;
    nanInd = cat(1, true(sz), nanInd, true(sz));
    ync = sum(h) - convn(double(nanInd), h, 'same');
    ync = ync((halfwinsz+1):(halfwinsz+size(y,1)), :);
    ync = reshape(ync, size(y));
    y = y ./ ync;
    if any(nanInd)
        % Correct NaN values that disappear because of roundoff.
        ycnt = convn(double(nanInd), ones(size(h)), 'same');
        ycnt = ycnt((halfwinsz+1):(halfwinsz+size(y,1)), :) == numel(h);
        y(ycnt) = NaN;
    end

    if evenWindow
        % All convolution is finished, so reverse the output.
        y = flip(y, 1);
    end
    
    if dim ~= 1
        y = ipermute(y, pind);
    end

end

%--------------------------------------------------------------------------
function tf = isuniform(t)
% Determine if sample points are uniformly spaced

    dt = diff(t);
    tf = (max(dt) == min(dt));

end

%--------------------------------------------------------------------------
function a = datetimeToComplex(b)
% Convert datetimes to complex numbers 

    y = year(b);
    m = month(b);
    d = day(b);
    h = hour(b);
    mn = minute(b);
    sc = floor(second(b));

    % Extract milliseconds
    ms = milliseconds(b - datetime(y,m,d,h,mn,sc,'TimeZone',b.TimeZone));
    data = {y, m, d, h, mn, sc, ms};
    a = matlab.internal.datetime.createFromDateVec(data, '');

end

%--------------------------------------------------------------------------
function tf = checkSinglePointWindow(t, winsz)
% Check whether each window contains only a single point

    if isempty(t)
        % t can only be empty for uniform code path, which can't happen if
        % the window size isn't scalar.
        assert(isscalar(winsz), ...
            't should only be empty for uniform points and scalar windows');
        tf = winsz < 2;
    else
        td = min(diff(t));
        % The smallest gap between sample points must be larger than the
        % window extent in either direction
        if numel(winsz) == 2
            tf = all(td > winsz);
        else
            tf = (2*td > winsz);
        end
    end

end