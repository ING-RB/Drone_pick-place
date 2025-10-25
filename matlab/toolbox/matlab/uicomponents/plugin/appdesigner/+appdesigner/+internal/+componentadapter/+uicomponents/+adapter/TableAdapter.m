classdef TableAdapter < appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter
    % Adapter for Table

    % Copyright 2015-2021 The MathWorks, Inc.

    properties (SetAccess=protected, GetAccess=public)
        % an array of properties, where the order in the array determines
        % the order the properties must be set for Code Generation and when
        % instantiating the MCOS component at design time.
        OrderSpecificProperties = {}

        % the "Value" property of the component
        % @ToDo maybe Data should be here.
        ValueProperty = [];
        
        ComponentType = 'matlab.ui.control.Table';
    end

    properties(Constant)                
        % an PV pairs of customized property/values for the design time
        % component

        % Data is added by default during design time due to the incremental delivery of UITable features.
        CustomDesignTimePVPairs = {'Position', [0 0 302 185], ...
            'RowName', [], ...
            'ColumnName', {...
            getString(message('MATLAB:ui:defaults:UITableColumn1Name')), ...
            getString(message('MATLAB:ui:defaults:UITableColumn2Name')), ...
            getString(message('MATLAB:ui:defaults:UITableColumn3Name')), ...
            getString(message('MATLAB:ui:defaults:UITableColumn4Name'))...
            }, ...
            };
    end
    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = TableAdapter(varargin)
            obj@appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter(varargin{:});
        end
        
        % ---------------------------------------------------------------------
        % Code Gen Method to return an array of property names, in the correct
        % order, as required by Code Gen
        % ---------------------------------------------------------------------
        function propertyNames = getCodeGenPropertyNames(obj, componentHandle)
            
            import appdesigner.internal.componentadapterapi.VisualComponentAdapter;

             % Get all properties as a struct and get the property names
            % properties as a starting point
            propertyValuesStruct = get(componentHandle);
            allProperties = fieldnames(propertyValuesStruct);

            % Properties that are always ignored and are never set when
            % generating code
            %
            % Remove these from both the properties and order specific
            % properties
            readOnlyProperties = VisualComponentAdapter.listNonPublicProperties(componentHandle);

            % 'RowName' is not in the inspector so normally it would be an ignored property.  However code is generated for it anyways 
            % to set its value to empty to override its default of 'numbered' because 'numbered' is not yet supported.
            % That is done in the DesignTimeTableController
            ignoredProperties = [obj.CommonPropertiesThatDoNotGenerateCode, readOnlyProperties, {...
                'ColumnFormat',...
                'Data'...
                'FontUnits',...
                'RearrangeableColumns',...
                'TooltipString'...
                'UIContextMenu',...
                'Units',...
                }];

            % Determine the last properties, as row
            propertiesAtEnd = {'FontSize',  'Position'};
            
            % Filter out properties to be at the end,otherwise there would
            % be duplicated name in the list, e.g. Position occurs twice
            propertyNames = setdiff(allProperties, [ignoredProperties, propertiesAtEnd], 'stable');            
        
            % Create the master list
            propertyNames = [...
                propertyNames', ...
                propertiesAtEnd, ...
                ];

        end
        
         function isDefaultValue = isDefault(obj, componentHandle, propertyName, defaultComponent)
            % ISDEFAULT - Returns a true or false status based on whether
            % the value of the component corresponding to the propertyName
            % inputted is the default value.  If the value returned is
            % true, then the code for that property will not be displayed
            % in the code at all

            % Override to handle the checks for design-time specific
            % properties: DataSize

            switch (propertyName)             
                 
                case 'DataSize'
                    isDefaultValue = isequal(componentHandle.Data, []);
               
                % The default ColumnWidth of a Table is a character vector, 'auto'.
                % The component ColumnWidth will actually be a cell array of
                % character vectors, {'auto'}.
                % Override the ColumnWidth case in order to deal with these
                % differences.
                case 'ColumnWidth'
                    if strcmp(componentHandle.(propertyName), defaultComponent.(propertyName))
                        isDefaultValue = 1;
                    else
                        isDefaultValue = 0;
                    end

                % The default ColumnEditable and ColumnSortable is logical array.  
                % The following cases deal with component values that are either a
                % logical array or a single logical value.
                case 'ColumnEditable'
                    if isequal(componentHandle.(propertyName), defaultComponent.(propertyName)) || isequal(componentHandle.(propertyName),logical(0))
                        isDefaultValue = 1;
                    else
                        isDefaultValue = 0;
                    end

                case 'ColumnSortable'
                    if isequal(componentHandle.(propertyName), defaultComponent.(propertyName)) || isequal(componentHandle.(propertyName),logical(0))
                        isDefaultValue = 1;
                    else
                        isDefaultValue = 0;
                    end

                otherwise
                    % Call superclass with the same parameters
                    isDefaultValue = isDefault@appdesigner.internal.componentadapter.uicomponents.adapter.BaseUIComponentAdapter(obj,componentHandle,propertyName, defaultComponent);
            end
         end
        
         function controllerClass = getComponentDesignTimeController(obj)
             controllerClass = 'matlab.ui.internal.DesignTimeTableController';
         end
    end
    
    methods (Access = protected)
        function applyCustomComponentDesignTimeDefaults(obj, component)
            % Apply custom design-time component defaults to the component
            %            
            % Set design time properties
            component.Position = [0 0 302 185];
            component.RowName = [];

            component.ColumnName = {...
                getString(message('MATLAB:ui:defaults:UITableColumn1Name')), ...
                getString(message('MATLAB:ui:defaults:UITableColumn2Name')), ...
                getString(message('MATLAB:ui:defaults:UITableColumn3Name')), ...
                getString(message('MATLAB:ui:defaults:UITableColumn4Name'))...
                };
        end
    end

    % ---------------------------------------------------------------------
    % Basic Registration Methods
    % ---------------------------------------------------------------------
    methods(Static)
        function adapter = getJavaScriptAdapter()
            adapter = 'uicomponents_appdesigner_plugin/model/TableModel';
        end       
    end

    % ---------------------------------------------------------------------
    % Code Gen Methods
    % ---------------------------------------------------------------------
    methods(Static)

        function codeSnippet = getCodeGenCreation(componentHandle, codeName, parentName)
            codeSnippet = sprintf('uitable(%s)', parentName);
        end
    end
end

