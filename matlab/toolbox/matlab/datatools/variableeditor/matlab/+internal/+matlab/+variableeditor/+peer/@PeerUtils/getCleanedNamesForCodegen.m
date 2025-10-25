% Returns cleaned names for code generation

% Copyright 2014-2023 The MathWorks, Inc.

function cleanFiltNames = getCleanedNamesForCodegen(names, quotes, cClass)
    % Using a regex to escape any single quotes or double quotes contained in
    % the names
    names = regexprep(cellstr(names),quotes,[quotes quotes]);
    if ~strcmp(cClass, 'logical')
        % Using a regex to escape any newline charecters contained in the names.
        if strcmp(cClass, 'string')
            % if it is a strings, using string concatenation code
            names = regexprep(cellstr(names), newline, ...
                [quotes '+newline+' quotes]);
            names = regexprep(cellstr(names), char(9), ...
                [quotes '+char(9)+' quotes]);
        else
            % If it is a Cellstr or categorical, use the appropriate
            % concatenation code for newline charecters.

            % Using a non-printing charecter as a placeholder for the whilespace
            % so that cats and cellstrs which have the keyword newline as part
            % of their strings do not get the square braces.
            names = regexprep(cellstr(names), newline, ...
                [quotes char(31) 'newline' char(31) quotes]);
            names = regexprep(cellstr(names), char(9), ...
                [quotes char(31) 'char(9)' char(31) quotes]);
        end
        temp = cell(1, length(names));
        for i = 1:length(names)
            if contains(names{i}, [char(31) 'newline' char(31)]) || ...
                    contains(names{i}, [char(31) 'char(9)' char(31)])

                % Replacing the non-printing charecter [char(31)] with the
                % charecter for whitespace [char(32)] to generate the optimal
                % code
                names{i} = regexprep(names{i}, char(31), char(32));
                % cellstr or cats need to wrap the value in square brackets for
                % correct code generation
                temp{i} = [char(91), quotes, names{i}, quotes, char(93)];
            else
                % If is it string, the newline command will automatically get
                % concatenated in the correct manner if needed
                temp{i} = [quotes, names{i}, quotes];
            end
        end
    else
        temp = names;
    end
    cleanFiltNames = temp;
end
