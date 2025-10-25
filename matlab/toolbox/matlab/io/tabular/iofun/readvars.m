function varargout = readvars(filename,varargin)

try
    if any(cellfun(@(arg) isa(arg,"matlab.io.ImportOptions"),varargin),'all')
        error(message('MATLAB:textio:io:OptsSecondArg','readvars'))
    end

    func = matlab.io.internal.functions.FunctionStore.getFunctionByName("readvars");
    C = onCleanup(@()func.WorkSheet.clear());
    [varargout{1:nargout}] = func.validateAndExecute(filename,varargin{:});
catch ME
    throw(ME);
end

end
%   Copyright 2018-2024 The MathWorks, Inc.
