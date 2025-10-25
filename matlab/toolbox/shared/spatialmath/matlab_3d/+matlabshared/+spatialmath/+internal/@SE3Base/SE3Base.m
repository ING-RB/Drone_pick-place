classdef (Abstract, Hidden) SE3Base < ...
        matlabshared.spatialmath.internal.SEBase & ...
        matlab.mixin.internal.indexing.Paren & ...
        matlab.mixin.internal.indexing.ParenAssign
%This class is for internal use only. It may be removed in the future.

%SE3Base Base class for user-visible se3 and internal SE3cg classes
%   All methods on this class need to support codegen.

% Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    properties (Constant, Hidden)
        %Dim - Dimensionality of underlying se3 matrix
        Dim = 4

        %ValidConversionTypes - Valid conversion type input strings
        ValidConversionTypes = {'axang','eul','quat','rotx','roty','rotz','trvec','xyzquat'}
    end

    methods
        function obj = SE3Base(varargin)
            n = nargin;
            switch n
              case 0
                % se3() with no arguments
                obj.M = eye(4);
                obj.MInd = 1;

              case 1
                [obj.M,obj.MInd] = obj.parseOneInput(varargin{1});

              case 2
                [obj.M,obj.MInd] = obj.parseTwoInputs(varargin{1}, varargin{2});


              case 3
                [obj.M,obj.MInd] = obj.parseThreeInputs(varargin{1}, varargin{2}, varargin{3});


              case 4
                [obj.M,obj.MInd] = obj.parseFourInputs(varargin{1}, varargin{2}, varargin{3}, varargin{4});

              case 8
                % This is a fake constructor used during codegen to
                % directly assign M and MInd.
                obj.M = varargin{1};
                obj.MInd = varargin{2};

              otherwise
                % Use errorIf to ensure compile-time error.
                % coder.internal.errorIf(true, ...) works here, since
                % nargin is always a compile-time constant.
                coder.internal.errorIf(true, "shared_spatialmath:matobj:InputNumber", "se3", 4);
            end
        end
    end

    % Externally defined, public methods
    methods
        a = axang(obj)
        e = eul(obj, seq)
        q = quat(obj)
        qobj = quaternion(obj)
        rot = so3(obj)
        pose = xyzquat(obj)
    end

    methods (Access = protected)
        R = quatToRotm(obj, q)
        q = toQuaternion(obj, numQuats, idx)
    end

    methods (Static, Access = {?matlabshared.spatialmath.internal.SE3Base, ?matlab.unittest.TestCase})
        [M,MInd] = parseOneInput(arg)
        [M,MInd] = parseTwoInputs(arg1, arg2)
        [M,MInd] = parseThreeInputs(arg1, arg2, arg3)
        [M,MInd] = parseFourInputs(arg1, arg2, arg3, arg4)
        [tf,sz,inputTypeStr] = parseConversionInputs(data, inputType, convention)
        transl = parseTranslationInput(data)
    end

    methods (Abstract, Static, Hidden)
        obj = fromRotmTrvec(R,t,sz)
    end

end
