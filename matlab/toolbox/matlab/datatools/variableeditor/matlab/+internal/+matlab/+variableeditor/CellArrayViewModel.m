classdef CellArrayViewModel < internal.matlab.variableeditor.ArrayViewModel
    %CellARRAYVIEWMODEL
    %   Cell Array View Model

    % Copyright 2014-2021 The MathWorks, Inc.
    
    properties
        MetaData = [];
    end
    
    % Public Abstract Methods
    methods(Access='public')
        % Constructor
        function this = CellArrayViewModel(dataModel, viewID, userContext)
            if nargin < 3
                userContext = '';
                if nargin < 2
                    viewID = '';
                end
            end
            this@internal.matlab.variableeditor.ArrayViewModel(dataModel, viewID, userContext);
        end
        
        function [renderedData, renderedDims, metaData] = getDisplayData(this,startRow,endRow,startColumn,endColumn)
            [renderedData, renderedDims, metaData] = internal.matlab.variableeditor.CellArrayViewModel.getParsedCellArrayData(...
                this.DataModel.Data, startRow, endRow, startColumn, endColumn, this.DisplayFormatProvider.NumDisplayFormat);
        end
        
        
        function [renderedData, renderedDims] = getRenderedData(this,startRow,endRow,startColumn,endColumn)
            currentData = this.DataModel.Data;
            [currentFormat, c] = internal.matlab.datatoolsservices.FormatDataUtils.getCurrentNumericFormat(true); 
            shortFormat = this.DisplayFormatProvider.NumDisplayFormat;
            format(shortFormat);
            [renderedData, renderedDims, metaData] = internal.matlab.variableeditor.CellArrayViewModel.getParsedCellArrayData(...
                currentData, startRow, endRow, startColumn, endColumn, shortFormat);
            this.MetaData = metaData;
        end
        
        % overriding the method to support the plots gallery
        function varargout = getFormattedSelection(this, varargin)
            data = this.DataModel.Data;
            outputSelectionString = '';
            % if data is not empty and the selection is not empty then
            % compute the selectionString
            if ~isempty(data) && ~isempty(this.SelectedRowIntervals) && ~isempty(this.SelectedColumnIntervals)                                
                selectionString = this.getFormattedSelection@internal.matlab.variableeditor.BlockSelectionModel();
                
                % replace the name of the selected variable with the string
                % 'data' so that we can evaluate it in the current workspace
                % 1. get the first occurrence of the datamodel name
                % 2. replace that with the string 'data'
                % 3. evaluate the string in the current workpace
                index = strfind(selectionString, this.DataModel.Name);
                evalSelectedDataString = ['data' selectionString(index(1)+length(this.DataModel.Name):end) ';'];
                selectedData = eval(evalSelectedDataString);
                          
                % cell arrays are supported by the plots gallery only if
                % 1. they contain scalar numerics or logical data
                % 2. all the cells in the selection should be of the
                % same type
                if(isnumeric(selectedData{1,1}) || islogical(selectedData{1,1})) 
                    if all(cellfun('isclass',selectedData,class(selectedData{1,1})))
                        % check if the dimensions of the elements are the same
                        % assuming 2 dimensions for all data
                        dim1 = cellfun('size',selectedData,1);
                        dim2 = cellfun('size',selectedData,2);
                        if(all(dim1(:)==1) && all(dim2(:)==1))
                            % wrap the selection in 'cell2mat' in order to compute
                            % the plots
                            outputSelectionString = ['cell2mat(' selectionString ')'];

                        % assuming it is not uncommon to have the first cell of
                        % the column as a heading, skip the first element
                        elseif(length(selectedData)> 1) && all(dim1(2:end)==1) && all(dim2(2:end)==1) 
                            selectionString = [this.DataModel.Name '('];
                            dataSize = this.getSize;
                            selectedRows = [];
                            selectedColumns = [];

                            % if selRow(1,1) == 1 then we have to ignore
                            % the first entry. We need to handle 2 cases
                            % Ex 1: [1 1;2 2;3 3] => [2 2;3 3]
                            % Ex 2: [1 3;4 5;6 7] => [2 3;4 5;6 7]
                            if isequal(this.SelectedRowIntervals(1),1) 
                                selectedRows = ignoreHeaderEntry(this.SelectedRowIntervals);
                                selectedColumns = this.SelectedColumnIntervals;
                            % handle similar case for columns
                            elseif isequal(this.SelectedColumnIntervals(1),1) 
                                selectedColumns = ignoreHeaderEntry(this.SelectedColumnIntervals);
                                selectedRows = this.SelectedRowIntervals;
                            end

                            if ~isempty(selectedRows) && ~isempty(selectedColumns)
                                selectionString = this.getSelectionString(selectionString, dataSize(1,1), selectedRows);
                                if ~isempty(selectedColumns)
                                    selectionString = [selectionString ','];
                                end
                                selectionString = this.getSelectionString(selectionString, dataSize(1,2), selectedColumns);
                                selectionString = [selectionString ')'];
                                outputSelectionString = ['cell2mat(' selectionString ')'];
                            end
                        end
                    end
                end
            end
            varargout{1} = outputSelectionString;
        end           
        
    end
    
    methods(Static)
        function [renderedData, renderedDims, metaData] = getParsedCellArrayData(data, ...
                startRow, endRow, startColumn, endColumn, format)
            arguments
                data
                startRow double
                endRow double
                startColumn double
                endColumn double
                format string = internal.matlab.datatoolsservices.FormatDataUtils.getCurrentNumericFormat;
            end
           
            [renderedData, renderedDims, metaData] = internal.matlab.datatoolsservices.FormatDataUtils.formatDataBlockForMixedView( ...
                startRow,endRow,startColumn,endColumn,data, format);
        end
    end    
end

function result = ignoreHeaderEntry(selection)
    % case : [1 1;2 2;3 3] => [2 2;3 3]
    if (selection(1,2) == 1)
        selection = selection(2:end,:);
    % case : [1 3;4 5;6 7] => [2 3;4 5;6 7]
    else
        selection(1,1) = selection(1,1) + 1;
    end
    result = selection;
end


            

