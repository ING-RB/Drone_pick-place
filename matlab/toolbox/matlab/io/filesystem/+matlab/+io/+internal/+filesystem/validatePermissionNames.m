function permissionNames = validatePermissionNames(permissionNames)
%

%   Copyright 2024 The MathWorks, Inc.

    arguments
        permissionNames (1, :) string 
    end
    obj = matlab.io.FileSystemEntryPermissionsPropertyNamesAndTypes();
    for ii = 1 : numel(permissionNames)
        if isunix
            permissionNames(ii) =  compareInputPermNamesWithAvailablePermSet(...
                permissionNames(ii), obj.AllPermNames, obj.AllPropNames);
        else
            permissionNames(ii) = compareInputPermNamesWithAvailablePermSet(...
                permissionNames(ii), obj.BasicPermNames, obj.BasicPropNames);
        end
    end
end

function permName = compareInputPermNamesWithAvailablePermSet(permName, permSet, propSet)
    import matlab.io.FileSystemEntryPermissionsPropertyNamesAndTypes;
    permExistsIndex = ~startsWith(permSet, permName);
    if all(permExistsIndex)
        if all(~contains(propSet, permName))
            error(message("MATLAB:io:filesystem:filePermissions:UnknownProperty", ...
                permName, char(strjoin(...
                FileSystemEntryPermissionsPropertyNamesAndTypes.getModifiablePermNames, ', '))));
        else
            error(message("MATLAB:io:filesystem:filePermissions:CannotModifyAbsPathOrType"));
        end
    elseif sum(~permExistsIndex) > 1
        error(message("MATLAB:io:filesystem:filePermissions:AmbiguousPermissionName", ...
            permName));
    else
        permName = permSet(~permExistsIndex);
    end
end
