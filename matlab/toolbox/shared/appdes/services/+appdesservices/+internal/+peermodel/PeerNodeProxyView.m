classdef PeerNodeProxyView < appdesservices.internal.interfaces.view.AbstractProxyView & ...
    appdesservices.internal.interfaces.controller.mixin.ClientEventReceiver
    % PEERNODEPROXYVIEW The ProxyView which wraps PeerNodes
    %
    % PeerNodeProxyView maintains a link to the view using a Peer Node, which is
    % a server-side "view model".
    %
    % To ferry data from the model to the view, the PeerNodeProxyView
    % keeps this Peer Node's properties populated by taking all properties
    % sent to the ProxyView and forwarding those properties to the Peer
    % Node.
    %
    % To forward user actions on the view to the models, 
    % PeerNodeProxyView observes 'Peer Events' fired by the Peer Node, which
    % represent an action taken by a user in a GUI.  The PeerNodeProxyView will
    % unpackage the event data, which is in the form of Java data
    % structures.  The event will then be re-fired as a 'GuiEvent', and the
    % event data will contain MATLAB data structures for easily processing
    % by other controllers.
    %
    % Additionally, the PeerNodeProxyView observes properties set on the
    % Peer Node from the client.  Similiar to how the 'Peer Event' data is
    % unpackaged and converted to MATLAB friendly GuiEvent, the property
    % changes will also be re-packaged adn fired as 'GuiEvents' with names
    % of 'PropertiesSet'
    
    % Copyright 2012-2019 The MathWorks, Inc.
    
    properties(GetAccess = 'public', SetAccess = 'private')
        % Handle to a com.mathworks.peermodel.PeerNode
        %
        % This PeerNode is populated during construction.
        PeerNode;                
    end
    
    properties(Constant)
        % A static object to be used for Peer Node Event Orginator marker,
        % and it will be only used by the instance of PeerNodeProxyView or
        % its subclass in the PeerNode events as an originator - see
        % isEventFromClient.m
        PeerEventMarkerObject = matlab.lang.internal.uuid;
    end
    
    methods(Access=public)
        function obj = PeerNodeProxyView(peerNode)
            % Creates an PeerNodeProxyView
            %
            % Inputs:
            %
            %   peerNode - A com.mathworks.peermodel.PeerNode
            %
            %              This Peer Node represents the server-side state
            %              of whatever component this ProxyView is
            %              managing. The Peer Node already has its
            %              properties fully populated and the Peer Node
            %              should already have a parent.
            %
            %              Values passed to setProperties() will be then
            %              set on this Peer Node.
            
            % Error Checks
            narginchk(1, 1);
            % Add assertion for ViewModel interface which is part of effort
            % to get rid of PeerModel
            assert(appdesservices.internal.peermodel.PeerNodeProxyView.isNode(peerNode));
            
            % Store inputs
            obj.PeerNode = peerNode;
            
            obj.PropertiesSetHandlerFcn = @obj.firePropertiesSetGuiEvent;
            obj.PeerEventHandlerFcn = @obj.firePeerEventGuiEvent;
            obj.startReceivingClientEvents(obj.PeerNode);
        end
        
        function setProperties(obj, properties, originator)
            % Sets the given pvPairs on this ProxyView's PeerNode
            %
            % Inputs:
            %
            %   pvPairs - A cell array of {name, value, name, value, ...},
            %             or a struct.
            %
            %             The names should all be chars and the values
            %             should be one of the following MATLAB data types:
            %
            %             - double / double array
            %             - char
            %             - cell array of string
            %             - [ ]
            %
            %             These properties will be set on the ProxyView's
            %             Peer Node.
            % properties
            %
            % originator
            
            if nargin == 2
                originator = obj.getId();
            end

            viewmodel.internal.factory.ManagerFactoryProducer.setProperties(obj.PeerNode, ...
                    properties, originator);
        end

        function setPropertiesWithJSONValue(obj, properties, originator)
            % Sets the given pvPairs on this ProxyView's PeerNode
            %
            % Inputs:
            %
            %   properties - A cell array of {name, value, name, value, ...}, 
            %                or a struct.
            %
            %             The names should all be chars and the values
            %             should be a JSON string which has been encoded 
            %             from a MATLAB data type
            %
            %             These properties will be set on the ProxyView's
            %             Peer Node.
            % properties 
            %
            % originator
            
            if nargin == 2
                originator = obj.getId();
            end

            viewmodel.internal.factory.ManagerFactoryProducer.setPropertiesWithJSONValue(obj.PeerNode, ...
                    properties, originator);
        end
        
        function value = getProperty(obj, propertyName)
           % Gets the value of the ProxyView's property propertyName  
           
           value = viewmodel.internal.factory.ManagerFactoryProducer.getProperty(obj.PeerNode, propertyName);
        end
        
        function propertyStruct = getProperties(obj)
           % Gets all properties of the peer node
           
           propertyStruct = viewmodel.internal.factory.ManagerFactoryProducer.getProperties(obj.PeerNode);
        end
        
        function id = getId(obj)
            % GETID(OBJ) returns a string that is the ID of the peer node
            id = char(obj.PeerNode.getId());
        end
        
        function children = getChildren(obj)
            children = obj.getViewModelChildren(obj.PeerNode);
        end
        
        function ix = getChildIndex(obj, child)
            ix = obj.getViewModelChildIndex(child, obj.PeerNode);
        end
        
        function type = getType(obj)
            % GETTYPE(OBJ) returns the type of the peer node
            type = char(obj.PeerNode.getType());
        end
        
        function delete(obj)
            % Detach peer node from Parent
            obj.deletePeerNode();
        end
        
    end
    
    methods (Access=protected)
        function deletePeerNode(obj)
            % this method is to give children classes to overwrite the
            % implementaiton of PeerNode or ViewModel object deletion
            % because during design-time double deletion of ViewModel
            % object on both client and MATLAB side would cause exception,
            % so the design-time proxyview could make it as no-op for this
            % deletion.
            if obj.isValidNode(obj.PeerNode)
                % 1)client-driven workflow would get PeerNode destroyed first
                % 2)re-parenting in runtime would also try to destroy peernode first
                obj.PeerNode.destroy();    
            end
        end
    end
    
    methods(Access = 'private')
        function firePropertiesSetGuiEvent(obj, ~, originalEvent, eventDataStruct)
            % Handles the 'propertiesSet' event from the Peer Node
            %
            % This method will:
            % - unpack event data from Peer Node
            % - re-pack into MATLAB event data
            % - fire a 'GuiEvent' event with the following event data
            % properties:
            %
            %    Name :    'PropertiesSet'
            %  Values :    A struct containing the changed properties
            %
            %       Property1 : new value for Property1
            %       Property2 : new value for Property2
            %       etc...
            %

            % Notify downstream listeners
            eventData = appdesservices.internal.component.view.GuiEventData(eventDataStruct, ...
                originalEvent.getOriginator(), ...
                appdesservices.internal.peermodel.PeerNodeProxyView.isEventFromClient(originalEvent), originalEvent);
            notify(obj, 'GuiEvent', eventData);
        end

        function firePeerEventGuiEvent(obj, ~, originalEvent, eventDataStruct)
            % Handles the 'PeerEvent' from the Peer Node
            %
            % This method will:
            % - unpack event data from Peer Node
            % - re-pack into MATLAB event data
            % - fire a 'GuiEvent' event
            %
            % The incoming event data is a Java Map with keys.  There will
            % always have at least one key:
            %
            %  'Name' : the type of the event, such as 'needledragged'.
            %
            % Additionally, there will be keys specific to the event.
            % These keys will just be unpackaged from the hashmap and put
            % into a struct and refired as new MATLAB event data.

            % Notify downstream listeners
            eventData = appdesservices.internal.component.view.GuiEventData(eventDataStruct, ...
                originalEvent.getOriginator(), ...
                appdesservices.internal.peermodel.PeerNodeProxyView.isEventFromClient(originalEvent), originalEvent);
            notify(obj, 'GuiEvent', eventData);
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Help shim methods for migrating into ViewModel (CPP)
    % We keep the helper methods here just for a central place to
    % manage calling to ViewModel shim APIs 
    % When PeerModel is going to be removed, we could only modify this file
    % Another reason we put these here is:
    % PeerNodeProxyView should be refactored when PeerModel is going to be
    % removed.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Static)
        function vmManager = getViewModelManager(mode, namespace, varargin)
            vmManagerFactory = appdesservices.internal.peermodel.PeerNodeProxyView.getViewModelManagerFactory(mode);
            
            vmManager = vmManagerFactory.getViewModelManager(namespace, varargin{:});
        end
        
        function factory = getViewModelManagerFactory(mode)
            factory = viewmodel.internal.factory.ManagerFactoryProducer.(mode);
        end
        
        function [m, s] = getPossibleViewModelModes()
            [m, s] = enumeration('viewmodel.internal.factory.ManagerFactoryProducer');
        end
        
        function isVM = isViewModel(viewModelObject)
            isVM = viewmodel.internal.factory.ManagerFactoryProducer.isViewModel(viewModelObject);
        end        
        
        function isManager = isManager(viewModelObject)
            isManager = viewmodel.internal.factory.ManagerFactoryProducer.isManager(viewModelObject);
        end
        
        function isNode = isNode(viewModelObject)
            isNode = viewmodel.internal.factory.ManagerFactoryProducer.isNode(viewModelObject) || isa(viewModelObject, 'FakeViewModel');
        end
        
        function isValid = isValidNode(viewModelObject)
            isValid = viewmodel.internal.factory.ManagerFactoryProducer.isValidNode(viewModelObject);
        end
        
        function isFromClient = isEventFromClient(event, varargin)
            isFromClient = viewmodel.internal.factory.ManagerFactoryProducer.isEventFromClient(event, varargin{:});
        end
        
        function children = getViewModelChildren(viewModelObject)
            children = viewmodel.internal.factory.ManagerFactoryProducer.getChildren(viewModelObject);
        end
        
        function ix = getViewModelChildIndex(viewModelObject, parentViewModelObject)
            ix = viewmodel.internal.factory.ManagerFactoryProducer.getChildIndex(viewModelObject, parentViewModelObject);
        end
        
        function data = convertEventDataToStruct(eventData)
            data = viewmodel.internal.factory.ManagerFactoryProducer.convertEventDataToStruct(eventData);
        end
    end
    
end


