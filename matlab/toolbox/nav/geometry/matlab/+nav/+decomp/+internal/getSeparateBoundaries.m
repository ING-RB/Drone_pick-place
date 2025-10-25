function bounds = getSeparateBoundaries(m)
%This function is for internal use only. It may be removed in the future.

%getSeparateBoundaries - Return the regions and holes of a polyshape as a cell array
%   
%   BOUNDS = getPolys(M) returns the boundaries of the regions and holes 
%   that compose getSeparateBoundaries M as a CELL array BOUNDS.

%   Copyright 2024 The MathWorks, Inc.

%#codegen
    arguments (Input)
        m (1,1) polyshape
    end
    arguments (Output)
        bounds (:, 1) cell
    end

    [x, y] = boundary(m);
    M = [x y];
    idx = all(isnan(M),2);
    idy = 1+cumsum(idx);
    idz = 1:size(M,1);
    bounds = accumarray(idy(~idx),idz(~idx),[],@(r){M(r,:)},{zeros(0,2)}); % fillval ([]) required for codegen
end
