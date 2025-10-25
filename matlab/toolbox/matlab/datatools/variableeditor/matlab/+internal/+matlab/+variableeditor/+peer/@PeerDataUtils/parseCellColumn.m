% Parse the cell column

% Copyright 2017-2023 The MathWorks, Inc.

function vals = parseCellColumn(strColumnData)
    textformat = ['%s', '%*[\n]'];
    vals = strtrim(textscan(strColumnData,textformat,'Delimiter',''));
    vals = strtrim(regexprep(vals{:}, '(^(({[)|[|{))|(((]})|]|})$)',''));
    vals = {vals(:)};
end
