function files = dbclearFile(filespec)
    files = matlab.internal.tabcompletion.dbclearHelper(filespec);
    hasFilemarker = contains(files, filemarker);
    files = [files, extractBefore(files(hasFilemarker), filemarker)];
end

% Copyright 2018 The MathWorks, Inc.
