
classdef PeerCharArrayViewModel < ...
        internal.matlab.legacyvariableeditor.peer.PeerArrayViewModel & ...
        internal.matlab.legacyvariableeditor.CharArrayViewModel
    % PeerCharArrayViewModel Peer Model View Model for char array
    % variables
    
    % Copyright 2014-2018 The MathWorks, Inc.

    methods
        function this = PeerCharArrayViewModel(parentNode, variable)
            this = this@internal.matlab.legacyvariableeditor.peer.PeerArrayViewModel(parentNode, variable);            
            this@internal.matlab.legacyvariableeditor.CharArrayViewModel(variable.DataModel);           

            % Build the ArrayEditorHandler for the new Document
            import com.mathworks.datatools.variableeditor.web.*;
            this.PagedDataHandler = ArrayEditorHandler(variable.Name,this.PeerNode.Peer,this,this.getRenderedData(1,1,1,1));

            % Set the renderer types on the table
            widgetRegistryInstance = internal.matlab.datatoolsservices.WidgetRegistry.getInstance();
            widgets = widgetRegistryInstance(1).getWidgets('', 'char');
            this.setTableModelProperties(...
                'renderer', widgets.CellRenderer,...
                'editor', widgets.Editor,...
                'inplaceeditor', widgets.InPlaceEditor,...
                'ShowColumnHeaderLabels', false,...
                'ShowRowHeaderLabels', false,...
                'RemoveQuotedStrings',false);
        end
    end
    
    methods(Access='public')
        % getRenderedData
        % returns a cell array of strings for the desired range of values
        function [renderedData, renderedDims] = getRenderedData(this,startRow,endRow,startColumn,endColumn)
            % dataSize denotes the actual char array size where each
			% character occupies one column.
			% Eg: s = 'hello_world'
			% dataSize = [1 11]
            dataSize = this.DataModel.getSize();
            data = this.getRenderedData@internal.matlab.legacyvariableeditor.CharArrayViewModel(startRow,dataSize(1),startColumn,dataSize(2));
            this.setCurrentPage(1,1,1, 1, false);

			if isempty(data)
				data = '';
            end
            isMetaData = dataSize(2) > internal.matlab.datatoolsservices.FormatDataUtils.MAX_TEXT_DISPLAY_LENGTH;
			jsonData = internal.matlab.legacyvariableeditor.peer.PeerUtils.toJSON(true, ...
                struct('class', 'char', ...
                'value', data,...
                'editValue', data, ...
                'isMetaData', isMetaData, ...
                'row', '0', ...
                'col', '0'));
            renderedData{1,1} = jsonData;

            renderedDims = size(renderedData);
        end
        
		% overidden method
		% handles data changes when the user edits the cell
		% char arrays handle a special 0x0 array view when data is empty
        function varargout = handleClientSetData(this, varargin)
            % Handles setData from the client and calls MCOS setData.  Also
            % fires a dataChangeStatus peerEvent.
            data = '';
            if ~isempty(varargin{1})
                data = this.getStructValue(varargin{1}, 'data');
            end
            
            try
                if isequal(data, '''') || isequal(data, '"')
                    dispValue = '';
                else
                    data = strrep(data,'''','''''');
                    if ~isempty(data)
                        % The user is not expected to explicitly type
                        % quotes while entering char data in the VE
                        data = ['''' data ''''];
                        this.logDebug('PeerArrayView','handleClientSetData','','row',1,'column',1,'data',data);
                        dispValue = this.getStructValue(varargin{1}, 'data');
                    else
                        % when data is empty, the web worker(in java) needs
                        % to translate it as valid empty data. The
                        % dispValue and data thus need to be padded with
                        % additional quotes. resultant dispValue = ''''
                        dispValue = '''''''''';
                        
                        % resultant data = ''
                        data = '''''';
                    end
                end
                currentValue = this.getData(1, 1, 1, this.getStructValue(varargin{1}, 'column'));
                
                if isequaln(dispValue, currentValue)
                    this.sendPeerEvent('dataChangeStatus','status', 'noChange', 'dispValue', dispValue, 'row', 0, 'column', 0);
                else
                    this.sendPeerEvent('dataChangeStatus','status', 'success', 'dispValue', dispValue, 'row', 0, 'column', 0);
                end
                
                varargout{1} = this.executeCommandInWorkspace(data, 0, 0);
            catch e
                % Send data change event.
                this.sendPeerEvent('dataChangeStatus', 'status', 'error', 'message', e.message, 'row', 0, 'column', 0);
                varargout{1} = '';
            end
        end
    end
end
