% Parse the char column

% Copyright 2017-2024 The MathWorks, Inc.

function [vals, metaData] = parseCharColumn(currentData)
    formatDataUtils = internal.matlab.datatoolsservices.FormatDataUtils();
    import internal.matlab.variableeditor.peer.PeerDataUtils;
    metaData = false(size(currentData,1),1);
    strData = string(currentData);
    overCharMax = (strlength(strData) > formatDataUtils.MAX_TEXT_DISPLAY_LENGTH);
    missingStrs = ismissing(strData) & isstring(currentData); %cellstr does what we want for char, categorical and cellstr
    if isstring(currentData)
        colVal = cellstr("""" + currentData + """");
    elseif iscellstr(currentData)
        colVal = cellstr('''' + strData + '''');
    else
        colVal = cellstr(currentData);
    end
    colVal = strrep(colVal, char(0), ' '); % Replace null characters
    mStr = strtrim(evalc('disp(string(missing))'));
    if any(overCharMax) || any(missingStrs)
        % For any char/categorical over the MAX string length we make it a
        % summary string
        classStr = class(currentData);
        if iscellstr(currentData) %#ok<ISCLSTR>
            classStr = 'char';
        end
        for row=1:size(currentData,1)
            if overCharMax(row)
                sizeStr = strjoin(split(num2str(size(currentData(row,:)))), ...
                    internal.matlab.datatoolsservices.FormatDataUtils.TIMES_SYMBOL);
                if iscellstr(currentData) %#ok<ISCLSTR>
                    sizeStr = strjoin(split(num2str(size(currentData{row,:}))), ...
                        internal.matlab.datatoolsservices.FormatDataUtils.TIMES_SYMBOL);
                end

                colVal{row} = [sizeStr ' ' classStr];
                metaData(row) = true;
            elseif missingStrs(row)
                colVal{row} = mStr;
                metaData(row) = true;
            end
        end
    end
    vals = {colVal};
end
