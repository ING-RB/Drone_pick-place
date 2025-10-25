classdef polygon
% Underlying implementation used in polyshape

%   Copyright 2023-2024 The MathWorks, Inc.

%#codegen

    properties
        boundaries;         % Object of boundary2D class
        numBoundaries;      % scalar storing num of boundaries in polygon
        polyArea;           % area of polygon, scalar
        polyPerimeter;      % perimeter of polygon, scalar
        polyCentroid;       % centroid of polygon, scalar
        polyBbox;           % bounding box of polygon, struct
        polyNumPoints;      % total number of points in polygon, scalar
        nestingResolved;    % scalar logical storing if boundary types have been updated
        polyClean;          % scalar logical storing if geometric quantities have been updated
        fillingRule;        % Not exposed to polyshape, used in clipper, set to default
        accessOrder;        % Used to map to the correct index in the underlying boundary implementation
    end

    methods

        function rule = getFillingRule(pg)
            rule = pg.fillingRule;
        end

        function pg = setFillingRule(pg, rule)
            pg.fillingRule = rule;
        end

        function [s, e] = getBoundaryPtr(pg)
            [s, e] = getBoundaryPtr(pg.boundaries);
        end

        function [x, y] = getVtxArray(pg)
            [x, y] = getVtxArray(pg.boundaries);
        end

        function a = getBoundaryAreas(pg)
            a = getBoundaryAreas(pg.boundaries);
        end

        function numBoundaries = getNumBoundaries(pg)
            numBoundaries = pg.numBoundaries;
        end

        function numPoints = getNumPoints(pg)
            numPoints = pg.polyNumPoints - pg.numBoundaries;
        end

        function numVertices = getNumPointsInBoundary(pg, it)
            it = pg.accessOrder.getMappedIndex(it);
            nc = pg.getNumBoundaries();
            if (nc == 0)
                numVertices = 0;
            else
                numVertices = pg.boundaries.getBoundarySize(it)-1;
            end
        end

        function pg = updateDerived(pg)
            if(~pg.polyClean)
                pg = pg.polyUpdateArea();
            end
        end

        function pg = clearDerived(pg)
            pg.polyClean = false;
        end

        function c = getCentroid(pg)
            assert(pg.polyClean);
            bbox_area = abs((pg.polyBbox.hiX-pg.polyBbox.loX)*(pg.polyBbox.hiY-pg.polyBbox.loY));
            bbox_ratio = abs(pg.polyArea/bbox_area);
            epsVal = eps('double');
            num_regions = pg.numBoundaries;
            if (bbox_ratio<1.0e-6 && bbox_ratio>epsVal  && num_regions>2)
                coder.internal.warning('MATLAB:polyshape:centroidMayBeOff');
            end
            c = [pg.polyCentroid.X, pg.polyCentroid.Y];
        end

        function c = getBoundaryCentroid(pg, it)
            it = pg.accessOrder.getMappedIndex(it);
            c = pg.boundaries.getCentroid(it);
        end

        function p = getPerimeter(pg)
            assert(pg.polyClean);
            p = pg.polyPerimeter;
        end

        function p = getBoundaryPerimeter(pg, it)
            it = pg.accessOrder.getMappedIndex(it);
            p = pg.boundaries.getPerimeter(it);
        end

        function a = getArea(pg)
            assert(pg.polyClean);
            a = pg.polyArea;
        end

        function a = getBoundaryArea(pg, it)
            it = pg.accessOrder.getMappedIndex(it);
            a = pg.boundaries.getArea(it);
            if( pg.boundaries.isHoleIdx(it) )
                a = -1*abs(a);
            else
                a = abs(a);
            end
        end

        function pgBbox = getBbox(pg)
            assert(pg.polyClean);
            pgBbox = pg.polyBbox;
        end

        function Boundbbox = getBoundaryBbox(pg, it)
            assert(pg.polyClean);
            it = pg.accessOrder.getMappedIndex(it);
            Boundbbox = pg.boundaries.getBbox(it);
        end

        function ih = getBoundaryIsHole(pg, it)
            assert(pg.polyClean);
            it = pg.accessOrder.getMappedIndex(it);
            ih = pg.boundaries.isHoleIdx(it);
        end

        function ih = getIsHole(pg)
            assert(pg.polyClean);
            ih = zeros(pg.numBoundaries, 1,'logical');
            for it = 1:pg.numBoundaries
                ih(it) = pg.boundaries.isHoleIdx(it);
            end
        end

        function bType = getbType(pg)
            bType = pg.boundaries.getbType();
        end

        function pg = polygon(varargin)
            pg.boundaries = coder.internal.polyshapeHelper.boundary2D();
            pg.polyNumPoints = 0;
            pg.polyClean = false;
            pg.nestingResolved = true;
            pg.numBoundaries = 0;
            pg.polyArea = 0;
            pg.polyPerimeter = 0;
            pg.polyBbox = struct('loX',realmax,'loY',realmax,'hiX',-1*realmax,'hiY',-1*realmax);
            pg.polyCentroid = struct('X',0.,'Y',0.);
            pg.fillingRule = uint8(0);
            pg.accessOrder = coder.internal.polyshapeHelper.accessWrapper();
            if nargin == 0
                % Empty polyshapes are clean by default, the user facing
                % methods will error if fetching any of its properties is
                % not allowed.
                pg = pg.updateDerived();
            else
                pg = pg.addBoundary(varargin{1},varargin{2},varargin{3}, ...
                                    varargin{4});
            end
        end

        function pg = copy(obj)
            pg = coder.internal.polyshapeHelper.polygon();
            pl = properties(obj);
            for k = 1:length(pl)
                if isprop(pg, pl{k})
                    if isa(pg.(pl{k}), 'coder.internal.polyshapeHelper.boundary2D')
                        pg.(pl{k}) = copy(obj.(pl{k}));
                    else
                        pg.(pl{k}) = obj.(pl{k});
                    end
                end
            end
        end

        function obj = clearAll(obj)
            obj.boundaries = obj.boundaries.clearAll();
            obj.polyNumPoints = 0;
            obj.polyClean = false;
            obj.nestingResolved = true;
            obj.numBoundaries = 0;
            obj.polyArea = 0;
            obj.polyPerimeter = 0;
            obj.polyBbox = struct('loX',realmax,'loY',realmax,'hiX',-1*realmax,'hiY',-1*realmax);
            obj.polyCentroid = struct('X',0.,'Y',0.);
            obj.fillingRule = uint8(0);
            obj.accessOrder = obj.accessOrder.clear();
        end

        function pg = appendBoundaries(pg, xPtArr, yPtArr, stPtr, enPtr, btype)
            stPtr = stPtr + pg.polyNumPoints;
            enPtr = enPtr + pg.polyNumPoints;
            pg.polyNumPoints = pg.polyNumPoints + numel(xPtArr);
            pg.numBoundaries = pg.numBoundaries + numel(stPtr);
            pg.boundaries = pg.boundaries.pushBoundaries(xPtArr, yPtArr, stPtr, enPtr, btype);
            pg.nestingResolved = pg.nestingResolved & (btype ~= coder.internal.polyshapeHelper.boundaryTypeEnum.UserAuto);
        end

        pg = addBoundary(pg, X, Y, btype, fillingRule)
        pg = addPoints(pg, Xarray, Yarray, nPts, btype)
        pg = removeBoundary(pg, bdIdx)
        pg = resolveNesting(pg)
        [X, Y] = getBoundary(pg, Idx)
        pg = polyUpdateArea(pg)
        nh = getNumHoles(pg)
        vertices = getPoints(pg)
        pg = polyScale(pg, ds, center)
        pg = polyRotate(pg, theta, center)
        pg = polyShift(pg, shift_x, shift_y)
        b = isEqual(pg, otherpg)
        [globalIdx, bdryIdx, localIdx] = nearestVertex(pg, V)
        ret_array = polyCompare(pgObj, pgOther)
        pg = polyRemoveHoles(pg)
        pg = polySortBoundaries(pg, direction, criterion, refPoint)

    end

end
