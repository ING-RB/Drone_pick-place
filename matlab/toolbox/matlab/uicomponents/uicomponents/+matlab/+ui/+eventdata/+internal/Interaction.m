classdef (Hidden) Interaction
    %

    % Do not remove above white space
    
    % Copyright 2022-2023 The MathWorks, Inc.

    properties (Dependent)
        Location
        ScreenLocation
    end
    properties (SetAccess = immutable, GetAccess = protected)
        LocationOffset
        Source
    end
    methods
        function obj = Interaction(options)
            obj.LocationOffset = options.LocationOffset;
            obj.Source = options.Source;
        end
        function location = get.Location(obj)

            % Calculate pixel position relative to the parent container
            location =  getLocation(obj);
        end
        function location = get.ScreenLocation(obj)

            % Calculate pixel position relative to the screen
            pixelPosition = getpixelposition(obj.Source, true);
            fig = ancestor(obj.Source, 'figure');
            location =  fig.Position(1:2) + pixelPosition(1:2) + obj.LocationOffset;
        end
    end
    methods (Access = protected)

        function location = getLocation(obj)
            location =  obj.Source.Position(1:2) + obj.LocationOffset;
        end
    end
end