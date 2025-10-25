function [c,i] = min(a,b,varargin) %#codegen
%MIN Find minimum of durations.

%   Copyright 2020-2021 The MathWorks, Inc.

coder.internal.implicitExpansionBuiltin;

for ii = 1:(nargin-2) % ComparisonMethod not supported.
    coder.internal.errorIf(matlab.internal.coder.datatypes.checkInputName(varargin{ii},{'ComparisonMethod'}),'MATLAB:min:InvalidAbsRealType');
end

if nargin < 2 ... % min(a)
        || (nargin > 2 && isnumeric(b) && isequal(b,[])) % min(a,[],...) but not min(a,[])
    
    c = duration(matlab.internal.coder.datatypes.uninitialized);
    c.fmt = a.fmt;
    
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
