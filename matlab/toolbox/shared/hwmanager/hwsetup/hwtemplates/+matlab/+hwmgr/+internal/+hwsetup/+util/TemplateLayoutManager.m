classdef TemplateLayoutManager < handle
    % TEMPLATELAYOUTMANAGER provides a collection of static functions to 
    % add, set and define the widget properties for Template Base
    
    % Copyright 2016-2023 The MathWorks, Inc.
    
    methods(Static)
        function widgetPropMap = getAllTemplateWidgetLayoutDetails()
            % getAllTemplateWidgetLayoutDetails - static function to get
            % the container Map where the keys are widget names
            % and the value is a structure that contains the widget
            % properties and the value to be set for each property
            
            widgetPropMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
            
            % parent grid to host all sections
            widgetPropMap('ParentGrid') = struct('Padding', [0 0 0 0],...
                'RowHeight', {{45, '1x', 45}},... 
                'ColumnWidth', {{'1x', 215}});
            
            % Banner section having its own grid for laying out steps and
            % title
            widgetPropMap('Banner') = struct('Padding', [5 2 5 2],...
                'Color',  matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorHighlightFocus,...
                'Column', [1 2], 'RowHeight', {{'fit', '1x'}}, 'ColumnWidth', {{'1x'}});
            
            widgetPropMap('WorkflowSteps') = struct('Text', 'Title', 'Row', 1,...
                'BackgroundColor', matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorHighlightFocus);

            widgetPropMap('Title') = struct('Text', 'Title', 'Row', 2,...
                'Color', matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorHighlightFocus,...
                'FontColor', matlab.hwmgr.internal.hwsetup.util.Color.ColorTertiary,...
                'FontSize', 18,...
                'FontWeight', 'bold');
            
            %content panel            
            widgetPropMap('ContentPanel') = struct('Title', '',... 
                'BorderType', 'none', 'Row', 2, 'Column', 1, 'Tag', 'ContentPanel');

            %content grid, hidden by default
            widgetPropMap('ContentGrid') = struct('RowHeight', {{'fit', 'fit'}},...
                'ColumnWidth', {{'1x'}}, 'RowSpacing', 10, 'ColumnSpacing', 10,...
                'Visible', 'off');
            
            %helptext
            widgetPropMap('HelpText') = struct('WhatToConsider', '',...
                'AboutSelection', '', 'Row', 2, 'Column', 2);
 
            %navigation panel
            widgetPropMap('NavigationGrid') = struct('Color',  matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorSecondary,...
                'Row', 3, 'Column', [1 2], 'RowHeight', {{'1x'}},'ColumnWidth', {{90, '1x', 90, 20, 90}});
            
            widgetPropMap('BackButton') = struct('Column', 1,...
                'Text',  ['< ' message('hwsetup:template:BackButtonText').getString]);
                        
            widgetPropMap('CancelButton') = struct('Column', 3,...
                'Text',  message('hwsetup:template:CancelButtonText').getString);

            widgetPropMap('NextButton') = struct('Column', 5,...
                'Text',  [message('hwsetup:template:NextButtonText').getString ' >']);

            widgetPropMap('Title') = struct('Position', [20 7 470 25],...
                'Color', matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorHighlightFocus,...
                'FontColor', matlab.hwmgr.internal.hwsetup.util.Color.ColorTertiary,...
                'FontSize', 16,...
                'FontWeight', 'bold',...
                'Text', '');
        end
        
        function setWidgetProperties(widgetPropertyStruct, widgetObject)
            % setWidgetProperties - Accepts a structure of Widget Property
            % Names and the corresponding values and the widget object. The
            % function assigns the property value to the widget property
                       
            propertiesToSet = fieldnames(widgetPropertyStruct);
            for j = 1:numel(propertiesToSet)
                widgetObject.(propertiesToSet{j}) = widgetPropertyStruct.(propertiesToSet{j});           
            end
        end
        
        function widget = addWidget(type, parent)
            % addWidget - Adds a widget of the specified type to the parent
            % This is a convenience function to enable addition of widgets in
            % a template or screen. 
            % widgetType = 'matlab.hwmgr.internal.hwsetup.EditText';
            % parent = screen.ContentPanel % The widgets should be added to
            %                              % the Content Panel
            % matlab.hwmgr.internal.hwsetup.util.TemplateLayoutManager.addWidget(...
            % widgetType, parent);
            
            p = inputParser;
            typeValidationFcn = @(x) ischar(x) && ~isempty(x);
            p.addRequired('type', typeValidationFcn);
            p.addRequired('parent', @matlab.hwmgr.internal.hwsetup.Widget.isValidParent);
            p.parse(type, parent);
            if ~exist(type, 'class')
                  error(message('hwsetup:widget:WidgetClassDoesNotExist', ...
                    type, message('hwsetup:widget:Widget').getString));
            end
            try
                widget = feval([type '.getInstance'], parent);
            catch ex
                error(message('hwsetup:widget:WidgetCreatingError', ...
                    type, class(parent), ex.message));
            end
        end 
    end
end