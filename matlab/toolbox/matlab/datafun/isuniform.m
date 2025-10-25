function [tf, step] = isuniform(x)
%   ISUNIFORM   Check if data is uniformly spaced
%   TF = ISUNIFORM(A) returns a logical scalar that is TRUE if a numeric 
%   vector A is uniformly spaced up to roundoff error. A vector is 
%   uniformly spaced if its elements increase or decrease with a constant,
%   finite step size.
%     
%   [TF,STEP] = ISUNIFORM(A) also returns the step size STEP. If A is
%   uniformly spaced, STEP is a scalar equal to the step size of A. If A is
%   not uniformly spaced, STEP is NaN.
%
%   Examples:
%       Check if a vector is uniformly spaced:
%       isuniform([2 4 6 8])
%
%       Check if a vector is uniformly spaced and return the step size:
%       [tf, step] = isuniform([3 6 9]); % step is of type double
%       [tf, step] = isuniform(single([3 6 9])); % step is of type single
%       [tf, step] = isuniform(int32([3 6 9])); % step is of type double
%
%   See also LINSPACE, COLON, ISREGULAR.

%   Copyright 2022-2024 The MathWorks, Inc.

if ~isreal(x)
    error(message('MATLAB:isuniform:MustBeReal'));
end

if isinteger(x) || islogical(x)
    step = NaN;
else
    step = NaN("like",x);
end

if isscalar(x) || isempty(x)
    tf = false;
    return
end

if ~isvector(x)
    error(message('MATLAB:isuniform:MustBeVector'));
end

if isinteger(x) || islogical(x)
    % Use unsigned integers internally to avoid step size overflow
    x = matlab.internal.math.convertToUnsignedWithSameSpacing(x);

    xWasFlipped = false;
    if x(2) < x(1)
        % data in descending order needs to be flipped to avoid negative steps
        x = flip(x);
        xWasFlipped = true;
    end

    integerStep = x(2)-x(1);
    tf = all(diff(x) == integerStep);

    if integerStep == 0 && tf
        % For unsigned integers the diff of descending elements is 0, so
        % check for a constant vector if the step is 0
        tf = all(x(1:end-1) == x(2:end));
    end

    if nargout == 2
        if isa(x,'uint64') && integerStep > flintmax
            % int64 data is converted to uint64 before this point
            error(message('MATLAB:isuniform:StepTooLarge'));
        end
        if tf
            step = (-1)^xWasFlipped*double(integerStep);
        end
    end
else
    maxElement = max(abs(x(1)),abs(x(end)));
    tol = 4*eps(maxElement);
    numSpaces = numel(x) - 1;
    span = x(end) - x(1);
    if isfinite(span)
        mean_step = span/numSpaces;
    else
        mean_step = x(end)/numSpaces - x(1)/numSpaces;
    end

    stepAbs = abs(mean_step);
    if stepAbs < tol
        % Special cases for very small step sizes
        if stepAbs < eps(maxElement)
            % Avoid having a tolerance that is tighter then round-off error
            tol = eps(maxElement);
        else
            tol = stepAbs;
        end
    end

    tf = all(abs(diff(x) - mean_step) <= tol);

    if ~tf && numel(x) == 2 && allfinite(x)
        % Correctly handle finite data causing the mean step to overflow
        tf = true;
        if nargout == 2
            error(message('MATLAB:isuniform:StepTooLarge'));
        end
    end

    if tf
        step = mean_step;
    end
end

end