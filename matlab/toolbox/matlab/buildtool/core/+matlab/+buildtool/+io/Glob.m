classdef Glob < matlab.buildtool.io.FileCollection
    % Glob - Collection of files matched by pattern
    %
    %   The matlab.buildtool.io.Glob class represents a collection of files on
    %   disk matched by a pattern that contains wildcard characters. The
    %   pattern in a Glob is re-evaluated every time you call the paths method.
    %
    %   The build tool instantiates this class. You cannot create an object of
    %   the class directly.
    %
    %   See also matlab.buildtool.Plan.files,
    %      matlab.buildtool.io.FileCollection

    %   Copyright 2022-2024 The MathWorks, Inc.

    properties (SetAccess = immutable)
        % Pattern - Pattern of glob
        %
        %   Pattern of glob, returned as a string scalar.
        Pattern (1,1) string
    end

    methods (Hidden)
        function glob = Glob(pattern)
            arguments
                pattern string {mustBeNonzeroLengthText}
            end

            import matlab.buildtool.io.Glob;

            if isscalar(pattern)
                glob.Pattern = pattern;
                return;
            end

            % Construct object array
            glob = arrayfun(@Glob, pattern);
            glob = [glob Glob.empty()];
        end
    end

    methods (Access = protected)
        function p = elementPaths(glob)
            p = matlab.io.internal.glob(glob.Pattern);
            p = sort(p)';
        end

        function rep = elementTextRepresentation(collection)
            rep = collection.Pattern;
        end
    end
end
