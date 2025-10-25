function choices = dbclearIdentifier(condIn)

    dbs = dbstatus;
    isCondIn = arrayfun(@(x) strcmp(x.cond, condIn), dbs);
    if(~isempty(dbs) && any(isCondIn))
            choices = dbs(isCondIn).identifier;
    else
        choices = [];
    end

end

% Copyright 2021 The MathWorks, Inc.
    