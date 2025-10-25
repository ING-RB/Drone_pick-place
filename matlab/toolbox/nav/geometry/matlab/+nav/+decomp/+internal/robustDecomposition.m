function [allCells, points, holeStatus] = robustDecomposition(m, visualize)
%This function is for internal use only. It may be removed in the future.

%robustDecomposition - Decompose a given polyshape into cells
%   [allCells, POINTS, holeStatus] = robustDecomposition(M, VISUALIZE) decomposes 
%   a given polyshape M into cells PCELLS that together cover the entire 
%   region defined by the polyshape. Also the cells in PCELLS reference
%   point indices for the points in POINTS, and holeStatus returns of each
%   point in POINTS is on a hole boundary (TRUE) or region boundary
%   (FALSE). If the VISUALIZE flag is set to TRUE, the cells will be
%   plotted against the region during the execution of the algorithm.

%   Copyright 2024-2025 The MathWorks, Inc.
%#codegen

    arguments
        m polyshape
        visualize logical = false;
    end
    % Prep outputs
    allCells = repmat(nav.decomp.internal.PolyCell.makeCell,0,1);
    points = zeros(0,2);
    holeStatus = false(0,1);
    coder.varsize("allCells","holeStatus",[inf 1]);
    coder.varsize("points",[inf 2]);

    % Only process non-empty polyshape
    if m.NumRegions > 0
        % Tolerance to check if we may be near polyshape's numerical weirdness
        forgivingTol = 1e-8;
    
        % Disable polyshape warnings and cache previous state to prevent
        % side-effects, set to return to state onCleanup
        % Turn off polyshape warnings for decomposition, reenable after
        warnings = {'MATLAB:polyshape:repairedBySimplify'...
                    'MATLAB:polyshape:boolOperationFailed'...
                    'MATLAB:polyshape:boundary3Points'};
        ws = warning;
        cellfun(@(x)warning('off',x),warnings,UniformOutput=false);
        cleanWarn = onCleanup(@()warning(ws));
    
        % Create the initial context from the polyshape 
        % (all data structures needed for event handlers)
        info = nav.decomp.internal.DecompositionContext(m, forgivingTol, visualize);
    
        if visualize
            % Plot the polyshape, which we will be plotting the cells over
            nav.decomp.internal.visualizePolyshape(m, info.EventTypes);
            hold on;
        end
    
        % Identify where crit-lines are and if they are degenerate
        [xCoord,firstXIndices,iSortMap] = unique(info.OrderedPoints(:,1));
        numEventsAtX = accumarray(iSortMap,1);
        isDegenerateRegion = [false; diff(xCoord) < forgivingTol; false];
    
        % Start sweeping left-right through the events
        for ix = 1:numel(firstXIndices)
            x = xCoord(ix);
            numEvents = numEventsAtX(ix);
            xOrderLoc = firstXIndices(ix);
            % Get all the events that occur at the x of the next event
            eventIndices = info.Order(xOrderLoc:xOrderLoc+numEvents-1)';
        
            % If crit-lines are too close together there is a chance for
            % numerical instability in determining connections because polyshape 
            % could consider two regions touching if they are close enough. 
            % To deal with this, we keep track of cells that are opened/closed
            % when crit-lines are within forgivingTol range of each other.
            % These flags keep track of when that case occurs, which we refer
            % to as a 'degenerate region'
            prevDegenerateRegion = isDegenerateRegion(ix);
            degenerateRegion = isDegenerateRegion(ix+1);
            endOfDegenerateRegion = ~degenerateRegion && prevDegenerateRegion;
    
            currEventIdx = 1;
            while currEventIdx <= numel(eventIndices) % go through each event on a single crit-line
                % get event info
                idxu = eventIndices(currEventIdx);
                pdu = info.EventTypes(idxu);
                pointu = info.Points(pdu.vertexId, :);
                eventu = eventData(idxu, pdu, pointu, currEventIdx);
    
                % The LOWER event in a UPPER\LOWER pair is always handled with
                % its UPPER, which always occurs first. VertEdge events are, by
                % definition, not events that cause cells to be changed. Both
                % of these cases can be safely ignored.
                if pdu.dir == nav.decomp.internal.Side.Lower || pdu.type == nav.decomp.internal.EventType.VertEdge
                    currEventIdx = currEventIdx + 1;
                    continue;
                end
                
                % Deal with potential collinearities
                [continueFlag, eventl, eventIndices] = handleCollinearities(info,eventu,eventIndices);
    
                % We have made adjustments due to collinearities, look again
                % here from the beginning
                if continueFlag
                    continue;
                end
    
                % Update the context with data we just changed
                info.X = x;
                info.EventU = eventu;
                info.EventL = eventl;
                info.EventIndices = eventIndices;
                info.StoreDegenerate = degenerateRegion || endOfDegenerateRegion;
    
                % Get the event type the events should be treated as
                effectiveEventType = getEffectiveEventType(eventu, eventl);
    
                % Run appropriate handler with context
                nav.decomp.internal.EventHandlers.handleCase(info,effectiveEventType);
    
                if endOfDegenerateRegion
                    % this is the end of the degenerate region, check if any
                    % events occur too close together
                    info.degenerateRegionCleanup();
                end
    
                % increment to next event
                currEventIdx = currEventIdx + 1;
            end
        end
   
        % POST PROCESSING
    
        % Make sure that the connections are correct for events that occur at
        % sweeplines that are too close together (within forgivingTol range)
        info.doubleCheckConnections();
    
        % Check if any cells are so small that polyshape considers them empty
        % if so, flag them for deletion and transfer their connections to neighbors
        [indicesToRemove, info.Points, info.AllCells] = correctEmptyPolyCells(info.AllCells, info.Points);

        % Remove the empty polycells and reindex accordingly
        info.removePolyCells(indicesToRemove);

        % Remove unmapped vertices and reindex accordingly
        info = remapUnusedVertices(info);
   
        if visualize
            hold off;
        end

        % Return outputs
        allCells = info.AllCells;
        points = info.Points;
        
        if m.NumHoles > 0
            holes = polyshape;
            ih = find(m.ishole)';
            for i = 1:numel(ih)
                [x,y] = m.boundary(ih(i));
                holes = holes.union(polyshape([x y]));
            end
            [tfInt,tfOn] = holes.isinterior(points);
            holeStatus = tfInt | tfOn;
        else
            holeStatus = false(size(points,1),1);
        end
    end
end

% MAIN HELPER FUNCTIONS

function [continueFlag, eventl, eventIndices] = handleCollinearities(info, eventu, eventIndices)
%handleCollinearities - Process events that occur along the same x point
    points = info.Points; pds = info.EventTypes; holeStatus = info.HoleStatus;
    forgivingTol = info.ForgivingTol;
    [openCells_i,iOpen_i] = info.openCells();
    aboveIdx = info.AboveOpenCellIdx;
    if ~isnan(aboveIdx)
        % do not include aboveOpenCell when checking collinearities
        openCells = openCells_i(1:end-1);
        iOpen = iOpen_i(1:end-1);
    else
        openCells = openCells_i;
        iOpen = iOpen_i;
    end

    continueFlag = false;
    cellPairsToCheck = [];
    % first things first, check if the current event is coincident
    [isCollision, endEventIdx] = nav.decomp.internal.checkUnhandledCollision(eventu.point, eventu.localIdx+1, eventIndices, points, pds);
            
    if isCollision % must reclassify points!
        % Check if there are open edges 'too-close' to the intersect point
        [eventIndices, endEventIdx, pds, cellPairsToCheck, openCells] = checkEdgeAtCollision(eventu, ...
            points, pds, eventIndices, openCells, holeStatus, forgivingTol, endEventIdx);
        % Perform the reclassification
        [newEventIdxs, pds, ~, openCells] = nav.decomp.internal.reclassifyCoincident(eventIndices(eventu.localIdx:endEventIdx), pds, points, openCells);
        eventIndices(eventu.localIdx:endEventIdx) = newEventIdxs;
        continueFlag = true;
        eventl = repmat(eventu,0,1);
    else
        % From here on, we know the event at pdu is not coincident with
        % anything or, if it is, we have dealt with it
    
        % If not an UPPER point, we can just stop here
        coupledEvent = eventu.pd.dir == nav.decomp.internal.Side.Upper;
        if ~coupledEvent
            eventl = eventu;
        else
            % Different lower and upper points -- a LOT more complex than single
            % point. We need to handle collisions until we get to a lower with no
            % unhanded collisions in between, hence the while loop
            isCoupledCollision = true;
                        idxl_eventIndex = eventu.localIdx;
            idxl = eventIndices(idxl_eventIndex);
            pdl = pds(idxl);
            pointl = points(pdl.vertexId, :);
            while isCoupledCollision
                % we have an upper and lower here
                idxl_eventIndex = eventu.localIdx+1;
                numBetween = 0;
                idxl = eventIndices(idxl_eventIndex);
                firstUnprocessedIdx = -idxl;
                firstUnprocessedEventIdx = -idxl_eventIndex;
                intersectPoints = [];
                while pds(idxl).dir ~= nav.decomp.internal.Side.Lower
                    % Only care about the number of non-processed points in
                    % between
                    if ~pds(idxl).bypassCoincidenceCheck
                        numBetween = numBetween + 1;
                        % track the actual points we see
                        intersectPoints = [intersectPoints; points(pds(idxl).vertexId, :)]; %#ok<AGROW>
                        % need to know the location of the point for making
                        % the new event
                        if firstUnprocessedIdx < 0
                            firstUnprocessedIdx = idxl;
                            firstUnprocessedEventIdx = idxl_eventIndex;
                        end
                    end
                    idxl_eventIndex = idxl_eventIndex+1;
                    idxl = eventIndices(idxl_eventIndex);
                end
                firstUnprocessedIdx = abs(firstUnprocessedIdx);
                firstUnprocessedEventIdx = abs(firstUnprocessedEventIdx);
        
                % we found the accompanying lower
                pdl = pds(idxl);
                pointl = points(pdl.vertexId, :);
        
                % check for line intersections between coupled points!
                % (below, for the case where we see the lower, but between are all intersect
                % points with the lower only, which is handled later)
                allBetweenAtLower = ~isempty(intersectPoints) && all(reshape(pointl == intersectPoints,[],1));
                if allBetweenAtLower % want the start index for the lower search to be where 
                                     % the collisions start
                    idxl_eventIndex = firstUnprocessedEventIdx;
                end
                isCoupledCollision = numBetween > 0 && ~allBetweenAtLower;
                if isCoupledCollision
                    % if we had to look too far there is someone in the way!
        
                    % create event for vertical edge to force collision
                    % checking
                    vertEventIdx = numel(pds)+1;
                    intersectPointIdx = pds(firstUnprocessedIdx).vertexId;
                    vertEvent = nav.decomp.internal.makePointData(vertEventIdx, nav.decomp.internal.EventType.VertEdge, ...
                                    intersectPointIdx, eventu.idx, idxl);

                    if pds(firstUnprocessedIdx).type == nav.decomp.internal.EventType.VertEdge
                        % If the current event is already a vertical edge,
                        % simply update it with the correct upper/lower
                        % indices
                        pds(firstUnprocessedIdx) = vertEvent;
                    else
                        % Otherwise we need to generate a new vertical edge
                        % and insert into the queue for subsequent
                        % processing
                        pds = [pds; vertEvent]; %#ok<AGROW>
                        eventIndices = [eventIndices(1:firstUnprocessedEventIdx) ...
                                    vertEventIdx ...
                                    eventIndices(firstUnprocessedEventIdx+1:end)];
                    end
        
                    % process the collision
                    intersectPoint = points(intersectPointIdx, :);
                    [isCollision, endEventIdx] = nav.decomp.internal.checkUnhandledCollision(intersectPoint, firstUnprocessedEventIdx, eventIndices, points, pds);
                    assert(isCollision);
                    [newEventIdxs, pds, newLowerIdx, openCells] = nav.decomp.internal.reclassifyCoincident(eventIndices(firstUnprocessedEventIdx:endEventIdx), pds, points, openCells);
                    eventIndices(firstUnprocessedEventIdx:endEventIdx) = newEventIdxs;
        
                    % see if a new lower for this upper has been created
                    if ~isempty(newLowerIdx)
                        newLower = pds(newLowerIdx);
                        idxl_eventIndex = firstUnprocessedEventIdx;
                        idxl = newLower.id;
                        pointl = points(pds(idxl).vertexId, :);
                        isCoupledCollision = false; % since we just created the new lower, we can leave
                    end
                end
            end
        
            % Check if there are any intersections at the LOWER point
            [isCollision, endEventIdx] = nav.decomp.internal.checkUnhandledCollision(pointl, idxl_eventIndex+1, eventIndices, points, pds);
            if isCollision
                % Check if there are open edges 'too-close' to the intersect point
                eventl = eventData(idxl, pds(idxl), pointl, idxl_eventIndex);
                [eventIndices, endEventIdx, pds, ~,openCells] = checkEdgeAtCollision(eventl, ...
                    points, pds, eventIndices, openCells, holeStatus, forgivingTol, endEventIdx);
                [newEventIdxs, pds, newLowerIdx, openCells] = nav.decomp.internal.reclassifyCoincident(eventIndices(idxl_eventIndex:endEventIdx), ...
                                                    pds, points, openCells);
                assert(~isempty(newLowerIdx));
                newLower = pds(newLowerIdx);
                eventIndices(idxl_eventIndex:endEventIdx) = newEventIdxs;
        
                % see if a new lower for this upper has been created
                idxl = newLower.id;
                pointl = points(pds(idxl).vertexId, :);
            end
        
            % Put the data about the lower point together to return
            eventl = eventData(idxl, pds(idxl), pointl, idxl_eventIndex);
        end
    end

    % Update the context with any modified cells/events
    info.AllCells(iOpen) = openCells;
    info.EventTypes = pds;

    % Store these if the collinearity check finds numerical issues
    if ~isempty(cellPairsToCheck)
        info.CellPairsToDoubleCheckIfConnected = [info.CellPairsToDoubleCheckIfConnected; cellPairsToCheck];
    end
end

function [eventIndices, endEventIdx, pds, cellPairsToCheck, openCells] = checkEdgeAtCollision(eventu, points, pds, eventIndices, openCells, holeStatus, forgivingTol, endEventIdx)
%checkEdgeAtCollision - Identify and handle an edge intersecting coincident events
    refX = eventu.point(1);
    refY = eventu.point(2);
    cellPairsToCheck = [];
    if coder.internal.isConstTrue(~isempty(openCells))
        % See which cells are close to the coincidence
        iFloorClose = arrayfun(@(pCell) abs(nav.decomp.internal.PolyCell.floorLimit(pCell,refX, points, pds, holeStatus) - refY) < forgivingTol, openCells);
        iCeilClose = arrayfun(@(pCell) abs(nav.decomp.internal.PolyCell.ceilLimit(pCell,refX, points, pds, holeStatus) - refY) < forgivingTol, openCells);
        iClose = find(iCeilClose & iFloorClose);
        iCeilThrough  = iClose(arrayfun(@(pCell) ~ismember(pCell.NextCeilEventIdx, eventIndices), openCells(iClose)));
        iFloorThrough = iClose(arrayfun(@(pCell) ~ismember(pCell.NextFloorEventIdx, eventIndices),openCells(iClose)));
        % See which of the cells is close BUT not AT the coincidence,
        % indicating that its edge is passing through the coincidence
        if ~isempty([iCeilThrough iFloorThrough]) % There is an edge probably touching the points!
            % Need to know new event idx for changing in closeCell
            newEventIdx = numel(pds)+1;
            % Check if floor or ceiling hit
            if ~isempty(iCeilThrough) % ceiling!
                iCell = iCeilThrough;
                eventType = nav.decomp.internal.EventType.Ceiling;
                nextCeil = openCells(iCell).NextCeilEventIdx;
                nextFloor = nan;
                windingAfter = nextCeil;
                windingBefore = nav.decomp.internal.PolyCell.prevCeil(openCells(iCell));
                openCells(iCell).NextCeilEventIdx = newEventIdx;
            else % floor!
                iCell = iFloorThrough;
                eventType = nav.decomp.internal.EventType.Floor;
                nextCeil = nan;
                nextFloor = openCells(iCell).NextFloorEventIdx;
                windingAfter = nav.decomp.internal.PolyCell.prevFloor(openCells(iCell));
                windingBefore = nextFloor;
                openCells(iCell).NextFloorEventIdx = newEventIdx;
            end
            % Make the new event representing this floor/ceil
            intersectPointIdx = eventu.pd.vertexId;
            newEvent = nav.decomp.internal.makePointData(newEventIdx, eventType, ...
                            intersectPointIdx, nextCeil, nextFloor, nav.decomp.internal.Side.None, false, windingBefore, windingAfter);
            pds = [pds; newEvent];
            eventIndices = [eventIndices(1:eventu.localIdx) ...
                newEventIdx ...
                eventIndices(eventu.localIdx+1:end)];
            endEventIdx = endEventIdx + 1;
            % Mark these cells for further adjacency checking
            openCellIds = arrayfun(@(x)x.id, openCells(:));
            openCellIds(openCellIds == openCells(iCell).id) = [];
            cellPairsToCheck = [openCells(iCell).id*ones(size(openCellIds)) openCellIds];
        end
    end
end

function event = eventData(idx, pd, point, localIdx)
%eventData - All of the data needed about an event during an algorithm pass
    event = struct('idx', idx, 'pd', pd, 'point', point, 'localIdx', localIdx);
end

function [indicesToRemove, points, pcells] = correctEmptyPolyCells(pcells, points)
%correctEmptyPolyCells - Removes cells that polyshape considers empty
%   [indicesToRemove, points] = correctEmptyPolyCells(pcells, points)
%   Checks if polyshape thinks any PolyCells are
%   'too small' such that it reduces to an empty polyshape. If so, the
%   PolyCell should be marked for deletion, neighbors should be
%   connected, and the left bound of the right neighbor should be shifted
%   left to account for the deleted cell
%   Return the indices of the empty cells and the updated list of points.

    indicesToRemove = [];
    for cellIdx = 1:numel(pcells)
        emptyCell = pcells(cellIdx);
        emptyPoly = nav.decomp.internal.PolyCell.asPoly(emptyCell,points);
        if emptyPoly.NumRegions == 0 % does not exist!
            % mark for removal
            indicesToRemove = [indicesToRemove cellIdx]; %#ok<AGROW>

            % remove this cell from neighbors' adjacency lists
            for i = 1:numel(emptyCell.LeftNeighbors)
                leftNeighborId = emptyCell.LeftNeighbors(i);
                pcells(leftNeighborId) = nav.decomp.internal.PolyCell.removeRightNeighbor(pcells(leftNeighborId),cellIdx);
            end
            for i = 1:numel(emptyCell.RightNeighbors)
                rightNeighborId = emptyCell.RightNeighbors(i);
                pcells(rightNeighborId) = nav.decomp.internal.PolyCell.removeLeftNeighbor(pcells(rightNeighborId),cellIdx);
            end

            % don't care about shifting if no neighbors on either side
            if isempty(emptyCell.LeftNeighbors) || isempty(emptyCell.RightNeighbors)
                continue;
            end

            lastCeil = points(emptyCell.CeilVtxIdxs(1), 1);
            lastFloor = points(emptyCell.FloorVtxIdxs(1), 1);
            newX = max([lastCeil, lastFloor]);
            % shift all right neighbors left
            for i = 1:numel(emptyCell.RightNeighbors)
                rightCell = pcells(emptyCell.RightNeighbors(i));
                points(rightCell.CeilVtxIdxs(1), 1) = newX;
                points(rightCell.FloorVtxIdxs(1), 1) = newX;
            end

            % once shifted, check union to see if neighbors
            for i = 1:numel(emptyCell.LeftNeighbors)
                leftNeighborId = emptyCell.LeftNeighbors(i);
                leftPoly = nav.decomp.internal.PolyCell.asPoly(pcells(leftNeighborId),points);
                for j = 1:numel(emptyCell.RightNeighbors)
                    rightNeighborId = emptyCell.RightNeighbors(j);
                    rightPoly = nav.decomp.internal.PolyCell.asPoly(pcells(rightNeighborId),points);
                    [areSeparate, connectAnyway] = nav.decomp.internal.checkSeparate(leftPoly, rightPoly);
                    if ~areSeparate || connectAnyway
                        pcells(leftNeighborId) = nav.decomp.internal.PolyCell.addRightNeighbor(pcells(leftNeighborId),rightNeighborId);
                        pcells(rightNeighborId) = nav.decomp.internal.PolyCell.addLeftNeighbor(pcells(rightNeighborId),leftNeighborId);
                    end
                end
            end
        end
    end
end

function eventType = getEffectiveEventType(eventu, eventl)
%getEffectiveEventType - The event represented by the upper/lower events
%   eventType = getEffectiveEventType(EVENTU, EVENTL) is the type of event
%   that the two events are treated as. If the events are the same type,
%   then the effective event type is that type. It is possible for two
%   coupled events of different types to be treated as a different type.
%   For example, an UPPER IN and LOWER PINCH would be treated as a FLOOR.
    pdu = eventu.pd;
    pdl = eventl.pd;

    if pdu.type == pdl.type
        eventType = pdu.type;
    elseif ((pdu.type == nav.decomp.internal.EventType.Out && pdl.type == nav.decomp.internal.EventType.Split) || ... % coupled floor 1
            (pdu.type == nav.decomp.internal.EventType.In && pdl.type == nav.decomp.internal.EventType.Pinch))        % coupled floor 2
        
        eventType = nav.decomp.internal.EventType.Floor;
    
    elseif ((pdu.type == nav.decomp.internal.EventType.Split && pdl.type == nav.decomp.internal.EventType.Out) || ... % coupled ceiling 1
            (pdu.type == nav.decomp.internal.EventType.Pinch && pdl.type == nav.decomp.internal.EventType.In))        % coupled ceiling 2
    
        eventType = nav.decomp.internal.EventType.Ceiling;
    else
        eventType = nav.decomp.internal.EventType.Split; %#ok<NASGU>
        error('This should not happen');
    end
end

function info = remapUnusedVertices(info)
    % Identify extra/unused vertices
    i0 = nan(0,1);
    for i = 1:numel(info.AllCells)
        i0 = [i0; info.AllCells(i).CeilVtxIdxs(:); info.AllCells(i).FloorVtxIdxs(:)]; %#ok<AGROW>
    end
    mUnused = ~ismember((1:size(info.Points,1))',unique(i0,"stable"));

    % Remap indices
    iOld = (1:numel(mUnused))';
    iNew = iOld-cumsum(mUnused);
    
    for i = 1:numel(info.AllCells)
        info.AllCells(i).CeilVtxIdxs = iNew(info.AllCells(i).CeilVtxIdxs);
        info.AllCells(i).FloorVtxIdxs = iNew(info.AllCells(i).FloorVtxIdxs);
    end

    info.Points(mUnused,:) = [];
    info.HoleStatus(mUnused) = [];
end
