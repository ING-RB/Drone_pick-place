classdef WindowsPermissions < matlab.io.FileSystemEntryPermissions
%

%   Copyright 2024 The MathWorks, Inc.

    methods
        function obj = WindowsPermissions(location)
            arguments (Input)
                location (1, 1) string
            end
            obj.AbsolutePath = matlab.io.internal.filesystem.resolveRelativeLocation(location);
        end
    end
end
