function n = numunique(varargin) %#ok<STOUT>
%numunique Number of unique values. Not supported for tall arrays.

% Copyright 2024 The MathWorks, Inc.

error(message("MATLAB:bigdata:array:FcnNotSupported", "numunique"));

end