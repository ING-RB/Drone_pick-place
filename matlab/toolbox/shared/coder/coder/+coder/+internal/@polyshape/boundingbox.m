function [xLimit, yLimit] = boundingbox(pshape, idx)
%MATLAB Code Generation Library Function
% BOUNDINGBOX Get vertices of the polyshape bounding box or of single
% bounding box inside the polyshape

%   Copyright 2022 The MathWorks, Inc.

%#codegen

coder.internal.polyshape.checkConsistency(pshape, nargin);

if nargin == 1

    minx = realmax;
    miny = realmax;
    maxx = -1*realmax;
    maxy = -1*realmax;

    valid_bb = false;
    for i=1:numel(pshape)
        if pshape(i).isEmptyShape()
            continue;
        end
        valid_bb = true;
        pshapeBbox = pshape(i).polyImpl.getBbox;
        minx = min(minx, pshapeBbox.loX);
        maxx = max(maxx, pshapeBbox.hiX);
        miny = min(miny, pshapeBbox.loY);
        maxy = max(maxy, pshapeBbox.hiY);
    end
    if valid_bb
        xLimit = [minx maxx];
        yLimit = [miny maxy];
    else
        xLimit = zeros(0, 2);
        yLimit = zeros(0, 2);
    end
else
    coder.internal.polyshape.checkScalar(pshape);
    coder.internal.polyshape.checkEmpty(pshape);
    II = coder.internal.polyshape.checkIndex(pshape, idx);

    subBbox = struct('loX',realmax,'loY',realmax,'hiX',-1*realmax,'hiY',-1*realmax);
    for i = 1:numel(II)
        bndBbox = getBoundaryBbox(pshape.polyImpl, II(i));
        subBbox = coder.internal.polyshapeHelper.mergeBbox(subBbox, bndBbox);
    end
    xLimit = [subBbox.loX, subBbox.hiX];
    yLimit = [subBbox.loY, subBbox.hiY];
end
