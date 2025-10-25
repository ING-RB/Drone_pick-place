classdef boundary2D
% Class defining the boundaries of the polyshape

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    properties
        vertices;    % Object of point class
        stPtr;       % array containing the starting index of each boundary
        enPtr;       % array containing the ending index of each boundary
        area;        % array with the area of each boundary
        perimeter;   % array with the perimeter of each boundary
        centroid;    % array with the centroid of each boundary
        dist2;
        bbox;        % structure array with bounding box for each boundary
        bType;       % boundary type of each boundary. enum of boundaryTypeEnum
        clean;       % array of logicals which store the state of the boundary
    end

    methods

        function [s, e] = getBoundaryPtr(bdObj)
            s = coder.internal.indexInt(bdObj.stPtr);
            e = coder.internal.indexInt(bdObj.enPtr);
        end

        function [x, y] = getVtxArray(bdObj)
            [x, y] = getVtxArray(bdObj.vertices);
        end

        function a = getBoundaryAreas(bdObj)
            a = bdObj.area;
        end

        function p = getBoundaryPerimeters(bdObj)
            p = bdObj.perimeter;
        end

        function c = getBoundaryCentroids(bdObj)
            c = bdObj.centroid;
        end

        function x = getBoundaryCentroidDists(bdObj, refPoint, nb)
            c = bdObj.getBoundaryCentroids();
            x = coder.nullcopy(zeros(1,nb));
            for i = 1:nb
                dx = c.X(i) - refPoint(1);
                dy = c.Y(i) - refPoint(2);
                % nan check is expensive, done here so only sort invokes it
                if (isnan(dx) || isnan(dy))
                    x(i) = realmax;
                else
                    x(i) = dx * dx + dy * dy;
                end
            end
        end

        function [s, e] = getBoundary(bdObj, bdIdx)
            s = bdObj.stPtr(bdIdx);
            e = bdObj.enPtr(bdIdx);
        end

        function boundSize = getBoundarySize(bdObj, bdIdx)
            [s,e] = bdObj.getBoundary(bdIdx);
            boundSize = e-s+1;
        end

        function x = getBoundarySizes(bdObj, nb)
            x = coder.nullcopy(zeros(1,nb));
            for i = 1:nb
                x(i) = getBoundarySize(bdObj, i);
            end
        end

        function [x, y] = getCoordAtIdx(bdObj, bdIdx, vtxIdx)
            s = bdObj.stPtr(bdIdx);
            s = s + vtxIdx - 1;

            x = bdObj.vertices.X(s);
            y = bdObj.vertices.Y(s);
        end

        function a = getArea(bdObj, bdIdx)
            assert(bdObj.clean(bdIdx)); % This should always be true for a fully constructed polyshape.
                                        % Catch errors in construction via assert.
            a = bdObj.area(bdIdx);
        end

        function p = getPerimeter(bdObj, bdIdx)
            assert(bdObj.clean(bdIdx));
            p = bdObj.perimeter(bdIdx);
        end

        function boundBbox = getBbox(bdObj, bdIdx)
            assert(bdObj.clean(bdIdx));
            boundBbox = struct('loX', bdObj.bbox.loX(bdIdx), ...
                               'loY', bdObj.bbox.loY(bdIdx), 'hiX', bdObj.bbox.hiX(bdIdx), ...
                               'hiY', bdObj.bbox.hiY(bdIdx) );
        end

        function c = getCentroid(bdObj, bdIdx)
            assert(bdObj.clean(bdIdx));
            c = [bdObj.centroid.X(bdIdx),bdObj.centroid.Y(bdIdx)];
        end

        function bType = getbType(bdObj)
            bType = bdObj.bType;
        end

        function bdObj = updateDerived(bdObj, bdIdx)
            if(~bdObj.clean(bdIdx))
                bdObj = bdObj.updateArea(bdIdx);
                coder.internal.assert(bdObj.clean(bdIdx),'MATLAB:polyshape:xyTooLarge');
            end
        end

        function bdObj = removeBndProps(bdObj, idx)
            bdObj.stPtr(idx) = [];
            bdObj.enPtr(idx) = [];
            bdObj.perimeter(idx) = [];
            bdObj.area(idx) = [];
            bdObj.bType(idx) = [];
            bdObj.centroid.X(idx) = [];
            bdObj.centroid.Y(idx) = [];
            bdObj.clean(idx) = [];
            bdObj.bbox.loX(idx) = [];
            bdObj.bbox.loY(idx) = [];
            bdObj.bbox.hiX(idx) = [];
            bdObj.bbox.hiY(idx) = [];
        end

        function bdObj = clearAll(bdObj)
            bdObj.vertices = bdObj.vertices.clearAll();
            bdObj.stPtr = zeros(1,0);
            bdObj.enPtr = zeros(1,0);
            bdObj.bType = repmat(uint8(coder.internal.polyshapeHelper.boundaryTypeEnum.UserAuto),1,0);
            bdObj.clean = zeros(1,0,'logical');

            bdObj.centroid = struct('X',zeros(1,0),'Y', zeros(1,0));

            bdObj.bbox = struct('loX',zeros(1,0), 'loY',zeros(1,0), 'hiX',zeros(1,0), 'hiY',zeros(1,0));

            bdObj.perimeter = zeros(1,0);
            bdObj.area = zeros(1,0);
            bdObj.dist2 = zeros(1,0);
        end

        function bdObj = boundary2D()
            bdObj.vertices = coder.internal.polyshapeHelper.point();

            bdObj.stPtr = coder.internal.polyshapeHelper.boundary2D.createVarSize(zeros(1,0));
            bdObj.enPtr = coder.internal.polyshapeHelper.boundary2D.createVarSize(zeros(1,0));
            bdObj.bType = coder.internal.polyshapeHelper.boundary2D.createVarSize( ...
                repmat(uint8(coder.internal.polyshapeHelper.boundaryTypeEnum.UserAuto),1,0));
            bdObj.clean = coder.internal.polyshapeHelper.boundary2D.createVarSize(zeros(1,0,'logical'));

            bdObj.centroid = struct('X',coder.internal.polyshapeHelper.boundary2D.createVarSize( ...
                zeros(1,0)),'Y', ...
                                    coder.internal.polyshapeHelper.boundary2D.createVarSize(zeros(1,0)));

            bdObj.bbox = struct( ...
                'loX',coder.internal.polyshapeHelper.boundary2D.createVarSize(zeros(1,0)), ...
                'loY',coder.internal.polyshapeHelper.boundary2D.createVarSize(zeros(1,0)), ...
                'hiX',coder.internal.polyshapeHelper.boundary2D.createVarSize(zeros(1,0)), ...
                'hiY',coder.internal.polyshapeHelper.boundary2D.createVarSize(zeros(1,0)));

            bdObj.perimeter = coder.internal.polyshapeHelper.boundary2D.createVarSize(zeros(1,0));
            bdObj.area = coder.internal.polyshapeHelper.boundary2D.createVarSize(zeros(1,0));
            bdObj.dist2 = coder.internal.polyshapeHelper.boundary2D.createVarSize(zeros(1,0));
        end

        function bdObj = pushBoundaries(bdObj, xPtArr, yPtArr, stPtr, enPtr, btype)

            bdObj.vertices = bdObj.vertices.pushVtxArr(xPtArr, yPtArr);
            bdObj.stPtr = horzcat(bdObj.stPtr, stPtr);
            bdObj.enPtr = horzcat(bdObj.enPtr, enPtr);
            bdObj.bType = horzcat(bdObj.bType, repmat(uint8(btype),1,numel(stPtr)));
            bdObj.clean = horzcat(bdObj.clean, zeros(1,numel(stPtr),'logical'));
            bdObj.area = horzcat(bdObj.area, zeros(1,numel(stPtr),'double'));
            bdObj.perimeter = horzcat(bdObj.perimeter, zeros(1,numel(stPtr),'double'));
            bdObj.centroid.X = horzcat(bdObj.centroid.X, zeros(1,numel(stPtr),'double'));
            bdObj.centroid.Y = horzcat(bdObj.centroid.Y, zeros(1,numel(stPtr),'double'));
            bdObj.bbox.loX = horzcat(bdObj.bbox.loX, repmat(realmax,1,numel(stPtr)));
            bdObj.bbox.loY = horzcat(bdObj.bbox.loY, repmat(realmax,1,numel(stPtr)));
            bdObj.bbox.hiX = horzcat(bdObj.bbox.hiX, repmat(-1*realmax,1,numel(stPtr)));
            bdObj.bbox.hiY = horzcat(bdObj.bbox.hiY, repmat(-1*realmax,1,numel(stPtr)));
        end

        function bd = copy(obj)
            bd = coder.internal.polyshapeHelper.boundary2D();
            pl = properties(obj);
            for k = 1:length(pl)
                if isprop(bd, pl{k})
                    if isa(bd.(pl{k}), 'coder.internal.polyshapeHelper.point')
                        bd.(pl{k}) = copy(obj.(pl{k}));
                    else
                        bd.(pl{k}) = obj.(pl{k});
                    end
                end
            end
        end

        function bdObj = reverseBndAtIdx(bdObj, bdIdx)
            [s, e] = getBoundary(bdObj, bdIdx);
            bdObj.vertices = reverseVtxsOfBnd(bdObj.vertices, ...
                                              coder.internal.indexInt(s), coder.internal.indexInt(e));
        end

        bdObj = updateArea(bdObj, this_bd)
        b = isHoleIdx(bdObj, bdIdx)
        b = isInside(bdObj, bdIdx, qX, qY)
        bdObj = bndScale(bdObj, sx, sy, ox, oy, this_bd)
        bdObj = bndRotate(bdObj, theta, ox, oy, this_bd)
        bdObj = bndShift(bdObj, x, y, this_bd)
        [bdObj, resolveNest, ptsErased] = eraseBoundary(bdObj, idx)
        b = isEqual(bdObj, otherBoundary)
    end

    methods(Static)

        [s_metric, s_angle, s_v1, s_v2, s_size, ...
         s_ht0_error, s_slope_error] = bndCompare(c1, c2, update_p)

        function varOut = createVarSize(varIn)
            varOut = varIn;
            coder.varsize('varOut',[1 inf]);
        end

    end
end
