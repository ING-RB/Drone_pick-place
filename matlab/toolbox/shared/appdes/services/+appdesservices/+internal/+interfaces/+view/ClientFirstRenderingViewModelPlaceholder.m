classdef ClientFirstRenderingViewModelPlaceholder < handle
    %CLIENTFIRSTRENDERINGVIEWMODELPLACEHOLDER A place holder object for ViewModel
    %   Support client/server in-parallel creation workflow.
    %
    
    % Copyright 2024 MathWorks, Inc.

    properties (SetAccess = private, GetAccess = public)
        Type = "";
        Id = "";
        Parent = [];
        RealViewModel = [];
    end

    properties (Access = private)
        PropertiesStruct;
        QueuedOperations = {};

        ViewModelManager = [];
    end

    events
        ViewModelAttached
    end

    methods
        function obj = ClientFirstRenderingViewModelPlaceholder(parent, vmm, type, props)
            arguments
                parent
                vmm,
                type 
                props = struct.empty();
            end
            
            obj.Parent = parent;
            obj.ViewModelManager = vmm;
            obj.Type = type;
            % The passed in property values could be a cell array or
            % the value of individual property could be jsonencoded,
            % so convert it to a struct with jsondecode value if needed.
            obj.PropertiesStruct = obj.convertPropertiesIfNeeded(props);
            
            if ~isempty(obj.PropertiesStruct) && isfield(obj.PropertiesStruct, "Id")
                obj.Id = obj.PropertiesStruct.Id;
            end
        end

        function listenerToReturn = addlistener(obj, eventName, callbackFcn)
            if strcmp(eventName, 'ViewModelAttached')
                listenerToReturn = addlistener@handle(obj, eventName, callbackFcn);
            else
                if isempty(obj.RealViewModel)
                    listenerToReturn = appdesservices.internal.interfaces.view.ViewModelListenerPlaceholder(eventName, callbackFcn);
                    obj.QueuedOperations{end+1} = listenerToReturn;
                else
                    listenerToReturn = obj.RealViewModel.addlistener(eventName, callbackFcn);
                end
            end
        end

        function vmm = getViewModelManager(obj)
            vmm = obj.ViewModelManager;
        end

        function id = getId(obj)
            if isempty(obj.RealViewModel)
                id = obj.Id;
            else
                id = obj.RealViewModel.getId();
            end
        end

        function p = getParent(obj)
            if isempty(obj.RealViewModel)
                p = obj.Parent;
            else
                p = obj.RealViewModel.getParent();
            end
        end

        function childNode = addChild(obj, type, props)
            arguments
                obj 
                type 
                props = struct.empty(); 
            end
            if isempty(obj.RealViewModel)
                childNode = appdesservices.internal.interfaces.view.ClientFirstRenderingViewModelPlaceholder(obj, obj.getViewModelManager(), type, props);
                obj.QueuedOperations{end+1} = appdesservices.internal.interfaces.view.ViewModelAddChildPlaceholder(childNode, type, props);
            else
                childNode = obj.RealViewModel.addChild(type, props);
            end
        end

        function childNode = addChildWithJSONValues(obj, type, props)
            arguments
                obj 
                type 
                props = struct.empty(); 
            end

            if isempty(obj.RealViewModel)
                childNode = appdesservices.internal.interfaces.view.ClientDrivenViewModelPlaceholder(obj, obj.getViewModelManager(), type, props);
                obj.QueuedOperations{end+1} = appdesservices.internal.interfaces.view.ViewModelAddChildPlaceholder(childNode, type, props, true);
            else
                childNode = obj.RealViewModel.addChildWithJSONValues(type, props);
            end
        end

        function setProperty(obj, propertyName, value)
            obj.setProperties(struct(propertyName, value));
        end

        function setProperties(obj, viewProperties, varargin)
            if isempty(obj.RealViewModel)
                updatedProps = obj.convertPropertiesIfNeeded(viewProperties);
                setPropOp = appdesservices.internal.interfaces.view.ViewModelSetPropertiesPlaceholder(updatedProps);
                obj.QueuedOperations{end+1} = setPropOp;

                fdNames = fieldnames(updatedProps);
                for ix = 1 : numel(fdNames)
                    key = fdNames{ix};
                    obj.PropertiesStruct.(key) = updatedProps.(key);
                end
            else
                obj.RealViewModel.setProperties(viewProperties, varargin{:});
            end
        end

        function tf = hasProperty(obj, propertyName)
            if isempty(obj.RealViewModel)
                tf = ~isempty(obj.PropertiesStruct) && isfield(obj.PropertiesStruct, propertyName);
            else
                tf = obj.RealViewModel.hasProperty(propertyName);
            end
        end

        function value = getProperty(obj, propertyName)
            value = [];

            if isempty(obj.RealViewModel)
                if obj.hasProperty(propertyName)
                    value = obj.PropertiesStruct.(propertyName);
                end
            else
                value = obj.RealViewModel.getProperty(propertyName);
            end
        end
        
        function propertyStruct = getProperties(obj)
            if isempty(obj.RealViewModel)
                propertyStruct = obj.PropertiesStruct;
            else
                obj.RealViewModel.getProperties();
            end
        end
        
        function dispatchEvent(obj, eventName, data, varargin)
            if isempty(obj.RealViewModel)
                if nargin == 4
                    eventOp = appdesservices.internal.interfaces.view.ViewModelDispatchEventPlaceholder(eventName, data, varargin{1});
                else
                    eventOp = appdesservices.internal.interfaces.view.ViewModelDispatchEventPlaceholder(eventName, data);
                end
                obj.QueuedOperations{end+1} = eventOp;
            else
                obj.RealViewModel.dispatchEvent(eventName, data, varargin{:});
            end
        end
        
        function children = getChildren(obj)
            children = [];
            if ~isempty(obj.RealViewModel)
                children = obj.RealViewModel.getChildren();
            end
        end
        
        function componentIndex = getChildIndex(obj, varargin)
            componentIndex = -1;

            if ~isempty(obj.RealViewModel)
                componentIndex = obj.RealViewModel.getChildIndex(varargin{:});
            end
        end

        function destroy(obj)
            obj.QueuedOperations = {};
            delete(obj);
        end
    end

    methods (Access = public)
        function attach(obj, vm)
            % This attach() method is called when client-side created ViewModel
            % has been synced to server side. At this point, server-side
            % already has queued up actions which are waiting for client side
            % 'isViewReady' event.
            % However, in app view cache-based rendering, 'isViewReady' has
            % been set to true before server side listener is set up on real
            % ViewModel. So the following logic is to flip 'isViewReady' state
            % to re-fire the event to trigger actions relying on 'isViewReady' from client side.

            % Need to flip the value to false first before listeners being added, 
            % otherwise, ViewModel has an optimization logic to skip the same value to be set
            vm.setProperty('isViewReady', false);
            
            obj.RealViewModel = vm;
            for ix = 1 : numel(obj.QueuedOperations)
                obj.QueuedOperations{ix}.attach(vm);
            end

            notify(obj, 'ViewModelAttached');

            % After listeners have been setup, 
            % trigger actions relying on 'isViewReady' from client side.
            % This is a solution for app view cach-based rendering implementation.
            vm.setProperty('isViewReady', true);
        end
    end

    methods (Access = private)
        function propStruct = convertPropertiesIfNeeded(~, viewProperties)

            if iscell(viewProperties)
                viewProperties = appdesservices.internal.peermodel.convertPvPairsToStruct(viewProperties);
            end

            isJSON = isstruct(viewProperties) && isfield(viewProperties, 'IsJSON') && viewProperties.IsJSON;
            hasPropertyValuesField = isstruct(viewProperties) && isfield(viewProperties, 'PropertyValues');

            if hasPropertyValuesField
                if isJSON
                    fdNames = fieldnames(viewProperties.PropertyValues);
                    for ix = 1 : numel(fdNames)
                        key = fdNames{ix};
                        propStruct.(key) = jsondecode(viewProperties.PropertyValues.(key));
                    end
                else
                    propStruct = viewProperties.PropertyValues;
                end
            else
                propStruct = viewProperties;
            end
        end
    end
end

