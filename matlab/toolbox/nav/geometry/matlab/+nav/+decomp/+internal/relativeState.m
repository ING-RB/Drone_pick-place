function R = relativeState(A, B, hD)
%This function is for internal use only. It may be removed in the future.

%relativeState - Direction of vector B w.r.t. vector A and the hole direction
%
%   R = relativeState(A, B, hD) classifies the direction
%   of vector B w.r.t. vector A and the global holeDirection hD.
%
%   See also RelativeAlignment

%   Copyright 2024 The MathWorks, Inc.

%#codegen
    R = zeros(size(hD));

    % Get quadrants of B vectors
    bQ = nav.decomp.internal.getQuad(B);
    aQ = nav.decomp.internal.getQuad(A);

    % Handle North and South easy cases
    R(bQ == 4) = nav.decomp.internal.RelativeAlignment.South;
    R(bQ == 3) = nav.decomp.internal.RelativeAlignment.North;

    % Opposite case
    R(R == 0 & (aQ == 1 & bQ == 1 | aQ == 2 & bQ == 2)) = nav.decomp.internal.RelativeAlignment.Opposite;

    % Aligned/unaligned cases
    % Get direction of B wrt A
    m = A(:,2)./A(:,1);
    bD = (B(:,2) > m.*B(:,1)) + 1;
    northA = A(:,1) == 0 & A(:,2) > 0;
    southA = A(:,1) == 0 & A(:,2) < 0;
    bD(northA) = (B(northA,1) < A(northA,1)) + 1;
    bD(southA) = (B(southA,1) > A(southA,1)) + 1;

    R(R == 0 & bD == hD) = nav.decomp.internal.RelativeAlignment.Unaligned;
    R(R == 0 & bD ~= hD) = nav.decomp.internal.RelativeAlignment.Aligned;
end
