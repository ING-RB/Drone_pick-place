classdef FileFix
    % This class represents a series of fixes which must ALL be performed
    % to make a file runnable. Types and Commands are string arrays, and
    % each element represents a separate step in the fix.
    %
    %   Types    - string array of fix types
    %   Commands - corresponding string array of commands to eval

    % Copyright 2023-2024 The MathWorks, Inc.

    properties
        Types
        Commands
    end

    methods
        function obj = FileFix(types, filepath, packageID, packageRoot)
            arguments
                types matlab.lang.internal.run.FixType {mustBeRowVector}
                filepath (1,1) string
                packageID (1,1) string
                packageRoot (1,1) string
            end

            obj.Types = sort(removeRedundantTypes(types));
            obj.Commands = createFixCommands(obj.Types, filepath, packageID, packageRoot);
        end
    end
end


% Helper functions

function mustBeRowVector(a)
    if ~isrow(a)
        eid = 'FileFix:TypesNotRowVector';
        msg = 'Fix types must be provided as a row vector.';
        throwAsCaller(MException(eid,msg))
    end
end

function mustBeMissingOrLogical(a)
    if ~ismissing(a) && ~islogical(a)
        eid = 'FileFix:PackageIsModularInvalidType';
        msg = 'packageIsModular flag must be missing or logical.';
        throwAsCaller(MException(eid,msg))
    end
end


function types = removeRedundantTypes(types)
    import matlab.lang.internal.run.*
    if ismember(FixType.CD, types)
        types(types == FixType.AddFolderToPath) = [];
        types(types == FixType.AddPackageToPath) = [];
    end
    if ismember(FixType.InstallPackage, types)
        types(types == FixType.AddPackageToPath) = [];
    end
    types = unique(types);
end


function fixCommands = createFixCommands(fixTypes, filepath, packageID, packageRoot)
    fixCommands = strings(size(fixTypes));
    for k = 1:length(fixTypes)
        fixCommands(k) = createCommand(fixTypes(k), filepath, packageID, packageRoot);
    end
end


function fixCommand = createCommand(fixType, filepath, packageID, packageRoot)
    import matlab.lang.internal.run.*

    switch fixType
        case FixType.CD
            parentFolder = fileparts(filepath);
            folderToUse = removeSpecialFolders(parentFolder);
            fixCommand = strcat("cd('", folderToUse, "');");

        case FixType.AddFolderToPath
            parentFolder = fileparts(filepath);
            folderToUse = removeSpecialFolders(parentFolder);
            fixCommand = strcat("addpath('", folderToUse, "');");

        case FixType.AddPackageToPath
            packageInfo = matlab.mpm.internal.info(packageID);
            if ~isscalar(packageInfo)
                % Problem getting installed package info
                fixCommand = missing;
                return;
            end
            isModular = feature('packages') && packageInfo.Modular;
            fixCommand = createAddPackageToPathCommand(isModular, ...
                packageInfo.InstallationLocation, packageInfo.PublicFolders);

        case FixType.InstallPackage
            fixCommand = strcat("mpminstall('", packageRoot, ...
                "',InPlace=true,Prompt=false,Verbosity='quiet',PathPosition='begin');");

        otherwise
            % Unhandled FixType
            fixCommand = missing;
    end
end


function folderToUse = removeSpecialFolders(folder)
    [pathName, folderName] = folderparts(folder);
    while ~isempty(folderName) && (startsWith(folderName, "+") || startsWith(folderName, "@"))
        [pathName, folderName] = folderparts(pathName);
    end
    folderToUse = fullfile(pathName, folderName);
end


function [pathName, folderName] = folderparts(folder)
    [pathName, folderName, folderNameAfterDot] = fileparts(folder);
    folderName = folderName + folderNameAfterDot;
end


function command = createAddPackageToPathCommand(isModular, rootFolder, publicFolders)
    % TODO (carlchan 4/28/2024): See g3293319. The behavior of
    % addpath/rmpath on packages is planned to change in the future. We'll
    % likely need to update this code to account for the new design.
    if isModular
        command = strcat("addpath('", rootFolder, "');");
        return;
    end
    folders = strcat("'", rootFolder, "'");
    % The concatenation order here is intentional, to preserve the path
    % order of public folders as defined by the package definition
    for k = 1:length(publicFolders)
        folders = folders + strcat(",'", fullfile(rootFolder, publicFolders(k)), "'");
    end
    command = strcat("addpath(", folders, ");");
end
