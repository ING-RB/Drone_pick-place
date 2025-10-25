function [y, winsz] = smoothdata(A, varargin)
%SMOOTHDATA   Smooth noisy data.
%   B = SMOOTHDATA(A) for a vector A returns a smoothed version of A using
%   a moving average with a fixed window length. The length of the moving
%   average is determined based on the values of A.
%
%   For N-D arrays, SMOOTHDATA operates along the first array dimension
%   whose size does not equal 1.
%
%   SMOOTHDATA(A,DIM) smooths A along dimension DIM.
%
%   SMOOTHDATA(A,METHOD) and SMOOTHDATA(A,DIM,METHOD) smooth the entries of
%   A using the specified moving window method METHOD. METHOD can be one of
%   the following:
%
%     "movmean"     - (default) smooths by averaging over each window of A.
%                     This method can reduce periodic trends in data.
%
%     "movmedian"   - smooths by taking the median over each window of A.
%                     This method can reduce periodic trends in the
%                     presence of outliers.
%
%     "gaussian"    - smooths by filtering A with a Gaussian window.
%
%     "lowess"      - smooths by computing a linear regression in each
%                     window of A. This method is more computationally
%                     expensive but results in fewer discontinuities.
%
%     "loess"       - is similar to 'lowess', but uses local quadratic
%                     regressions.
%
%     "rlowess"     - smooths data using 'lowess' but is more robust to
%                     outliers at the cost of more computation.
%
%     "rloess"      - smooths data using 'loess' but is more robust to
%                     outliers at the cost of more computation.
%
%     "sgolay"      - smooths A using a Savitzky-Golay filter, which may be
%                     more effective than other methods for data that
%                     varies rapidly.
%
%   SMOOTHDATA(A,METHOD,WINSIZE) and SMOOTHDATA(A,DIM,METHOD,WINSIZE)
%   specify the moving window length used for METHOD. WINSIZE can be a
%   scalar or two-element vector. By default, WINSIZE is determined
%   automatically from the entries of A.
%
%   SMOOTHDATA(...,NANFLAG) specifies how NaN values are treated:
%
%     "omitmissing" / "omitnan"         -
%                      (default) NaN elements in the input data are ignored
%                      in each window. If all input elements in any window
%                      are NaN, the result for that window is NaN.
%     "includemissing" / "includenan"   -
%                      NaN values in the input data are included when
%                      computing within each window, resulting in NaN.
%
%   SMOOTHDATA(...,'SmoothingFactor',FACTOR) specifies a smoothing factor
%   that may be used to adjust the level of smoothing by tuning the default
%   window size. FACTOR must be between 0 (producing smaller moving window
%   lengths and less smoothing) and 1 (producing larger moving window
%   lengths and more smoothing). By default, FACTOR = 0.25.
%
%   The smoothing factor cannot be specified if WINSIZE is given.
%
%   SMOOTHDATA(...,'SamplePoints',X) also specifies the sample points X
%   used by the smoothing method. X must be a numeric, duration, or
%   datetime vector. X must be sorted and contain unique points. If the
%   first input is a table, X can also specify a table variable. You can
%   use X to specify time stamps for the data. By default, SMOOTHDATA uses
%   data sampled uniformly at points X = [1 2 3 ... ].
%
%   When 'SamplePoints' are specified, the moving window length is defined
%   relative to the sample points. If X is a duration or datetime vector,
%   then the moving window length must be a duration.
%
%   SMOOTHDATA(...,'sgolay',...,'Degree',D) specifies the degree for the
%   Savitzky-Golay filter. For uniform sample points, D must be a
%   nonnegative integer less than WINSIZE. For nonuniform sample points, D
%   must be a nonnegative integer less than maximum number of points in
%   any window of length WINSIZE.
%
%   [B, WINSIZE] = SMOOTHDATA(...) also returns the moving window length.
%
%   Arguments supported only when first input is table or timetable:
%
%   SMOOTHDATA(...,'DataVariables',DV) smooths the data only in the table
%   variables specified by DV. The default is all table variables in A.
%   DV must be a table variable name, a cell array of table variable names,
%   a vector of table variable indices, a logical vector, a function handle
%   that returns a logical scalar (such as @isnumeric), or a table vartype
%   subscript. The output table B has the same size as input table A.
%
%   SMOOTHDATA(...,'ReplaceValues',TF) specifies how the smoothed data is
%   returned. TF must be one of the following: 
%        true   - (default) replace table variables with the smoothed data 
%        false  - append the smoothed data as additional table variables 
%
%   EXAMPLE: Smooth a noisy exponential
%       a = 6*exp(-((-50:49)/20).^2) + 0.5*randn(1,100);
%       b = smoothdata(a);
%       plot(1:100, a, '-o', 1:100, b, '-x');
%
%   EXAMPLE: Smooth data with outliers using a moving median filter
%       a = 2*cos(2*pi*0.023*(1:100)) + randn(1,100);
%       a([15 35 46]) = -20*(rand(1,3)-0.5);
%       b = smoothdata(a, 'movmedian', 7);
%       plot(1:100, a, '-o', 1:100, b, '-x');
%
%   EXAMPLE: Smooth nonuniform data with a Gaussian filter
%       t = 100*sort(rand(1, 100));
%       x = cos(2*pi*0.04*t+2*pi*rand) + 0.4*randn(1,100);
%       y = smoothdata(x, 'gaussian', 15, 'SamplePoints', t);
%       plot(t, x, '-o', t, y, '-x');
%
%
%    See also fillmissing, rmmissing, filloutliers, rmoutliers, isoutlier

%   Copyright 2016-2023 The MathWorks, Inc.

    narginchk(1,inf);

    if ~isnumeric(A) && ~islogical(A) && ~istabular(A)
        error(message("MATLAB:smoothdata:badArray"));
    end
    if isinteger(A) && ~isreal(A)
        error(message("MATLAB:smoothdata:complexIntegers"));
    end

    sparseInput = issparse(A);
    if sparseInput
        A = full(A);
    end

    is2D = false;
    [method,winsz,nanflag,t,sgdeg,dim,dvars,replace] = matlab.internal.math.parseSmoothdataInputs(A, is2D, varargin{:});

    % Handle subclasses of numeric types
    if isnumeric(A) || islogical(A)
        if isobject(A)
            if isa(A, 'single') || isequal(underlyingType(A), 'single')
                A = single(A);
            else
                A = double(A);
            end
        end
    else
        isNumericSubclass = @(x) (isnumeric(x) || islogical(x)) && isobject(x);
        convertCheck = varfun(isNumericSubclass, A, ...
            'InputVariables', dvars, 'OutputFormat', 'uniform');
        for j = dvars(convertCheck)
            if isa(A.(j), 'single') || isequal(underlyingType(A.(j)), 'single')
                A.(j) = single(A.(j));
            else
                A.(j) = double(A.(j));
            end
        end
    end

    if isempty(A) || (dim > ndims(A)) || (size(A,dim) < 2)
        % Non-floating point variables converted to double in output
        if istabular(A)
            y = A;
            for j = dvars
                y.(j) = convertToFloat(y.(j));
            end
        else
            y = convertToFloat(A);
            if sparseInput
                y = sparse(y);
            end
        end
        return;
    end

    if isnumeric(A) || islogical(A)
        y = smoothNumericArray(A, method, dim, winsz, nanflag, t, sgdeg);
    else
        % A is tabular
        y = A;
        if isempty(dvars)
            return;
        end
        if ~replace
            y = A(:,dvars);
            dvars = 1:width(y);
        end
        % Homogeneous tables can be filled as arrays
        singleCheck = varfun(@(x) isa(x, 'single'), y, ...
            'InputVariables', dvars, 'OutputFormat', 'uniform');
        sparseCheck = varfun(@issparse, y, 'InputVariables', dvars, ...
            'OutputFormat', 'uniform');
        if (all(singleCheck) || ~any(singleCheck)) && ~any(sparseCheck)
            if ~any(singleCheck)
                for j = dvars
                    y.(j) = double(y.(j));
                end
            end
            y{:,dvars} = smoothNumericArray(y{:, dvars}, method, dim, ...
                winsz, nanflag, t, sgdeg);
        else
            for j = dvars
                if issparse(y.(j))
                    y.(j) = sparse(smoothNumericArray(full(y.(j)), method, ...
                        dim, winsz, nanflag, t, sgdeg));
                else
                    y.(j) = smoothNumericArray(y.(j), method, dim, winsz,...
                        nanflag, t, sgdeg);
                end
            end
        end
        if ~replace
            y = matlab.internal.math.appendDataVariables(A,y,"smoothed");
        end
    end

    if sparseInput
        y = sparse(y);
    end

end

%--------------------------------------------------------------------------
function y = smoothNumericArray(A, method, dim, winsz, nanflag, t, degree)
% Smooth a single numeric array

    % Dispatch to the correct method
    if method == "gaussian"
        y = matlab.internal.math.smoothgauss(A,winsz,dim,nanflag,t);
    % Moving mean or median
    elseif startsWith(method, "mov")
        spargs = {};
        if ~isempty(t)
            spargs = { 'SamplePoints', t };
        end
        if contains(method, "mean")
            y = movmean(A, winsz, dim, char(nanflag), spargs{:});
        else
            % Smoothing always converts integers to doubles
            if isinteger(A)
                y = movmedian(double(A), winsz, dim, char(nanflag), spargs{:});
            else
                y = movmedian(A, winsz, dim, char(nanflag), spargs{:});
            end
        end
    % One of the (r)lo(w)ess methods
    elseif contains(method, "ess")
        degree = 1 + ~contains(method, "wess");
        y = matlab.internal.math.localRegression(A, winsz, dim, ...
            nanflag, degree, method, t);
    % Savitzky-Golay
    else
        y = matlab.internal.math.localRegression(A, winsz, dim, ...
            nanflag, degree, method, t);
    end

end

%--------------------------------------------------------------------------
function y = convertToFloat(x)
% Convert non-float inputs to double
    if ~isfloat(x)
        y = double(x);
    else
        y = x;
    end
end