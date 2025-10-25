classdef (Abstract, Hidden) SO3Base < ...
        matlabshared.spatialmath.internal.SOBase & ...
        matlab.mixin.internal.indexing.Paren & ...
        matlab.mixin.internal.indexing.ParenAssign
%This class is for internal use only. It may be removed in the future.

%SO3Base Base class for user-visible so3 and internal SO3cg classes
%   All methods on this class need to support codegen.

% Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    properties (Constant, Hidden)
        %Dim - Dimensionality of underlying so3 matrix
        Dim = 3

        %ValidConversionTypes - Valid conversion type input strings
        ValidConversionTypes = {'axang','eul','quat','rotx','roty','rotz'}
    end

    methods
        function obj = SO3Base(varargin)
            n = nargin;
            switch n
              case 0
                % so3() with no arguments
                obj.M = eye(3);
                obj.MInd = 1;

              case 1
                [obj.M,obj.MInd] = obj.parseOneInput(varargin{1});

              case 2
                [obj.M,obj.MInd] = obj.parseTwoInputs(varargin{1}, varargin{2});

              case 3
                [obj.M,obj.MInd] = obj.parseThreeInputs(varargin{1}, varargin{2}, varargin{3});

              case 8
                % This is a fake constructor used during codegen to
                % directly assign M and MInd.
                obj.M = varargin{1};
                obj.MInd = varargin{2};

              otherwise
                % Use errorIf to ensure compile-time error.
                % coder.internal.errorIf(true, ...) works here, since
                % nargin is always a compile-time constant.
                coder.internal.errorIf(true, "shared_spatialmath:matobj:InputNumber", "so3", 3);
            end

        end
    end

    % Externally defined, public methods
    methods
        a = axang(obj)
        e = eul(obj, seq)
        q = quat(obj)
        qobj = quaternion(obj)
        pose = xyzquat(obj)
    end

    methods (Access = protected)
        R = quatToRotm(obj, q)
        q = toQuaternion(obj, numQuats, idx)
    end

    methods (Static, Access = {?matlabshared.spatialmath.internal.SO3Base, ?matlab.unittest.TestCase})
        [M,MInd] = parseOneInput(arg)
        [M,MInd] = parseTwoInputs(arg1, arg2)
        [M,MInd] = parseThreeInputs(arg1, arg2, arg3)
        [rotm,sz,inputTypeStr] = parseConversionInputs(data, inputType, convention)
    end

end
