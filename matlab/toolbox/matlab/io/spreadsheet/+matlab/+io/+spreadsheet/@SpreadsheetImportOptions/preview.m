function data = preview(filename,opts)

if nargin < 2
    error(message("MATLAB:textio:preview:NotEnoughArguments"));
end

if ~isa(opts,"matlab.io.ImportOptions")
    error(message("MATLAB:textio:io:OptsSecondArg","preview"))
end

% We request extra rows in case some rows are empty or the MissingRule or
% ImportErrorRule are set to 'omitrow'. In these cases we might get less
% than the preview size so read some extra rows to fill them in if
% necessary.
rowsToRequest = 20;

if iscell(opts.DataRange)
    % Convert cell array notation to numeric notation, e.g. {'1:3';'5:6'}
    % to [1 3; 5 6];
    opts.DataRange = str2double(split(string(opts.DataRange),':'));
end


if ~matlab.io.internal.common.validators.isGoogleSheet(filename)
    tempFileHandler = matlab.io.internal.filesystem.tempfile.tempFileFactory(filename);
    filename = char(tempFileHandler.createLocalCopy());
end

filename = convertStringsToChars(filename);
if isnumeric(opts.DataRange)
    opts.DataRange = getDataRange(opts.DataRange,rowsToRequest);
    [opts, sheet] = opts.getSheet(filename);
elseif ischar(opts.DataRange)
    % We need to create a workbook to understand what our ranges mean in
    % the context of the provided sheet
    [opts, sheet] = opts.getSheet(filename);
    [numRange, type] = sheet.getRange(opts.DataRange, false);
    switch type
        case "single-cell"
            % convert to two-corner form based on range if only one
            % variable is asked for, otherwise do nothing
            if opts.fast_var_opts.numVars() == 1
                rowNum = regexp(opts.DataRange,'[0-9]');
                colVal = opts.DataRange(1:rowNum-1);
                numRows = str2double(opts.DataRange(rowNum:end)) + rowsToRequest - 1;
                opts.DataRange = [opts.DataRange,':',colVal,num2str(numRows)];
            end
        case "column-only"
            addRows = num2str(rowsToRequest);
            idx = regexp(opts.DataRange,':');
            firstRange = [opts.DataRange(1:idx-1),'1'];
            secondRange = [opts.DataRange(idx+1:end),addRows];
            opts.DataRange = [firstRange, ':', secondRange];
        case "two-corner"
            numrows = min(rowsToRequest,numRange(3));
            addRows = numRange(1) + numrows - 1;
            idx = regexp(opts.DataRange,'[A-Z]');
            idx = idx(end);
            firstPart = opts.DataRange(1:idx);
            secondPart = num2str(addRows);
            opts.DataRange = [firstPart,secondPart];
        case "row-only"
            numrows = min(rowsToRequest,numRange(3));
            opts.DataRange = [numRange(1) numRange(1) + numrows - 1];
    end
end

try
    data = readPreview(opts, sheet, rowsToRequest);
catch ME
    throwAsCaller(ME);
end

if isempty(data)
    error(message("MATLAB:textio:preview:NoDataAvailable"));
end

rowsToRequest = min(matlab.io.ImportOptions.PreviewSize, size(data, 1));
data = data(1:rowsToRequest, :);
end

function newDataRange = getDataRange(dataRange, previewSize)
% Computes the interval of lines to read based based on the dataRange and
% previewSize, which is the maximum number of rows to read.
linesToRead = previewSize;
i = 1;
newDataRange = zeros(0,2);
while linesToRead > 0 && i <= size(dataRange,1)
    startrow = dataRange(i,1);
    if ~isscalar(dataRange)
        endrow = dataRange(i,2);
    else
        endrow = Inf;
    end
    numrows = endrow - startrow + 1;
    if numrows >= linesToRead
        % read until we've hit linesToRead
        newDataRange(i,1) = startrow;
        newDataRange(i,2) = startrow + linesToRead - 1;
        linesToRead = 0;
    else
        % read whatever is available
        newDataRange(i,1) = startrow;
        newDataRange(i,2) = endrow;
        linesToRead = linesToRead - numrows;
    end
    i = i + 1;
end
end

%   Copyright 2018-2024 The MathWorks, Inc.
