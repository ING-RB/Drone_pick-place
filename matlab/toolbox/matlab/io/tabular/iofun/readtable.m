function t = readtable(filename,varargin)

if any(cellfun(@(arg) isa(arg,"matlab.io.ImportOptions"),varargin),'all')
    error(message('MATLAB:textio:io:OptsSecondArg','readtable'))
end

[varargin{1:2:end}] = convertStringsToChars(varargin{1:2:end});
names = varargin(1:2:end);

try
    if any(strcmpi(names,"Format"))
        t = matlab.io.internal.legacyReadtable(filename,varargin);
    else
        func = matlab.io.internal.functions.FunctionStore.getFunctionByName("readtable");
        C = onCleanup(@()func.WorkSheet.clear());
        t = func.validateAndExecute(filename,varargin{:});
    end
catch ME
    throw(ME)
end

% Copyright 2012-2024 The MathWorks, Inc.
