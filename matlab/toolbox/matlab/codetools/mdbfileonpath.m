function varargout = mdbfileonpath(inFilename, ~)
    %MDBFILEONPATH Helper function for the Editor/Debugger
    %   MDBFILEONPATH is passed a string containing an absolute filename of an
    %   file.
    %   It returns:
    %      a filename:
    %         the filename that will be run (may be a shadower)
    %         if file not found on the path and isn't shadowed, returns the
    %         filename passed in
    %      an integer defined in FilePathState
    %      describing the status:
    %         FILE_NOT_ON_PATH - file not on the path or error occurred
    %         FILE_WILL_RUN - file is the one MATLAB will run (or is shadowed by a newer
    %         p-file)
    %         FILE_SHADOWED_BY_PWD - file is shadowed by another file in the current directory
    %         FILE_SHADOWED_BY_TBX - file is shadowed by another file somewhere in the MATLAB path
    %         FILE_SHADOWED_BY_PFILE - file is shadowed by a p-file in the same directory
    %         FILE_SHADOWED_BY_MEXFILE - file is shadowed by a mex, mdl, or slx file in the same directory
    %         FILE_SHADOWED_BY_MLX - file is shadowed by a mlx file file somewhere in the MATLAB path
    %         FILE_SHADOWED_BY_MLAPP - file is shadowed by a mlapp file somewhere in the MATLAB path
    %         INVALID_FILENAME_FOR_EXECUTION - file's name is not a MATLAB identifier
    %         IN_FOLDER_NAMED_PRIVATE - file is in a private folder
    %         INVALID_PKG_DEF - Package definition file is invalid
    %         IN_PKG_REPOSITORY
    %         OUT_OF_DATE_PKG - Package is out of date
    %         PKG_PRIVATE_FILE - File is in a private folder of a package
    %         INCOMPATIBLE_PKG - Package is not compatible
    %         NOT_EXECUTABLE_PKG - Package is not executable
    %         MODULAR_PKGS_NOT_SUPPORTED - Package is not compatible
    %         SHADOWED_BY_VAR - file is shadowed by a variable
    %         NOT_INSTALLED_PKG - Package is not installed
    %         NOT_INSTALLED_PKG_SHADOWED_BY_PWD - Package is not installed and shadowed
    %
    %     The command to install the package if required
    %
    %   inFilename should be an absolute filename with extension ".m" (no
    %   checking is done).
    %
    %   This file is for internal use only and is subject to change without
    %   notice.

    %   Copyright 1984-2023 The MathWorks, Inc.
    import matlab.lang.internal.run.ErrorCause
    try
        if nargin > 0
            varargout{1} = inFilename;
            varargout{2} = double(FilePathState.FILE_NOT_ON_PATH);
            varargout{3} = '';

            fileToRunInfo = matlab.lang.internal.run.FileToRun(inFilename);
            if strcmp(fileToRunInfo.FileType, 'DoesNotExist')
                return;
            end

            if strcmp(fileToRunInfo.Status, 'Runnable')
                varargout{1} = inFilename;
                varargout{2} = double(FilePathState.FILE_WILL_RUN);
                return;
            end

            if strcmp(fileToRunInfo.Status, 'NotRunnable')
                switch fileToRunInfo.ErrorCause
                    case { ErrorCause.InvalidFilenameForExecution, ErrorCause.InVfsLocation }
                        varargout{1} = '';
                        varargout{2} = double(FilePathState.INVALID_FILENAME_FOR_EXECUTION);
                    case ErrorCause.InvalidPkgDef
                        varargout{1} = '';
                        varargout{2} = double(FilePathState.INVALID_PKG_DEF);
                    case ErrorCause.InPkgRepository
                        varargout{1} = '';
                        varargout{2} = double(FilePathState.IN_PKG_REPOSITORY);
                    case ErrorCause.OutOfDatePkg
                        varargout{1} = '';
                        varargout{2} = double(FilePathState.OUT_OF_DATE_PKG);
                    case ErrorCause.PkgPrivateFile
                        varargout{1} = '';
                        varargout{2} = double(FilePathState.PKG_PRIVATE_FILE);
                    case ErrorCause.IncompatiblePkg
                        varargout{1} = '';
                        varargout{2} = double(FilePathState.INCOMPATIBLE_PKG);
                    case ErrorCause.NotExecutablePkg
                        varargout{1} = '';
                        varargout{2} = double(FilePathState.NOT_EXECUTABLE_PKG);
                    case ErrorCause.ModularPkgsNotSupported
                        varargout{1} = '';
                        varargout{2} = double(FilePathState.MODULAR_PKGS_NOT_SUPPORTED);
                    case ErrorCause.ShadowedByVar
                        varargout{1} = getShadowedBy(fileToRunInfo);
                        varargout{2} = double(FilePathState.SHADOWED_BY_VAR);
                    case { ErrorCause.ShadowedByMex, ErrorCause.ShadowedByMdl, ErrorCause.ShadowedBySlx, ErrorCause.ShadowedBySfx }
                        varargout{1} = getShadowedBy(fileToRunInfo);
                        varargout{2} = double(FilePathState.FILE_SHADOWED_BY_MEXFILE);
                    case ErrorCause.ShadowedByP
                        varargout{1} = getShadowedBy(fileToRunInfo);
                        varargout{2} = double(FilePathState.FILE_SHADOWED_BY_PFILE);
                    case ErrorCause.ShadowedByMlapp
                        varargout{1} = getShadowedBy(fileToRunInfo);
                        varargout{2} = double(FilePathState.FILE_SHADOWED_BY_MLAPPFILE);
                    case ErrorCause.ShadowedByMlx
                        varargout{1} = getShadowedBy(fileToRunInfo);
                        varargout{2} = double(FilePathState.FILE_SHADOWED_BY_MLXFILE);
                    otherwise
                        error('Unknown cause');
                end
                return;
            else
                if ~strcmp(fileToRunInfo.Status, 'RunnableAfterFix')
                    error('Unknown status');
                end

                switch fileToRunInfo.ErrorCause
                    case { ErrorCause.InFolderNamedPrivate, ErrorCause.InFolderNamedPrivateAndNotInstalled }
                        varargout{1} = '';
                        varargout{2} = double(FilePathState.IN_FOLDER_NAMED_PRIVATE);
                    case ErrorCause.NotInstalled
                        packageIDParts = fileToRunInfo.PackageID.split('@');
                        simplifiedPackageID = packageIDParts(1);
                        varargout{1} = char(simplifiedPackageID);
                        varargout{2} = double(FilePathState.NOT_INSTALLED_PKG);
                        varargout{3} = getPackageInstallCommand(fileToRunInfo);
                    case ErrorCause.ShadowedByPwdAndNotInstalled
                        packageIDParts = fileToRunInfo.PackageID.split('@');
                        simplifiedPackageID = packageIDParts(1);
                        varargout{1} = char(simplifiedPackageID);
                        varargout{2} = double(FilePathState.NOT_INSTALLED_PKG_SHADOWED_BY_PWD);
                    case ErrorCause.NotOnPath
                        varargout{1} = inFilename;
                        varargout{2} = double(FilePathState.FILE_NOT_ON_PATH);
                    case { ErrorCause.ShadowedByPwd, ErrorCause.NotOnPathAndShadowedByPwd }
                        varargout{1} = getShadowedBy(fileToRunInfo);
                        varargout{2} = double(FilePathState.FILE_SHADOWED_BY_PWD);
                    case ErrorCause.ShadowedByPath
                        varargout{1} = getShadowedBy(fileToRunInfo);
                        varargout{2} = double(FilePathState.FILE_SHADOWED_BY_TBX);
                    otherwise
                        error('Unknown cause');
                end
            end
        else
            varargout{1} = '';
            varargout{2} = double(FilePathState.FILE_NOT_ON_PATH);
            varargout{3} = '';
        end
    catch e %#ok<NASGU>
        varargout{1} = inFilename;
        varargout{2} = double(FilePathState.FILE_NOT_ON_PATH);
        varargout{3} = '';
    end
end

function shadower = getShadowedBy(fileToRunInfo)
    shadower = [];
    for i = 1:numel(fileToRunInfo.ErrorDetails)
        if isfield(fileToRunInfo.ErrorDetails, 'ShadowedBy')
            shadower = char(fileToRunInfo.ErrorDetails.ShadowedBy);
        end
    end
end

function cmd = getPackageInstallCommand(fileToRunInfo)
    cmd = '';
    for i=1:numel(fileToRunInfo.Fixes.Types)
        if fileToRunInfo.Fixes.Types(i) == matlab.lang.internal.run.FixType.InstallPackage
            cmd = char(fileToRunInfo.Fixes.Commands(i));
            return;
        end
    end
end
