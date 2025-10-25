classdef MATLABOnlineHelper < ros.internal.utilities.MATLABOnlineHelperInterface
    %ROSENVIRONMENT Helper class for MATLAB Online
    %   

    %  Copyright 2023 The MathWorks, Inc.
    properties 
        PythonPath = '/usr/bin/python3.10';
        PipUrl = 'https://bootstrap.pypa.io/get-pip.py'
    end


    methods (Static)
        function ret = isMATLABOnline()
            %ISMATLABONLINE Return true if we are in MATLAB Online
            ret = connector.internal.Worker.isMATLABOnline;
        end

        function ret = isJSD()
            ret = logical(feature('webui'));
        end
    end
end