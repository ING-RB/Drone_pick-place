classdef PolarAxesInteractor < matlab.uiautomation.internal.interactors.AbstractAxesInteractor
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2019 The MathWorks, Inc.

    methods
        
        function uipress(actor, varargin)
            
            narginchk(1,2)
            
            pt = actor.parseCoordinatesAndGetPoint(varargin{:});
            
            [axesID, container]  = actor.getAxesDispatchData(); 
            
            actor.Dispatcher.dispatch(container, 'uipress', ...
                            'axesType', 'PolarAxes', ...
                            'axesID', axesID, ...
                            'X', pt(1), ...
                            'Y', pt(2), ...
                            'Z', pt(3));        
        end
        
        function uihover(actor, varargin)
            
            narginchk(1,2)
            
            pt = actor.parseCoordinatesAndGetPoint(varargin{:});
            
            [axesID, container]  = actor.getAxesDispatchData(); 
            
            actor.Dispatcher.dispatch(container, 'uihover', ...
                            'axesType', 'PolarAxes', ...
                            'axesID', axesID, ...
                            'X', pt(1), ...
                            'Y', pt(2), ...
                            'Z', pt(3));  
        end

    end
    
    methods (Access = protected)
        
        function centerCoords  = getDataSpaceCenter(actor)
            % We dont caculate mean for Polar axes. 
            % We press on the visual center. 
            
            pax = actor.Component;
            RLim = pax.RLim;
            centerCoords = [0 RLim(1)];
            
            if strcmp(pax.RDir, 'reverse')
                % Calculate Visual center for reverse R direction
                centerCoords = [0 RLim(2)];
            end
        end
        
        function RTheta = validateCoordinate(~, coord)
            % Validate correct coordinate inputs, as well as providing a "free" z-coord
            % if in 2D.
            
            validateattributes(coord, {'numeric'}, {'row', 'real', 'nonnan', 'finite'});
            L = length(coord);
            if ~any(L == [2 3])
                error( message('MATLAB:uiautomation:Driver:InvalidAxesCoordinate') );
            end
            RTheta = coord;
        end

        function bool = isSSR(~)
            % always uses server-side rendering
            bool = true;
        end
        
    end
    
end