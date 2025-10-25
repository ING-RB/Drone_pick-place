classdef TableArrayStrategy< matlab.ui.internal.controller.uitable.utils.TableViewDataStrategy
    %TABLEVIEWDATASTRATEGY - This contains any code that specialized for
    %when the Data property contains a table array (vs numeric or cell
    %array).
    
    methods    
        function obj = TableArrayStrategy()
            
        end
    end
    
    methods (Static)
        function dataType = getDataType(data, varargin)
            % GETDATATYPE - Return cell array of strings representing the
            % datatype sent to the view for each column
            
            switch nargin
                case 1
                    varNames = data.Properties.VariableNames;
                    dataType = cell(1, length(varNames));

                    for index = 1:length(varNames)

                        if iscellstr(data.(varNames{index}))
                            dataType{index} = 'cellstr';
                        else
                            dataType{index} = class(data.(varNames{index}));
                        end
                    end
                case 2
                    % TODO
                case 3
                    % For mixed cell data types
                    row = varargin{1};
                    column = varargin{2};
                    data = data{row,column};
                    if iscell(data)
                        cellData = data{1};
                    else
                        cellData = data;
                    end

                    if iscellstr(data)
                        dataType = 'cellstr';
                    else
                        dataType = class(cellData);
                    end
            end
        end
        
        function groupedColumnWidths = getGroupColumnSize(data)
            % GETGROUPCOLUMNSIZE - Get the size of each column.  For table
            % array, it is the width of each variable in the table array.
            % Value is returned as a cell array of numbers.
            % Minimum value for each group should be 1
            
            variableNames = string(data.Properties.VariableNames);
            groupedColumnWidths = num2cell(ones(1, numel(variableNames)));
            
            for idx = 1:numel(variableNames)
                
                if ischar(data.(variableNames(idx)))
                    groupedColumnWidths{idx} = 1;
                else
                    sz = size(data.(variableNames(idx)));
                    % Grouped column size can be more than one for 2-D data,
                    % but not 3+ dimensional data.  This keeps the uitable
                    % output consistent with table array commandline.
                    if sz(2) > 1 && numel(sz) == 2
                        groupedColumnWidths{idx} = sz(2);
                    end
                end
            end            
        end
        
        function doesRequire = requiresAdditionalColumnMetadataWhenDataSet(dataType)
            % REQUIRESADDITIONALCOLUMNMETADATAWHENDATASET - Returns true if
            % the additional column metadata has a dependency on the Data.
            
            doesRequire = any(strcmp(dataType, 'categorical'));
        end
        
        function categoricalMetadata = getCategoricalMetadata(data, columnFormat, varargin)
           % getCategoricalMetadata - returns a cell containing PV 
           % pairs with the additional properties that are required to be
           % sent to the view 
           categoricalMetadata = {};
           
           switch nargin
                case 3
                    column = varargin{1};
                    categoricalMetadata = struct();
                    if iscategorical(data.(column))
               			categoricalMetadata.Protected = isprotected(data.(column));
               			categoricalMetadata.Categories = categories(data.(column))';
                    else
                        % Clear Categories and Protected
                        categoricalMetadata.Protected = logical.empty;
                        categoricalMetadata.Categories = {};
                    end
                case 4
                    row = varargin{1};
                    column = varargin{2};
					categoricalMetadata = struct();
					cellData = data{row, column};
                    if iscell(cellData)
                        cellData = cellData{1};
                    end
                    if iscategorical(cellData)
                        categoricalMetadata.Protected = isprotected(cellData);
                        categoricalMetadata.Categories = categories(cellData)';
                    else
                        % Clear Categories and Protected
                        categoricalMetadata.Protected = logical.empty;
                        categoricalMetadata.Categories = {};
                    end
           end   
        end
        
        function doesSupportGroup = supportsGroupColumnSize()
            % SUPPORTSGROUPCOLUMNSIZE - Returns true if this strategy supports group
            % column size that is non-default of 1
            
            doesSupportGroup = true;            
        end 
        
        function doesSupportData = supportsData(data)
            % SUPPORTSDATA - Returns true if this strategy supports this
            % data type.  Returns false if not.
            
            doesSupportData = istable(data);
            
        end
        
        function supportsSorting = dataSupportsSorting(data, columnIndices, datatype)
            % DATASUPPORTSSORTING - Returns true if the column of data
            % supports sorting, returns false if not.  Returns a boolean
            % array the same size as columnIndex;
            
            supportsSorting = true(size(columnIndices));
            for index = 1: numel(columnIndices)
                colIndex = columnIndices(index);
                columnDataType = datatype(colIndex);                
                if strcmp(columnDataType, 'cell')
                    supportsSorting(index) = matlab.ui.internal.controller.uitable.utils.TableViewDataStrategy.isCellArraySortable(data{:, colIndex});
                else
                    supportsSorting(index) = matlab.ui.internal.controller.uitable.utils.TableViewDataStrategy.isDataTypeSortable(columnDataType);
                end

            end
        end

        function supportsColumnFormat = dataSupportsColumnFormat()
            
            % By default, this class does not support ColumnFormat
            supportsColumnFormat = false;
        end
    end  
    
end

