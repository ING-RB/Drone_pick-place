classdef (Hidden) ahrs10filtercg < fusion.internal.AHRS10FilterBase
%   This class is for internal use only. It may be removed in the future.

%   Copyright 2018-2020 The MathWorks, Inc.

%#codegen

    methods
        function obj = ahrs10filtercg(varargin)
            obj@fusion.internal.AHRS10FilterBase(varargin{:});
        end
        
        function cpObj = copy(obj)
            s = saveObject(obj);
            cpObj = fusion.internal.coder.ahrs10filtercg( ...
                'ReferenceFrame', obj.ReferenceFrame);
            loadObject(cpObj, s);
        end
    end
    methods (Static, Hidden)
        function name = matlabCodegenUserReadableName
            name = 'ahrs10filter';
        end
    end
end
