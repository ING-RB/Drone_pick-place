% Formats the string to display as shown on the client

% Copyright 2014-2023 The MathWorks, Inc.

function formattedData = formatStringClientView(data)
    formattedData = regexprep(data,'\n', '\x21b5');
    formattedData = regexprep(formattedData,'\t', '\x2192');
end
