function [a,b, aTailIdx, bHeadIdx] = getDefiningVectors(eventIdxs, points, pds)
%getDefiningVectors - Get the defining (INWARD/OUTWARD) vectors of point at idx
%   Each vertex of a polygon can be defined by the vector of the side going
%   in to the point (INWARD vector A) and the vector of the side going out
%   of the point (OUTWARD vector B), with the direction of the vectors
%   determined by the winding order of the polygon
%
%   [A, B, aTailIdx, bHeadIdx] = getDefiningVectors(idx, points)
%   returns the A and B vectors for the point at idx, along with the vertex
%   ids of the heads and tails of these vectors

%   Copyright 2024 The MathWorks, Inc.
%#codegen
    vtxIdx = [pds(eventIdxs).vertexId];
    aHeadIdx = vtxIdx;
    bTailIdx = vtxIdx;

    aTailIdx = [pds(eventIdxs).windingBefore];
    bHeadIdx = [pds(eventIdxs).windingAfter];

    a = points(aHeadIdx, :) - points(aTailIdx, :);
    b = points(bHeadIdx, :) - points(bTailIdx, :);
end
