classdef (Hidden) GridLayoutController < matlab.ui.control.internal.controller.ComponentController ...
        & matlab.ui.internal.controller.CanvasController
    % GridLayoutController  Handles grid-specific positioning and row/column events and properties
    
    % Copyright 2018-2024 The MathWorks, Inc.
    properties(Access=private)
        scrollableBehavior
    end
    
    methods
        function hObj = GridLayoutController(model, varargin)
            hObj = hObj@matlab.ui.control.internal.controller.ComponentController(model, varargin{:});
            hObj.scrollableBehavior = matlab.ui.internal.componentframework.services.optional.ScrollableBehaviorAddOn([], []);
        end
        
        function viewPvPairs = getPositionPropertiesForView(obj, propertyNames)
            % Gets all properties for view based related to Size,
            % Location, etc...
            import appdesservices.internal.util.ismemberForStringArrays;
            
            % Get position properties from superclass
            positionViewPvPairs = getPositionPropertiesForView@matlab.ui.control.internal.controller.ComponentController(obj, propertyNames);
            
            % Separate property names and values so we can restructure them
            positionPropertyNames = positionViewPvPairs(1:2:end);
            positionPropertyValues = positionViewPvPairs(2:2:end);
            
            % Remove Size, OuterSize, Location, and OuterLocation because 
            % GridLayout doesn't have them
            excludedPositionProperties = ["Size", "OuterSize", "Location", "OuterLocation"]; 
            isExcluded = ismemberForStringArrays(string(positionPropertyNames), excludedPositionProperties);

            % Remove the names and corresponding values
            positionPropertyNames(isExcluded) = [];
            positionPropertyValues(isExcluded) = [];

            % Bring PV pairs back together
            viewPvPairs = reshape([positionPropertyNames; positionPropertyValues], 1, []);
        end

    end

    methods(Access='protected')
        function propertyNames = getAdditionalPropertyNamesForView(obj)
            propertyNames = getAdditionalPropertyNamesForView@matlab.ui.control.internal.controller.ComponentController(obj);
            
            propertyNames = [propertyNames; {...
                'ScrollableViewportLocation';...
                'ScrollTarget' ...
                }];
        end
        
        function viewPvPairs = getPropertiesForView(obj, propertyNames)
            import appdesservices.internal.util.ismemberForStringArrays;
            
            viewPvPairs = getPropertiesForView@matlab.ui.control.internal.controller.ComponentController(obj, propertyNames);

            viewPvPairs = [viewPvPairs, {'ScrollableViewportLocation', obj.Model.ScrollableViewportLocation}];

            scrollTargetValue = obj.scrollableBehavior.updateScrollTarget(obj.Model);
            if ~isempty(scrollTargetValue)
                viewPvPairs = [viewPvPairs, {'ScrollTarget', scrollTargetValue}];
            end
            
            checkFor = ["ColumnWidth", "RowHeight"]; 
            isPresent = ismemberForStringArrays(checkFor, propertyNames);

            if isPresent(1)
                viewPvPairs = [viewPvPairs, {'ColumnWidth', obj.convert0xTo0px(obj.Model.ColumnWidth)}];
            end
            
            if isPresent(2)
                viewPvPairs = [viewPvPairs, {'RowHeight', obj.convert0xTo0px(obj.Model.RowHeight)}];
            end
            
        end
        
        function handleEvent(obj, src, event)
            handleEvent@matlab.ui.control.internal.controller.ComponentController(obj, src, event);

            if obj.scrollableBehavior.handleClientScrollEvent(src, event.Data, obj.Model)
                return;
            end
            
            switch(event.Data.Name)
                case 'positionChangedEvent'
                    outerValUnits = event.Data.valuesInUnits.OuterPosition;
                    
                    % Ensure value was sent in pixels
                    assert(strcmpi(outerValUnits.Units, 'pixels'), 'Position value is expected to be in pixels');

                    if isfield(event.Data, 'ContentAreaPosition')
                        obj.Model.setContentSizeFromClient(event.Data.ContentAreaPosition);
                    end
                    if isfield(event.Data, 'HorizontalScrollbarInset') && isfield(event.Data, 'VerticalScrollbarInset')
                        obj.Model.setScrollbarSizes(event.Data.HorizontalScrollbarInset, event.Data.VerticalScrollbarInset);
                    end
                    
                    newPos = outerValUnits.Value;
                    
                    % Convert from (0,0) to (1,1) origin
                    newPos = matlab.ui.control.internal.controller.PositionUtils.convertFromZeroToOneOrigin(newPos);
                    
                    obj.Model.setPositionFromClient(newPos);
                    
                case 'viewReady'
                    obj.setViewReady();
            end
        end

        function setViewReady(obj)
            obj.Model.setViewReady( true );
            notify( obj.Model, 'ViewReady' );
        end
    end

    methods(Hidden, Access = 'public')
        function isChildOrderReversed = isChildOrderReversed(obj)
           isChildOrderReversed = false; 
        end
    end
    
    methods(Static)
        
        function newSizes = convert0xTo0px (sizes)
            % Converts track sizes that are '0x' to 0 (pixels)
            
            newSizes = sizes;
            for k = 1:length(sizes)
                if strcmp(sizes{k}(end), 'x')
                    weight = str2double(sizes{k}(1:end-1));
                    if weight == 0
                        % Only check against zero weight because:
                        %  - track sizes have already been validated by the
                        %  model and
                        %  - strings have been converted to char vectors
                        %  - weight have be converted to numbers without
                        %  leading / trailing 0, etc via str2double
                        newSizes{k} = 0;
                    end
                end
            end
        end
    end
end
