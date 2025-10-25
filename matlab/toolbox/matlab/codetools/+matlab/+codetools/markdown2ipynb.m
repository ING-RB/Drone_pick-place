function ipynbFilename = markdown2ipynb(varargin)

% MARKDOWN2IPYNB Convert Markdown file to Jupyter Notebook (IPYNB file)
%
% Syntax:
% markdown2ipynb(mdFilename, ipynbFilename)
% markdown2ipynb(mdFilename, ipynbFilename, Name, Value)
%
% Description:
% markdown2ipynb(mdFilename, ipynbFilename)
%    converts the Markdown file 'mdFilename' to a Jupyter Notebook and
%    saves it to the file 'ipynbFilename'.
%
% Input Arguments:
% mdFilename    - a string or character array representing a filename,
%                 which can include an absolute or relative path.
%                 The file extension should be .md or .rmd or .markdown.
% ipynbFilename - a string or character array representing a filename,
%                 which can include an absolute or relative path.
%                 The file extension should be .ipynb.
%
% Output Arguments:
% ipynbFilename - Same as input argument 'ipynbFilename' but with an
%                 absolute path instead of a releative path.
%
% Name-Value Pairs:
% MergeCells -     true or false. The default is true.
%                  If MergeCells = true then all consecutive lines of text
%                  are merged into a single IPYNB Markdown cell.
%                  If MergeCells = false then each block of text separated
%                  by an empty line creates its own IPYNB Markdown cell.
% CopyImages -     true or false. The default is true.
%                  Note: This option is ignored when EmbedImages = true.
%                  If CopyImages = true then all images included in the
%                  Markdown file 'mdFilename' are copied to the folder
%                  where the Jupyter Notebook 'ipynbFilename' is located.
%                  The images are stored in the folder ipynbFilename_images.
%                  Example: If 'tmp/test.ipynb' is the name of the Jupyter
%                  Notebook, then all images are stored in the folder
%                  'test_images' which is located in the folder 'tmp'.
%                  If CopyImages = false then the images included in the
%                  Markdown file 'mdFilename' are not copied to a new folder.
% EmbedImages -    true or false. Default is true.
%                  If EmbedImages = true, images are embedded in the IPYNB
%                  file as based64 encoded strings.
%                  If EmbedImages = false, then the IPYNB file just
%                  contains links to the images which are stored in a
%                  folder. E.g.,
%                  markdown2ipynb("penny.md", "penny.ipynb", ...
%                                 EmbedImages = false, CopyImages = true)
%                  will store all images contained in "penny.md" in the
%                  folder penny_images, and this folder is located in the
%                  same folder where penny.ipynb is located.
% ProgrammingLanguage - a string. Default is "matlab".
%                  All code chunks in the Markdown file are interpreted
%                  as code written in the programming language
%                  'ProgrammingLanguage', e.g. in the MATLAB language.
%                  'ProgrammingLanguage' can be also an empty string.
%                  If it is the empty string, then the language defined
%                  by the code chunk, e.g. ```python, will be used.
%
% Examples:
% >> markdown2ipynb("path/to/test.md", "other/path/to/mytest.ipynb")
%
% >> markdown2ipynb("test.md", "test.ipynb", MergeCells = false)
%
% Note:
% markdown2ipynb is also called from the function export. E.g.,
% >> export("path/to/test.mlx", "other/path/to/mytest.ipynb")
%
% See also:
% export
%
% Copyright 2022-2025 The MathWorks, Inc.

import matlab.desktop.editor.export.ExportUtils

% Validate input arguments
[mdFilename, ipynbFilename, options] = validateArguments(varargin{:});

% Read the content of the Markdown File
content = fileread(mdFilename, "encoding", "UTF-8");

% Create folder names for images
mdImageDir = ExportUtils.imageFolder(mdFilename);
if ~options.EmbedImages
    ipynbImageDir = ExportUtils.imageFolder(ipynbFilename);
end

% Remove temporary file and folder
if calledbyExport(options)
    obj1 = onCleanup(@() ExportUtils.deleteFile(mdFilename));
    obj2 = onCleanup(@() ExportUtils.deleteFolder(mdImageDir));
end

% Main function: Convert Markdown to IPYNB
json = convertMarkdown2ipynb(content, options);

% Postprocess IPYNB file
if ~options.EmbedImages
    if isfield(options, "imagePath")
        mediaDir = ExportUtils.RelativePath(options.imagePath, ipynbFilename);
        json = ExportUtils.postProcessing(json, mediaDir, options.imagePath, true);
    else
        json = ExportUtils.postProcessing(json, ipynbImageDir, mdImageDir);
    end
    if calledbyExport(options)
        % mardown2ipynb was called by export(...) or exportDocumentByID(...)
        ExportUtils.moveImageFolder(mdImageDir, ipynbImageDir)
    elseif options.CopyImages
        % mardown2ipynb was called directly
        ExportUtils.copyImageFolder(mdImageDir, ipynbImageDir)
    end
end

% Remove empty Markdown cells
json = removeEmptyCells(json);

% Postprocess json
json = postprocess(json);

% Write IPYNB file
ExportUtils.writeFile(ipynbFilename, json);

end % markdown2ipynb

%==========================================================================

%--------------------------------------------------------------------------
% convertMarkdown2ipynb contains the main functionality of markdown2ipynb
%--------------------------------------------------------------------------

function json = convertMarkdown2ipynb(content, options)

content = preprocessTeX(content);

% An input can generate outputs containing multiple parts, e.g.
% a text, a figure, and a table output. Group such multiple outputs,
% so that it regonized as a single output region.
content = encapsulateOutputs(content);

Lines = string(strsplit(content, newline, "CollapseDelimiters", false));

language = {}; cnt = 0; firstCell = true; ma = 1; mb = 0;
inCode = false; inOutput = false; codeCnt = 1;
CodeCell = string.empty; n = numel(Lines);

json = header();

for i=1:n
    line = Lines(i);
    if strcmp(strtrim(line), "") && ~options.MergeCells
        if ~inCode && ~inOutput
            mb = i-1;
            if ~isEmpty(Lines, ma, mb)
                json = json + ...
                    markdownCell(Lines, ma, mb, firstCell, options);
                ma = i+1; firstCell = false;
            end
        end
    elseif startsWith(line, "!!!BeginOutputRegion!!!")
        inOutput = true; cnt = 0;
    elseif startsWith(line, "!!!EndOutputRegion!!!")
        CodeCell = OutputCellFooter(CodeCell);
        inOutput = false;
    elseif startsWith(line, "```TextOutput") || ...
           startsWith(line, "```matlabTextOutput")
        inOutput = true; outputType = "Text"; cnt = cnt + 1;
    elseif startsWith(line, "```SymbolicOutput")
        inOutput = true; outputType = "Symbolic"; cnt = cnt + 1;
    elseif startsWith(line, "```FigureOutput")
        inOutput = true; outputType = "Figure"; cnt = cnt + 1;
    elseif startsWith(line, "```TableOutput")
        inOutput = true; outputType = "Table"; cnt = cnt + 1;
    elseif startsWith(line, "```")
        if inOutput
            args = {CodeCell, Lines, ma, mb, cnt};
            switch outputType
                case "Text"
                    output = TextOutputCell(args{:});
                case "Figure"
                    output = FigureOutputCell(args{:});
                case "Table"
                    output = TableOutputCell(args{:});
                case "Symbolic"
                    output = SymbolicOutputCell(args{:});
            end
            CodeCell = string(CodeCell) + output;
            ma = i+1; mb = 0;
            continue;
        end
        if ~isempty(CodeCell)
            json = json + CodeCell; CodeCell = string.empty;
        end
        if ~isEmpty(Lines, ma, mb)
           json = json + markdownCell(Lines, ma, mb, firstCell, options);
           firstCell = false;
        end
        if inCode
            cb = i-1; inCode = false;
            if ca > cb
                cnt = cnt - 1;
            else
                CodeCell = codeCell(Lines, ca, cb, codeCnt, firstCell);
                firstCell = false; ma = i+1; mb = 0; codeCnt = codeCnt + 1;
            end
        else
            ca = i+1; inCode = true; cnt = cnt + 1; ma = i+1; mb = 0;
            if ~strcmp(options.ProgrammingLanguage, "")
                % Set given language regardless which language is
                % specified for the code block (code chunk).
                language = options.ProgrammingLanguage;
            else
                % Set language specified for the code block (code chunk).
                language = getLanguageInfo(line, language);
            end
        end
    elseif ~inCode
        if mb == 0
            ma = i; mb = i;
        else
            mb = i;
        end
    end
end
if ~isempty(CodeCell)
    json = json + CodeCell;
    if endsWith(json, '"outputs": [')
        json = json + "]" + newline + "}" + newline;
    end
end
if ma <= mb && ~isEmpty(Lines, ma, max(mb, n))
    json = json + markdownCell(Lines, ma, max(mb, n), firstCell, options);
end

language = setLanguage(language, options);

json = json + footer();
json = json + metadata(language);

end % convertMarkdown2ipynb

%--------------------------------------------------------------------------

function [mdFilename, ipynbFilename, options] = validateArguments(varargin)

import matlab.desktop.editor.export.ExportUtils

p = inputParser;

if nargin == 1 && isstruct(varargin{1})
    options = varargin{1};
    p.KeepUnmatched = true;
    % Restruture options for markdown2ipynb.
    % Note: markdown2ipynb ignores all options (name-value pairs)
    % which are unknown by markdown2ipynb. In other words:
    % markdown2ipynb does not throw an error if options are
    % unknown.
    mdFilename = options.MarkdownDestination;
    ipynbFilename = options.IPYNBDestination;
    options = namedargs2cell(options);
elseif nargin < 2
    error(message("MATLAB:minrhs"));
else
    mdFilename    = varargin{1};
    ipynbFilename = varargin{2};
    if nargin > 2
        options   = varargin(3:end);
    else
        options   = {};
    end
    p.KeepUnmatched = false;
end

addParameter(p, "MergeCells"         , true,     @ExportUtils.isLogical);
addParameter(p, "CopyImages"         , true,     @ExportUtils.isLogical);
addParameter(p, "EmbedImages"        , true,     @ExportUtils.isLogical);
addParameter(p, "ProgrammingLanguage", "",       @ExportUtils.isString );
addParameter(p, "IncludeOutputs"     , false,    @ExportUtils.isLogical);
addParameter(p, "AcceptHTML"         , true,     @ExportUtils.isLogical);

parse(p, options{:});
options = p.Results;
f = fields(p.Unmatched);
for i=1:numel(f)
    options.(f{i}) = p.Unmatched.(f{i});
end

[~, ~, ext] = fileparts(mdFilename);
if ~any(strcmpi(ext, [".md", ".rmd"]))
    Error("MarkdownFileExtensionExpected");
end
if ~exist(mdFilename, "file")
    Error("ScriptFileNotFound");
end

if exist(ipynbFilename, "file")
    [status, fattrib] = fileattrib(ipynbFilename);
    if ~(status && fattrib.UserWrite)
        Error("OverrideError");
    end
    % Get full path
    info = dir(ipynbFilename);
    ipynbFilename = fullfile(info.folder, info.name);
end

[fullFilename, status] = ExportUtils.getFullFilename(mdFilename);
if status == 0
    options.imageDir = string.empty;
else
    [path, name] = fileparts(fullFilename);
    options.imageDir = fullfile(path, name + "_images");
end

if isfield(options, "imagePath") && ...
   (endsWith(options.imagePath, "/") || endsWith(options.imagePath, "\"))
    options.imagePath = options.imagePath(1:end-1);
end

end % validateArguments

%--------------------------------------------------------------------------

function language = getLanguageInfo(line, language)
% Get language from
% ```language
%   or
% ```language:...
%   or
% ```{language ...}
%   or
% ```{.language ...}
line = char(line); cellLang = line(4:end); cellLang = deblank(cellLang);
if ~isempty(cellLang)
    lang = extractBetween(cellLang, "{", "}");
    if ~isempty(lang)
        lang = strtrim(lang{1}); lang = strsplit(lang, " ");
        cellLang = lang{1};
    end
    cellLang = strsplit(cellLang, ":"); cellLang = cellLang{1};
    if strcmp(cellLang(1), ".")
        cellLang = cellLang(2:end);
    end
end
language = [language, cellLang];

end % getLanguageInfo

%--------------------------------------------------------------------------

function language = setLanguage(lang, options)

if isempty(lang)
    if ~strcmp(options.ProgrammingLanguage, "")
        lang = options.ProgrammingLanguage;
    else
        language = '';
        return;
    end
end
lang = strtrim(lang);
if iscell(lang)
    language = lang{1};
else
    language = lang; lang = {char(lang)};
end
lang = unique(lang);
if numel(lang) > 1
    Warning("MultipleLanguagesSpecified", language);
end
end % setLanguage

%--------------------------------------------------------------------------

function json = header()
json = "{" + newline;
json = json + ' "cells": [' + newline;
end

%--------------------------------------------------------------------------

function json = footer()
json = sprintf("\n ],\n");
end % header

%--------------------------------------------------------------------------

function json = metadata(language)

lang = strtrim(language); language = lower(lang);
if startsWith(language, "matlab")
    json = metadataMATLAB();
elseif startsWith(language, "python")
    json = metadataPython(language);
else
    if strcmp(language, "")
        Warning("NoLanguageSpecified");
    else
        Warning("LanguageNotSupported", lang);
    end
    json = metadataGeneric(language);
end
end % metadata

%--------------------------------------------------------------------------

function json = metadataMATLAB()
%--------------------------------------------------------------------------
% MATLAB language
%
% pygments_lexer: See
% https://pygments.org/docs/lexers/#lexers-for-matlab-and-related-languages
%--------------------------------------------------------------------------

% Note: kernel.display_name and kernel.name are preliminary.
% They must be updated as soon as a MathWorks MATLAB Kernel for Jupyter
% is available.

Version = string(strsplit(version, " ")); Version = Version(1);

% Information for kernelspec
kernel.language     = "matlab";
kernel.display_name = "MATLAB (matlabkernel)";
kernel.name         = "matlab";
% Information for language_info
lang.file_extension     = ".m";
lang.mimetype           = "text/matlab";
lang.name               = "matlab";
lang.nbconvert_exporter = "matlab";
lang.pygments_lexer     = "matlab";
lang.version            = Version;

json = metadataTemplate(kernel, lang);

end % metadataMATLAB

%--------------------------------------------------------------------------

function json = metadataPython(language)
%--------------------------------------------------------------------------
% Python language
%
% pygments_lexer: See https://pygments.org/docs/lexers/ , ipython3
%--------------------------------------------------------------------------

% Get version of Python used by MATLAB.
if strcmp(language, "python")
    pe = pyenv; Version = pe.Version; major = "";
    if ~strcmp(Version, "")
        v = strsplit(Version, "."); major = v(1);
    end
else
    v = erase(language, "python");
    if isnan(str2double(v))
        major = ""; Version = "";
    else
        major = v; Version = v;
    end
end

% Information for kernelspec
kernel.language     = "python";
kernel.display_name = "Python " + major + " (ipykernel)";
kernel.name         = "python" + major;
% Information for language_info
lang.file_extension     = ".py";
lang.mimetype           = "text/x-python";
lang.name               = "python";
lang.nbconvert_exporter = "python";
lang.pygments_lexer     = "ipython" + major;
lang.version            = Version;

json = metadataTemplate(kernel, lang);

end % metadataPython

%--------------------------------------------------------------------------

function json = metadataGeneric(language)
%--------------------------------------------------------------------------
% Unknown or unsupported language
%--------------------------------------------------------------------------

% Information for kernelspec
kernel.language     = language;
kernel.display_name = "";
kernel.name         = "";
% Information for language_info
lang.file_extension     = "";
lang.mimetype           = "text/plain";
lang.name               = "";
lang.nbconvert_exporter = language;
lang.pygments_lexer     = "";
lang.version            = "";

json = metadataTemplate(kernel, lang);

end % metadataGeneric

%--------------------------------------------------------------------------

function json = metadataTemplate(kernel, lang)
% The generic Template for the metadata in JSON encoded IPYNB format.
json = sprintf(' "metadata": {\n');
json = sprintf('%s  "kernelspec": {\n'             , json);
json = sprintf('%s   "display_name": "%s",\n'      , json, kernel.display_name);
json = sprintf('%s   "language": "%s",\n'          , json, kernel.language);
json = sprintf('%s   "name": "%s"\n'               , json, kernel.name);
json = sprintf('%s  },\n'                          , json);
json = sprintf('%s  "language_info": {\n'          , json);
json = sprintf('%s   "file_extension": "%s",\n'    , json, lang.file_extension);
json = sprintf('%s   "mimetype": "%s",\n'          , json, lang.mimetype );
json = sprintf('%s   "name": "%s",\n'              , json, lang.name);
json = sprintf('%s   "nbconvert_exporter": "%s",\n', json, lang.nbconvert_exporter);
json = sprintf('%s   "pygments_lexer": "%s",\n'    , json, lang.pygments_lexer);
json = sprintf('%s   "version": "%s"\n'            , json, lang.version);
json = sprintf('%s  }\n'                           , json);
json = sprintf('%s },\n'                           , json);
json = sprintf('%s%s\n'                            , json, nbformat());
json = sprintf('%s}\n'                             , json);

end % metadataTemplate

%--------------------------------------------------------------------------

function json = nbformat()
% nbformat 4.4 is used.
json = sprintf(' "nbformat": 4,\n');
json = sprintf('%s "nbformat_minor": 4', json);

end % nbformat

%--------------------------------------------------------------------------

function json = markdownCell(Lines, a, b, firstCell, options)
% The source of the Markdown cell contains the lines from 'a' to 'b'.
lines = Lines(a:b);
if strcmp(strtrim(strjoin(lines)), "!!!EndOutputRegion!!!")
    json = '';
    return;
end

json = genericCell(Lines, a, b, 0, firstCell, "markdown");

raw = extractBetween(json, "```", "```", "Boundaries", "inclusive");
newraw = replace(raw, "![", "!!!BRACKET!!!");
newraw = replace(newraw, "<img", "!!!IMAGETAG!!!");
json = replace(json, raw, newraw);

js = eraseBetween(json, "\begin{matlabtableoutput}", "\end{matlabtableoutput}");
js = eraseBetween(js, "```", "```");

if options.EmbedImages && (contains(js, "![") || contains(js, "<img"))
    [json, attachments] = embedImages(json, options);
    if firstCell
        json = sprintf('  {\n%s%s', attachments, json);
    else
        json = sprintf(',\n  {\n%s%s', attachments, json);
    end
else
    if firstCell
        json = sprintf('  {\n%s', json);
    else
        json = sprintf(',\n  {\n%s', json);
    end
end
end % markdownCell

%--------------------------------------------------------------------------

function json = codeCell(Lines, a, b, cnt, firstCell)
% The source of the Code cell contains the lines from 'a' to 'b'.
% 'cnt' specifies that it is code cell number 'cnt'.
json = genericCell(Lines, a, b, cnt, firstCell, "code");
json = string(json);
end % codeCell

%--------------------------------------------------------------------------

function json = genericCell(Lines, a, b, cnt, firstCell, type)
% The source of the cell contains the lines from 'a' to 'b'.
% If it's not the first cell, then we have to add a ',\n' to json.
if strcmp(type, "code")
    if firstCell; json = ''; else; json = sprintf(',\n'); end
    json = sprintf('%s  {\n', json);
else
    json = '';
end

json = sprintf('%s   "cell_type": "%s",\n'    , json, type);
if strcmp(type, "code")
    json = sprintf('%s   "execution_count": %d,\n', json, cnt);
end
json = sprintf('%s   "metadata": {},\n'       , json);
json = sprintf('%s   "source": [\n'           , json);
for i=a:b-1
    json = printLine(json, maskedBackslash(Lines(i), type), true);
end
json = printLine(json, maskedBackslash(Lines(b), type), false);
if strcmp(type, "code")
    json = sprintf('%s   ],\n'                , json);
    json = sprintf('%s   "outputs": ['        , json);
else
    json = sprintf('%s   ]\n'                 , json);
    json = sprintf('%s  }'                    , json);
end

end % genericCell

%--------------------------------------------------------------------------

function json = printLine(json, line, appendNewline)
if startsWith(line, '<img src="https://latex.codecogs.com/')
    json = sprintf('%s    "$$\\n",\n'     , json);
    line = extractBetween(line, '?', '"/>');
    line = replace(line, ["&space;", "\"], [" ", "\\"]);
    json = sprintf('%s    "%s\\n",\n'    , json, line);
    if appendNewline
        json = sprintf('%s    "$$\\n",\n', json);
    else
        json = sprintf('%s    "$$",\n'   , json);
    end
else
    if appendNewline
        json = sprintf('%s    "%s\\n",\n', json, text(line));
    else
        json = sprintf('%s    "%s"\n'    , json, text(line));
    end
end
end % printLine

%--------------------------------------------------------------------------

function line = text(line)
line = replace(deblank(line), '"', '\"');
end % text

%--------------------------------------------------------------------------

function tf = isEmpty(Lines, a, b)
tf = a > b || (a == b && strcmp(text(Lines(a)), "")) || ...
     (a == b && strcmp(text(Lines(a)), "!!!EndOutputRegion!!!")) || ...
     (a+1 == b && Lines(a) == "" && Lines(b) == "!!!EndOutputRegion!!!");
end % isEmpty

%--------------------------------------------------------------------------

function tf = calledbyExport(options)
tf = isfield(options, "Destination");
end

%--------------------------------------------------------------------------

function content = preprocessTeX(content)

content = replace(content, "\$", "!!!DOLLAR!!!"   );
content = replace(content, "$$", "!!!BLOCKTEX!!!" );
content = replace(content, "$" , "!!!INLINETEX!!!");
content = replace(content, "\\", "!!!NEWLINE!!!"  );
TeX = extractBetween(content, "!!!BLOCKTEX!!!", "!!!BLOCKTEX!!!", "Boundaries", "inclusive");
newTeX = replace(TeX, char(13), ' ');
newTeX = replace(newTeX, newline, '');
newTeX = replace(newTeX, '\', '\\');
newTeX = strtrim(newTeX);
content = replace(content, TeX, newTeX);
TeX = extractBetween(content, "!!!INLINETEX!!!", "!!!INLINETEX!!!", "Boundaries", "inclusive");
newTeX = replace(TeX, char(13), ' ');
newTeX = replace(newTeX, newline, '');
newTeX = replace(newTeX, '\', '\\');
newTeX = strtrim(newTeX);
content = replace(content, TeX, newTeX);
content = replace(content, "!!!DOLLAR!!!"   , "\$");
content = replace(content, "!!!BLOCKTEX!!!" , "$$");
content = replace(content, "!!!INLINETEX!!!", "$" );
content = replace(content, "!!!NEWLINE!!!"  , "\\\\");

end % preprocessTeX

%--------------------------------------------------------------------------

function [json, attach] = attachmentsCell(json, imageFiles, options)

attach = sprintf('   "attachments": {\n');
noImageFound = true; n = numel(imageFiles);

for i=1:n
    imageFile = imageFiles{i};
    [status, base64] = encodeImage(imageFile, options);

    if status == 0
        % image not found
        Warning("ImageNotFound", imageFile);
        continue;
    end

    [~,name,ext] = fileparts(char(imageFile));
    filename = [name, ext]; ext = ext(2:end);

    attach = sprintf('%s    "%s": {\n'          , attach, filename);
    attach = sprintf('%s     "image/%s": "%s"\n', attach, ext, base64);
    if i < n
        attach = sprintf('%s    },\n'               , attach);
    else
        attach = sprintf('%s    }\n'            , attach);
        attach = sprintf('%s   },\n'            , attach);
    end

    noImageFound = false;

    json = replace(json, imageFile, "attachment:" + filename);
end

if noImageFound
    attach = string.empty;
end

end % attachmentsCell

%--------------------------------------------------------------------------

function json = removeEmptyCells(json)
md = extractBetween(json, 'cell_type": "markdown",', ']', ...
                          'Boundaries','inclusive');
n = numel(md); newmd = strings(n, 1); pat = '"source": [';
src = extractBetween(md, '"source": [', ']');
for k=1:n
    if strcmp(strtrim(replace(src(k), {'"\n",', '""'}, {'', ''})), "")
        newmd(k) = replace(md(k),  pat + src(k) + ']', '"source": []');
    else
        newmd(k) = md(k);
    end
end
json = replace(json, md, newmd);

% Empty Markdown cell before Metadata
emptyCell = "";
emptyCell = emptyCell + ',' + newline;
emptyCell = emptyCell + '  {' + newline;
emptyCell = emptyCell + '   "cell_type": "markdown",' + newline;
emptyCell = emptyCell + '   "metadata": {},' + newline;
emptyCell = emptyCell + '   "source": []' + newline;
emptyCell = emptyCell + '  }' + newline;
emptyCell = emptyCell + ' ],';
json = replace(json, emptyCell, " ],");

% Empty Markdown cells
emptyCell = "";
emptyCell = emptyCell + '  {' + newline;
emptyCell = emptyCell + '   "cell_type": "markdown",' + newline;
emptyCell = emptyCell + '   "metadata": {},' + newline;
emptyCell = emptyCell + '   "source": []' + newline;
emptyCell = emptyCell + '  },' + newline;
json = erase(json, emptyCell);
end % removeEmptyCells

%--------------------------------------------------------------------------

function [json, attachments] = embedImages(json, options)
images = extractBetween(json, "![", ")", "Boundaries", "inclusive");
images = extractBetween(images, "](", ")");
[json, attachments] = attachmentsCell(json, images, options);
end % embedImages

%--------------------------------------------------------------------------

function json = TextOutputCell(CodeCell, Lines, a, b, cnt)
json = OutputCell(CodeCell, Lines, a, b, cnt, "Text");
end

function json = SymbolicOutputCell(CodeCell, Lines, a, b, cnt)
json = OutputCell(CodeCell, Lines, a, b, cnt, "Symbolic");
end

function json = TableOutputCell(CodeCell, Lines, a, b, cnt)
json = OutputCell(CodeCell, Lines, a, b, cnt, "Table");
end

function json = FigureOutputCell(CodeCell, Lines, a, b, cnt)
json = OutputCell(CodeCell, Lines, a, b, cnt, "Figure");
end

%--------------------------------------------------------------------------

function json = OutputCellFooter(CodeCell)
json = sprintf('%s\n   ]\n', CodeCell);
json = sprintf('%s  }'   , json);
end

function json = OutputCell(CodeCell, Lines, a, b, cnt, OutputType)
if cnt == 1
    json = sprintf('\n    {\n');
    json = sprintf('%s%s', json, dataPart(Lines, a, b, OutputType));
    n = extractBetween(CodeCell, '"execution_count":', newline);
    n = n{1};
else
    json = sprintf(',\n    {\n');
    json = sprintf('%s%s', json, dataPart(Lines, a, b, OutputType));
end
json = sprintf('%s     "metadata": {},\n'                    , json);
if cnt == 1
    json = sprintf('%s     "execution_count": %s\n'          , json, n);
    json = sprintf('%s     "output_type": "execute_result"\n', json);
else
    json = sprintf('%s     "output_type": "display_data"\n' , json);
end
json = sprintf('%s    }'                                     , json);
end

%--------------------------------------------------------------------------

function json = dataPart(Lines, a, b, OutputType)
lines = strjoin(Lines(a:b), newline);
switch OutputType
    case "Text"
        lines = erase(lines, "```TextOutput");
        lines = erase(lines, "```matlabTextOutput");
    case "Symbolic"
        lines = erase(lines, "```SymbolicOutput");
    case "Table"
        lines = erase(lines, "```TableOutput");
    case "Figure"
        lines = erase(lines, "```FigureOutput");
end
lines = strtrim(lines);
lines = strsplit(lines, newline); n = numel(lines);
json = sprintf('     "data": {\n');
switch OutputType
    case "Text"
        % Text outputs are always using plain text
        json = sprintf('%s      "text/plain": [\n', json);
    case {"Symbolic", "Table"}
        % Symbolic Output and Tables are always using TeX syntax
        json = sprintf('%s      "text/latex": [\n', json);
    case "Figure"
        % Figures are always using HTML syntax
        json = sprintf('%s      "text/html": [\n', json);
end
for k=1:n-1
    json = sprintf('%s       "%s\\n",\n', json, adapt(lines(k)));
end
json = sprintf('%s       "%s"\n', json, adapt(lines(n)));
json = sprintf('%s      ]\n', json);
json = sprintf('%s     },\n', json);

json = maskedBackslash(json, OutputType);

end

function str = adapt(str)
str = replace(str, '"', '\"');
str = replace(str, "data:image/;base64,", "data:image;base64,");
end

function json = maskedBackslash(json, OutputType)
switch lower(OutputType)
    case {"code", "markdown"}
        specialCharacters = "\\";
        subsCharacters    = "!!!SLASH!!!";
    case "table"
        specialCharacters = ["\\", "\n", '\"'];
        subsCharacters    = ["!!!SLASH!!!", "!!!NEWLINE!!!", ...
                             "!!!DOUBLEQUOTE"];
    case "text"
        specialCharacters = ...
            ["\\", "\n", "\r", "\f", "\t", "\b", "\'", '\"'];
        subsCharacters    = ...
            ["!!!SLASH!!!", "!!!NEWLINE!!!", "!!!RETURN!!!", ...
             "!!!FORMFEED!!!", "!!!TAB!!!", "!!!BACK!!!",    ...
            "!!!SINGLEQUOTE!!!", "!!!DOUBLEQUOTE"];
    otherwise
        return;
end
json = replace(json, specialCharacters, subsCharacters);
json = replace(json, "\", "\\");
json = replace(json, subsCharacters, specialCharacters);
end

%--------------------------------------------------------------------------

function content = encapsulateOutputs(content)
inOutput = false; n = 0;
lines = string(strsplit(content, newline, "CollapseDelimiters", false));
m = numel(lines);
for k=1:m
    line = strtrim(lines(k));
    if ~startsWith(line, "```")
        if line ~= "" && inOutput && n == 0
            lines(k) = "!!!EndOutputRegion!!!" + newline + line;
            inOutput = false;
        end
    else % line starts with ```
        if startsWith(line, "```TextOutput")       || ...
           startsWith(line, "```matlabTextOutput") || ...
           startsWith(line, "```TableOutput")      || ...
           startsWith(line, "```FigureOutput")     || ...
           startsWith(line, "```SymbolicOutput")
            if ~inOutput
                lines(k) = "!!!BeginOutputRegion!!!" + newline + line;
            end
            inOutput = true; n = n + 1;
        else
            if ~startsWith(lines(k), "```")
                continue;
            end
            if line == "```"
                if inOutput
                    n = n - 1;
                end
            elseif inOutput && n == 0
                lines(k) = "!!!EndOutputRegion!!!" + newline + line;
                inOutput = false;
            end
        end
    end
end
if inOutput
    lines(m) = lines(m) + newline + "!!!EndOutputRegion!!!";
end
content = strjoin(lines, newline);
end

%--------------------------------------------------------------------------

function json = postprocess(json)
% Empty outputs must be corrected.
emptyOutput1 = ['"outputs": []', newline, '  },'];
emptyOutput2 = ['"outputs": []', newline, '  }', ' ],'];
json = replace(json, '"outputs": [,', emptyOutput1);
json = replace(json, ['"outputs": [', newline, ' ],'], emptyOutput2);
json = erase(json, '"!!!BeginOutputRegion!!!\n",');
json = erase(json, '"!!!EndOutputRegion!!!\n",');
% Replace tabular by array
json = replace(json, "\begin{tabular}", "\begin{array}");
json = replace(json, "\end{tabular}", "\end{array}");
% Replace \multicolumn in array
arrays = extractBetween(json, "\begin{array}", "\end{array}");
for j=1:numel(arrays)
    array = arrays(j);
    mcols = extractBetweenBraces(array, "\multicolumn");
    for k=1:numel(mcols)
        align =extractBetween(array, "}{", "}{");
        ncol = str2double(mcols{k}); align = align{1};
        pat = sprintf("\\multicolumn{%d}{%s}", ncol, align);
        text = extractBetweenBraces(arrays(k), pat); text = text{1};
        old = sprintf("\\\\multicolumn{%d}{%s}{%s}", ncol, align, text);
        new = "" + text + replace(blanks(ncol-1), " ", " & ");
        json = replace(json, old, new);
    end
end
% Remove empty lines
lines = strsplit(json, newline);
newLines = lines; n = 1;
for k=1:numel(lines)
    if strtrim(lines(k)) ~= ""
        newLines(n) = lines(k); n = n + 1;
    end
end
lines = newLines(1:n-1);
json = strjoin(lines, newline);

tb = extractBetween(json, "\text{", "}", "Boundaries", "inclusive");
for k=1:numel(tb)
    if startsWith(tb(k), '\text{\"')
        newtb = replace(tb(k), '\text{\"', '\text{');
        newtb = replace(newtb, '\"}', '}');
        json = replace(json, tb(k), newtb);
    end
end

json = erase(json, "\\begin{matlabtableoutput}");
json = erase(json, "\\end{matlabtableoutput}");

json = replace(json, "<DOLLORSIGN>", "$");

end

%--------------------------------------------------------------------------

function Warning(msgID, varargin)
Message("warning", msgID, varargin{:});
end

function Error(msgID, varargin)
Message("error", msgID, varargin{:});
end

function Message(type, msgID, varargin)
status = warning("backtrace", "off");
obj = onCleanup(@() warning("backtrace", status.state));
if type == "warning"
    warning(matlab.desktop.editor.export.ExportUtils.getMsg(msgID, varargin{:}));
else % type == "error"
    error(matlab.desktop.editor.export.ExportUtils.getMsg(msgID, varargin{:}));
end
end

function [status, base64] = encodeImage(image, options)
[status, base64] = ...
    matlab.desktop.editor.export.ExportUtils.encodeImage(image, options);
end

%--------------------------------------------------------------------------

function extracted = extractBetweenBraces(content, cmd, varargin)
p = strfind(content, cmd + "{");
if isempty(p); extracted = {}; return; end
content = char(content);
p = p(1);
len = strlength(cmd) + 1;

braces = 1; q = p; q = q + len; slen = strlength(content);
while braces ~= 0 && q <= slen
    if content(q) == '}' && (q == 1 || (q > 1 && content(q-1) ~= '\'))
        braces = braces - 1;
    elseif content(q) == '{' && (q == 1 || (q > 1 && content(q-1) ~= '\'))
        braces = braces + 1;
    end
    q = q + 1;
end
extracted = content(p+len:q-2);

fullCmd = cmd + "{" + extracted + "}";
if ~contains(content, fullCmd)
    return;
end
content = replace(content, fullCmd, "");
if nargin == 3 && varargin{1} == true
    cmd = char(cmd);
    extracted = cmd + "{" + extracted + "}";
end
extracted = {extracted};

if ~strcmp(strtrim(content), '')
    extracted = [extracted, extractBetweenBraces(content, cmd, varargin{:})];
end

end