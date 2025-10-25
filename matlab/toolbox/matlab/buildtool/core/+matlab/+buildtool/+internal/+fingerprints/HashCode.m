classdef HashCode
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2022-2024 The MathWorks, Inc.

    properties (SetAccess = immutable)
        Bytes (1,:) uint8
    end

    methods
        function hash = HashCode(bytes)
            arguments
                bytes (1,:) uint8 = uint8([])
            end
            hash.Bytes = bytes;
        end

        function tf = eq(a, b)
            if ~isa(a, "matlab.buildtool.internal.fingerprints.HashCode") || ~isa(b, "matlab.buildtool.internal.fingerprints.HashCode")
                error(message("MATLAB:buildtool:HashCode:InvalidComparison", class(a), class(b)));
            end
            if isscalar(a)
                a = repmat(a, size(b));
            elseif isscalar(b)
                b = repmat(b, size(a));
            end
            if ~isequal(size(a), size(b))
                error(message("MATLAB:buildtool:HashCode:ComparisonSizeMismatch"));
            end
            tf = arrayfun(@isequal, a, b);
            tf = logical(tf);
        end

        function tf = ne(a, b)
            try
                tf = ~eq(a, b);
            catch x
                throw(x);
            end
        end
    end
end
