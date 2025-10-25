function y = createArray(varargin) %#ok<STOUT>
%createArray Create an array of a specified size and class. Not supported for tall arrays.

% Copyright 2023 The MathWorks, Inc.


error(message("MATLAB:bigdata:array:FcnNotSupported", "createArray"));

end