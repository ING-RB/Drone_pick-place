function tc = cov(varargin)
%COV Covariance matrix.
%   C = COV(X)
%   C = COV(X,Y)
%   C = COV(...,FLAG) where FLAG is 0 or 1
%   C = COV(...,NANFLAG)
%
%   Limitations:
%   1) X and Y must be tall arrays of the same size, even if both are vectors.
%   2) Option 'partialrows' is not supported.
%
%   See also: COV.

%   Copyright 2016-2024 The MathWorks, Inc.

narginchk(1, 4);
[cellIn, normFlag, NaNFlag] = parseInputs(varargin{:});
if strcmp(NaNFlag,'partialrows')
   error(message('MATLAB:bigdata:array:CovPartialRowsNotSupported')); 
end
tc = computeCov(cellIn, normFlag, NaNFlag);
end

function [cellIn, normFlag, NaNFlag] = parseInputs(varargin)
tx = varargin{1};
tx = tall.validateType(tx, mfilename, {'numeric','char','logical'}, 1);
tx = tall.validateMatrix(tx, 'MATLAB:cov:InputDim');
cellIn = {tx};
varargin = varargin(2:end);
%Set up default flag
NaNFlag = 'includenan';
normFlag = 0;
% Check second input if it is tall.
% If it is tall, assume it is COV(X,Y,...)
offset = 1;
if nargin > 1 
    if istall(varargin{1})
        ty = varargin{1};
        varargin = varargin(2:end);
        ty = tall.validateType(ty, mfilename, {'numeric','char','logical'}, 1);
        ty = tall.validateMatrix(ty, 'MATLAB:cov:InputDim');
        [tx, ty] = validateSameTallSize(tx, ty);
        [tx, ty] = lazyValidate(tx, ty, {@(x,y)size(x)==size(y), ...
            'MATLAB:cov:XYlengthMismatch'});
        cellIn = {tx, ty};
        offset = 2;
    end
    % The trailing inputs must not be tall.
    tall.checkNotTall(upper(mfilename), offset, varargin{:});
    numTrailingArg = length(varargin);
    if numTrailingArg == 1
        if isNonTallScalarString(varargin{1})
            NaNFlag = parseFlag(varargin{1});
        else
            if ~isnormfactor(varargin{1})
                if nargin == 2 % COV(X,Y) with non-tall Y
                    error(message('MATLAB:bigdata:array:CorrcoefCovSecondArgMustBeTall'));
                else
                    error(message('MATLAB:cov:notScalarFlag'));
                end
            end
            normFlag = varargin{1};
        end
    elseif numTrailingArg == 2
        if isNonTallScalarString(varargin{2})
            NaNFlag = parseFlag(varargin{2});
        else
            error(message('MATLAB:cov:unknownFlag'));
        end
        if ~isnormfactor(varargin{1})
            error(message('MATLAB:cov:notScalarFlag'));
        end
        normFlag = varargin{1};
    elseif numTrailingArg > 2
        error(message('MATLAB:cov:unknownFlag'));
    end 
end
end

function flag = parseFlag(flag)
if (ischar(flag) || (isstring(flag) && isscalar(flag))) && (strlength(flag) == 0)
    error(message('MATLAB:cov:unknownFlag'));
else
    option = ["omitrows", "partialrows", "includenan", "includemissing"];
    s = startsWith(option, flag, 'IgnoreCase', true);
    if all(s == false) % no match
        error(message('MATLAB:cov:unknownFlag'));
    end
    flag = option(s);
    % Partial match for nanflag (i.e. "include") is triggered for two
    % options
    if any(s([3 4]))
        flag = "includenan";
    end
end
end

function y = isnormfactor(x)
% normfactor for cov must be 0 or 1. 
y = isscalar(x) && (isnumeric(x) || islogical(x)) && (x==0 || x==1);
end
