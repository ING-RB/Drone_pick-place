function t = issortedrows(a,varargin) %#codegen
%ISSORTEDROWS   Check if matrix rows are sorted

%   Copyright 2020 The MathWorks, Inc.

coder.internal.prefer_const(varargin);

% Set the code value for undefined elements to NaN after changing to double
acodes = a.codes;
dcodes = double(acodes);
dcodes(acodes==categorical.undefCode) = NaN;

for ii = 1:(nargin-2) % ComparisonMethod not supported.
    coder.internal.errorIf(matlab.internal.coder.datatypes.checkInputName(varargin{ii},{'ComparisonMethod'}),...
        'MATLAB:sort:InvalidAbsRealType',class(a));
end

t = issortedrows(dcodes,varargin{:});

