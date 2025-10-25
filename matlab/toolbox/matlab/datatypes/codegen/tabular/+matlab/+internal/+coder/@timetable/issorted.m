function tf = issorted(tt,rowsFlag,varargin) %#codegen
%ISSORTED TRUE for a sorted timeable.

%   Copyright 2020 The MathWorks, Inc.

coder.internal.prefer_const(rowsFlag,varargin);

if nargin > 1
    % only 'rows' is accepted
    coder.internal.errorIf(nargin > 2 || ~matlab.internal.coder.datatypes.isScalarText(rowsFlag) ...
        || ~all(strncmpi('rows', rowsFlag, max(1,length(rowsFlag)))),...
        'MATLAB:timetable:issorted:DimArgNotAccepted');
end

tf = issorted(tt.rowDim.labels);