function resolved = removeDotsFromFilePath(filePath)
    resolved = regexprep(filePath, '(?<=^|[\\/])\.[\\/]', '');
    
    dotDotRegexp = '(?<=^|[\\/])(?!\.\.[\\/])[^\\/]+[\\/]\.\.[\\/]';
    while ~isempty(regexp(resolved, dotDotRegexp, 'once'))
        resolved = regexprep(resolved, dotDotRegexp, '');
    end
end

%   Copyright 2011-2020 The MathWorks, Inc.
