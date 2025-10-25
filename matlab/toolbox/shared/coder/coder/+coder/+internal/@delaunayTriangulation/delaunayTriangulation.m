classdef(Sealed) delaunayTriangulation
% This is NOT the coder implementation of delaunayTriangulation.
% Helper class for Coder implementation of scatteredInterpolant.

%   Copyright 2024 The MathWorks, Inc.

%#codegen

    properties
        numPts
        spatialDim
        numVxsPerSimplex
        thePoints
        qhWrapper
        triValidity
        numVerticesOnHull
        idxMap
        dupesExist
        mergeDuplicatePoints
    end

    methods
        %% Constructor
        function obj = delaunayTriangulation(npts, ndim, narr, varargin)
            coder.internal.prefer_const(npts, ndim, narr);

            % To disable handling of duplicate points, set this constant
            % to false.
            obj.mergeDuplicatePoints = true;

            obj.spatialDim = coder.internal.indexInt(ndim);
            obj.numVxsPerSimplex = obj.spatialDim + 1;
            if narr == 1
                %% Matrix input, scatteredInterpolant(P,v);
                if obj.mergeDuplicatePoints
                    [uqPts, obj.idxMap, obj.dupesExist] = coder.internal.delaunayTriangulation.mergeDuplicates(varargin{1});
                    obj.thePoints = uqPts';
                else
                    obj.idxMap = [];
                    obj.dupesExist = false;
                    obj.thePoints = (varargin{1})';
                end
            elseif narr == 2
                %% 2D column vector inputs, scatteredInterpolant(x,y,v)
                if obj.mergeDuplicatePoints
                    [uqPts, obj.idxMap, obj.dupesExist] = coder.internal.delaunayTriangulation.mergeDuplicates([varargin{1} varargin{2}]);
                    obj.thePoints = uqPts';
                else
                    obj.idxMap = [];
                    obj.dupesExist = false;
                    obj.thePoints = ([varargin{1} varargin{2}])';
                end
            elseif narr == 3
                %% 3D column vector inputs
                coder.internal.assert(false, 'Coder:polyfun:scatteredInterp2DOnly')
            end
            obj.numPts = coder.internal.indexInt(size(obj.thePoints, 2));

            % Default, initialized if extrapolation method is, linear or boundary.
            obj.numVerticesOnHull = coder.internal.indexInt(0);
            %% Store pointers to Qhull strcuts of delaunay triangulation and convex hull.
            obj.qhWrapper = coder.internal.qhullStructsWrapper();
            obj = coder.internal.scatteredInterpAPI.buildDelaunayTri(obj);
            obj.triValidity = true;
        end

        %% Search methods
        function sid = tsearch(obj, xi)
            arguments
                obj
                xi (1,2) double
            end
            sid = coder.internal.scatteredInterpAPI.tsearch(obj.qhWrapper, xi(:)');
        end

        function [isInHull, vid] = dsearch(obj, xi)
            arguments
                obj
                xi (1,2) double
            end
            [isInHull, vid] = coder.internal.scatteredInterpAPI.dsearch(obj.qhWrapper, xi(:)');
        end

        %% Cache Methods
        function obj = extractConvexHullOfDelaunayTriangulation(obj)
            coder.inline('always')
            if obj.triValidity
                [obj, nVtx] = ...
                    coder.internal.scatteredInterpAPI.extractConvexHullOfDelaunayTriangulation(obj);
                obj.numVerticesOnHull = nVtx;
            end
        end

        function obj = cacheTriangulationOfConvexHull(obj)
            coder.inline('always')
            if obj.triValidity
                obj = coder.internal.scatteredInterpAPI.cacheTriangulationOfConvexHull(obj);
            end
        end

        %% Set Methods
        function obj = setPoints(obj, pts)
            obj = obj.invalidateTriangulation();
            if obj.mergeDuplicatePoints
                [uqPts, ~, inputHasDups] = coder.internal.delaunayTriangulation.mergeDuplicates(pts);
                obj.thePoints = uqPts';
                if inputHasDups
                    coder.internal.warning('MATLAB:mathcgeo_catalog:DupPtsWarnId', 'scatteredInterpolant');
                end
            else
                obj.thePoints = pts';
            end
            obj.numPts = coder.internal.indexInt(size(obj.thePoints, 2));
            % Delete the existing triangulation and create a new one.
            % Codegen doesn't support explicit delete calls on handle
            % objects. Invoke the API that frees allocated memory and redo
            % the triangulation.
            coder.internal.scatteredInterpAPI.deleteQhullStructs(obj.qhWrapper);
            coder.internal.scatteredInterpAPI.createQhullWrapperStructs(obj.qhWrapper);
            obj = coder.internal.scatteredInterpAPI.buildDelaunayTri(obj);
            obj.triValidity = true;
        end

        %% Update Methods
        function obj = invalidateTriangulation(obj)
            coder.inline('always');
            obj.triValidity = false;
        end

        %% Get Methods
        function vtxPt = getVertexAtID(obj, id)
            vtxPt = obj.thePoints(:, id)';
        end

        function vxID =  getVtxIDsOfSimplex(obj, sxId)
            vxID = coder.internal.scatteredInterpAPI.getVtxIDsOfSimplex( ...
                obj.qhWrapper, obj.numVxsPerSimplex, sxId);
        end

        function triVtx = getVerticesOfSimplex(obj, sid)
            vid = obj.getVtxIDsOfSimplex(sid);
            triVtx = coder.nullcopy([obj.numVxsPerSimplex, obj.spatialDim], 'double');
            for i = 1:coder.internal.indexInt(vid)
                triVtx(i, :) = obj.getVertexAtID(id);
            end
        end

        function sdim = numSpatialDim(obj)
            coder.inline('always')
            sdim = obj.spatialDim;
        end

        function isvalid = isTriangulationValid(obj)
            coder.inline('always')
            isvalid = obj.triValidity;
        end

    end

    methods(Static, Access=private, Hidden=true)
        %% Make dimensions nontunable
        function props = matlabCodegenNontunableProperties(~)
            props = {'numVxsPerSimplex', 'spatialDim', 'mergeDuplicatePoints'};
        end

        function [uniquePts, idxMap, dupesExist] = mergeDuplicates(inputPts)
            % Merge duplicate points in input set.
            
            % Preserve ordering of input points.
            [uniquePts, ~, idxMap] = unique(inputPts, 'rows', 'stable');

            numIn = length(inputPts);
            numUnique = length(uniquePts);
            if (numUnique < numIn)
                dupesExist = true;
            else
                dupesExist = false;
            end
        end
    end

end
