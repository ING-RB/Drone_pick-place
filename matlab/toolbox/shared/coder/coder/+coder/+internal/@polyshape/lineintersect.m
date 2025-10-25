function [out1, out2] = lineintersect(subject, lineseg)
%MATLAB Code Generation Library Function
% extract polyshape properties and line intersection in clipper API

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

subNumBnd = subject.numboundaries;
subNumPts = subject.polyImpl.polyNumPoints;
[subX, subY] = getVtxArray(subject.polyImpl);
subIsHole = uint8(ishole(subject));
[subStPtr, subEnPtr] = getBoundaryPtr(subject.polyImpl);
subAreas = getBoundaryAreas(subject.polyImpl);
subFillRule = subject.polyImpl.getFillingRule();

[out1, out2] = coder.internal.clipperAPI.lineIntersect(subNumBnd, subNumPts, subX, subY, ...
                                                       subIsHole, subStPtr, subEnPtr, subAreas, subFillRule, lineseg);

% Bug fix for edge case where single line segment parallel to one
% of edges of the polyshape and lying outside the polyshape does not
% generate the out2 array (g3080709).
if (isempty(out1) && isempty(out2))
    uniqueCoordsInLine = unique(lineseg,'rows','stable');
    numUnique = size(uniqueCoordsInLine,1);
    outT = coder.nullcopy(lineseg);
    j = 0; % Number of elements filled into outT array.
    if numUnique > 1
        for ii = 1:coder.internal.indexInt(numUnique)
            [in1, on1] = inpolygon(uniqueCoordsInLine(ii,1), ...
                                   uniqueCoordsInLine(ii,2), subject.Vertices(:,1), ...
                                   subject.Vertices(:,2));
            if ~in1 || on1
                outT(j+1,:) = uniqueCoordsInLine(ii,:);
                j = j+1;
            end
        end
    end
    out2 = outT(1:j, :);
end
