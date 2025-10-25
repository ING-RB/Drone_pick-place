classdef FileInformation < matlab.io.internal.filesystem.fileinfo_perms.FileSystemEntryInformation
%

%   Copyright 2024 The MathWorks, Inc.

    properties (Dependent)
        FileType (1, 1) string
        Size (1, 1) double
        Description (1, 1) string
        RelatedFunctions (:, :) string
    end

    methods
        function obj = FileInformation(location, options)
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

            % P = matlab.io.internal.filesystem.Path(obj.AbsolutePath);
            % registry = imformats;
            % supportedFormats = {registry.ext};

            % if lower(P.FileType) == ".parquet"
            %     obj.Description = parquetinfo(obj.AbsolutePath);
            % elseif any(lower(P.FileType) == matlab.io.internal.xlsreadSupportedExtensions)
            %     obj.Description = sheetnames(obj.AbsolutePath);
            % elseif any(lower(extractAfter(P.FileType, ".")) == [supportedFormats{:}])
            %     % try imfinfo
            %     obj.Description = imfinfo(obj.AbsolutePath);
            % end
        end

        function type = get.FileType(obj)
            [~, ~, type] = fileparts(obj.AbsolutePath);
            type = type.split(".");
            type = type(end);
        end

        function seeAlso = get.RelatedFunctions(obj)
            seeAlso = "imread, imwrite, imfinfo, imformats";
        end

        function desc = get.Description(obj)
            desc = "JPG is a widely used image format for containing digital images";
        end

        function size = get.Size(obj)
            S = matlab.io.internal.filesystem.resolvePathWithAttributes(obj.AbsolutePath);
            size = S.Size;
        end

        function info = preview(obj)
            disp("Not yet implemented");
            info = [];
        end

        function result = openFcn(obj)
            disp("Not yet implemented");
            result = [];
        end
    end
end
