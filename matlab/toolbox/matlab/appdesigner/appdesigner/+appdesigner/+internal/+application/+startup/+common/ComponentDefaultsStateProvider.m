classdef  ComponentDefaultsStateProvider < appdesigner.internal.application.startup.StartupStateProvider
	% A provider which gives dynamic defaults for components that is 
	% sensitive to the user's environment
	
	% Copyright 2018 The MathWorks, Inc.
	
	methods
		function state = getState(obj, argumentStruct)						
			
			% Get defaults
			%
			% Pass in a hardReload of true so that the component
			% dynamic defaults will be reloaded each time App Designer
			% starts			
			hardReload = true;
			defaults = appdesigner.internal.application.retrieveComponentDynamicDefaults(hardReload);									
			
			% Return
			state.DynamicDefaults = defaults;
		end
	end
end