function state = getStartupState(resetAfter)
    % Used by client to retrieve all startup - related parameters
    %
    % resetAfter = optional parameter that means "once this data is
    % retrieved, any temporary state in the startup state providers should
    % be reset"
    %
    % For example, once App Designer is loaded and its initial state is
    % shown (ex: an open app, a tutorial, etc...) we do not want to re-do
    % that same action when we start up
    
    % Copyright 2018 The MathWorks, Inc.
    if(nargin == 0)
        resetAfter = false;
    end
    
    ade = appdesigner.internal.application.getAppDesignEnvironment();
    
    if(isempty(ade.StartupStateModel))
        % This is possible when state is requested but App Designer has not
        % started yet.
        %
        % Having this happens is less than ideal but needed at times, such
        % as a user just launching App Designer with a URL
        
        ade.initializeStartupState();
    end
    
    state = ade.StartupStateModel.State;        
    
    if(resetAfter)
        % Clean out the state
        ade.StartupStateModel = appdesigner.internal.application.startup.StartupStateModel.empty();
    end    
end