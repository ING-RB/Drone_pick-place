function holeStatus = holeMapping(m)
%holeMapping - The map from vertex ID to hole status
%
%   holeStatus = holeMapping(M) gives a logical vector indicating whether
%   each vertex of M lies on a region boundary or hole boundary. A logical
%   value of TRUE indicates that the vertex is on a hole. FALSE indices the 
%   vertex is on a region. 

%   Copyright 2024 The MathWorks, Inc.

%#codegen
    arguments (Input)
        m (1,1) polyshape
    end
    arguments (Output)
        holeStatus (:, 1) logical
    end

    x = m.boundary;
    n = numel(x);
    i = find(isnan(x))+1;
    bIdx = [1;i(:);n+1];
    holeStatus = false(n,1);
    for iReg = 1:(numel(bIdx)-1)
        holeStatus(bIdx(iReg):(bIdx(iReg+1)-1)) = m.ishole(iReg);
    end
end
