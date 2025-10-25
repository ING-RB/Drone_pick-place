function [E, dirFlags, aQ, bR, hD] = classifyAB(A, B)
%This function is for internal use only. It may be removed in the future.

%classifyAB - Classify the type of event present at a vertex
% 
%   [E, dirFlags, aQ, bR, hD] = classifyAB(A, B) produces the event type E and
%   corresponding direction flag dirFlags for the vertex represented by vectors
%   A and B. A is the vector pointing into the point, while B points out. 
%   This represents the winding order defining the polygon this point is a 
%   part of.

%   Copyright 2024 The MathWorks, Inc.

%#codegen
    hD = nav.decomp.internal.getHoleDirection(A);
    aQ = nav.decomp.internal.getQuad(A);
    bR = nav.decomp.internal.relativeState(A, B, hD);

    % Get classifications
    E = nav.decomp.internal.classifyVertexByQuadrant(aQ, bR, hD);

    % Set dir flags
    dirFlags = zeros(size(E));
    dirFlags(aQ == 4 | bR == nav.decomp.internal.RelativeAlignment.North) = nav.decomp.internal.Side.Lower;
    dirFlags(aQ == 3 | bR == nav.decomp.internal.RelativeAlignment.South) = nav.decomp.internal.Side.Upper;
    dirFlags(E == nav.decomp.internal.EventType.VertEdge) = nav.decomp.internal.Side.None;
    dirFlags(dirFlags == 0) = nav.decomp.internal.Side.None;
end
