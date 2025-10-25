classdef NumericArrayViewModel < internal.matlab.variableeditor.ArrayViewModel
    %NUMERICARRAYVIEWMODEL
    %   Numeric Array View Model

    % Copyright 2013-2023 The MathWorks, Inc.

    properties (SetAccess='protected', Transient)
        TableMetaDataChangedListener;
    end
    % Public Abstract Methods
    methods(Access='public')
        % Constructor
        function this = NumericArrayViewModel(dataModel, viewID, userContext)
            if nargin < 3
                userContext = '';
                if nargin < 2
                    viewID = '';
                end
            end            
            this@internal.matlab.variableeditor.ArrayViewModel(dataModel, viewID, userContext);
            this.initListeners();
        end
        
        function displaySize = getDisplaySize(this)
            import internal.matlab.datatoolsservices.FormatDataUtils;
            data = this.DataModel.DataI;            
            displaySize = FormatDataUtils.formatSize(data, false);
        end

        function [renderedData, renderedDims] = getDisplayData(this, startRow, endRow, startColumn, endColumn, numberFormat)
            arguments
                this
                startRow double
                endRow double
                startColumn double
                endColumn double
                numberFormat = this.DisplayFormatProvider.NumDisplayFormat
            end
            fullData = this.DataModel.Data;
            data = this.getData(startRow,endRow,startColumn,endColumn);
            scalingFactor = strings(0,0);                    
            if ~isempty(fullData)
                scalingFactor = internal.matlab.variableeditor.peer.PeerDataUtils.getScalingFactor(fullData);
            end            
            [renderedData, renderedDims] = internal.matlab.variableeditor.peer.PeerDataUtils.getFormattedNumericData(fullData, data, scalingFactor, numberFormat, true);
        end
    
        % getRenderedData
        % returns a cell array of strings for the desired range of values
        function [renderedData, renderedDims] = getRenderedData(this,startRow, endRow, startColumn, endColumn)
            [renderedData, renderedDims] = this.getDisplayData(startRow, endRow, startColumn, endColumn);
        end

        % Cleanup any listeners that were attached at constructor time
        function delete(this)
            if ~isempty(this.TableMetaDataChangedListener)
                delete(this.TableMetaDataChangedListener);
                this.TableMetaDataChangedListener = [];
            end          
        end
    end
    
    methods(Access='protected')
        % When numeric changes from numeric type to object numeric (like
        % embedded.fi), we need to update tableMetaData on the view.
        function initListeners(this)
            this.TableMetaDataChangedListener = event.listener(this.DataModel,'TableMetaDataChanged',@(es,ed) this.notify('TableMetaDataChanged', ed));
        end
    end
end
