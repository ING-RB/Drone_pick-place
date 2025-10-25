classdef StartupStateProviderFactory < handle
    %STARTUPSTATEPROVIDERFACTORY
    %
    % Abstract factory class to return a set of StartupStateProviders
    %
    % Factory is used to encapsulate exactly what set of startup state
    % providers to use in a given context.
    %
    % Subclasses are expected to define a list of packages in
    % StartupStateProviderPackages, which will be quiered for
    % startup state providers classdefs.
    %
    % When createStartupStateProviders is called, the classes found in the
    % packages will be instantiated and returned.
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties(Abstract)
        StartupStateProviderPackages cell;
    end
    
    methods(Sealed)
        
        function allProviders = createStartupStateProviders(obj)
            % Factory method to get all providers
            %
            % This is the public interface to retrieve providers
            allProviders = {};
            
            for idx = 1:length(obj.StartupStateProviderPackages)                                
                providers = obj.discoverProvidersInPackage(obj.StartupStateProviderPackages{idx});                
                allProviders = [allProviders providers];                             
            end
        end
    end
    
    methods(Access = 'private')
        function providers = discoverProvidersInPackage(obj, packageName)            
            % Given a package name.. will find all startup state providers,
            % instantiate them, and return in a cell array
            
            % Find all providers
            subclassMetaClasses = internal.findSubClasses( ...
                packageName, ...
                'appdesigner.internal.application.startup.StartupStateProvider', ...
                true);
            
            providers = {};
            
            for idx = 1:length(subclassMetaClasses)
                
                % Create a provider based on the meta class
                providerMetaClass = subclassMetaClasses{idx};
                providerInstance = eval(providerMetaClass.Name);
                
                providers = [providers, {providerInstance}];
            end
        end
    end
end

