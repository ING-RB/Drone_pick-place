function [c,i] = max(a,b,varargin) %#codegen
%MAX Find maximum of durations.

%   Copyright 2020-2021 The MathWorks, Inc.

coder.internal.implicitExpansionBuiltin;

for ii = 1:(nargin-2) % ComparisonMethod not supported.
    coder.internal.errorIf(matlab.internal.coder.datatypes.checkInputName(varargin{ii},{'ComparisonMethod'}),'MATLAB:max:InvalidAbsRealType');
end

if nargin < 2 ... % max(a)
        || (nargin > 2 && isnumeric(b) && isequal(b,[])) % max(a,[],...) but not max(a,[])
    
    c = duration(matlab.internal.coder.datatypes.uninitialized);
    c.fmt = a.fmt;
    
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
