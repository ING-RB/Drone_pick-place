function exportFolder(sourcePath, targetPath, varargin)
% matlab.desktop.editor.export.exportFolder Exports all RTC document inside the
% sourcePath to the targetPath.
%
% This exporter respects the following options.
%   sourcePath:  The path to the source folder of live script files. This is mandatory.
%   targetPath:  The path to the target folder (in which the files should be exported). This is mandatory.
%   varargin:    A set of configuration key-values. This is optional.
%       exportFormat                The target format, e.g. 'html'. This is optional (html is the default).
%       askOverwriteExistingFiles   true, if a message dialog should be opened and ask, if the file can be
%                                   overwritten (if it already exists in the target). This is optional.
%       copySupportedFiles          true, if other found (not live script) files in the source path,
%                                   should be copied to the target. This is optional.
%       progressChannel             The message service channel, for progress messages. This is optional.
%                                   The progress channel will send important messages
%                                   regarding the current progress state on the passed channel.
%                                   This can be used for a progress bar.
%                                    - The first message will contain the total number of files.
%                                    - For each file, it sends a message containing the current file number and file path.
%                                    - The last message contains the string "done".
%       Caching                     true or false. Default is true. If true, an existing WebWindow is used.
%                                   This options should not be documented in the reference page of exportFolder.
%                                   It should be only used if export throws a timeout error.
%                                   Note: On purpose, Caching starts with a capital letter.
%
% All other options are silently passed through.
%
% Example usage:
%   matlab.desktop.editor.export.exportFolder(
%               "/my/source/path/",
%               "/my/target/path/",
%               "exportFormat", "html",
%               "askOverwriteExistingFiles", false,
%               "copySupportedFiles", false,
%               "progressChannel", "/myChannel123");
%
%   matlab.desktop.editor.export.exportFolder(
%               "path/",
%               "export/")

%   Copyright 2020-2024 The MathWorks, Inc.

    sourcePath = getAbsolutePath(convertContainedStringsToChars(sourcePath));
    targetPath = getAbsolutePath(convertContainedStringsToChars(targetPath));

    parser = inputParser;
    parser.KeepUnmatched = true;
    parser.PartialMatching = false;
    addParameter(parser, "exportFormat",              "html",  @isStringOrChar);
    addParameter(parser, "askOverwriteExistingFiles", false,   @islogical);
    addParameter(parser, "copySupportedFiles",        false,   @islogical);
    addParameter(parser, "progressChannel",           "",      @isStringOrChar);
    addParameter(parser, "Caching",                   true,    @islogical);

    parse(parser, varargin{:});
    parameter = parser.Results;
    varargin = [fieldnames(parser.Unmatched) struct2cell(parser.Unmatched)];

    overwriteDontAsk = false;

    progressEnables = false;
    if ~(parameter.progressChannel == "")
        progressEnables = true;
    end

    % Collect all files in the source path with given extension(including sub-directories).
    if parameter.copySupportedFiles
        fileList = dir(strcat(sourcePath, filesep, '**', filesep, '*.*'));
    else
        % Collect all .mlx and .m file. .m files can be live or plain. We
        % will only export .m live scripts. For now get all.
        fileList = [...
            dir(strcat(sourcePath, filesep, '**', filesep, '*.mlx'));
            dir(strcat(sourcePath, filesep, '**', filesep, '*.m'))
            ];
    end

    % Removing useless files (e.g. .DS_Store on Mac) from file list.
    fileList = fileList(~startsWith({fileList.name}, '.'));
    % Removing folder from file list.
    fileList = fileList(~[fileList.isdir]);

    if progressEnables
        message.publish(parameter.progressChannel, num2str(length(fileList)));
    end

    for n = 1 : length(fileList)
        currentFilePath = fullfile(fileList(n).folder, fileList(n).name);

        if progressEnables
            message.publish(parameter.progressChannel, [num2str(n) ":" currentFilePath]);
        end
        fileSubPath = extractAfter(currentFilePath, sourcePath);
        [~, baseFileName, ext] = fileparts(currentFilePath);
        isLiveCodeFile = matlab.desktop.editor.EditorUtils.isLiveCodeFile(currentFilePath);
        if (isLiveCodeFile)
            % Creating a target path and change the file extension into the target format.
            newBaseFileName = sprintf('%s.%s', baseFileName, parameter.exportFormat);
            targetSubPath = fullfile(targetPath, erase(fileSubPath, append(baseFileName, ext)), newBaseFileName);
        else
            targetSubPath = fullfile(targetPath, fileSubPath);
        end

        if ~overwriteDontAsk && parameter.askOverwriteExistingFiles && isfile(targetSubPath)
            overwrite = askOverwrite(targetSubPath);
            % Default is 1 (Overwrite existing file), no special handling needed for this case.
            switch overwrite
                case 0
                    % In this case, we will not ask again. Existing files will be silently overwritten.
                    overwriteDontAsk = true;
                case 2
                    % In case, the file exists and should not be overwritten.
                    continue;
            end
        end

        targetFolder = fileparts(targetSubPath);
        if ~isfolder(targetFolder)
           mkdir(targetFolder)
        end
        if (isLiveCodeFile)
            try
                runExport(currentFilePath, targetSubPath, parameter.Caching, varargin{:});
            catch ME
                if contains(lower(ME.message), "timeout")
                    if parameter.Caching
                        suggestion = getMsg("UseOption", "Caching = false");
                        error(getMsg("Timeout", suggestion.getString));
                    else
                        error(getMsg("Timeout", ""));
                    end
                else
                    rethrow(ME);
                end
            end
        else
            % There can be plain m files in fileList. Copy only if requested
            if parameter.copySupportedFiles
                copyfile(currentFilePath, targetSubPath);
            end
        end
    end
    if progressEnables
        message.publish(parameter.progressChannel, "done");
    end
end

function overwriteFiles = askOverwrite(file)
    dialogQuestion = message('MATLAB:Editor:Export:ExportFolderOverwriteDialogQuestion').getString();
    dialogTitle = message('MATLAB:Editor:Export:ExportFolderOverwriteDialogTitle').getString();
    dialogOptionYes = message('MATLAB:Editor:Export:ExportFolderOverwriteDialogOptionYes').getString();
    dialogOptionSkip = message('MATLAB:Editor:Export:ExportFolderOverwriteDialogOptionSkip').getString();
    dialogOptionAll = message('MATLAB:Editor:Export:ExportFolderOverwriteDialogOptionAll').getString();

    answer = questdlg([dialogQuestion file ], ...
            dialogTitle, ...
            dialogOptionYes, dialogOptionSkip, dialogOptionAll, dialogOptionSkip);
    switch answer
        case dialogOptionYes
            overwriteFiles = 1;
        case dialogOptionSkip
            overwriteFiles = 2;
        case dialogOptionAll
            overwriteFiles = 0;
    end
end

function b = isStringOrChar(s)
    b = isstring(s) || ischar(s);
end

function path = getAbsolutePath(path)
    % Checking, if the path is not an absolute path
    if ~startsWith(path, '/') && ~startsWith(path, '\') && ~isequal(strfind(path, ":\"),2) && ~isequal(strfind(path, ":/"),2)
        path = fullfile(pwd, path);
    end
end

function runExport(sourceFileName, destinationFile, reuse, varargin)
    import matlab.internal.liveeditor.LiveEditorUtilities
    warn = warning("off"); cleanupWarn = onCleanup(@() warning(warn));
    % Opens the file in a headless mode
    [~, ~, ext] = fileparts(sourceFileName);
    if strcmpi(ext, '.mlx')
        [editorDocument, cleanupObj] = ...
        matlab.internal.liveeditor.LiveEditorUtilities.open(...
            sourceFileName, reuse ...
        );%#ok<ASGLU>
        editorId = char(editorDocument.getUniqueKey());
    else
        % Rich M
        editorDocument = matlab.desktop.editor.openDocument(sourceFileName,...
        'Visible', matlab.lang.OnOffSwitchState.off);
        % Ensuring the file is loaded
        if editorDocument.Opened
            editorId = char(editorDocument.Editor.RtcId);
        end
        cleanupDocument = onCleanup(@() editorDocument.closeNoPrompt);
    end

    % Turn on warning before calling the next function
    warning(warn);
    % Saves the contents into the file
    matlab.desktop.editor.internal.exportDocumentByID(editorId, 'Destination', destinationFile, varargin{:});
end

function msg = getMsg(id,varargin)
    msg = message(['MATLAB:Editor:Export:' id], varargin{:});
end
