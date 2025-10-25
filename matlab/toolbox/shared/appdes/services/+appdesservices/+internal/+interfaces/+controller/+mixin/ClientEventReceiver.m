classdef ClientEventReceiver < handle
    properties(Access = protected)
        PropertiesSetHandlerFcn
        PeerEventHandlerFcn
    end

    properties(Access = private)
        % These listeners are tracked so they can be properly cleaned up when
        % this ProxyView is deleted.

        ClientEventSource

        % Listener to 'peerEvent' of the PeerNode
        PeerEventListener

        % Listener to 'propertiesSet' of the PeerNode
        PropertiesSetListener
    end

    methods
        function startReceivingClientEvents(obj, source)
            assert(isempty(obj.ClientEventSource), 'Client event source should be set only once');
            obj.ClientEventSource = source;

            % Attach to the 'PeerEvent', saving the listener so we can cleanup later
            obj.PeerEventListener = addlistener(source, 'peerEvent', @obj.handlePeerEventFromClient);

            % Listen to property changes
            obj.PropertiesSetListener = addlistener(source, 'propertiesSet', @obj.handlePropertiesSetFromClient);
        end

        function stopReceivingClientEvents(obj)
            % Clean up java based peer node listeners
            if ishandle (obj.PeerEventListener)
                delete(obj.PeerEventListener);
            end
            if ishandle (obj.PropertiesSetListener)
                delete(obj.PropertiesSetListener);
            end
        end

        function disablePeerEventListener(obj)
            % DISABLEPEEREVENTLISTENER - deletes the peer node listener for
            % 'peerEvent' events.
            delete(obj.PeerEventListener);
        end

        function disablePropertiesSetListener(obj)
            % DISABLEPROPERTIESSETLISTENER - deletes the peer node listener for
            % 'propertiesSet' events.
            delete(obj.PropertiesSetListener);
        end

        function delete(obj)
            stopReceivingClientEvents(obj);
        end
    end

    methods(Access = private)
        function isSelf = isEventOriginatedFromSelf(obj, event)
            isSelf = ~event.isFromClient() && ~strcmp(obj.ClientEventSource.Id, event.getOriginator());
        end

        function isValid = isEventSourceValid(obj)
            if ~isvalid(obj) || ~viewmodel.internal.factory.ManagerFactoryProducer.isValidNode(obj.ClientEventSource)
                % Under MF0ViewModel, it's possible the ProxyView has been
                % deleted because of reacting to PeerEvent, for instance,
                % opening and closing an app soon, but ViewModel may still
                % be in the process of firing event.
                % Todo: ViewModel layer should dput some robust checking there.
                isValid = false;
            else
                isValid = true;
            end
        end

        function handlePeerEventFromClient(obj, source, event)
            if ~obj.isEventSourceValid
                return;
            end

            narginchk(3, 3);

            if obj.isEventOriginatedFromSelf(event)
                % Avoid reentering if event triggered from the same instance
                return;
            end

            eventDataStruct = obj.unpackPeerEvent(event);

            obj.PeerEventHandlerFcn(source, event, eventDataStruct);
        end

        function handlePropertiesSetFromClient(obj, source, event)
            if ~obj.isEventSourceValid
                return;
            end

            narginchk(3, 3);

            if obj.isEventOriginatedFromSelf(event)
                % Avoid reentering if event triggered from the same instance
                return;
            end

            % Create the struct to hold all changed properties
            newValuesStruct = obj.unpackPropertiesSetEvent(event);

            % Create MCOS event data
            eventDataStruct.Name = 'PropertiesChanged';
            eventDataStruct.Values = newValuesStruct;

            obj.PropertiesSetHandlerFcn(source, event, eventDataStruct);
        end
    end

    methods(Static)
        function eventData = unpackPeerEvent(event)
            % Unpacks 'peerEvent' data from a view model event
            %
            % The incoming event data is a Java Map with keys. There will
            % always have at least one key:
            %  'Name' : the type of the event, such as 'needledragged'.
            %
            % Additionally, there will be keys specific to the event.
            % These keys will just be unpackaged from the hashmap and put
            % into a struct and returned.

            % Get all the event data's names
            eventDataHashMap = event.getData();

            % Error Checking
            assert(eventDataHashMap.containsKey('Name'), ...
                'The event data is malformed.  It does not contain a ''Name'' field.');

            eventData = viewmodel.internal.factory.ManagerFactoryProducer.convertEventDataToStruct(eventDataHashMap);
        end

        function newValues = unpackPropertiesSetEvent(event)
            % Unpacks the 'propertiesSet' data from a view model event
            %
            % The incoming event data will have a key, 'newValues', which
            % is a Java Map. This map contains entries for the properties
            % that changed to trigger the event.

            % Get all the event data's names
            eventDataJavaMap = event.getData();

            % Error Checking
            assert(eventDataJavaMap.containsKey('newValues'), ...
                'The event data is malformed.  It does not contain a ''newValues'' field.');

            newValuesJavaMap = eventDataJavaMap.get('newValues');

            % Create the struct to hold all changed properties
            newValues = viewmodel.internal.factory.ManagerFactoryProducer.convertEventDataToStruct(newValuesJavaMap);
        end
    end
end