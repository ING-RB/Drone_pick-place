function close(uuid)
%CLOSE remove a code analyzer report backend

%   Copyright 2021 The MathWorks, Inc.

    obj = matlab.codeanalyzerreport.internal.Server.Map(uuid);
    delete(obj);
    remove(matlab.codeanalyzerreport.internal.Server.Map, uuid);
end
