function out = getBaseVariableName(name)
    % Returns the base variable name.  For example:
    %
    %   'st.f' returns 'st'
    %   "c{1,2}" returns "c"
    %   'arr(1,5){2}' returns 'arr'
    %
    % This is a copy of the long standing function in arrayviewfunc. Repeating
    % here since arrayviewfunc will be deprecated.  The only difference is that
    % this function will return the text type based on the input type (string
    % will return string, char will return char)

    % Copyright 2020-2023 The MathWorks, Inc.

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
        % get rid of beginning and end chars
        nameModified = false;
        while any(strfind(name, '[') == 1) || any(strfind(name, '{') == 1)
            name = strtrim(name(2:end));
            nameModified = true;
        end

        while any(strfind(name, ']') == length(name)) || ...
                any(strfind(name, '}') == length(name)) || ...
                any(strfind(name, '''') == length(name))
            name = strtrim(name(1:length(name)-1));
            nameModified = true;
        end

        % Find any indexing characters
        special = getIndicesOfIndexingChars(name);
        if ~isempty(special)
            out = name(1:special(1)-1);
        elseif nameModified
            out = name;
        end
    end

    if stringOutput
        % Convert back to string if the argument was a string
        out = string(out);
    end
end

function out = getIndicesOfIndexingChars(in)
    out = [];
    if length(in) >= 2
        dots = strfind(in, '.');
        parens = strfind(in, '(');
        curleys = strfind(in, '{');
        out = sort([dots parens curleys]);
    end
end

