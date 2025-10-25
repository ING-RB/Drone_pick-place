% Calls save or matlab.io.saveVariablesToScript if there are variables in the
% workspace

% Copyright 2020-2024 The MathWorks, Inc.

function saveWorkspace()
    w = evalin("debug", "who");
    if ~isempty(w)
        [saveFileName, filterIndex] = internal.matlab.datatoolsservices.VariableUtils.getSaveVarsFileName;
        if ~isempty(saveFileName)
            if filterIndex == 2
                % User specifically select MATLAB script
                cmd = "matlab.io.saveVariablesToScript('" + saveFileName + "')";
            else
                % User filtered on MAT or *.*, either way we create a MAT file
                % by default
                cmd = "save('" + saveFileName + "')";
            end

            try
                evalin("debug", cmd);
            catch ex
                errordlg(string(message("MATLAB:datatools:workspaceFunctions:SaveErrorMessage", ex.message)), ...
                    string(message("MATLAB:datatools:workspaceFunctions:SaveErrorTitle")));
            end
        end
    end
end