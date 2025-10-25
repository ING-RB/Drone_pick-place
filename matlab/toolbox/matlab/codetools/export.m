function outputAbsoluteFilename = export(inCodeFile, varargin)
%EXPORT Convert live script or function to standard format.
%   PATH = EXPORT(FILE) converts the specified live script or function to a PDF file
%   with the same name and returns the full path to the converted file. FILE must be a
%   live script or live function file with a .m or .mlx extension. Specify FILE as an absolute or relative path.
%
%   PATH = EXPORT(FILE,OUTPUTFILE) converts the specified live script or function to the
%   location and/or format specified by OUTPUTFILE. The destination folder must exist and be
%   writable. Supported file extensions include .pdf, .html, .docx, .tex and .m.
%
%   Examples:
%       export('myLiveScript.mlx')
%       export('path/to/myLiveScript.mlx','other/path/to/mytest.html')
%       export('path/to/myLiveScript.m','mytest.html')
%       export('path/to/myLiveScript.m','other/path/to/')
%
%   PATH = EXPORT(FILE, NAME=VALUE)
%   PATH = EXPORT(FILE, OUTPUTFILE, NAME=VALUE) sets the export options using one
%   or more name-value arguments:
%     Run: false | true
%     CatchError: true | false
%     Format: 'pdf' | 'html' | 'docx' | 'latex' | 'm' | 'markdown' | 'ipynb'
%     HideCode: true | false
%     OpenExportedFile: true | false
%
%  Options for 'pdf', 'docx', and 'latex' file formats only:
%     PageSize: 'Letter' | 'Legal' | 'Tabloid' | 'A2' | 'A3' | 'A4' | 'A5'
%     Orientation: 'Portrait' | 'Landscape'
%     Margins: Array in the form [left top right bottom], values given in pt (1/72 inch)
%
%  Options for 'pdf', 'latex', 'markdown', and 'ipynb' file formats only.
%  Set Run=true when specifying these options:
%     FigureFormat:
%        For pdf     : 'png' | 'jpeg' | 'bmp'  | 'svg'
%        For latex   : 'eps' | 'png'  | 'jpeg' | 'pdf'
%        For markdown: 'png' | 'jpeg' | 'bmp'  | 'svg'
%        For ipynb   : 'png' | 'jpeg' | 'bmp'  | 'svg'
%  FigureResolution: Given in dpi as positive integers between 36 and 2880
%                    (default is 600 dpi). FigureResolution of 0 means
%                    screen resolution.
%
%  Options for 'markdown' and 'ipynb' file formats only:
%     IncludeOutputs     : true | false
%     EmbedImages        : true | false
%     ProgrammingLanguage: a string or character array. Default: "matlab".
%
%  Options for 'markdown' file format only:
%     AcceptHTML       : true  | false
%     RenderLaTeXOnline: "off" | "svg" | "png" | "jpeg"
%
%  Examples:
%       export('myLiveScript.mlx','path/to/file.docx',HideCode=true,PageSize='A4',Orientation='Landscape')
%       export('myLiveScript.m','path/to/file.pdf',Run=true,FigureFormat='svg',Margins=[144 72 36 72])
%       export('myLiveScript.mlx','path/to/file.tex',Run=true,FigureFormat='eps',OpenExportedFile=true)
%       export('myLiveScript.m','path/to/file.md')
%       export('myLiveScript.mlx', Format='markdown')
%       export('myLiveScript.m','path/to/file.ipynb')

%   Copyright 2021-2024 The MathWorks, Inc.

validateattributes(inCodeFile,{'char','string'},{'nonempty','scalartext'});
[varargin{:}] = convertContainedStringsToChars(varargin{:});

% Get full path to the source file
[status, fileAttributes] = fileattrib(inCodeFile);
if status && isscalar(fileAttributes)
    % Unique file found with that path. Using it.
    sourceFilePath = fileAttributes.Name;
else
    % Try to find on MATLAB path.
    sourceFilePath = which(inCodeFile);
end
if isempty(sourceFilePath)
    error(getMsg('ScriptFileNotFound'));
end

[~, name, ext] = fileparts(sourceFilePath);

% We support exporting for live scripts only
if ~matlab.desktop.editor.EditorUtils.isLiveCodeFile(sourceFilePath)
    if (strcmpi(ext, '.m'))
         % Ask caller to use Publish if a Plain M file
        error(getMsg('UsePublishForPlainM'))
    else
        error(getMsg('NotALiveScript'))
    end
end

% Create parser and add custom arguments.
eParser = matlab.desktop.editor.export.ExportParser();
eParser.addParameter('Run',        false, @isLogical);
eParser.addParameter('CatchError', true,  @isLogical);
eParser.addParameter('Caching',    true,  @isLogical);

% Parse ...
try
    results = eParser.parse(name, varargin{:});
catch ME
    throwAsCaller(ME)
end

% Parser gives us a destination path. Check for write permissions.
% checkWritePermission throws an error if the destination is read-only.
checkWritePermission(results.Destination);

% Make sure that input file and output file are not the same.
outputFile = results.Destination;
outputAbsoluteFilename = getFullFilename(outputFile);
if strcmp(outputAbsoluteFilename, sourceFilePath)
    error(getMsg('FilesMustBeDifferent'));
end

% Use MediaLocation to set the internal options imagePath and figurePath.
% Try to avoid an absolute path and use a relative path if possible.
if isfield(results, 'MediaLocation') && ~strcmp(results.MediaLocation, '')
    results.imagePath  = results.MediaLocation;
    results.figurePath = results.MediaLocation;
end

% The HTML exporter uses the internal option embeddedImages.
if isfield(results, "EmbedImages")
    results.embeddedImages = results.EmbedImages;
end

if results.Run
    % Don't use cache when running the file.
    results.Caching = false;
end

% Caching the CEF window
persistent webWindow;
cachedWebWindowExist = ~isempty(webWindow) && webWindow.isvalid() && webWindow.isWindowValid();

if ~results.Caching
    % Reset caching
    if cachedWebWindowExist
        delete(webWindow);
    end
end

% Opening the file
try
    warn = warning("off");
    cleanupWarn = onCleanup(@() warning(warn));
    if (~cachedWebWindowExist || ~results.Caching)
        % openDocument expects a proper type for ReuseWebWindow.
        webWindow = matlab.internal.cef.webwindow.empty;
    end
    editorDocument = matlab.desktop.editor.openDocument(sourceFilePath,...
    'Visible', matlab.lang.OnOffSwitchState.off,...
    'ReuseWebWindow', webWindow);
    %Ensuring the file is loaded
    if editorDocument.Opened
        id = char(editorDocument.Editor.RtcId);
        if results.Caching && ~cachedWebWindowExist
            % Clone last used webwindow for reuse.
            webWindow = matlab.internal.cef.webwindow(editorDocument.Editor.WebWindow.URL);
        end
    end
    cleanupDocument = onCleanup(@() editorDocument.closeNoPrompt);
    warning(warn);
catch ME
    if contains(lower(ME.message), "timeout")
        if results.Caching
            suggestion = getMsg("UseOption", "Caching = false");
            error(getMsg("Timeout", suggestion.getString));
        else
            error(getMsg("Timeout", ""));
        end
    else
        rethrow(ME);
    end
end

% Running.
if results.Run
    err = runDocumentByID(id, sourceFilePath);
    if ~results.CatchError && ~isempty(err)
        % Error and re-show the exec error in another line.
        error(getMsg('ExecutionError', newline, err.message));
    end
elseif isfield(results, 'needsRerun') && results.needsRerun
    % Warn if there was an option which may require running the script.
    warning(getMsg('NeedsReRun'))
end

% Finally, export with arguments passed through.
options = namedargs2cell(results);
outputAbsoluteFilename = matlab.desktop.editor.internal.exportDocumentByID(id, options{:});

end % export

%===============================================================
% Helper to execute a Live Script by its id.
% Returns an execution error as string, empty string otherwise.
function err = runDocumentByID(id, filename)
    % LiveEditorUtilities.execute runs the script in the base workspace
    % so we have to save and restore.
    varFile = [tempname '.mat'];
    evalin('base', ['save(''' varFile ''')']);
    evalin('base', 'clear all');
    function restoreBase(matfile)
        evalin('base', 'clear all');
        evalin('base', ['load(''' matfile ''')']);
        delete(matfile);
    end
    stRestoreBase = onCleanup(@()restoreBase(varFile));

    lasterror('reset') %#ok % not recommended but no alternative yet.

    % Change to the folder where live script is located.
    % This is necessary because data files, like MAT files, which are
    % needed by the live script are stored in the folder where the
    % live script is located.
    folder = fileparts(filename);
    cwd = cd(folder);
    obj = onCleanup(@() cd(cwd));

    % Actually run ...
    % Since we already know its a live script, we directly call doExecute.
    matlab.internal.liveeditor.LiveEditorUtilities.doExecute(id, filename);
    err = lasterror; %#ok
    % Catch strange unrelated errors.
    if strcmp(err.identifier, 'MATLAB:mpath:cannotAbsolutizePath')
        err = '';
    end
end

%===============================================================
% Helper functions.

% checkWritePermission checks if 'filename' can be overwritten.
% checkWritePermission throws an error if 'filename' is read-only.
%
% fileattrib is not reliable on Windows, therefore we just
% try to write to it.
% checkWritePermission is implemented in such a way that 'filename' is
% not overwritten.
function checkWritePermission(filename)
outFileExists = exist(filename, 'file');
if outFileExists
    tempFile = tempname;
    status = copyfile(filename, tempFile, "f");
end
[fid, err] = fopen(filename, 'w');
if fid < 0
    if outFileExists
      if status == 1
          delete(tempFile);
      end
      error(getMsg('OverrideError'));
    else
      error(getMsg('NoWritePermission', err));
    end
else
    fclose(fid);
    if outFileExists
        if status == 1
            movefile(tempFile, filename, "f");
        end
    else
        delete(filename);
    end
end
end

function fullFilename = getFullFilename(Filename)
fullFilename = ...
    matlab.desktop.editor.export.ExportUtils.getFullFilename(Filename);
end

function msg = getMsg(varargin)
msg = matlab.desktop.editor.export.ExportUtils.getMsg(varargin{:});
end

function tf = isLogical(varargin)
tf = matlab.desktop.editor.export.ExportUtils.isLogical(varargin{:});
end




