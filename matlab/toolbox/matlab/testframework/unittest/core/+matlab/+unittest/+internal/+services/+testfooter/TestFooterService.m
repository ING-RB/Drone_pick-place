classdef TestFooterService < matlab.unittest.internal.services.Service
    %

    % Copyright 2022 The MathWorks, Inc.

    methods (Abstract, Access=protected)
        % footer = getFooter(service, suite, variableName) returns a
        % FormattableString summarizing an attribute of the suite content.
        footer = getFooter(service, suite, variableName);
    end

    methods (Sealed)
        function fulfill(services, liaison)
            for idx = 1:numel(services)
                liaison.Footers(end+1) = services(idx).getFooter(liaison.Suite, liaison.VariableName);
            end
        end
    end
end
