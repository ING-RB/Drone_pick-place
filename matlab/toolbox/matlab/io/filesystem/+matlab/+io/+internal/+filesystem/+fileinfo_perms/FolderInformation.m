classdef FolderInformation < matlab.io.internal.filesystem.fileinfo_perms.FileSystemEntryInformation
%

%   Copyright 2024 The MathWorks, Inc.

    methods
        function obj = FolderInformation(location, options)
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

        function listing = contents(obj)
            D = dir(obj.AbsolutePath + filesep + "**/*");
            D1 = {D(:).name};
            D2 = {D(:).folder};
            D = strcat(D2, filesep, D1);
            for ii = 3 : numel(D)
                try
                    listing(ii-2) = matlab.io.internal.filesystem.fileinfo_perms.fileinfo(D(ii));
                catch ME
                    disp(ME.message)
                end
            end
        end
    end
end
