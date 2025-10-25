function tf = issorted(tt,rowsFlag,varargin)
%

%   Copyright 2016-2024 The MathWorks, Inc.

import matlab.internal.datatypes.isScalarText

if nargin > 1
    if nargin > 2 || ~isScalarText(rowsFlag) || ~strncmpi(rowsFlag,'rows',max(1,length(rowsFlag))) % only 'rows' is accepted
        error(message('MATLAB:timetable:issorted:DimArgNotAccepted'));
    end
end

tf = issorted(tt.rowDim.labels);

