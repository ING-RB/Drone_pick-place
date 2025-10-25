classdef ScrollableBehaviorAddOn < matlab.ui.internal.componentframework.services.optional.BehaviorAddOn & ...
        matlab.ui.internal.componentframework.services.optional.ControllerInterface
% SCROLLABLEBEHAVIORADDON - Add-on class for controllers of containers that support scrolling

%   Copyright 2018-2023 The MathWorks, Inc.

    properties(Access=private)
        EventHandlingService
        PendingScrollTargets = {}
    end

    properties(Dependent, Hidden)
        ScrollTargetQueueSize
    end
    
    methods
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         %
         %  Method:  Constructor                     
         %
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         function this = ScrollableBehaviorAddOn( propManagementService, eventHandlingService )
           % Super constructor
           this = this@matlab.ui.internal.componentframework.services.optional.BehaviorAddOn( propManagementService );
           this.EventHandlingService = eventHandlingService;
         end

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         %
         %  Method:      updateScrollTarget
         %
         %  Description: Converts the ScrollTarget property to a view-compatible value
         %
         %  Outputs:     Value to be set on the view model
         %
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         function result = updateScrollTarget( obj, model )
            result = obj.getScrollTargetViewProperty(model);
            if ~isempty(result)
                queueableValue = obj.getQueueableValue(result);
                if ~isempty(queueableValue)
                    obj.PendingScrollTargets{end+1} = queueableValue;
                end
            end
        end
        
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         %
         %  Method:      handleClientScrollEvent
         %
         %  Description: Responds to scroll events from the client by updating the
         %               hidden scroll location property
         %
         %  Outputs:     Boolean indicator of whether the event was handled
         %
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         function handled = handleClientScrollEvent( obj, ~, eventStructure, model )
            handled = false;
            if strcmp(eventStructure.Name, 'scrollLocationChangedEvent')
                handled = true;
                scrollToResolved = isfield(eventStructure, 'ScrollToResolved') && eventStructure.ScrollToResolved;
                model.setScrollLocationFromClient(eventStructure.ScrollLocation, scrollToResolved);
            elseif strcmp(eventStructure.Name, 'scrollLocationChangingEvent')
                handled = true;
                model.notifyScrollLocationChangingFromClient(eventStructure.ScrollLocation);
            elseif strcmp(eventStructure.Name, 'scrollContentsSizeChangedEvent')
                model.setContentSizeFromClient(eventStructure.ContentAreaPosition);
                model.setScrollbarSizes(eventStructure.HorizontalScrollbarInset, eventStructure.VerticalScrollbarInset);
                handled = true;
            elseif strcmp(eventStructure.Name, 'scrollToTargetComplete')
                index = find(strcmp(obj.PendingScrollTargets, obj.getQueueableValue(eventStructure.target)), 1);
                if ~isempty(index)
                    obj.PendingScrollTargets = obj.PendingScrollTargets(index+1:end);
                end
                if isempty(obj.PendingScrollTargets)
                    model.ScrollTarget = [];
                end
                model.setScrollLocationFromClient(eventStructure.scrollLocation, true);
                handled = true;
            end
         end

         function value = get.ScrollTargetQueueSize(obj)
             value = numel(obj.PendingScrollTargets);
         end
    end
    
    methods(Access=protected)
        
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         %
         %  Method:      defineViewProperties                     
         %
         %  Description: Within the context of MVC ( Model-View-Controller )   
         %               software paradigm, this is the method the "Controller"
         %               layer uses to define which properties will be consumed by
         %               the web-based user interface.
         %  Inputs:      None 
         %  Outputs:     None 
         %
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         function defineViewProperties( ~, propManagementService )
             % Define model properties that concern the view. 
             propManagementService.defineViewProperty( 'Scrollable' );
             propManagementService.defineViewProperty( 'ScrollTarget' );

         end

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         %
         %  Method:      defineRequireUpdateProperties
         %  Description: Within the context of MVC ( Model-View-Controller )
    	 %               software paradigm, this is the method the "Controller"
    	 %               layer uses to establish property which needs updates
    	 %               before updating them to view.
         %  Inputs:      None 
         %  Outputs:     None 
         %
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

         function defineRequireUpdateProperties(  ~, propManagementService  )
             propManagementService.defineRequireUpdateProperty( 'ScrollTarget' );
         end
    end

    methods(Static)
        function id = getComponentViewModelId(component)
            id = '';
            if ~isempty(component)
                controller = getControllerHandle(component);
                if ~isempty(controller)
                    id = controller.ViewModel.Id;
                end
            end
        end

        function value = getScrollTargetViewProperty(model)
            import matlab.ui.internal.componentframework.services.optional.ScrollableBehaviorAddOn.getComponentViewModelId;
            if isa(model.ScrollTarget, 'matlab.ui.control.WebComponent')
                value = getComponentViewModelId(model.ScrollTarget);
            elseif iscell(model.ScrollTarget)
                value = cellfun(@char, model.ScrollTarget, 'UniformOutput', false);
            else
                value = model.ScrollTarget;
            end
        end

        function value = getQueueableValue(target)
            if iscell(target)
                temp = cellfun(@char, target, 'UniformOutput', false);
                value = [temp{:}];
            elseif isstring(target)
                value = char(strjoin(target, ''));
            elseif ischar(target)
                value = target;
            else
                % Mostly to guard against deleted handles. Handles are queried
                % for their view model UUID which is convertible to a string
                % and is used as the identifier. Deleted handles can get to
                % this point so avoid attempting to convert them to a char array.
                value = [];
            end
        end
    end
end
