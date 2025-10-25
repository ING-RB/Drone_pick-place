classdef PolyCell
%This class is for internal use only. It may be removed in the future.

%PolyCell - Helper class for operating on PolyCell structs during exact cellular decomposition
%
%   The cell itself is represented by a list of ceiling vertex ids and
%   floor vertex ids. This class is mainly used for the construction of
%   cells, so the cached 'next' floor and ceiling ids are also stored to
%   allow for efficient calculations of intersection points, should the
%   cell be closed before either of the 'next' points are reached.
%   The ids of the left and right neighbor cells are also tracked.

%   Copyright 2024 The MathWorks, Inc.

%#codegen
    % properties
    %     %CeilVtxIdxs - The vertex ids of the ceiling vertices
    %     %   Important: This list contains VERTEX ids, NOT event ids
    %     CeilVtxIdxs (:,1) {mustBeScalarOrEmpty,mustBeInteger} = ones(0,1);
    %     %FloorVtxIdxs - The vertex ids of the floor vertices
    %     %   Important: This list contains VERTEX ids, NOT event ids
    %     FloorVtxIdxs (:,1) {mustBeScalarOrEmpty,mustBeInteger} = ones(0,1);
    %     %NextCeilEventIdx - The event id of the next ceiling event
    %     NextCeilEventIdx (1,1) = inf; % inf->Unassigned, nan->Edge is complete
    %     %NextFloorEventIdx - The event id of the next floor event
    %     NextFloorEventIdx (1,1) = inf; % inf->Unassigned, nan->Edge is complete
    %     %leftNeighbors - Cells ids of the bordering cells to the left
    %     LeftNeighbors (:,1) {mustBeInteger} = ones(0,1);
    %     %rightNeighbors - Cells ids of the bordering cells to the right
    %     RightNeighbors (:,1) {mustBeInteger} = ones(0,1);
    %     % id - The id of this cell
    %     id (1,1) double = -1;
    % end

    methods (Static)
        %% Mutating methods
        function obj = makeCell(ceilIdx, floorIdx, nextCeilIdx, nextFloorIdx)
        %PolyCell - Create a PolyCell object
            arguments
                ceilIdx         (:,1) {mustBeInteger} = ones(0,1);
                floorIdx        (:,1) {mustBeInteger} = ones(0,1);
                nextCeilIdx     (1,1) = inf;
                nextFloorIdx    (1,1) = inf;
            end
            idxList = ones(0,1);
            coder.varsize("idxList",[inf 1],[1 0]);

            % See commented class properties for field descriptions
            obj = struct( ...
                'CeilVtxIdxs',idxList, ...
                'FloorVtxIdxs', idxList, ...
                'NextCeilEventIdx', nextCeilIdx, ...
                'NextFloorEventIdx', nextFloorIdx, ...
                'LeftNeighbors', idxList, ...
                'RightNeighbors', idxList, ...
                'id', -1);
            obj.CeilVtxIdxs = ceilIdx;
            obj.FloorVtxIdxs = floorIdx;
        end

        function obj = addCeil(obj, ceilVtxIdx, nextCeilEventIdx)
        % addCeil - Add the next ceiling vertex id to this PolyCell
        %
        % addCeil(obj, ceilVtxIdx, nextCeilEventIdx) adds ceilVtxIdx to the list of
        % ceiling vertex ids and stores nextCeilEventIdx as the cached `next`
        % ceiling id
            arguments
                obj 
                ceilVtxIdx (1,1);
                nextCeilEventIdx (1,1) = nan;
            end
            obj.CeilVtxIdxs = [obj.CeilVtxIdxs(:); ceilVtxIdx];
            obj.NextCeilEventIdx = nextCeilEventIdx;
        end

        function obj = addFloor(obj, floorVtxIdx, nextFloorEventIdx)
        %addFloor - Add the next floor vertex id to this PolyCell
        %
        % addFloor(obj, floorVtxIdx, nextFloorEventIdx) adds floorIdx to the list of
        % floor vertex ids and stores nextFloorIdx as the cached `next`
        % floor id
            arguments
                obj 
                floorVtxIdx (1,1);
                nextFloorEventIdx (1,1) = nan;
            end
            obj.FloorVtxIdxs = [obj.FloorVtxIdxs(:); floorVtxIdx];
            obj.NextFloorEventIdx = nextFloorEventIdx;
        end

        function obj = addLeftNeighbor(obj, cellId)
        %addLeftNeighbor - Add a new cell id to the list of left neighbors

            arguments (Input)
                obj
                cellId (1,1) {mustBeInteger}
            end

             obj.LeftNeighbors = [obj.LeftNeighbors(:); cellId];
        end

        function obj = addRightNeighbor(obj, cellId)
        %addRightNeighbor - Add a new cell id to the list of right neighbors

            arguments (Input)
                obj
                cellId (1,1) {mustBeInteger}
            end
             obj.RightNeighbors = [obj.RightNeighbors(:); cellId];
        end

        function obj = removeLeftNeighbor(obj, cellId)
        %removeLeftNeighbor - Remove cell id from the list of left neighbors

            arguments (Input)
                obj
                cellId (1,1) {mustBeInteger}
            end

             left = obj.LeftNeighbors;
             obj.LeftNeighbors(left==cellId) = [];
        end

        function obj = removeRightNeighbor(obj, cellId)
        %removeRightNeighbor - Remove cell id from the list of right neighbors

            arguments (Input)
                obj
                cellId (1,1) {mustBeInteger}
            end
             right = obj.RightNeighbors;
             obj.RightNeighbors(right==cellId) = [];
        end

        %% Const methods

        function [pc1, pc2] = cellOpenCeiling(obj, points, pds)
        %cellOpenCeiling - The line defining the open ceiling
        %
        %   [pc1, pc2] = cellOpenCeiling(CELL, POINTS, PDS) gives the line
        %   (in Cartesian coordinates) between the previously added
        %   ceiling vertex and the vertex of the cached `next` ceiling
        %   event

            arguments (Input)
                obj
                points (:, 2) double
                pds (:, 1) struct
            end
            arguments (Output)
                pc1 (1,2) double
                pc2 (1,2) double
            end

            % Get ceiling indices 
            ic1 = obj.CeilVtxIdxs(end);
            % Get corresponding points
            pc1 = points(ic1, :);
            pc2 = nav.decomp.internal.PolyCell.nextCeilPoint(obj,points, pds);
        end

        function [pf1, pf2] = cellOpenFloor(obj, points, pds)
        %cellOpenFloor - The line defining the open floor
        %
        %   [pf1, pf2] = cellOpenFloor(CELL, POINTS, PDS) gives the line
        %   (in Cartesian coordinates) between the previously added
        %   floor vertex and the vertex of the cached `next` floor
        %   event

            arguments (Input)
                obj
                points (:, 2) double
                pds (:, 1) struct
            end
            arguments (Output)
                pf1 (1,2) double
                pf2 (1,2) double
            end

            % Get floor indices 
            if1 = obj.FloorVtxIdxs(end);
            % Get corresponding points
            pf1 = points(if1, :);
            pf2 = nav.decomp.internal.PolyCell.nextFloorPoint(obj,points, pds);
        end

        function iCeilIdx = prevCeil(obj)
        %prevCeil - The vertex id of the last added ceiling point
            arguments (Input)
                obj
            end
            arguments (Output)
                iCeilIdx (1,1) {mustBeInteger}
            end

            iCeilIdx = obj.CeilVtxIdxs(end);
        end

        function iFloorIdx = prevFloor(obj)
        %prevFloor - The vertex id of the last added floor point
            arguments (Input)
                obj
            end
            arguments (Output)
                iFloorIdx (1,1) {mustBeInteger}
            end

            iFloorIdx = obj.FloorVtxIdxs(end);
        end

        function [ceilLim, floorLim, ceilHole, floorHole] = limits(obj, x, points, pds, holeStatus)
            %LIMITS - The y-value of the open ceiling and floor at given x
            %
            %   [ceilLim, floorLim, ceilHole, floorHole] = LIMITS(PCELL, X,
            %   POINTS, PDS, holeStatus) gives the y-values of the open
            %   ceiling and floor values as the given X position. Used for
            %   determining where to create new points when a cell is
            %   closed. For bookkeeping, the hole status of the ceiling and
            %   floor points is also returned

                arguments (Input)
                    obj
                    x (1,1) double
                    points (:,2) double
                    pds (:,1) struct
                    holeStatus (:,1) double
                end
                arguments (Output)
                    ceilLim (1,1) double
                    floorLim (1,1) double
                    ceilHole (1,1) logical
                    floorHole (1,1) logical
                end

            [ceilLim, ceilHole] = nav.decomp.internal.PolyCell.ceilLimit(obj,x, points, pds, holeStatus);
            [floorLim, floorHole] = nav.decomp.internal.PolyCell.floorLimit(obj,x, points, pds, holeStatus);

        end

        function [ceilLim, ishole] = ceilLimit(obj, x, points, pds, holeStatus)
            %ceilLimit - The y-value of the open ceiling at a given x
            %
            %   [ceilLim, ISHOLE] = ceilLimit(PCELL, X,
            %   POINTS, PDS, holeStatus) gives the y-value of the open
            %   ceiling value as the given X position. Used for
            %   determining where to create new points when a cell is
            %   closed. For bookkeeping, the hole status of the ceiling 
            %   point is also returned

                arguments (Input)
                    obj
                    x (1,1) double
                    points (:,2) double
                    pds (:,1) struct
                    holeStatus (:,1) double
                end
                arguments (Output)
                    ceilLim (1,1) double
                    ishole (1,1) logical
                end

            [c1, c2] = nav.decomp.internal.PolyCell.cellOpenCeiling(obj,points, pds);
            % Get ceiling limit
            ceilLim = intercept(c1, c2, x);
            if isnan(ceilLim)
                % xc, yc is a point or vertical line
                ceilLim = max([c1(2) c2(2)]);
            end
            ishole = holeStatus(nav.decomp.internal.PolyCell.prevCeil(obj));
        end

        function [floorLim, ishole] = floorLimit(obj, x, points, pds, holeStatus)
            %floorLimit - The y-value of the open floor at a given x
            %
            %   [floorLim, ISHOLE] = floorLimit(PCELL, X,
            %   POINTS, PDS, holeStatus) gives the y-value of the open
            %   floor value as the given X position. Used for
            %   determining where to create new points when a cell is
            %   closed. For bookkeeping, the hole status of the floor 
            %   point is also returned

                arguments (Input)
                    obj 
                    x (1,1) double
                    points (:,2) double
                    pds (:,1) struct
                    holeStatus (:,1) double
                end
                arguments (Output)
                    floorLim (1,1) double
                    ishole (1,1) logical
                end
            [f1, f2] = nav.decomp.internal.PolyCell.cellOpenFloor(obj,points, pds);
            % Get floor limit
            floorLim = intercept(f1, f2, x);
            if isnan(floorLim)
                % xf, yf is a point or vertical line
                floorLim = min([f1(2) f2(2)]);
            end
            ishole = holeStatus(nav.decomp.internal.PolyCell.prevFloor(obj));
        end

        function [m,vIdx] = asPoly(obj, points)
        %asPoly - The polyshape representation of this cell
        %
        %   [M, vIdx] = asPoly(PCELL, POINTS) constructs the polyshape
        %   representation M of the PolyCell. The vertex indices used to
        %   construct the polyshape are returned as vIdx.

            arguments (Input)
                obj
                points (:,2) double
            end
            arguments (Output)
                m polyshape
                vIdx (:,1) {mustBeInteger}
            end

            idx = nav.decomp.internal.PolyCell.boundaryIdx(obj);
            m = polyshape(points(idx,:));
            if nargout > 1
                vIdx = idx;
            end
        end

        function idx = boundaryIdx(obj)
        %boundaryIdx - The vertex ids of this cells boundary

            arguments (Input)
                obj
            end
            arguments (Output)
                idx (1,:) {mustBeInteger}
            end
            idx = [obj.CeilVtxIdxs(:); flip(obj.FloorVtxIdxs(:))];
        end

        function [m,vIdx] = asPolyPartial(obj, points, pds)
        %asPoly - The polyshape representation including 'next' points
        %
        %   [M, vIdx] = asPoly(PCELL, POINTS) constructs the polyshape
        %   representation M of the PolyCell including the vertices cached
        %   as 'next'. Used for checking edge cases with polyshape.
        %   The vertex indices used to construct the polyshape are returned 
        %   as vIdx.

            arguments (Input)
                obj
                points (:,2) double
                pds (:,1) struct
            end
            arguments (Output)
                m polyshape
                vIdx (:,1) {mustBeInteger}
            end
            if isfinite(obj.NextCeilEventIdx)
                iNextCeil = pds(obj.NextCeilEventIdx).vertexId;
            else
                iNextCeil = zeros(0,1);
            end
            if isfinite(obj.NextFloorEventIdx)
                iNextFloor = pds(obj.NextFloorEventIdx).vertexId;
            else
                iNextFloor = zeros(0,1);
            end
            idx =  [obj.CeilVtxIdxs(:); iNextCeil; iNextFloor; flip(obj.FloorVtxIdxs(:))];
            m = polyshape(points(idx,:));
            if nargout > 1
                vIdx = idx;
            end
        end

        function c = isComplete(obj)
        %isComplete - Return TRUE when the polygon is completed
        %
        %   C = isComplete(PCELL) is true when there is no cached 'next'
        %   ceiling or floor event. This indicates that the construction of
        %   the cell has completed.

            arguments (Input)
                obj
            end
            arguments (Output)
                c (1,1) logical
            end

            c = isnan(obj.NextCeilEventIdx) && isnan(obj.NextFloorEventIdx);
        end

        function point = nextCeilPoint(obj, points, pds)
        %nextCeilPoint - The rightmost ceiling point in this obj
        %
        %   POINT = nextCeilPoint(PCELL, POINTS, PDS) is the rightmost
        %   ceiling point on this cell. If there is a cached 'next'
        %   ceiling, it is this point. Otherwise, it is the rightmost
        %   actual ceiling point.

            arguments (Input)
                obj
                points (:,2) double
                pds (:,1) struct
            end
            arguments (Output)
                point (1,2) double
            end

            if isfinite(obj.NextCeilEventIdx)
                ic2 = pds(obj.NextCeilEventIdx).vertexId;
            else
                ic2 = nav.decomp.internal.PolyCell.prevCeil(obj);
            end
            point = points(ic2, :);
        end

        function point = nextFloorPoint(obj, points, pds)
        %nextFloorPoint - The rightmost floor point in this cell
        %
        %   POINT = nextFloorPoint(PCELL, POINTS, PDS) is the rightmost
        %   floor point on this cell. If there is a cached 'next'
        %   floor, it is this point. Otherwise, it is the rightmost
        %   actual floor point.

            arguments (Input)
                obj
                points (:,2) double
                pds (:,1) struct
            end
            arguments (Output)
                point (1,2) double
            end
            if isfinite(obj.NextFloorEventIdx)
                ic2 = pds(obj.NextFloorEventIdx).vertexId;
            else
                ic2 = nav.decomp.internal.PolyCell.prevFloor(obj);
            end
            point = points(ic2, :);
        end
    end
end

function y = intercept(p1, p2, xSweep)
% INTERCEPT - The y-value of the given x along the given line
%
%   Y = INTERCEPT(P1, P2, xSweep) calculates the y-value along the line
%   represented by points P1, P2 at xSweep.

    arguments (Input)
        p1 (1,2) double
        p2 (1,2) double
        xSweep (1,1) double
    end
    arguments (Output)
        y (1,1) double
    end

    p = [p1; p2];
    dx = xSweep-p(1,1);
    v = diff(p);
    vNorm = normalize(v,"norm");
    y = p(1,2) + vNorm(2)/vNorm(1)*dx;
end