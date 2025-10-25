classdef so3 < ...
        matlabshared.spatialmath.internal.SO3Base & ...
        matlab.mixin.internal.MatrixDisplay
%SO3 Create an SO(3) rotation matrix
%   The SO3 class represents an SO(3) rotation in 3-D.
%   This rotation is represented by a 3-by-3 matrix in a right-handed
%   Cartesian coordinate system.
%
%   R = SO3 creates an object with the identity rotation.
%
%   R = SO3(Rm) creates a 1-by-N rotation array defined by the array of
%   orthonormal rotation matrices, Rm. Rm is
%   either a numeric 3-by-3-by-N array or an SO3 array of 3-D rotations or
%   an so2 array of 2-D rotations.
%
%
%   SO(3) rotations can also be created from other 3-D rotation
%   representations.
%
%   R = SO3(QTN) creates an N-by-M array from the rotations
%   specified by the N-by-M quaternion array QTN.
%
%   R = SO3(E, "eul") creates a 1-by-N array from the rotations in the
%   N-by-3 matrix E. Each row of E represents a set of Euler angles (in
%   radians). The angles in E are rotations about the "ZYX" axes.
%
%   R = SO3(E, "eul", CV) creates a 1-by-N rotation array.
%   The angles in E are rotations about the axes in
%   convention CV. CV can be any one of "YZY", "YXY", "ZYZ", "ZXZ",
%   "XYX", "XZX", "XYZ", "YZX", "ZXY", "XZY", "ZYX", or "YXZ".
%
%   R = SO3(Q, "quat") creates a 1-by-N array from the rotations in the
%   N-by-4 matrix Q. Each row of Q represents a quaternion rotation and is
%   of the form [QW QX QY QZ], with W as the scalar number.
%
%   R = SO3(AXANG, "axang") creates a 1-by-N array from
%   the rotations in the N-by-4 matrix AXANG. Each row of AXANG represents
%   an axis-angle rotation and is of the form [X Y Z THETA], with the
%   first three elements specifying the rotation axis and the last element
%   defining the rotation angle (in radians).
%
%   R = SO3(ANG, "rotx") creates an N-by-M array of rotations around the
%   X-axis defined by the N-by-M array of angles ANG (in radians). The
%   rotation angle is positive if the rotation is counter-clockwise when
%   viewed by an observer looking along the X-axis towards the origin.
%
%   R = SO3(ANG, "roty") creates an N-by-M array of rotations around the
%   Y-axis defined by the N-by-M array of angles ANG (in radians).
%
%   R = SO3(ANG, "rotz") creates an N-by-M array of rotations around the
%   Z-axis defined by the N-by-M array of angles ANG (in radians).
%
%
%   SO3 methods:
%      axang      - Convert to axis-angle rotation
%      dist       - Calculate distance between transformations
%      eul        - Convert to Euler or Tait-Bryan angle rotation
%      interp     - Interpolate poses
%      inv        - Inverse of transformation
%      normalize  - Normalize the rotation matrix
%      quat       - Convert to quaternion rotation (numeric)
%      quaternion - Convert to quaternion array
%      rotm       - Convert to rotation matrix (numeric)
%      tform      - Convert to homogeneous transformation matrix
%      transform  - Apply rigid body transformation to points
%      trvec      - Create translation vector
%      xyzquat    - Convert to compact pose representation
%
%   Example:
%
%      % Create rotation from random matrix
%      T = SO3(rand(3));
%
%      % Normalize to get proper rotation matrix
%      Tn = normalize(T)
%
%      % Visualize rotation
%      figure;
%      plotTransforms([0 0 0], Tn)
%
%      % Rotate 50 random points around origin
%      pts = rand(50,3);
%      ptsT = transform(T, pts);
%      % Plot original and transformed points
%      figure;
%      hold on;
%      plot3(pts(:,1), pts(:,2), pts(:,3), ".", MarkerSize=20)
%      plot3(ptsT(:,1), ptsT(:,2), pts(:,3), ".", MarkerSize=20)
%
%      % Create rotation from Euler angle rotations
%      T = SO3([0.2 pi/4 0.1], "eul", "zyx")
%
%   See also se3, quaternion, eul2rotm.

%   Copyright 2022-2024 The MathWorks, Inc.

    methods
        function obj = so3(varargin)
            obj@matlabshared.spatialmath.internal.SO3Base(varargin{:});
        end
    end

    % Externally defined, public methods
    methods
        obj = ctranspose(obj)
        obj = pagectranspose(obj)
        obj = pagetranspose(obj)
        obj = permute(obj, order)
        x   = reshape(obj, varargin)
        obj = transpose(obj)
    end

    methods (Static)
        o = ones(varargin)
    end

    methods (Hidden)
        obj = parenReference(obj, varargin)
        obj = parenAssign(obj, rhs, varargin)
    end

    methods (Static, Hidden)
        obj = empty(varargin)
        obj = fromMatrix(T,sz)
        name = matlabCodegenRedirect(~)
    end

end
