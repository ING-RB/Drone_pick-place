
%

%   Copyright 2010-2013 The MathWorks, Inc.

classdef M3IUserMessageStream < handle
    methods (Access=public, Static)
        
        function addStreamListener(listener)
            % Remove the listener if it has been added.
            M3IUserMessageStream.streamListeners('remove', listener);
            % Add the listener to the end.
            M3IUserMessageStream.streamListeners('add', listener);
        end
        
        function removeStreamListener(listener)
            M3IUserMessageStream.streamListeners('remove', listener);
        end
        
    end
    
    % Called from C++
    methods(Access=public, Static)
        
        function clear(~)
            listeners = M3IUserMessageStream.streamListeners('get');
            for i=1:numel(listeners)
                listener = listeners{i};
                listener.flush();
            end
        end
        
        function pushMsg(type, classifier, source, summary, reportedBy, details)            
            % Pass the message on to all the listeners.
            listeners = M3IUserMessageStream.streamListeners('get');
            for i=1:numel(listeners)
                listener = listeners{i};
                try
                    handleMessage(listener, type, classifier, source, summary, reportedBy, details);
                catch ME
                    % remove M3I error stacks
                    ME.throwAsCaller();
                end
            end
        end
        
        function flush(~)
            listeners = M3IUserMessageStream.streamListeners('get');
            for i=1:numel(listeners)
                listener = listeners{i};
                listener.flush();
            end
        end
        
    end
    
    methods (Access=private, Static)
        % Emulate a modifiable static property.
        function listeners = streamListeners(mode, arg)
            persistent pListeners;
            
            if isempty(pListeners)
                pListeners = {};
            end
           
            mode = lower(mode);
            
            switch mode
                case 'add',
                    pListeners{end+1} = arg;
                    listeners = pListeners;
                    
                case 'remove',
                    for i=numel(pListeners):-1:1
                        if pListeners{i} == arg
                            pListeners(i) = [];
                        end
                    end
                    
                case 'get',
                    listeners = pListeners;
                    
                otherwise
                    throw('mode must be add, remove or get');
            end
        end
        
    end
end