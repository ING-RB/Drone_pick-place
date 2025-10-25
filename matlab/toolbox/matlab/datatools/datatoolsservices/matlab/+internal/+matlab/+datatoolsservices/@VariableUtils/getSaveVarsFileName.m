% Calls uiputfile with a filter for MAT file, MATLAB script, or *.*, for the
% user to select the filename to save variables to.  Returns the full path
% including the filename and extension, along with the filter index which is: 1
% for MAT file, 2 for MATLAB script, or 3 for *.*.

% Copyright 2024-2025 The MathWorks, Inc.

function [saveFileName, filterIndex] = getSaveVarsFileName()
    saveFileName = '';
    filters = {...
        '*.mat', getString(message('MATLAB:datatools:workspaceFunctions:SaveFilterMAT')); ...
        '*.m',   getString(message('MATLAB:datatools:workspaceFunctions:SaveFilterM')); ...
        '*.*',   getString(message('MATLAB:datatools:workspaceFunctions:SaveFilterAll'))};
    [fn, pn, filterIndex] = uiputfile(filters, getString(message('MATLAB:uistring:filedialogs:SaveWorkspaceVariables')), "matlab");
    if ~isequal(fn, 0)
        if filterIndex == 1 && ~endsWith(fn, ".mat", "IgnoreCase", true)
            fn = fn + ".mat";
        elseif filterIndex == 2 && ~endsWith(fn, ".m", "IgnoreCase", true)
            fn = fn + ".m";
        end
        saveFileName = fullfile(pn, fn);
    end
end