classdef (Sealed) PackageFolder < matlab.mixin.CustomCompactDisplayProvider

    properties
        Path (1,1) string
        Languages (1,:) matlab.mpm.PackageFolderLanguage = ...
            matlab.mpm.PackageFolderLanguage.matlab
    end

    methods
        function obj = PackageFolder(pathArray, opts)
            arguments
                pathArray (1,:) string {mustBeNonzeroLengthText}
                opts.Languages (1,:) matlab.mpm.PackageFolderLanguage ...
                    = matlab.mpm.PackageFolderLanguage.matlab
            end

            n = numel(pathArray);
            switch (n)
                case 0
                    obj = matlab.mpm.PackageFolder.empty(1, 0);
                case 1
                    obj.Path = pathArray;
                    obj.Languages = opts.Languages;
                otherwise
                    for k = 1:n
                        obj(k) = matlab.mpm.PackageFolder(pathArray(k), Languages=opts.Languages);
                    end
            end
        end

        function obj = set.Path(obj, newPath)
            arguments
                obj
                newPath (1,1) string {mustBeNonzeroLengthText}
            end
            obj.Path = newPath;
        end

        function obj = set.Languages(obj, newLanguages)
            arguments
                obj
                newLanguages (1,:) matlab.mpm.PackageFolderLanguage
            end

            if numel(newLanguages) > 1
                if numel(newLanguages) ~= numel(unique(newLanguages))
                    error(message('mpm:package:RepeatedArrayValue', 'Languages'));
                end
            end

            obj.Languages = newLanguages;
        end

        function displayRep = compactRepresentationForSingleLine(obj, displayConfiguration, width)
            paths = [obj.Path];
            displayRep = widthConstrainedDataRepresentation(obj, displayConfiguration, width, ...
                StringArray = paths, ...
                Annotation = matlab.mpm.internal.dimensionAndTypeAnnotation(obj, displayConfiguration), ...
                AllowTruncatedDisplayForScalar = true);
        end

    end
end

% Copyright 2024 The MathWorks, Inc.
