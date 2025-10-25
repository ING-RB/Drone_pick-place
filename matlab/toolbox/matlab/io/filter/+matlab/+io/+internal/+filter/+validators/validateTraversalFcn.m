function validateTraversalFcn(fcn)
%validateTraversalFcn   validates the function_handle used for RowFilter
%   tree traversal.
%
%   Currently, this requires one input and one output.

%   Copyright 2021 The MathWorks, Inc.

    arguments
        fcn (1, 1) function_handle
    end

    if nargin(fcn) == 0 || nargout(fcn) == 0
        error(message('MATLAB:io:filter:filter:InvalidTraverseFcn'));
    end
end