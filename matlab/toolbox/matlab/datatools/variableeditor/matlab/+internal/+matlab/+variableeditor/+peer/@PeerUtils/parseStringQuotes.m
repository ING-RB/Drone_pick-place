% If the data is string, just replace the first and last "" with '' for
% validation. Any "" within the string is legitimate and should not be replaced,
% but escaped

% Copyright 2014-2023 The MathWorks, Inc.

function data = parseStringQuotes(data, classType, classShowsQuotes)
    % Evaluate String to check if it begins and ends with "" for replacement,
    % else append the string with ""
    if (strcmp(classType, 'string') && ~isempty(data))
        data = regexprep(data, '(^''|''$)', '');
        data = regexprep(data, '(^"|"$)', '');
        if (contains(data, '"') && ~contains(data, '""')) || ~classShowsQuotes
            data = strrep(data, '"', '""');
        end
        data = ['"' data '"'];
    end
end
