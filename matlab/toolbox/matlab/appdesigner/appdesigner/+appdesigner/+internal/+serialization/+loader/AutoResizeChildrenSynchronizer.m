classdef AutoResizeChildrenSynchronizer < appdesigner.internal.serialization.loader.interface.DecoratorLoader
	%AutoResizeChildrenSynchronizer  A decorator class that ensures all
	% containers under a figure have the same AutoResizeChildren property value
	
	% Copyright 2018 The MathWorks, Inc.
	
	methods
		
		function obj = AutoResizeChildrenSynchronizer(loader)
			obj@appdesigner.internal.serialization.loader.interface.DecoratorLoader(loader);
		end
		
		function appData = load(obj)
			appData = obj.Loader.load();			
			
			% Suppress the warning at the command line when setting
			% AutoResizeChildren at design time.
			% The warning would otherwise display if AutoResizeChildren
			% is set to 'on' and SizeChangedFcn is not empty
			ws = warning('off', 'MATLAB:ui:containers:SizeChangedFcnDisabledWhenAutoResizeOn');
			c = onCleanup(@()warning(ws));			
			
			
			
			% Initialize the auto resize property.
			% Apps created in 16a/16b do not define the AutoResizeChildren
			% property. Instead, they have a dynamic property AutoResize.
			% We use AutoResize if it was loaded from the saved app to
			% maintain backwards compatibility.			
			figureHandle = appData.components.UIFigure;
			
			if(isprop(figureHandle, 'AutoResize'))
				if(figureHandle.AutoResize)
					figureHandle.AutoResizeChildren = 'on';
				else
					figureHandle.AutoResizeChildren = 'off';
				end
				% Once we have used the saved dynamic property 'AutoResize'
				% to load the app, we no longer need it, and we don't
				% want to re-save it either
				metaObj = figureHandle.findprop('AutoResize');
				delete(metaObj);
				
			end
			
			% At this point, the AutoResizeChildren property is correct
			%
			% Synchronize it on all children
			obj.synchronizeAutoResizeChildren(appData.components.UIFigure, appData.components.UIFigure.AutoResizeChildren);
		end
		
	end
	
	methods (Access=private)
		
		function synchronizeAutoResizeChildren(obj, component, value)
			
			% Only do something if it is a container
			if ( isprop(component,'AutoResizeChildren'))
				
				% Initialize the auto resize property.
				% Apps created in 16a/16b do not define the AutoResizeChildren
				% property. Initialize auto resize with the parent's setting
				% since:
				%
				% - Auto resize could only be enabled for all or none of the containers
				% - The uifigure was initialized correctly using the saved
				% dynamic property defined for 16a/16b apps
				component.AutoResizeChildren = value;
				
				children = allchild(component);
				for i = 1:length(children)
					childComponent = children(i);
					% recursively walk the children
					obj.synchronizeAutoResizeChildren(childComponent, value);
				end
			end
		end
		
	end
end
