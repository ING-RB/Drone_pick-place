classdef (Abstract, Hidden) SE2Base < ...
        matlabshared.spatialmath.internal.SEBase & ...
        matlab.mixin.internal.indexing.Paren & ...
        matlab.mixin.internal.indexing.ParenAssign
%This class is for internal use only. It may be removed in the future.

%SE2Base Base class for user-visible se2 and internal SE2cg classes
%   All methods on this class need to support codegen.

% Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    properties (Constant, Hidden)
        %Dim - Dimensionality of underlying se2 matrix
        Dim = 3

        %ValidConversionTypes - Valid conversion type input strings
        ValidConversionTypes = {'theta','trvec','xytheta'}
    end

    methods
        function obj = SE2Base(varargin)
            n = nargin;
            d = matlabshared.spatialmath.internal.SE2Base.Dim;
            switch n
              case 0
                % se2() with no arguments
                obj.M = eye(d);
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
                % Use errorIf to ensure compile-time error
                coder.internal.errorIf(true, "shared_spatialmath:matobj:InputNumber", "se2", 2);
            end
        end
    end

    % Externally defined, public methods
    methods
        rot = so2(obj)
        th = theta(obj)
        pose = xytheta(obj)
    end

    methods (Access = protected)
        R = quatToRotm(obj, q)
        q = toQuaternion(obj, numQuats, idx)
    end

    methods (Abstract, Static, Hidden)
        obj = fromRotmTrvec(R,t,sz)
    end

    methods (Static, Access = {?matlabshared.spatialmath.internal.SE2Base, ?matlab.unittest.TestCase})
        [M,MInd] = parseOneInput(arg)
        [M,MInd] = parseTwoInputs(arg1, arg2)
        [M,MInd] = parseThreeInputs(arg1, arg2, arg3)
        [tf,sz,inputTypeStr] = parseConversionInputs(data, inputType)
        transl = parseTranslationInput(data)
    end

end
