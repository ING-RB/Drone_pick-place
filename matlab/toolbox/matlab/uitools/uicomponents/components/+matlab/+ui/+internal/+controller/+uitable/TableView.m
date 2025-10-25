classdef TableView < handle
    %UITableView abstract interface defines how the table controller talks to
    % its view implementation.
    
    %   Copyright 2021 The MathWorks, Inc.
    
    methods (Abstract)

        % setters
        % update data in table view.
        updateViewData(obj)
        
        % update single cell data in table view.
        updateSingleViewData(obj, row, column)
        
        setViewColumnName(obj, columnName)
        
        setViewColumnEditable(obj, editable)
        
        setViewColumnSortable(obj, sortable)
        
        setViewColumnFormat(obj, formats)
        
        setViewColumnRearrangeable(obj, rearrangeable)
        
        setViewTableStyle(obj, style)
        
        setViewColumnWidth(obj, columnWidth)

        setViewGroupColumnSize(obj, data);

        sortTable(obj, columnIndex, direction)
        
        clearCellMetaData(obj, displayRow, displayColumn)
        
        clearRowMetaData(obj, displayRow)
        
        clearColumnMetaData(obj, displayColumn)
        
        clearTableMetaData(obj)
        
        convertToViewIndex(obj, modelIndex, indexType)
        
        % getters
        [ChannelID] = getViewInfo(obj)

        metadata = getMetadataDefaults(obj)
        
        dataSize = getDataStoreSourceDataSize(obj)

        setViewDataType(obj, data)
    end
end