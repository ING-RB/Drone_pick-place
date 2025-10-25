classdef FileToRun
    % This class represents a file to be run. It is constructed with a full
    % filepath, and contains various information about the file, including
    % whether the file is runnable, the command to run the file, errors
    % which prevent the file from running, and fixes to resolve those
    % errors.
    %
    %   Filepath         - full filepath of the file
    %   FileType         - type of the file
    %   Status           - whether the file is runnable or requires fixes
    %   ErrorCauses      - issues which prevent the file from being run
    %   ErrorDetails     - details of each error cause
    %   RunCommand       - command to run the file at the command line
    %   PackageID        - package ID of the claiming package
    %   PackageRoot      - package root of the claiming package
    %   PackageIsModular - whether the file is claimed by a modular package
    %   Fixes            - fixes which will make the file runnable

    % Copyright 2023-2024 The MathWorks, Inc.

    properties
        Filepath
        FileType
        Status = missing
        ErrorCause = missing
        ErrorDetails = missing
        RunCommand = missing
        PackageID = missing
        PackageRoot = missing
        PackageIsModular = missing
        Fixes = missing
    end

    methods
        function obj = FileToRun(filepath)
            arguments
                filepath {mustBeTextScalar}
            end

            import matlab.lang.internal.run.*

            obj.Filepath = string(filepath);

            info = commandToRun(obj.Filepath);
            obj.FileType = FileType(info.FileType);

            if obj.FileType ~= FileType.DoesNotExist
                obj.Status = FileStatus(info.Status);
                [obj.ErrorCause, obj.ErrorDetails] ...
                    = combineErrors(ErrorCause(info.ErrorCauses), info.ErrorDetails);
                obj.RunCommand = info.RunCommand;
                obj.PackageID = info.PackageID;
                obj.PackageRoot = info.PackageRoot;
                obj.PackageIsModular = info.PackageIsModular;
                obj.Fixes = createFixesForFile(obj);
            end
        end
    end
end


% Helper functions

function [combinedCause, combinedDetails] = combineErrors(errorCauses, errorDetails)
    % See g3119538 for more details on what is considered a redundant error
    % or an invalid combination of errors
    import matlab.lang.internal.run.ErrorCause

    if isempty(errorCauses)
        combinedCause = ErrorCause.empty;
        combinedDetails = struct();
        return;
    end

    redundantErrorCauses = ErrorCause.empty;
    for k = 1:numel(errorCauses)
        redundantErrorCauses = ...
            [redundantErrorCauses, getRedundantErrorCauses(errorCauses(k))]; %#ok<AGROW>
    end

    [errorCauses, idx] = setdiff(errorCauses, redundantErrorCauses);
    errorDetails(~idx) = [];

    if isscalar(errorCauses)
        combinedCause = errorCauses;
        combinedDetails = errorDetails{1};
        return;
    end

    if all(ismember([ErrorCause.NotOnPath, ErrorCause.ShadowedByPwd], errorCauses))
        combinedCause = ErrorCause.NotOnPathAndShadowedByPwd;
    elseif all(ismember([ErrorCause.ShadowedByPwd, ErrorCause.NotInstalled], errorCauses))
        combinedCause = ErrorCause.ShadowedByPwdAndNotInstalled;
    elseif all(ismember([ErrorCause.InFolderNamedPrivate, ErrorCause.NotInstalled], errorCauses))
        combinedCause = ErrorCause.InFolderNamedPrivateAndNotInstalled;
    else
        % Invalid combination of errors
        combinedCause = ErrorCause.empty;
        combinedDetails = struct();
        return;
    end

    combinedDetails = errorDetails{1};
    for j = 2:numel(errorDetails)
        fields = fieldnames(errorDetails{j});
        for k = 1:numel(fields)
            fieldname = fields{k};
            combinedDetails.(fieldname) = errorDetails{j}.(fieldname);
        end
    end
end

function redundantCauses = getRedundantErrorCauses(errorCause)
    import matlab.lang.internal.run.ErrorCause
    switch errorCause
        case ErrorCause.ShadowedByPath
            redundantCauses = ErrorCause.NotOnPath;
        case ErrorCause.NotInstalled
            redundantCauses = [ErrorCause.NotOnPath, ErrorCause.ShadowedByPath];
        case ErrorCause.InFolderNamedPrivate
            redundantCauses = [ErrorCause.NotOnPath, ErrorCause.ShadowedByPwd, ...
                ErrorCause.ShadowedByPath, ErrorCause.ShadowedWithinPkg];
        case ErrorCause.ShadowedWithinPkg
            redundantCauses = ErrorCause.NotOnPath;
        otherwise
            redundantCauses = ErrorCause.empty;
    end
end

function fixes = createFixesForFile(obj)
    import matlab.lang.internal.run.*

    if obj.Status ~= FileStatus.RunnableAfterFix
        fixes = FileFix.empty;
        return;
    end

    fixTypes = getPossibleFixTypes(obj.ErrorCause, obj.FileType);
    [~, n] = size(fixTypes);
    fixes = FileFix.empty;
    for k = 1:n
        fixes(k) = FileFix(fixTypes(:,k)', obj.Filepath, obj.PackageID, obj.PackageRoot);
    end
end


function fixTypes = getPossibleFixTypes(errorCause, fileType)
    import matlab.lang.internal.run.*

    % The returned types in each column have an AND relationship, and will
    % be used to construct a single FileFix object (you must perform all
    % the fixes in a column to fix the file). The columns have an OR
    % relationship with each other (you may perform all the fixes in column
    % 1, OR all the fixes in column 2, to fix the file).
    switch errorCause
        case {ErrorCause.NotOnPath, ErrorCause.ShadowedByPath}
            switch fileType
                case FileType.Package
                    fixTypes = [FixType.CD, FixType.AddPackageToPath];
                case FileType.NonPackage
                    fixTypes = [FixType.CD, FixType.AddFolderToPath];
                otherwise
                    % Unhandled FileType
                    fixTypes = missing;
            end
        case ErrorCause.NotInstalled
            fixTypes = FixType.InstallPackage;
        case {ErrorCause.ShadowedByPwd, ErrorCause.InFolderNamedPrivate, ErrorCause.NotOnPathAndShadowedByPwd}
            fixTypes = FixType.CD;
        case {ErrorCause.ShadowedByPwdAndNotInstalled, ErrorCause.InFolderNamedPrivateAndNotInstalled}
            fixTypes = [FixType.InstallPackage; FixType.CD];
        case ErrorCause.ShadowedWithinPkg
            fixTypes = FixType.CD;
        otherwise
            % Unhandled ErrorCause
            fixTypes = missing;
    end
end
