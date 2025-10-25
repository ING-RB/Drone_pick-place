function names = dbclearBuiltin
    dbs = dbstatus;
    dbs(~cellfun('isempty', {dbs.line})) = [];
    names = {dbs.name};
    names(names=="") = [];
    names = extractAfter(names, filemarker);
end

% Copyright 2018 The MathWorks, Inc.
