function mlappfile(file, linenumber, column, selectLine) 
% This function is internal and may change in future releases.

% Plug-in for the opentoline function for MATLAB app files.

% Copyright 2014 - 2020, The MathWorks, Inc.

% The column input argument is optional (g1268749)
if nargin == 2
    column = 1;
    selectLine = true;
end

% The selectLine input argument is optional (g2226981)
if nargin == 3
    selectLine = false;
end

% Get AppCodeTool instance 
appCodeTool = appdesigner.internal.application.getAppCodeTool();

% Process GoToLineColumn request to open app in App Designer
try 
    appCodeTool.processGoToLineColumn(file, linenumber, column, selectLine);
catch exception
    throwAsCaller(exception);
end

end