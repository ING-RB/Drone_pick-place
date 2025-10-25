classdef ProjectHandlerService < matlab.unittest.internal.services.informalsuite.HandlerService
    %

    % Copyright 2022 The MathWorks, Inc.

    methods
        function handler = getHandler(~)
            handler = matlab.unittest.internal.services.informalsuite.ProjectHandler;
        end
    end
end