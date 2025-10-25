classdef (Hidden) insfilterAsyncCG < fusion.internal.AsyncMARGGPSFuserBase
%   This class is for internal use only. It may be removed in the future.

%   Copyright 2018-2020 The MathWorks, Inc.

%#codegen

    methods
        function obj = insfilterAsyncCG(varargin)
            obj@fusion.internal.AsyncMARGGPSFuserBase(varargin{:});
        end
        
        function cpObj = copy(obj)
            s = saveObject(obj);
            cpObj = fusion.internal.coder.insfilterAsyncCG( ...
                'ReferenceFrame', obj.ReferenceFrame);
            loadObject(cpObj, s);
        end
    end
    methods (Static, Hidden)
        function name = matlabCodegenUserReadableName
            name = 'insfilterAsync';
        end
    end
end
