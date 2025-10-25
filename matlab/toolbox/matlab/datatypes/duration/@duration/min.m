function [c,i] = min(a,b,varargin)
%

%   Copyright 2014-2024 The MathWorks, Inc.

import matlab.internal.datatypes.throwInstead;

for ii = 1:(nargin-2) % ComparisonMethod not supported.
    if matlab.internal.math.checkInputName(varargin{ii},{'ComparisonMethod'})
        error(message('MATLAB:min:InvalidAbsRealType'));
    end
end

try
    if nargin < 2 ... % min(a)
            || (nargin > 2 && isnumeric(b) && isequal(b,[])) % min(a,[],...) but not min(a,[])
        c = a;
        if nargin < 2
            if nargout <= 1
                c.millis = min(a.millis);
            else
                [c.millis,i] = min(a.millis);
            end
        else
            if nargout <= 1
                c.millis = min(a.millis,[],varargin{:});
            else
                [c.millis,i] = min(a.millis,[],varargin{:});
            end
        end
    else % min(a,b) or min(a,b,...)
        [amillis,bmillis,c] = duration.compareUtil(a,b);
        if nargout <= 1
            c.millis = min(amillis,bmillis,varargin{:});
        else
            [c.millis,i] = min(amillis,bmillis,varargin{:});
        end
    end
catch ME
    throwInstead(ME,"MATLAB:min:unknownOption","MATLAB:duration:MinMaxUnknownOption");
end
