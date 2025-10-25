function [globalIdx, bdryIdx, localIdx] = nearestVertex(pg, V)
%MATLAB Code Generation Private Function

% called by nearestvertex method of polyshape. 

%   Copyright 2023 The MathWorks, Inc.
%#codegen

    npts = size(V,1);
    globalIdx = coder.nullcopy(zeros(npts, 1));
    bdryIdx = coder.nullcopy(zeros(npts, 1));
    localIdx = coder.nullcopy(zeros(npts, 1));
    for i = 1:npts
        [bIdx, locIdx, idx] = findNearestVertex(pg, V(i,1), V(i,2));
        % Should never occur adding as safeguard
        assert(~(bIdx==0 || locIdx==0 || idx==0))
        globalIdx(i) = idx;
        bdryIdx(i) = bIdx;
        localIdx(i) = locIdx;
    end
end

function [bIdx, locIdx, nearestIdx] = findNearestVertex(pgon, x, y)
    nb = pgon.numBoundaries;
    nearestIdx = 0;
    bIdx = 0;
    locIdx = 0;
    globalIdx = 1; % Idx in vertices array returned by polyshapeObj.Vertices call
    nearestDist = Inf;
    for i = 1:nb
        bndSz = pgon.boundaries.getBoundarySize(i);
        bndSz = bndSz - 1; % boundary is closed loop, first point is repeated at the end
        for j = 1:bndSz
            [xb, yb] = pgon.boundaries.getCoordAtIdx(i, j);
            dx = x - xb;
            dy = y - yb;
            d = dx * dx + dy * dy;
            if (d <= nearestDist) 
                % tie breaker: larger index
                nearestDist = d;
                nearestIdx = globalIdx;
                bIdx = i;
                locIdx = j;
            end
            globalIdx = globalIdx + 1;
        end
        % increment as boundary is seperated by nan in vertex array
        globalIdx = globalIdx + 1;
    end
end