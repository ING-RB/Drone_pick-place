classdef ArrayWithColumnFormatSupportStrategy< matlab.ui.internal.controller.uitable.utils.TableViewDataStrategy
    %ARRAYWITHCOLUMNFORMATSUPPORTSTRATEGY - This contains any code that is
    % shared by all arrays that support column format
    
    methods (Static)
        
        function groupedColumnWidths = getGroupColumnSize(data)
            % GETGROUPCOLUMNSIZE - Get the size of each column. For
            % non-table array data, the width of each column is always 1.
            % Value is returned as a cell array of numbers.
            
            groupedColumnWidths = repmat({1}, 1, size(data, 2));
        end
        
        function doesRequire = requiresAdditionalColumnMetadataWhenDataSet(dataType)
            % REQUIRESADDITIONALCOLUMNMETADATAWHENDATASET - Returns true if
            % the additional column metadata has a dependency on the Data.
            
            % Strategies with columnFormat only support column metadata
            % when the ColumnFormat changes. Data sets do not have an
            % effect.
            doesRequire = false;
        end
        
        function categoricalMetadata = getCategoricalMetadata(data, columnFormat, varargin)
            % GETCATEGORICALMETADATA - returns a cell containing PV
            % pairs with the categorical properties that are required to be
            % sent to the view
            
            switch nargin
                case 3
                    column = varargin{1};
                case 4
                    row = varargin{1};
                    column = varargin{2};
            end
            hasCategoricalMetadata = column <= numel(columnFormat) ...
                && ~isempty(columnFormat) && iscell(columnFormat{column});
            
            categoricalMetadata = struct();
            
            if  hasCategoricalMetadata
                % Users are allowed to enter what they wish
                isProtected = false;
                
                % Use the categorical model (in table arrays) for additional properties
                categoricalMetadata.Protected = isProtected;
                categoricalMetadata.Categories = columnFormat{column};
            else
                % Clear Categories and Protected
                categoricalMetadata.Protected = logical.empty;
                categoricalMetadata.Categories = {};
            end
        end
        
        function supportsSorting = dataSupportsSorting(data, datatype, columnSortable)
            
            % By default, treat all columns as sortable.
            % Specialized data will provide additional constraints
            supportsSorting = columnSortable;
        end
        function supportsColumnFormat = dataSupportsColumnFormat()
            
            % By default, this class supports ColumnFormat
            supportsColumnFormat = true;
        end
    end
end

