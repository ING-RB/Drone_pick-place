function [bNear, bi] = getClosest(a, B)
%getClosest - Get the vector in Bs closest to A, moving CCW from A
%   [B, BI] = getClosest(A, Bs) is the closest vector B in Bs to A, and BI
%   is the index of B in Bs such that Bs(BI, :) == B. 
%   The purpose of this function is to get the next out vector B for the in
%   vector A in the event of a collision. 
%   For example, if A = [0 1] and Bs = [1 0; 1 -1], B = [1 -1] (BI = 2) is
%   the closest vector to A because it is the first vector encountered when
%   moving CCW from the tail of A

%   Copyright 2024 The MathWorks, Inc.

%#codegen

    % Compare Bs to the negative of A because their directions are swapped
    % as OUTWARD and INWARD vectors, respectively

    % Compute side of vectors via cross-prod
    cdir = sign(sum([a(2) -a(1)].*B,2));

    % Compute vector-alignment
    nprod = sum(-a.*B,2) ./ (norm(a).*vecnorm(B,2,2));

    % Scale vector dist in second half of unit-circle to [-1 -2)
    m = cdir~=1;
    nprod(m) = -1 - (nprod(m)+1)/2; 

    % Find closest vector in CCW direction
    [~,bi] = max(nprod);
    bNear = B(bi,:);
end
