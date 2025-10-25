function parsedProperties = parseModifiedProperties (generatedCode)
    % with the given generated code, parse out what properties have
    % been written as non-default. First line is skipped since it
    % is construction

    % Copyright 2022-2023 MathWorks, Inc.

    function property = parseDirtyProperty(codeLine)
        property = '';

        line = strtrim(codeLine);

        if startsWith(line, 'app') || startsWith(line, 'comp')
            objName = extractBefore(line, '.');
            prop = extractBetween(line, append(objName, '.ad_CODENAME_ad.'), ' = ');
            if ~isempty(prop)
                property = prop{1};
            end
        else
            property = extractBefore(line, '(');
        end

        if contains(property, " ")
            % Strip any leading spaces then split string on space (assumes
            % there is always a space between property name and "=" in generated code).
            % See g3058786 for LaTeX case where above regex does not parse correctly.
            property = strsplit(strip(property));
            property = property{1};
        end
    end

    if iscell(generatedCode)
        count = length(generatedCode);
        parsedProperties = cell(1, count - 1);

        if count > 1
            for i = 2:count
                property = parseDirtyProperty(generatedCode{i});
                if ~isempty(property)
                    parsedProperties{i - 1} = strtrim(property);
                end
            end
        end
    else
        parsedProperties = {};
    end
end