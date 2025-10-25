%

%   Copyright 2023 The MathWorks, Inc.
classdef (Abstract) ResultFooterService < matlab.automation.internal.services.Service

    methods (Abstract)
        footerStr = getFooter(this, resObj, variableName)
    end

    methods (Sealed)
        function fulfill(~, ~)
            % No-op fulfill, call getFooter instead
        end
    end
end
