function parsedResults = setupParsePaths(parsedResults)
% Set parse environment using absolute paths

%   Copyright 2024 The MathWorks, Inc.

% Set the absolute paths
parsedResults.HeaderFiles = cellstr(convertStringsToChars(parsedResults.HeaderFiles));
% Check the extension of the header file or files.
if(iscellstr(parsedResults.HeaderFiles))
    for index = 1:length(parsedResults.HeaderFiles) %#ok<*FXUP>
        try
            parsedResults.HeaderFiles{index} = clibgen.internal.getHeaderFileWithValidExtension(parsedResults.HeaderFiles{index});
        catch ME
            throwAsCaller(ME)
        end
        % Convert header to absolute path before writing to Data File
        [~,values] = fileattrib(parsedResults.HeaderFiles{index});
        parsedResults.HeaderFiles{index} =  values.Name;
    end
end

% Normalize the include paths (Removed any trailing slash)
% Ensure there is no trailing slash so that cl and link command
% works
if iscellstr(parsedResults.IncludePath)
    for index = 1: length(parsedResults.IncludePath)
        [status, value]= fileattrib(char(parsedResults.IncludePath{index}));
        if status
            parsedResults.IncludePath{index} = value.Name;
        end
    end
else 
    if ~isempty(parsedResults.IncludePath)
        [status, value]= fileattrib(char(parsedResults.IncludePath));
        if status
            parsedResults.IncludePath = value.Name;
        end
    end
end

end
