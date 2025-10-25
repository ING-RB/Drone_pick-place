function openOutsideMatlab(paths)
    % openOutsideMatlab Opens the given filepaths outside of MATLAB using the default application specified at the OS-level
    %
    %   matlab.internal.filesystem.openOutsideMatlab(paths)
    %   Opens the given filepaths outside of MATLAB using the default application specified at the OS-level. 
    %
    
    % Copyright 2022 The MathWorks, Inc.
    paths = jsondecode(paths);
    for i = 1:length(paths)     
        pathToOpen = string(paths(i));
        if ispc
            winopen(pathToOpen)
        elseif ismac
            matlab.system.internal.executeCommand('open "' + pathToOpen + '" &');
        else
            matlab.system.internal.executeCommand('xdg-open "' + pathToOpen + '" &');
        end
    end
end