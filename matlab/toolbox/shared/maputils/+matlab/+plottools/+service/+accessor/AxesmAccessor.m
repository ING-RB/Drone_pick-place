classdef AxesmAccessor < matlab.plottools.service.accessor.BaseAxesAccessor
    %

    % Copyright 2024 The MathWorks, Inc.

    methods
        function obj = AxesmAccessor
            obj = obj@matlab.plottools.service.accessor.BaseAxesAccessor;
        end

        function id = getIdentifier(~)
            id = 'axesm-based map';
        end
    end

    % SupportsFeature Method Overrides
    methods(Access = protected)
        function result = supportsTitle(~)
            result = true;
        end

        function result = supportsSubtitle(~)
            result = true;
        end

        function result = supportsLegend(~)
            result = true;
        end

        function result = supportsColorbar(~)
            result = true;
        end

        function result = supportsXLabel(~)
            result = false;
        end

        function result = supportsYLabel(~)
            result = false;
        end

        function result = supportsZLabel(~)
            result = false;
        end

        function result = supportsGrid(~)
            result = false;
        end

        function result = supportsXGrid(~)
            result = false;
        end

        function result = supportsYGrid(~)
            result = false;
        end

        function result = supportsZGrid(~)
            result = false;
        end

        function result = supportsBasicFitting(~)
            result = false;
        end

        function result = supportsDataStats(~)
            result = false;
        end

        function result = supportsDataLinking(~)
            result = false;
        end

        function result = supportsCameraTools(~)
            result = false;
        end 
    end
end