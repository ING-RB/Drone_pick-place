function H = getHoleDirection(P)
%getHoleDirection - The global hole direction of vector A based on its quadrant
%
%   holeDirection = getHoleDirection(aQuad) determines the global hole direction with respect
%   to A (Upper or Lower) where "hole direction" is defined as the side of 
%   A that is bordered by a hole. This function assumes that the local hole 
%   direction is always to the 'left' of A, from A's perspective. 
%   For example, if A = [1 0], the hole direction is Upper because the left
%   of A is in the positive y-direction.

%   Copyright 2024 The MathWorks, Inc.
%#codegen
    H = sign(sum([-1 0].*P,2));
    H(H == 1) = 2; % Lower
    H(H == -1) = 1; % Upper
    H(H == 0) = 1; % By convention
    H(all(P == [0 0],2)) = 2; % by convention
end
