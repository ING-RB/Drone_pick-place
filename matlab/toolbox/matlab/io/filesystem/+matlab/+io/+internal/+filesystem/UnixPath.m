classdef UnixPath < matlab.io.internal.filesystem.Path
%UNIXPATH Path object with access to name, parent, extension - treats path
%         as existing on Unix

%   Copyright 2023 The MathWorks, Inc.

    methods
        function obj = UnixPath(pathStr)
            repeatedTypes = repmat("unix", size(pathStr, 1) * size(pathStr, 2), 1);
            obj = obj@matlab.io.internal.filesystem.Path(pathStr, Type = repeatedTypes);
        end
    end
end
