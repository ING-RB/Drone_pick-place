classdef ManagerFactoryProducer < handle
    %ManagerFactoryProducer
    %
     
    % Copyright 2020-2023 The MathWorks, Inc.
    
    enumeration
        % By default, use CPP based ViewModel
        MF0ViewModel(viewmodel.internal.factory.CPPVMMFactoryHelper);
        
        % CPP based MF0 ViewModel
        CPPMF0ViewModel(viewmodel.internal.factory.CPPVMMFactoryHelper);
    end
    
    properties(Access = private)
        ManagerHelper;
    end
    
    methods (Access = private)
        % Private Constructor since this class is scoped to enumerated use
        function obj = ManagerFactoryProducer(managerHelper)
            obj.ManagerHelper = managerHelper;    
        end
    end
    
    methods (Access = public)
        function viewModelManager = getViewModelManager(obj, varargin)
            viewModelManager = obj.ManagerHelper.getViewModelManager(varargin{:});
        end
        
        function cleanup(obj, namespace, varargin)
            obj.ManagerHelper.cleanup(namespace, varargin{:});
        end
    end
    
    methods (Static, Access = public)
        function isVM = isViewModel(viewModelObject)
            isVM = viewmodel.internal.factory.CPPVMMFactoryHelper.isViewModel(viewModelObject);
        end        
        
        function isManager = isManager(viewModelObject)
            isManager = viewmodel.internal.factory.CPPVMMFactoryHelper.isViewModelManager(viewModelObject);
        end
        
        function isNode = isNode(viewModelObject)
            isNode = viewmodel.internal.factory.CPPVMMFactoryHelper.isViewModelObject(viewModelObject);
        end
        
        function isValid = isValidNode(viewModelObject)
            isValid = false;
            
            if ~isempty(viewModelObject)
                if isa(viewModelObject,'viewmodel.internal.ViewModel')
                    isValid = isvalid(viewModelObject);
                else
                    % we can not do isvalid() check on PeerModel node, but only
                    % for ViewModel node
                    isValid = true;
                end
            end
        end
        
        function isFromClient = isEventFromClient(event, ori)
            try
                isFromClient = event.isFromClient();
            catch ME %#ok
                originator = event.getOriginator();
                isFromClient = ~isempty(originator);
                if nargin == 2 && isFromClient                
                    isFromClient = ~isequal(originator, ori);
                end
            end
        end
        
        function proxyCallback = getProxyCallback(callback)
            proxyCallback = @(src, event)callback(src, ...
                                    viewmodel.internal.factory.ManagerFactoryProducer.convertStructToEventData(event));
        end
        
        function childNode = addChild(viewModelObject, type, varargin)
            if nargin == 2
                childNode = viewModelObject.addChild(type);
            else
                properties = varargin{1};

                % properties could be a struct with value as JSON encoded data
                hasIsJSON = isstruct(properties) && isfield(properties, 'IsJSON');
                isJSON = false;
                if hasIsJSON
                    isJSON = properties.IsJSON;
                    properties = properties.PropertyValues;                    
                end

                if isJSON
                    childNode = viewmodel.internal.factory.ManagerFactoryProducer.addChildWithJSONValues(viewModelObject, type, properties, varargin{2:end});                    
                else
                    if nargin == 3
                        childNode = viewModelObject.addChild(type, properties);
                    elseif nargin == 4
                        originator = varargin{2};
                        % 0 means appending to the end.
                        % CPP ViewModel only supports the following overided function signature when
                        % calling with originator
                        childNode = viewModelObject.addChild(type, properties, 0, originator);
                    else
                        childNode = viewModelObject.addChild(type, properties, varargin{2:end});
                    end
                end                
            end
        end

        function childNode = addChildWithJSONValues(viewModelObject, type, properties, varargin)
            if nargin == 2
                childNode = viewModelObject.addChild(type);
            else
                if nargin == 3
                    childNode = viewModelObject.addChildWithJSONValues(type, properties);
                elseif nargin == 4
                    % 0 means appending to the end.
                    % CPP ViewModel only supports the following overided function signature when
                    % calling with originator
                    childNode = viewModelObject.addChildWithJSONValues(type, properties, 0, varargin{1});
                else
                    childNode = viewModelObject.addChildWithJSONValues(type, properties, varargin{:});
                end
            end
        end
        
        function setProperties(viewModelObject, properties, originator, isJSONValue)
            if nargin < 4
                isJSONValue = false;
            end

            if isJSONValue
                if nargin == 2
                    viewModelObject.setPropertiesWithJSONValue(properties);
                else
                    viewModelObject.setPropertiesWithJSONValue(properties, originator);
                end
            else
                if nargin == 2
                    viewModelObject.setProperties(properties);
                else
                    viewModelObject.setProperties(properties, originator);
                end
            end
        end

        function setPropertiesWithJSONValue(viewModelObject, properties, originator)
            if nargin == 2
                viewModelObject.setPropertiesWithJSONValue(properties);
            else
                viewModelObject.setPropertiesWithJSONValue(properties, originator);
            end
        end

        function value = getProperty(viewModelObject, propertyName)
           % Gets the value of the ViewModel/PeerNode's property propertyName  
           
           value = viewModelObject.getProperty(propertyName);
        end
        
        function propertyStruct = getProperties(viewModelObject)
           % Gets all properties of the ViewModel/PeerNode
           
           propertyStruct = viewModelObject.getProperties();
        end
        
        function dispatchEvent(viewModelObject, eventName, data, originator)        
            if nargin == 4
                viewModelObject.dispatchEvent(eventName, data, originator);
            else
                viewModelObject.dispatchEvent(eventName, data);
            end
        end
        
        function children = getChildren(viewModelObject)
            children = viewModelObject.getChildren();
        end
        
        function componentIndex = getChildIndex(viewModelObject, parent)
            if nargin == 1
                parent = viewModelObject.getParent();
            end
            componentIndex = parent.getChildIndex(viewModelObject);
        end
        
        function deleteViewModelObject(viewModelObject)
            % Todo: remove this method once nobody use it
            viewModelObject.destroy();
        end
        
        function data = convertDataIfNeeded(data)
            if iscell(data)
                data = viewmodel.internal.convertPVPairsToStruct(data);
            end
        
            if isa(data, 'java.util.Map')
                data = appdesservices.internal.peermodel.convertJavaMapToStruct(data);
            end
        end
        
        function s = convertEventDataToStruct(eventData)
            assert(isa(eventData, 'java.util.Map') || isstruct(eventData) || ...
                isa(eventData, 'viewmodel.internal.interface.eventdata.StructData'));
            
            if isa(eventData, 'java.util.Map')
                s = appdesservices.internal.peermodel.convertJavaMapToStruct(eventData);
            else
                % Changes for ViewModel interface
                % Todo: ViewModel should always return an instance of 
                % matlab.internal.appbuilding.interface.viewmodel.eventdata.StructData.
                % Once it's done, remove isstruct() check.
                if isstruct(eventData)
                    s = eventData;
                elseif isa(eventData, 'viewmodel.internal.interface.eventdata.StructData')
                    s = eventData.Data;
                end
            end
        end
        
        function convertedEventData = convertStructToEventData(eventData)
            if isa(eventData, 'com.mathworks.peermodel.events.Event')
                % It's already an event data object, which is from PeerModel
                convertedEventData = eventData;
            elseif isa(eventData, 'viewmodel.internal.interface.eventdata.GenericEventData')
                % It's already a GenericEventData data object, which is from
                % MATLAB based MF0ViewModel
                convertedEventData = eventData;
            else
                % It must be a struct data from C++ implementaiton of 
                % MF0ViewModel, which should have the following fields:
                % type
                % originator
                % target
                % data
                % srcLang
                if strcmp(eventData.type, 'rootSet')
                    target = eventData.data.root;
                else
                    target = eventData.target;
                end
                convertedEventData = viewmodel.internal.interface.eventdata.GenericEventData(...
                    eventData.type, ...
                    eventData.originator, ...
                    target, ...
                    eventData.data, ...
                    eventData.srcLang);
            end
        end
    end    
end

