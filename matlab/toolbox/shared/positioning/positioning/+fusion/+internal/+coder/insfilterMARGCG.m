classdef (Hidden) insfilterMARGCG < fusion.internal.MARGGPSFuserBase
%   This class is for internal use only. It may be removed in the future.

%   Copyright 2018-2020 The MathWorks, Inc.

%#codegen

    methods
        function obj = insfilterMARGCG(varargin)
            obj@fusion.internal.MARGGPSFuserBase(varargin{:});
        end
        
        function cpObj = copy(obj)        
            s = saveObject(obj);
            cpObj = fusion.internal.coder.insfilterMARGCG( ...
                'ReferenceFrame', obj.ReferenceFrame);
            loadObject(cpObj, s);
        end
    end
    methods (Static, Hidden)
        function name = matlabCodegenUserReadableName
            name = 'insfilterMARG';
        end
    end
end
