classdef DatasetMetaDataProxyView < matlab.internal.datatools.sidepanelwidgets.propediting.TableMetaDataProxyView
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Internal class that defines the DatasetMetaData ProxyView to represent
    % proxy view in displaying dataset properties in Property Inspector
    
    % Copyright 2022 The MathWorks, Inc.

    methods
        function this = DatasetMetaDataProxyView(datasetMetaDataObj)
            this@matlab.internal.datatools.sidepanelwidgets.propediting.TableMetaDataProxyView(datasetMetaDataObj);
        end

        % Helper function to not initialize custom properties as datasets
        % do not have custom properties
        function initializeCustomProperties(~)
        end

    end
end

