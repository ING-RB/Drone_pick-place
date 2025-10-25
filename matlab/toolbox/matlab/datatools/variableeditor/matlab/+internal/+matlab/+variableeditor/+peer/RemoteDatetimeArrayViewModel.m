classdef RemoteDatetimeArrayViewModel < internal.matlab.variableeditor.peer.RemoteArrayViewModel & ...
        internal.matlab.variableeditor.DatetimeArrayViewModel
    
    % REMOTEDATETIMEARRAYVIEWMODEL Remote Model Datetime Array View Model

    % Copyright 2015-2025 The MathWorks, Inc.

    methods
        function this = RemoteDatetimeArrayViewModel(document, variable, viewID, userContext)
            if nargin < 4
                userContext = '';
                if nargin < 3
                    viewID = '';
                end
            end
            this@internal.matlab.variableeditor.DatetimeArrayViewModel(variable.DataModel, viewID, userContext);
            this = this@internal.matlab.variableeditor.peer.RemoteArrayViewModel(document,variable,'viewID',viewID);
        end
        
        function initTableModelInformation (this)
            this.setTableModelProperties(...
                'EditorConverter', 'datetimeConverter',...
                'class','datetime');
        end       
   
        % getRenderedData
        % returns a cell array of strings for the desired range of values
        function [renderedData, renderedDims] = getRenderedData(this,startRow,endRow,startColumn,endColumn)
            [renderedData, renderedDims] = this.getRenderedData@internal.matlab.variableeditor.DatetimeArrayViewModel(startRow,endRow,startColumn,endColumn);            
        end   
    end

    methods(Access='protected')

        % Replaces data with empty value replacement or formats incoming
        % data such that we can eval the data to be set for the row/column
        % in the correct workspace.
        function [data, origValue, evalResult, isStr] = processIncomingDataSet(this, row, column, data)
            origValue = this.getData(row, row, column, column);
            isStr = false;
            if ~isempty(data)
                % Pad user entered value with quotes
                data = ['"' data '"'];
            end
            evalResult = [];
        end

        function isValid = validateInput(this,value,row,column)
            % Since the client is sending characters we need to try to
            % convert them to a valid datetime object. This requires
            % getting a copy of the actual datetime data and trying an
            % assignment of the form data(row, column) = value. If the
            % result is a datetime, then the value is valid. If an
            % exception occurs, throw a datetime specific error instead of
            % the error sent from handleClientSetData. (g1239590)
            if isStringScalar(value)
                try
                    dt = this.getData();
                    dt(row, column) = value;
                    isValid = isdatetime(dt);
                catch
                    error(message('MATLAB:datetime:InvalidFromVE'));
                end
            else
                isValid = false;
            end
        end
        
        function replacementValue = getEmptyValueReplacement(~,~,~)
            % Empty values should be replaced with NaT.
            replacementValue = datetime('NaT');
        end

        function changed = didValuesChange(~, newValue, oldValue, ~, ~)
            arguments
                ~
                newValue % Any type
                oldValue % Any type
                ~
                ~
            end

            changed = true;
            newValueDatetime = isdatetime(newValue);
            oldValueDatetime = isdatetime(oldValue);

            % We have to explicitly check if the new and old values are NaTs; there is no other reliable
            % method to do so unless we use hacky warning suppression workarounds so users don't get warnings
            % in their Command Window.
            bothAreNaTs = (newValueDatetime && oldValueDatetime) && (isnat(newValue) && isnat(oldValue));
            if bothAreNaTs
                changed = false;
                return
            end

            if newValueDatetime || oldValueDatetime
                % If at least one datetime value is involved, we must do a bit of additional work
                % to detect data changes.
                try
                    changed = newValue ~= oldValue;
                catch e
                    % Equality checks between datetime and string/char values can easily result in errors.
                    % If we encounter an error about being unable to convert a text value to datetime due to
                    % an unrecognized format, we simply note that the value has changed.
                    if strcmp(e.identifier, 'MATLAB:datetime:AutoConvertString')
                        changed = true;
                    else
                        internal.matlab.datatoolsservices.logDebug("variableeditor::RemoteDatetimeArrayViewModel::didValuesChange::error", e.message);
                    end
                end
            else
                % Otherwise, we can rely on our base class's implementation of this function.
                changed = didValuesChange@internal.matlab.variableeditor.peer.RemoteArrayViewModel(newValue, oldValue);
            end
        end
    end   
end
