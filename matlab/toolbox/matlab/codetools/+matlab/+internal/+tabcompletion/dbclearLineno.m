function choices = dbclearLineno(filespec)
    filespec = string(filespec);

    [files, dbs] = matlab.internal.tabcompletion.dbclearHelper(filespec);

    localMarker = filespec + filemarker;
    localFunctions = extractAfter(files(startsWith(files, localMarker)), localMarker);

    hasFilemarker = contains(files, filemarker);
    files(hasFilemarker) = extractBefore(files(hasFilemarker), filemarker);
    
    lines = {dbs.line};
    lines = lines(files == filespec);
    choices = [localFunctions, compose('%d', [lines{:}])];
end

% Copyright 2018 The MathWorks, Inc.
