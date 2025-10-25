classdef BaseUIComponentAdapter <  appdesigner.internal.componentadapterapi.VisualComponentAdapter
	% Base class for UI Component Adapters in App Designer
	
	% Copyright 2018 The MathWorks, Inc.
	properties (SetAccess=protected, GetAccess=public)
		PluginLocation = '/toolbox/matlab/uicomponents/web/plugin/appdesigner'
		PluginName = 'uicomponents_appdesigner_plugin'
	end
	
	methods		
		function tf = isAvailable(obj)			
			% UIComponents are always available
			tf = true;
		end
	end
end



