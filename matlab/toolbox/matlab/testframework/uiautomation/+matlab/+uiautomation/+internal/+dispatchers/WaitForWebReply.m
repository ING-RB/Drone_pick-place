classdef WaitForWebReply < matlab.uiautomation.internal.dispatchers.DispatchDecorator
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2017-2023 The MathWorks, Inc.
    
    properties (Access = private)
        Pending = false;
        ProgressTimer;
        SettledState = [];
        SubIDs = {};
    end
    
    properties (Constant, Access = private)
        FulfillChannel = "/uitest/fulfilled";
        WarnChannel    = "/uitest/settledWithWarnings";
        RejectChannel  = "/uitest/rejected";
        LogChannel = "/uitest/log";
        OverallTimeOut = 300;  % Maximum overall time to wait.
        ProgressTimeout = 20;  % Maximum time between progress updates.
    end
    
    methods
        function decorator = WaitForWebReply(delegate)
            decorator@matlab.uiautomation.internal.dispatchers.DispatchDecorator(delegate);
        end
        
        function dispatch(decorator, model, evtName, varargin)
            import matlab.uiautomation.internal.FigureHelper;
            
            connector.ensureServiceOn;
            decorator.subscribe();
            clean = onCleanup(@()decorator.unsubscribe);
            
            decorator.Pending = true;
            
            dispatch@ ...
                matlab.uiautomation.internal.dispatchers.DispatchDecorator( ...
                decorator, model, evtName, varargin{:});

            settled = decorator.block();
            settled.resolve();
        end
        
    end
    
    methods (Access = protected)
        function settledState = fulfill(dispatcher, ~)
            import matlab.uiautomation.internal.dispatchstate.Fulfilled;
            
            settledState = Fulfilled();
            dispatcher.unblock(settledState);
        end
        
        function settledState = settleWithWarnings(dispatcher, eventdata)
            import matlab.uiautomation.internal.dispatchstate.SettledWithWarnings;
            
            settledState = SettledWithWarnings(message(eventdata.MessageInput{:}));
            dispatcher.unblock(settledState);
        end
        
        function settledState = reject(dispatcher, eventdata) 
            import matlab.uiautomation.internal.dispatchstate.Rejected;
            
            me = MException( message(eventdata.MessageInput{:}) );
            settledState = Rejected(me);
            dispatcher.unblock(settledState);
        end
        
        function settledState = block(dispatcher)
            import matlab.uiautomation.internal.dispatchstate.Rejected;
            
            overallTimer = tic;
            dispatcher.ProgressTimer = tic;
            while dispatcher.Pending && ...
                    toc(overallTimer) <= dispatcher.OverallTimeOut && ...
                    toc(dispatcher.ProgressTimer) <= dispatcher.ProgressTimeout
                drawnow limitrate
            end

            drawnow limitrate
            
            if dispatcher.Pending
                % still pending past timeout
                me = MException(message("MATLAB:uiautomation:Driver:GestureNotCompleted", ...
                    round(toc(overallTimer))));
                settledState = Rejected(me);
                return
            end
            
            % hand off resulting state
            settledState = dispatcher.SettledState;
            dispatcher.SettledState = [];
        end
        
        function unblock(dispatcher, state)
            dispatcher.Pending = false;
            dispatcher.SettledState = state;
        end
        
    end
    
    methods (Access = private)
        function resetTimer(dispatcher, ~)
            % Incremental client progress; reset timeout.
            dispatcher.ProgressTimer = tic;
        end

        function subscribe(dispatcher)
            dispatcher.SubIDs{1} = message.subscribe(...
                dispatcher.FulfillChannel, @(data)dispatcher.fulfill(data));
            dispatcher.SubIDs{2} = message.subscribe(...
                dispatcher.WarnChannel, @(data)dispatcher.settleWithWarnings(data));
            dispatcher.SubIDs{3} = message.subscribe(...
                dispatcher.RejectChannel, @(data)dispatcher.reject(data));
            dispatcher.SubIDs{4} = message.subscribe(...
                dispatcher.LogChannel, @(data)dispatcher.resetTimer(data));
        end
        
        function unsubscribe(dispatcher)
            sub = dispatcher.SubIDs;
            for k=1:length(sub)
                message.unsubscribe(sub{k})
            end
        end
        
    end
    
end

% LocalWords:  uitest evt dispatchstate eventdata limitrate
