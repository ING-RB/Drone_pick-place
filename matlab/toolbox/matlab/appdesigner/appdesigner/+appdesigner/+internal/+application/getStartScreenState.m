function state = getStartScreenState(resetAfter)
    % Used by client to retrieve start screen - related parameters
    %
    
    % Copyright 2021 The MathWorks, Inc.
    if(nargin == 0)
        resetAfter = false;
    end
    
    ade = appdesigner.internal.application.getAppDesignEnvironment();
    
    if(isempty(ade.StartScreenStateModel))
        % This is possible when state is requested but App Designer has not
        % started yet.
        %
        % Having this happens is less than ideal but needed at times, such
        % as a user just launching App Designer with a URL
        
        ade.initializeStartScreenState();
    end
    
    state = ade.StartScreenStateModel.State;        
    
    if(resetAfter)
        % Clean out the state
        ade.StartScreenStateModel = appdesigner.internal.application.startup.StartScreenStateModel.empty();
    end
    
    % Run async task when start screen state is returned to client side,
    % because feval() from client side would be put into MVM queue, which
    % would wait for other tasks to complete to cause JS end delay.
    % We should be able to move this back to AppDesignerEnvrionment when
    % we can use bacgroundPool() to run asyn tasks in a separated thread.
    ade.runAsyncStartupTasks();
end