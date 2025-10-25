%--------------------------------------------------------------------------
% convertLaTeX2Markdown converts a LaTeX file to a Markdown file.
%
% convertLaTeX2Markdown is called from MarkdownExporter.export.
%--------------------------------------------------------------------------

% Copyright 2022-2024 The MathWorks, Inc.

function result = convertLaTeX2Markdown(options)

import matlab.desktop.editor.export.ExportUtils
import matlab.desktop.editor.export.MarkdownExporter

%------------------------------------------------------------------------
% Preprocess options - these are the options used by convertLaTeX2Markdown

texFilename    = options.Destination;
mdFilename     = options.MarkdownDestination;
figureFormat   = options.FigureFormat;
includeOutputs = options.IncludeOutputs;
moveImages     = options.MoveImages;

imagePath = validateImagePath(options);
if imagePath ~= ""
    % imagePath is a child directory of the directory where the .md file
    % should be stored.
    useCustomPath = true;
    mdImageFolder = imagePath;
else
    % imagePath is not set, is an absolute path, or is not a child
    % directory of the directory where the .md file should be stored.
    % In this case, we do not throw error but fall back to the default
    % directory for storing images.
    useCustomPath = false;
    mdImageFolder = ExportUtils.imageFolder(mdFilename);
end
texImageFolder = ExportUtils.imageFolder(texFilename);

%------------------------------------------------------------------------
% Clean up temporary files and folders

% Remove temporary LaTeX file when processing is done.
obj1 = onCleanup(@() ExportUtils.deleteFile(texFilename));
% Remove temporary LaTeX image folder when processing is done.
if moveImages
    obj2 = onCleanup(@() ExportUtils.deleteFolder(texImageFolder));
end
path = fileparts(texFilename);
styFile = fullfile(path, "matlab.sty");
obj3 = onCleanup(@() ExportUtils.deleteFile(styFile));

%------------------------------------------------------------------------
% Parse name-value pairs used by latex2markdown

options = namedargs2cell(options);

% We need to parse and validate some specific name-value pairs.
p = inputParser; p.KeepUnmatched = true;
addParameter(p, "AcceptHTML"         , true    , @ExportUtils.isLogical            );
addParameter(p, "HTMLanchors"        , true    , @ExportUtils.isLogical            );
addParameter(p, "EmbedImages"        , true    , @ExportUtils.isLogical            );
addParameter(p, "RenderLaTeXOnline"  , "off"   , @ExportUtils.isValidCodeCogsValue );
addParameter(p, "MarkdownFormat"     , "github", @ExportUtils.isValidMarkdownFormat);
addParameter(p, "ProgrammingLanguage", "matlab", @ExportUtils.isValidKernel        );
addParameter(p, "ToC"                , true    , @ExportUtils.isLogical            );
parse(p, options{:});

options = namedargs2cell(p.Results);
%------------------------------------------------------------------------

result = mdFilename;

% read content of the LaTeX file
texText = string(fileread(texFilename, "encoding", "UTF-8"));

% Postprocess LaTeX file
if ~includeOutputs
    texText = ExportUtils.removeOutputs(texText);
end

% Process image files

texText = processImages(texText, texImageFolder);

% Process figure and table outputs
if isfield(p.Unmatched, "IPYNBDestination")
    texText = preprocessFigureOutputs(texText);
end

% Main function to convert LaTeX to Markdown
if contains(figureFormat, ["jpg", "jpeg"])
    options = {options{:}, "png2jpeg", true}; %#ok
end
if isfield(p.Unmatched, "IPYNBDestination")
    options = {options{:}, "isIPYNB", true};  %#ok
    mediaFolder = mdImageFolder;
else
    options = {options{:}, "isIPYNB", false}; %#ok
    mediaFolder = ExportUtils.RelativePath(mdImageFolder, mdFilename);
end
mdText = latex2markdown(texText, texFilename, options{:});

% Postprocess Markdown file
mdText = ExportUtils.postProcessing( ...
    mdText, mediaFolder, texImageFolder, useCustomPath ...
);

% Write Markdown file
ExportUtils.writeFile(mdFilename, mdText);

% Move image folder
if moveImages
    ExportUtils.moveImageFolder(texImageFolder, mdImageFolder);
end

end % convertLaTeX2Markdown

%------------------------------------------------------------------------
% There is a bug in export to LaTeX: images that are animated GIF are
% stored with the file extension .png. The file extension must be
% changed to .gif.
% Note: Do not remove this code even if the bug is fixed.
%       This is still needed for older MATLAB releases.

function texText = processImages(texText, folder)
files = dir(folder);
for i=1:numel(files)
    file = files(i); file = fullfile(folder, file.name);
    [path,name,ext] = fileparts(file);
    if strcmpi(ext, ".png") && startsWith(name, "image_")
        info = imfinfo(file);
        if numel(info) > 1 && strcmpi(unique({info.Format}), "gif")
            newfile = fullfile(path, name + ".gif");
            movefile(file, newfile);
            texText = replace(texText, file, newfile);
        end
    end
end
end % processImages

%------------------------------------------------------------------------

function content = preprocessFigureOutputs(content)
% Delete figure output
content = processFigureOutput(content, "matlabcode");
content = processFigureOutput(content, "matlaboutput");
content = processFigureOutput(content, "matlabsymbolicoutput");
end % preprocessFigureOutputs

function content = processFigureOutput(content, outputType)
env = "\end{" + outputType + "}";
start = env + newline + "\begin{center}";
stop = "\end{center}";
figure = extractBetween(content, start, stop, "Boundaries", "inclusive");
newfigure = replace(figure, "\begin{center}", "```FigureOutput");
newfigure = replace(newfigure, "\end{center}", "```");
content = replace(content, figure, newfigure);
end % processFigureOutput

%------------------------------------------------------------------------

function path = validateImagePath(options)
if ~isfield(options, "imagePath")
    path = "";
    return;
end
path = fullfile(strtrim(options.imagePath));
if path == "" || path == "." || path == "." + filesep || ...
   contains(path, ":") || startsWith(path, filesep) || ...
   (ispc && contains(path, ":"))
    path = "";
    return;
end
end % validateImagePath

