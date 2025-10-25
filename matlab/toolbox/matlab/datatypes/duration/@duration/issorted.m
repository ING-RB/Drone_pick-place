function tf = issorted(this,varargin)
%

%   Copyright 2014-2024 The MathWorks, Inc.

for ii = 1:(nargin-2) % ComparisonMethod not supported.
    if matlab.internal.math.checkInputName(varargin{ii},{'ComparisonMethod'})
        error(message('MATLAB:sort:InvalidAbsRealType',class(this)));
    end
end
tf = issorted(this.millis,varargin{:});
