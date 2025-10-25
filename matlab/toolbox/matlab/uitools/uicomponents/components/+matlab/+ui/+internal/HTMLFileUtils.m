classdef (Sealed, Abstract) HTMLFileUtils
    methods(Static)
        function htmlFile = resolveFilePath(htmlFile)
            if ~isfile(htmlFile)
                % The path might be an encoded one, decode once and use it.
                htmlFile = char(matlab.net.internal.urldecode(htmlFile));
            end
            fullpath = matlab.ui.internal.HTMLFileUtils.getWhich(htmlFile);
            % If the file is on MATLAB's search path, get the fully qualified filename.
            if ~isempty(fullpath)
                if iscell(fullpath)
                    for i = 1:length(fullpath)
                        if isfile(fullpath{i})
                            htmlFile = fullpath{i};
                            return;
                        end
                    end
                elseif isfile(fullpath)
                    % This means the file is on the path somewhere.
                    htmlFile = fullpath;
                end
            else
                % If the file is referenced as a relative path, get the fully
                % qualified filename.
                fullpath = fullfile(pwd, htmlFile);
                if isfile(fullpath)
                    htmlFile = fullpath;
                end
            end
        end

        function status = isValidExtension(extension)
            inputFileExtensionPattern = matlab.ui.internal.HTMLFileUtils.getValidFileExtensionPattern();
            status = matches(extension, inputFileExtensionPattern);
        end

        function pattern = getSlashPattern()
            % regex pattern matches any leading whitespace at the start of a line, 
            % followed by zero or more backslashes or forward slashes
            pattern = regexpPattern("^\s*(\\|\/)*");
        end

        function pattern = getValidFileExtensionPattern()
            pattern = regexpPattern("^.(htm|html)", "IgnoreCase", true);
        end

        function fullpath = getWhich(htmlFile)
            try
                fullpath = which(htmlFile, '-all');
            catch
                fullpath = '';
            end
        end

        function htmlFile = resolvePathSeparator(htmlFile)
            if ispc
                htmlFile = replace(htmlFile, '/', filesep);
                drivePattern = lettersPattern(1) + ":";
                % Return if file path starts with drive letter format
                % (Ex: "C:") since it is already an absolute path.
                if startsWith(htmlFile, drivePattern)
                    return
                end
            else
                htmlFile = replace(htmlFile, '\', filesep);
            end
            if ispc && contains(htmlFile, filesep)
                % Prefix '//' or '\\' based on platform since this could be UNC path.
                if startsWith(htmlFile, filesep)
                    htmlFile = sprintf('%s%s', filesep, htmlFile);
                else
                    htmlFile = sprintf('%s%s%s', filesep, filesep, htmlFile);
                end
            end
        end
    end
end