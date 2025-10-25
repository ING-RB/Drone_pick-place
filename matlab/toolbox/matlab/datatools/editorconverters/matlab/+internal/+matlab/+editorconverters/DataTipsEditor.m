classdef DataTipsEditor < ...
        internal.matlab.editorconverters.EditorConverter
    
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Copyright 2018-2014 The MathWorks, Inc.
    
    properties
        dataTipRows;
    end
    
    properties (Constant)
        LABEL = "Label";
        VALUE = "Value";
        FORMAT = "Format";
    end
    
    methods
        function setServerValue(this, value, ~, ~)
            this.dataTipRows = value;
        end
        
        function setClientValue(this, value)
            this.dataTipRows = value;
        end
        
        function value = getServerValue(this)
            value = this.dataTipRows;
        end
        
        function value = getClientValue(this)
            % Loop through the data tip descriptors and build a data
            % structure that is sent to the server for the display in the
            % cell editor
            tipDescriptors = this.getDescriptors();
            dataTipValues = cell(1,numel(tipDescriptors));
            if ~isempty(tipDescriptors)
                for i = 1:numel(tipDescriptors)
                    tipValue = tipDescriptors(i).Value;
                    % We need to populate the "format" dropdown list based
                    % on type of the tip descriptor value. Numeric format
                    % has values like usd, jpy, auto etc. 
                    formattedValue = tipValue;
                    format = 'auto';
                    if ~isempty(this.dataTipRows) && numel(this.dataTipRows) >= i
                        formattedValue = this.formatValues(this.dataTipRows(i).Value);
                        format = this.dataTipRows(i).Format;
                    end
                    
                    % We need to display the correct numeric values like [2.2 3.3] 
                    % in the cell editor as it is, so we convert it to
                    % numeric using mat2str first. For all other type of
                    % tipValue, simple string conversion should suffice
                    % g2108033
                    if isnumeric(tipValue)
                        tipValue = mat2str(tipValue);
                    end
                    
                    dataTipValues{i} = internal.matlab.legacyvariableeditor.peer.PeerUtils.toJSON(...
                        true, ...
                        struct( ...
                        'label',tipDescriptors(i).Name,...
                        'value', string(tipValue), ...
                        'format',format,...
                        'formattedValue',formattedValue,...
                        'rowNumber',i));
                end
            end
            value = dataTipValues;
        end
        
        function props = getEditorState(this)
            props = struct;
            props.fields = [this.LABEL, this.VALUE, this.FORMAT];
            props.numElements = 3;
            props.editable = true;
            props.isMetaData = true;
            props.DnDSupported = false;
        end
        
        function setEditorState(~, ~)
        end
        
        function formattedValue = formatValues(~, rowValue)
            formattedValue = rowValue;
            if iscell(rowValue) && length(rowValue) <= 1
                if isempty(rowValue)
                    formattedValue = '';
                else
                    formattedValue = rowValue{1};
                end
            elseif isa(rowValue, 'function_handle')
                % Function handle should be displayed properly g1884449
                formattedValue = func2str(rowValue);
            elseif ~ischar(rowValue) && ~isstring(rowValue)
                fdu = internal.matlab.datatoolsservices.FormatDataUtils;
                formattedValue = fdu.formatSingleDataForMixedView(rowValue);
            end
        end
    end
    methods (Hidden)
        function desc = getDescriptors(~)
            desc = matlab.graphics.datatip.internal.DataTipRowHelper.getCurrentTipDescriptors();
        end
    end
end