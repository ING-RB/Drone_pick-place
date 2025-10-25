function checkEmptyEntries(entries, fcnName)
% Errors if the entries struct is empty.

% Copyright 2020 The MathWorks, Inc.
if isempty(entries)
    eid=sprintf('MATLAB:%s:noEntries', fcnName);
    error(eid,'%s',getString(message('MATLAB:io:archive:getArchiveEntries:noEntries',fcnName)))
end
end