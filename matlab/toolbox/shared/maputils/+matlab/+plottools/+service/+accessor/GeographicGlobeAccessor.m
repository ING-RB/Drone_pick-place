classdef GeographicGlobeAccessor < matlab.plottools.service.accessor.BaseAxesAccessor
    %GeographicGlobeAccessor Class for geographic globe accessor objects

    % Copyright 2024 The MathWorks, Inc.
    methods
        function obj = GeographicGlobeAccessor()
            obj = obj@matlab.plottools.service.accessor.BaseAxesAccessor;
        end

        function id = getIdentifier(~)
            id = 'globe.graphics.GeographicGlobe';
        end
    end
    
    % SupportsFeature Method Overrides
    methods(Access = protected)
        function result = supportsTitle(~)
            result = false;
        end

        function result = supportsSubtitle(~)
            result = false;
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

        function result = supportsRGrid(~)
            result = false;
        end

        function result = supportsThetaGrid(~)
            result = false;
        end

        function result = supportsLegend(~)
            result = false;
        end

        function result = supportsColorbar(~)
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

        function result = supportsLight(~)
            result = false;
        end
    end
end
