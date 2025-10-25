classdef se3 < ...
        matlabshared.spatialmath.internal.SE3Base & ...
        matlab.mixin.internal.MatrixDisplay
%SE3 Create an SE(3) homogeneous transformation
%   The SE3 class represents an SE(3) transformation consisting of
%   3-D translation and rotation in a right-handed
%   Cartesian coordinate system. This pose is represented by a 4-by-4
%   homogeneous transformation matrix.
%
%   T = SE3 creates an identity transformation.
%   The translation is zero, and the rotation is an identity
%   rotation.
%
%   T = SE3(R) creates a 1-by-N transformation array representing a pure
%   rotation defined by the array of orthonormal rotation matrices, R. R is
%   either a numeric 3-by-3-by-N array or an so3 array of rotations.
%   All translations in T are zero.
%
%   T = SE3(R, TRANSL) creates a 1-by-N transformation array representing a
%   rotation defined by R and translation defined by TRANSL. TRANSL can be
%   either a 1-by-3 vector (same translation applied to all rotations in R)
%   or an N-by-3 matrix (each row corresponds to the translation for each
%   rotation in R).
%
%   T = SE3(TF) creates a 1-by-N transformation array representing
%   translation and rotation defined by the array of homogeneous
%   transformation matrices, TF. TF is either a numeric 4-by-4-by-N array
%   or an SE3 array of 3-D transformations or an se2 array of 2-D
%   transformations.
%
%
%   Transformations can also be created from other 3-D rotation
%   representations.
%
%   T = SE3(QTN) creates an N-by-M transformation array from the rotations
%   specified by the N-by-M quaternion array QTN. All translations in T are
%   zero.
%
%   T = SE3(E, "eul") creates a 1-by-N transformation array
%   from the rotations in the N-by-3 matrix E. Each row of E represents
%   a set of Euler angles (in radians). The angles in E are rotations about
%   the "ZYX" axes. All translations in T are zero.
%
%   T = SE3(E, "eul", "SEQ") creates a 1-by-N transformation array.
%   The angles in E are rotations about the axes sequence in
%   convention SEQ. SEQ can be any one of "YZY", "YXY", "ZYZ", "ZXZ",
%   "XYX", "XZX", "XYZ", "YZX", "ZXY", "XZY", "ZYX", or "YXZ".
%
%   T = SE3(Q, "quat") creates a 1-by-N transformation array from
%   the rotations in the N-by-4 matrix Q. Each row of Q represents a
%   quaternion rotation and is of the form [QW QX QY QZ], with QW as the
%   scalar number. All translations in T are zero.
%
%   T = SE3(AXANG, "axang") creates a 1-by-N transformation array from
%   the rotations in the N-by-4 matrix AXANG. Each row of AXANG represents
%   an axis-angle rotation and is of the form [X Y Z THETA], with the
%   first three elements specifying the rotation axis and the last element
%   defining the rotation angle (in radians). All translations in T are
%   zero.
%
%   T = SE3(ANG, "rotx") creates an N-by-M transformation array from
%   rotations around the X-axis defined by the N-by-M array of angles ANG
%   (in radians). The rotation angle is positive if the rotation is
%   counter-clockwise when viewed by an observer looking along the X-axis
%   towards the origin. All translations in T are zero.
%
%   T = SE3(ANG, "roty") creates an N-by-M transformation array from
%   rotations around the Y-axis defined by the N-by-M array of angles ANG
%   (in radians).
%
%   T = SE3(ANG, "rotz") creates an N-by-M transformation array from
%   rotations around the Z-axis defined by the N-by-M array of angles ANG
%   (in radians).
%
%   T = SE3(..., "...", TRANSL) creates a transformation array from N
%   rotations. The translations are defined by TRANSL. TRANSL can be either
%   a 1-by-3 vector (same translation applied to all rotations) or an
%   N-by-3 matrix (each row corresponds to the translation for each
%   rotation).
%
%
%   Transformations can also be created from other 3-D translation and
%   transformation representations.
%
%   T = SE3(TRANSL, "trvec") creates a 1-by-N transformation array from
%   the translations in the N-by-3 matrix TRANSL. Each row of TRANSL
%   represents a translation of the form [X Y Z]. All rotations in T are
%   the identity rotation.
%
%   T = SE3(POSE, "xyzquat") creates a 1-by-N transformation array from
%   the poses in the N-by-7 matrix POSE. Each row of POSE represents
%   a 3-D pose of the form [X Y Z QW QX QY QZ]. [X Y Z] is the translation
%   and [QW QX QY QZ] is the quaternion rotation.
%
%
%   SE3 methods:
%      axang       - Extract axis-angle rotation
%      dist        - Calculate distance between transformations
%      eul         - Extract Euler or Tait-Bryan angle rotation
%      interp      - Interpolate poses
%      inv         - Inverse of transformation
%      normalize   - Normalize the rotation submatrix
%      quat        - Extract quaternion rotation (numeric)
%      quaternion  - Extract rotation as quaternion array
%      rotm        - Extract rotation matrix
%      so3         - Extract SO(3) rotation array
%      tform       - Homogeneous transformation matrix
%      transform   - Apply rigid body transformation to points
%      trvec       - Extract translation vector
%      xyzquat     - Convert to compact pose representation
%
%   Example:
%
%      % Create transformation from rotation and translation
%      T = SE3(eye(3), [1 2 3]);
%
%      % Create transformation from Euler angle rotations
%      T = SE3([0.2 pi/4 0.1], "eul", "xyz")
%
%      % Interpolate between transformations in 10 steps
%      T1 = SE3;
%      T2 = SE3([deg2rad(45) 0 deg2rad(45)], "eul", "xyz", [2 1 0]);
%      Ti = interp(T1,T2,10);
%
%      % Visualize interpolated transformations
%      figure;
%      plotTransforms(Ti)
%
%      % Transform 50 random points around origin
%      pts = [rand(50,2) ones(50,1)];
%      ptsT = transform(T, pts);
%      % Plot original and transformed points
%      figure;
%      hold on;
%      plot3(pts(:,1), pts(:,2), pts(:,3), ".", MarkerSize=20)
%      plot3(ptsT(:,1), ptsT(:,2), ptsT(:,3), ".", MarkerSize=20)
%
%
%   See also so3, rotm2tform, eul2tform.

%   Copyright 2022-2024 The MathWorks, Inc.

    methods
        function obj = se3(varargin)
            obj@matlabshared.spatialmath.internal.SE3Base(varargin{:});
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
        obj = fromRotmTrvec(R,t,sz)
        name = matlabCodegenRedirect(~)
    end

end
