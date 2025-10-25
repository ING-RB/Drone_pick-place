classdef (Hidden) insfilterNonholonomicCG < ...
        fusion.internal.NHConstrainedIMUGPSFuserBase
%insfilterNonholonomicCG - Codegen class for insfilterNonholonomic
%
%   This class is for internal use only. It may be removed in the future.

%   Copyright 2018-2020 The MathWorks, Inc.

%#codegen

    methods
        function obj = insfilterNonholonomicCG(varargin)
            obj@fusion.internal.NHConstrainedIMUGPSFuserBase(varargin{:});
        end
        
        function cpObj = copy(obj)
            s = saveObject(obj);
            cpObj = fusion.internal.coder.insfilterNonholonomicCG( ...
                'ReferenceFrame', obj.ReferenceFrame);
            loadObject(cpObj, s);
        end
    end
    
    methods (Static, Hidden)
        function name = matlabCodegenUserReadableName
            name = 'insfilterNonholonomic';
        end
    end
end
