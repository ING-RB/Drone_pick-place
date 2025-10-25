classdef so2 < ...
        matlabshared.spatialmath.internal.SO2Base & ...
        matlab.mixin.internal.MatrixDisplay
%SO2 Create an SO(2) rotation matrix
%   The SO2 class represents an SO(2) rotation in 2-D.
%   This rotation is represented by a 2-by-2 matrix in a right-handed
%   Cartesian coordinate system.
%
%   R = SO2 creates an object with the identity rotation.
%
%   R = SO2(Rm) creates a 1-by-N rotation array defined by the array of
%   orthonormal rotation matrices, Rm. Rm is
%   either a numeric 3-by-3-by-N array or an so2 array of rotations.
%
%
%   SO(2) rotations can also be created from other 2-D rotation
%   representations.
%
%   T = SO2(ANG, "theta") creates an N-by-M transformation array from
%   rotations around the Z-axis defined by the N-by-M array of angles ANG
%   (in radians).
%
%
%   SO2 methods:
%      dist      - Calculate distance between transformations
%      interp    - Interpolate poses
%      inv       - Inverse of transformation
%      normalize - Normalize the rotation matrix
%      rotm      - Convert to rotation matrix (numeric)
%      tform     - Convert to homogeneous transformation matrix
%      theta     - Extract rotation angle
%      transform - Apply rigid body transformation to points
%      trvec     - Create translation vector
%      xytheta   - Convert to compact pose representation
%
%
%   Example:
%
%      % Create rotation from random matrix
%      T = SO2(rand(2));
%
%      % Normalize to get proper rotation matrix
%      Tn = normalize(T)
%
%      % Visualize rotation
%      figure;
%      plotTransforms([0 0], Tn)
%
%      % Rotate 50 random points around origin
%      pts = rand(50,2);
%      ptsT = transform(T, pts);
%      % Plot original and transformed points
%      figure;
%      hold on;
%      plot(pts(:,1), pts(:,2), ".", MarkerSize=20)
%      plot(ptsT(:,1), ptsT(:,2), ".", MarkerSize=20)
%
%      % Create rotation from angle
%      Te = SO2(pi/3, "theta");
%
%   See also se2, quaternion, eul2rotm.

%   Copyright 2022-2024 The MathWorks, Inc.

    methods
        function obj = so2(varargin)
            obj@matlabshared.spatialmath.internal.SO2Base(varargin{:});
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
