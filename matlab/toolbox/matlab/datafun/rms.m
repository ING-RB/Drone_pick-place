function y = rms(x, opt1, opt2)
% Syntax:
%     Y = rms(X)
%     Y = rms(X,VECDIM)
%     Y = rms(___,NANFLAG)
%
% For more information, see documentation

%   Copyright 2011-2023 The MathWorks, Inc.

if isinteger(x)
    x = double(x);
end

% mean accepts an outtype flag, but rms does not.
if nargin > 1
    isNanflag = validateInput(opt1,false);
    if nargin > 2
        if isNanflag
            error(message('MATLAB:rms:UnknownFlag'));
        else
            validateInput(opt2,true);
        end
    end
end

if isreal(x)
    if nargin==1
        y = sqrt(mean(x .* x));
    elseif nargin==2
        y = sqrt(mean(x .* x, opt1));
    else
        y = sqrt(mean(x .* x, opt1, opt2));
    end
else
    if nargin==1
        y = sqrt(mean(real(x) .* real(x) + imag(x) .* imag(x)));
    elseif nargin==2
        y = sqrt(mean(real(x) .* real(x) + imag(x) .* imag(x), opt1));
    else
        y = sqrt(mean(real(x) .* real(x) + imag(x) .* imag(x), opt1, opt2));
    end
end
end

function isNanflag = validateInput(name,checkNanflagOnly)
    if (ischar(name) && isrow(name)) || (isstring(name) && isscalar(name))
        if checkNanflagOnly
            tf = strncmpi(name, {'omitnan', 'includenan','omitmissing', 'includemissing'}, max(1,strlength(name)));
        else
            tf = strncmpi(name, {'omitnan', 'includenan', 'omitmissing', 'includemissing','all'}, max(1,strlength(name)));
        end
        isValid = any(tf);
        isNanflag = any(tf(1:4));
    else
        isValid = ~(checkNanflagOnly || ~isnumeric(name));
        isNanflag = false;
    end
    
    if ~isValid
        if checkNanflagOnly
            error(message('MATLAB:rms:UnknownFlag'));
        else
            error(message('MATLAB:rms:UnknownFlagOrDim'));
        end
    end
end