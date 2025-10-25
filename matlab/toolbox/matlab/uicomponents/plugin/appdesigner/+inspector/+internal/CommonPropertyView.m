classdef CommonPropertyView
	%CommonPropertyView - a helper class that creates common as well as component specific
	%                     property groups
	
	%   Copyright 2015-2022 The MathWorks, Inc.
	
	methods (Static)
		
		
		function group = createPropertyInspectorGroup(propertyViewObject, groupMessageId, varargin)
			% createPropertyInspectorGroup function is responsible for creating
			% a component specific property inspector group. The function takes
			% in the property view object, a group message id that is defined in
			% the Inspector.xml resource file and a list of property names.
			%   ex: inspector.internal.CommonPropertyView.createPropertyInspectorGroup(obj, 'MATLAB:ui:propertygroups:<group name>',...
			%                                                                           '<property 1>', '<property 2>');
			
			% Explicitly shut off group description tooltip
			groupDescription = '';
			group = propertyViewObject.createGroup( ...
				groupMessageId, ...
				groupMessageId, ...
				groupDescription);
			
			group.addProperties(varargin{:});
			
			% by default, expand all groups
			group.Expanded = true;
		end
		
		function groupStruct = createCommonPropertyInspectorGroup(propertyViewObject, includePosition)
			% createCommonPropertyInspectorGroup function is responsible for
			% creating common property inspector groups that are shared across
			% all the components. The following are considered to be common
			% properties across all components: Font, Location, Enable, Visible,
			% Editable, HandleVisibility.
			%
			% includePosition - optional logical to explicitly include or
			%                   exclude the Position category
			%
			%                   true by default if not specified
			
			if(nargin == 1)
				includePosition = true;
			end
			
			groupStruct = struct;
			
			import inspector.internal.CommonPropertyView;
			
			if(isprop(propertyViewObject, 'BackgroundColor'))
				groupStruct.FontAndColorGroup = CommonPropertyView.createFontAndColorGroup(propertyViewObject);
			else
				groupStruct.FontGroup = CommonPropertyView.createFontGroup(propertyViewObject);
			end
			
			
			groupStruct.InteractivityGroup = CommonPropertyView.createInteractivityGroup(propertyViewObject);
			
			if(includePosition)
				groupStruct.PositionGroup = CommonPropertyView.createPositionGroup(propertyViewObject);
			end
			
			groupStruct.CallbackExecutionControlGroup = CommonPropertyView.createCallbackExecutionControlGroup(propertyViewObject);
			groupStruct.ParentChildControlGroup = CommonPropertyView.createParentChildGroup(propertyViewObject);
			
			groupStruct.IdentifiersGroup = CommonPropertyView.createIdentifiersGroup(propertyViewObject);
		end
		
		function createPanelPropertyGroups(propertyViewObject)
			% This creates common groups related to containers like Panel
			% and Button Group
			%
			% Because these components have slightly differently named
			% properties for color (ex: ForegroundColor), their groupings
			% are different
			
			import inspector.internal.CommonPropertyView;
			
			CommonPropertyView.createPropertyInspectorGroup(propertyViewObject, 'MATLAB:ui:propertygroups:ColorAndStylingGroup', ...
				'ForegroundColor',...
				'BackgroundColor',...
				'BorderType', ...
                'BorderWidth',...
                'BorderColor' ...
				);
			
			CommonPropertyView.createPropertyInspectorGroup(propertyViewObject, 'MATLAB:ui:propertygroups:FontGroup', ...
				'FontName', ...
				'FontSize',...
				'FontWeight', ...
				'FontAngle'...
				);
			
			CommonPropertyView.createInteractivityGroup(propertyViewObject);
			CommonPropertyView.createPositionGroup(propertyViewObject);
			CommonPropertyView.createCallbackExecutionControlGroup(propertyViewObject);
			CommonPropertyView.createParentChildGroup(propertyViewObject);
            CommonPropertyView.createIdentifiersGroup(propertyViewObject);
		end
		
		% List of functions to specific common property groups
		%
		% Should be used when createCommonPropertyInspectorGroup() is
		% making too broad of assumptions about what is "common" to all
		% components
		
		% Expanded Groups
		function group = createFontAndColorGroup(propertyViewObject)
			
			group = inspector.internal.CommonPropertyView.createPropertyInspectorGroup(propertyViewObject, 'MATLAB:ui:propertygroups:FontAndColorGroup', ...
				'FontName', ...
				'FontSize',...
				'FontWeight', ...
				'FontAngle',...
				'FontColor', ...
				'ForegroundColor',...
				'BackgroundColor'...
				);
		end
		
		function group = createFontGroup(propertyViewObject)
			% This is used when there is no 'BackgroundColor
			
			group = inspector.internal.CommonPropertyView.createPropertyInspectorGroup(propertyViewObject, 'MATLAB:ui:propertygroups:FontGroup', ...
				'FontName', ...
				'FontSize',...
				'FontWeight', ...
				'FontAngle',...
				'FontColor', ...
				'ForegroundColor'...
				);
		end
		
		% Non Expanded Groups
		function group = createInteractivityGroup(propertyViewObject)
			group = inspector.internal.CommonPropertyView.createPropertyInspectorGroup(propertyViewObject, 'MATLAB:ui:propertygroups:InteractivityGroup');
			
			group.addProperties('Visible');
			
			% Conditionally add the property
			if(isprop(propertyViewObject, 'SelectionType'))
				group.addProperties('SelectionType');
			end

			% Conditionally add the property
			if(isprop(propertyViewObject, 'Multiselect'))
				group.addProperties('Multiselect');
			end
			
			% Conditionally add the property
			if(isprop(propertyViewObject, 'Editable'))
				group.addProperties('Editable');
			end
			
			group.addProperties('Enable');
			
			% Conditionally add the property
			% Tooltip not supported by:
			% figure, treenode and axes
			if(isprop(propertyViewObject, 'Tooltip'))
				group.addProperties('Tooltip');
			end
			
			% Conditionally add the property
            if(isprop(propertyViewObject, 'Scrollable'))
                group.addProperties('Scrollable');
            end
            
			group.addProperties('ContextMenu');

			group.Expanded = false;
		end
		
		function group = createPositionGroup(propertyViewObject)
			
			group = propertyViewObject.createGroup( ...
				'MATLAB:ui:propertygroups:PositionGroup', ...
				'MATLAB:ui:propertygroups:PositionGroup', ...
				'');
			
			group.addEditorGroup('Position');
			
			if(isprop(propertyViewObject, 'AutoResizeChildren'))
				group.addProperties('AutoResizeChildren');
			end
			
			group.Expanded = false;
		end
		
		function group = createParentChildGroup(propertyViewObject)
			% Note for future property support:
			%
			% For Parent and Child, the long term design would be
			% to have them here in this grouping, and send them to
			% client.  However, the infrastructure is not in place in
			% App Designer nor the Inspector widget to:
			% - know what to send to the peer nodes
			% - know how to handle an edit (if editing is even
			% supported)
			%
			%
			
			group = inspector.internal.CommonPropertyView.createPropertyInspectorGroup(propertyViewObject, 'MATLAB:ui:propertygroups:ParentChildGroup', ...
				'HandleVisibility' ...
				);
			
			group.Expanded = false;
		end
		
		function group = createCallbackExecutionControlGroup(propertyViewObject)
			
			group = inspector.internal.CommonPropertyView.createPropertyInspectorGroup(propertyViewObject, 'MATLAB:ui:propertygroups:CallbackExecutionControlGroup',...
				'Interruptible', ...
				'BusyAction' ...
				);
			
			group.Expanded = false;
		end
		
		function group = createOptionsGroup(propertyViewObject, titleCatalogId)
			
			group = propertyViewObject.createGroup( ...
				titleCatalogId, ...
				titleCatalogId, ...
				'');
			
			group.addEditorGroup('Value', 'Items');
			group.addProperties('ItemsData');
			group.Expanded = true;
        end
        
        function group = createIdentifiersGroup(propertyViewObject)
            
            group = inspector.internal.CommonPropertyView.createPropertyInspectorGroup(propertyViewObject, 'MATLAB:ui:propertygroups:IdentifiersGroup', ...
                'Tag' ...
                );
            
            group.Expanded = false;
        end
		
		% Component specific , but shared Groups
		
		function group = createTicksGroup(propertyViewObject)
			
			group = propertyViewObject.createGroup( ...
				'MATLAB:ui:propertygroups:TicksGroup', ...
				'MATLAB:ui:propertygroups:TicksGroup', ...
				'');
			
			group.addEditorGroup('MajorTicks','MajorTickLabels');
			group.addProperties('MinorTicks');
			
			
			group.addSubGroup( 'MajorTicksMode', 'MajorTickLabelsMode', 'MinorTicksMode');
			
			group.Expanded = true;
			
		end
	end
end
