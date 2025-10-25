% WEBEVENTHANDLINGSERVICE As a core service of the MATLAB Component Framework 
% (MCF), the Event Handling Service (EHS) is designed to provide the capability
% to customize the way web components and their corresponding controllers are 
% able to handle events. Events can either be server or client driven and 
% typically take the form of user interactions, which translate to property
% updates and/or deletions, view element additions/deletions and/or other
% forms of web-based events with a payload.

%   Copyright 2014-2023 The MathWorks, Inc.

classdef WebEventHandlingService < handle

  properties( Access = private )

    % View abstraction
    ViewModel = appdesservices.internal.interfaces.view.EmptyViewModel.Instance;

    % Listener for property updates
    PropertyUpdateListener

    % Listener for property deletions
    PropertyDeletionListener

    % Listener for child additions in terms of view elements
    ChildAdditionListener

    % Listener for child deletions in terms of view elements
    ChildDeletionListener

    % General purpose event listener
    EventListener

  end

  methods

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %  Method:      isServerEvent
    %
    %  Inputs :     event -> Event payload.
    %  Outputs:     flag -> Boolean indicating the event origination. If true,
    %                       the event origination is the server.
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function flag = isServerEvent( ~, event )
       % Method which deciphers the event payload to determine the origin of the
       % event. If the event is server-based, returns true.
       flag = ~viewmodel.internal.factory.ManagerFactoryProducer.isEventFromClient(event);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %  Method:      isClientEvent
    %
    %  Inputs :     event -> Event payload.
    %  Outputs:     flag  -> Boolean indicating the event origination.
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function flag = isClientEvent( obj, event )
       % Method which deciphers the event payload to determine the origin of the 
       % event. If the event is client-based, returns true.
       flag = ~obj.isServerEvent( event );
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %  Method:         attachView
    %
    %  Inputs :        view -> View to which the EHS will attach to.
    %  Outputs:        None.
    %  Postconditions: EHS ready to respond to the view events as customized by     
    %                  the addition of listeners.
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function attachView( obj, view )
      % MATLAB Component Framework's (MCF) Event Handling Service (EHS) needs a 
      % view to start handling events. This method attaches the EHS to the view
      % of interest.
      obj.ViewModel = view;
   end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %  Method:         clearView
    %
    %  Inputs :        None.
    %  Outputs:        None.
    %  Postconditions: View representation destroyed by the EHS.
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function clearView( obj )
       % Method which removes the view representation of the web component from 
       % the view hierarchy. 
       if viewmodel.internal.factory.ManagerFactoryProducer.isValidNode( obj.ViewModel )
         destroy(obj.ViewModel);
       end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %  Method:      dispatchEvent
    %
    %  Inputs :     eventName -> Name of the event.
    %               payload -> Event payload.
    %  Outputs:     None.
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function dispatchEvent( obj, eventName, payload )
       % Method which triggers a server-driven event on the view which the Event
       % Handling Service has been attached to.
       if ~isempty(obj.ViewModel)
           if( exist( 'payload', 'var' ) )
               namedPayload = obj.convertPvPairsToStruct(payload);
           end
           namedPayload.Name = eventName;
           viewmodel.internal.factory.ManagerFactoryProducer.dispatchEvent(obj.ViewModel, ...
               'peerEvent', namedPayload);
       end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %  Method:      hasProperty
    %
    %  Inputs :     property -> Name of the property.
    %  Outputs:     Boolean which indicates if the property participates in the 
    %               view representation.
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function flag = hasProperty( obj, property )
       % Method which determines if the provided property participates in the   
       % view representation of the web component.
       flag = false;
       if ~isempty(obj.ViewModel) && isvalid(obj.ViewModel)
         flag = obj.ViewModel.hasProperty( property );
       end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %  Method:      setProperty
    %
    %  Inputs :     property -> Name of the property to set.   
    %               value -> Value to set the property to.     
    %  Outputs:     None.                         
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function setProperty( obj, property, value )
       % Method which sets the value of the property. 
       pvPair = { property, value };
       
       obj.setProperties(pvPair);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %  Method:      setPropertyWithCommit
    %
    %  Inputs :     property -> Name of the property to set.   
    %               value -> Value to set the property to.     
    %  Outputs:     None.                         
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function setPropertyAndCommit( obj, property, value )
        % Method which sets the value of a property and commits the
        % transaction. Commiting the transaction is essential if the
        % property exists only in the View or if the property is updated
        % without marking an equivalent Model property as dirty.
        pvPairCell = { property, value };
        obj.setProperties(pvPairCell);

        obj.dispatchEvent([], pvPairCell);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %  Method:      setProperties
    %
    %  Inputs :     pvPairs -> Property/value pairs.
    %  Outputs:     None.
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function setProperties( obj, pvPairs )
	    if ~isempty(obj.ViewModel) && isvalid(obj.ViewModel)
		   % Method which sets the view properties to the values provided through
		   % the PV (property/value) pairs.
		   viewmodel.internal.factory.ManagerFactoryProducer.setProperties(...
			   obj.ViewModel, ...
			   appdesservices.internal.peermodel.convertPvPairsToStruct(pvPairs));
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %  Method:      deleteProperty
    %
    %  Inputs :     property -> Name of the property to delete.
    %  Outputs:     None.
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function deleteProperty( obj, property )
       % Method which removes the property from the view representation.         
       obj.ViewModel.unsetProperty( property );
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %  Method:      getProperty
    %
    %  Inputs :     Property name.
    %  Outputs:     Property value to get.
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function value = getProperty( obj, property )
       % Method which gets the value of the property.
       value = obj.ViewModel.getProperty( property );
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %  Method:          attachPropertyUpdateListener
    %
    %  Inputs :         handler -> Method handler for property updates.
    %  Outputs:         None.                     
    %  Postconditions:  Listener created for property updates. Handle to this
    %                   listener is saved for later use. 
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function attachPropertyUpdateListener( obj, handler )
        % Method which attaches a listener for property updates.
        obj.PropertyUpdateListener = addlistener(...
            obj.ViewModel, 'propertySet', handler);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %  Method:          attachPropertyDeletionListener
    %
    %  Inputs :         handler -> Method handler for property deletes.
    %  Outputs:         None.                     
    %  Postconditions:  Listener created for property deletes. Handle to this
    %                   listener is saved for later use.
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function attachPropertyDeletionListener( obj, handler )
        % Method which attaches a listener for property deletes.        
        obj.PropertyDeletionListener = addlistener(...
                obj.ViewModel, 'PropertyUnset', handler );
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %  Method:          attachChildAdditionListener
    %
    %  Inputs :         handler -> Method handler for child additions. 
    %  Outputs:         None.                     
    %  Postconditions:  Listener created for child additions. Handle to this
    %                   listener is saved for later use.
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function attachChildAdditionListener( obj, handler )
        % Method which attaches a listener for child additions.
        obj.ChildAdditionListener = addlistener(...
                obj.ViewModel, 'childAdded', handler );
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %  Method:          attachChildDeletionListener
    %
    %  Inputs :         handler -> Method handler for child deletions. 
    %  Outputs:         None.                     
    %  Postconditions:  Listener created for child deletions. Handle to this
    %                   listener is saved for later use.
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function attachChildDeletionListener( obj, handler )
       % Method which attaches a listener for child deletions.
       obj.ChildDeletionListener = addlistener(...
               obj.ViewModel, 'childRemoved', handler );
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %  Method:          attachEventListener
    %
    %  Inputs :         Method handler.
    %  Outputs:         None.                     
    %  Postconditions:  Listener created for general purpose events. Handle to               
    %                   this listener is saved for later use.
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function attachEventListener( obj, handler )
       % Method which attaches a listener for general purpose events.
       obj.EventListener = ...
               addlistener(...
               obj.ViewModel, 'peerEvent', handler );
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %  Method:         attachPropertyListeners
    %
    %  Inputs :        updateHandler -> Handler for property updates.
    %                  deletionHandler -> Handler for property deletions.
    %  Outputs:        None.                     
    %  Postconditions: Listeners created for property updates and deletions.                 
    %                  Handles to these listeners are saved for later use.
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function attachPropertyListeners( obj, updateHandler, deletionHandler )
       % Method which attaches listeners for property updates and deletions.
       obj.attachPropertyUpdateListener( updateHandler );
       obj.attachPropertyDeletionListener( deletionHandler );
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %  Method:         attachChildListeners
    %
    %  Inputs :        childAdditionHandler -> Handler for child additions.
    %                  childDeletionHandler -> Handler for child deletions.
    %  Outputs:        None.                     
    %  Postconditions: Listeners created for child additions and deletions.                  
    %                  Handles to these listeners are saved for later use.
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function attachChildListeners( obj, ...
                                   childAdditionHandler, ...
                                   childDeletionHandler )
       % Method which attaches listeners for child additions and deletions. 
       obj.attachChildAdditionListener( childAdditionHandler );
       obj.attachChildDeletionListener( childDeletionHandler );
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %  Method:         removePropertyListeners
    %
    %  Inputs :        None. 
    %  Outputs:        None.                     
    %  Postconditions: Listeners removed for property updates and deletions.                 
    %                  Previously stored listener handles are discarded.  
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function removePropertyListeners( obj )
       % Method which removes listeners for property updates and deletions. 
       delete( obj.PropertyUpdateListener );
       delete( obj.PropertyDeletionListener );
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %  Method   :      removeChildListeners
    %
    %  Inputs :        None. 
    %  Outputs:        None.                     
    %  Postconditions: Listeners removed for child additions and deletions.                 
    %                  Previously stored listener handles are discarded.  
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function removeChildListeners( obj )
       % Method which removes listeners for child additions and deletions.  
       delete( obj.ChildAdditionListener );
       delete( obj.ChildDeletionListener );
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %  Method:         removeEventListener
    %
    %  Inputs :        None. 
    %  Outputs:        None.                     
    %  Postconditions: Listener removed for general purpose events. Previously                         
    %                  stored listener handle is discarded.
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function removeEventListener( obj )
       % Method which removes the listener for general purpose events.      
       delete( obj.EventListener );
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %  Method:        getUpdatedProperty
    %
    % Inputs :        event -> Event data.
    % Outputs:        property -> Name of the updated property.
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function property = getUpdatedProperty( obj, event )
       % Method which retrieves the name of the updated property.
        property = event.Data.key;
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %  Method:      getEventStructure
    %
    %  Inputs :     event -> Event data.
    %  Outputs:     eventStructure -> MATLAB based event structure.
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function eventStructure = getEventStructure( ~, event )
       % Method which converts the event data into a MATLAB structure. 
       eventStructure = viewmodel.internal.factory.ManagerFactoryProducer.convertEventDataToStruct(event.getData);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %  Method:      convertPvPairsToJavaMap
    %
    %  Inputs :     pvPairs -> Property/value pairs.
    %  Outputs:     javaMap -> Java map converted from the PV pairs.
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function javaMap = convertPvPairsToJavaMap( ~, pvPairs )
       % Method which converts the PV pairs to java map.                    
       javaMap = appdesservices.internal.peermodel.convertPvPairsToJavaMap( pvPairs ); 
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %  Method:         convertPvPairsToStruct
    %
    %  Inputs:         pvPairs -> Property/value pairs to be converted.
    %  Outputs:        structFormat -> MATLAB structure for the PV pairs.      
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function structFormat = convertPvPairsToStruct( ~, pvPairs )
       % Converts the PV pairs into MATLAB structure.
       structFormat = appdesservices.internal.peermodel.convertPvPairsToStruct( pvPairs );
    end

  end

  methods (Static)
      function vmm = getViewModelManager(mode, namespace, varargin)
          factory = viewmodel.internal.factory.ManagerFactoryProducer.(mode);
          vmm = factory.getViewModelManager(namespace, varargin{:});
      end
      
      function childNode = addChild(node, type, varargin)
          childNode = viewmodel.internal.factory.ManagerFactoryProducer.addChild(node, type,varargin{:});
      end
      
      function children = getChildren(node)
          children = viewmodel.internal.factory.ManagerFactoryProducer.getChildren(node);
      end
  end
end
