function params = reportParamsList(detected,delimiter,headerlines,readVarNames,format)
    % Add a list of the detected parameters into a single character vector

%   Copyright 2016-2020 The MathWorks, Inc.

    params = {};
    if detected.Delimiter
        % Delimiter is detected only as a scalar, or as {' ','\t'} so no need to
        % wrap them in a cell for this output
        if ischar(delimiter)
            params{end+1} = sprintf('''Delimiter'', ''%s''',delimiter);
        else
            params{end+1} = sprintf('''Delimiter'', ''%s''',[delimiter{:}]);
        end
        if numel(delimiter) > 1
            params{end+1} = sprintf('''MultipleDelimsAsOne'', true');
        end
    end

    if detected.HeaderLines
        params{end+1} = sprintf('''HeaderLines'', %d',headerlines);
    end

    if detected.ReadVariableNames
        if readVarNames, rvn = 'true'; else, rvn = 'false'; end
        params{end+1} = sprintf('''ReadVariableNames'', %s',rvn);
    end

    if detected.Format
        params{end+1} = sprintf('''Format'', ''%s''',format);
    end

    if ~isempty(params)
        params = strrep(matlab.io.internal.utility.unescape(strjoin(params,', ')),'\','\\');
    end
end

