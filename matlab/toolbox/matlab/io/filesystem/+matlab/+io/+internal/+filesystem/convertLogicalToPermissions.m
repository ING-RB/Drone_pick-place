function permission = convertLogicalToPermissions(permissionName, permissionValue, permissionObj)
%

%   Copyright 2024 The MathWorks, Inc.

    arguments
        permissionName (1, 1) string
        permissionValue (1, 1) {isLogicalOrMissing}
        permissionObj (1, 1) matlab.io.FileSystemEntryPermissions
    end

    import matlab.io.PermissionsValues;
    if ~isa(permissionObj, "matlab.io.UnixPermissions") && ...
            any(permissionName == ["UserExecute", "GroupRead", "GroupWrite", ...
            "GroupExecute", "OtherRead", "OtherWrite", "OtherExecute"])
        permission = PermissionsValues.NA;
        return;
    end
    if ismissing(permissionValue)
        permission = PermissionsValues.missing;
    elseif permissionValue
        permission = PermissionsValues.true;
    else
        permission = PermissionsValues.false;
    end
end

function tf = isLogicalOrMissing(permissionValue)
    tf = ismissing(permissionValue) || islogical(permissionValue);
end
