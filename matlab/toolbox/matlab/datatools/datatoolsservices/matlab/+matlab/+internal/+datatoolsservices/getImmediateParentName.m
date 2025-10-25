function out = getImmediateParentName(name)
    % Returns the parent name immediately to the current name.  For example:
    %
    %   'st.f.foo' returns 'st.f'
    %   "c{1,2}" returns "c"
    %   'arr(1,5){2}' returns 'arr', () are stripped
    %   c(1,1) returns 'c', () is stripped
    %   (assume delimiter of #) 'st#f#foo returns 'st#f' (see comment further
    %                                                     down about g3128711)
    
    % this function will return the text type based on the input type (string
    % will return string, char will return char)
    
    % Copyright 2020-2024 The MathWorks, Inc.
    
    arguments
        name {mustBeTextScalar}
    end
    
    stringOutput = isstring(name);
    name = convertStringsToChars(name);
    out = '';
    done = false;
    
    if isempty(name)
        % Early return for empty
        done = true;
    end
    
    if isvarname(name)
        % Early return for valid variable name (so it must be the base name)
        out = name;
        done = true;
    end
    
    if ~done
        % g3128711: Tree scalar struct Documents use a custom delimiter that is not ".".
        % We must handle this case, as it's possible to have a Document name like so
        % (assume the delimiter is "#"): "s#tableField#Column.Name"
        % In this example, we do _not_ want to consider "s#tableField#Column" as the parent.
        % It should be "s#tableField".
        if internal.matlab.variableeditor.VEUtils.idHasCustomDelimiter(name)
            delimiter = internal.matlab.variableeditor.VEUtils.DELIMITER;
        else
            delimiter = '.';
        end

        % Check for occurences of {} and the chosen delimiter in order to fetch the
        % correct parent name.
        delimiterOccurrences = strfind(name, delimiter);
        curleys = strfind(name, '{');
        maxIndex = max([delimiterOccurrences, curleys]);

        if ~isempty(maxIndex)
            out = name(1:maxIndex(1)-1);
            if endsWith(out, ')')
                out = out(1:max(strfind(out, '('))-1);
            end
        else
            % For usecases like c(1,1), we want to return c.
            % Check after { & the delimiter are processed. (g2648971)
            if contains(name, "(")
               out = extractBefore(name, "(");
            end
        end
    end

    if stringOutput
        % Convert back to string if the argument was a string
        out = string(out);
    end
end
