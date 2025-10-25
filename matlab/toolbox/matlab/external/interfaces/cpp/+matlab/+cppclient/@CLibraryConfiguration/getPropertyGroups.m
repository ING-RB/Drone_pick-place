function group = getPropertyGroups(obj)
    % Provide a custom display to,
    % 1. hide process information if not present
    % 2. hide out-of-process environment variables in inprocess execution mode

    % Copyright 2022-2024 The MathWorks, Inc.

    propList = struct();
    % add all the properties to the struct from obj, except ProcessID and OutOfProcessEnvironmentVariables
    if ~isempty(obj.InterfaceLibraryPath)
        propList = struct("InterfaceLibraryPath", obj.InterfaceLibraryPath,...
            "Libraries", obj.Libraries, ...
            "Loaded", obj.Loaded, ...
            "ExecutionMode", obj.ExecutionMode);

        % add processID if available
        if obj.ProcessID ~= 0 && obj.ProcessName ~= ""
            propList.ProcessID = obj.ProcessID;
        end

        % add environment variables if execution mode is out-of-process
        if obj.ExecutionMode == 1
            propList.OutOfProcessEnvironmentVariables = obj.OutOfProcessEnvironmentVariables;
        end
    end
    group = matlab.mixin.util.PropertyGroup(propList);
end