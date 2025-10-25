function eventTypes = classifyPolyshape(m)
%This function is for internal use only. It may be removed in the future.

%classifyPolyshape Classify each vertex of the given polyshape
%
%   eventTypes = classifyPolyshape(M) classifies each vertex of polyshape M as
%   one of the six events defined in PointData: IN, OUT, FLOOR, CEILING, 
%   PINCH or SPLIT.
%   Assumes boundaries have a CW winding order, while that of holes is CCW.

%   Copyright 2024 The MathWorks, Inc.

%#codegen
    arguments (Input)
        m polyshape
    end
    arguments (Output)
        eventTypes (:, 1) struct
    end
    % Get the sub-polygons the polygons
    bounds = nav.decomp.internal.getSeparateBoundaries(m);

    % area to store class data
    nEvts = numel(m.boundary);
    eventTypes = repmat(nav.decomp.internal.makePointData,nEvts,1);

    % go through each poly and classify points
    shift = 0;
    for i = 1:numel(bounds)
        P = bounds{i};
        xp = P(:, 1);
        yp = P(:, 2);
        % Run the classifier
        pds = nav.decomp.internal.classifyPoints(xp, yp);
        % Adjust indices to align with global indices
        pds = shiftIndices(pds, shift);
        % Add to global array
        eventTypes(shift+1:shift+numel(pds)) = pds;
        % update the global value to shift by
        shift = shift+numel(pds)+1;
    end
end


function shifted = shiftIndices(pds, shift)
% shiftIndices   Shift all of the indices of PointData by a given amount
%
%   SHIFTED = shiftIndices(PDS, SHIFT) shifts all of the indices in the
%   point data array PDS by the given SHIFT amount

    arguments (Input)
        pds (:,1) struct
        shift (1,1) double
    end
    arguments (Output)
        shifted (:,1) struct
    end

    % Iterate through PDS incrementing by SHIFT
    for i = 1:numel(pds)
        pd = pds(i);
        pd.id = pd.id + shift;
        pd.vertexId = pd.vertexId + shift;
        pd.nextCeilId = pd.nextCeilId + shift;
        pd.nextFloorId = pd.nextFloorId + shift;
        pd.windingBefore = pd.windingBefore + shift;
        pd.windingAfter = pd.windingAfter + shift;
        pds(i) = pd;
    end
    shifted = pds;
end
