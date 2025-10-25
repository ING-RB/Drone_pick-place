classdef DatasetMetaDataObj < matlab.internal.datatools.sidepanelwidgets.propediting.TableMetaDataObj
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Internal class that defines the DatasetMetaData Object to represent
    % table properties for viewing and editing
    
    % Copyright 2022 The MathWorks, Inc.
    
    methods
        
        % Helper function to retrieve the dataset variable names from
        % properties 
        function varNames = getVarNames(~, properties)
            varNames = properties.VarNames;
        end

        % Helper function to override superclass to do nothing as datasets
        % do not have custom properties
        function addCustomProps(~)
        end

        % Helper function to retrieve specific dataset dimension names from
        % properties 
        function dimName = getDimensionName(~, properties, index)
            dimName = properties.DimNames{index};
        end

        % Helper function generate the command string used to set a
        % dimension name in the dataset properties
        function setDimStr = createSetDimNameStr(~, index)
            setDimStr = ['%s.Properties.DimNames{' num2str(index) '} = "%s";'];
        end
    end
end

