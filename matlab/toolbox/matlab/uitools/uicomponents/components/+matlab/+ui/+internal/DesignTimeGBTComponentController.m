classdef DesignTimeGBTComponentController < ...
        appdesigner.internal.controller.DesignTimeController & ...
        appdesservices.internal.interfaces.controller.mixin.ClientEventSender & ...
        matlab.ui.internal.DesignTimeGBTControllerPositionMixin & ...
        matlab.ui.internal.DesignTimeGBTControllerFontMixin & ...
        matlab.ui.internal.DesignTimeGBTControllerViewPropertiesMixin
    %DESIGNTIMEGBTCOMPONENTCONTROLLER This is the super class for all
    %Visual Components' design time controllers.  It will act as a bridge
    %between the DesignTimeController which is the interface for all
    %components integrated with AppDesigner and each indivual visual
    %component.

    %  Copyright 2016-2023 The MathWorks, Inc.

    properties(Hidden, Dependent, Transient)
        ClientEventSender appdesservices.internal.interfaces.controller.mixin.ClientEventSender
    end

    methods
        function obj = DesignTimeGBTComponentController(varargin)
            model = varargin{1};
            parentController = varargin{2};
            proxyView = varargin{3};
            if length(varargin) >= 4
                adapter = varargin{4};
            else
                adapter = [];
            end

            obj = obj@matlab.ui.internal.DesignTimeGBTControllerPositionMixin(model, proxyView);
            obj = obj@matlab.ui.internal.DesignTimeGBTControllerFontMixin(model, proxyView);
            obj = obj@matlab.ui.internal.DesignTimeGBTControllerViewPropertiesMixin(model);

            obj = obj@appdesigner.internal.controller.DesignTimeController(model, proxyView, adapter);

            obj.setParentController(parentController);

            if ~isempty(proxyView)
                obj.ViewModel = proxyView.PeerNode;
            end

            % Now, inject the controller before calling update model from
            % view
            configureController(obj, model, proxyView);

            if ~isempty(obj.ViewModel)
                % When ViewModel is not empty, it's in the design time
                obj.getEventHandlingService().attachView(obj.ViewModel);

                if ~proxyView.HasSyncedToModel
                    % Initialize the model from the view upon creation of
                    % component from client side
                    obj.updateModelFromViewModel(obj.ViewModel);
                end
            end
        end

        function sender = get.ClientEventSender(obj)
            sender = obj;
        end

        function sendEventToClient(obj, eventName, pvPairs)
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
    end

    methods(Access = 'protected')

        function model = getModel(obj)
            % GETMODEL( obj )
            % Method providing access to the model.
            model = obj.Model;
        end

        function model = configureController(obj,model, proxyView)
            % Configure the controller of the component.
            % This function gives individual component controllers the
            % ability to override the controller configuration, if needed.
            %
            % For example, Axes (subclassed from matlab.graphics.axis.Axes)
            % is a charting component.  In this case, controller
            % configuration must be dealt with differently than typical GBT
            % Components.

            model.setControllerHandle(obj);
        end

        function handleDesignTimePropertiesChanged(obj, peerNode, valuesStruct)
            % This is required by the DesignTimeComponentController. This method
            % will take the data given by the DesignTimeController and form
            % data that can be used by the Tab and Tab Group controllers
            %
            % peerNode - The peerNode associated with this controller's
            %            component
            %
            % valuesStruct - This is a MATLAB struct with two fields 'oldValues'
            %            and 'newValues'.  Each of these fields contains a
            %            struct.  For this struct, each field is a changed
            %            property which contains it's appropriate value.

            % Filter out the properties which should not be set to the
            % component model
            % value not changed for those properties with corresponding
            % 'xxxMode' property
            % if the value passed in is the same as the value on the model
            % object, and the corresponding 'xxxMode' value is 'auto'
            % Remove it to avoid unncessary setting to the model object.
            % Otherwise a side effect is that during drag/drop creating a
            % new component, 'xxxMode' property would be updated from 'auto'
            % to 'manual' regardless the value is the same as default value
            % or not. see g1627559
            includeHiddenProperty = true;
            priorModePropertyOnModel = false;
            valuesStruct = obj.handleChangedPropertiesWithMode(obj.Model, valuesStruct, includeHiddenProperty, priorModePropertyOnModel);

            % Start to handle property updating
            valuesStruct = handleSizeLocationPropertyChange(obj, valuesStruct);

            propertyList = fields(valuesStruct);
            % Iterate over properties and update the component one property
            % at a time.
            for index = 1:numel(propertyList)
                propertyName = propertyList{index};
                updatedValue = valuesStruct.(propertyName);

                switch (propertyName)
                    % For property updates that are common between run time
                    % and design time, this method delegates to the
                    % corresponding run time controller.
                    case {'FontSize', 'FontName', 'FontAngle', 'FontWeight', 'FontUnits'}
                        obj.handleFontUpdate(propertyName, updatedValue);

                    case 'HandleVisibility'
                        obj.handleCommonHGPropertyUpdated(propertyName, updatedValue);
                    case 'BusyAction'
                        obj.handleCommonHGPropertyUpdated(propertyName, updatedValue);
                    case 'Interruptible'
                        obj.handleCommonHGPropertyUpdated(propertyName, updatedValue);
                    otherwise
                        % set the property with propertySetData struct
                        propertySetData.newValue = updatedValue;
                        propertySetData.key = propertyName;

                        obj.handleDesignTimePropertyChanged(peerNode, propertySetData);
                end
            end
        end

        function handleDesignTimeEvent(obj, src, event)
            % Handler for 'peerEvent' from the Peer Node

            if strcmp(event.Data.Name,'positionChangedEvent') ||strcmp(event.Data.Name,'insetsChangedEvent')
                obj.updateToPositionBehavior( src, event.Data);
            end
        end

        function updateToPositionBehavior(obj, src, eventData)
            % This method expects a zero-based InnerPosition & OuterPosition
            %
            % no-op for base class
            % base class to implement it to use positionBehavior, which
            % is a proteced memeber in runtime controller
            % Todo: we could ask runtime to make it accessible
        end

        function handleDesignTimePropertyChanged(obj, ~, data)

            % handleDesignTimePropertyChanged( obj, peerNode, data )
            % Controller method which handles property updates in design time.
            % This is a default implementation for updating value to the
            % property on the server model directly, and the individual
            % subclass of each component could overrid it to handle
            % specific properties, and then call base class to deal with
            % others

            % Handle property updates from the client

            updatedProperty = data.key;
            updatedValue = data.newValue;

            if isprop(obj.Model, updatedProperty)
                % Checking to filter DesignTime property out, e.g.
                % CodeName, GroupId
                obj.Model.(updatedProperty) = updatedValue;
            end
        end

        function handleCommonHGPropertyUpdated(obj, propertyName, updatedValue)
            % Handle common HG property updating
            switch (propertyName)
                case 'HandleVisibility'
                    obj.Model.HandleVisibility = updatedValue;
                case 'BusyAction'
                    obj.Model.BusyAction = updatedValue;
                case 'Interruptible'
                    obj.Model.Interruptible = updatedValue;

                otherwise
                    % no-op
            end
        end

        function updateModelFromViewModel(obj, viewModel)
            % UPDATEMODELFROMVIEWMODEL( obj, viewModel )
            % Updates the model from view for relevant design-time/run-time properties.
            % this only called when we drag and drop the component to the
            % canvas

            % Apply the state of the view to the model
            %
            % This is done in a view-driven workflow where the model
            % needs to be hooked up to the view
            viewPropertyStruct = viewModel.getProperties();

            % leverages controllers logic of handling property changes
            % to update the model
            obj.handleDesignTimePropertiesChanged(viewModel, viewPropertyStruct);
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

            import appdesservices.internal.util.ismemberForStringArrays;
            checkFor = ["LayoutConstraints", "ContextMenuID"];
            isPresent = ismemberForStringArrays(checkFor, propertyNames);

            if isPresent(1)
                constraints = obj.Model.Layout;
                constraintsStruct = matlab.ui.control.internal.controller.mixin.LayoutableController.convertContraintsToStruct(constraints);
                viewPvPairs = [viewPvPairs, ...
                    {'LayoutConstraints', constraintsStruct} ...
                    ];
            end

            % Update ContextMenu property so it can be sent to the view
            if isPresent(2)
                cmID = '';
                % Get ObjectID from UIContextMenu object
                if(~isempty(obj.Model.ContextMenu))
                    cmID = obj.Model.ContextMenu.ObjectID;
                end
                viewPvPairs = [viewPvPairs, ...
                    {'ContextMenuID', cmID} ...
                    ];
            end
        end

        function additionalPropertyNames = getAdditionalPropertyNamesForView(obj)
            % Get the list of additional properties to be sent to the view

            additionalPropertyNames = {};

            % Position related properties
            additionalPropertyNames = [additionalPropertyNames; ...
                obj.getAdditonalPositionPropertyNamesForView();...
                ];
        end

        function excludedPropertyNames = getExcludedPropertyNamesForView(obj)
            excludedPropertyNames = {'ContextMenuID'};
            % TODO: re-assess

            excludedPropertyNames = [excludedPropertyNames; ...
                obj.getExcludedPositionPropertyNamesForView(); ...
                ];

            excludedPropertyNames = [excludedPropertyNames; ...
                getExcludedPropertyNamesForView@matlab.ui.internal.DesignTimeGBTControllerViewPropertiesMixin(obj); ...
                ];
        end
    end
end
