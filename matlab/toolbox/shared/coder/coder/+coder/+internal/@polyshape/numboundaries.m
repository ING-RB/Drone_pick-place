function nb = numboundaries(pshape)
%MATLAB Code Generation Library Function
% NUMBOUNDARIES Get the number of boundaries in the polyshape

%   Copyright 2022 The MathWorks, Inc.

%#codegen

n = coder.internal.polyshape.checkArray(pshape);
nb = zeros(n);
for i=1:numel(pshape)
    nb(i) = pshape(i).polyImpl.getNumBoundaries();
end