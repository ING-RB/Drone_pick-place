classdef MATLABOnlineHelperInterface 
    %MATLABOnlineHelperInterface Interface for MATLAB Online helper class
    %   

    %  Copyright 2023 The MathWorks, Inc.
    properties (Abstract)
        PythonPath
        PipUrl
    end

    methods (Abstract,Static)
        ret = isMATLABOnline();
        ret = isJSD();
    end
end