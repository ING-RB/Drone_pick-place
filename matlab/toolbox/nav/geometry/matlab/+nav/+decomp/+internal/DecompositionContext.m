classdef DecompositionContext < handle
%This class is for internal use only. It may be removed in the future.

%DecompositionContext - Stores data structures for decomposition as handle

%#codegen
%   Copyright 2024 The MathWorks, Inc.

    properties
        %AllCells - All cells created during the decomposition
        AllCells (:,1) struct; %nav.decomp.internal.PolyCell;

        %Points - All points in input polyshape, ordered by vertexId
        Points (:,2) double;

        %HoleStatus - Indicates if the corresponding point is a hole
        HoleStatus (:,1) double;

        %AboveOpenCellIdx - Index of cell that has been opened by previous collinear event
        %   The AboveOpenCellIdx is used for handling cases where many events
        %   fall on the same crit-line. Allows events lower on the
        %   crit-line to access and modify the newly-created cells rather
        %   than generating new ones that would overlap and be redundant
        AboveOpenCellIdx (1,1);

        %Order - The order of events sorted left-right by x and top-down by y
        Order (:,1) double;

        %OrderedPoints - All points sorted left-right by x and top-down by y
        OrderedPoints (:,2) double;

        %EventTypes - The event and vertical flag information for each point
        EventTypes (:,1) struct;

        %OpenCellIndices - Mask over AllCells indicating which are currently open
        OpenCellIndices (:,1) double;

        %Visualize - Plot the closed cells as the algorithm progresses
        Visualize (1,1) logical;

        %X - The current x-value of the sweepline
        X (1,1) double = -Inf;

        %EventU - The upper event of a coupled event; the single event otherwise
        EventU (1,1) struct;

        %EventL - The lower event of a coupled event; same as EventU otherwise
        EventL (1,1) struct;

        %EventIndices - The indices of events on the current crit-line
        EventIndices (1,:) {mustBeInteger};

        %ForgivingTol - Tolerance to check for potential numerical mismatch
        %   We wish to maintain consistency in our cells with `polyshape`.
        %   Due to the complexity of how polyshape determines to
        %   split/merge shapes with points close to touching, the only way
        %   to do this consistently is to check what polyshape will do with
        %   two shapes. However, performing this check frequently would be
        %   costly, performance-wise. To save on computation we only check
        %   with polyshape when two shapes are 'too-close-for-comfort',
        %   defined as being within the giving ForgivingTol tolerance. This
        %   tolerance must be set high enough to assure it is larger than
        %   any reasonable tolerance polyshape may use, but small enough as
        %   to not incur excess computation. Around 1e-8 is suggested.
        ForgivingTol (1,1) double;

        %EventsInDegenerateRegions - Events that occur at close crit-lines
        %   Events that occur at crit-lines that are within a ForgivingTol
        %   distance from each other may need to be merged according to
        %   polyshape. The cell id, upper y bound, and lower y bound of
        %   these events are stored in this matrix for post-processing.
        EventsInDegenerateRegions (:,3) double;

        %StoreDegenerate - Flag to indicate that event info should be saved
        %  to EventsInDegenerateRegions. This flag is true when crit-lines
        %  appear 'too-close-for-comfort', so we want to check the events
        %  that occur at these crit-lines
        StoreDegenerate (1,1) logical;

        %CellPairsToDoubleCheckIfConnected - Flagged cells for post-processing
        %   These cells are flagged as too-close-for-comfort by the
        %   post-processing step operating on EventsInDegenerateRegions,
        %   which checks if these events are close on both the x and y
        %   axes. If so, the cell ids are stored for checking at the end if
        %   they should be connected or not.
        CellPairsToDoubleCheckIfConnected (:,2) = [];
    end

    methods
        function obj = DecompositionContext(poly, forgivingTol, visualize)
        %DecompositionContext - Construct an initial context handle for a given polyshape
        arguments
            poly (1,1) polyshape;
            forgivingTol (1,1) double;
            visualize (1,1) logical;
        end
            % Initialize data structures
            [obj.Points, obj.EventTypes, obj.Order, obj.HoleStatus, obj.OrderedPoints] = ...
                nav.decomp.internal.DecompositionContext.coreDataFromPolyshape(poly);
            pCell = repmat(nav.decomp.internal.PolyCell.makeCell,0,1);
            coder.varsize('pCell',[inf 1]);
            cIdx = zeros(0,1);
            coder.varsize('cIdx',[inf 1]);
            degenEvents = zeros(0,3);
            degenCellPairs = zeros(0,2);
            coder.varsize('degenEvents',[inf 3]);
            coder.varsize('degenCellPairs',[inf 2]);
            obj.AllCells = pCell;
            obj.AboveOpenCellIdx = nan;
            obj.OpenCellIndices = cIdx;
            obj.ForgivingTol = forgivingTol;
            obj.Visualize = visualize;
            obj.EventsInDegenerateRegions = degenEvents;
            obj.CellPairsToDoubleCheckIfConnected = degenCellPairs;
        end

        function [oCells,iOpen] = openCells(obj)
            iOpen = obj.OpenCellIndices;
            oCells = obj.AllCells(iOpen);
        end

        function newIdx = openCell(obj, pCell)
        %openCell - Add the cell to the cell array and update indices accordingly
            % add to the cell array
            newIdx = numel(obj.AllCells)+1;
            pCell.id = newIdx;
            obj.AllCells = [obj.AllCells(:);pCell];
            % add index to open cells
            obj.OpenCellIndices = [obj.OpenCellIndices(:);newIdx];
        end

        function markClosed(obj, cellIdx)
        %markClosed - Mark a cell as closed and visualize, if enabled
            obj.OpenCellIndices(obj.OpenCellIndices == cellIdx) = [];
            if coder.internal.isConstTrue(obj.Visualize) && nav.decomp.internal.PolyCell.asPoly(obj.AllCells(cellIdx),obj.Points).NumRegions > 0
                plot(nav.decomp.internal.PolyCell.asPoly(obj.AllCells(cellIdx),obj.Points) ,'FaceColor','green');
            end
        end

        function index = addPoint(obj, point, isHole)
        %addPoint - Add a new point to the point array and update indices
            obj.Points = [obj.Points; point];
            obj.HoleStatus = [obj.HoleStatus; isHole];
            index = size(obj.Points, 1);
        end

        function storePotentialDegenerateEvent(obj, id, yupper, ylower)
        %storePotentialDegenerateEvent - Store a cell id and the upper and lower bounds of the event 
            obj.EventsInDegenerateRegions = [obj.EventsInDegenerateRegions; id yupper ylower];
        end
    
        function setAboveOpenCellIdx(obj, newCellIdx)
        %setAboveOpenCellIdx - Sets AboveOpenCellIdx to given value; clears if no argument given
            arguments
                obj
                newCellIdx (1,1) = nan
            end
            obj.AboveOpenCellIdx = newCellIdx;
        end

        function removePolyCells(obj, indicesToRemove)
        %removePolyCells - Remove the marked polycells from the list and update indices
            
            if ~isempty(indicesToRemove)
                % Compute cumulative number of cells removed. This is used to
                % offset any right-hand neighbors.
                iRem = zeros(1,numel(obj.AllCells));
                iRem(indicesToRemove) = 1;
                numRemoved = cumsum(iRem);

                % Remove empty cells from list
                obj.AllCells(indicesToRemove) = [];

                % Re-index cells
                for i = 1:numel(obj.AllCells)
                    oldId = obj.AllCells(i).id;
                    if oldId == i
                        continue;
                    end
                    
                    % Change id in struct
                    obj.AllCells(i).id = i;
                    % go to connections and update there,  too
                    for j = 1:numel(obj.AllCells(i).LeftNeighbors)
                        neighborId = obj.AllCells(i).LeftNeighbors(j);
                        % Any cell neighboring the current cell should have
                        % it's right-side neighbor updated to match new idx
                        obj.AllCells(neighborId) = nav.decomp.internal.PolyCell.removeRightNeighbor(obj.AllCells(neighborId),oldId);
                        obj.AllCells(neighborId) = nav.decomp.internal.PolyCell.addRightNeighbor(obj.AllCells(neighborId),i);
                    end
                    for j = 1:numel(obj.AllCells(i).RightNeighbors)
                        neighborId = obj.AllCells(i).RightNeighbors(j);
                        % Any cells right-neighboring current cell must 
                        % remap their left-nbr for the current idx. Since
                        % these cells have been shifted due to remove of 
                        % prior cells we must compute their new index
                        % in the vector.
                        newNbrIdx = neighborId-numRemoved(neighborId);
                        obj.AllCells(newNbrIdx) = nav.decomp.internal.PolyCell.removeLeftNeighbor(obj.AllCells(newNbrIdx),oldId);
                        obj.AllCells(newNbrIdx) = nav.decomp.internal.PolyCell.addLeftNeighbor(obj.AllCells(newNbrIdx),i);
                    end
                end
            end
        end

        function degenerateRegionCleanup(obj)
        %degenerateRegionCleanup - Perform post-processing on too-close-for-comfort events
            % check if any events occur too close together
            if ~isempty(obj.EventsInDegenerateRegions)
                newCellPairs = nav.decomp.internal.DecompositionContext.checkNumericallyUnstableCellPairs(...
                    obj.EventsInDegenerateRegions, obj.ForgivingTol);
                obj.CellPairsToDoubleCheckIfConnected = [obj.CellPairsToDoubleCheckIfConnected; newCellPairs];
            end
            obj.EventsInDegenerateRegions = [];
        end

        function doubleCheckConnections(obj)
        %doubleCheckConnections - Update cell neighbors to match polyshape UNION
            if isempty(obj.CellPairsToDoubleCheckIfConnected)
                return;
            end
            % Check all pairs in our list
            numToCheck = numel(obj.CellPairsToDoubleCheckIfConnected(:, 1));
            for doubleCheckIndex = 1:numToCheck
                idxLeft = obj.CellPairsToDoubleCheckIfConnected(doubleCheckIndex, 1);
                idxRight = obj.CellPairsToDoubleCheckIfConnected(doubleCheckIndex, 2);
                polyLeft = nav.decomp.internal.PolyCell.asPoly(obj.AllCells(idxLeft),obj.Points);
                polyRight = nav.decomp.internal.PolyCell.asPoly(obj.AllCells(idxRight),obj.Points);
        
                areSeparate = nav.decomp.internal.checkSeparate(polyLeft, polyRight);
        
                if ~areSeparate
                    % by the gods, this case actually occurred
                    obj.AllCells(idxLeft) = nav.decomp.internal.PolyCell.addRightNeighbor(obj.AllCells(idxLeft),idxRight);
                    obj.AllCells(idxRight) = nav.decomp.internal.PolyCell.addLeftNeighbor(obj.AllCells(idxRight),idxLeft);
                end
            end
        end
    end
    methods (Static)
        function [points, pds, order, holeStatus, sortedEvtVtx] = coreDataFromPolyshape(m)
        %coreDataFromPolyshape - Get polyshape data in form usable by algorithm
        %   [POINTS, PDS, ORDER, holeStatus] = coreDataFromPolyshape(M) gets the
        %   points in the polyshape M as POINTS, the events types of each point as
        %   PDS, the left-right top-down order of the events as ORDER (with nulls 
        %   and duplicates removed), and the hole status of each vertex as
        %   holeStatus
        
            % Get classifications for events
            pds = nav.decomp.internal.classifyPolyshape(m);
        
            % Get the points themselves
            [x, y] = boundary(m);
            points = [x y];
            % Associate each point with its hole flag
            holeStatus = nav.decomp.internal.holeMapping(m);
        
            % Get the left-right/top-down order of the non-null points
            % for performing the sweep
            [sortedEvtVtx, order] = sortrows(points, [1 2], {'ascend', 'descend'});
        
            % clear out null and duplicate terms from order
            n = size(points,1);
            allIndices = 1:n;
            nullIndices = allIndices(isnan(points(:, 1)));
            duplicateIndices = nullIndices-1; % dups precede nulls
            lastDupIndex = size(points,1); % last is also a dup
            removalIndices = [nullIndices duplicateIndices lastDupIndex];
            % Actually perform the removal
            removalMask = any(order == removalIndices, 2);
            order(removalMask) = [];
            sortedEvtVtx(removalMask, :) = [];
        
            % Add trailing null to points and holeStatus to separate originals from
            % the points added during algorithm execution
            points = [points; nan(1,2)];
            holeStatus = [holeStatus(:); nan];
        end
        
        function pairs = checkNumericallyUnstableCellPairs(eventsInDegenerateRegions, forgivingTol)
        %checkNumericallyUnstableCellPairs - Check for cells polyshape may consider together
        %   Given the cell id and event upper and lower bounds of events that occur
        %   in a degenerate region (area where sweeplines are very close together), 
        %   return the cell pairs close enough to warrant further connectivity 
        %   checks later
            pairs = [];
            numToCheckCloseEnough = size(eventsInDegenerateRegions, 1);
            for idx1 = 1:numToCheckCloseEnough
                cellIdx1 = eventsInDegenerateRegions(idx1, 1);
                yUpper1 = eventsInDegenerateRegions(idx1, 2);
                yLower1 = eventsInDegenerateRegions(idx1, 3);
                for idx2 = 1:numToCheckCloseEnough
                    if idx2 == idx1
                        continue;
                    end
                    cellIdx2 = eventsInDegenerateRegions(idx2, 1);
                    yUpper2 = eventsInDegenerateRegions(idx2, 2);
                    yLower2 = eventsInDegenerateRegions(idx2, 3);
        
                    % if cells bounds are close enough to
                    % overlapping, mark indices to be checked for
                    % connection at the end by polyshape `union`
                    if (abs(yUpper1 - yUpper2) < forgivingTol || ...
                        abs(yLower1 - yLower2) < forgivingTol || ...
                        (yLower2 > yLower1 && yLower2 < yUpper1) || ...
                        (yLower1 > yLower2 && yLower1 < yUpper2) || ...
                        abs(yUpper1 - yLower2) < forgivingTol || ...
                        abs(yUpper2 - yLower1) < forgivingTol)
                        pairs = [pairs; cellIdx2 cellIdx1]; %#ok<AGROW>
                    end
                end
            end
        end
    end
end