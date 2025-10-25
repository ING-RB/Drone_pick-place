function [c,i] = max(a,b,varargin)
%

%   Copyright 2014-2024 The MathWorks, Inc.

import matlab.internal.datatypes.throwInstead;

for ii = 1:(nargin-2) % ComparisonMethod not supported.
    if matlab.internal.math.checkInputName(varargin{ii},{'ComparisonMethod'})
        error(message('MATLAB:max:InvalidAbsRealType'));
    end
end

try
    if nargin < 2 ... % max(a)
            || (nargin > 2 && isnumeric(b) && isequal(b,[])) % max(a,[],...) but not max(a,[])
        c = a;
        if nargin < 2
            if nargout <= 1
                c.millis = max(a.millis);
            else
                [c.millis,i] = max(a.millis);
            end
        else
            if nargout <= 1
                c.millis = max(a.millis,[],varargin{:});
            else
                [c.millis,i] = max(a.millis,[],varargin{:});
            end
        end
    else % max(a,b) or max(a,b,...)
        [amillis,bmillis,c] = duration.compareUtil(a,b);
        if nargout <= 1
            c.millis = max(amillis,bmillis,varargin{:});
        else
            [c.millis,i] = max(amillis,bmillis,varargin{:});
        end
    end
catch ME
    throwInstead(ME,"MATLAB:max:unknownOption","MATLAB:duration:MinMaxUnknownOption");
end
