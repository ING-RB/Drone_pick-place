classdef ObjectArrayViewModel < ...
        internal.matlab.variableeditor.ArrayViewModel
    %OBJECTARRAYVIEWMODEL
    % Object Array View Model

    % Copyright 2015-2023 The MathWorks, Inc.
    properties
        MetaData = [];
    end

    properties (SetObservable=true, SetAccess='protected', Transient)
        CellMetaDataChangedListener;
    end

    methods(Access='public')
        % Constructor
        function this = ObjectArrayViewModel(dataModel, viewID, userContext)
            if nargin < 3
                userContext = '';
                if nargin < 2
                    viewID = '';
                end
            end
            this@internal.matlab.variableeditor.ArrayViewModel(dataModel, viewID, userContext);
            this.initListeners();
        end
        
        function [renderedData, renderedDims] = getDisplayData(this, startRow, endRow, startColumn, endColumn)
            [renderedData, renderedDims, this.MetaData] = internal.matlab.variableeditor.ObjectArrayViewModel.getParsedExpandedObjectArrayData(...
                this.DataModel.Data, this.DataModel.DataAsCell, startRow, endRow, startColumn, endColumn, this.DisplayFormatProvider.NumDisplayFormat);
        end
    
        % getRenderedData
        % returns a cellstr for the desired range of values
        function [renderedData, renderedDims] = getRenderedData(this,startRow, endRow, startColumn, endColumn)
            [renderedData, renderedDims] = this.getDisplayData(startRow, endRow, startColumn, endColumn);
        end

        % The view model's getSize should always return the size of the 
        % object array when converted to a cell array 
        function s = getSize(this)
            data = this.DataModel.getData;
            % mx1 object array
            if (size(data,2) == 1)
                s = [size(data,1) length(this.DataModel.getProperties())];
            % 1xm object array, 0x0 object array
            else
                s = [size(data,2) length(this.DataModel.getProperties())];
            end
        end

        % The view model's getData should return the data  
        % converted to a cell array 
        function varargout = getData(this,varargin)
            varargout{1} = this.DataModel.getData(varargin{:});
        end

        function varargout = getFormattedSelection(this, varargin)
            rows = this.SelectedRowIntervals;
            cols = this.SelectedColumnIntervals;

            data = this.DataModel.Data;
            variableName = this.DataModel.Name;

            props = this.DataModel.getProperties();

            if isempty(rows) || isempty(cols) || any(cols > length(props), "all")
                varargout{1} = variableName;
                return;
            end

            rowIndices = "[" + join(join(string(rows), ":"), ",") + "]";
            rowIndices = regexprep(rowIndices, "(?<row>\d*?):\1(?<rest>\D|$)", "$<row>$<rest>");
            colIndices = "[" + join(join(string(cols), ":"), ",") + "]";
            colIndices = regexprep(colIndices, "(?<row>\d*?):\1(?<rest>\D|$)", "$<row>$<rest>");
            expandedCols = eval(colIndices);
            if ~strcmp(rows, ':')
                expandedRows = eval(rowIndices);
            else
                expandedRows = 1:length(data);
            end
            % Cap the expanded columns to the length of the properties in
            % case the user has switched from full property list to
            % shortened property list
            expandedCols = expandedCols(expandedCols <= length(props));
            if ~isempty(props)
                colNames = string(props(expandedCols));
                if strcmp(rows, ':') || (length(expandedRows) == length(data))
                    dataRowCmd = variableName;
                else
                    dataRowCmd = sprintf("%s(%s)", variableName, rowIndices);
                end
                
                % Char's need to be made into cellstrs
                charColumns = zeros(1, length(colNames));
                try
                    charColumns = arrayfun(@(v)ischar([data.(v)]), colNames);
                catch
                    for i=1:length(colNames)
                        try
                            cn = colNames(i);
                            charColumns(i) = ischar(data.(cn));
                        catch
                        end
                    end
                end
    
                if any(charColumns)
                    colStrings = string.empty;
                    for col = 1:length(colNames)
                        if (charColumns(col))
                            colStrings(end+1) = "{" + dataRowCmd + "." + colNames(col) + "}";
                        else
                            colStrings(end+1) = "[" + dataRowCmd + "." + colNames(col) + "]";
                        end
                    end
                    selectionString = "[" + colStrings.join(";") + "]";
                else
                    selectionString = "[" + dataRowCmd + "." + colNames.join("];[" + dataRowCmd + ".") + "]";
                end
    
                varargout{1} = char(selectionString);
            else
                varargout{1} = {};
            end
        end

        % Cleanup any listeners that were attached at constructor time
        function delete(this)
            if ~isempty(this.CellMetaDataChangedListener)
                delete(this.CellMetaDataChangedListener);
                this.CellMetaDataChangedListener = [];
            end
        end

        function [secondaryStatus,totalPropertyCount,visiblePropertyCount] = getSecondaryStatus(this)
            totalPropertyCount = height(properties(this.DataModel.Data));
            visiblePropertyCount = height(this.DataModel.getProperties());

            % Set summary bar status
            if totalPropertyCount == 1
                secondaryStatus = getString(message('MATLAB:codetools:variableeditor:ObjectVectorOneProperty'));
            elseif totalPropertyCount == visiblePropertyCount
                secondaryStatus = getString(message('MATLAB:codetools:variableeditor:ObjectVectorProperties', totalPropertyCount));
            else
                secondaryStatus = getString(message('MATLAB:codetools:variableeditor:ObjectVectorFilteredProperties', visiblePropertyCount, totalPropertyCount));
            end
        end
    end

    methods(Access='protected')
        % Initializing listeners
        function initListeners(this)
            this.CellMetaDataChangedListener = event.listener(this.DataModel,'CellMetaDataChanged',@(es,ed) this.notifyCellMetaDataChanged(ed));            
        end

        function notifyCellMetaDataChanged(this, ed)
            try
                this.notify('CellMetaDataChanged', ed);
            catch e
                internal.matlab.datatoolsservices.logDebug("variableeditor::ObjectArrayViewModel::notifyCellMetaDataChanged::error", e.message)
            end
        end
    end
    
    methods(Static)
        function [renderedData, renderedDims] = ...
                getParsedObjectArrayData(currentData, startRow, endRow, ...
                startColumn, endColumn)
            % Return the renderedData for the object array, in the
            % specified range (startRow/endRow startColumn/endColumn)            
            try
                currentDataCell = arrayfun(@(x) {x}, currentData);
            catch
                s = size(currentData);
                currentDataCell = cell(s);
                for row = 1:s(1)
                    for col = 1:s(2)
                        currentDataCell{row, col} = currentData(row, col);
                    end
                end
            end
            [renderedData, renderedDims, ~] = ...
                internal.matlab.datatoolsservices.FormatDataUtils.formatDataBlockForMixedView(startRow, endRow, ...
                startColumn, endColumn, currentDataCell);
            
        end

        function [renderedData, renderedDims, metaData] = getParsedExpandedObjectArrayData(data, ...
                dataAsCell, startRow, endRow, startColumn, endColumn, format)
            arguments
                data
                dataAsCell cell
                startRow double
                endRow double
                startColumn double
                endColumn double
                format string = internal.matlab.datatoolsservices.FormatDataUtils.getCurrentNumericFormat;
            end
            if ~isempty(data)
                currentDataAsCell =  dataAsCell;
                [renderedData, renderedDims, metaData] = internal.matlab.datatoolsservices.FormatDataUtils.formatDataBlockForMixedView(...
                    startRow,endRow,startColumn,endColumn,currentDataAsCell,format);
            else
                renderedDims = size(data);
                renderedData = cell(renderedDims);
                metaData = false(renderedDims);
            end            
        end
    end
end