function tf = issortedrows(this,varargin) %#codegen
%ISSORTEDROWS   Check if matrix rows are sorted

%   Copyright 2020 The MathWorks, Inc.

for ii = 1:(nargin-2) % ComparisonMethod not supported.
    coder.internal.errorIf(matlab.internal.coder.datatypes.checkInputName(varargin{ii},{'ComparisonMethod'}),...
        'MATLAB:sort:InvalidAbsRealType',class(this));
end
tf = issortedrows(this.millis,varargin{:});
