classdef TableMetaDataProxyView < internal.matlab.inspector.InspectorProxyMixin & dynamicprops & internal.matlab.inspector.ProxyAddPropMixin
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Internal class that defines the TableMetaData ProxyView to represent
    % proxy view in displaying table properties in Property Inspector
    
    % Copyright 2021 - 2024 The MathWorks, Inc.

    properties(Description = getString(message('MATLAB:datatools:widgets:datatoolsWidgets:ROW_DIM_NAME')), ...
            DetailedDescription = getString(message('MATLAB:datatools:widgets:datatoolsWidgets:ROW_DIM_DESC'))) %#ok<*ATUNK>
        RowDimensionName internal.matlab.editorconverters.datatype.NonQuotedTextType;
    end

    properties(Description = getString(message('MATLAB:datatools:widgets:datatoolsWidgets:VAR_DIM_NAME')), ...
            DetailedDescription = getString(message('MATLAB:datatools:widgets:datatoolsWidgets:VAR_DIM_DESC'))) %#ok<*ATUNK>
        VariableDimensionName internal.matlab.editorconverters.datatype.NonQuotedTextType;
    end

    properties(Description = getString(message('MATLAB:datatools:widgets:datatoolsWidgets:USER_DATA')), ...
            DetailedDescription = getString(message('MATLAB:datatools:widgets:datatoolsWidgets:USER_DATA_DESC'))) %#ok<*ATUNK>
        UserData;
    end

    properties(Access='protected')
        TablePropsGroup
    end

    properties(Description = getString(message('MATLAB:datatools:widgets:datatoolsWidgets:DESCRIPTION')), ...
            DetailedDescription = getString(message('MATLAB:datatools:widgets:datatoolsWidgets:DESCRIPTION_DESC'))) %#ok<*ATUNK>
        Description internal.matlab.editorconverters.datatype.NonDelimitedMultlineText
    end

    methods
        function this = TableMetaDataProxyView(tableMetaDataObj)
            this@internal.matlab.inspector.InspectorProxyMixin(tableMetaDataObj);
            tablePropsGroupTitle = getString(message('MATLAB:datatools:widgets:datatoolsWidgets:TABLE_PROPS'));
            tablePropsGroup = this.createGroup('TableProperties', tablePropsGroupTitle, '');
            tablePropsGroup.addProperties('RowDimensionName', 'VariableDimensionName', 'UserData', 'Description');
            tablePropsGroup.Expanded = true;
            this.TablePropsGroup = tablePropsGroup;

            this.initializeCustomProperties();
        end

        function initializeCustomProperties(this)
            customPropsGroupTitle = getString(message('MATLAB:datatools:widgets:datatoolsWidgets:CUSTOM_TABLE_PROPS'));
            customTablePropGroup = this.createGroup('CustomTableProperties', customPropsGroupTitle, '');
            customTablePropGroup.Expanded = true;
            this.addCustomProperties(customTablePropGroup);
        end

        function addCustomProperties(this, customTablePropGroup)
            origObj = this.OriginalObjects;
            [~,customProps] = origObj.getCustomProps();
            for i=1:numel(customProps)
                propname = customProps{i};
                this.addDynamicProp(propname, ...
                    "Description", propname, ...
                    "DetailedDescription", propname, ...
                    "Value", origObj.(propname), ...
                    "GetMethod", @(this)origObj.internalGetProperty(propname), ...
                    "SetMethod", @(this, newValue)origObj.internalSetProperty(propname, newValue));
                customTablePropGroup.addProperties(propname);
            end
        end

        function dimName = get.VariableDimensionName(obj)
            dimName = obj.OriginalObjects.VariableDimensionName;
        end

        function dimName = get.RowDimensionName(obj)
            dimName = obj.OriginalObjects.RowDimensionName;
        end

        function userData = get.UserData(obj)
            userData = obj.OriginalObjects.UserData;
        end

        function userData = get.Description(obj)
            userData = obj.OriginalObjects.Description;
        end

        function set.RowDimensionName(obj, value)
            if isa(value, 'internal.matlab.editorconverters.datatype.NonQuotedTextType')
                val = value.Value;
            else
                val = value;
            end
            obj.OriginalObjects.RowDimensionName = val;
        end

        function set.VariableDimensionName(obj, value)
             if isa(value, 'internal.matlab.editorconverters.datatype.NonQuotedTextType')
                val = value.Value;
            else
                val = value;
            end
            obj.OriginalObjects.VariableDimensionName = val;
        end

        function set.Description(obj, value)
            newVal = value.getValue;
            if strcmp(newVal, '[]')
                obj.OriginalObjects.Description = "";
            else
                obj.OriginalObjects.Description = string(strjoin(newVal));
            end
        end
    end
end

