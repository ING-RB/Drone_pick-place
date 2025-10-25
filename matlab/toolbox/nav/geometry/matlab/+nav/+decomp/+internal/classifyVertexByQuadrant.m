function E = classifyVertexByQuadrant(aQ, bR, hD)
%classifyVertexByQuadrant - Classify the vertex event based on quadrant information
%
%   E = classifyVertexByQuadrant(aQuad, bRelative, holeDirection) classifies the
%   point represented by the quadrant of its A vector aQ, the direction 
%   of its B vector relative to its A vector bR, and the global hole
%   direction hD, represented as the direction (above or below) that the hole
%   area is relative to the A vector

%   Copyright 2024 The MathWorks, Inc.
%#codegen

    % Longest name for most data
    M = nav.decomp.internal.EventClassificationMatrices.AllClassificationMatrix552;
    % Get classifications based on aQuad, bRelative, and holeDirection
    E = M(sub2ind(size(M), aQ, bR, hD));
end