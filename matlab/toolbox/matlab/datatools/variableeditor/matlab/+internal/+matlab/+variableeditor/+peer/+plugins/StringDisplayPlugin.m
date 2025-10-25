
classdef StringDisplayPlugin < internal.matlab.variableeditor.peer.plugins.ServerConnectedPlugin
    % Server side plugin class that takes in a ViewModel.
    % This plugin fetches a string display for the requested range and dispatches
    % a server event with this data.

    % Copyright 2019-2024 The MathWorks, Inc.
    methods
        function handled = handleEventFromClient(this, ed)
            this.ViewModel.logDebug('StringDisplayPlugin','handleEventFromClient','');
            handled = false;
            if isfield(ed, 'data') && isfield(ed.data,'type')
                if strcmp(ed.data.type, 'getStringData')
                    this.handleClientGetStringData(ed.data);
                    handled = true;
                end
            end
        end

        function data = handleClientGetStringData(this, varargin)
            % Converts client getData request to MCOS getData call
            % if rows less than 10 then show all
            startRow =  this.ViewModel.getStructValue(varargin{1}, 'startRow') + 1;
            endRow = min(this.ViewModel.getStructValue(varargin{1}, 'endRow') + 1, size(this.ViewModel.DataModel.Data,1));
            startColumn = min(this.ViewModel.getStructValue(varargin{1}, 'startColumn') + 1, size(this.ViewModel.DataModel.Data,2));
            endColumn = size(this.ViewModel.DataModel.Data,2);
            rowFetchLimit =  this.ViewModel.getStructValue(varargin{1}, 'rowFetchLimit'); % This is already 1 indexed

            % adjust rows
            if size(this.ViewModel.DataModel.Data,1) > rowFetchLimit
                startRow = endRow - (rowFetchLimit - 1);
            end
            currentNumFormat = this.ViewModel.DisplayFormatProvider.NumDisplayFormat;
            data = this.getDataForStringDisplay(startRow, endRow, startColumn, endColumn);
            scalingFactor = strings(0,0);
            if isprop(this.ViewModel, 'scalingFactorString')
                scalingFactor = this.ViewModel.scalingFactorString;
            end
            stringData = internal.matlab.variableeditor.peer.PeerDataUtils.getStringData(this.getDataForStringDisplay(), data, endRow-startRow+1, size(this.ViewModel.DataModel.Data,2)-startColumn+1, ...
                scalingFactor, currentNumFormat);

            % Dispatch a server event with the data
            this.ViewModel.dispatchEventToClient(struct('type', 'setStringData', ...
                'source', 'server', ...
                'startRow', startRow-1, ...
                'endRow', endRow-1, ...
                'startColumn', startColumn-1, ...
                'endColumn', endColumn-1, ...
                'data', stringData ));
        end

        % wrapper around getData. Required since getData for tables returns a cell array instead of table.
        % Wrapper function returns data in the form of table
        function value = getDataForStringDisplay(this, varargin)
            value = this.ViewModel.DataModel.getData(varargin{:});
        end
    end
end
