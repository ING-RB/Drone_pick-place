classdef SymbolicLinkInformation < matlab.io.internal.filesystem.fileinfo_perms.FileSystemEntryInformation
%

%   Copyright 2024 The MathWorks, Inc.

    properties (Dependent)
        Target (1, 1) string
    end

    methods
        function obj = SymbolicLinkInformation(location, options)
            arguments
                location (1, 1)
                options.LocationResolved logical = false
                options.ResolveSymbolicLink logical = false
            end

            if ~options.LocationResolved
                S = matlab.io.internal.filesystem.resolveLocation(location, ...
                    ResolveSymbolicLink=options.ResolveSymbolicLink, GetAttributes=true);
            else
                S.ResolvedPath = location;
            end
            obj.AbsolutePath = S.ResolvedPath;
        end

        function target = get.Target(obj)
            [~, target] = isSymbolicLink(obj.AbsolutePath);
        end
    end
end
