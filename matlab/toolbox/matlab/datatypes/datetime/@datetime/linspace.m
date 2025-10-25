function c = linspace(a,b,n)
%

%   Copyright 2014-2024 The MathWorks, Inc.

if nargin < 3, n = 100; end

[aData,bData,c] = datetime.compareUtil(a,b);

if ~isscalar(aData) || ~isscalar(bData) || ~isscalar(n)
    error(message('MATLAB:datetime:linspace:NonScalarInputs'));
end

% Call linspace from 0 to (bData-aData) and then add aData to ensure correct precision of the
% datetimes is maintained
cData = matlab.internal.datetime.datetimeAdd(...
    aData,linspace(0,matlab.internal.datetime.datetimeSubtract(bData,aData),n));

% Ensure that last element is bData when linspace returns a non-empty array
if ~isempty(cData), cData(end) = bData; end

c.data = cData;
