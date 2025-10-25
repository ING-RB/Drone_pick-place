classdef File < matlab.buildtool.io.FileCollection
    % File - File system location
    %
    %   The matlab.buildtool.io.File class represents a file system location. A
    %   file represented by File might not exist on disk.
    %
    %   The build tool instantiates this class. You cannot create an object of
    %   the class directly.
    %
    %   See also matlab.buildtool.Plan.files,
    %      matlab.buildtool.io.FileCollection

    %   Copyright 2022-2024 The MathWorks, Inc.

    properties (SetAccess = immutable)
        % Path - Path of file
        %
        %   Path of file, returned as a string scalar.
        Path (1,1) string
    end

    methods (Hidden)
        function file = File(path, options)
            arguments
                path string {mustBeNonzeroLengthText}
                options.BuildingTask (1,1) string = ""
            end

            import matlab.buildtool.io.File;

            if isscalar(path)
                file.Path = path;
                file.BuildingTask = options.BuildingTask;
                return;
            end

            % Construct object array
            file = arrayfun(@(p)File(p,BuildingTask=options.BuildingTask), path);
            file = [file File.empty()];
        end
    end

    methods (Access = protected)
        function p = elementPaths(file)
            p = file.Path;
        end

        function f = selectElement(file, filter)
            arguments (Input)
                file (1,1) matlab.buildtool.io.File
                filter (1,1) function_handle
            end
            arguments (Output)
                f matlab.buildtool.io.File
            end
            f = file(filter(file.Path));
        end

        function f = transformElement(file, transform, options)
            arguments
                file (1,1) matlab.buildtool.io.File
                transform (1,1) function_handle
                options.AllowResizing (1,1) logical = false
            end

            import matlab.buildtool.io.File;

            if options.AllowResizing
                f = transformElement@matlab.buildtool.io.FileCollection(file, transform, AllowResizing=true);
            else
                p = transform(file.Path);
                if ~isscalar(p)
                    error(message("MATLAB:buildtool:TransformedFileCollection:TransformMustPreserveSize"));
                end

                f = File(p);
                f.BuildingTask = file.BuildingTask;
            end
        end

        function rep = elementTextRepresentation(collection)
            rep = collection.Path;
        end
    end
end
