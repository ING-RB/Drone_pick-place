% Returns the JSON for a cell

% Copyright 2015-2023 The MathWorks, Inc.

function jsonData = getJSONforCell(~, data, longData, isMeta, editorValue, row, col)

    if isempty(data)
        data = '[]';
    end
    if isempty(longData)
        longData = '[]';
    end

    % case when value is not metadata eg: c{1} = 10
    if ~isMeta
        if isempty(editorValue)
            jsonData = ['{' '"value"' ':' '"' data '"' ',' '"editValue"' ':' '"' longData '"' ','...
                '"isMetaData"' ':' '"0"' ',' '"row"' ':' '"' row '"' ',' '"col"' ':' '"' col '"' '}'];
        else
            % in case of char arrays, Ex: c = {'abc';'def'}, on double clicking
            % the data should be opened in a new VE tab
            jsonData = ['{' '"value"' ':' '"' data '"' ',' '"editValue"' ':' '"' longData '"' ','...
                '"isMetaData"' ':' '"0"' ',' '"editor"' ':' '"variableeditor/views/editors/OpenvarEditor"'...
                ',' '"editorValue"' ':' '"' editorValue '"' ',' '"row"' ':' '"' row '"' ',' '"col"' ':' '"' col '"' '}'];
        end
        % case when value is metadata c{1} = 5x5 double
    else
        jsonData = ['{' '"value"' ':' '"' data '"' ',' '"editValue"' ':' '"' longData '"' ','... 
                '"isMetaData"' ':' '"1"' ',' '"editor"' ':' '"variableeditor/views/editors/OpenvarEditor"'... 
                ',' '"editorValue"' ':' '"' editorValue '"' ',' '"row"' ':' '"' row '"' ',' '"col"' ':' '"' col '"' '}'];
    end
end	 
