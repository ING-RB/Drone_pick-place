function failedFiles = managePerms(location, type, permNames, permValues, permissionsTarget, callFromSetMethod)
%
%
%   Internal function, not to be called directly.

%   Copyright 2024 The MathWorks, Inc.

    arguments
        location {mustBeTextScalar, mustBeNonzeroLengthText}
        type (1, :) string {mustBeNonmissing};
        permNames (1, :) {mustBeText} = missing;
        permValues (1, :) logical {mustBeNumericOrLogical} = [];
        permissionsTarget (1, 1) string = missing;
        callFromSetMethod (1, 1) logical = false;
    end
    narginchk(4, 6);

    if type == ""
        error(message("MATLAB:io:filesystem:filePermissions:EmptyType"));
    end

    if ismissing(permNames)
        error(message("MATLAB:io:filesystem:filePermissions:EmptyPermissionNames"));
    end

    if isempty(permValues)
        error(message("MATLAB:io:filesystem:filePermissions:EmptyPermissionValues"));
    end

    if ~callFromSetMethod
        permNames = matlab.io.internal.filesystem.validatePermissionNames(permNames);
    end

    % Inputs must be vectors
    if ~isvector(permNames) || ~isvector(permValues)
        error(message("MATLAB:io:filesystem:filePermissions:OnlyVectorSupported"));
    end

    % if scalar logical is provided for multiple permNames, create a
    % vector of permValues replicating the supplied value
    if isscalar(permValues)
        permValues = repmat(permValues, 1, length(permNames));
    end

    % Size check
    if length(permValues) ~= length(permNames)
        error(message("MATLAB:io:filesystem:filePermissions:NamesValuesSizeMismatch"));
    end

    % Initialize the struct
    inputStruct = struct();
    for ii = 1 : numel(permNames)
        inputStruct.(permNames{ii}) = permValues(ii);
    end

    try
        if ismissing(permissionsTarget)
            failedFiles = matlab.io.internal.filesystem.modifyPerms(location, ...
                type, inputStruct);
        else
            if (type == "Folder" && permissionsTarget == "target") || ...
                    (type == "File" && permissionsTarget ~= "all") || ...
                    (type == "SymbolicLink" && any(permissionsTarget == ...
                    ["files", "folders", "symboliclinks"]))
                failedFiles.Name = location;
                if type == "File"
                    failedFiles.Cause = ...
                        message("MATLAB:io:filesystem:filePermissions:" + ...
                        "InvalidPermissionsTargetForFile", permissionsTarget).getString();
                elseif type =="Folder"
                    failedFiles.Cause = ...
                        message("MATLAB:io:filesystem:filePermissions:" + ...
                        "InvalidPermissionsTargetForFolder", permissionsTarget).getString();
                elseif type == "SymbolicLink"
                    failedFiles.Cause = ...
                        message("MATLAB:io:filesystem:filePermissions:" + ...
                        "InvalidPermissionsTargetForSymlink", permissionsTarget).getString();
                end
            else
                failedFiles = matlab.io.internal.filesystem.modifyPerms(location, ...
                    type, inputStruct, "PermissionsTarget", permissionsTarget);
            end
        end
    catch ME
        failedFiles.Name = location;
        failedFiles.Cause = ME.message;
    end
end

function mustBeText(permNames)
    missingCondition = all(~ismissing(permNames));
    notTextCondition = ~isstring(permNames) && ~ischar(permNames) && ...
        ~iscellstr(permNames) && missingCondition;
    notVectorCondition = ~isvector(permNames);
    emptyCondition = missingCondition && (isstring(permNames) && ...
        any(~strlength(permNames), "all")) || ...
        (ischar(permNames) && isempty(permNames)) || ...
        (iscellstr(permNames) && any(cellfun(@isempty, permNames), "all"));
    if notTextCondition || notVectorCondition
        error(message("MATLAB:io:filesystem:filePermissions:InvalidPermissionNames"));
    end
    if emptyCondition
        error(message("MATLAB:io:filesystem:filePermissions:EmptyPermissionNames"));
    end
end
