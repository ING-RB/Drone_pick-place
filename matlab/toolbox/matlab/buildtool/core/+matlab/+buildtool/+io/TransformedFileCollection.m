classdef TransformedFileCollection < matlab.buildtool.io.FileCollection
    % TransformedFileCollection - Collection of files transformed by a function
    %
    %   The build tool instantiates this class. You cannot create an object of
    %   the class directly.
    %
    %   See also matlab.buildtool.io.FileCollection.transform,
    %      matlab.buildtool.io.FileCollection

    %   Copyright 2023 The MathWorks, Inc.

    properties (SetAccess = immutable)
        UnderlyingFileCollection matlab.buildtool.io.FileCollection
        Transform function_handle
        AllowResizing (1,1) logical
    end

    methods (Access = ?matlab.buildtool.io.FileCollection)
        function collection = TransformedFileCollection(underlying, transform, options)
            arguments
                underlying (1,1) matlab.buildtool.io.FileCollection
                transform (1,1) function_handle
                options.AllowResizing (1,1) logical = false
            end
            collection.UnderlyingFileCollection = underlying;
            collection.Transform = transform;
            collection.AllowResizing = options.AllowResizing;
            collection.BuildingTask = underlying.BuildingTask;
        end
    end

    methods (Access = protected)
        function p = elementPaths(collection)
            arguments (Output)
                p (1,:) string
            end
            underlyingPaths = collection.UnderlyingFileCollection.paths;
            p = collection.Transform(underlyingPaths);
            if ~collection.AllowResizing && ~isequal(size(p), size(underlyingPaths))
                error(message("MATLAB:buildtool:TransformedFileCollection:TransformMustPreserveSize"));
            end
        end
    end
end