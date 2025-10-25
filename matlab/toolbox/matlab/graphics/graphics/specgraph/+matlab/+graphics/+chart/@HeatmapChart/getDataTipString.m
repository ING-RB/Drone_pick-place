function str = getDataTipString(hObj, point, labelColor, valueColor)
% Get a data tip string for a heatmap cell.

% Copyright 2017-2024 The MathWorks, Inc.

arguments
    hObj
    point
    labelColor 
    valueColor 
end

% Get the XData, YData, and ColorDisplayData
xval = hObj.XDisplay_I;
yval = hObj.YDisplay_I;
[cd, errID,counts,rInds] = hObj.getColorDisplayData(...
    hObj.ColorData, hObj.XData_I, hObj.YData_I, ...
    xval(:,1), yval(:,1), hObj.MissingDataValue, ...
    hObj.CalculatedCounts, hObj.CalculatedRowIndices);
interpreter = hObj.Interpreter_I;

% Throw an error if the XData or YData size did not match
% ColorData.
if ~isempty(errID)
    error(message(errID));
end

% Make sure the data point is valid.
x = point(1);
y = point(2);
sz = size(cd);
if y < 1 || y > sz(1) || x < 1 || x > sz(2)
    str = '';
    return
end

% Make sure we have valid colors. These will be empty in the case of a
% figure without a theme.
if isempty(labelColor) 
    labelColor = [0.25 0.25 0.25];
end
if isempty(valueColor)
    valueColor = [0 0.6 1];
end

% Get the x-label, y-label, and cell label.
ind = sub2ind(sz, y, x);
valstr = sprintf(hObj.CellLabelFormat,cd(ind));
xval = xval(x,:);
yval = yval(y,:);

% Generate the string for the x-value. The first value is the
% XDisplayData value, the second is the XDisplayLabel value.
% XDisplayData cannot be empty or missing, but XDisplayLabel may be empty
% or missing.
if xval(2) == "" || ismissing(xval(2))
    xval(2) = xval(1);
end

% Use the x label for the x prefix, unless it is empty. In the
% table case this will default to the table variable name.
xLabel = truncateLabel(hObj.XLabel);
if xLabel == ""
    xLabel = 'X';
end
xstr = makeDataTipString(xLabel, char(xval(2)), labelColor, valueColor, interpreter);

% Generate the string for the y-value. The first value is the
% YDisplayData value, the second is the YDisplayLabel value.
% YDisplayData cannot be empty or missing, but YDisplayLabel may be empty
% or missing.
if yval(2) == "" || ismissing(yval(2))
    yval(2) = yval(1);
end

% Use the y label for the y prefix, unless it is empty. In the
% table case this will default to the table variable name.
yLabel = truncateLabel(hObj.YLabel);
if yLabel == ""
    yLabel = 'Y';
end
ystr = makeDataTipString(yLabel, char(yval(2)), labelColor, valueColor, interpreter);

% Get the message catalog prefix.
msgPrefix = 'MATLAB:Chart:Datatip';

% Use the color method for the value prefix, unless it is
% 'none', in which case just use 'Value'.
colorMethod = hObj.ColorMethod;
colorMethod(1) = upper(colorMethod(1));
msgID = [msgPrefix colorMethod];
valstr = makeDataTipString(getString(message(msgID)), valstr, labelColor, valueColor, interpreter);

if hObj.UsingTableForData
    % Generate the data tip string based on DataTipConfiguration_I
    dtConfig = hObj.getDataTipConfiguration();
    str = cell(size(dtConfig,1),1);
    for i = 1:size(dtConfig,1)
        dtVar = char(dtConfig(i,1));
        dtMethod = char(dtConfig(i,2));
        aggregatedData = hObj.CalculatedDataTipData{i};
        dtLabel = getTranslatedDataTipLabel(dtVar,dtMethod);

        if strcmp(hObj.SourceTable.Properties.DimensionNames{1},dtVar)
            rowIndex = rInds(ind);
            if strcmp(dtMethod,'count')
                dtVal = sprintf('%u',counts(ind));
                str{i,1} = makeDataTipString(dtLabel, dtVal, labelColor, valueColor, interpreter);
            elseif rowIndex > 0
                str{i,1} = makeDataTipString(dtLabel, mat2str(rowIndex), labelColor, valueColor, interpreter);
            end
        elseif strcmp(dtVar,hObj.XVariableName)
            str{i,1} = xstr;
        elseif strcmp(dtVar,hObj.YVariableName)
            str{i,1} = ystr;
        else
            % The columns/rows of the matrix may have been rearranged,
            % and getColorDisplayData corrects for that mapping.
            if ~isempty(aggregatedData)
                aggVal = hObj.getColorDisplayData(...
                    aggregatedData, hObj.XData_I, hObj.YData_I, ...
                    xval(:,1), yval(:,1), hObj.getMissingDataValue(dtMethod));

                str{i,1} = makeDataTipString(dtLabel, sprintf(hObj.CellLabelFormat,aggVal), labelColor, valueColor, interpreter);
            else
                % Get the row number to fetch the table columns data
                rowInd = rInds(ind);
                % rowInd should not be NaN normally, but adding a check
                % protects us against NaN values which may error out in
                % below line number 111
                if rowInd > 0
                    valueToDisplay = matlab.graphics.datatip.internal.formatDataTipValue...
                        (hObj.SourceTable.(dtVar)(rowInd,:),'auto');
                    str{i,1} = makeDataTipString(dtLabel,valueToDisplay, labelColor, valueColor, interpreter);
                end
            end
        end
    end
else
    % Collect all the strings together.
    str = {xstr; ystr; valstr};
end
end

function str = makeDataTipString(label, value, labelColor, valueColor, interpreter)

switch interpreter
    case 'none'
        str = [label ' ' value];
    case 'tex'
        texLabelColor = mat2str(labelColor);
        texValueColor = mat2str(valueColor);
        str = sprintf('{\\color[rgb]{%s}\\rm%s} {\\color[rgb]{%s}\\bf%s}',...
            texLabelColor(2:end-1), label, texValueColor(2:end-1), value);
    case 'latex'
        str = ['\textnormal{' label '} \textbf{' value '}'];
end

end

function lbl = truncateLabel(lbl)

% Convert into a string array.
lbl = string(lbl);

% Find the first non-empty string.
ind = find(lbl ~= "", 1);

if isempty(ind)
    lbl = '';
else
    % Merge the string into a single line.
    lbl = strjoin(lbl(ind:end));
    
    % Truncate the string at 25 characters.
    n = min(25, strlength(lbl))+1;
    lbl = char(extractBefore(lbl, n));
end
end

function translatedLabel = getTranslatedDataTipLabel(dtVar,dtMethod)
% Get the datatip label from message catalog. It matters how different
% languages translate Maximum Weight vs Weight Maximum
msgPrefix = 'MATLAB:graphics:datatip:';
dtMethod(1) = upper(dtMethod(1));
msgID = [msgPrefix dtMethod 'Variable'];
translatedLabel = getString(message(msgID,dtVar));
end
