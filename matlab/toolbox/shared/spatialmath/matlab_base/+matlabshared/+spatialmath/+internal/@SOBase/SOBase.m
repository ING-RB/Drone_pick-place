classdef (Abstract,Hidden) SOBase < matlabshared.spatialmath.internal.SpatialMatrixBase
%This class is for internal use only. It may be removed in the future.

%SOBase Base class for user-visible so2 and so3 classes
%   All methods on this class need to support codegen.

% Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% Externally defined, public methods
    methods
        d = dist(obj, obj2)
        Tint = interp(obj, obj2, pts)
        Tinv = inv(obj)
        Tnorm = normalize(obj, varargin)
        R = rotm(obj)
        TF = tform(obj)
        tpts = transform(obj, pts, varargin)
        transl = trvec(obj, varargin)
    end

    methods (Static, Access={?matlabshared.spatialmath.internal.SOBase, ?matlab.unittest.TestCase})
        [M, MInd] = rawDataFromRotm(rotm,sz)
    end

    methods (Access = protected)
        function obj = assignFromRotationMatrix(obj, R)
        %assignFromRotationMatrix Assign the underlying matrix based on 3x3xN numeric matrix

            [obj.M,obj.MInd] = obj.rawDataFromRotm(R);
        end
    end
end
