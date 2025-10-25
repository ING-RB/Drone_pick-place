classdef FigureInteraction
    %

    % Do not remove above white space
    
    % Copyright 2023 The MathWorks, Inc.

    properties (Dependent)
        Location
        ScreenLocation
    end
    properties (SetAccess = immutable, GetAccess = private)
        LocationOffset
        Source
    end
    methods
        function obj = FigureInteraction(options)
            obj.LocationOffset = options.LocationOffset;
            obj.Source = options.Source;
        end
        function location = get.Location(obj)

            % Calculate pixel position relative to the parent container
            location =  obj.LocationOffset;
        end
        function location = get.ScreenLocation(obj)

            % Calculate pixel position relative to the screen
            location = obj.Source.Position(1:2) + obj.LocationOffset;
        end
    end
end