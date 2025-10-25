classdef MapAxesAccessor < matlab.plottools.service.accessor.BaseAxesAccessor
    %MAPAXESACCESSOR Provides the methods to access mapaxes properties

    % Copyright 2022-2023 The MathWorks, Inc.

    methods
        function obj = MapAxesAccessor
            obj = obj@matlab.plottools.service.accessor.BaseAxesAccessor;
        end

        function id = getIdentifier(~)
            id = 'map.graphics.axis.MapAxes';
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

        function result = supportsBasicFitting(~)
            result = false;
        end
    end
end