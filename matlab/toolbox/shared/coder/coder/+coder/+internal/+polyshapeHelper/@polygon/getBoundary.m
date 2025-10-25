function [X, Y] = getBoundary(pgon, it)
%MATLAB Code Generation Library Function
% Get the vertices of the boundary

%   Copyright 2023 The MathWorks, Inc.

%#codegen

idx = pgon.accessOrder.getMappedIndex(it);

numReqBound = numel(idx);
npts = 0;
for ii = 1:numReqBound
    [stPtr, enPtr] = pgon.boundaries.getBoundary(idx(ii));
    npts = npts + enPtr - stPtr + 1;
    if (ii < numReqBound)
        npts = npts + 1;
    end
end

X = coder.nullcopy(zeros(npts,1,'double'));
Y = coder.nullcopy(zeros(npts,1,'double'));

iv = 1;
for ii = 1:numReqBound

    [stPtr, enPtr] = pgon.boundaries.getBoundary(idx(ii));
    last_j = enPtr - stPtr + 1;

    for j = 1:last_j
        [X(iv), Y(iv)] = pgon.boundaries.getCoordAtIdx(idx(ii), j);
        iv = iv+1;
    end
    if (ii < numReqBound)
        X(iv) = nan;
        Y(iv) = nan;
        iv = iv + 1;
    end
end
