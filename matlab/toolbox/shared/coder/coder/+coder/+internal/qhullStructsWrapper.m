classdef (Sealed) qhullStructsWrapper < handle
% Holds pointer to qhull structs defined in qhTWrapper.h
% Used to free memory when the scatteredInterpolant object goes out of
% scope

%   Copyright 2024 The MathWorks, Inc.

%#codegen
    properties
        delTri      % Delaunay Triangulation.
        convHull    % Vertices forming convex hull of the delaunay triangulation.
        convHullTri % Triangulation of the vertices on the convex hull.
    end

    methods
        function obj = qhullStructsWrapper
        % Initialize pointers, coder.internal.delaunayTriangulation
        % class will use these to store the created qhT structs.
            obj.delTri = coder.opaquePtr('void', coder.internal.null);
            obj.convHull = coder.opaquePtr('void', coder.internal.null);
            obj.convHullTri = coder.opaquePtr('void', coder.internal.null);
            coder.internal.scatteredInterpAPI.createQhullWrapperStructs(obj);
        end

        function delete(obj)
            coder.internal.scatteredInterpAPI.deleteQhullStructs(obj);
        end
    end

end
