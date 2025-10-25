classdef VariableMetaDataProxyView < internal.matlab.inspector.InspectorProxyMixin & dynamicprops & ...
        internal.matlab.inspector.ProxyAddPropMixin
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Internal class that defines the VariableMetaData ProxyView to represent
    % proxy view in displaying properties for each variable column of tables/timetables in Property Inspector
    
    % Copyright 2021-2024 The MathWorks, Inc.
   
    properties(Description = getString(message('MATLAB:datatools:widgets:datatoolsWidgets:UNITS')), ...
            DetailedDescription = getString(message('MATLAB:datatools:widgets:datatoolsWidgets:UNITS_DESC'))) %#ok<*ATUNK>
        Units internal.matlab.editorconverters.datatype.NonQuotedTextType;
    end

    properties(Description = getString(message('MATLAB:datatools:widgets:datatoolsWidgets:VAR_DESCRIPTION')), ...
            DetailedDescription = getString(message('MATLAB:datatools:widgets:datatoolsWidgets:VAR_DESCRIPTION_DESC'))) %#ok<*ATUNK>
        Description internal.matlab.editorconverters.datatype.NonDelimitedMultlineText        
    end

    properties(Description = 'Variable Name', SetAccess = private) %#ok<*ATUNK>
        VariableName internal.matlab.editorconverters.datatype.NonQuotedTextType;
    end

    properties(Description = getString(message('MATLAB:datatools:widgets:datatoolsWidgets:VAR_CONTINUITY')), ...
            DetailedDescription = getString(message('MATLAB:datatools:widgets:datatoolsWidgets:VAR_CONTINUITY_DESC'))) %#ok<*ATUNK>
        VariableContinuity internal.matlab.editorconverters.datatype.StringEnumeration;
    end

    properties (Constant, Access='private')
        DEFAULT_VARIABLE_CONTINUITY= ['<' getString(message('MATLAB:datatools:widgets:datatoolsWidgets:VARIABLE_CONTINUITY_CHOOSE')) '>'];
    end
    
    methods
        function this = VariableMetaDataProxyView(variableMetaDataObj)
            this@internal.matlab.inspector.InspectorProxyMixin(variableMetaDataObj);
            
            variablePropsGroupTitle = getString(message('MATLAB:datatools:widgets:datatoolsWidgets:VARIABLE_PROPS'));
            variablePropsGroup = this.createGroup('VariableProperties', variablePropsGroupTitle, '');
            variablePropsGroup.addProperties('VariableName', 'Units', 'Description', 'VariableContinuity');           
            variablePropsGroup.Expanded = true;

            customPropsGroupTitle = getString(message('MATLAB:datatools:widgets:datatoolsWidgets:CUSTOM_VARIABLE_PROPS'));
            customVarPropGroup = this.createGroup('CustomVarProperties', customPropsGroupTitle, '');
            customVarPropGroup.Expanded = true;
            this.addCustomProperties(customVarPropGroup);
        end

        function addCustomProperties(this, customVarPropGroup)
            origObj = this.OriginalObjects(end);
            customProps = origObj.getCustomProps();
            for i=1:numel(customProps)
                propname = customProps{i};
                this.addDynamicProp(propname, ...
                    "Description", propname, ...
                    "DetailedDescription", propname, ...
                    "Value", origObj.(propname), ...
                    "GetMethod", @(this)origObj.internalGetProperty(propname), ...
                    "SetMethod", @(this, newValue)internalSetProperty(this, propname, newValue));
                customVarPropGroup.addProperties(propname);
            end
        end

        function internalSetProperty(obj, propname, newValue)
            if ~obj.InternalPropertySet
                origObjs = obj.OriginalObjects;
                for i=1:length(origObjs)
                    if ~strcmp(newValue, origObjs(i).(propname))
                        origObjs(i).(propname) = newValue;
                    end
                end
            end
        end

        function varName = get.VariableName(this)
            origObjs = this.OriginalObjects;
            varName = string.empty;
            for i=1:length(origObjs)
                varName(end+1) = string(origObjs(i).VariableName);
            end
            varName = strjoin(varName, ',');
            % Replace newline and tab alone to print correct chars on
            % display.
            varName = replace(varName, {newline, char(9)}, {matlab.internal.display.getNewlineCharacter(10), ...
                char(8594)});
        end

        function units = get.Units(this)
            units = this.OriginalObjects(end).Units;
        end

        function desc = get.Description(this)   
            desc = this.OriginalObjects(end).Description;
        end

        function set.Description(obj, value)
            if ~obj.InternalPropertySet
                descValue = value.getValue;
                % This is called twice for the same edit, shortcircuit for same
                % value edits.
                origObjs = obj.OriginalObjects;
                for i=1:length(origObjs)
                     if ~strcmp(descValue, origObjs(i).Description)
                        origObjs(i).Description = string(descValue);
                    end
                end
            end
        end

        function set.Units(obj, value)
            if ~obj.InternalPropertySet
                origObjs = obj.OriginalObjects;
                for i=1:length(origObjs)
                    if isa(value, 'internal.matlab.editorconverters.datatype.NonQuotedTextType')
                        val = value.Value;
                    else
                        val = value;
                    end
                    if ~strcmp(val, origObjs(i).Units)
                        origObjs(i).Units = val;
                    end
                end
            end
        end

        function continuity = get.VariableContinuity(this)
            continuityVal = this.OriginalObjects(end).VariableContinuity;
            possibleValues = string(enumeration(matlab.tabular.Continuity.unset))';
            if strcmp(continuityVal, "")
                continuityVal = this.DEFAULT_VARIABLE_CONTINUITY;
                possibleValues = [this.DEFAULT_VARIABLE_CONTINUITY possibleValues];
            end
            continuity = internal.matlab.editorconverters.datatype.StringEnumeration(continuityVal, possibleValues);
        end

        function set.VariableContinuity(obj, value)
            if ~obj.InternalPropertySet
                origObjs = obj.OriginalObjects;
                setval = string(value);
                for i=1:length(origObjs)
                    if ~strcmp(setval, origObjs(i).VariableContinuity)
                        origObjs(i).VariableContinuity = setval;
                    end
                end
            end
        end
    end
end

