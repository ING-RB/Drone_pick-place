classdef (Hidden) ExportUtils
%EXPORTUTILS Static utility methods for matlab.desktop.editor.export functions
%
% These are utility functions to be used by matlab.desktop.editor.export
% functions and classes are not meant to be called by users directly.

% Copyright 2020-2024 The MathWorks, Inc.

    methods (Static)

        % Errors if the given struct does not have a field 'Destination'
        function assertHasDestination(exportOptions)
            if ~isfield(exportOptions, "Destination")
                try
                    error(matlab.desktop.editor.export.ExportUtils.getMsg("NeedsDestinationPath"));
                catch ex
                    throwAsCaller(ex);
                end
            end
        end % assertHasDestination

        % Checks if the given struct has a field 'MATLABRelease' and adds
        % it, if needed.
        function outOptions = fillMATLABRelease(inOptions)
            outOptions = inOptions;
            if ~isfield(outOptions, "MATLABRelease")
                outOptions.MATLABRelease = version("-release");
            end
        end % fillMATLABRelease

        function imagedir = imageFolder(filename)
            [~, ~, ext] = fileparts(filename);
            if ext == ".tex"
                imagedir = matlab.desktop.editor.export.ExportUtils.imageFolderTeX(filename);
                if ~isempty(imagedir)
                    return;
                end
            end
            [path, filename, ~] = fileparts(fullfile(filename));
            % LaTeX doesn't like spaces in graphics paths.
            filename = strrep(filename, " ", "_");
            imagedir = char(fullfile(path, filename + "_media"));
        end % imageFolder

        function imagedir = imageFolderTeX(filename)
            try
                content = fileread(filename, "encoding", "UTF-8");
                imagedir = extractBetween(content, "\graphicspath{", "}");
                if isempty(imagedir)
                    imagedir = string.empty;
                    return;
                end
                imagedir = strtrim(erase(imagedir{1}, "{"));
                if startsWith(imagedir, ".")
                    imagedir = tempdir + imagedir(2:end);
                end
                imagedir = fullfile(imagedir);
            catch
                imagedir = string.empty;
            end
        end % imageFolderTeX

        function launch(filename)
            try
                % Java dependency and 'com.mathworks' package and
                % subpackages will be removed in a future release.
                file = java.io.File(filename);
                com.mathworks.fileutils.DesktopUtils.open(file.toPath()); %#ok
            catch
                % If
                % * there is no default application associated with the
                %   file extension of 'filename', or
                % * if  com.mathworks.fileutils.DesktopUtils.open failed,
                % we open it as text in MATLAB.
                edit(filename);
            end
        end % launch

        %---------------------------------------------------------------
        % The following functions are used by MarkdownExporter and
        % IPYNExporter
        %---------------------------------------------------------------

        %---------------------------------------------------------------
        % Utilities for inputParser

        function isValidMarkdownFormat(str)
            validatestring(str, ["github", "github_math"]);
        end % isValidMarkdownFormat

        function isValidCodeCogsValue(value)
            msg = matlab.desktop.editor.export.ExportUtils.getMsg("InvalidCodeCogsValue");
            assert(contains(value, ["off", "png", "jpeg", "svg"]), msg);
        end % isValidCodeCogsValue

        function isValidKernel(s)
            if ~(ischar(s) || isstring(s))
                error(matlab.desktop.editor.export.ExportUtils.getMsg("StringExpected", "KernelLanguage"));
            end
        end % isValidKernel

        % isLogical follows the PRISM standard for accepting logical
        % values, namely: isLogical accepts true, false, 0, and 1
        function tf = isLogical(value, varargin)
            tf = isscalar(value) &&   ...
                 (islogical(value) || ...
                  matlab.desktop.editor.export.ExportUtils.isIntegerInRange(value, 0, 1) ...
                 );
            if tf == false && nargin == 1
                error(matlab.desktop.editor.export.ExportUtils.getMsg("LogicalExpected"));
            end
        end % isLogical

        function tf = isIntegerInRange(value, a, b)
            tf = matlab.desktop.editor.export.ExportUtils.isInteger(value) && a <= value && value <= b;
        end

        function tf = isInteger(n)
            tf = isscalar(n) && isreal(n) && mod(n, 1) == 0;
        end

        function tf = isString(value)
            tf = ischar(value) || isstring(value);
        end % isString

        % Encode image stored in file 'imageFile' as base64.
        function [status, base64] = encodeImage(imageFile, options)
            status = 1; base64 = string.empty;
            [~,name, ext] = fileparts(string(imageFile));
            imageFile = fullfile(options.imageDir, name + ext);
            fid = fopen(imageFile, "r");
            if fid == -1
                status = 0; return;
            end
            obj = onCleanup(@() fclose(fid));
            image = fread(fid);
            image = uint8(image);
            base64 = matlab.net.base64encode(image);
        end % encodeImage

        %---------------------------------------------------------------
        % Utilities for postprocessing LaTeX file

        % Delete outputs in LaTeX file:
        % Even if the MLX file is not evaluated,
        % the MLX file can include outputs.
        function content = removeOutputs(content)
            import matlab.desktop.editor.export.ExportUtils
            % Delete figure output
            content = ExportUtils.removeFigure(content, "matlabcode");
            content = ExportUtils.removeFigure(content, "matlaboutput");
            content = ExportUtils.removeFigure(content, "matlabsymbolicoutput");
            % Delete standard output
            start = "\begin{matlaboutput}"; stop = "\end{matlaboutput}";
            content = replaceBetween(content, start, stop, "", "Boundaries", "inclusive");
            % Delete table output
            start = "\begin{matlabtableoutput}"; stop = "\end{matlabtableoutput}";
            content = replaceBetween(content, start, stop, "", "Boundaries", "inclusive");
            % Delete symbolic output
            start = "\begin{matlabsymbolicoutput}";
            stop = "\end{matlabsymbolicoutput}";
            content = replaceBetween(content, start, stop, "", "Boundaries", "inclusive");
        end % removeOutputs

        function content = removeFigure(content, outputType)
            env = "\end{" + outputType + "}";
            start = env + newline + "\begin{center}";
            stop = "\end{center}";
            while true
                fig = extractBetween(content, start, stop);
                if isempty(fig)
                    break;
                end
                content = replaceBetween(content, start, stop, env, "Boundaries", "inclusive");
            end
        end % removeFigureOutput

        %---------------------------------------------------------------
        % Utilities for postprocessing Markdown file

        % Postprocess Markdown file
        function mdText = postProcessing( ...
                mdText, mdImageFolder, texImageFolder, varargin)
            if nargin == 4
                useCustomPath = varargin{1};
            else
                useCustomPath = false;
            end
            % File path of the images must be changed.
            [~, texFolderName] = fileparts(texImageFolder);
            if useCustomPath
                mdFolderName = strrep(mdImageFolder, "\", "/");
            else
                [~, mdFolderName ] = fileparts(mdImageFolder);
            end
            mdFolderName = char(mdFolderName);
            if endsWith(mdFolderName, "/") || endsWith(mdFolderName, "\")
                mdFolderName = mdFolderName(1:end-1);
            end
            mdText = replace(mdText, texFolderName, mdFolderName);
            mdText = replace(mdText, "././", "./");
            % Remove empty lines. Exeception: Between an <img ...> and
            % and a heading (a line starting with #), there must be an
            % empty line!
            toc = extractBetween(mdText, '<a name="beginToc"></a>', '<a name="endToc"></a>');
            if ~isempty(toc); mdText = replace(mdText, toc, "!!!TOC!!!"); end
            pat = ">" + newline + newline + "#";
            mdText = replace(mdText, pat, "!!!DONOTDELETE!!!");
            mdText = replace(mdText, [newline,newline], newline);
            mdText = replace(mdText, "!!!DONOTDELETE!!!", pat);
            if ~isempty(toc); mdText = replace(mdText, "!!!TOC!!!", toc); end
            % Remove unneccessary space before and after a TeX formula.
            mdText = replace(mdText, "\$", "!!!DOLLAR!!!");
            mdText = replace(mdText, "  $", " $");
            mdText = replace(mdText, "$  ", "$ ");
            mdText = replace(mdText, "!!!DOLLAR!!!", "\$");
            mdText = replace(mdText, "\hskip2newline", newline);
        end % postProcessing

        % Write content to file.
        function writeFile(filename, content)
            % The following fopen call is equivalent to
            % fopen(filename, "w", "n", "UTF-8");
            [fid, errmsg] = fopen(filename, "w");
            if fid == -1
                error(errmsg);
            else
                obj = onCleanup(@() fclose(fid));
            end
            fprintf(fid, "%s", content);
        end % writeFile

        % If the folder 'old' exists, then move the folder 'old' which
        % contains images, resp. move the files inside
        % the folder 'old', to the folder 'new'.
        % The folder 'old' was created by the LaTeXExporter.
        function moveImageFolder(old, new)
            if strcmp(old, new) || ~exist(old, "dir")
                return;
            end
            if exist(new, "dir")
                % Move all files
                movefile(fullfile(old, "*.*"), new);
                rmdir(old, "s");
            else
                % Move entire folder
                movefile(old, new);
            end
        end % moveImageFolder

        function copyImageFolder(old, new)
            if strcmp(old, new) || ~exist(old, "dir")
                return;
            end
            if exist(new, "dir")
                % Copy all files
                copyfile(fullfile(old, "*.*"), new);
                rmdir(old, "s");
            else
                % Copy entire folder
                copyfile(old, new);
            end
        end % moveImageFolder

        %---------------------------------------------------------------
        % Miscellaneous utilities

        % Returns 'fullFilename' which is 'Filename' including the
        % absolute path as a string.
        % The function calls 'which', which uses the MATLAB search
        % path, to find 'Filename'.
        % If nargin == 2 then the function
        %    returns status == 0, if the operation failed, or
        %    returns status == 1, if the operation was successful,
        %    and 'fullFilename' is the empty string.
        % If nargin == 1, then the function throws an error if the
        % operation failed,
        function [fullFilename, status] = getFullFilename(Filename)
            filename = string(which(Filename));
            if filename == ""
                filename = string(Filename);
            end
            [path, name, ext] = fileparts(filename);
            if path == ""
                fullFilename = fullfile(pwd, name + ext);
            else
                content = dir(path);
                if isempty(content)
                    % Folder 'path' does not exist.
                    if nargout ~= 2
                        error(matlab.desktop.editor.export.ExportUtils.getMsg("PathNotFound", path));
                    else
                        status = 0; fullFilename = string.empty;
                        return;
                    end
                end
                path = content(1).folder;
                fullFilename = fullfile(path, name + ext);
            end
            fullFilename = string(fullFilename);
            status = 1;
        end % getFullFilename

        % Delete file
        function deleteFile(filename)
            if exist(filename, "file")
                delete(filename);
            end
        end % deleteFile

        % Delete folder
        function deleteFolder(folder)
            if exist(folder, "dir")
                rmdir(folder, "s");
            end
        end % deleteFolder

        % Get Message from message catalog
        function msg = getMsg(id, varargin)
            msg = message("MATLAB:Editor:Export:" + id, varargin{:});
        end

        % Get media folder with relative path. The relative path is
        % related to the path of filename.
        % Reason: Avoid an absolute path, because several Markdown renderer
        % don't accept an absolute path due to security reasons.
        % Also note, that even a relative path like ..\mediafolder could
        % cause issues, because .. could be ouside of the user directory.
        % Some Markdown renderer don't allow that by default.
        % However, such Markdown renderer, like Visual Studio Code,
        % accept an absolute path or a relative path which is a directory
        % outside the user director, if the user tells the renderer that
        % the directory is a trusted directory.
        function folder = RelativePath(mediafolder, filename)
            try
                folder = matlab.desktop.editor.export.ExportUtils.getFullFilename(mediafolder);
            catch
                folder = mediafolder;
            end
            try
                filename  = matlab.desktop.editor.export.ExportUtils.getFullFilename(filename);
            catch
            end
            [mediapath, name] = fileparts(folder);
            filepath  = fileparts(filename);
            if strcmp(mediapath, filepath)
                folder = "." + filesep + name;
            elseif contains(filepath, mediapath)
                path = erase(filepath, mediapath);
                c = count(path, filesep);
                path = "";
                for k=1:c
                    path = path + ".." + filesep;
                end
                folder = path + name;
            elseif contains(mediapath, filepath)
                path = erase(mediapath, filepath);
                folder = "." + path + filesep + name;
            else
                % Use original media folder
                folder = mediafolder;
            end
        end

    end % methods (Static)

end % classdef
