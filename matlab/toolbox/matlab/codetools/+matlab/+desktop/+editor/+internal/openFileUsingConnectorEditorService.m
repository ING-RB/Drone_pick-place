function editorObj = openFileUsingConnectorEditorService(filename)
%matlab.desktop.editor.internal.openFileUsingConnectorEditorService Open file using connector editor service.
%   EDITOROBJ = matlab.desktop.editor.internal.openFileUsingConnectorEditorService(FILENAME)
%   opens FILENAME in the native plain code editor or MATLAB live editor on MATLAB Mobile.
%   Currently, this function always returns an empty matlab.desktop.editor.Document object.
%
%   FILENAME must include the full path, otherwise a MATLAB:Editor:Document:PartialPath
%   exception is thrown.
%   If FILENAME is empty then an untitled file will be created on the disk and
%   opened in the editor.
%   If FILENAME does not exist, file will be created on the disk.
%
%   This function supports scalar arguments only, and does not display
%   any dialog boxes.
%
%   This function is unsupported and might change or be removed without
%   notice in a future version.

%   Copyright 2022 The MathWorks, Inc.

    arguments
        filename {mustBeTextScalar} = ''
    end

    editorObj = matlab.desktop.editor.Document.empty;

    shadowFileVersion = connector.internal.getClientTypeProperties().shadowFileVersion;

    % If the shadowFileVersion property does not exist from the client,
    % that means the client is not ready to support edit feature.
    if isempty(shadowFileVersion) || strcmpi(shadowFileVersion, '')
        nse = connector.internal.notSupportedError;
        nse.throwAsCaller;
    end

    if filename == ""
        createUntitled();
        return;
    end

    checkEndsWithBadExtension(filename, shadowFileVersion);
    checkFileSize(filename);

    createOrOpenFile(filename);
end

%--------------------------------------------------------------------------
% Create a new file called untitled<n>.m in the current directory
%--------------------------------------------------------------------------
function createUntitled()
    connector.ensureServiceOn;

    basename = 'untitled';
    ext = '.m';

    name = [basename ext];
    count = 1;
    while isfile(name) && count < 100
        name = [basename int2str(count) ext];
        count = count + 1;
    end

    if isfile(name)
        error(message('MATLAB:connector:Platform:NoAvailableUntitledName'));
    end

    connector.internal.editorServiceOpenOrCreate(fullfile(pwd, name)).get();
end

%--------------------------------------------------------------------------
% Helper method that checks if filename is supported in the product offering
% of MATLAB Mobile
%--------------------------------------------------------------------------
function checkEndsWithBadExtension(filename, shadowFileVersion)
    if ~isSupportedInNativePlainEditor(filename) && ~isSupportedInLiveEditor(filename, shadowFileVersion)
        error(message('MATLAB:Editor:Document:BadExtensionFile'));
    end
end

%--------------------------------------------------------------------------
% Helper method that checks if file size is too big.
% For now, we think size bigger than 300kB is going to affect the user's
% experience on mobile devices. It takes about 1 min to load on the Android
% devices.
%--------------------------------------------------------------------------
function checkFileSize(filename)
    myFile = dir(which(filename));

    if isempty(myFile) % return if file does not exists    
        return;
    end

    size = myFile(1).bytes;

    % Currently, 300kB is the m file size limit, and 20MB is the mlx file size limit (same as MATLAB Online)
    if (isSupportedInNativePlainEditor(filename) && size > 300000) || (isLiveCodeFile(filename) && size > 20000000)
        error(message('MATLAB:Editor:Document:FileSizeTooLarge'));
    end
end


%--------------------------------------------------------------------------
% Create or open a file with the full absolute path: 'filename'
%--------------------------------------------------------------------------
function createOrOpenFile(filename)
    isMlxFile = matlab.desktop.editor.EditorUtils.isLiveCodeFile(filename);
    % Create empty live code file if the filename is a live script file
    % and it does not exist.
    if isMlxFile && ~isfile(filename)
        fileModel = matlab.internal.livecode.FileModel.createEmptyLiveCodeFile(filename);
        if isempty(fileModel)
            error('MATLAB:Editor:Document:ErrorCreatingFile', ...
                getString(message('MATLAB:Editor:Document:ErrorCreatingFileNoPrompt', filename)));
        end
    end

    connector.internal.editorServiceOpenOrCreate(filename).get();
end

%--------------------------------------------------------------------------
% Helper method that checks if file is supported in native plain editor.
%--------------------------------------------------------------------------
function tf = isSupportedInNativePlainEditor(filename)
    [~, ~, ext] = fileparts(filename);
    tf = any(strcmpi(ext, {'', '.m', '.txt', '.xml', '.csv', '.html', '.ini'}));
end

%--------------------------------------------------------------------------
% Helper method that checks if file is supported in live editor.
%--------------------------------------------------------------------------
function tf = isSupportedInLiveEditor(filename, shadowFileVersion)
    tf = isLiveCodeFile(filename) && isLiveEditorAvailable(shadowFileVersion);
end

%--------------------------------------------------------------------------
% Helper method that checks if file is a live code file.
%--------------------------------------------------------------------------
function tf = isLiveCodeFile(filename)
    tf = matlab.desktop.editor.EditorUtils.isLiveCodeFile(filename);
end

%--------------------------------------------------------------------------
% Helper method that checks if live editor is available on MATLAB Mobile.
%--------------------------------------------------------------------------
function tf = isLiveEditorAvailable(shadowFileVersion)
    tf = ~strcmpi(shadowFileVersion, '1');
end
