classdef (Hidden) AccordionController < matlab.ui.control.internal.controller.ComponentController
    %ACCORDIONCONTROLLER Handles specific controls (eg: scroll) for Accordion

    % Copyright 2023 The MathWorks, Inc.
    properties(Access=private)
        scrollableBehavior
    end

    methods
        function hObj = AccordionController(model, varargin)
            hObj = hObj@matlab.ui.control.internal.controller.ComponentController(model, varargin{:});
            hObj.scrollableBehavior = matlab.ui.internal.componentframework.services.optional.ScrollableBehaviorAddOn([], []);
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
            import matlab.ui.internal.componentframework.services.optional.ScrollableBehaviorAddOn.getScrollTargetViewProperty;
            
            viewPvPairs = getPropertiesForView@matlab.ui.control.internal.controller.ComponentController(obj, propertyNames);

            viewPvPairs = [viewPvPairs, {'ScrollableViewportLocation', obj.Model.ScrollableViewportLocation}];

            scrollTargetValue = obj.scrollableBehavior.updateScrollTarget(obj.Model);
            if ~isempty(scrollTargetValue)
                viewPvPairs = [viewPvPairs, {'ScrollTarget', scrollTargetValue}];
            end
        end
        
        function handleEvent(obj, src, event)
            handleEvent@matlab.ui.control.internal.controller.ComponentController(obj, src, event);

            if obj.scrollableBehavior.handleClientScrollEvent(src, event.Data, obj.Model);
                return;
            end
        end

    end

end