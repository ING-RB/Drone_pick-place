classdef AbstractProxyView < handle
    % ABSTRACTPROXYVIEW is an abstraction for a view, the V in MVC.
    %
    % AbstractProxyView provides the following:
    %
    % - A common method setProperties() which controllers may use to pass
    %   data to the view.  The controller will remain decoupled from the
    %   implementation of where these properties are going, be it over a
    %   web socket, being sent directly to a Java control, etc...
    %
    % - A common event 'GuiEvent' which controllers may subscribe to so
    %   that they can observe user interactions on the view.  The controller
    %   remain decoupled from how this event was captured from the user,
    %   be it an HTML DOM listener, a Java ActionListener, etc...
    
    % Copyright 2012 MathWorks, Inc.    
    
    
    methods(Access = 'public', Abstract)
        % SETPROPERTIES(OBJ, PVPAIRS) should be used whenever a controller
        % wishes to push data to the view.
        %
        % Implementations should ensure that these updates get set on the
        % real view, whether it be a MOTW peer node, a Java control, etc...
        setProperties(obj, pvPairs)
            
        % GETID(OBJ) returns a string ID        
        id = getId(obj)
        
        % GETPROPERTIES(OBJ) Gets the value of all ProxyView's properties
        % as a MATLAB struct
        valueStruct = getProperties(obj)    
    end    
    
    events
        % This event will be published whenever the user interacts with the
        % view on the client.
        %
        % The "event" will have an "EventData" field like all MATLAB
        % events.
        %
        % The EventData field will always be a struct.  The struct will
        % always have a 'Name' field which is used to identify the type of
        % user interaction that occured (ButtonPushed, MouseClicked,
        % etc...).
        %
        % Depending on the type of event, additional fields will be in the
        % struct so that controllers can respond appropriately.
        GuiEvent
    end
    
    methods
       
        function notify(obj, varargin)
            % Override the default notify method.
            % When the user has errors in his callbacks, the errors are
            % thrown as warnings and those warnings show the backtrace
            % indicating which event the callback was responding to. 
            % We want to hide the backtrace from the user because it 
            % shows internal code that is not useful for his purpose.
            
            % Turn off the backtrace and store the current warning state
            ws = warning('off', 'backtrace');
            
            % Call the notify method from the super class
            obj.notify@handle(varargin{:});
            
            % Restore the old warning state
            oc = onCleanup(@()warning(ws));            
            
        end
        
       
        
    end
end



