function varargout = convertCharsToStrings(varargin) %#ok<STOUT>
%convertCharsToStrings Convert character arrays to string arrays and leave
%others unaltered. Not supported for tall arrays.

% Copyright 2023 The MathWorks, Inc.

error(message("MATLAB:bigdata:array:ConvertCharsNotSupported", upper(mfilename)))

end