classdef EventHandlers
%This class is for internal use only. It may be removed in the future.

%EventHandlers - Class containing the maps from EventType to its handler

%#codegen
%   Copyright 2024 The MathWorks, Inc.

    properties (Constant)
        %EventTypes - Ordered list of all EventTypes
        EventTypes = [nav.decomp.internal.EventType.In ...
            nav.decomp.internal.EventType.Out ...
            nav.decomp.internal.EventType.Ceiling ...
            nav.decomp.internal.EventType.Floor ...
            nav.decomp.internal.EventType.Pinch ...
            nav.decomp.internal.EventType.Split];

        %HandlerMap - Maps an EventType to a cell containing the function handle of its handler
        HandlerMap = dictionary(nav.decomp.internal.EventHandlers.EventTypes, ...
            {@handleInEvent @handleOutEvent @handleCeilingEvent @handleFloorEvent ...
            @handlePinchEvent @handleSplitEvent});
    end

    methods (Static)
        function handleCase(info,eventType)
            %getHandler - Gets a function handle to the handler of the eventType
            switch eventType
                case nav.decomp.internal.EventType.In
                    nav.decomp.internal.EventHandlers.handleInEvent(info);
                case nav.decomp.internal.EventType.Out
                    nav.decomp.internal.EventHandlers.handleOutEvent(info);
                case nav.decomp.internal.EventType.Ceiling
                    nav.decomp.internal.EventHandlers.handleCeilingEvent(info);
                case nav.decomp.internal.EventType.Floor
                    nav.decomp.internal.EventHandlers.handleFloorEvent(info);
                case nav.decomp.internal.EventType.Pinch
                    nav.decomp.internal.EventHandlers.handlePinchEvent(info);
                case nav.decomp.internal.EventType.Split
                    nav.decomp.internal.EventHandlers.handleSplitEvent(info);
            end
        end

        function handleInEvent(info)
        %handleInEvent Process an event of type IN
            
            if ~isempty(info.OpenCellIndices)
                % in what cell does this event occur?
                points = info.Points;
                holeStatus = info.HoleStatus;
                iClose = nav.decomp.internal.inCell(info, info.EventU.point, ...
                    points, info.EventTypes, holeStatus);

                % DEAL WITH THE UPPER CELL FIRST
    
                % Get floorLim now for future calculations
                [floorLim, floorHole] = nav.decomp.internal.PolyCell.floorLimit(info.AllCells(iClose),info.X, points, info.EventTypes, holeStatus);
                if floorLim > info.EventL.point(2)
                    floorLim = info.EventL.point(2);
                end
                aboveIdx = info.AboveOpenCellIdx;
                if isnan(aboveIdx) % make a new cell if a prior event did not
                    [ceilLim, ceilHole] = nav.decomp.internal.PolyCell.ceilLimit(info.AllCells(iClose),info.X, points, info.EventTypes, holeStatus);
                    if ceilLim < info.EventU.point(2)
                        % defense against the dark arts
                        ceilLim = info.EventU.point(2);
                    end
                    newCeil = [info.X ceilLim];
                    if isequal(newCeil, points(nav.decomp.internal.PolyCell.prevCeil(info.AllCells(iClose)), :))
                        % check for case where we cast up to a ceiling
                        % vertex already in Points
                        newCeilIdx = nav.decomp.internal.PolyCell.prevCeil(info.AllCells(iClose));
                    else
                        % Need to add a new ceiling point to Points
                        newCeilIdx = info.addPoint(newCeil, ceilHole);
                        % info.addCastEvent(newCeilIdx, )
                        % Update points references from change
                        points = info.Points;
                    end
    
                    % Get the next vertices from closingCell
                    cachedNextCeil = info.EventTypes(info.AllCells(iClose).NextCeilEventIdx).vertexId;
                    info.AllCells(iClose) = nav.decomp.internal.PolyCell.addCeil(info.AllCells(iClose),newCeilIdx);
    
                    % Create new upper cell
                    newUpperIdx = info.openCell(nav.decomp.internal.PolyCell.makeCell(newCeilIdx, info.EventU.pd.vertexId, ...
                        cachedNextCeil, info.EventU.pd.nextFloorId));
    
                    % Handle adjacency tracking
                    connectUpper = true;
                    % see if we should connect upper cell
                    %this comparison is checking if the higher of the two event points
                    % (if there are two) is 'too close' to the ceiling point above it
                    % such that polyshape might split the cell here.
                    if abs(info.EventU.point(2) - points(newCeilIdx, 2)) < info.ForgivingTol
                        upperPoly = nav.decomp.internal.PolyCell.asPolyPartial(info.AllCells(newUpperIdx),points, info.EventTypes);
                        cidx = info.AllCells(iClose).CeilVtxIdxs(:);
                        fidx = flip(info.AllCells(iClose).FloorVtxIdxs(:));
                        pcellTempPoints = [points(cidx, :); [info.X floorLim]; points(fidx, :)];
                        oldPoly = polyshape(pcellTempPoints);
    
                        [~, connectUpper] = nav.decomp.internal.checkSeparate(upperPoly, oldPoly);
                    end
    
                    if connectUpper
                        info.AllCells(iClose) = nav.decomp.internal.PolyCell.addRightNeighbor(info.AllCells(iClose),newUpperIdx);
                        info.AllCells(newUpperIdx) = nav.decomp.internal.PolyCell.addLeftNeighbor(info.AllCells(newUpperIdx),info.AllCells(iClose).id);
                    end
                else
                    % we must deal with the previous event opening a
                    % cell by adding ourselves as the floor
                    info.AllCells(aboveIdx) = nav.decomp.internal.PolyCell.addFloor(info.AllCells(aboveIdx),info.EventU.pd.vertexId, info.EventU.pd.nextFloorId);
                end
    
                % NOW CONSIDER THE LOWER CELL
                % Check if any other events occur in between this event
                % and the bottom of the lower cell
                searchIdx = info.EventL.localIdx + 1;
                if searchIdx <= numel(info.EventIndices)
                    yNext = points(info.EventTypes(info.EventIndices(searchIdx)).vertexId,2);
                    collision = yNext < info.EventL.point(2) && yNext >= floorLim;
                else
                    collision = false;
                end
    
                % OPEN NEW CELLS
    
                if ~collision % close the cell and make a new cell with matching floor to the cell we just closed
                    % add close the current open cell
                    newFloor = [info.X floorLim];
                    newFloorIdx = info.addPoint(newFloor, floorHole);
                    points = info.Points;
                    cachedNextFloor = info.EventTypes(info.AllCells(iClose).NextFloorEventIdx).vertexId;
                    info.AllCells(iClose) = nav.decomp.internal.PolyCell.addFloor(info.AllCells(iClose),newFloorIdx);
                    info.markClosed(info.AllCells(iClose).id);
    
                    % add a new cell below
                    newLowerIdx = info.openCell(nav.decomp.internal.PolyCell.makeCell(info.EventL.pd.vertexId, newFloorIdx, ...
                        info.EventL.pd.nextCeilId, cachedNextFloor));
                else
                    % leave closingCell open and make a new lower cell without bottom
                    newLowerIdx = info.openCell(nav.decomp.internal.PolyCell.makeCell(info.EventL.pd.vertexId, [], ...
                        info.EventL.pd.nextCeilId, inf));
                end
    
                % Handle adjacency tracking
    
                % Adjust the reference y we check to based on if there
                % is a event below us
                if ~collision
                    floorRef = floorLim;
                else
                    floorRef = points(info.EventTypes(info.EventIndices(searchIdx)).vertexId, 2);
                end
    
                % see if we should connect lower cell
                if abs(info.EventL.point(2) - floorRef) < info.ForgivingTol
                    % If collision, must add a temporary floor to lower cell to create
                    % a valid polyshape
                    if collision
                        extendedNextFloor = info.EventTypes(info.EventIndices(searchIdx)).nextFloorId;
                        if isnan(extendedNextFloor) % collision event is OUT
                            extendedNextFloor = info.EventTypes(info.AllCells(iClose).NextFloorEventIdx).vertexId;
                        end
                        extendedFloor = info.EventTypes(info.EventIndices(searchIdx)).vertexId;
                        info.AllCells(newLowerIdx) = nav.decomp.internal.PolyCell.addFloor(info.AllCells(newLowerIdx),extendedFloor, extendedNextFloor); % will undo this
                    end
    
                    % Construct the polyshapes and check if we should connect
                    oldPoly = nav.decomp.internal.PolyCell.asPoly(info.AllCells(iClose),points);
                    lowerPoly = nav.decomp.internal.PolyCell.asPolyPartial(info.AllCells(newLowerIdx),points, info.EventTypes);
                    [~, connectLower] = nav.decomp.internal.checkSeparate(lowerPoly, oldPoly);
    
                    % Undo the modification to lower cell if collision
                    if collision
                        info.AllCells(newLowerIdx).FloorVtxIdxs = [];
                        info.AllCells(newLowerIdx).NextFloorEventIdx = inf;
                    end
                else
                    % By default we connecting the closing and lower cells
                    connectLower = true;
                end
    
                if connectLower
                    info.AllCells(iClose) = nav.decomp.internal.PolyCell.addRightNeighbor(info.AllCells(iClose),newLowerIdx);
                    info.AllCells(newLowerIdx) = nav.decomp.internal.PolyCell.addLeftNeighbor(info.AllCells(newLowerIdx),info.AllCells(iClose).id);
                end
    
                if ~collision
                    % there is now no active 'above cell'
                    info.setAboveOpenCellIdx();
                else
                    % set the new cell as the 'above cell'
                    info.setAboveOpenCellIdx(newLowerIdx);
                end
            end
        end

        function handleOutEvent(info)
        %handleOutEvent Handle and event of type OUT

            if ~isempty(info.OpenCellIndices)
                % Find neighboring cells
                [openCells,iOpen] = info.openCells();
                iHit = find(arrayfun(@(x)x.NextFloorEventIdx==info.EventU.idx || ...
                    x.NextCeilEventIdx == info.EventL.idx, openCells), 2);
                assert(numel(iHit) == 2);
    
                % Retrieve upper/lower
                nbrCellIdx = circshift(iHit,double(openCells(iHit(1)).NextFloorEventIdx ~= info.EventU.idx));
                [iUpper,iLower] = deal(nbrCellIdx(1),nbrCellIdx(2));
    
                % Close the upper cell
                points = info.Points;
                info.AllCells(iOpen(iUpper)) = nav.decomp.internal.PolyCell.addFloor(info.AllCells(iOpen(iUpper)),info.EventU.pd.vertexId);
                newCeilIdx = [];
                cachedNextCeil = nan;
                coder.varsize("newCeilIdx",[1 1],[1 0]);
                if ~nav.decomp.internal.PolyCell.isComplete(info.AllCells(iOpen(iUpper)))
                    % Update the ceiling with the new ceiling point
                    % (if it does not already have an ending ceiling point)
                    [ceilLim, ceilHole] = nav.decomp.internal.PolyCell.ceilLimit(info.AllCells(iOpen(iUpper)),info.X, points, ...
                        info.EventTypes, info.HoleStatus);
                    % Prevent numerical shenanigans from messing with us
                    % defense against the dark arts
                    ceilLim = max(ceilLim,info.EventU.point(2));
                    % New ceiling point
                    newCeil = [info.X ceilLim];
                    if isequal(newCeil, points(nav.decomp.internal.PolyCell.prevCeil(info.AllCells(iOpen(iUpper))), :))
                        % check for case where we cast up to a ceiling
                        % point
                        newCeilIdx = nav.decomp.internal.PolyCell.prevCeil(info.AllCells(iOpen(iUpper)));
                    else
                        newCeilIdx = info.addPoint(newCeil, ceilHole);
                        % update our local reference to points
                        points = info.Points;
                    end
                    % Actually add the new ceiling point to the upper cell
                    cachedNextCeil = info.EventTypes(info.AllCells(iOpen(iUpper)).NextCeilEventIdx).vertexId;
                    info.AllCells(iOpen(iUpper)) = nav.decomp.internal.PolyCell.addCeil(info.AllCells(iOpen(iUpper)),newCeilIdx);
                end
    
                % Finally, close the upper cell
                info.markClosed(info.AllCells(iOpen(iUpper)).id);
    
                % Move on to the lower cell we need to close
                [floorLim, floorHole] = nav.decomp.internal.PolyCell.floorLimit(info.AllCells(iOpen(iLower)),info.X, points, ...
                    info.EventTypes, info.HoleStatus);
    
                % Again, prevent numerical weirdness
                floorLim = min(floorLim,info.EventL.point(2));
    
                % Check for other event collisions
                searchIdx = info.EventL.localIdx + 1;
                if searchIdx <= numel(info.EventIndices)
                    % Look below us at all of the events sharing the same X value and
                    % see if they are between us and our floorLim - this is a
                    % 'collision'
                    yNext = points(info.EventTypes(info.EventIndices(searchIdx)).vertexId,2);
                    collision = yNext < info.EventL.point(2) && yNext >= floorLim;
                else
                    collision = false;
                end
    
                % Add current point as ceil to lower cell
                info.AllCells(iOpen(iLower)) = nav.decomp.internal.PolyCell.addCeil(info.AllCells(iOpen(iLower)),info.EventL.pd.vertexId);
    
                % We can close the lower cell if there is no collision
                newFloorIdx=[];
                cachedNextFloor=inf;
                coder.varsize("newFloorIdx",[1 1],[1 0]);
                if ~collision
                    % Make floor point from floorLim
                    newFloor = [info.X floorLim];
                    newFloorIdx = info.addPoint(newFloor, floorHole);
                    % update our local reference to points
                    points = info.Points;
    
                    % Get the next vertices from current cell
                    cachedNextFloor = info.EventTypes(info.AllCells(iOpen(iLower)).NextFloorEventIdx).vertexId;
    
                    % Actually do the closing
                    info.AllCells(iOpen(iLower)) = nav.decomp.internal.PolyCell.addFloor(info.AllCells(iOpen(iLower)),newFloorIdx);
                    info.markClosed(info.AllCells(iOpen(iLower)).id);
                end
    
                % OPEN NEW CELL
    
                % Check floor/ceil collisions for proper adjacency
                % update
                upperCeilIdx = nav.decomp.internal.PolyCell.prevCeil(info.AllCells(iOpen(iUpper)));
                connectUpper = checkOutEventConnection(info, info.EventU.point(2), ...
                    points(upperCeilIdx, 2), info.AllCells(iOpen(iUpper)), upperCeilIdx, floorLim, cachedNextCeil);
                connectLower = checkOutEventConnection(info, info.EventL.point(2), ...
                    floorLim, info.AllCells(iOpen(iLower)), upperCeilIdx, floorLim, cachedNextCeil);
    
                % Actually make the new cell
                aboveIdx = info.AboveOpenCellIdx;
                if isnan(aboveIdx)
                    % Create new cell if one doesn't exist
                    newIdx = info.openCell(nav.decomp.internal.PolyCell.makeCell(newCeilIdx, newFloorIdx, cachedNextCeil, cachedNextFloor));
    
                    % Make adjacency connections
                    if connectUpper
                        info.AllCells(iOpen(iUpper)) = nav.decomp.internal.PolyCell.addRightNeighbor(info.AllCells(iOpen(iUpper)),newIdx);
                        info.AllCells(newIdx) = nav.decomp.internal.PolyCell.addLeftNeighbor(info.AllCells(newIdx),info.AllCells(iOpen(iUpper)).id);
                    end
                    if connectLower
                        info.AllCells(iOpen(iLower)) = nav.decomp.internal.PolyCell.addRightNeighbor(info.AllCells(iOpen(iLower)),newIdx);
                        info.AllCells(newIdx) = nav.decomp.internal.PolyCell.addLeftNeighbor(info.AllCells(newIdx),info.AllCells(iOpen(iLower)).id);
                    end
    
                    % Event below me (if it exists) must deal with the newCell
                    if collision
                        info.setAboveOpenCellIdx(newIdx)
                    else
                        info.setAboveOpenCellIdx()
                    end
                else
                    if ~collision
                        % Add event to floor of above cell
                        info.AllCells(aboveIdx) = nav.decomp.internal.PolyCell.addFloor(info.AllCells(aboveIdx),newFloorIdx, cachedNextFloor);
                        info.setAboveOpenCellIdx();
                    end
                    if connectLower
                        info.AllCells(iOpen(iLower)) = nav.decomp.internal.PolyCell.addRightNeighbor(info.AllCells(iOpen(iLower)),info.AllCells(aboveIdx).id);
                        info.AllCells(aboveIdx) = nav.decomp.internal.PolyCell.addLeftNeighbor(info.AllCells(aboveIdx),info.AllCells(iOpen(iLower)).id);
                    end
                end
            end
        end

        function handleFloorEvent(info)
        %handleFloorEvent Process an event of type FLOOR

            if ~isempty(info.OpenCellIndices)
                % If this is a coupled event, we need to see which event should occur
                % first (the one the floor is going into), and which should occur
                % second (the one the next floor should come out of)
                [firstEvent, secondEvent, lowerPointFirst] = orderEvents(info, ...
                    nav.decomp.internal.EventType.In, ...
                    nav.decomp.internal.EventType.Pinch);
    
                % Get the higher/lower points
                topPoint = info.EventU.point;
                bottomPoint = info.EventL.point;
    
                % See which (single) cell this FLOOR is associated with
                [openCells,iOpen] = info.openCells();
                iHit = find([openCells.NextFloorEventIdx] == firstEvent.idx);
                parentIdx = iOpen(iHit(1));
                aboveIdx = info.AboveOpenCellIdx;

                if ~isnan(aboveIdx) % Above cell is already open, easy!
                    % Above cell is already open. No degenerate intersection can occur
                    % at this floor, as the presence of openAboveCell indicates that the
                    % previous handler found the current floor event to be the bottom
                    % of the open cell along this crit-line. Update the floor of the
                    % current cell and its parent, and close the parent.
                    % Note: there is no chance of a degenerate intersection here, as
                    % the aboveOpenCell being present indicates that the event above me
                    % saw me in between it and the floor, implying there is nothing
                    % else between us, including another edge
                    info.AllCells(parentIdx) = nav.decomp.internal.PolyCell.addFloor(info.AllCells(parentIdx),firstEvent.pd.vertexId);
                    info.markClosed(info.AllCells(parentIdx).id);
    
                    info.AllCells(aboveIdx) = nav.decomp.internal.PolyCell.addFloor(info.AllCells(aboveIdx),secondEvent.pd.vertexId, secondEvent.pd.nextFloorId);
                else % normal floor
                    % Always add the first event to the parentCell
                    info.AllCells(parentIdx) = nav.decomp.internal.PolyCell.addFloor(info.AllCells(parentIdx),firstEvent.pd.vertexId, firstEvent.pd.nextFloorId);
    
                    % Check if we have an intersection and need to make a new cell
                    ceilLim = nav.decomp.internal.PolyCell.ceilLimit(info.AllCells(parentIdx),info.X, info.Points, info.EventTypes, info.HoleStatus);
                    ceilLim = max(ceilLim, topPoint(2)); % defense against the dark arts
                    isSplit = handleFloorCeilCutoff(info, ceilLim, topPoint(2), parentIdx, ...
                        firstEvent, secondEvent, info.Points, info.EventTypes, ...
                        topPoint, bottomPoint, lowerPointFirst,...
                        @makeFloorRightPoly, ...
                        @makeFloorNewCell, ...
                        @floorFinishParentCell);
                    % If we have a coupled event and did not split, add the second event to parentCell
                    if ~isSplit && firstEvent.idx ~= secondEvent.idx
                        info.AllCells(parentIdx) = nav.decomp.internal.PolyCell.addFloor(info.AllCells(parentIdx),secondEvent.pd.vertexId, secondEvent.pd.nextFloorId);
                    end
                end
                if info.StoreDegenerate
                    info.storePotentialDegenerateEvent(info.AllCells(parentIdx).id, topPoint(2), bottomPoint(2));
                end
                % Clear aboveOpenCell
                info.setAboveOpenCellIdx();
            end
        end

        function handleCeilingEvent(info)
        %handleFloorEvent Process an event of type CEILING

            if ~isempty(info.OpenCellIndices)
                % If this is a coupled event, we need to see which event should occur
                % first (the one the ceiling is going into), and which should occur
                % second (the one the next ceiling should come out of)
                [firstEvent, secondEvent, lowerPointFirst] = orderEvents(info, ...
                    nav.decomp.internal.EventType.Split, ...
                    nav.decomp.internal.EventType.Out);
    
                % Get the higher/lower points
                topPoint = info.EventU.point;
                bottomPoint = info.EventL.point;
    
                % See which (single) cell this ceiling is associated with
                [openCells,iOpen] = info.openCells();
                iHit = find([openCells.NextCeilEventIdx] == firstEvent.idx);
                parentIdx = iOpen(iHit(1));
    
                % Always add the first event to the parentCell
                info.AllCells(parentIdx) = nav.decomp.internal.PolyCell.addCeil(info.AllCells(parentIdx),firstEvent.pd.vertexId, firstEvent.pd.nextCeilId);
    
                % Check if we have an intersection and need to make
                % a new cell
                floorLim = nav.decomp.internal.PolyCell.floorLimit(info.AllCells(parentIdx),info.X, info.Points, info.EventTypes, info.HoleStatus);
                floorLim = min(floorLim,bottomPoint(2));
                isSplit = handleFloorCeilCutoff(info, floorLim, bottomPoint(2), parentIdx, ...
                    firstEvent, secondEvent, info.Points, info.EventTypes, ...
                    topPoint, bottomPoint, lowerPointFirst,...
                    @makeCeilingRightPoly, ...
                    @makeCeilingNewCell,...
                    @ceilingFinishParentCell);
                % If we have a coupled event and did not split, add the second event to parentCell
                if ~isSplit && firstEvent.idx ~= secondEvent.idx
                    info.AllCells(parentIdx) = nav.decomp.internal.PolyCell.addCeil(info.AllCells(parentIdx),secondEvent.pd.vertexId, secondEvent.pd.nextCeilId);
                end
    
                if info.StoreDegenerate
                    info.storePotentialDegenerateEvent(info.AllCells(parentIdx).id, topPoint(2), bottomPoint(2));
                end
    
                % Clear aboveOpenCell
                info.setAboveOpenCellIdx();
            end
        end

        function handleSplitEvent(info)
        %handleSplitEvent Process an event of type SPLIT

            % single split is relatively easy
            newIdx = info.openCell(nav.decomp.internal.PolyCell.makeCell(info.EventU.pd.vertexId, info.EventL.pd.vertexId, ...
                info.EventU.pd.nextCeilId, info.EventL.pd.nextFloorId));

            % watch out for overlapping pinch/split that is not
            % caught, must track these cells for checking later...
            if info.StoreDegenerate
                info.storePotentialDegenerateEvent(newIdx, info.EventU.point(2), info.EventL.point(2));
            end
        end

        function handlePinchEvent(info)
        %handlePinchEvent Process an event of type PINCH

            if ~isempty(info.OpenCellIndices)
                % See which (single) cell this pinch is associated with
                [openCells,iOpen] = info.openCells();
                iHit = find([openCells.NextFloorEventIdx] == info.EventL.idx & [openCells.NextCeilEventIdx] == info.EventU.idx);
                parentIdx = iOpen(iHit(1));
    
                % only add to floor or ceil to avoid duplications
                info.AllCells(parentIdx) = nav.decomp.internal.PolyCell.addCeil(info.AllCells(parentIdx),info.EventU.pd.vertexId);
                if info.EventU.idx ~= info.EventL.idx
                    info.AllCells(parentIdx) = nav.decomp.internal.PolyCell.addFloor(info.AllCells(parentIdx),info.EventL.pd.vertexId);
                end
    
                % watch out for overlapping pinch/split that is not
                % caught, must track these cells for checking later...
                if info.StoreDegenerate
                    info.storePotentialDegenerateEvent(info.AllCells(parentIdx).id, info.EventU.point(2), info.EventL.point(2));
                end
    
                info.markClosed(info.AllCells(parentIdx).id);
            end
        end
    end
end

function isSplit = handleFloorCeilCutoff(info, lim, checkY, parentIdx, ...
        firstEvent, secondEvent, points, pds, ...
        topPoint, bottomPoint, lowerPointFirst,...
        makeRightPolyFcn, makeNewCellFcn, finishParentCellFcn)
    %handleFloorCeilCutOff - Check for and handle case where FLOOR/CEIL intersects edge
    %   This function deals with the edge case where a floor or ceiling event
    %   intersects the edge above/below it, effectively 'cutting off' the cell
    %   it was a part of and forcing a new cell to be created. This case is
    %   made doubly complicated by the case where the floor ceiling is
    %   coupled (Upper and Lower events together making a floor/ceiling). In
    %   these cases, the construction of the polyshapes for checking adjacency
    %   must be done carefully--this functionality is passed to this function
    %   as makeRightPolyFcn and makeNewCellFcn.
    isSplit = false;
    if abs(lim - checkY) < info.ForgivingTol
        % Make polyshape to the left of the intersection
        leftPoly = makeLeftPoly(info.AllCells(parentIdx), info.X, lim, points);
        % Make polyshape to the right of the intersection
        rightPoly = makeRightPolyFcn(lowerPointFirst, firstEvent, secondEvent, info.AllCells(parentIdx), points, pds);
        % Check for connection
        [isSplit, connect] = nav.decomp.internal.checkSeparate(leftPoly, rightPoly);
        if isSplit
            % Open new cell resulting from the cutoff
            newIdx = info.openCell(makeNewCellFcn(lowerPointFirst, firstEvent, secondEvent, info.AllCells(parentIdx), pds));

            % Make new connections, if required
            if connect
                info.AllCells(parentIdx) = nav.decomp.internal.PolyCell.addLeftNeighbor(info.AllCells(parentIdx),newIdx);
                info.AllCells(newIdx) = nav.decomp.internal.PolyCell.addRightNeighbor(info.AllCells(newIdx),info.AllCells(parentIdx).id);
            end
            % Flag this event for later checking if in degenerate region
            if info.StoreDegenerate
                info.storePotentialDegenerateEvent(newIdx, topPoint(2), bottomPoint(2));
            end
            % Add final points to parent cell
            info.AllCells(parentIdx) = finishParentCellFcn(lowerPointFirst, firstEvent, secondEvent, info.AllCells(parentIdx));
            % Finally, close the cell that has been cut off
            info.markClosed(info.AllCells(parentIdx).id);
        end
    end
end

function connect = checkOutEventConnection(info, eventPoint, limPoint, pCell, upperCeilIdx, floorLim, cachedNextCeil)
    %checkOutEventConnection - Helper helper to determine how to connect new cells to closing cell in an OUT event
    connect = true;
    if abs(eventPoint - limPoint) < info.ForgivingTol
        closingPoly = nav.decomp.internal.PolyCell.asPoly(pCell,info.Points);
        ceilPoint = info.Points(upperCeilIdx, :);
        aboveIdx = info.AboveOpenCellIdx;
        if isnan(aboveIdx)
            nextCeilPoint = info.Points(cachedNextCeil, :);
        else
            nextCeilPoint = info.Points(info.EventTypes(info.AllCells(aboveIdx).NextCeilEventIdx).vertexId, :);
        end
        newPoly = polyshape([ceilPoint; nextCeilPoint; [info.X floorLim]]);

        [~, connect] = nav.decomp.internal.checkSeparate(closingPoly, newPoly);
    end
end

function [firstEvent, secondEvent, lowerPointFirst] = orderEvents(info, upType, lowType)
    %orderEvents - Determine which events in a couple floor/ceil occur first
    if info.EventU.pd.type == upType && info.EventL.pd.type == lowType
        firstEvent = info.EventL;
        secondEvent = info.EventU;
        lowerPointFirst = true;
    else
        firstEvent = info.EventU;
        secondEvent = info.EventL;
        lowerPointFirst = false;
    end
end

function leftPoly = makeLeftPoly(parentCell, x, lim, points)
    %makeLeftPoly - Make the left poly for adjacency checking a cut off floor/ceiling
    cidx = parentCell.CeilVtxIdxs(:);
    fidx = flip(parentCell.FloorVtxIdxs(:));
    leftPoly = polyshape([points(cidx, :); [x lim]; points(fidx, :)]);
end

function rightPoly = makeCeilingRightPoly(lowerPointFirst, firstEvent, secondEvent, parentCell, points, pds)
    %makeCeilingRightPoly - Make the right poly for adjacency checking a cut off ceiling
    if lowerPointFirst % need first as vertex here
        rightPoly = polyshape([firstEvent.point; secondEvent.point; points(secondEvent.pd.nextCeilId, :); points(pds(parentCell.NextFloorEventIdx).vertexId, :)]);
    else % cannot have first as vertex here
        rightPoly = polyshape([secondEvent.point; points(secondEvent.pd.nextCeilId, :); points(pds(parentCell.NextFloorEventIdx).vertexId, :)]);
    end
end

function newCell = makeCeilingNewCell(lowerPointFirst, firstEvent, secondEvent, parentCell, pds)
    %makeCeilingNewCell - Construct the new cell for when a ceiling event is cut off
    if lowerPointFirst
        newCell = nav.decomp.internal.PolyCell.makeCell(secondEvent.pd.vertexId, firstEvent.pd.vertexId, ...
            secondEvent.pd.nextCeilId, pds(parentCell.NextFloorEventIdx).vertexId);
    else
        newCell = nav.decomp.internal.PolyCell.makeCell(secondEvent.pd.vertexId, secondEvent.pd.vertexId, ...
            secondEvent.pd.nextCeilId, pds(parentCell.NextFloorEventIdx).vertexId);
    end
end

function rightPoly = makeFloorRightPoly(lowerPointFirst, firstEvent, secondEvent, parentCell, points, pds)
    %makeFloorRightPoly - Make the right poly for adjacency checking a cut off floor
    if lowerPointFirst
        rightPoly = polyshape([secondEvent.point; points(secondEvent.pd.nextFloorId, :); points(pds(parentCell.NextCeilEventIdx).vertexId, :)]);
    else
        rightPoly = polyshape([secondEvent.point; firstEvent.point; points(secondEvent.pd.nextFloorId, :); points(pds(parentCell.NextCeilEventIdx).vertexId, :)]);
    end
end

function newCell = makeFloorNewCell(lowerPointFirst, firstEvent, secondEvent, parentCell, pds)
    %makeFloorNewCell - Construct the new cell for when a floor event is cut off
    if lowerPointFirst
        newCell = nav.decomp.internal.PolyCell.makeCell(secondEvent.pd.vertexId, secondEvent.pd.vertexId, pds(parentCell.NextCeilEventIdx).vertexId, secondEvent.pd.nextFloorId);
    else
        newCell = nav.decomp.internal.PolyCell.makeCell(firstEvent.pd.vertexId, secondEvent.pd.vertexId, pds(parentCell.NextCeilEventIdx).vertexId, secondEvent.pd.nextFloorId);
    end
end

function parentCell = ceilingFinishParentCell(lowerPointFirst, ~, secondEvent, parentCell)
    %ceilingFinishParentCell - Update parentCell ceiling if ~lowerPointFirst
    if ~lowerPointFirst
        parentCell = nav.decomp.internal.PolyCell.addCeil(parentCell,secondEvent.pd.vertexId);
    end
end

function parentCell = floorFinishParentCell(lowerPointFirst, firstEvent, secondEvent, parentCell)
    %floorFinishParentCell - Update the parentCell floor for single floor or when lowerPointFirst
    if firstEvent.idx == secondEvent.idx || lowerPointFirst
        parentCell = nav.decomp.internal.PolyCell.addFloor(parentCell,secondEvent.pd.vertexId, secondEvent.pd.nextFloorId);
    end
end