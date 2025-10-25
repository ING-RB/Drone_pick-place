classdef TabularMetaDataStore < handle
    %TabularMetaDataStore Abstract Tabular MetaDataStore Class
    
    events
        CellMetaDataChanged;
        TableMetaDataChanged;
        ColumnMetaDataChanged;
        RowMetaDataChanged;
    end
    
    methods (Access='public',Abstract=true)
        tableProperties = getTabularTableMetaData(this);
        columnProperties = getTabularColumnMetaData(this, column);
        rowProperties = getTabularRowMetaData(this, row);
        cellProperties = getTabularCellMetaData(this, row, column);
    end
end