classdef VariableMetaDataObj < dynamicprops
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Internal class that defines the VariableMetaData Object to represent
    % Variable properties for viewing and editing
    
    % Copyright 2021-2022 The MathWorks, Inc.
    properties
        VariableName
        Units {mustBeText} = ""
        Description = ""
        VariableContinuity
    end

    properties(Hidden)
        Workspace;
        CurrentColumn;        
        TableName
        TableProperties
    end
    
    methods
        function this = VariableMetaDataObj(tableObj, column, tableName, workspace, tableProperties)
            props = tableObj.Properties;
            if isa(tableObj, 'dataset')
                this.VariableName = props.VarNames{column};
            else
                this.VariableName = props.VariableNames{column};
            end
            this.TableName = tableName;
            this.Workspace = workspace;
            this.TableProperties = tableProperties;
            if ~isa(tableObj, 'dataset')
                this.addCustomProps();
            end
        end

        function addCustomProps(this)
            varnames = this.getCustomProps();
            if ~isempty(varnames)
                for i = 1:length(varnames)
                    propname = varnames{i};
                    p = addprop(this, propname);
                    p.SetMethod = @(this, newValue)internalSetProperty(this, propname, newValue);
                    p.GetMethod = @(this)internalGetProperty(this, propname);
                end
            end
        end

        function variableCustomProps = getCustomProps(this)
             tableProps = this.getTableProperties();
             if isprop(tableProps, 'CustomProperties')
                customProps= tableProps.CustomProperties;
                [variableCustomProps, ~] = getNames(customProps);
             else
                variableCustomProps = {};
             end
        end

        % TODO: Handle on DataChanged event
        function internalSetProperty(this, name, newValue)                
            cmd = sprintf('%s.Properties.CustomProperties.%s(%s) = %s;', this.TableName, name, num2str(this.CurrentColumn), newValue);
        end

        function val = internalGetProperty(this, name)
            tableObj = evalin(this.Workspace, this.TableName);
            customProps = tableObj.Properties.CustomProperties;
            val = customProps.(name);                    
            if length(val) >= width(tableObj)
                val = val(this.CurrentColumn);
            end
        end

        function name = getObjName(this)
            name = this.TableName;
        end

        function currentColumn = get.CurrentColumn(this)
            tableProps = this.getTableProperties();
            if isfield(tableProps, 'VarNames')
                currentColumn = find(strcmp(tableProps.VarNames, this.VariableName));
            else
                currentColumn = find(strcmp(tableProps.VariableNames, this.VariableName));
            end
        end

        function variableUnits = get.Units(this)
            variableUnits = "";
            props = this.getTableProperties();
            currColumn = this.CurrentColumn;
            if isfield(props, 'Units') %% TODO used to make the fields appear in editor
                if (size(props.Units, 2) >= currColumn)
                    variableUnits = props.Units{currColumn};
                end
            else
                if (size(props.VariableUnits, 2) >= currColumn)
                    variableUnits = props.VariableUnits{currColumn};
                end
            end
        end


        function variableContinuity = get.VariableContinuity(this)
            variableContinuity = "";
            props = this.getTableProperties();
            currColumn = this.CurrentColumn;
            if (size(props.VariableContinuity, 2) >= currColumn)
                variableContinuity = props.VariableContinuity(currColumn);
            end
        end

        function variableDesc = get.Description(this)
            variableDesc = "";
            props = this.getTableProperties();
            currColumn = this.CurrentColumn;
            if isfield(props, 'VarDescription') %% TODO used to make the fields appear in editor
                if (size(props.VarDescription, 2) >= currColumn)
                    variableDesc = props.VarDescription{currColumn};
                end
            else
                if (size(props.VariableDescriptions, 2) >= currColumn)
                    variableDesc = props.VariableDescriptions{currColumn};
                end
            end
        end

        function set.Units(this, value)
            value =  matlab.internal.datatools.sidepanelwidgets.propediting.TableMetaDataObj.getEscapedString(value);
            this.Units = value;
            if isfield(this.getTableProperties(), 'Units')
                cmd = sprintf('%s.Properties.Units{%s} = "%s";', this.TableName, num2str(this.CurrentColumn), value);
            else
                cmd = sprintf('%s.Properties.VariableUnits(%s) = "%s";', this.TableName, num2str(this.CurrentColumn), value);
            end
                        
            evalin(this.Workspace, cmd);
            internal.matlab.desktop.commandwindow.insertCommandIntoHistoryWithNoPrompt(cmd);
            this.updatePropertiesCache();
        end

        function set.Description(this, value)
            value =  matlab.internal.datatools.sidepanelwidgets.propediting.TableMetaDataObj.getEscapedString(value);
            this.Description = value;
            if isfield(this.getTableProperties(), 'VarDescription')
                cmd = sprintf('%s.Properties.VarDescription{%s} = "%s";', this.TableName, num2str(this.CurrentColumn), value);
            else
                cmd = sprintf('%s.Properties.VariableDescriptions(%s) = "%s";', this.TableName, num2str(this.CurrentColumn), value);
            end     
            evalin(this.Workspace, cmd);
            internal.matlab.desktop.commandwindow.insertCommandIntoHistoryWithNoPrompt(cmd);
            this.updatePropertiesCache();
        end

        function set.VariableContinuity(this, value)
            this.VariableContinuity = value;
            cmd = sprintf('%s.Properties.VariableContinuity(%s) = ''%s'';', this.TableName, num2str(this.CurrentColumn), value);            
            evalin(this.Workspace, cmd);
            internal.matlab.desktop.commandwindow.insertCommandIntoHistoryWithNoPrompt(cmd);
            this.updatePropertiesCache();
        end
    end

    methods(Access='private')

        function updatePropertiesCache(this)
            if ~isempty(this.TableProperties)
                matlab.internal.datatools.sidepanelwidgets.propediting.TableMetaDataObj.updateTablePropertiesCache(this);            
            end
        end

        function props = getTableProperties(this)
            props = matlab.internal.datatools.sidepanelwidgets.propediting.TableMetaDataObj.getTableProperties(this);
        end
    end
end

