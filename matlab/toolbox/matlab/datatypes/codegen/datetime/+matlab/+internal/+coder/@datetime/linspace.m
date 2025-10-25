function c = linspace(a,b,n) %#codegen
%LINSPACE Create equally-spaced sequence of datetimes.
%   C = LINSPACE(A,B) generates a row vector of 100 equally-spaced datetimes
%   between A and B. A and B are scalar datetimes. A or B can also be a datetime
%   string.
%
%   C = LINSPACE(A,B,N) generates N points between A and B. For N = 1, LINSPACE
%   returns B.

%   Copyright 2019 The MathWorks, Inc.

if nargin < 3, n = 100; end

[aData,bData,c] = datetime.compareUtil(a,b);

coder.internal.assert(isscalar(aData) && isscalar(bData) && isscalar(n),'MATLAB:datetime:linspace:NonScalarInputs');

% Call linspace from 0 to (bData-aData) and then add aData to ensure correct precision of the
% datetimes is maintained
cData = matlab.internal.coder.doubledouble.plus(...
    aData,linspace(0,matlab.internal.coder.doubledouble.minus(bData,aData),n));

% Ensure that last element is bData when linspace returns a non-empty array
if ~isempty(cData), cData(end) = bData; end

c.data = cData;