classdef  ComponentSetStateProvider < appdesigner.internal.application.startup.StartupStateProvider
	% A provider which discovers all component sets on the MATLAB path

	% Copyright 2018 The MathWorks, Inc.

	methods
		function state = getState(obj, startupArguments)
			% This function will:
			%
			% - Look for all ComponentSetAdapter subclasses
			%
			% - Get their properties
			%
			% - test if their license is available
			%
			% - For those with valid licenses, their information is stored
			%   and returned
            
            componentSets = [];
            
            adapterMap = appdesigner.internal.application.getComponentAdapterMap();						
            allAdapterKeys = keys(adapterMap);
            
			for idx = 1:length(allAdapterKeys)
                
				adapterClassName = adapterMap(allAdapterKeys{idx});

				componentAdapter = eval(adapterClassName);

				isAvailable = componentAdapter.isAvailable();

				if(~isAvailable)
					% If not licensed, then drop the set
					continue;
				end

				componentSets = [componentSets, ...
					struct(...
					'PluginLocation', componentAdapter.PluginLocation, ...
					'PluginName', componentAdapter.PluginName ...
					)
					]; %#ok<AGROW>
			end

			% remove the dupes so that we end up with just a unique set
			[~, uniqueIndices] = unique({componentSets.PluginLocation});
			componentSets = componentSets(uniqueIndices);

			% ensure that UIComponents are always first
			%
			% Pull out uicomponents, and adjust the rest
			%
			% TODO: This should likely be done in the client
			%
			%		Will do this when we need to iterate over entries and enable
			%		/ disable.
			index = find(strcmp({componentSets.PluginName}, 'uicomponents_appdesigner_plugin'));
			componentSets = [ componentSets(index) componentSets([1 : index - 1, index + 1 : end])];

			% It is important to store as a cell array of structs so
			% that the data is translated to the UI as an array of JS
			% objects
			%
			% Otherwise, it could be transported as just a struct when
			% there is only 1 component set
			state.ComponentSets = num2cell(componentSets);
		end
	end
end
