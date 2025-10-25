% Parse a numeric column

% Copyright 2015-2023 The MathWorks, Inc.

function vals = parseNumericColumn(r, currentData, currentFormat)
    arguments
        r
        currentData
        currentFormat = internal.matlab.datatoolsservices.FormatDataUtils.getCurrentNumericFormat();
    end
    % When format is compact, e* might just have one newline, check
    % for a single newline to parse cellwise.
    if ~contains(r, "*" + newline)
        textformat = ['%s', '%*[\n]'];
        emptyDecimal = '\.0+\n';
        % remove the trailing .0000 from each number
        rWithoutDecimals = regexprep(r, emptyDecimal, '\n');

        if strcmp(currentFormat, '+')
            % g2028503: Do not omit the whitespace for format +
            % since that would get rid of any 0s.
            vals = textscan(rWithoutDecimals,textformat,'Delimiter','','Whitespace','');
        else
            vals = textscan(rWithoutDecimals,textformat,'Delimiter','');
        end
    else
        % We need to parse row by row, switch to using evalc over formattedDisplayText as there is a huge perf difference between the two APIs.
        colVal = cell(size(currentData,1),1);
        for row=1:size(currentData,1)
            colVal{row} = strtrim(evalc('disp(currentData(row))'));
        end
        vals = {colVal};
    end
end
