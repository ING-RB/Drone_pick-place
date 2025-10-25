function opts = setvaropts(opts,varargin)

narginchk(2,inf);
if nargout == 0
    error(message('MATLAB:textio:io:NOLHS','setvaropts','setvaropts'))
end

try
    func = matlab.io.internal.functions.FunctionStore.getFunctionByName('setvaropts');
    opts = func.validateAndExecute(opts,varargin{:});
catch ME
    throw(ME);
end
end

% Copyright 2016-2023 The MathWorks, Inc.