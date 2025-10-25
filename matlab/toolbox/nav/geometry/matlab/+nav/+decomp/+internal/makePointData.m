function pd = makePointData(id, type, vertexId, nextCeilId, nextFloorId, dirFlag, bypassCoincidenceCheck, before, after)
%This function is for internal use only. It may be removed in the future.

%makePointData - Create the struct defining and event at a vertex
%
%   PD = makePointData(ID, TYPE, vertexId, nextCeilId, nextFloorId, dirFlag,
%   bypassCoincidenceCheck) creates a struct defining and event with id ID of
%   type TYPE at vertex vertexId. The event ids of the next ceiling and floor
%   events are stored as nextCeilId and nextFloorId, respectively. If this
%   event is coupled, its direction (Upper or Lower) is saved as dirFlag. The 
%   bypassCoincidenceCheck is used to let the sweep-line algorithm know that
%   this event has been created while dealing with conflicting events and
%   that it can accordingly skip its check for conflicts when looking at this
%   event

%   Copyright 2024 The MathWorks, Inc.

%#codegen
    arguments (Input)
        id (1,1) {mustBeInteger} = 0
        type (1,1) nav.decomp.internal.EventType = 0
        vertexId (1,1) {mustBeInteger} = 0;
        nextCeilId (1,1) = nan
        nextFloorId (1,1) = nan;
        dirFlag (1,1) nav.decomp.internal.Side = nav.decomp.internal.Side.None;
        bypassCoincidenceCheck logical = false;
        before (1,1) = nan;
        after (1,1) = nan;
    end
    arguments (Output)
        pd (1,1) struct
    end
    pd = struct('id', id, 'type', type, 'vertexId', vertexId, ...
        'nextCeilId', nextCeilId, 'nextFloorId', nextFloorId, 'dir', dirFlag, ...
        'bypassCoincidenceCheck', bypassCoincidenceCheck, 'windingBefore', before, 'windingAfter', after);
end
