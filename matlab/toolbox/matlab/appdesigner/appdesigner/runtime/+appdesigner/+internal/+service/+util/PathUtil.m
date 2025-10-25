classdef (Abstract) PathUtil
    % PATHUTIL A class to decode full file paths and return the qualified
    % package / class name that can be run at the command line.

    % Copyright 2019-2023 The MathWorks, Inc.

    methods (Static)

        function command = getAppRunCommandFromFileName(fullFileName)
            % Parse the full file name of the app, and extract the fully
            % qualified command that will run the app.  This method deals
            % with changing package and class dirs (starting with + and @)
            % to the proper MATLAB command.
            % E.g.
            % "C:\work\+foo\@bar\bar.m"      => "foo.bar"         // constructor of class in package
            % "C:\work\+foo\+baz\@bar\bar.m" => "foo.baz.bar"     // constructor of class in subpackage
            % "C:\work\+foo\+baz\@bar\bat.m" => "foo.baz.bar.bat" // constructor of class in subpackage
            % "C:\work\+foo\baz.m"           => "foo.baz"         // static package method
            % "C:\work\@bar\bar.m"           => "bar"             // constructor of class, not in package
            % "C:\work\@bar\method.m"        => "bar.method"      // class method
            % "C:\work\@bar\blah\foo.m"      => "foo"             // not runnable in MATLAB
            % "C:\+work\blah\foo.m"          => "foo"             // "+work" is not a package, so just return simple name (see next rule)
            % "C:\work\foo.m"                => "foo"             // foo is maybe MCOS classdef, maybe just a function, so just return simple name
            import appdesigner.internal.service.util.PathUtil;

            [appPath, appName] = fileparts(fullFileName);

            isFileDirectlyInClassOrPackageFolder = PathUtil.fileDirectlyInClassOrPackageFolder(fullFileName);

            if ~isFileDirectlyInClassOrPackageFolder
                command = appName;
                return;
            end

            [~, appPath] = PathUtil.splitPathAtMCOSDirs(fullfile(appPath, appName));

            % Convert file separators to dots
            appPath = regexprep(appPath, filesep, '.');

            % Replace class directories with nothing
            % This uses a lookahead expression to match things like
            % '@foo.foo' but not '@foo.bar'.
            appPath = regexprep(appPath, '@(?<classname>.*?)\.\k<classname>', '$<classname>');

            % Remove other @ directories
            appPath = regexprep(appPath, '@', '');

            % Remove package prefix
            command = regexprep(appPath, '\+', '');
        end

        function pathToApp = getPathToApp(fullFileName)
            % Returns the base path that must be added to the MATLAB path
            % to ensure the app is found on the MATLAB path.  For package
            % and method dirs, the base path would be the parent directory
            % of the root of the package or method dir.
            % E.g.
            % "C:\work\+foo\bar.mlapp"           => "C:\work\"
            % "C:\work\@foo\foo.mlapp"           => "C:\work\"
            % "C:\work\+foo\+bar\@baz\baz.mlapp" => "C:\work\"

            isFileDirectlyInClassOrPackageFolder = appdesigner.internal.service.util.PathUtil.fileDirectlyInClassOrPackageFolder(fullFileName);
            if ~isFileDirectlyInClassOrPackageFolder
                [pathToApp, ~] = fileparts(fullFileName);
                return;
            end

            [pathToApp, ~] = appdesigner.internal.service.util.PathUtil.splitPathAtMCOSDirs(fullFileName);
        end
    end

    methods (Access = private, Static)
        function val = fileDirectlyInClassOrPackageFolder(fullFileName)
            pathComponents = split(fullFileName, filesep);

            if length(pathComponents) == 1
                val = false;
                return;
            end

            parentDir = pathComponents(end - 1);

            if startsWith(parentDir, {'@', '+'})
                val = true;
            else
                val = false;
            end
        end

        function [basePath, mcosPath] = splitPathAtMCOSDirs(originalPath)

            % If we're using windows, add another '\' character to make
            % sure the regular expression is escaped properly.
            if strcmp(filesep, '\')
                sep = ['\' filesep];
            else
                sep = filesep;
            end

            firstSeparator = regexp(originalPath, [sep '\+']);
            if isempty(firstSeparator)
                firstSeparator = regexp(originalPath, [sep '@']);
            end

            if isempty(firstSeparator)
                mcosPath = '';
                basePath = originalPath;

                % Remove trailing file separator if it exists
                if basePath(end) == filesep
                    basePath = basePath(1:end-1);
                end
            else
                mcosPath = originalPath(firstSeparator(1) + 1:end);
                basePath = originalPath(1:firstSeparator(1) - 1); % strip off the final file separator
            end
        end
    end
end
