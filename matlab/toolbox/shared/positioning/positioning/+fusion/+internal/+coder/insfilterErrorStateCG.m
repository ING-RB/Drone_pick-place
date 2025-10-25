classdef (Hidden) insfilterErrorStateCG < fusion.internal.ErrorStateIMUGPSFuserBase
%   This class is for internal use only. It may be removed in the future.

%   Copyright 2018-2020 The MathWorks, Inc.

%#codegen

    methods
        function obj = insfilterErrorStateCG(varargin)
            obj@fusion.internal.ErrorStateIMUGPSFuserBase(varargin{:});
        end
        
        function cpObj = copy(obj)
            s = saveObject(obj);
            cpObj = fusion.internal.coder.insfilterErrorStateCG( ...
                'ReferenceFrame', obj.ReferenceFrame);
            loadObject(cpObj, s);
        end
    end
    methods (Static, Hidden)
        function name = matlabCodegenUserReadableName
            name = 'insfilterErrorState';
        end
    end
end
