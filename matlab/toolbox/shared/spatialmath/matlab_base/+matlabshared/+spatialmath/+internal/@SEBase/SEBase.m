classdef (Abstract,Hidden) SEBase < matlabshared.spatialmath.internal.SpatialMatrixBase
%This class is for internal use only. It may be removed in the future.

%SEBase Base class for user-visible se2 and se3 classes
%   All methods on this class need to support codegen.

% Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% Externally defined, public methods
    methods
        d = dist(obj, obj2, weights)
        Tint = interp(obj, obj2, pts)
        Tinv = inv(obj)
        Tnorm = normalize(obj, varargin)
        R = rotm(obj)
        TF = tform(obj)
        tpts = transform(obj, pts, varargin)
        transl = trvec(obj, varargin)
    end

    methods (Access = {?matlabshared.spatialmath.internal.SEBase, ?matlab.unittest.TestCase})
        function T = rt2tform(obj,R,t)
        %rt2tform Method to create a transformation matrix from a numeric rotation and a translation

            T = matlabshared.spatialmath.internal.rt2tform(R,t,obj.Dim);
        end
    end

    % Externally defined methods
    methods (Access = protected)
        t = toTrvec(obj, numTransl)
    end

    methods (Static, Access={?matlabshared.spatialmath.internal.SEBase, ?matlab.unittest.TestCase})
        [M, MInd] = rawDataFromTform(tf,sz)
        [M,MInd] = rawDataFromTformTrvec(varargin)
        [tfValid,arraySize] = alignTformTrvecSize(tf, transl, rotArraySize)
    end

    methods (Access = protected)
        function obj = assignFromTransformMatrix(obj, varargin)
        %assignFromTransformMatrix Assign the underlying matrix based on 4x4xN numeric matrix

            [obj.M,obj.MInd] = obj.rawDataFromTform(varargin{:});

        end

        function obj = assignFromTformTrvec(obj, tf, transl, rotArraySize)
        %assignFromTformTrvec Assign data from transform matrix and translation vector
        %   The rotArraySize describes the shape of the rotation array
        %   if it was provided as an object array, e.g. so3 or
        %   quaternion. If there are multiple rotations, use
        %   rotArraySize to reshape the output accordingly.

        % Assign the final transformation matrices
            [obj.M,obj.MInd] = obj.rawDataFromTformTrvec(tf, transl, rotArraySize);
        end

        function transl = trvecCol(obj)
        %trvecCol Fast way to extract translation vectors as columns

            d = obj.Dim;
            translMD = obj.M(1:d-1, d, :);
            transl = squeeze(translMD);
        end
    end

end
