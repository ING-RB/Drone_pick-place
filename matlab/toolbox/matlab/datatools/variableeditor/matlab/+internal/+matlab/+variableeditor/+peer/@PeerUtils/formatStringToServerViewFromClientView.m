% Formats the client string to display as per server characters

% Copyright 2014-2023 The MathWorks, Inc.

function formattedData = formatStringToServerViewFromClientView(data)
    formattedData = regexprep(data,  '\x21b5', '\n');
    formattedData = regexprep(formattedData, '\x2192', '\t');
end
