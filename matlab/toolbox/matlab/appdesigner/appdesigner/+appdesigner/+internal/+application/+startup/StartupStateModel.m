classdef  StartupStateModel < handle
	% Represents the sum of all state retrieved from
	% StartupStateProviders
	%
	% To use:
    %
	%  state =
	%  appdesigner.internal.application.state.StartupStateModel(startupStateProviders)
	%  state.initialize(startupArguments);
	%  allState = state.State;

	% Copyright 2018 The MathWorks, Inc.

	properties
		% All state from each StartupStateProvider
		State struct = struct();
        
        StartupStateProviders;            
    end    

	methods
        
        function obj = StartupStateModel(startupStateProviders)
            obj.StartupStateProviders = startupStateProviders;
        end
        
		function initialize(obj, startupArguments)
			% Populates all state
			%
			% This method will find all StartupStateProviders on the
			% path, query them for their state, and populate this object's
			% State property
            %
            % Input parameters:
            % startupArguments - arguments that were passed to appDesignEnvironment.start()
            % with fieldnames associated with the arguments' role e.g. FileName, Tutorial, URL            
            
            providers = obj.StartupStateProviders;

            allState = struct;

			for idx = 1:length(providers)

				providerInstance = providers{idx};

				% Gets its state
				providersState = providerInstance.getState(startupArguments);

				% Take this providers state and merge it into the overall
				% state
				providerFieldNames = fieldnames(providersState);
				for jdx = 1:length(providerFieldNames)
					allState.(providerFieldNames{jdx}) = providersState.(providerFieldNames{jdx});
				end
			end

			% Store for future access
			obj.State = allState;

		end
	end
end
