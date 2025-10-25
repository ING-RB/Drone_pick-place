classdef (Abstract, Hidden) SO2Base < ...
        matlabshared.spatialmath.internal.SOBase & ...
        matlab.mixin.internal.indexing.Paren & ...
        matlab.mixin.internal.indexing.ParenAssign
%This class is for internal use only. It may be removed in the future.

%SO2Base Base class for user-visible so2 and internal SO2cg classes
%   All methods on this class need to support codegen.

% Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    properties (Constant, Hidden)
        %Dim - Dimensionality of underlying so2 matrix
        Dim = 2

        %ValidConversionTypes - Valid conversion type input strings
        ValidConversionTypes = {'theta'}
    end

    methods
        function obj = SO2Base(varargin)
            n = nargin;
            switch n
              case 0
                % so2() with no arguments
                obj.M = eye(2);
                obj.MInd = 1;

              case 1
                [obj.M,obj.MInd] = obj.parseOneInput(varargin{1});

              case 2
                [obj.M,obj.MInd] = obj.parseTwoInputs(varargin{1}, varargin{2});

              case 8
                % This is a fake constructor used during codegen to
                % directly assign M and MInd.
                obj.M = varargin{1};
                obj.MInd = varargin{2};

              otherwise
                % Use errorIf to ensure compile-time error
                coder.internal.errorIf(true, "shared_spatialmath:matobj:InputNumber", "so2", 1);
            end
        end
    end

    % Externally defined, public methods
    methods
        th = theta(obj)
        pose = xytheta(obj)
    end

    methods (Access = protected)
        R = quatToRotm(obj, q)
        q = toQuaternion(obj, numQuats, idx)
    end

    methods (Static, Access = {?matlabshared.spatialmath.internal.SO2Base, ?matlab.unittest.TestCase})
        [M,MInd] = parseOneInput(arg)
        [M,MInd] = parseTwoInputs(arg1, arg2)
        [rotm,sz,inputTypeStr] = parseConversionInputs(data, inputType)
    end


end
