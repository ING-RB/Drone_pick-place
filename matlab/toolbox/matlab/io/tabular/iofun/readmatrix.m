function A = readmatrix(filename,varargin)

try
    if any(cellfun(@(arg) isa(arg,"matlab.io.ImportOptions"),varargin),'all')
        error(message('MATLAB:textio:io:OptsSecondArg','readmatrix'))
    end
    func = matlab.io.internal.functions.FunctionStore.getFunctionByName('readmatrix');
    C = onCleanup(@()func.WorkSheet.clear());
    A = func.validateAndExecute(filename,varargin{:});
catch ME
    throw(ME);
end

%    Copyright 2018-2024 The MathWorks, Inc.
