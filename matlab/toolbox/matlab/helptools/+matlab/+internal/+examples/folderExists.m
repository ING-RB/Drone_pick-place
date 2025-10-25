function tf = folderExists(f)
%

%   Copyright 2019-2020 The MathWorks, Inc.

    tf = numel(dir(f)) > 1;
end
