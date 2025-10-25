function writeFunction = parseWriteArguments(location, filePattern, ...
    isIri, isHdfs, prototype, ...
    otherArgs)
%PARSEWRITEARGUMENTS Parse the inputs to WRITE and return the appropriate
%writer object for writing out the output in the specified format.

%   Copyright 2018-2022 The MathWorks, Inc.

% Parse the extra args. First P-V pair must be FileType or OutputFcn.
parser = inputParser;
parser.FunctionName = "write";
addParameter(parser, "FileType", "auto");
addParameter(parser, "WriteFcn", [], @iIsValidWriteFcn);
% - Text options
addParameter(parser, "Delimiter", [])
addParameter(parser, "WriteVariableNames", [])
addParameter(parser, "QuoteStrings", [])
addParameter(parser, "DateLocale", [])
addParameter(parser, "Encoding", [])
% - Spreadsheet specific options
addParameter(parser, "Sheet", []);
% - Parquet specific options
addParameter(parser, "VariableCompression", []);
addParameter(parser, "VariableEncoding", []);
addParameter(parser, "Version", []);
parser.parse(otherArgs{:});

specifiedOpts = setdiff(fieldnames(parser.Results), parser.UsingDefaults);

% Can't specify both FileType and OutputFcn
if all(ismember(["FileType", "WriteFcn"], specifiedOpts))
    throwAsCaller(MException(message("MATLAB:bigdata:write:WriteFcnAndType")));
end

writeFcn = parser.Results.WriteFcn;

if ~isempty(writeFcn)
    % User defined file type.
    fileType = "custom";
    writeFcn = @(varargin) iWrapWriteFcn(writeFcn, varargin{:});
else
    % Try to determine the file type from the supplied pattern.
    try
        fileType = iDetermineFileType(filePattern, parser.Results.FileType);
        iErrorIfSeqWithoutHadoop(fileType);
        iValidateDatatypeForFileType(fileType, class(prototype));
    catch err
        throwAsCaller(err)
    end
end

% Remove OutputFcn or FileType, then rebuild the argument list
specifiedOpts = setdiff(specifiedOpts, ["FileType", "WriteFcn"]);
args = cell(1, numel(specifiedOpts)*2);
for ii=1:numel(specifiedOpts)
    args{2*ii-1} = specifiedOpts{ii};
    args{2*ii} = parser.Results.(specifiedOpts{ii});
end

try
    iCheckOptsForType(fileType, specifiedOpts, args, prototype);
    writeFunction = matlab.bigdata.internal.io.createWriteFunction(...
        fileType, location, filePattern, isIri, isHdfs, args, writeFcn);
catch err
    throwAsCaller(err);
end

end


function fileType = iDetermineFileType(filePattern, fileType)
% Helper to check that the specified file type is supported and return it
% in standard form
err = "MATLAB:bigdata:write:BadFileType";
if ~matlab.internal.datatypes.isScalarText(fileType) || strlength(fileType)==0
    error(message(err));
end
allowedStrings = ["auto", "sequence", "mat", "text", "spreadsheet", "parquet"];
match = strncmpi(fileType, allowedStrings, strlength(fileType));
if nnz(match)~=1
    % No match or ambiguous match
    error(message(err));
end
fileType = allowedStrings(match);

% Also try to deduce the file type from the filePattern in case the two
% disagree
[patternFileType, ext] = iGetFileTypeFromPattern(filePattern);

% If the type is "auto" (default), then try to determine the type from the
% file pattern.
if isequal(fileType, "auto")
    if strlength(patternFileType)>0
        fileType = patternFileType;
    else
        % If no type was specified either using FileType or FilePattern, make
        % sure we didn't get an unrecognized extension.
        if strlength(ext)>0
            error(message("MATLAB:bigdata:write:UnrecognizedFileExtension", ext));
        end
    end
elseif strlength(ext)>0 && ~isequal(fileType, patternFileType)
    % Both file pattern and file type specified. Make sure they agree!
    error(message("MATLAB:bigdata:write:FileTypeConflict", ...
        fileType, ext));
end
end


function iValidateDatatypeForFileType(fileType, inputType)
% Validate that the input data type is supported by the requested fileType

if ~ismember(fileType, ["text", "spreadsheet", "parquet"])
    % All types are supported by the selected fileType
    return;
end

if strcmp(fileType, "parquet")
    % parquet supports either table or timetable
    if ~ismember(inputType, ["table", "timetable"])
        error(message("MATLAB:bigdata:write:NotTableOrTimetable", fileType));
    end
else
    % "text" and "spreadsheet" only support table
    if ~strcmp(inputType, "table")
        % Throw a specific error for timetables
        if strcmp(inputType, "timetable")
            error(message("MATLAB:bigdata:write:TimetableNotTable", fileType));
        else
            error(message("MATLAB:bigdata:write:NotTable", fileType));
        end
    end
end
end


function [fileType, ext] = iGetFileTypeFromPattern(filePattern)
% Helper to deduce the output type from the filePattern, if any. If no
% pattern is provided or the extension is not recognized then the result
% will be "".
fileType = "";
ext = "";
if strlength(filePattern)==0
    return
end

[~,~,ext] = fileparts(filePattern);
switch lower(string(ext))
    case {".mat"}
        fileType = "mat";
    case {".seq"}
        fileType = "sequence";
    case {".csv", ".txt", ".dat"}
        fileType = "text";
    case {".xls", ".xlsx", ".xlsb", ".xlsm", ".xltx", ".xltm"}
        fileType = "spreadsheet";
    case {".parq", ".parquet"}
        fileType = "parquet";
    otherwise
        % Leave blank
end

end


function iCheckOptsForType(fileType, specifiedOpts, args, prototype)
% Helper to validate the allowed P-V pairs for different output formats
switch fileType
    case {"custom","auto", "mat", "sequence"}
        allowedOpts = string.empty(1,0);
    case "parquet"
        allowedOpts = [
            "VariableCompression"
            "VariableEncoding"
            "Version"
            ];
    case "text"
        allowedOpts = [
            "Delimiter"
            "WriteVariableNames"
            "QuoteStrings"
            "DateLocale"
            "Encoding"
            ];
    case "spreadsheet"
        allowedOpts = [
            "WriteVariableNames"
            "DateLocale"
            "Sheet"
            ];
end
if ~isempty(setdiff(specifiedOpts, allowedOpts))
    badOpts = setdiff(specifiedOpts, allowedOpts);
    if strcmp(fileType, "custom")
        error(message("MATLAB:bigdata:write:WriteFcnParameter", badOpts(1)));
    else
        error(message("MATLAB:bigdata:write:BadParameterForType", badOpts(1), fileType));
    end
end

if any(fileType == ["text" "spreadsheet"])
    % Validate writetable args by attempting to write the prototype
    % Create a temporary filename with the appropriate file extension
    tempFile = tempname;
    
    if fileType == "text"
        tempFile = tempFile + ".txt";
    else
        tempFile = tempFile + ".xlsx";
        
        % Ensure that excel is not used for argument validation
        args = [{"UseExcel", false} args];
    end
    
    % Call writetable with user-supplied arguments.  This will allow any
    % writetable input parsing errors to be reported as tall/write errors.
    c = onCleanup(@() iSafeDeleteFile(tempFile));
    writetable(prototype, tempFile, "FileType", fileType, args{:});
elseif fileType == "parquet"    
    % make sure prototype is tabular and has at least one variable.
    matlab.io.parquet.internal.validateTabularShape(prototype);
    % matlab2arrow errors if prototype contains an unsupported datatype.
    arrowStruct = matlab.io.arrow.matlab2arrow(prototype);
    schema = matlab.io.internal.arrow.schema.TableSchema.buildTableSchema(arrowStruct);
    matlab.io.parquet.internal.parseParquetWriterOptions(schema, args{:});
end
end


function iSafeDeleteFile(f)
% Only attempt to delete the supplied file if it exists.
if isfile(f)
    delete(f);
end
end


function tf = iIsValidWriteFcn(fcn)
tf = isa(fcn, "function_handle");
if ~tf
    % Might be convertible to a function
    try
        fcn = str2func(fcn);
        tf = isa(fcn, "function_handle");
    catch
        tf = false;
    end
end
end


function iWrapWriteFcn(fcn, varargin)
% Wrap user-supplied write function so that any errors can be reported back
% to the client.
try
    feval(fcn, varargin{:});
catch e
    matlab.bigdata.internal.throw(e, "IncludeCalleeStack", true);
end
end

function iErrorIfSeqWithoutHadoop(fileType)
if fileType == "sequence"
    % Check that a hadoop installation is available
    try
        matlab.io.internal.vfs.hadoop.discoverHadoopInstallFolder();
    catch
        error(message('MATLAB:bigdata:write:HadoopRequiredSeq'));
    end
end
end
