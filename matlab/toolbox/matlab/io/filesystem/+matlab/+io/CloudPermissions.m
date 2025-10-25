classdef CloudPermissions < matlab.io.FileSystemEntryPermissions
%

%   Copyright 2024 The MathWorks, Inc.

    methods
        function obj = CloudPermissions(location)
            arguments (Input)
                location (1, 1) string
            end
            if ~matlab.io.internal.vfs.validators.isIRI(location)
                error(message("MATLAB:io:filesystem:filePermissions:InvalidURLToCloudPermissions", location));
            end
            obj.AbsolutePath = location;
        end
    end
end
