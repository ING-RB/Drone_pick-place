function value = sanitizeComponentPropertyValue(elementValue)
    %SANITIZECOMPONENTPROPERTYVALUE

%   Copyright 2024 The MathWorks, Inc.

%TODO: throw an error if a user is calling eval or feval
    value = strip(handleEmbeddedSingleQuotes(elementValue));

    if isempty(value)
        value = '''''';
    end
end

function output = handleEmbeddedSingleQuotes(input)
    output = input;
    if ischar(input) && length(input) > 2
        firstChar = input(1);
        lastChar = input(end);

        if strcmp(firstChar, '''') && strcmp(lastChar, '''')
            % strsplit is expensive, and in most cases, there's no need to
            % call it, so check number of single quote first.
            numOfSingleQuotes = count(input(2:end-1), '''');            
            if numOfSingleQuotes > 0
                parts = strsplit(input(2:end-1), '''');

                numOfSplitStr = numOfSingleQuotes + 1;

                processedParts = cell(1, numOfSplitStr*2-1);
                for i=1:numOfSplitStr
                    processedParts{i*2-1} = parts{i};
                    if i < numOfSplitStr
                        processedParts{i*2} = char;
                    end
                end
    
                output = strcat(firstChar, strjoin(processedParts, ''''), lastChar);
            end
        end
    end
end
