classdef ProceduralFileInformation < matlab.unittest.internal.fileinformation.FileInformation
    %

    %  Copyright 2017-2021 The MathWorks, Inc.
    
    properties (SetAccess = private)
        MethodList  matlab.unittest.internal.fileinformation.CodeSegmentInformation = matlab.unittest.internal.fileinformation.MethodInformation.empty(1,0);
    end
    
    methods (Access = ?matlab.unittest.internal.fileinformation.FileInformation)
        function info = ProceduralFileInformation(parseTree)
            info = info@matlab.unittest.internal.fileinformation.FileInformation(parseTree);
        end
    end
end

