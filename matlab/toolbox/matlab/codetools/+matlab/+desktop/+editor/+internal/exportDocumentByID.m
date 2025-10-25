function result = exportDocumentByID(editorID, varargin)
%matlab.desktop.editor.internal.exportDocumentByID exports an RTC instance with given ID
%to a specific format.
%   If this function is called with just two arguments, the second is
%   interpeted as the target file path. Otherwise, the arguments are
%   expected as name/Value pairs.
%
%   FILEPATH = matlab.desktop.editor.exportDocumentByID(ID, FILEPATH) exports the
%   RTC instance given by ID to the file given by FILEPATH. The export
%   format is guessed from the FILEPATH.
%
%   RESULT = matlab.desktop.editor.exportDocumentByID(ID, VARARGIN) exports the
%   RTC instance given by ID to a target specified by given options.
%   VARARGIN is a sequence of name/value pairs where at least either 'Format' or
%   'Destination' (or both) must be specified.
%   See individual exporters in matlab.desktop.editor.export.* for supported options and return values.
%
% Examples:
%    import matlab.desktop.editor.internal.*
%    filePath = exportDocumentByID('123456', 'path/to/file.html')
%    filePath = exportDocumentByID('123456', "path/to/file.tex")
%    filePath = exportDocumentByID('123456', 'Destination', 'path/To/file.pdf', 'OpenExportedFile', true)
%    filePath = exportDocumentByID('123456', 'Format', 'tex', 'Destination', "path/To/file.txt")
%    htmlString = exportDocumentByID('123456', 'Format', 'html')

%   Copyright 2020-2022 The MathWorks, Inc.

  narginchk(2,inf);
  [varargin{:}] = convertContainedStringsToChars(varargin{:});
  if nargin == 2
      % If we have 2 arguments and the second could be file path,
      % we interpret it as a destination path.
      if mayBeAFilePath(varargin{1})
          options = struct('Destination', varargin{1});
      else
          error(message('MATLAB:narginchk:notEnoughInputs'));
      end
  else
      % Since we expect name/value pairs, check that the number of args is even.
      if mod(numel(varargin), 2) == 1
         error('Parameter names and values do not match.')
      end
      % Check if every other argument is a name.
      nonCharArgs = arrayfun(@(n) ~ischar(varargin{n}), 1:2:numel(varargin));
      if any(nonCharArgs)
        error ('Option names must be non-empty character vectors or string scalars.')
      end
      % Make a name/value struct.
      options = cell2struct(varargin(2:2:end), varargin(1:2:end), 2);
  end

  if isfield(options, 'Format')
      formatHint = options.Format;
  else
      if isfield(options, 'Destination')
          [fileDir, ~, formatHint] = fileparts(fullfile(char(options.Destination)));
          if ~isempty(fileDir) && ~exist(fileDir, 'file')
              error(['Path ' fileDir ' does not exist!']);
          end
          formatHint = lower(strip(formatHint, 'left', '.'));
     else
          error('Either Format or Destination must be specified');
     end
  end

  import matlab.desktop.editor.export.*;

  switch formatHint
      case 'm'
        exporter = MExporter;
      case {'html', 'htm'}
        exporter = HTMLExporter;
      case {'tex', 'latex'}
        exporter = LaTeXExporter;
      case {'pdf'}
        exporter = PDFExporter;
      case {'docx'}
        exporter = DOCXExporter;
      case {'docbookxml', 'xml'}
        exporter = DocBookXMLExporter;
      case {'md', 'rmd', 'markdown'}
        exporter = MarkdownExporter;
      case 'ipynb'
        exporter = IPYNBExporter;
     otherwise
        error(['Unknown export format: ' formatHint])
  end

  result = exporter.export(editorID, options);
end

% Helper function to detect a potential target file path.
% Basically it checks for a filename and an extension.
function result = mayBeAFilePath(inValue)
    result = false;
    if ischar(inValue)
        [~, name, ext] = fileparts(inValue);
        if ~isempty(name) && ~isempty(ext)
            result = true;
        end
    end

end
