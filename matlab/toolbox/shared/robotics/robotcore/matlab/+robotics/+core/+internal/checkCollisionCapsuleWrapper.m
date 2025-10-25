function varargout = checkCollisionCapsuleWrapper(egoXYZ, egoUnitV, D1, R1, objXYZs, objUnitVs, D2, R2, exhaustive)
% This function is for internal use only. It may be removed in the future.

%checkCollisionCapsuleWrapper Wrapper for capsule-capsule collision check
%
%   This file serves as a wrapper around the MEX and MATLAB capsule-capsule
%   collision-checking implementation. Different MEX files must be generated
%   to trigger or avoid computation of distance and/or witness points.
%
%   COLLISIONFOUND = checkCollisionCapsuleWrapper(P1,V1,D1,R1,P2,V2,D2,R2) performs
%   a pair-wise comparison of capsules in Set1 against capsules in Set2. If
%   the number of capsules in Set2 (e.g M) is an integer multiple of the number of
%   capsules in Set1 (e.g. N), then Set1 is compared against M/N horizontally
%   concatenated set of capsules in Set2. COLLISIONFOUND is returned as an
%   N-by-(M/N) matrix of logicals, where the [i,j]-th element represents
%   the comparison of the ith capsule in Set1 against the paired capsule
%   in the jth concatenated set of capsules in Set2.
%
%       [A1 A2 .. AN] |^| [[B11 B12 .. B1N] [B21 B22 .. B2N] ... [...]]
%
%                           -> [A1_B11 A1_B21     A1_BM1
%                               A2_B12 A2_B22     A2_BM2
%                                   ...
%                               AN_B1N AN_B2N ... AN_BMN]
%
%       An individual capsule is defined by a set of parameters:
%           P   - An xy or xyz point corresponding to the start of the capsule's axis
%           V   - An xy or xyz unit vector describing the direction of the capsule's axis
%           D   - The length of the line segment at the core of the capsule
%           R   - The capsule's radius
%
%                           ,.-+-------------------+-.,
%                          /       V                   \
%                Z  Y     (    P===>- - - - - - - -+    )
%                | /       \                        \R /
%                |/_ _X     `*-+-------------------+-*`
%                              |---------D---------|
%
%       For a set of capsules, P and V are DIM-by-NumCapsule matrices, where
%       DIM is either 2 or 3 depending on whether the capsule is 2D (xy) or
%       3D (xyz). D and R can either be scalar, or NumCapsule-element vectors.
%
%   COLLISIONFOUND = checkCollisionCapsuleWrapper(P1,V1,D1,R1,P2,V2,D2,R2,EXHAUSTIVE)
%   takes an optional logical flag, EXHAUSTIVE. If this is set to true,
%   then each capsule in Set1 is compared against ALL capsules in Set2. The
%   size of COLLISIONFOUND will be N-by-M, where the [i,j]-th element
%   represents the comparison of SetA's ith capsule with SetB's jth
%   capsule.
%
%           [A1 A2 .. AN] |^| [B1 B2 .. BN]
%
%                           -> [A1_B1 A1_B2     A1_BM
%                               A2_B1 A2_B2     A2_BM
%                                   ...
%                               AN_B1 AN_B2 ... AN_BM]
%
%   [___, DISTANCE] = checkCollisionCapsuleWrapper(P1,V1,D1,R1,P2,V2,D2,R2,___)
%   returns the distance between pairs of capsules in SetA and SetB. If a
%   pair of capsules are not in collision, then DISTANCE will contain the
%   distance between the nearest points on the capsules' boundary. If two
%   capsules are intersecting, the corresponding element of DISTANCE will
%   contain NaN.
%
%   [___, WITNESSPOINTS] = checkCollisionCapsuleWrapper(P1,V1,D1,R1,P2,V2,D2,R2,___)
%   returns the closest points, WITNESSPOINTS, between each pair of
%   compared capsules in SetA and SetB.
%   If each set only contains 1 capsule, then the result will be a DIM-by-2
%   matrix. If the number of capsules in either set is greater than 1, then
%   the output will be of size [NSetA OUTHEIGHT DIM 2], where OUTHEIGHT is
%   NSetB when EXHAUSTIVE=true and NSetB/NSetA otherwise. For any pair of
%   colliding capsules, the WITNESSPOINTS will contain NaN.
%
%   References:
%
%       [1] Distance calculation based on http://geomalgorithms.com/a07-_distance.html

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    narginchk(8,9);

    if nargin == 8
        exhaustive = false;
    end

    if coder.target('MATLAB')
        varargout = cell(1,nargout);
        switch nargout
          case 1
            [varargout{:}] = robotics.core.internal.mex.checkCollisionCapsule(...
                egoXYZ, egoUnitV, D1, R1, objXYZs, objUnitVs, D2, R2, exhaustive);
          case 2
            [varargout{:}] = robotics.core.internal.mex.checkCollisionCapsuleDistance(...
                egoXYZ, egoUnitV, D1, R1, objXYZs, objUnitVs, D2, R2, exhaustive);
          otherwise
            [varargout{:}] = robotics.core.internal.mex.checkCollisionCapsuleWitnessPoints(...
                egoXYZ, egoUnitV, D1, R1, objXYZs, objUnitVs, D2, R2, exhaustive);
        end
    else
        [varargout{:}] = robotics.core.internal.impl.checkCollisionCapsule(...
            egoXYZ, egoUnitV, D1, R1, objXYZs, objUnitVs, D2, R2, exhaustive);
    end
end
