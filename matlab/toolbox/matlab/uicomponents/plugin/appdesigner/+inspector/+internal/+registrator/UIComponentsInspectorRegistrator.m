classdef UIComponentsInspectorRegistrator < internal.matlab.inspector_registration.InspectorRegistrator
    % Registers component property inspector views
    %
    % This will be called during the build for the
    % uicomponents/appdesigner_plugin_m component.  It creates the inspector
    % registration cache file for the components container here, in the
    % uicomponents/uicomponents/plugin/appdesigner directory.
    
    % Copyright 2016-2023 The MathWorks, Inc.
    
    properties(Constant)
        RegistrationName = 'AppDesigner';
    end
    
    methods (Static = true)
        function path = getRegistrationFilePath()
            path = fullfile((matlabroot), "toolbox", "matlab", "uicomponents", ...
                "plugin", "appdesigner");
        end

        function name = getRegistrationName()
            name = inspector.internal.registrator.UIComponentsInspectorRegistrator.RegistrationName;
        end
        
        % Get the documentation page for the component
        function docString = getHelpSearchTerm(object)
            % Argument object can be the actual object or a class name
            objectOrClassName = convertStringsToChars(object);
            if ~ischar(objectOrClassName)
                className = class(objectOrClassName);
            else
                className = objectOrClassName;
            end
            
            % From the class name, find the text after the last period.
            % For example, 'Table' in 'matlab.ui.control.Table'
            classNameSections = strsplit(className,'.');
            componentName = classNameSections{end};
            
            % The Figure adapter is named UIFigureAdapter while the class is
            % matlab.ui.Figure.  Account for this difference.
            if strcmp(componentName,'Figure')
                componentName = 'UIFigure';
            end
            
            % Create the Adapter Name
            adapterName = strcat(componentName,'Adapter');
            
            % Get the docString from the Adapter Name.
            docString = appdesigner.internal.componentadapter.uicomponents.adapter.(adapterName).getDocString();
        end
    end
    
    methods
        function this = UIComponentsInspectorRegistrator
            this@internal.matlab.inspector_registration.InspectorRegistrator;
        end
        
        function registerInspectorComponents(obj)
            
            % Needed to enable ContextMenu
            feature('EnableUIComponentsInUIFigure',1)
            
            tempFigure = uifigure('Visible', 'off');
            
            % List of Applications to register with.  Only register
            % AppDesigner for now, so components like figure aren't also
            % modified to use the AppDesigner specific view.
            applicationNames = {
                % App Designer
                obj.RegistrationName; ...
                
                % Regular Inspector
                % 'default'; ...
                
                % Namespace used by MOTW
                % 'PropertyInspector'
                };
            
            % Components To Register
            %
            % This list should be able to be updated without needing to update any code
            % further down
            
            % Registering these components adds roughly 25-27 seconds to the
            % appdesigner load time. See geck: 1271705 for more details
            components = {
                'matlab.ui.control.Label', ...
                'matlab.ui.control.TextArea', ...
                'matlab.ui.control.EditField', ...
                'matlab.ui.control.NumericEditField', ...
                'matlab.ui.control.Spinner', ...
                'matlab.ui.control.Slider', ...
                'matlab.ui.control.RangeSlider', ...
                'matlab.ui.control.Button', ...
                'matlab.ui.control.StateButton', ...
                'matlab.ui.control.CheckBox', ...
                'matlab.ui.control.DropDown', ...
                'matlab.ui.control.DatePicker', ...
                'matlab.ui.control.Image', ...
                'matlab.ui.control.ListBox', ...
                'matlab.ui.control.Hyperlink', ...
                'matlab.ui.container.ButtonGroup', ...
                'matlab.ui.container.Panel', ...
                'matlab.ui.container.Tab', ...
                'matlab.ui.container.GridLayout', ...
                'matlab.ui.container.TabGroup', ...
                'matlab.ui.control.RadioButton', ...
                'matlab.ui.control.ToggleButton', ...
                'matlab.ui.control.Lamp', ...
                'matlab.ui.control.Gauge', ...
                'matlab.ui.control.LinearGauge', ...
                'matlab.ui.control.NinetyDegreeGauge', ...
                'matlab.ui.control.SemicircularGauge', ...
                'matlab.ui.control.Knob', ...
                'matlab.ui.control.DiscreteKnob', ...
                'matlab.ui.control.Switch', ...
                'matlab.ui.control.ToggleSwitch', ...
                'matlab.ui.control.RockerSwitch', ...
                'matlab.ui.control.UIAxes', ...
                'matlab.ui.control.Table', ...
                'matlab.ui.container.Menu', ...
                'matlab.ui.container.Tree', ...
                'matlab.ui.container.TreeNode', ...
                'matlab.ui.Figure', ...
                'matlab.ui.control.HTML', ...
                'matlab.ui.container.ContextMenu', ...
                'matlab.ui.container.Toolbar', ...
                'matlab.ui.container.toolbar.PushTool', ...
                'matlab.ui.container.toolbar.ToggleTool', ...
                'matlab.ui.container.CheckBoxTree', ...
                'matlab.ui.control.ColorPicker'
                };
            
            % Loop over all components
            for componentIdx = 1:length(components)
                
                componentFullName = components{componentIdx};
                indices = regexp(componentFullName, '\.');
                componentShortName = componentFullName(indices(end) + 1 : end);
                
                % Assume its inspector.internal.<ShortName>PropertyView
                %
                % Ex: inspector.internal.LabelPropertyView
                propertyViewClass = sprintf('inspector.internal.%sPropertyView', componentShortName);
                
                parent = [];
                if(strcmp(componentFullName, 'matlab.ui.Figure'))
                    defaultObj = tempFigure;
                    
                elseif(strcmp(componentFullName, 'matlab.ui.container.Tab'))
                    parent = matlab.ui.container.TabGroup;
                    defaultObj = feval(componentFullName, 'Parent', parent );
                    
                    % Checks if the component is either a RadioButton or a
                    % ToggleButton
                elseif ismember(componentFullName, {'matlab.ui.control.RadioButton','matlab.ui.control.ToggleButton'})
                    parent = matlab.ui.container.ButtonGroup;
                    defaultObj = feval(componentFullName, 'Parent', parent);
                    
                elseif(strcmp(componentFullName, 'matlab.ui.container.TreeNode'))
                    parent = matlab.ui.container.Tree;
                    defaultObj = feval(componentFullName, 'Parent', parent);
                    
                    % Checks if the component is either a PushTool or a
                    % ToggleTool
                elseif ismember(componentFullName, {'matlab.ui.container.toolbar.PushTool','matlab.ui.container.toolbar.ToggleTool'})
                    parent = matlab.ui.container.Toolbar;
                    defaultObj = feval(componentFullName, 'Parent', parent);
                    
                else
                    defaultObj = feval(componentFullName, 'Parent', tempFigure);
                end
                
                % Loop over all applications
                for applicationIdx = 1:length(applicationNames)
                    
                    applicationName = applicationNames{applicationIdx};
                    
                    % Store the getHelpSearchTerm method in a function
                    % handle that can be used by the inspector.
                    getSearchTermFunctionHandle = @(graphicsObject) inspector.internal.registrator.UIComponentsInspectorRegistrator.getHelpSearchTerm(graphicsObject);
                    
                    % Register the inspector view
                    obj.inspectorRegistrationManager.registerInspectorView(...
                        componentFullName, ...
                        applicationName, ...
                        propertyViewClass, ...
                        defaultObj, ...
                        getSearchTermFunctionHandle ...
                        );
                end
                delete(parent)
            end
            delete(tempFigure);
        end
    end
end