classdef FileSystemEntryPermissions < matlab.mixin.Heterogeneous ...
        & matlab.mixin.CustomDisplay
%

%   Copyright 2024-2025 The MathWorks, Inc.

    properties (SetAccess = protected)
        AbsolutePath (:, :) string
    end

    properties (Dependent)
        Readable (:, :) logical
        Writable (:, :) logical
    end

    properties (Dependent, SetAccess = immutable)
        Type (:, :) matlab.io.FileSystemEntryType
    end

    methods
        function obj = FileSystemEntryPermissions(locations)
            arguments
                locations (:, :) string = missing;
            end
            resolvedPaths = matlab.io.internal.filesystem.resolvePath(locations, ...
                ResolveSymbolicLinks=false);
            tempObj(numel(resolvedPaths), 1) = obj;
            for ii = 1 : numel(resolvedPaths)
                tempObj(ii).AbsolutePath = resolvedPaths(ii).ResolvedPath;
            end
            tempObj = reshape(tempObj, size(resolvedPaths));
            obj = tempObj;
        end
    end

    % Getters block
    methods
        function readValue = get.Readable(obj)
            type = obj.Type;
            if type == "None"
                % could not find file system entry
                readValue = false;
            else
                S = matlab.io.internal.filesystem.getPerms(obj.AbsolutePath, ...
                    string(type), "Readable");
                readValue = S.Readable;
            end
        end

        function writeValue = get.Writable(obj)
            type = obj.Type;
            if type == "None"
                % could not find file system entry
                writeValue = false;
            else
                S = matlab.io.internal.filesystem.getPerms(obj.AbsolutePath, ...
                    string(type), "Writable");
                writeValue = S.Writable;
            end
        end

        function type = get.Type(obj)
            S = matlab.io.internal.filesystem.resolvePath(obj.AbsolutePath, ...
                ResolveSymbolicLinks=false);
            type = matlab.io.internal.filesystem.convertStringToFileSystemEntryType(S.Type);
        end
    end

    % Setters block
    methods
        function obj = set.Readable(obj, value)
            absPath = char(obj.AbsolutePath);
            validURL = matlab.io.internal.vfs.validators.isIRI(absPath);
            if validURL && matlab.io.internal.vfs.validators.GetScheme(absPath) ~= "file"
                error(message("MATLAB:io:filesystem:filePermissions:CannotModifyCloudPermissions"));
            else
                matlab.io.internal.filesystem.modifyPerms(obj.AbsolutePath, ...
                    string(obj.Type), struct("Readable", value));
            end
        end

        function obj = set.Writable(obj, value)
            absPath = char(obj.AbsolutePath);
            validURL = matlab.io.internal.vfs.validators.isIRI(absPath);
            if validURL && matlab.io.internal.vfs.validators.GetScheme(absPath) ~= "file"
                error(message("MATLAB:io:filesystem:filePermissions:CannotModifyCloudPermissions"));
            else
                matlab.io.internal.filesystem.modifyPerms(obj.AbsolutePath, ...
                    string(obj.Type), struct("Writable", value));
            end
        end
    end

    methods (Sealed)
        function varargout = setPermissions(objArr, permissionNames, permissionValues, options)
            arguments
                objArr (:, :) matlab.io.FileSystemEntryPermissions
                permissionNames (1, :) string
                permissionValues (1, :) logical
                options.PermissionsTarget (1, 1) string = missing
                options.UseParallel (1, :) {mustBeDoubleOrLogical} = false
            end

            import matlab.io.internal.filesystem.validatePermissionNames;
            if isscalar(objArr) && isa(objArr, "matlab.io.CloudPermissions")
                error(message("MATLAB:io:filesystem:filePermissions:CannotModifyCloudPermissions"));
            end

            if ~isscalar(permissionNames) && ~isscalar(permissionValues)
                % check that both vectors have the same length
                if numel(permissionNames) ~= numel(permissionValues)
                    error(message("MATLAB:io:filesystem:filePermissions:NamesValuesSizeMismatch"));
                end
            end

            % Validate the permission names
            permissionNames = validatePermissionNames(permissionNames);

            permissionsTarget = validatePermissionsTarget(options.PermissionsTarget);
            if options.UseParallel
                % get workers for parallel writing
                if matlab.internal.parallel.isPCTInstalled()
                    % use Thread pool for performance
                    poolObj = gcp('nocreate');
                    if isempty(poolObj)
                        poolObj = parpool("Threads");
                    end
                else
                    poolObj = [];
                end
                if ~isempty(poolObj)
                    M = poolObj.NumWorkers;
                else
                    M = 1;
                end

                failures = [];
                parfor (ii = 1 : numel(objArr), M)
                    result = matlab.io.internal.filesystem.managePerms(...
                        objArr(ii).AbsolutePath, objArr(ii).Type, ...
                        permissionNames, permissionValues, permissionsTarget, true);
                    failures = [failures; result];
                end
            else
                failures = [];
                for ii = 1 : numel(objArr)
                    result = matlab.io.internal.filesystem.managePerms(...
                        objArr(ii).AbsolutePath, objArr(ii).Type, ...
                        permissionNames, permissionValues, permissionsTarget, true);
                    failures = [failures; result]; %#ok<AGROW>
                end
            end
            if nargout
                varargout{1} = failures;
            else
                if ~isempty(failures)
                    namesAndcauses = strings(numel(failures), 1);
                    for ii = 1 : numel(failures)
                        namesAndcauses(ii) = string(failures(ii).Name + ...
                            ": " + failures(ii).Cause);
                    end
                    error(message("MATLAB:io:filesystem:filePermissions:UnableToSetPermissionsError", ...
                        strjoin(namesAndcauses, newline)));
                end
            end
        end

        function varargout = getPermissions(objArr, propNames)
            arguments
                objArr (:, :) matlab.io.FileSystemEntryPermissions
                propNames (1, :) string = missing
            end
            import matlab.io.FileSystemEntryPermissionsPropertyNamesAndTypes;
            import matlab.io.internal.filesystem.convertLogicalToPermissions;
            basicClassProps = FileSystemEntryPermissionsPropertyNamesAndTypes.BasicPropNames;
            unixExtendedProps = FileSystemEntryPermissionsPropertyNamesAndTypes.ExtendedUnixPermNames;

            % maintain an indicator variable that properties were
            % supplied as input
            initPropNamesMissing = false;
            if ismissing(propNames)
                % No properties were passed in - return values for all
                % properties as is relevant for filesystem
                numelUnixPerms = false;
                propNames = basicClassProps;
                % check if any location is Unix-based
                if isunix
                    for ii = 1 : numel(objArr)
                        obj = objArr(ii);
                        if isa(obj, "matlab.io.UnixPermissions")
                            numelUnixPerms = true;
                            break;
                        end
                    end
                end
                if numelUnixPerms
                    propNames = [basicClassProps, unixExtendedProps];
                end
                initPropNamesMissing = true;
            end

            propsNamesAndTypes = matlab.io.FileSystemEntryPermissionsPropertyNamesAndTypes();
            varNamesAndTypes = propsNamesAndTypes.allPropsNamesAndTypes();
            if ~initPropNamesMissing && (any(contains(propNames, propsNamesAndTypes.AllPermNames)) && ...
                    any(contains(propNames, propsNamesAndTypes.BasicClassPropNames)))
                % Combination of permissions and other properties
                permNames = intersect(propNames, propsNamesAndTypes.AllPermNames());
            else
                % Only permissions
                permNames = propNames;
            end

            % Create output table with appropriate variable names and types
            varTypes = [varNamesAndTypes(propNames(:))];
            T = table(Size=[numel(objArr) numel(propNames)], ...
                VariableNames=propNames, VariableTypes=varTypes);

            for ii = 1 : numel(objArr)
                obj = objArr(ii);
                absPath = obj.AbsolutePath;
                type = string(obj.Type);
                if matlab.io.internal.vfs.validators.hasIriPrefix(absPath) ...
                        && initPropNamesMissing && ...
                        (matlab.io.internal.vfs.validators.GetScheme(absPath) ~= "file")
                    % remote path only has 2 permissions
                    if type == "None"
                        % cannot find file system entry
                        propVals = struct("Readable", string.empty(), ...
                            "Writable", string.empty());
                    else
                        propVals = matlab.io.internal.filesystem.getPerms(absPath, ...
                            type, propsNamesAndTypes.BasicPermNames);
                    end
                else
                    % use input permissions
                    if type == "None"
                        % cannot find file system entry
                        propVals = struct();
                        for index = 1 : numel(permNames)
                            propVals.(permNames(index)) = missing;
                        end
                    else
                        propVals = matlab.io.internal.filesystem.getPerms(absPath, ...
                            type, permNames);
                    end
                end

                % get fields that exist on this object
                fields = fieldnames(obj);
                % get fields that exist on permissions object
                permFields = fieldnames(propVals);
                for jj = 1 : numel(propNames)
                    if any(contains(fields, propNames(jj)))
                        if any(contains(permFields, propNames(jj)))
                            % this is a permission, assign from output
                            % already computed
                            propVal = propVals.(propNames(jj));
                            isPermName = true;
                        else
                            % this is not a permission, dynamic computation
                            propVal = obj.(propNames(jj));
                            isPermName = false;
                        end
                        if isa(propVal, "logical")
                            % For logical permissions, we need to check
                            % whether they exist for this location. If not,
                            % set the value to NA.
                            if propNames(jj) == "Type"
                                T(ii, :).(propNames(jj)) = type;
                            else
                                T(ii, :).(propNames(jj)) = propVal;
                            end
                        else
                            if isPermName && type == "None"
                                % cannot find file system entry
                                if propNames(jj) == "Type"
                                    T(ii, :).(propNames(jj)) = type;
                                else
                                    T(ii, :).(propNames(jj)) = false;
                                end
                            else
                                T(ii, :).(propNames(jj)) = propVal;
                            end
                        end
                    else
                        % This permission does not exist for this
                        % filesystem, set to NA.
                        T(ii, :).(propNames(jj)) = false;
                    end
                end
            end
            if nargout == 0
                disp(T);
            else
                varargout = {T};
            end
        end
    end

    methods (Sealed, Access = protected)
        function displayNonScalarObject(objArr)
            % Display for heterogeneous arrays
            import matlab.io.FileSystemEntryPermissionsPropertyNamesAndTypes;
            import matlab.io.internal.filesystem.*;
            numelUnixPerms = false;

            % check if any location is Unix-based
            for ii = 1 : numel(objArr)
                obj = objArr(ii);
                if isa(obj, "matlab.io.UnixPermissions")
                    numelUnixPerms = true;
                    break;
                end
            end

            % Set up variable names and types for table
            propNamesAndTypesObj = FileSystemEntryPermissionsPropertyNamesAndTypes();
            if ~numelUnixPerms
                varNames = propNamesAndTypesObj.BasicPropNames;
                varTypes = propNamesAndTypesObj.DisplayBasicPropTypes;
            else
                varNames = propNamesAndTypesObj.AllPropNames;
                varTypes = propNamesAndTypesObj.DisplayAllPropTypes;
            end

            T = table(Size=[numel(objArr) numel(varNames)], VariableNames=varNames, ...
                VariableTypes=varTypes);
            for index = 1 : numel(objArr)
                obj = objArr(index);
                absPath = obj.AbsolutePath;
                type = string(obj.Type);
                reducedPath = obj.AbsolutePath;

                % Reduce the length of absolute path for display purposes
                if strlength(reducedPath) > propNamesAndTypesObj.DisplayLength
                    reducedPath = reverse(extractBefore(reverse(reducedPath), ...
                        propNamesAndTypesObj.DisplayLength));
                    % find filesep in path
                    if isa(obj, "matlab.io.CloudPermissions") || ...
                            isa(obj, "matlab.io.UnixPermissions") || ...
                            matlab.io.internal.vfs.validators.hasIriPrefix(reducedPath)
                        pathSep = "/";
                    elseif isa(obj, "matlab.io.FileSystemEntryPermissions")
                        pathSep = filesep;
                    else
                        pathSep = "\";
                    end
                    reducedPath = "..." + pathSep + extractAfter(reducedPath, pathSep);
                end
                T(index, :).AbsolutePath = reducedPath;
                T(index, :).Type = type;
                isUnixPerms = isa(obj, "matlab.io.UnixPermissions") && isunix;

                % If Unix, then we can get all permissions
                if isUnixPerms
                    if type == "None"
                        % file system entry cannot be found
                        for ii = 1 : numel(propNamesAndTypesObj.AllPermNames)
                            perms.(propNamesAndTypesObj.AllPermNames(ii)) = missing;
                        end
                    else
                        perms = matlab.io.internal.filesystem.getPerms(absPath, ...
                            type, propNamesAndTypesObj.AllPermNames);
                    end
                else
                    % Not Unix, limited to basic permissions only
                    if type == "None"
                        % file system entry cannot be found
                        for ii = 1 : numel(propNamesAndTypesObj.BasicPermNames)
                            perms.(propNamesAndTypesObj.BasicPermNames(ii)) = missing;
                        end
                    else
                        perms = matlab.io.internal.filesystem.getPerms(absPath, ...
                            type, propNamesAndTypesObj.BasicPermNames);
                    end
                end
                if ismissing(perms.Readable)
                    T(index, :).Readable = matlab.io.PermissionsValues.missing;
                else
                    T(index, :).Readable = convertLogicalToPermissions("Readable", ...
                        perms.Readable, obj);
                end

                if ismissing(perms.Writable)
                    T(index, :).Writable = matlab.io.PermissionsValues.missing;
                else
                    T(index, :).Writable = convertLogicalToPermissions("Writable", ...
                        perms.Writable, obj);
                end

                if (numel(varNames) > 4)
                    if isUnixPerms
                        T = setUnixOnlyPermsForTabularDisplay(obj, T, index, perms);
                    else
                        % Not Unix, all non-basic permissions are set to NA
                        perms = struct("UserExecute", false, "GroupRead", false, ...
                            "GroupWrite", false, "GroupExecute", false, ...
                            "OtherRead", false, "OtherWrite", false, ...
                            "OtherExecute", false);
                        T = setUnixOnlyPermsForTabularDisplay(obj, T, index, perms);
                    end
                end
            end
            displayTabularObject(objArr, T);
        end

        function displayScalarObject(obj)
            % Display for scalar object of class matlab.io.UnixPermissions,
            % matlab.io.WindowsPermissions, or matlab.io.CloudPermissions
            import matlab.io.internal.filesystem.*;
            % Set up variable names and types for table
            propNamesAndTypesObj = matlab.io.FileSystemEntryPermissionsPropertyNamesAndTypes();
            isUnixPerms = isa(obj, "matlab.io.UnixPermissions") && isunix;
            if isUnixPerms
                varNames = propNamesAndTypesObj.AllPropNames;
                varTypes = propNamesAndTypesObj.DisplayAllPropTypes;
            else
                varNames = propNamesAndTypesObj.BasicPropNames;
                varTypes = propNamesAndTypesObj.DisplayBasicPropTypes;
            end

            T = table(Size=[1 numel(varNames)], VariableNames=varNames, ...
                VariableTypes=varTypes);
            absPath = obj.AbsolutePath;
            reducedPath = obj.AbsolutePath;
            type = string(obj.Type);

            % Reduce the length of absolute path for display purposes
            if strlength(reducedPath) > propNamesAndTypesObj.DisplayLength
                reducedPath = reverse(extractBefore(reverse(reducedPath), ...
                    propNamesAndTypesObj.DisplayLength));
                if isa(obj, "matlab.io.CloudPermissions")
                    % use "/" for URLs
                    pathSep = "/";
                else
                    % use filesystem-specific path separator for local
                    % paths
                    pathSep = filesep;
                end
                reducedPath = "..." + pathSep + extractAfter(reducedPath, pathSep);
            end
            T(1, :).AbsolutePath = reducedPath;
            T(1, :).Type = type;
            % If Unix, then we can get all permissions
            if isUnixPerms
                if type == "None"
                    % file system entry cannot be found
                    perms = struct();
                    for ii = 1 : numel(propNamesAndTypesObj.AllPermNames)
                        perms.(propNamesAndTypesObj.AllPermNames(ii)) = missing;
                    end
                else
                    perms = matlab.io.internal.filesystem.getPerms(absPath, ...
                        type, propNamesAndTypesObj.AllPermNames);
                end
            else
                % Not Unix, limited to basic permissions only
                if type == "None"
                    % file system entry cannot be found
                    perms = struct();
                    for ii = 1 : numel(propNamesAndTypesObj.BasicPermNames)
                        perms.(propNamesAndTypesObj.BasicPermNames(ii)) = missing;
                    end
                else
                    perms = matlab.io.internal.filesystem.getPerms(absPath, ...
                        type, propNamesAndTypesObj.BasicPermNames);
                end
            end

            if ismissing(perms.Readable)
                T(1, :).Readable = matlab.io.PermissionsValues.missing;
            else
                T(1, :).Readable = convertLogicalToPermissions("Readable", ...
                    perms.Readable, obj);
            end

            if ismissing(perms.Writable)
                T(1, :).Writable = matlab.io.PermissionsValues.missing;
            else
                T(1, :).Writable = convertLogicalToPermissions("Writable", ...
                    perms.Writable, obj);
            end

            if (numel(varNames) > 4)
                T = setUnixOnlyPermsForTabularDisplay(obj, T, 1, perms);
            end

            displayTabularObject(obj, T);
        end

        function displayTabularObject(obj, T)
            % Custom display function
            className = class(obj);
            dims = matlab.internal.display.dimensionString(obj);
            if matlab.internal.display.isHot
                fontType = 'style="font-weight:bold"';
                out = [dims, ' <a href="matlab:helpPopup ' ,class(obj), ...
                    '" ', fontType, '>', className, '</a>'];
            else
                out = [dims,' ',className];
            end
            out = [char(32), char(32), out];
            fprintf(out); 
            fprintf(newline); fprintf(newline);

            % Render the table display into a string.
            fh = feature('hotlinks');
            if fh
                disp(T);
            else
                % For no desktop, use hotlinks off on evalc to get rid of
                % xml attributes for display, like, <strong>Var1</strong>, etc.
                disp(evalc('feature hotlinks off; disp(T);'));
                feature('hotlinks', fh);
            end
        end
    end
end

function matchedStr = validatePermissionsTarget(target)
    if ~ismissing(target)
        matchedStr = validatestring(target, ["all", "files", "folders", ...
            "symboliclinks", "target"], ...
            "matlab.io.FileSystemEntryPermissions/set");
    else
        matchedStr = missing;
    end
end

function T = setUnixOnlyPermsForTabularDisplay(obj, T, index, perms)
    import matlab.io.internal.filesystem.convertLogicalToPermissions;
    T(index, :).UserExecute = convertLogicalToPermissions(...
        "UserExecute", perms.UserExecute, obj);
    T(index, :).GroupRead = convertLogicalToPermissions(...
        "GroupRead", perms.GroupRead, obj);
    T(index, :).GroupWrite = convertLogicalToPermissions(...
        "GroupWrite", perms.GroupWrite, obj);
    T(index, :).GroupExecute = convertLogicalToPermissions(...
        "GroupExecute", perms.GroupExecute, obj);
    T(index, :).OtherRead = convertLogicalToPermissions(...
        "OtherRead", perms.OtherRead, obj);
    T(index, :).OtherWrite = convertLogicalToPermissions(...
        "OtherWrite", perms.OtherWrite, obj);
    T(index, :).OtherExecute = convertLogicalToPermissions(...
        "OtherExecute", perms.OtherExecute, obj);
end


function mustBeDoubleOrLogical(useParallel)
    if ~isnumeric(useParallel) && ~islogical(useParallel)
        error(message("MATLAB:io:filesystem:filePermissions:InvalidValueForUseParallel"));
    end
end
