function filename = getCurrentFilename(~, info)
%GETCURRENTFILENAME Get the current file name
%   Get the name of the file read by the datastore

%   Copyright 2022 The MathWorks, Inc.

if iscell(info)
    if isfield(info{1}, "Filename")
        filename = string(info{1}.Filename);
    else
        filename = "";
    end
elseif isfield(info, "Filename")
    filename = string(info.Filename);
else
    filename = "";
end
end