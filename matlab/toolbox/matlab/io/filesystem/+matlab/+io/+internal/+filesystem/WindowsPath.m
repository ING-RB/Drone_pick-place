classdef WindowsPath < matlab.io.internal.filesystem.Path
%WINODWSPATH Path object with access to name, parent, extension - treats path
%            as existing on Unix

%   Copyright 2023 The MathWorks, Inc.

    methods
        function obj = WindowsPath(pathStr)
            repeatedTypes = repmat("windows", size(pathStr, 1) * size(pathStr, 2), 1);
            obj = obj@matlab.io.internal.filesystem.Path(pathStr, Type = repeatedTypes);
        end
    end
end
