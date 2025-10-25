classdef CellArrayStrategy< matlab.ui.internal.controller.uitable.utils.ArrayWithColumnFormatSupportStrategy
    %CELLARRAYSTRATEGY - This contains any code that specialized for
    %when the Data property contains cell array.
        
    methods (Static)
        function dataType = getDataType(data, varargin)
            % GETDATATYPE - Return cell array of strings representing the
            % datatype sent to the view for each column
            
            switch nargin
                case 1
                    dataType = repmat({class(data)}, 1, size(data, 2));

                    for index = 1:length(dataType)
                        if iscellstr(data(:, index))
                            dataType{index} = 'cellstr';
                        end
                    end
                case 2
                    % TODO: column pagination feature
                case 3
                    row = varargin{1};
                    column = varargin{2};
                    if iscellstr(data(row,column))
                        dataType = 'cellstr';
                    else
                        dataType = class(data{row,column});
                    end
            end
        end
        
        function doesSupportGroup = supportsGroupColumnSize()
            % SUPPORTSGROUPCOLUMNSIZE - Returns true if this strategy supports group
            % column size that is non-default of 1
            
            doesSupportGroup = false;            
        end 
        
        function doesSupportData = supportsData(data)
            % SUPPORTSDATA - Returns true if this strategy supports this
            % data type.  Returns false if not.
            
            doesSupportData = iscell(data);            
        end 
        
        function supportsSorting = dataSupportsSorting(data, columnIndices, datatype)
            % DATASUPPORTSSORTING - Returns true if the column of data
            % supports sorting, returns false if not.  Returns a boolean
            % array the same size as columnIndex;
            supportsSorting = true(size(columnIndices));
            
            for index = 1: numel(columnIndices)
                colIndex = columnIndices(index);
                               
                supportsSorting(index) = matlab.ui.internal.controller.uitable.utils.TableViewDataStrategy.isCellArraySortable(data(:, colIndex));
            end
        end
    end
end

