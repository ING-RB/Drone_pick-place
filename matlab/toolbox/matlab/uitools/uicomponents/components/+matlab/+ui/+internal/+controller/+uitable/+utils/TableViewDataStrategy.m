classdef TableViewDataStrategy < handle
    %TABLEVIEWDATASTRATEGY This fine contains any operations for the
    %datastore that vary by the class of the Data property
    % This strategy is for when the Data property contains a table array
    % 
    
    methods (Abstract, Static)
        % Returns data type per column
        dataType = getDataType(data);
        
        % Returns a cell array of numbers representing the column widths
        groupedColumnWidths = getGroupColumnSize(data)
        
        % Returns true if column metadata must be updated when data is set
        doesRequire = requiresAdditionalColumnMetadataWhenDataSet(dataType)
        
        % Additional categorical metadata for specific datatypes
        categoricalMetadata = getCategoricalMetadata(data, columnFormat, column, row)
        
        % Returns true if the group column size can change
        supportsGroup = supportsGroupColumnSize();
        
        % Returns true if the strategy supports the datatype
        supportsData = supportsData(data)
        
        % Returns per column true/false if column is sortable
        supportsSorting = dataSupportsSorting(data, columnIndex, datatype);

        % Returns true/false if ColumnFormat is supported
        supportsSorting = dataSupportsColumnFormat(data);
        
    end
    
    methods (Static, Access = protected)

        function isSortable = isDataTypeSortable(datatype)
            % ISDATATYPESORTABLE - The inputs supported by sortrows are
            % taken from the doc
            % numeric types: double | single | int8 | int16 | int32 | 
            %       int64 | uint8 | uint16 | uint32 | uint64 | 
            % other types: logical | char | string | categorical |
            %       datetime | duration
            % 'char' is replaced with cellstr for the purpose of the sort
            % feature
            
            isSortable = any(strcmp(datatype, ["double", "single", ...
                "int8", "int16", "int32", "int64", "uint8", "uint16", ...
                "uint32", "uint64", "logical", "cellstr", "string", ...
                "categorical", "datetime", "duration"]));
        end

        function isSortable = isCellArraySortable(cellArray)
            % ISCELLARRAYSORTABLE - Returns true if cell Array is sortable,
            % returns false if cell array is not sortable.

            % Not sortable - empty values in cell array
            % Not sortable - cell array of mixed data types
            isSortable = false;

            if iscellstr(cellArray)
                isSortable = true;
            else
                % Check if cell array contains mixed data type
                cellClass = class(cellArray{1});
                hasSameClass = cellfun('isclass',cellArray,cellClass);
                
                % Check if cell array has empty element
                isCellEmpty = find(cellfun(@isempty,cellArray));
                
                if ~all(hasSameClass(:)) || numel(isCellEmpty)>0
                    isSortable = false;
                else
                    isSortable = matlab.ui.internal.controller.uitable.utils.TableViewDataStrategy.isDataTypeSortable(class(cellArray{1}));
                end
            end
        end
    end
end

