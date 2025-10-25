classdef RemoteNumericArrayViewModel < internal.matlab.variableeditor.peer.RemoteArrayViewModel & ...
        internal.matlab.variableeditor.NumericArrayViewModel
    %REMOTENUMERICARRAYVIEWMODEL Remote Model Numeric Array View Model

    % Copyright 2013-2024 The MathWorks, Inc.

    properties
        scalingFactorString;
    end

    properties (Access=private)
        ShowMultipliedExponent (1,1) logical % True if we multiply exponents and false if we display scaling factor
    end

    methods
        % Constructor of the ViewModel. Do not set any model properties
        % during view initialization
        function this = RemoteNumericArrayViewModel(document, variable, viewID, userContext)
            if nargin < 4
                userContext = '';
                if nargin < 3
                    viewID = '';
                end
            end
            % Ensure that NumericArrayViewModel is initialized first, else
            % TableModelProperties set during initTableModelInformation
            % will get reset.
            this@internal.matlab.variableeditor.NumericArrayViewModel(variable.DataModel, viewID, userContext);
            this = this@internal.matlab.variableeditor.peer.RemoteArrayViewModel(document,variable, 'viewID', viewID);
            this.ShowMultipliedExponent = this.shouldShowMultipliedExponentValues(userContext);
            this.updateScalingFactorString();
            this.setProperty('Slice', this.DataModel.Slice);
            this.setProperty('FullSize', size(this.DataModel.DataI));
        end 
        
        % Overrides RemoteArrayViewModel, do not set any table model props
        % initially
        function initTableModelInformation(this)
        end
    end

    methods(Access='public')
        % getRenderedData
        % returns a cell array of strings for the desired range of values
        function [renderedData, renderedDims] = getRenderedData(this,startRow,endRow,startColumn,endColumn)
            fullData = this.DataModel.Data;
            dataSubset = this.getData(startRow,endRow,startColumn,endColumn);
            [renderedData, renderedDims] = internal.matlab.variableeditor.peer.RemoteNumericArrayViewModel.getJSONForNumericData(fullData, dataSubset, ...
                startRow, endRow, startColumn, endColumn, this.userContext, this.scalingFactorString, this.DisplayFormatProvider, this.ShowMultipliedExponent);       
        end
        
        % For numerics that have columnWidth at a table level(Live Editor), do not set
        % ColumnWidths at a column level.
        function updateColumnWidths(this, startCol, endCol)
            if ~isempty(this.getTableModelProperty('ColumnWidth'))
                return;
            end
            this.updateColumnWidths@internal.matlab.variableeditor.peer.RemoteArrayViewModel(startCol, endCol);
        end

        function status = handlePropertySetFromClient(this, ~, ed)
            status = '';
            if ~isvalid(this) || ~isfield(ed, 'data')
                return;
            end

            if strcmpi(ed.data.key, 'Slice')
                if isprop(this.DataModel, 'Slice')
                    this.DataModel.Slice = string(ed.data.newValue);
                    return;
                end
            end

            status = this.handlePropertySetFromClient@internal.matlab.variableeditor.peer.RemoteArrayViewModel([], ed);
        end
    end
    
    methods(Static)
        % TODO: Move this to a utility or make this a server side plugin.
        function [renderedData, renderedDims, scalingFactorString, dataSubset] = getJSONForNumericData(fullData, dataSubset, startRow, endRow, startColumn, endColumn, usercontext, scalingFactorString, DisplayFormatProvider, showMultipliedExponent)
            arguments
                fullData;
                dataSubset;
                startRow double;
                endRow double;
                startColumn double;
                endColumn double;
                usercontext string;
                scalingFactorString string;
                DisplayFormatProvider internal.matlab.variableeditor.NumberDisplayFormatProvider = internal.matlab.variableeditor.NumberDisplayFormatProvider
                showMultipliedExponent (1,1) logical = false
            end
            [currentFormat, c] = internal.matlab.datatoolsservices.FormatDataUtils.getCurrentNumericFormat(true); 
            origData = dataSubset;
            shortFormat = DisplayFormatProvider.NumDisplayFormat;
            longFormat = DisplayFormatProvider.LongNumDisplayFormat;
            % Convert to current NumDisplayFormat for evalc if scaling factor is present.
            format(shortFormat);
            [dataSubset, ~, scalingFactorString] = internal.matlab.variableeditor.peer.PeerDataUtils.getFormattedNumericData(fullData, dataSubset, scalingFactorString, DisplayFormatProvider.NumDisplayFormat, showMultipliedExponent);
            longData = dataSubset;
            % TODO: We should not be checking this based on context, this should be a server side plugin for numeric outputs. 
            % Fetch long formats only if they differ from short formats
            if ~internal.matlab.variableeditor.peer.PeerUtils.isLiveEditor(usercontext) && ~strcmp(shortFormat, longFormat)
                % Convert to current LongNumDisplayFormat for evalc if scaling factor is present.
                format(longFormat);
                [longData, ~, scalingFactorString] = internal.matlab.variableeditor.peer.PeerDataUtils.getFormattedNumericData(fullData, origData, scalingFactorString, DisplayFormatProvider.LongNumDisplayFormat, showMultipliedExponent);
            end
            renderedData = cell(size(dataSubset));
            
            try
                if ~internal.matlab.variableeditor.peer.PeerUtils.isLiveEditor(usercontext)
                    % Create JSON string, calling toJSON once instead of in
                    % a loop optimizes performance, but means in order to
                    % create our array of strings, we need to split up the
                    % JSON array removing the array elements
                    % [[,,,],[,,,]...[,,,]]
                    numRows = min(size(renderedData,1),size(dataSubset,1));
                    numCols = min(size(renderedData,2),size(dataSubset,2));
                    sa = struct('value', [], 'editValue', []);
                    sa = repmat(sa, numRows, numCols);
                    for row=1:numRows
                        for col=1:numCols
                            sa(row,col).value = dataSubset{row,col};
                            sa(row,col).editValue = longData{row,col};
                        end
                    end
                    % JSON encode
                    jd = jsonencode(sa);

                    % Get rid of array brackets and split out row elements
                    if size(sa,2) > 1
                        jd = jd(2:end-1);
                    end
                    rs = split(jd, "],[");
                    % Get rid of array elements
                    rs = strrep(rs, "[", "");
                    rs = strrep(rs, "]", "");
                    % Replace comma between cells with arbitrary string so that we can split on it
                    rs = strrep(rs, "},{", "}_@TSPLIT_{");
                    % Split to get column elements
                    ds = split(rs, "_@TSPLIT_");
                    % Need to make sure the array has the correct
                    % dimensions
                    renderedData = reshape(ds, numRows, numCols);
                else
                    renderedData = cellstr("{""value"":""" + dataSubset + """}");
                end
            catch
            end
            
            renderedDims = size(renderedData);
        end

    end

    methods(Access='protected')
        function result = evaluateClientSetData(~, data, ~, ~)
            % In case of numerics, if the user types a single character in
            % single quotes, it is converted to its equivalent ascii value
            result = [];
            if (isequal(length(data), 3) && isequal(data(1),data(3),''''))
                result = double(data(2));
            end
        end

        function isValid = validateInput(this, value, ~, ~) %#ok<INUSL>
            % The only valid input types are 1x1 doubles
            % (~isempty(value) && ismissing(value)) isempty is for the ''
            % use case
            isValid = (isnumeric(value) || (~isempty(value) && ~ischar(value) && ismissing(value))) && size(value, 1) == 1 && size(value, 2) == 1;
        end

        function replacementValue = getEmptyValueReplacement(~, ~, ~) 
			replacementValue = 0;
        end
         
        % On DataModel Updates, update the scalingFactorString so that getRenderedData can fetch the correct data subset. 
        function handleDataChangedOnDataModel(this, es ,ed)
            this.updateScalingFactorString();
            this.setProperty('Slice', this.DataModel.Slice);
            this.setProperty('FullSize', size(this.DataModel.DataI));
            this.handleDataChangedOnDataModel@internal.matlab.variableeditor.peer.RemoteArrayViewModel(es, ed);
        end
        
        % Sets the scalingFactorString class property to the scaling
        % factor of the data. if setExponent is true, updates
        % RemoteProperty 'ScalingFactor' with exponent value.
        function updateScalingFactorString(this)
            fullData = this.DataModel.Data;
            if ~isempty(fullData)
                this.scalingFactorString = internal.matlab.variableeditor.peer.PeerDataUtils.getScalingFactor(fullData);  
                if ~isempty(this.scalingFactorString) && ~this.ShowMultipliedExponent
                    exponent = internal.matlab.variableeditor.peer.PeerDataUtils.getScalingFactorExponent(this.scalingFactorString);
                    this.setProperty('ScalingFactor', num2str(exponent));
                end
            else
                this.scalingFactorString = strings(0,0);
            end
        end

        % API that decides whether scaling factor should be multiplied in
        % or not. Currently this is multiplied only for LE usecases.
        function shouldShow = shouldShowMultipliedExponentValues(this, userContext)
            shouldShow = ~internal.matlab.variableeditor.peer.PeerUtils.isLiveEditor(userContext);
        end
        
        % Query for class and set dataAttributes based on
        % sparse/complex etc.
        function updateTableModelInformation(this)
            editable = true;
            % Turn off editability for embedded.fi numeric object types (g2215330)
            if isa(this.DataModel.Data, 'embedded.fi')
                editable = false;
            end
            % Make sure to take into account current property setting g2847601
            if this.hasTableModelProperty('editable')
                editable = editable && this.getTableModelProperty('editable');
            end
            dataClass = class(this.DataModel.Data);
            % g2374723: Ensure data is not a primitive numeric when
            % checking for objects using ishandle to catch false positives
            % due to open figures.
            if (isobject(this.DataModel.Data) || ...
                    ~internal.matlab.datatoolsservices.VariableUtils.isPrimitiveNumeric(this.DataModel.Data))
                dataClass = 'object';
            end
            this.setTableModelProperty('class', dataClass, false);
            this.setTableModelProperty('editable', editable, false);

            % This will take care of updating client side metadata.
            this.updateTableModelInformation@internal.matlab.variableeditor.peer.RemoteArrayViewModel();
        end
    end
end
