% WEBCOMPONENTCONTROLLER Base class for all MATLAB Component Framework (MCF)
% web-based component controllers. Captures commonalities across all web-based
% component controllers in terms of the use of MCF services, such as the
% Property Management Service (PMS) and the Event Handling Service (EHS).

%   Copyright 2013-2024 The MathWorks, Inc.

classdef WebComponentController < ...
        matlab.ui.internal.componentframework.WebController & ...
        matlab.ui.internal.componentframework.services.optional.ControllerInterface & ...
        matlab.ui.internal.componentframework.services.optional.EventDispatcherAddOn

    properties (GetAccess = {?appdesservices.internal.interfaces.view.ViewModelFactoryManager, ...
            ?matlab.ui.internal.componentframework.WebComponentController, ...
            ?matlab.ui.internal.componentframework.WebController}, SetAccess = protected)
        % ViewModelFactory to be used to centralize ViewModel creation for components and Figure
        ViewModelFactory = [];
    end

    properties(Access = protected)
        % Store component view properties on init creation,
        % so that it could be used to generate layout cache file
        CachedPropertiesForViewDuringConstruction;
    end

    methods(Static)
        function controller = getControllerFromModel(model)
            controller = model.getControllerHandle();
        end

        function newValue = executeUpdateMethod(controller, name)
            newValue = controller.(['update', name]);
        end
    end

    methods ( Access = 'public' )

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:       Constructor
        %
        %  Inputs:       model -> Model MCOS object for the web component.
        %                varargin{1} -> Parent controller.
        %                varargin{2) -> View.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = WebComponentController( model, varargin )
            % MCF's web-based controller constructor for all web-based controllers,
            % which utilize the services provided by the MCF, such as the PMS and
            % the EHS.

            % Input verification
            % Call the base class constructor
            obj = obj@matlab.ui.internal.componentframework.WebController();
            obj.Model = model;
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:       add
        %
        %  Inputs :      model -> Web component for which the MCF will create a view
        %                element.
        %                parentController -> Parent's controller.
        %  Outputs:      None.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function add( obj, ~, parentController )
            % Adds web component's view element into the view hierarchy previously
            % established by the MATLAB Component Framework (MCF). This method uses
            % MCF's Property Management Service to create an initial set of view
            % properties.

            % Retrieve the ViewModel of the parent
            obj.ParentController = parentController;
            parentView = obj.getParentView( parentController );

            % Add this web component as a child to the peer node hierarchy
            obj.createView( parentController, parentView );
            
            % Do any post updates after the ViewModel is updated
            updateFullView_Post(obj);

            % Post add operation
            obj.postAdd();
        end

        function propertiesStruct = getPropertiesForViewDuringConstruction (obj, model, disableCacheAfterGet)
            arguments
                obj;
                model = [];
                disableCacheAfterGet = true;
            end
            
            propertiesStruct = struct("PropertyValues", [], "IsJSON", false);

            % Create property/value (PV) pairs
            % This check is necessary in the event of copyobj,
            % save-load, reparenting, where we explicitly turn off
            % caching, because  we need to send all properties to the
            % view.
            if obj.Model.isCacheReady()
                dirtyProperties = obj.Model.getDirtyProperties();
                pvPairs = obj.PropertyManagementService.definePvPairs( obj, obj.Model, dirtyProperties);
                if disableCacheAfterGet
                    obj.Model.disableCache();
                end
            else
                pvPairs = obj.PropertyManagementService.definePvPairs(obj, obj.Model);
            end
            
            propertiesStruct.PropertyValues = appdesservices.internal.peermodel.convertPvPairsToStruct(pvPairs);

            % Give subclass a chance to add additional view properties
            addedPropStruct = obj.getAdditionalPropertiesForViewDuringConstruction();
            if ~isempty(addedPropStruct)
                fdNames = fieldnames(addedPropStruct);
                fdNum = numel(fdNames);

                for ix = 1 : fdNum
                    key = fdNames{ix};
                    propertiesStruct.PropertyValues.(key) = addedPropStruct.(key);
                end
            end

            obj.storeCachedPropertiesForViewDuringConstruction(propertiesStruct);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:       triggerUpdatesOnDependentViewProperties
        %
        %  Input :       varargin - optional list of property names which are
        %                to be excluded from processing.
        %
        %  Output:       None.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function triggerUpdatesOnDependentViewProperties( obj , varargin)
            % This method triggers the any post-update actions which are to be
            % done on dependent properties, as specified for this particular
            % controller.
            triggerUpdatesHelper(obj, false, varargin);
        end


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:       triggerPostUpdatesOnDependentViewProperties
        %
        %  Input :       varargin - optional list of property names which are
        %                to be excluded from processing.
        %
        %  Output:       None.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function triggerPostUpdatesOnDependentViewProperties( obj , varargin)
            % This method triggers the any post-update actions which are to be
            % done on dependent properties, as specified for this particular
            % controller.
            triggerUpdatesHelper(obj, true, varargin);
        end


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:       triggerUpdatesHelper
        %
        %  Input :       doPostOnly - if true, will only do the postUpdate.
        %                Otherwise, will do both pre- and post-updates.
        %
        %                varargin - optional list of property names which are
        %                to be excluded from processing.
        %
        %  Output:       None.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function triggerUpdatesHelper( obj, doPostOnly, varargin)
            % This method triggers the any pre- and/or post-update actions
            % which are to be done on dependent properties, as specified for
            % this particular controller.  Depending on the boolean value of
            % doPostOnly argument, either pre-and-post, or just post-update
            % actions are done.
            triggerProps = obj.PropertyManagementService.getTriggerUpdatesProperties();

            for idx = 1:numel(triggerProps)
                name = triggerProps(idx);
                if ~doPostOnly
                    obj.triggerUpdateOnDependentViewProperty(name);
                else
                    obj.triggerPostUpdateOnDependentViewProperty(name);
                end
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:       triggerUpdateOnDependentViewProperty
        %
        %  Details:      Method which triggers update and postUpdate methods on
        %                a view property which depends on other model
        %                properties.
        %
        %  Input :       Name of property to be updated.
        %
        %  Output:       None.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function triggerUpdateOnDependentViewProperty( obj, property )
            % This method triggers the recomputation and postUpdate actions for
            % a property value which is dependent on other model properties.
            value = obj.("update" + property);

            obj.EventHandlingService.setProperty( property, value );
            
            % Customizable post set operation
            obj.postSet(property);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:       triggerUpdateOnDependentViewPropertyAndCommit
        %
        %  Details:      Method which triggers update and postUpdate methods on
        %                a view property which depends on other model
        %                properties.
        %
        %  Input :       Name of property to be updated.
        %
        %  Output:       None.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function triggerUpdateOnDependentViewPropertyAndCommit( obj, property )
            % This method triggers the recomputation and postUpdate actions for
            % a property value which is dependent on other model properties.
            % It then commits the transaction, which is essential if the
            % property exists only in the View or if the property is updated
            % without marking an equivalent Model property as dirty.
            value = obj.("update" + property);

            if ~isempty(obj.ViewModel) && isvalid(obj.ViewModel)
                obj.EventHandlingService.setPropertyAndCommit( property, value );
            end

            % Customizable post set operation
            obj.postSet( property );

        end


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:       triggerPostUpdateOnDependentViewProperty
        %
        %  Details:      Method which triggers update methods on view
        %                properties during controller creation, *after* the
        %                view is created.
        %
        %  Input :       Name of the property to be updated.
        %
        %  Output:       None.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function triggerPostUpdateOnDependentViewProperty( obj, property )
            % This method triggers the postUpdate action for a property which
            % is dependent on other model properties.

            % Customizable post set operation
            obj.postSet( property );
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:       setProperty
        %
        %  Inputs:       property -> Name of the model side property.
        %  Outputs:      None.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function setProperty( obj, property )
            % Using MCF's Property Management Service, this method updates the
            % the view representation of the web component, when a model side
            % property is set. During update, any property renames and/or property
            % dependencies will be taking into account.

            if (endsWith(property, '_I'))
                property = property(1:end-2);
            end

            % Account for property dependencies using the PMS.
            if obj.PropertyManagementService.hasDependency(property)
                % Lookup dependent properties first
                dependentProperties = ...
                    obj.PropertyManagementService.getDependencies(property);

                % Iterate through dependencies and invoke the corresponding
                % custom "update" method.
                for idx=1:numel( dependentProperties )
                    obj.triggerUpdateOnDependentViewProperty(dependentProperties{idx});
                end
            elseif obj.PropertyManagementService.requireUpdate(property)
                obj.triggerUpdateOnDependentViewProperty(property);
            elseif obj.PropertyManagementService.isModelPropertyForView(property)
                % Set the property only if it is a model property for view.
                value = obj.Model.(property);
                
                obj.EventHandlingService.setProperty(property, value);
            end

            % Customizable post set operation
            obj.postSet( property );
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:       updateFullViewFromModel
        %
        %  Inputs:       None.
        %  Outputs:      None.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function updateFullViewFromModel (obj)
            % Do a full update of the properties to the View. This is called on the rare
            % occasion when the object state changes (marked dirty) but the specific props
            % changed is not available (e.g. reset is called)

            % Gather PV pairs to update the ViewModel
            pvPairs = updateFullView_Pre (obj);

            % Update all properties to the ViewModel via EHS
            for idx = 1:2:numel(pvPairs)
                pname = pvPairs{idx};
                pvalue = pvPairs{idx + 1};
                if obj.EventHandlingService.hasProperty( pname )
                    obj.EventHandlingService.setProperty( pname, pvalue);
                end
            end

            % Do any post updates after the ViewModel is updated
            updateFullView_Post (obj);
        end

        function className = getViewModelType(~, model)
            % The className is the thing sent to the client to represent this
            % components type
            className = class(model);
        end
    end

    methods ( Access = 'protected' )
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:       postAdd
        %
        %  Inputs:       None.
        %  Outputs:      None.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function postAdd( ~ )
            % Customizable method provided by the MATLAB Component Framework (MCF)
            % that will be invoked after the web component's view representation is
            % added to the hierarchy.

            % Noop default implementation
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:       postSet
        %
        %  Inputs:       property -> Name of the model property which will be set.
        %  Outputs:      None.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function postSet( ~, ~ )
            % Customizable method provided by the MATLAB Component Framework (MCF)
            % that will be invoked after to the setting of the property.

            % Noop default implementation
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:       updateFullView_Pre
        %
        %  Inputs:       None.
        %  Outputs :     pvPairs - property name/value pairs of view, renamed and
        %                dependet properties that need to be updated.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function pvPairs = updateFullView_Pre (obj)
            % Create property/value (PV) pairs
            pvPairs = obj.PropertyManagementService.definePvPairs( obj, obj.Model );
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:       updateFullView_Post
        %
        %  Inputs:       None.
        %  Outputs:      None.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function updateFullView_Post (obj)
            % For applicable  view properties which have trigger the customized
            % postUpdate methods.
            obj.triggerPostUpdatesOnDependentViewProperties;

        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:       handleEvent
        %
        %  Details:      MCF provides this customizable event handling method per
        %                web component. Specialization of this method can be
        %                implemented in the web-based controller corresponding to
        %                the web component.
        %
        %  Inputs:       src -> Source of the event.
        %                event -> Event payload.
        %  Outputs:      None.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function handleEvent( obj, src, event )
            % Customizable event handling method provided by the Event Handling
            % Service (EHS), which is a core service of the MATLAB Component
            % Framework (MCF).

            % If callback is executed due to an event that was triggered as part
            % of the destructor, obj would be invalid
            if isvalid(obj) && obj.EventHandlingService.isClientEvent( event )
                eventStructure = obj.EventHandlingService.getEventStructure( event );
                obj.handleClientEvent(src, eventStructure);
            end
        end

        % TODO consider making this change for all components:
        % Separate handling "ANY" event from handling "CLIENT" event
        function handleClientEvent( obj, ~, eventStructure)
            switch ( eventStructure.Name )
                case 'viewReady'
                    obj.setViewReady();
                case {'processButtonEvent', 'processMouseMoveEvent'}
                    % decide the selectionType based on the button value
                    timeStamp = eventStructure.data.timeStamp;
                    switch eventStructure.data.button
                        case 0
                            button = 'left';
                        case 2
                            button = 'right';
                        case 1
                            button = 'middle';
                        otherwise
                            button = 'left';
                    end

                    obj.Model.processButtonEventFromClient(eventStructure.data.type, ...
                        eventStructure.data.position, ...
                        eventStructure.data.selectionType, ...
                        button, ...
                        timeStamp);

                case 'processKeyEvent'
                    modifier = eventStructure.data.modifier;
                    if isempty(modifier)
                        modifier = {};
                    end
                    if (~isempty(eventStructure.data.key) && (eventStructure.data.key ~= "'") && (eventStructure.data.key ~= "") && (eventStructure.data.key ~= "Unidentified"))
                        obj.Model.processKeyEventForComponent(eventStructure.data.type, ...
                            eventStructure.data.character, ...
                            modifier, ...
                            eventStructure.data.key, ...
                            eventStructure.data.keyTarget);
                    end
                otherwise
                    %Noop
            end

            % After all matlab events for this client side event have been
            % emitted and callbacks processed, send an event to the client
            % if the event is registered to use an event coalescing
            % mechanism.
            % Need to check if controller is valid or not because the
            % user's callback could delete the app or the component
            % see g1336677
            coalescedEventIsField = isfield(eventStructure, 'CoalescedEvent');
            if(isvalid(obj) && coalescedEventIsField && eventStructure.CoalescedEvent)
                obj.sendFlushEventToClient(obj.Model, eventStructure.Name, obj.EventHandlingService);
            end

        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:       getParentView
        %
        %  Inputs:       parentController -> Parent's web controller which contains
        %                                    the view representation for the parent.
        %  Outputs:      parentViewElement -> Parent view representation.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function parentView = getParentView( ~, parentController )
            % Retrieves the view element of the parent component, if applicable.
            % The base implementation pulls it off the parent controller.
            parentView = parentController.ViewModel;
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        %  Method:       createView
        %
        %  Inputs:       parentController -> Parent's web controller which contains
        %                                    the view representation for the parent.
        %                parentViewElement -> Parent view representation.
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function createView( obj, parentController, parentView)
            % This method creates the view element for the web component, given the
            % parent information. This base implementation assumes that the given
            % parent view representation is not empty, but subclasses could accept
            % empty parent view representations when creation new PeerModelManagers.
            obj.ViewModelFactory = appdesservices.internal.interfaces.view.ViewModelFactoryManager.Instance.getViewModelFactory(obj.Model, obj, parentController);
            
            obj.ViewModel = obj.ViewModelFactory.create(...            
                        obj.Model, obj, parentController, parentView);

            obj.attachView();
        end

        function attachView(obj)
            % Have the EHS attach to the view
            obj.EventHandlingService.attachView( obj.ViewModel );

            % If it's a client-first rendering, listen to ViewModel creation
            % from client side to swap it and run queued operations
            obj.listenToViewModelPlaceholderEvent(obj.ViewModel);
        end

        function listenToViewModelPlaceholderEvent(obj, viewModelPlaceholder)
            if isa(viewModelPlaceholder, "appdesservices.internal.interfaces.view.ClientFirstRenderingViewModelPlaceholder")
                % This is a ViewModel place holder object, which would be swapped by a real ViewModel
                % object created from client side
                addlistener(viewModelPlaceholder, 'ViewModelAttached', @(~, ~)obj.attachViewModelFromClient(viewModelPlaceholder.RealViewModel));
            end
        end

        function addedPropStruct = getAdditionalPropertiesForViewDuringConstruction(~)
            % Give subclass a chance to modify view properties for construction
            addedPropStruct = struct.empty();
        end

        function setViewReady(obj)
            obj.Model.setViewReady( true );
            notify( obj.Model, 'ViewReady' );
        end
        
        function attachViewModelFromClient(obj, viewModel)
            obj.ViewModel = viewModel;
            obj.EventHandlingService.attachView(viewModel);

            obj.setViewReady();
        end

    end

    methods(Access = {?matlab.ui.internal.componentframework.services.optional.ControllerInterface; ...
            ?matlab.ui.internal.componentframework.WebComponentController})
        function setParentController(obj, newParentController)
            % SETPARENTCONTROLLER(obj)
            % Method to set the parent controller
            obj.ParentController = newParentController;
        end

        function eventHandlingService = getEventHandlingService(obj)
            eventHandlingService = obj.EventHandlingService;
        end

        function propertyManagementService = getPropertyManagementService(obj)
            propertyManagementService = obj.PropertyManagementService;
        end
    end

    methods(Access = private, Sealed = true)
        function storeCachedPropertiesForViewDuringConstruction(obj, viewProps)
            if isempty(obj.CachedPropertiesForViewDuringConstruction)
                obj.CachedPropertiesForViewDuringConstruction = viewProps;
            end
        end
    end

    methods(Hidden, Access='public')
        function newInteractionInformation = addComponentSpecificInteractionInformation(obj, interactionInformation, eventStructure)
            % ADDCOMPONENTSPECIFICINTERACTIONINFORMATION - Add any
            % InteractionInformation that is specific to this component.
            % Typically, components do not have any special
            % InteractionInformation to add, so this is no-op by default.
            % Allow controllers to override this functionality
            newInteractionInformation = interactionInformation;
        end

        function interactionObject = constructInteractionObject(obj, interactionInformation)
            % CONSTRUCTINTERACTIONOBJECT - Construct the object to be used
            % with InteractionInformation. Typically, this will be a
            % ComponentInteraction object.
            % Allow controllers to override this functionality
            interactionObject = matlab.ui.eventdata.ComponentInteraction(interactionInformation);
        end

        function viewProperties = retrieveCachedPropertiesForViewDuringConstruction(obj)
            if isempty(obj.CachedPropertiesForViewDuringConstruction)
                propertiesStruct = obj.getPropertiesForViewDuringConstruction(obj.Model, false);

                if iscell(propertiesStruct)
                    % uitable overrides getPropertiesForViewDuringConstruction() method, so
                    % we need to do this check and conversion here.
                    % It would be nice to get rid of this overriden in table controller.
                    propertiesStruct = struct("PropertyValues", appdesservices.internal.peermodel.convertPvPairsToStruct(propertiesStruct), "IsJSON", false);            
                end

                obj.storeCachedPropertiesForViewDuringConstruction(propertiesStruct);
            end

            viewProperties = obj.CachedPropertiesForViewDuringConstruction;
        end
    end
end

