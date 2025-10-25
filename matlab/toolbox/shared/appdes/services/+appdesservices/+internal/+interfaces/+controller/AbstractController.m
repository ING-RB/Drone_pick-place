classdef AbstractController < handle & ...
        appdesservices.internal.interfaces.controller.mixin.ClientEventSender & ...
        appdesservices.internal.interfaces.controller.mixin.ViewPropertiesHandler

    % ABSTRACTCONTROLLER class an abstraction for a controller, the C
    % in MVC.
    %
    % The purpose of this class is to keep a model class and a view class
    % in sync.  There are two directions of synchronization.
    %
    % Model Properties -> ProxyView
    %
    %   The Controller's updateProperties() should be called whenever when
    %   model has a property change.  When this happens, the base class
    %   will gather up information by calling subclass's
    %   getPropertiesForView() method.  This method will return all
    %   view-specific properties that are needed to be pushed from the
    %   view, and this controller will then take care of forwarding those
    %   properties to the view.
    %
    %   The entire property change set should be communciated with 1 call
    %   to updateProperties.  Mutliple calls will result in multiple
    %   dispatches to the view and can result in excessive redrawing.
    %
    % Proxy View Events -> models
    %
    %   When a user interacts with the view, updates need to happen to the
    %   model, such as changing properties and firing user callbacks. This
    %   controller handles registering the listeners on the ProxyView class
    %   for the events it fires.  When an event is recieved, this
    %   controller will call the subclass's handleEvent() method, where
    %   controllers can then determine based on the event how to update the
    %   model.

    % Copyright 2012-2024 The MathWorks, Inc.

    methods(Abstract, Access = 'protected')
        % HANDLEEVENT(OBJ, SOURCE, EVENT) This method recieves event from
        % ProxyView class each time a user interacts with the visual
        % representation through mouse or keyboard. The controller sets
        % appropiate properties of the model each time it receives these
        % events.
        %
        % Inputs:
        %
        %   source  - object generating event, i.e ProxyView class object.
        %
        %   event   - the event data that is sent from the ProxyView. The
        %             data is translated to property value of the model.
        handleEvent(obj, source, event);
    end

    properties(SetAccess='private', GetAccess='public')
        % A component's controller holds a handle to its view model
        ViewModel = appdesservices.internal.interfaces.view.EmptyViewModel.Instance;        
    end

    properties (SetAccess = protected, ...
            GetAccess = {?appdesservices.internal.interfaces.view.ViewModelFactoryManager, ...
            ?appdesservices.internal.interfaces.controller.AbstractController, ...
            ?appdesservices.internal.interfaces.controller.AbstractControllerMixin})
        % ViewModelFactory to be used to centralize ViewModel creation for components and Figure
        ViewModelFactory = [];
    end

    properties
        % Handle to the Controller of the model's Parent.
        %
        % If the model is not capable of having a Parent, such as a Figure,
        % then this will be empty.
        ParentController
    end

    properties(Access = {...
            ?appdesservices.internal.interfaces.controller.AbstractController, ...
            ?appdesservices.internal.interfaces.controller.AbstractControllerMixin, ...
            ?appdesservices.internal.interfaces.controller.DesignTimeParentingController, ...
            ?appdesigner.internal.serialization.model.AppCodeMixin})
        % Handle of model Object
        Model
    end

    properties(Access='protected')
        % An event.listener connected to view model 'peerEvent' events.
        %
        % These listeners are added so that controller can respond to
        % events from the view. These listeners must be deleted to ensure
        % that the object is deleted correctly.
        Listeners
    end

    properties(Hidden, Dependent, Transient)
        % Object with the responsibility for sending events to the client.
        ClientEventSender appdesservices.internal.interfaces.controller.mixin.ClientEventSender
    end

    properties(Access = private)
        % Store properties for view during construciton to generate
        % layout cache data.
        CachedPropertiesForView
    end

    methods
        function obj = AbstractController(model, parentController, proxyView)
            %
            % Inputs:
            %
            %   model             The model being controlled by this
            %                     controller
            %
            %   parentController  an instance of the model's Parent's
            %                     controller.  It will be empty if this model
            %                     is not capable of having a parent.
            %
            %   proxyView         Used when  the ProxyView is already
            %                     created.  When passed in, instead of
            %                     creating a new ProxyView, this ProxyView
            %                     is used instead.
            %
            %                     Should be [] or not pass in when a view
            %                     does not exist.
            narginchk(2, 3);

            obj.Model = model;
            obj.ParentController = parentController;

            dirtyPropertyStrategy = appdesservices.internal.interfaces.model.DirtyPropertyStrategyFactory.getDirtyPropertyStrategy(obj.Model);

            obj.Model.setDirtyPropertyStrategy(dirtyPropertyStrategy);

        end

        function sender = get.ClientEventSender(obj)
            sender = obj;
        end

        function sendEventToClient(obj, eventName, pvPairs)
            % ViewModel can be empty during app loading
            if isempty(obj.ViewModel)
                return;
            end

            if ~isstruct(pvPairs)
                eventData = appdesservices.internal.peermodel.convertPvPairsToStruct(pvPairs);
            else
                eventData = pvPairs;
            end

            % The client is expecting this Name property to distinguish
            % between events sent by the server.
            eventData.Name = eventName;

            viewmodel.internal.factory.ManagerFactoryProducer.dispatchEvent(obj.ViewModel, ...
                'peerEvent', eventData, obj.ViewModel.Id);
        end

        function refreshProperties(obj, pvPairs)
            % Sends an event to force the view to refresh
            % This is needed when a property is set to the value that the
            % peernode already contains, and the regular PropertiesSet event
            % is not fired because the peernode is up-to-date.

            obj.ClientEventSender.sendEventToClient('propertiesSetRefresh', pvPairs);
        end

        function populateView(obj, proxyView)

            % Inject the controller
            obj.Model.setController(obj);

            % Todo: use ViewModelFactory to take the following else design-time case out
            % of this runtime logic
            if(nargin < 2 || isempty(proxyView))
                % Create a View
                obj.ViewModelFactory = appdesservices.internal.interfaces.view.ViewModelFactoryManager.Instance.getViewModelFactory(obj.Model, obj, obj.ParentController);
                obj.ViewModel = obj.ViewModelFactory.create(...
                    obj.Model, obj, obj.ParentController, obj.ParentController.ViewModel);

                obj.listenToViewModelPlaceholderEvent(obj.ViewModel);
            else
                % If the proxyView is not empty then its a client-driven
                % workflow. Need to hook up the model to the view.

                % Store the view model
                if isempty(proxyView.PeerNode)
                    % No peer node associated to the proxyview, and it's
                    % the case of loading an, so set back proxyview to empty
                    obj.ViewModel = [];
                else
                    obj.ViewModel = proxyView.PeerNode;
                end

                if ~isempty(obj.ViewModel) && ~proxyView.HasSyncedToModel
                    % If the model is a component model, and it is created
                    % during loading an app, the properties in the model
                    % are already synced with the proxy view because the
                    % model object is loaded from the saved app.
                    %
                    % Otherwise, the model is created through client-driven,
                    % model needs to apply properties from the view

                    % Apply the state of the view to the model
                    %
                    % This is done in a view-driven workflow where the model
                    % needs to be hooked up to the view
                    viewPropertyStruct = obj.ViewModel.getProperties();

                    % leverages controllers logic of handling property changes
                    % to update the model
                    handlePropertiesChanged(obj, viewPropertyStruct);
                end
            end

            % During construction:
            % 1) For runtime all properties are sent to the view,
            % including any properties that were marked dirty.
            % 2) or for design time, it's client driven, and view already
            % has the latest values.
            % Reset dirty properties on the model because they have
            % been sent and are no longer dirty
            obj.Model.resetDirtyProperties();

            % There are scenarios where the component is instantiated
            % without a view (e.g. retrieving component default values)
            % so checking the view model is not empty is necessary.
            if ~isempty(obj.ViewModel)
                % Listen to peer events for interactions at run-time,
                % or AppDesigner commands at design-time.
                obj.Listeners = addlistener(obj.ViewModel, 'peerEvent', @obj.handleEvent);
            end
        end

        function updateProperties(obj, propertyNames)
            % UPDATEPROPERTIES(OBJ,PROPERTYNAME) Update the visual
            % representation of the model according to the updated value of
            % model's property.
            %
            % Note that depending on the implementation of the ProxyView,
            % this may be an asynchronous method and will return before the
            % actual visual is updated.  However, the caller does not need
            % to worry about whether previous updates are done or not.
            %
            % Inputs:
            %
            %   propertyNames - a cell array of strings containing the
            %                   names of the property of the model that
            %                   have changed

            pvPairs = calculatePVPairsForView(obj, string(propertyNames));

            % Pass along to the view. There are scenarios where the
            % component is instantiated without a view (e.g. retrieving
            % component default values) so a check is included to make sure
            % the ViewModel is not empty
            if ~isempty(obj.ViewModel) && ~isempty(pvPairs)
                % Passing the ViewModel's ID as the "originator" is required
                % only for design-time controllers. See failures in
                % tDesignTimeController if "obj.ViewModel.Id" is not given
                % as the third argument. ProxyView.setProperties formerly
                % hid this detail. The generated code will not be updated
                % unless the controller receives a "propertiesSet" event
                % back from the client and that doesn't happen unless we
                % specify "ViewModel.id" as the event originator here.
                obj.ViewModel.setProperties(pvPairs, obj.ViewModel.Id);
            end
        end

        function id = getId(obj)
            % GETID(OBJ) returns a string that is the ID of the peer node
            id = obj.ViewModel.Id;
        end

        function className = getViewModelType(~, model)
            % The className is the thing sent to the client to represent this
            % components type
            className = class(model);
        end

        function delete(obj)
            % DELETE(OBJ) delete the controller.
            %
            % Deletes all the listeners to events so that this object goes
            % away cleanly.

            % Stop listening to 'peerEvent' from the view model object
            delete(obj.Listeners);

            % Delete the ViewModel
            if ~isempty(obj.ViewModel) && isvalid(obj.ViewModel)
                delete(obj.ViewModel);
            end
        end
    end

    methods(Access = protected)
        function attachViewModelFromClient(obj, viewModel)
            obj.ViewModel = viewModel;
        end

        function listenToViewModelPlaceholderEvent(obj, viewModelPlaceholder)
            if isa(viewModelPlaceholder, "appdesservices.internal.interfaces.view.ClientFirstRenderingViewModelPlaceholder")
                % This is a ViewModel place holder object, which would be swapped by a real ViewModel
                % object created from client side
                addlistener(viewModelPlaceholder, 'ViewModelAttached', @(~, ~)obj.attachViewModelFromClient(viewModelPlaceholder.RealViewModel));
            end
        end

        function unhandledProperties = handlePropertiesChanged(obj, changedPropertiesStruct)
            % Default handler for properties being set from the client
            %
            % Inputs:
            %
            %   changedPropertiesStruct     A struct whos fieldnames are
            %                               changed property names and
            %                               values are the new property
            %                               values
            %
            % Subclasses wanting to handle specific properties should:
            %
            % - override this method
            % - inspect the changedPropertiesStruct for fields of interest
            % - act on the property / properties if they are present and update
            %   the Model
            % - remove the handled properties from the structure
            % - call super() to handle the rest of the properties with the
            %   modified properties structure
            %
            %
            % Example: Change the model in a non-deafult way
            %
            %  changedProperties = fieldnames(changedPropertiesStruct);
            %
            %  if(ismember('SomeProp', changedProperties))
            %
            %     obj.Model = (some special version of the property value)
            %
            %     updatedStruct = rmfield(changedPropertiesStruct, 'SomeProp')
            %  end
            %
            %  super(updatedStruct);
            %
            %
            % Example: Using Validation
            %
            %  changedProperties = fieldnames(changedPropertiesStruct);
            %
            %  if(ismember('SomeProp', changedProperties))
            %
            %    try
            %
            %       (do some validation)
            %
            %    catch ex
            %
            %        (notify the view an error occured)
            %    end
            %
            %     updatedStruct = rmfield(changedPropertiesStruct, 'SomeProp')
            %  end
            %
            %  super(updatedStruct);

            % figure out the changed properties names
            changedProperties = fieldnames(changedPropertiesStruct);
            trimmedPropertiesStruct = changedPropertiesStruct;

            if ~isempty(changedProperties)
                % Properties to exclude (i.e. not to set on the model) are:
                %
                %   fields in struct not in model
                fieldsInModel = properties(obj.Model);
                mc = meta.class.fromName(obj.ViewModel.Type);
                % Themeable 'Mode' properties are hidden.
                % So we need to find the hidden properties so that
                % Mode properties are accurately updated on the Model.
                % Find the Hidden Mode properties
                hiddenProperties = findobj(mc.PropertyList, 'GetAccess', 'public', ...
                    'SetAccess', 'public', 'Hidden', true);
                if ~isempty(hiddenProperties)
                    fieldsInModel = [fieldsInModel; string({hiddenProperties.Name})'];
                end

                for index = 1:numel(changedProperties)
                    prop = changedProperties{index};
                    if ~any(strcmp(fieldsInModel, prop))
                        trimmedPropertiesStruct = rmfield(trimmedPropertiesStruct, prop);
                    end
                end
                % Do 1 bulk set on the model
                set(obj.Model, trimmedPropertiesStruct);

            end

            % All properties are handled by this class, so the result is an
            % empty struct to indicate nothing more needing to be done
            unhandledProperties = struct;
        end

        function propertiesForView = getPropertyNamesForView(obj)
            % Get the properties to be sent to the view.
            % By default, all the public properties of the component are
            % sent.
            % If more or less properties are to be sent, subclasses should
            % use the methods:
            % -- getAdditionalPropertyNamesForView to add properties
            % -- getExcludedPropertyNamesForView to exclude properties
            %
            % An example of such information is the aspect ratio limits:
            % the information needs to be sent to the view but is not a
            % public property

            propertiesForView = properties(obj.Model);

            additionalProperties = getAdditionalPropertyNamesForView(obj);
            propertiesForView = union(propertiesForView, additionalProperties);

        end
    end

    methods(Access = {?appdesservices.internal.interfaces.controller.AbstractController;...
            ?appdesservices.internal.interfaces.controller.mixin.ViewPropertiesHandler})
        function storeCachedPropertiesForViewDuringConstruction(obj, viewProps)
            if isempty(obj.CachedPropertiesForView)
                obj.CachedPropertiesForView = viewProps;
            end
        end
    end

    methods (Access = private)
        function pvPairs = calculatePVPairsForView(obj, propertyNames)
            % Calculate changed properties PV pairs
            pvPairs = obj.getPVPairsForView(obj.Model, propertyNames);
        end                
    end

    methods (Access = public, Hidden)
        function viewProperties = retrieveCachedPropertiesForViewDuringConstruction(obj)
            if isempty(obj.CachedPropertiesForView)
                obj.storeCachedPropertiesForViewDuringConstruction(...
                    obj.getPropertiesForViewDuringConstruction(obj.Model, false));
            end

            viewProperties = obj.CachedPropertiesForView;
        end
    end

    methods(Static, Access=protected)
        function callback = wrapLegacyProxyViewPropertiesChangedCallback(legacyPropertiesChangedCallback)
            %WRAPLEGACYPROXYVIEWPROPERTIESCHANGEDCALLBACK Wraps a ProxyView GuiEvent callback
            %for compatibility with view model "propertiesSet" events
            %
            %   Unpacks the changes properties and passes them as a struct to the given callback
            %
            % TODO determine whether we want to remove this or just give it a better name
            % and continue unpacking properties centrally before passing them to a controller
            % method
            %
            function viewModelCallback(source, event)
                eventData = event.getData();
                newValues = eventData.get('newValues');
                newValuesStruct = viewmodel.internal.factory.ManagerFactoryProducer.convertEventDataToStruct(newValues);
                legacyPropertiesChangedCallback(newValuesStruct);
            end
            callback = @viewModelCallback;
        end
    end
end
