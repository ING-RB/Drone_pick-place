classdef (Hidden) ComponentController < ...
        appdesservices.internal.interfaces.controller.AbstractController & ...
        appdesservices.internal.interfaces.controller.ServerSidePropertyHandlingController  & ...
        matlab.ui.control.internal.controller.mixin.PositionableComponentController  & ...
        matlab.ui.control.internal.controller.mixin.HGCommonPropertiesComponentController & ...
        matlab.ui.internal.componentframework.services.optional.ControllerInterface  & ...
        matlab.ui.control.internal.controller.mixin.LayoutableController & ...
        matlab.ui.control.internal.controller.mixin.HasContextMenuController & ...
        matlab.ui.internal.componentframework.services.optional.EventDispatcherAddOn
    
    
    % appdesservices.internal.interfaces.controller.ComponentController
    
    % COMPONENTCONTROLLER Base Class for all HMI Component Controllers.
    %
    % This class provides the following:
    %
    % - creation of all ProxyView's by delegating to the
    %   HmiProxyViewFactoryManager
    %
    % - provides an empty implementation of handleEvent().  Interactive
    %   components should overide this method as needed.
    
    % Copyright 2011-2024 The MathWorks, Inc.
    
    properties
        % List of numeric properties that will be automatically converted
        % when coming from the client, before being set on the model
        %
        % This property is used by the handler for 'PropertyEditorEdited'
        % to convert event data to numeric values and save controller
        % subclasses from writing boiler plate.
        %
        % Controller subclasses should concatenate any specific properties
        % they want handled onto this property.
        %
        % Its use could be expanded to other places as well, such as
        % responding to any property edit, and not just
        % 'PropertyEditorEdited' events.
        NumericProperties = {'Position', 'InnerPosition', 'OuterPosition'};
    end
    
    methods(Hidden, Access = 'public')
        function obj = ComponentController(varargin)
            obj@appdesservices.internal.interfaces.controller.AbstractController(varargin{:});
        end
        
        function move(obj, newParent)
            % MOVE(OBJ, NEWPARENT) tells the Controller to react to a new
            % parent changing
            %
            % 'newParent' is the model's new parent
            
            % Update this objects parent controller
            obj.ParentController = newParent.getControllerHandle();
            
            % Tell the view to move
            move(obj.ProxyView, newParent.getControllerHandle().ProxyView);
            
        end
        
        function propertiesForView = getPropertyNamesToProcessAtRuntime(obj)
            % GETPROPERTYNAMESTOPROCESSATRUNTIME - These are properties
            % eligible to be processed by handlePropertiesChanged in the
            % runtimecontrollers.
            % This is used by the getControllerPropertiesForViewPopulation
            % function which stores the properties per component
            
            propertiesForView = properties(obj.Model);
                        
            % Remove properties that are not honored by view
            ignoredPropertyNames = getIgnoredPropertyNamesForView(obj);
            
            % Add back in the position properties
            propertiesForView = setdiff(string(propertiesForView), string(ignoredPropertyNames));
            
            % Add controller specified additional property names
            additionalProperties = getAdditionalPropertyNamesForView(obj);
            propertiesForView = union(propertiesForView, additionalProperties);

            % Verify the property has a defining class
            % Remove dynamic properties from consideration for view
            for index = numel(propertiesForView):-1:1
                propInfo = findprop(obj.Model, propertiesForView{index});
                
                if isa(propInfo, 'meta.DynamicProperty')
                    
                    % Remove dynamic property
                    propertiesForView(index) = [];
                end
            end
            
        end
        
        function excludedPropertyNames = getExcludedComponentSpecificPropertyNamesForView(obj)
            % GETEXCLUDEDCOMPONENTSPECIFICPROPERTYNAMESFORVIEW - By default there are no
            % component specific properties, but components can add them.  One reason a
            % property may not be sent at runtime is if it requires a lot of memory and
            % has no role at runtime.
            
            excludedPropertyNames = [];
        end

        function component = getComponentToApplyButtonEvent(obj, event)
            % GETCOMPONENTTOAPPLYBUTTONEVENT - Calculate what the
            % current object should be given the event information.
            % Typically the current object will be the model associated
            % with the controller
            % Allow controllers to override this functionality.        
            component = obj.Model;
        end

        function component = getComponentToApplyContextMenuEvent(obj, event)
            % GETCOMPONENTTOAPPLYCONTEXTMENUEVENT - Calculate what the
            % current object should be given the event information.
            % Typically the current object will be the model associated
            % with the controller
            % Allow controllers to override this functionality.        
            component = obj.Model;
        end
    end
    methods (Access = protected)
        function newInteractionInformation = getComponentInteractionInformation(obj, event, interactionInformation)
            % GETCOMPONENTSPECIFICINTERACTIONINFORMATION - Get
            % InteractionInformation object that is specific to this component.
            % Typically, components do not have any special
            % InteractionInformation to add, so this is no-op by default.
            % Allow controllers to override this functionality
            newInteractionInformation = matlab.ui.eventdata.ComponentInteraction(interactionInformation);
        end        
    end
    
    methods(Hidden, Sealed = true)
        
        function excludedPropertyNames = getExcludedPropertyNamesToProcessAtRuntime(obj)
            % Get the list of properties that need to be excluded from the
            % properties sent to the view at Run time
            % (The list is shorter than at design time, because
            % the processed list of properties to be sent to the view
            % has already been significantly trimmed)
            
            excludedPropertyNames = {};
            
            % Position related properties
            excludedPropertyNames = [excludedPropertyNames; ...
                obj.getExcludedPositionPropertyNamesForView();...
                ];
            
            % Layout related properties
            excludedPropertyNames = [excludedPropertyNames; ...
                obj.getExcludedLayoutPropertyNamesForView();...
                ];
            
            % ContextMenu related properties
            excludedPropertyNames = [excludedPropertyNames; ...
                obj.getExcludedContextMenuPropertyNamesForView();...
                ];
            
            % Allow components to add restricted properties
            excludedPropertyNames = [excludedPropertyNames; ...
                obj.getExcludedComponentSpecificPropertyNamesForView();...
                ];
            
            % Identifier related properties
            % 'Tag' is sent to the client at design time.  Since 'Tag' has
            % no value at run-time, it should be excluded from the properties
            % sent to the view.
            excludedPropertyNames = [excludedPropertyNames; ...
                'Tag';...
                ];
            
        end
    end
    
    methods(Access = 'protected')
        
        function additionalPropertyNames = getAdditionalPropertyNamesForView(obj)
            % Get the list of additional properties to be sent to the view
            
            additionalPropertyNames = {};
            
            % Position related properties
            additionalPropertyNames = [additionalPropertyNames; ...
                obj.getAdditonalPositionPropertyNamesForView();...
                ];
            
            % Most but not all components have Layout property.
            if (obj.Model.isprop('Layout'))
                additionalPropertyNames = [additionalPropertyNames; ...
                    matlab.ui.control.internal.controller.mixin.LayoutableController.getAdditonalLayoutPropertyNamesForView(); ...
                    ];
            end
            
            % ContextMenu property
            additionalPropertyNames = [additionalPropertyNames; ...
                obj.getAdditonalContextMenuPropertyNamesForView();...
                ];
            
            additionalPropertyNames = [additionalPropertyNames; ...
                obj.getAdditonalComponentSpecificPropertyNamesForView();...
                ];
            
        end
        
        function excludedPropertyNames = getExcludedPropertyNamesForView(obj)
            % Get the list of properties that need to be excluded from the
            % properties sent to the view at Design time
            
            excludedPropertyNames = {};
            
            % Handles to other objects
            excludedPropertyNames = [excludedPropertyNames; {...
                'Parent'; ...
                'Children'; ...
                }];
            
            % HG properties
            excludedPropertyNames = [excludedPropertyNames; ...
                obj.getExcludedHGCommonPropertyNamesForView();...
                ];
            
            % Position related properties
            excludedPropertyNames = [excludedPropertyNames; ...
                obj.getExcludedPositionPropertyNamesForView();...
                ];
            
            % Layout related properties
            excludedPropertyNames = [excludedPropertyNames; ...
                obj.getExcludedLayoutPropertyNamesForView();...
                ];
            
            % ContextMenu related properties
            excludedPropertyNames = [excludedPropertyNames; ...
                obj.getExcludedContextMenuPropertyNamesForView();...
                ];
        end
        
        function viewPvPairs = getPropertiesForView(obj, propertyNames)
            % GETPROPERTIESFORVIEW(OBJ, PROPERTYNAME) returns view-specific
            % properties, given the PROPERTYNAMES
            %
            % Inputs:
            %
            %   propertyNames - list of properties that changed in the
            %                   component model.
            %
            % Outputs:
            %
            %   viewPvPairs   - list of {name, value, name, value} pairs
            %                   that should be given to the view.
            
            viewPvPairs = {};
            
            % Size, Location, OuterSize, OuterLocation, AspectRatioLimits, Parent
            viewPvPairs = [viewPvPairs, ...
                getPositionPropertiesForView(obj, propertyNames);
                ];
            
            % LayoutConstraints
            viewPvPairs = [viewPvPairs, ...
                getLayoutConstraintsForView(obj, propertyNames);
                ];
            
            % ContextMenu Property
            viewPvPairs = [viewPvPairs, ...
                getContextMenuPropertyForView(obj, propertyNames);
                ];
        end
        
        function handleEvent(obj, src, event)
            
            % Allow super classes to handle their events
            positionEventHandled = handleEvent@matlab.ui.control.internal.controller.mixin.PositionableComponentController(obj, src, event);
            contextMenuEventHandled = handleEvent@matlab.ui.control.internal.controller.mixin.HasContextMenuController(obj, src, event);

            
            if(positionEventHandled || contextMenuEventHandled)
                return;
            end
            
            obj.handleClientEvent(src, event);
            % Handle changes in the property editor that needs a
            % server side validation
            if(strcmp(event.Data.Name, 'PropertyEditorEdited'))
                
                propertyName = event.Data.PropertyName;
                propertyValue = event.Data.PropertyValue;
                
                if(any(strcmp(obj.NumericProperties, propertyName)))
                    propertyValue = convertClientNumbertoServerNumber(obj, propertyValue);
                end
                
                setModelProperty(obj, propertyName, propertyValue, event);
            end
        end
        
        function handleClientEvent( obj, ~, eventStructure)
            timeStamp = -1;
            switch ( eventStructure.Data.Name )
                case {'processButtonEvent', 'processMouseMoveEvent'}
                    if isfield(eventStructure.Data.data, 'timeStamp')
                        timeStamp = eventStructure.Data.data.timeStamp;
                    end
                    % decide the selectionType based on the button value
                    switch eventStructure.Data.data.button
                        case 0
                            button = 'left';
                        case 2
                            button = 'right';
                        case 1
                            button = 'middle';
                        otherwise
                            button = 'left';
                    end
                    component = getComponentToApplyButtonEvent(obj, eventStructure);
                    component.processButtonEventFromClient(eventStructure.Data.data.type, ...
                        eventStructure.Data.data.position, ...
                        eventStructure.Data.data.selectionType, ...
                        button, ...
                        timeStamp);
                otherwise
                    %Noop
            end

            % After all matlab events for this client side event have been
            % emitted and callbacks processed, send an event to the client
            % if the event is registered to use an event coalescing
            % mechanism.
            % Need to check if obj and ViewModel are valid or not because
            % the user's callback could delete the app or the component
            % see g1336677
            isFromClient = any(eventStructure.isFromClient);
            coalescedEventIsField = isfield(eventStructure.Data, 'CoalescedEvent');
            if(isvalid(obj) && isFromClient && coalescedEventIsField && eventStructure.Data.CoalescedEvent)
                obj.sendFlushEventToClient(obj.Model, eventStructure.Data.Name);
            end
        end
        
        
    
        function handlePropertiesChanged(obj, changedPropertiesStruct)
            % Handles properties changed from client
            
            % Check for properties with a corresponding 'Mode' property
            %
            % This check is to explicitly handle the case when the client
            % is sending a property change struct like:
            %
            % XLim      : [0 100]
            % XLimMode  : 'auto'
            % ...
            %
            % or
            %
            % Limits    : [0, 100]
            % MajorTicks: 0:20:100
            % ...
            %
            % In the case where the mode is 'auto', the property values are
            % for the sibling property (XLim) are there just beacuse the
            % view needs them, and we do not want to overwrite what the
            % Model currently has.
            %
            % In the case of dependent properties like Limits and
            % MajorTicks, the mode is in 'auto' but might not have been
            % passed in changedPropertiesStruct if the mode was already
            % 'auto' (it is filtered out by peer node layer if unchanged).
            % Althought the mode is not passed in, we need to check if the
            % mode is 'auto' and if so, not explicitely set it on the model
            % (to avoid flipping the mode to 'manual' (see g1044814)
            %
            % Therefore, explicitly look for properties with a 'Mode' property.
            % If the mode property is 'auto', then exclude the sibling from
            % being set and let 'auto' take over
            includeHiddenProperty = true;
            priorModePropertyOnModel = false;
            changedPropertiesStruct = obj.handleChangedPropertiesWithMode(obj.Model, changedPropertiesStruct, includeHiddenProperty, priorModePropertyOnModel);
            
            % 'BeingDeleted' is a readonly property that should not be set on the model.
            % AbstractComponent owns adding 'BeingDeleted' which is the
            % highest UIComponent model class (not part of appdesservices)
            % ComponentController will remove the property because it is
            % the highest UIComponent controller (not part of
            % appdesservices
            
            readOnlyProperty = 'BeingDeleted';
            if(isfield(changedPropertiesStruct, readOnlyProperty))
                changedPropertiesStruct = rmfield(changedPropertiesStruct, readOnlyProperty);
            end
            % Allow super classes to handle properties changed
            unHandledProperties = handlePropertiesChanged@matlab.ui.control.internal.controller.mixin.PositionableComponentController(obj, changedPropertiesStruct);
            handlePropertiesChanged@appdesservices.internal.interfaces.controller.AbstractController(obj, unHandledProperties);
        end
        
        function propertyNames = getAdditonalComponentSpecificPropertyNamesForView(obj)
            % GETADDITIONALCOMPONENTSPECIFICPROPERTYNAMESFORVIEW - Specify
            % per component if there are any non-public properties that
            % should be sent to the view at runtime.
            propertyNames = [];
        end
    end
    
    methods(Access = ?matlab.ui.internal.componentframework.services.optional.ControllerInterface)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Methods that a controller mixin may need direct access to
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        function handleUserInteraction(obj, clientEventName, eventData, callbackInfo)
            % Method to be called by the subclasses when handling a user
            % interaction that results in either:
            % - a user callback executing  (e.g. ButtonPushedFcn)
            % - a property update and a user callback executing (e.g.
            % ValueChangedFcn)
            % - any number greater than 2 of the above (e.g. 'mouseclicked'
            % results in 2 callbacks)
            %
            % Typically, the subclasses would implement handleEvent, and in
            % the case of a user interaction, call handleUserInteraction.
            %
            % INPUTS:
            %
            %  - clientEventName:  event name of the client side event
            %                       that this is a response to
            %
            %  - eventData: event data of the client side event that this
            %               is a response to
            %
            %  - as many cells as the number of callbacks to execute.
            %  Minimum is 1.
            %  See executeUserCallback for the formatting of each cell.
            %
            % Example:
            %
            % obj.handleUserInteraction(...
            %       'mousedragging', ...
            %       event.Data, ...
            %       {'ValueChanging', eventData}, ...
            %       {'ValueChanged', eventData, 'Value', newValue}, ...
            %       );
            
            assert(nargin == 4);           
            
            obj.Model.executeUserCallback(callbackInfo{:});

            if(~isvalid(obj))
                % It is possible the user callback deleted the component
                %
                % If so, don't do any more
                return;
            end

            % Force the view to process the value update before
            % emitting the event.
            % If the property is revered to its old value in a callback
            % (its own or from another component),
            % the visual might not update because of the peer node
            % coalescing events from property sets.
            % Ensure that the visual will react to a potential
            % reversion by forcing the view to process the current
            % value.
            %
            % We don't need to specify any property names in
            % 'refreshProperties' because simply sending an event
            % flushes the propertiesSet event queue. If we explicitly
            % passed in the propertyName, the view would refresh
            % twice in the case of the reversion from the callback of
            % another component.
            %
            % see g1124873 and g1218934
            
            obj.refreshProperties({});


            % After all matlab events for this client side event have been
            % emitted and callbacks processed, send an event to the client
            % if the event is registered to use an event coalescing
            % mechanism.
            % Need to check if obj and ViewModel are valid or not because
            % the user's callback could delete the app or the component
            % see g1336677
            coalescedEventIsField = isfield(eventData, 'CoalescedEvent');
            if(isvalid(obj) && coalescedEventIsField && eventData.CoalescedEvent)
                obj.sendFlushEventToClient(obj.Model, clientEventName);
            end
            
        end
    end
    methods(Access = private)
        
        function propertyNames = getExcludedCallbackPropertyNamesForView(obj)
            
            % By Convention, all callback names end with 'Fcn'
            props = properties(obj.Model);
            propertyNames = props(endsWith(props, 'Fcn'));
            
        end
        
        function ignoredPropertyNames = getIgnoredPropertyNamesForView(obj)
            % Get the list of properties that need to be excluded from the
            % properties sent to the view
            
            ignoredPropertyNames = {};
            
            % Handles to other objects
            ignoredPropertyNames = [ignoredPropertyNames; {...
                'Parent'; ...
                'Children'; ...
                }];
            
            % HG properties
            ignoredPropertyNames = [ignoredPropertyNames; ...
                obj.getExcludedHGCommonPropertyNamesForView();...
                "BusyAction"; ...    % GraphicsCoreProperties
                "Interruptible"; ... % GraphicsCoreProperties
                "HandleVisibility";...% GraphicsCoreProperties
                ];
            
            ignoredPropertyNames = [ignoredPropertyNames; ...
                obj.getExcludedCallbackPropertyNamesForView();...
                ];
            
            ignoredPropertyNames = [ignoredPropertyNames; ...
                "UserData";...% UserData is not required by the view
                ];
            
        end
    end
    methods(Access = {...
            ?appdesservices.internal.interfaces.controller.AbstractControllerMixin, ...
            ?appdesservices.internal.interfaces.controller.AbstractController
            })
        
        function setModelProperty(obj, propertyName, propertyValue, event)
            % Convience function used to set a model property.
            %
            % Passes through to parent class and consolodates the
            % extraction of the command ID, model
            
            commandId = event.Data.CommandId;
            model = obj.Model;
            
            setServerSideProperty(obj, model, propertyName, propertyValue, commandId)
        end
        
    end
end
