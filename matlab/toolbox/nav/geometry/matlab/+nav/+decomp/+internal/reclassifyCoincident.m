function [newEventIdxs, newPds, newLowerIdx, openCells] = reclassifyCoincident(eventIdxs, pds, points, openCells)
%This function is for internal use only. It may be removed in the future.

%reclassifyCoincident - Reclassify coincident events to correct classifications
%   [newEventIdxs, newPds, newLowerIdx, openCells] = reclassifyCoincident(eventIdxs, pds, points, openCells)
%   reclassifies the event types of coincident events with indexes
%   eventIdxs. Returns the indices of the newly created events as
%   newEventIdxs, the new PointData structs as newPds, and if a new LOWER
%   event index is returned as newLowerIdx.
%   Also updates the event indices in the given openCells.

%   Copyright 2024 The MathWorks, Inc.

%#codegen

    nEvts = numel(eventIdxs);
    As = zeros(nEvts, 2);
    Bs = zeros(nEvts, 2);
    newPds = pds;
    Atails = zeros(1, nEvts);
    Bheads = zeros(1, nEvts);
    newLowerIdx = [];

    % need to make sure we return the events in correct order for
    % processing
    beginningEventIdxs = [];
    middleEventIdxs = [];
    endingEventIdxs = [];

    % Find vertex edge events
    m = [pds(eventIdxs).type] == nav.decomp.internal.EventType.VertEdge; 

    % Process events
    [As(m,:),Bs(m,:), Atails(m), Bheads(m)] = nav.decomp.internal.getVertEdgeDefiningVectors(pds(eventIdxs(m)),points,pds);
    [As(~m,:),Bs(~m,:), Atails(~m), Bheads(~m)] = nav.decomp.internal.getDefiningVectors(eventIdxs(~m),points,pds);
    
    changelog = repmat(makeChange(true, nan, nan),numel(eventIdxs)*2,1);

    % Re-pair the vectors to make new events
    for ai = numel(eventIdxs):-1:1
        aEventIdx = eventIdxs(ai);
        a = As(ai, :);
        [b, bi] = nav.decomp.internal.getClosest(a, Bs);
        bEventIdx = eventIdxs(bi);

        [eventType, holeDirection] = nav.decomp.internal.classifyAB(a,b);

        % figure out how to assign the next floor/ceil values
        % recall, events are processed in left/right order
        if eventType == nav.decomp.internal.EventType.Out || eventType == nav.decomp.internal.EventType.Pinch
            nextCeilIdx = nan;
            nextFloorIdx = nan;
        elseif eventType == nav.decomp.internal.EventType.Split
            nextCeilIdx = Bheads(bi);
            nextFloorIdx = Atails(ai);
        elseif eventType == nav.decomp.internal.EventType.In
            nextFloorIdx = Atails(ai);
            nextCeilIdx = Bheads(bi);
        elseif eventType == nav.decomp.internal.EventType.Floor
            nextCeilIdx = nan;
            nextFloorIdx = Atails(ai);
        else % Ceiling
            nextCeilIdx = Bheads(bi);
            nextFloorIdx = nan;
        end  

        pointIdx = pds(aEventIdx).vertexId;
        newEventIdx = numel(newPds)+1;

        % assure that the new events are ordered correctly
        if holeDirection == nav.decomp.internal.Side.Lower
            % LOWERS must be handled first
            beginningEventIdxs = [newEventIdx beginningEventIdxs]; %#ok<AGROW>
            newLowerIdx = newEventIdx;
        elseif holeDirection == nav.decomp.internal.Side.Upper
            % UPPERS must be handled last
            endingEventIdxs = [endingEventIdxs newEventIdx]; %#ok<AGROW>
        elseif eventType == nav.decomp.internal.EventType.In || eventType == nav.decomp.internal.EventType.Floor
            % INs and FLOORS should be handled first
            beginningEventIdxs = [beginningEventIdxs newEventIdx]; %#ok<AGROW>
        elseif eventType == nav.decomp.internal.EventType.Pinch || eventType == nav.decomp.internal.EventType.Split
            % PINCHES and SPLITS are handled in the middle in any order
            middleEventIdxs = [middleEventIdxs newEventIdx]; %#ok<AGROW>
        else
            % OUTs and CEILINGs are handles last
            endingEventIdxs = [endingEventIdxs newEventIdx]; %#ok<AGROW>
        end

        newEvent = nav.decomp.internal.makePointData(newEventIdx, eventType, pointIdx, ...
            nextCeilIdx, nextFloorIdx, holeDirection, true);
        newPds = [newPds; newEvent]; %#ok<AGROW>

        % Store changes to be made after all changes are found
        changeA = makeChange(true, aEventIdx, newEventIdx);
        changeB = makeChange(false, bEventIdx, newEventIdx);
        changelog(2*ai - 1) = changeA;
        changelog(2*ai) = changeB;
    end

    % Apply changes to already existing cells, updating ids to be correct
    % NOTE this could, in theory, be a rather expensive loop
    for celli = 1:numel(openCells)
        for changei = 1:numel(changelog)
            change = changelog(changei);

            if openCells(celli).NextCeilEventIdx == change.prevDestEvtIdx && change.inward
                openCells(celli).NextCeilEventIdx = change.newDestEvtIdx;
            elseif openCells(celli).NextFloorEventIdx == change.prevDestEvtIdx && ~change.inward
                openCells(celli).NextFloorEventIdx = change.newDestEvtIdx;
            end

        end
    end
    
    % beginningEventIdxs and endingEventIdxs should only ever have, at
    % most, 1 event in each
    newEventIdxs = [beginningEventIdxs middleEventIdxs endingEventIdxs];
end


function change = makeChange(inward, prevDestEvtIdx, newDestEvtIdx)
%makeChange - Get the information for a change in a struct
    change = struct("inward", inward, ...
        "prevDestEvtIdx", prevDestEvtIdx, ...
        "newDestEvtIdx", newDestEvtIdx);
end
