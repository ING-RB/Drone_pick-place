function t = issortedrows(a,varargin)
%

%   Copyright 2016-2024 The MathWorks, Inc.

% Set the code value for undefined elements to NaN after changing to double
acodes = a.codes;
dcodes = double(acodes);
dcodes(acodes==categorical.undefCode) = NaN;

for ii = 1:(nargin-2) % ComparisonMethod not supported.
    if matlab.internal.math.checkInputName(varargin{ii},{'ComparisonMethod'})
        error(message('MATLAB:sort:InvalidAbsRealType',class(a)));
    end
end

t = issortedrows(dcodes,varargin{:});

