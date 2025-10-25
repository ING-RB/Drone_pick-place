classdef FilteredFileCollection < matlab.buildtool.io.FileCollection
    % FilteredFileCollection - Collection of files whose paths satisfy a condition
    %
    %   The build tool instantiates this class. You cannot create an object of
    %   the class directly.
    %
    %   See also matlab.buildtool.io.FileCollection.select,
    %      matlab.buildtool.io.FileCollection

    %   Copyright 2023 The MathWorks, Inc.

    properties (SetAccess = immutable)
        UnderlyingFileCollection matlab.buildtool.io.FileCollection
        Filter function_handle
    end

    methods (Access = ?matlab.buildtool.io.FileCollection)
        function collection = FilteredFileCollection(underlying, filter)
            arguments
                underlying (1,1) matlab.buildtool.io.FileCollection
                filter (1,1) function_handle
            end
            collection.UnderlyingFileCollection = underlying;
            collection.Filter = filter;
            collection.BuildingTask = underlying.BuildingTask;
        end
    end

    methods (Access = protected)
        function p = elementPaths(collection)
            arguments (Output)
                p (1,:) string
            end
            underlyingPaths = collection.UnderlyingFileCollection.paths;
            inds = collection.Filter(underlyingPaths);
            p = underlyingPaths(inds);
        end
    end
end
