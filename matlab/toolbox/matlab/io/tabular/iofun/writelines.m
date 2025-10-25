function writelines(lines, filename, options)

arguments
    % Required input.
    lines {mustBeText};
    filename {mustBeTextScalar, mustBeNonzeroLengthText};

    % Name-value pair inputs.
    options.LineEnding {mustBeTextScalar, mustBeNonzeroLengthText} = getDefaultLineEnding();
    options.Encoding {mustBeTextScalar} = "UTF-8";
    options.WriteMode {mustBeTextScalar} = "overwrite";
    options.TrailingLineEndingRule {mustBeTextScalar} = "auto" ;
end

import matlab.io.internal.utility.validateAndEscapeCellStrings
import matlab.io.text.internal.write.FprintfErrorHandler
import matlab.io.internal.utility.FileHandleGuard

writeMode = validateWriteMode(options.WriteMode);
lineEnding = string(validateAndEscapeCellStrings(options.LineEnding));
trailingLineEndRule = validateTrailingLineEndingRule(options.TrailingLineEndingRule);

% open the file for writing (or appending)

guard = FileHandleGuard(filename, writeMode, "n", options.Encoding);

if ~guard.openSucceeded()
    error(message("MATLAB:textio:writelines:InvalidFileIdentifier"));
end

lines = handleTrailingLines(lines,...
    guard.FileID,trailingLineEndRule,writeMode,...
    filename,lineEnding);
if ~isempty(lines)
    lines = join(lines(:),lineEnding);
end

fprintf(guard.FileID, "%s", lines);
[msg, errNum] = ferror(guard.FileID);

if ~isempty(msg) || errNum
    FprintfErrorHandler(guard.FileID, filename, errNum);
end
end

function lines = handleTrailingLines(lines,fid,trailingLineEndRule,writeMode,filename,lineEnding)
% handle the adding of new-lines
import matlab.io.text.internal.write.appendNewlineToEOFIfNeeded

lines = string(lines);
lines = lines(:);
lines(ismissing(lines)) = "";

% if append mode, add a newline to the end of the file so writes start
% from the next line
if writeMode == "a+" && ~(trailingLineEndRule == "never" && numel(lines) == 0)
    % If "WriteMode" == "append", ensure the text file ends
    % with a line ending character so that new rows are appended
    % beneath the existing file contents, rather than starting on the last
    % line.
    isEmpty = appendNewlineToEOFIfNeeded(filename, fid, ...
        "append", lineEnding);
else
    isEmpty = true;
end

if numel(lines) == 0
    % An empty file won't get a new line added
    % A non-empty file that doesn't end in a new line will have one added.
    if trailingLineEndRule == "always" ...
            || (trailingLineEndRule == "auto" && isEmpty)
        lines = lineEnding;
    end
else
    if trailingLineEndRule == "always" ...
            || (trailingLineEndRule == "auto" ...
            && needsTrailingLines(lines,lineEnding))
        lines(end+1) = "";
    end
end
end

function writeMode = validateWriteMode(writeMode)
writeMode = validatestring(writeMode, ["overwrite", "append"]);
if writeMode == "overwrite"
    writeMode = "W";
elseif writeMode == "append"
    writeMode = "a+";
end
end

function trailLineEndRule = validateTrailingLineEndingRule(trailLineEndRule)
trailLineEndRule = validatestring(trailLineEndRule,["auto", "always", "never"]);
end

function lineEnding = getDefaultLineEnding()
if ispc
    lineEnding = "\r\n";
else
    lineEnding = "\n";
end
end

function tf = needsTrailingLines(lines,lineEnding)
% check if there is a line ending at end of input, if not, add
% one. For LineEnding "\n", it gets converted to "" (special
% case)
n = strlength(lines(end));
tf = (n > 0  && ~endsWith(lines(end),lineEnding)) ...
    || (numel(lines) == 1  && n == 0);
end

% Copyright 2021-2024 The MathWorks, Inc.
