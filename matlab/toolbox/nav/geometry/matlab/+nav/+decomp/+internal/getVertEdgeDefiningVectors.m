function  [A,B, aTail, bHead] = getVertEdgeDefiningVectors(pd, points, pds)
%This function is for internal use only. It may be removed in the future.

%getVertEdgeDefiningVectors - Get defining vectors A and B for a VertEdge event
%   [a,b, aTail, aHead, bTail, bHead] = getVertEdgeDefiningVectors(event, points, pds)
%   returns the A and B vectors for VertEdge event, along with the vertex
%   ids of the heads and tails of these vectors.

%   Copyright 2024 The MathWorks, Inc.
%#codegen
    if isempty(pd)
        A = zeros(0,2);
        B = zeros(0,2);
        aTail = zeros(0,1);
        bHead = zeros(0,1);
        return;
    end
    % get the top and bottom points
    idxu = [pd.nextCeilId];
    idxl = [pd.nextFloorId];
    upperPoint = points([pds(idxu).vertexId], :);
    lowerPoint = points([pds(idxl).vertexId], :);

    % get intersection point
    idxi = [pd.vertexId];
    intersectPoint = points(idxi, :);

    A = zeros(size(upperPoint));
    B = zeros(size(upperPoint));
    aTail = zeros(size(idxu));
    bHead = zeros(size(idxu));

    % the direction of a,b can be determined by the event type of the upper
    % point
    m = [pds(idxu).type] == nav.decomp.internal.EventType.Out | [pds(idxu).type] == nav.decomp.internal.EventType.Split;
    B(m,:) = upperPoint(m,:) - intersectPoint(m,:);
    A(m,:) = intersectPoint(m,:) - lowerPoint(m,:);
    aTail(m) = idxl(m);
    bHead(m) = idxu(m);
    
    B(~m,:) = lowerPoint(~m,:) - intersectPoint(~m,:);
    A(~m,:) = intersectPoint(~m,:) - upperPoint(~m,:);
    aTail(~m) = idxu(~m);
    bHead(~m) = idxl(~m);
end
