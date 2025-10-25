function [files, dbs] = dbclearHelper(filespec)
    dbs = dbstatus;
    dbs(cellfun('isempty', {dbs.line})) = [];
    files = {dbs.file};
    files = cellfun(@(f)matlab.lang.internal.introspective.minimizePath(f, false), files, 'UniformOutput', false);
    noFilesep = ~contains(files, filesep);
    files(noFilesep) = {dbs(noFilesep).name};
    files = regexprep(files, '^@(\w+)[\\/]\1\.\w+$', '$1');
    files = regexprep(files, '^@(\w+)[\\/](\w+)\.\w+$', '$1/$2');
    if ispc && contains(filespec, '/')
        files = replace(files, '\', '/');
    end
end

% Copyright 2018-2023 The MathWorks, Inc.
