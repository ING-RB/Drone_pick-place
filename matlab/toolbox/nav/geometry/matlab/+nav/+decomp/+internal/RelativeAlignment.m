classdef RelativeAlignment < uint8
%RelativeAlignment - Represent vector B w.r.t. a vector A and the hole direction

%   Copyright 2024 The MathWorks, Inc.

%#codegen
    enumeration
        %Opposite - B is on the opposite half of the plane w.r.t. A
        %   When the tail of B is placed at the tip of A and this touch
        %   point is considered to be the origin, B is on the opposite side
        %   of the plane (considering left/right sides). For example,
        %   vector B = [1 1] is opposite of vector A = [1 1].
        %   (Note: A == B and B and A are considered opposite)
        %   Put differently, A and B are considered opposite if -A and B lie on
        %   the same half (left or right) of the Cartesian plane.
        Opposite (1)
        %Aligned - B is not Opposite A and is in line with the hole
        %   B and A are considered aligned if they are not Opposite, B is
        %   not North or South, and the location of the tip of B is in line
        %   with the global hole direction. For example, for A = [1 1] and
        %   holeDirection = Upper, B = [-1 1] is Aligned because the tip of
        %   B is above A and so is the hole direction
        Aligned (2)
        %Unaligned - B is not Opposite A and is not in line with the hole
        %   B and A are considered aligned if they are not Opposite, B is
        %   not North or South, and the location of the tip of B is not in 
        %   line with the global hole direction. For example, for A = [1 1]
        %   and holeDirection = Lower, B = [-1 1] is Unaligned because the 
        %   tip of B is above A but the holeDirection is below
        Unaligned (3)
        %North - Vector B points straight up
        North (4)
        %South - Vector B points straight down
        South (5)
    end
end
