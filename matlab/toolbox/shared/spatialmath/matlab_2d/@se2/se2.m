classdef se2 < ...
        matlabshared.spatialmath.internal.SE2Base & ...
        matlab.mixin.internal.MatrixDisplay
%SE2 Create an SE(2) homogeneous transformation
%   The SE2 class represents an SE(2) transformation consisting of
%   2-D translation and rotation in a right-handed
%   Cartesian coordinate system. This pose is represented by a 3-by-3
%   homogeneous transformation matrix.
%
%   T = SE2 creates an identity transformation.
%   The translation is zero, and the rotation is an identity
%   rotation.
%
%   T = SE2(R) creates a 1-by-N transformation array representing a pure
%   rotation defined by the array of orthonormal rotation matrices, R. R is
%   either a numeric 2-by-2-by-N array or an so2 array of rotations. The
%   translation for each element in T will be zero.
%
%   T = SE2(R,TRANSL) creates a 1-by-N transformation array representing a
%   rotation defined by R and translation defined by TRANSL. TRANSL can be
%   either a 1-by-2 vector (same translation applied to all rotations in R)
%   or an N-by-2 matrix (each row corresponds to the translation for each
%   rotation in R).
%
%   T = SE2(TF) creates a 1-by-N transformation array representing
%   translation and rotation defined by the array of homogeneous
%   transformation matrices, TF. TF is either a numeric 3-by-3-by-N array
%   or an SE2 array of transformations.
%
%
%   Transformations can also be created from other 2-D rotation
%   representations.
%
%   T = SE2(ANG, "theta") creates an N-by-M transformation array from
%   rotations around the Z-axis defined by the N-by-M array of angles ANG
%   (in radians).
%
%   T = SE2(ANG, "theta", TRANSL) creates a transformation array from N
%   rotations. The translations are defined by TRANSL. TRANSL is either a
%   1-by-3 vector (same translation applied to all rotations) or an N-by-3
%   matrix (each row corresponds to the translation for each rotation).
%
%
%   Transformations can also be created from other 2-D translation and
%   transformation representations.
%
%   T = SE2(TRANSL, "trvec") creates a 1-by-N transformation array from the
%   translations in the N-by-2 matrix TRANSL. Each row of TRANSL represents
%   a translation of the form [X Y]. All rotations in T are the identity
%   rotation.
%
%   T = SE2(POSE, "xytheta") creates a 1-by-N transformation array from the
%   poses in the N-by-3 matrix POSE. Each row of POSE represents a 2-D pose
%   of the form [X Y THETA]. [X Y] is the translation and [THETA] is the
%   rotation angle around the Z-axis.
%
%
%   SE2 methods:
%      dist      - Calculate distance between transformations
%      interp    - Interpolate poses
%      inv       - Inverse of transformation
%      normalize - Normalize the rotation submatrix
%      rotm      - Extract rotation matrix
%      so2       - Extract SO(2) rotation array
%      tform     - Homogeneous transformation matrix
%      theta     - Extract rotation angle
%      transform - Apply rigid body transformation to points
%      trvec     - Extract translation vector
%      xytheta   - Convert to compact pose representation
%
%   Example:
%
%      % Create transformation from rotation and translation
%      T = SE2(eye(2), [1 3]);
%
%      % Create transformation from rotation angle and translation
%      Te = SE2(pi/3, "theta", [0 -1]);
%
%      % Interpolate between transformations in 10 steps
%      T1 = SE2;
%      Ti = interp(T1,Te,10);
%
%      % Visualize interpolated transformations
%      figure;
%      plotTransforms(Ti)
%
%      % Transform 50 random points around origin
%      pts = rand(50,2);
%      ptsT = transform(T, pts);
%      % Plot original and transformed points
%      figure;
%      hold on;
%      plot(pts(:,1), pts(:,2), ".", MarkerSize=20)
%      plot(ptsT(:,1), ptsT(:,2), ".", MarkerSize=20)
%
%   See also so2.

%   Copyright 2022-2024 The MathWorks, Inc.

    methods
        function obj = se2(varargin)
            obj@matlabshared.spatialmath.internal.SE2Base(varargin{:});
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
