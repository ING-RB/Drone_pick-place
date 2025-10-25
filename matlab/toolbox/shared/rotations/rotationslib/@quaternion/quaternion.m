classdef (Sealed) quaternion < matlabshared.rotations.internal.quaternionBase & ...
        matlab.mixin.internal.MatrixDisplay
%QUATERNION - quaternion array
%   Q = QUATERNION(A,B,C,D) creates a quaternion array where the four
%   quaternion parts are taken from the arrays A,B,C and D. All of the
%   inputs must have the same size and be of the same class, either
%   double or single.
%  
%   A quaternion is a four part hypercomplex number that can be used to
%   represent rotations in three dimensions.
%  
%   A quaternion is a number
%  
%     a + b*i + c*j + d*k,   
%  
%   where i*i = j*j = k*k = i*j*k = -1
%  
%   Q = QUATERNION(M) creates an N-by-1 quaternion array from an N-by-4
%   matrix M where each column becomes one part of the quaternion.
%  
%   Quaternions can also be created from other 3-D rotation
%   representations. 
%  
%   Q = QUATERNION(RV, 'rotvec') creates an N-by-1 quaternion array from
%   the N-by-3 matrix RV. Each row of RV represents the [X Y Z] elements
%   of a rotation vector. Rotation vectors represent a 3-D axis of
%   rotation, where the magnitude corresponds to the rotation angle in
%   radians.
%
%   Q = QUATERNION(RV, 'rotvecd') creates an N-by-1 quaternion array from
%   an N-by-3 matrix where each row is a rotation vector with the
%   magnitude of the rotation angle in degrees.
%   
%   Many rotation representations are designed for point or frame
%   rotation. Quaternions can be created from these also.
%  
%   Q = QUATERNION(R, 'rotmat', PF) creates an N-by-1 quaternion array
%   from the array R of rotation matrices. R can be 3-by-3 or 3-by-3-N.
%   PF can be either 'point' if the Euler angles represent point
%   rotations or 'frame' for frame rotations.
%  
%   Q = QUATERNION(E, 'euler', CV, PF) creates an N-by-1 quaternion array
%   from the N-by-3 matrix E. Each row of E represents a set of Euler
%   angles in radians. The angles in E are rotations about the axes in
%   convention CV. CV can be any one of 'YZY', 'YXY', 'ZYZ', 'ZXZ',
%   'XYX', 'XZX', 'XYZ', 'YZX', 'ZXY', 'XZY', 'ZYX', or 'YXZ'. PF can be
%   either 'point' if the Euler angles represent point rotations or
%   'frame' for frame rotations.
%
%   Q = QUATERNION(E, 'eulerd', CV, PF) converts to quaternions from Euler
%   angles expressed in degrees.
%
%   QUATERNION methods and functions:
%     Construction and conversion:
%       quaternion  - Create quaternion from parts or other rotation 
%                     representations.
%       rotmat      - Convert to rotation matrices.
%       euler       - Convert to Euler or Tait-Bryan angles (radians).
%       eulerd      - Convert to Euler or Tait-Bryan angles (degrees).
%       rotvec      - Convert to rotation vectors (radians).
%       rotvecd     - Convert to rotation vectors (degrees).
%       compact     - Arrays from quaternions.
%       parts       - Extract four parts of a quaternion.
%     Rotation:
%       rotateframe - Rotate coordinate frame using quaternions.
%       rotatepoint - Rotate 3D points using quaternions.
%     Normalization:
%       norm        - Quaternion norm.
%       normalize   - Convert to a unit quaternion.
%     Computations on quaternions:
%       dist        - Distance between two quaternions.
%       log         - Quaternion logarithm.
%       exp         - Quaternion exponentiation.
%       meanrot     - Average rotation.
%       slerp       - Spherical Linear Interpolation.
%
%    Examples:
%  
%     % Rotate the point [1 1 1] by 30 degrees around the z-axis
%     q = quaternion( [0 0 deg2rad(30)] , 'rotvec');
%     pRotQuat = rotatepoint(q, [1 1 1])
%  
%     % Convert to a rotation matrix and compare the result
%     pRotMat = rotmat(q, 'point') * [1 1 1].' 
%     
%     % Multiply two quaternions and get the equivalent rotation matrix
%     q1 = quaternion([0.5 0.5 0.5 0.5]);
%     q2 = quaternion([1 0 0 1] * sqrt(2)/2);
%     m = rotmat(q1*q2, 'frame')
%
%     % Average
%     edeg = [10 40 30; 20 45 50; 30 43 70];
%     qa = quaternion(edeg, 'eulerd', 'ZYX', 'frame');
%     qaverage = meanrot(qa) % Average quaternion
%     eavg = eulerd(qaverage, 'ZYX','frame')
%
%     % Interpolation
%     qnear = slerp(qa(1), qa(2), 0.3)  % Quaternion 30 percent of the way 
%                                        %between 1st and 2nd
%     enear = eulerd(qnear, 'ZYX','frame')
%
%    See also: randrot
%

%   Copyright 2017-2024 The MathWorks, Inc.
    
    methods
        function obj = quaternion(varargin)
            obj@matlabshared.rotations.internal.quaternionBase(varargin{:});
        end
    end

    methods % Public, externally defined
        o = times(x,y)
        obj = transpose(obj)
        obj = ctranspose(obj)
        obj = permute(obj, order)
        x = reshape(obj, varargin)
        q = double(q)
        q = single(q)
        o = rdivide(x,y)
        o = ldivide(x,y)
        r = power(q,n);
    end

    methods (Access = protected) % Protected, externally defined
        q = buildOutput(q,a,b,c,d)
    end
    
    methods (Static)
        o = zeros(varargin)
        o = ones(varargin)
        o = nan(varargin)
    end
    
    methods (Static,Hidden)
        o = empty(varargin)
    end
    
    methods (Hidden)
        obj = parenReference(obj,varargin)
        obj = parenAssign(obj,rhs,varargin)
        o = ctor(~,varargin)
    end
    
    methods (Access=public,Hidden,Static)
        name = matlabCodegenRedirect(~)
    end
end

% [EOF]
