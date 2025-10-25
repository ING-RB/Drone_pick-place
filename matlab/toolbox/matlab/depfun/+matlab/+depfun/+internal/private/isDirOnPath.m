function onPath = isDirOnPath(pth)
%

%   Copyright 2013-2020 The MathWorks, Inc.

    p = [pwd strsplit(path,pathsep)];
    onPath = any(strcmp(pth,p)); 
end
