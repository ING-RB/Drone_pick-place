classdef MATLABChecker < handle
    %MATLABCHECKER Utility functions to check MATLAB GUI version
    %   Check if current MATLAB is a Java Desktop, JSD or MO

    %   Copyright 2023 The MathWorks, Inc.

    methods (Static)
        function isJavaDesktop = isJavaDesktop()
            isJavaDesktop = ~appdesservices.internal.util.MATLABChecker.isJSD() && ...
                ~appdesservices.internal.util.MATLABChecker.isMATLABOnline();
        end

        function isJSD = isJSD()
            isJSD = logical(feature("webui"));
        end

        function isMO = isMATLABOnline()
            import matlab.internal.capability.Capability;
            isLocalClient = Capability.isSupported(Capability.LocalClient);
            isMO = ~isLocalClient;
        end
    end
end