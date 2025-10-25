classdef TableMetaDataObj < handle & dynamicprops
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Internal class that defines the TableMetaData Object to represent
    % table properties for viewing and editing
    
    % Copyright 2021-2022 The MathWorks, Inc.

    properties
        Description
        UserData
        Variable
        RowDimensionName string
        VariableDimensionName string
    end
    
    properties(Hidden)
        TableName
        Workspace
        TableObj
        TableProperties = [];
    end

    properties(Constant, Hidden)
        MAX_VAR_CUTOFF = 100;
        MAX_VARIABLES_IN_HIERARCHY = 1001;
    end

    properties(Access='private')
        PropNameMap string % Maintain a string map for arbitrary variable names
    end

    properties(Access={?matlab.internal.datatools.sidepanelwidgets.propediting.PropertyEditInspector,?matlab.unittest.TestCase})
        VariablesObj string
        CustomPropsObj string
    end
    
    methods
        function this = TableMetaDataObj(tableObj, tableName, workspace)
            arguments
                tableObj (:,:) {mustBeA(tableObj, ["table", "timetable", "dataset"])}
                tableName
                workspace = 'debug';
            end
            this.Workspace = workspace;
            this.TableName = tableName;
            this.TableObj = tableObj;
            % If table has more than 100 variables, update the
            % tableproperties local cache.
            if (width(tableObj) > this.MAX_VAR_CUTOFF)
               matlab.internal.datatools.sidepanelwidgets.propediting.TableMetaDataObj.updateTablePropertiesCache(this, tableObj);
            end
            this.updateDynamicProperties(tableObj, tableName, workspace);
            this.addCustomProps();
        end

        function name = getObjName(this)
            name = this.TableName;
        end

        % Helper function to retrieve the table variable names from
        % properties 
        function varNames = getVarNames(~, properties)
            varNames = properties.VariableNames;
        end

        function props = properties(this)
            tableProps = matlab.internal.datatools.sidepanelwidgets.propediting.TableMetaDataObj.getTableProperties(this);
            props = this.getVarNames(tableProps); 
            for i=1:length(props)
                [r,c] = find(this.PropNameMap==props{i});
                if ~isempty(r)
                    props{i} = char(this.PropNameMap(r, c+1));
                end
            end
        end

        function addCustomProps(this)
            [varprops, customprops] = this.getCustomProps();
            if ~isempty(customprops)
                for i = 1:length(customprops)
                    propname = customprops{i};
                    p = addprop(this, propname);
                    p.SetMethod = @(this, newValue)internalSetProperty(this, propname, newValue);
                    p.GetMethod = @(this)internalGetProperty(this, propname);
                    
                end
            end
            % Save CustomProperty names as classobj to compare when custom
            % props are added/removed
            allprops = [varprops' customprops'];
            if ~isempty(allprops)
                this.CustomPropsObj = allprops;
            end
        end

        % returns Variable level custom properties as well as table level
        % custom properties
        function [VariableCustomProps, tableCustomProps] = getCustomProps(this)
             tableProps = matlab.internal.datatools.sidepanelwidgets.propediting.TableMetaDataObj.getTableProperties(this);
             [VariableCustomProps, tableCustomProps] = getNames(tableProps.CustomProperties);

        end

        % TODO: Internal property sets need to be handed with DataChanged
        function internalSetProperty(this, name, newValue)                
            cmd = sprintf('%s.Properties.CustomProperties.%s = %s;', this.TableName, name, newValue);            
        end

        function val = internalGetProperty(this, name)
            tableProps = matlab.internal.datatools.sidepanelwidgets.propediting.TableMetaDataObj.getTableProperties(this);
            customProps = tableProps.CustomProperties;
            val = customProps.(name);
        end

        % Add Variables as Dynamic Properties to the Object. Since tables
        % can contain arbitrary names, generate valid names for property names.
        function updateDynamicProperties(this, tableObj, tableName, workspace)
            varNames = this.getVarNames(tableObj.Properties);
            % Update only upto a max of 1000
            varNames(this.MAX_VARIABLES_IN_HIERARCHY:end)=[];
            for i=1:length(varNames)
                colName = varNames{i};
                validPropName = colName;
                if ~isvarname(validPropName)
                    validPropName = internal.matlab.datatoolsservices.VariableUtils.generateUniqueName(validPropName, varNames);
                    [r,c] = find (this.PropNameMap == colName);
                    if isempty(r)
                        this.PropNameMap(height(this.PropNameMap)+1,1) = colName;
                        this.PropNameMap(height(this.PropNameMap),2) = validPropName;
                    else
                        this.PropNameMap(r,c+1) = validPropName;
                    end
                    % add to exclusion List
                    varNames{end+1} = char(validPropName);
                end
                this.addNewProp(tableObj, i, tableName, validPropName, workspace);
                this.VariablesObj(end+1) = colName;
            end
        end   

        % Helper function to retrieve specific table dimension names from
        % properties 
        function dimName = getDimensionName(~, properties, index)
            dimName = properties.DimensionNames{index};
        end

        function addNewProp(this, tableObj, column, tableName, variableName, workspace)
            currValue = matlab.internal.datatools.sidepanelwidgets.propediting.VariableMetaDataObj(tableObj, column, tableName, workspace, this.TableProperties);
            this.addprop(variableName);
            % Add VariableMetaDataObj for variableName as property
            this.(variableName) = currValue;
        end

        function dimName = get.RowDimensionName(obj)
            tableProps = matlab.internal.datatools.sidepanelwidgets.propediting.TableMetaDataObj.getTableProperties(obj);
            dimName = string(obj.getDimensionName(tableProps, 1));
        end

        % Helper function generate the command string used to set a
        % dimension name in the table properties
        function setDimStr = createSetDimNameStr(~, index)
            setDimStr = ['%s.Properties.DimensionNames(' num2str(index) ') = "%s";'];
        end

        function set.RowDimensionName(obj, value)
            rowDimValue = matlab.internal.datatools.sidepanelwidgets.propediting.TableMetaDataObj.getEscapedString(char(value));
            cmd = sprintf(obj.createSetDimNameStr(1), obj.TableName, rowDimValue);
            evalin(obj.Workspace, cmd);
            internal.matlab.desktop.commandwindow.insertCommandIntoHistoryWithNoPrompt(cmd);
            obj.updatePropertiesCache(obj);
        end

        function dimName = get.VariableDimensionName(obj)
            tableProps = matlab.internal.datatools.sidepanelwidgets.propediting.TableMetaDataObj.getTableProperties(obj);
            dimName = string(obj.getDimensionName(tableProps, 2));
        end

        function set.VariableDimensionName(obj, value)
            varDimValue = matlab.internal.datatools.sidepanelwidgets.propediting.TableMetaDataObj.getEscapedString(char(value));
            cmd = sprintf(obj.createSetDimNameStr(2), obj.TableName, varDimValue);
            evalin(obj.Workspace, cmd);
            internal.matlab.desktop.commandwindow.insertCommandIntoHistoryWithNoPrompt(cmd);
            obj.updatePropertiesCache(obj);
        end

        function userData = get.UserData(obj)
            tableProps = matlab.internal.datatools.sidepanelwidgets.propediting.TableMetaDataObj.getTableProperties(obj);
            userData = tableProps.UserData;
        end

        % TODO: Update on DataChanged event
        function set.UserData(obj, value)
        end

        function userData = get.Description(obj)
            tableProps = matlab.internal.datatools.sidepanelwidgets.propediting.TableMetaDataObj.getTableProperties(obj);
            userData = tableProps.Description;
        end

        function set.Description(obj, value)
            desc = matlab.internal.datatools.sidepanelwidgets.propediting.TableMetaDataObj.getEscapedString(char(value));
            cmd = sprintf('%s.Properties.Description = "%s";', obj.TableName, desc);
            evalin(obj.Workspace, cmd);
            internal.matlab.desktop.commandwindow.insertCommandIntoHistoryWithNoPrompt(cmd);
            obj.updatePropertiesCache(obj);
        end
    end

    methods(Static)
        % If Table properties are set,return the cached version. Else query
        % from desktop.
        function props = getTableProperties(obj)
            if ~isempty(obj.TableProperties)
                props = obj.TableProperties;
            else
                props = evalin(obj.Workspace, obj.TableName + ".Properties");
            end
        end

        function updatePropertiesCache(obj)
            if ~isempty(obj.TableProperties)
                obj.updateTablePropertiesCache();
            end
        end

        % Updating table properties cache.
        function updateTablePropertiesCache(obj, tableObj)
            arguments
                obj 
                tableObj = []
            end
            if isempty(tableObj)
                obj.TableProperties = evalin(obj.Workspace, obj.TableName + ".Properties");
            else
               obj.TableProperties = tableObj.Properties;
            end
        end
       
        function str = getEscapedString(inputStr)
            str = replace(inputStr, '"', '""');
        end
    end
end

