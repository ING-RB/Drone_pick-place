function varNames = determineVarNames(vnline, format, delimiter, whiteSpace, eol, allowSkips, otherArgs)
% DETERMINEVARNAMES Decide the variable names from the given line.

%   Copyright 2012-2022 The MathWorks, Inc.

% Search for any of the allowable conversions: a '%', followed
% optionally by '*', followed optionally by 'nnn' or by 'nnn.nnn',
% followed by one of the type specifiers or a character list or a
% negative character list.  Keep the '%' and the '*' if it's there,
% but replace everything else with the 'q' type specifier.
vnformat = varnameFormats(format, allowSkips);

% Append a delimiter in case the last varname is missing, so we get a cell
% containing an empty string, not an empty cell.
if ischar(delimiter)
    vnline = [vnline, delimiter];
else
    % delimiter is a cell containing a single string or multiple strings.
    % Append the first delimiter to the varname line. Appending any one of
    % the delimiter strings leads to correct varnames detection.
    vnline =  [vnline, sprintf(delimiter{1})];
end

% Add an extra field on the end of the format to collect anything extra as one
% string. Callers can error because of "too many" names, or parse it themselves.
vnformat = [vnformat '%[^' eol ']'];

% vnline does not contain an EOL, but specify it so that textscan will
% not assume the wrong thing.
varNames = textscan(vnline,vnformat,1,'delimiter',delimiter, ...
                               'whitespace',whiteSpace,'EndOfLine',eol,otherArgs{:});
% If there are not enough fields in the var names line, trailing cells contain
% an empty cell. Remove those. This is different than if there is the right
% number of fields but some are empty. In that case, the cell contains the empty
% string, which will be left alone to be fixed up later on in setvarnames. One
% way that not enough var name fields can happen is when delimiters are
% (incorrectly) specified in the format string rather than using the 'Delimiter'
% input, because they're read as part of the first %q field.
varNames = varNames(~cellfun(@isempty,varNames));
% Each cell in varnames contains another 1x1 cell containing a string; get those
% out. TEXTSCAN ignores leading whitespace, remove trailing whitespace here.
% Embedded whitespace is not removed, and further down the road makeValidName
% will not know to respect custom whitespace. While not quite right, in practice
% that's usually OK.
varNames = cellstr([varNames{:}]);
whiteSpace = ['[', regexptranslate('escape', sprintf(whiteSpace)), ']*'];
varNames = regexprep(varNames,[whiteSpace '$'], '');
end


function vnformat = varnameFormats(format, allowSkips)
%VARNAMEFORMATS Get formats for reading variable names
%   This function is responsible for returning formats for reading variable
%   names. The allowSkips argument controls whether the returned format can
%   contains skips or not.

fi = matlab.iofun.internal.formatParser(format);

% TabularTextDatastore does not respect skips, readtable does
if ~allowSkips
    vnformat = repmat('%q ', 1, nnz(~fi.IsLiteral));
    return
end

fi.Format(~fi.IsSkipped) = {'%q'};
fi.Format(~fi.IsLiteral & fi.IsSkipped) = {'%*q'};
vnformat = strjoin(fi.Format, ' '); %Concatenate the Formats into one character vector.
end