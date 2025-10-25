classdef TestRunnerPluginService < matlab.unittest.internal.services.Service
    % TestRunnerPluginService - Interface for services that provide TestRunnerPlugins.    
    %
    %   Plugins provided by TestRunnerPluginServices are used when running 
    %   tests that utilize the MATLAB Unit Test Runner via runtests.
    %
    % See Also: matlab.unittest.internal.services.Service,
    %           matlab.automation.internal.services.ServiceLocator,
    %           matlab.unittest.internal.services.ServiceFactory
    
    % Copyright 2017-2023 The MathWorks, Inc.
    
    methods (Abstract)
        % providePlugins - Provide plugins to the testing framework.
        %
        %   PLUGINS = providePlugins(SERVICE, PLUGINPROVIDERDATA) should be implemented 
        %   to return an array of zero or more TestRunnerPlugins that are to be used when
        %   running tests. The method can return an empty array in the case where
        %   it is not appropriate to return any plugins given the environmental
        %   state at the time the method is invoked. The method can also return a
        %   vector of plugins if the service needs to provide more than one
        %   plugin. PLUGINPROVIDERDATA is a matlab.unittest.internal.plugins.PluginProviderData 
        %   object which can be used to determine the right type of plugin 
        %   to be returned.
        plugins = providePlugins(service, pluginProviderData)
    end    
    
    methods (Sealed)
        function fulfill(services, liaison)
            % fulfill - Fulfill an array of TestRunnerPluginServices.
            %
            %   fulfill(SERVICES,LIAISON) fulfills an array of TestRunnerPluginServices
            %   by calling the providePlugins method on each element of the array. The
            %   plugins provided by all the services are provided to the liaison.
            
            plugins = arrayfun(@(s)makeRow(s.providePlugins(liaison.PluginProviderData)), services, 'UniformOutput',false);
            liaison.Plugins = [matlab.unittest.plugins.TestRunnerPlugin.empty(1,0), plugins{:}];
        end
    end
end

function row = makeRow(anyMatrix)
row = reshape(anyMatrix, 1, []);
end

% LocalWords:  PLUGINPROVIDERDATA
