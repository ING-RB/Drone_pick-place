classdef EventHandle < dynamicprops
    %EVENTHANDLE Representation of an event (or multiple events). Users of
    %the handle can notify listeners of a specific event without having to
    %define / own the event.
    
    % Copyright 2018 The MathWorks, Inc.    

    properties (SetAccess = protected)
        Name (1, :) string = strings(1, 0)
    end
    
    methods
        function obj = EventHandle(name)
            obj.addEvent(name);
        end
        
        function addEvent(obj, name)
            try
                prop = obj.addprop(name);
                prop.SetObservable = true;
                prop.AbortSet = true;
                obj.Name(end+1) = name;
            catch e
                switch e.identifier
                    case 'MATLAB:class:PropertyInUse'
                        error(message('testmeaslib:AsyncioBuffer:EventNameExists', name));
                    otherwise
                        rethrow(e)
                end
            end
        end
        
        function removeEvent(obj, name)
            idx = strcmp(obj.Name, name);
            
            if any(idx)
                obj.Name(idx) = [];
                delete(obj.findprop(name));
            end            
        end
    end
    
    %% Handle (overrides)
    methods
        function e = listener(eventHandle, eventSource, eventName, callback)
            % LISTENER Overrides handle.listener
            %
            % LISTENER(EVENTHANDLE, EVENTSOURCE, EVENTNAME, CALLBACK)
            
            % If the listener is defined on an EVENTNAME corresponding to a
            % property/event pointed to by the handle, then it will define
            % proplistener for that property (using EVENTHANDLE). If the
            % EVENTNAME does not correspond to the handle, then a standard
            % listener is defined on the source of the event/handle.
            %
            % Inputs: 
            % EVENTHANDLE - The event handle object
            % 
            % EVENTSOURCE - The object that is the actual source of the
            % event
            %
            % EVENTNAME - Name of the event to listen for
            %
            % CALLBACK - Function to execute
            
            narginchk(4, 4)
            
            if any(strcmp(eventHandle.Name, eventName))
                e = listener@handle(eventHandle, eventName, 'PostSet', callback);
            else
                e = listener@handle(eventSource, eventName, callback);
            end            
        end
    end
    
    %% Save / Load    
    methods
        function s = saveobj(obj)
            s.Name = obj.Name;
        end
    end
    
    methods (Hidden, Static)
        function eh = loadobj(s)
            if isstruct(s)
                name = s.Name;
                eh = matlabshared.asyncio.buffer.internal.EventHandle(name(1));
                
                for idx = 2:length(name)
                    eh.addEvent(name(idx));
                end
            else
                eh = s;
            end
        end
    end     
    
end
