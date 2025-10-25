classdef RemoteTimeTableViewModel < internal.matlab.variableeditor.peer.RemoteTableViewModel & ...
        internal.matlab.variableeditor.TimeTableViewModel
    %PeerTimeTableViewModel Peer TimeTable View Model (Inherits from
    %PeerTable as well as TimeTable views)

    % Copyright 2013-2025 The MathWorks, Inc.

    methods
        function this = RemoteTimeTableViewModel(document, variable, viewID, usercontext)
            arguments
                document
                variable
                viewID = ''
                usercontext = ''
            end
            this@internal.matlab.variableeditor.TimeTableViewModel(variable.DataModel, viewID);
            this = this@internal.matlab.variableeditor.peer.RemoteTableViewModel(document,variable, viewID, usercontext);   
            this.setColumnModelProperty(1,'DataAttributes','TimeColumn', false);            
        end

        function viewProps = getViewProperties(this, adapter, nameValueProps)
            viewProps = this.getViewProperties@internal.matlab.variableeditor.peer.RemoteArrayViewModel(adapter, nameValueProps);
            if ~isempty(this.EventLabelText)
                % This is currently set as a viewmodelprop so that it can
                % exist at plugin creation time
                viewProps.CornerSpacerTitle = this.EventLabelText;
            end
        end

        % Gets selection indices for the current view. From the current
        % selection, adjust column indices to account for time column.
        function s = getSelectionIndices(this)
            s = this.getSelectionIndices@internal.matlab.variableeditor.peer.RemoteTableViewModel;
            if ~isempty(s{2})
                cols = s{2} - 1;
                % If time column is discontiguous, remove it entirely from
                % range
                if (all(cols(1,:)==[0 0]))
                    cols = cols(2:end,:); 
                end
                s{2} = max(cols, 1);
            end
        end

        % Handles remote events from client. On SummaryStatusClicked,
        % Display the underlying eventable.
        function handleEventFromClient(this, eventSource, event)
            this.handleEventFromClient@internal.matlab.variableeditor.peer.RemoteTableViewModel(eventSource, event);

            % NOTE: This event will only be dispatched for timetables with events attached.
            if strcmp(event.data.type, 'SummaryStatusClicked')
                % Open events table when summarystatus with event information is clicked.
                openvarcmd = "openvar(""%s.Properties.Events"");";
                cmd = sprintf(openvarcmd, this.DataModel.Name);
                internal.matlab.variableeditor.Actions.ActionUtils.executeCommand(cmd);
            end
        end

        function assignmentString = generateVariableNameAssignmentStringHelper(this, ~, subs, vname, tname)
            arguments
                this
                ~ % rawData
                subs
                vname
                tname
            end

            assignmentString = matlab.internal.tabular.generateVariableNameAssignmentString(this.DataModel.Data_I, subs, vname, tname);
        end
    end  

    methods(Access='protected')
        function columnIndex = getColumnIndex(this, columnHeaderInfo)
            columnHeaderInfo.column = max(this.getStructValue(columnHeaderInfo,'column') -1, 0);
            columnIndex = this.getColumnIndex@internal.matlab.variableeditor.peer.RemoteTableViewModel(columnHeaderInfo);
        end
        
        % From the computed intervals, adjust selectedColumns such that setSelection will have the 
        % correct indices (incl time column) for a timetable view.
        function intervals = getRangeIntervals(this, rangeVal, dim)
            intervals = this.getRangeIntervals@internal.matlab.variableeditor.peer.RemoteTableViewModel(rangeVal, dim);
            if strcmp(dim, 'cols')
                intervals = intervals + 1;
            end
        end

        function rowNames = getRowNames(this, ~)
            arguments
                this
                ~ % data
            end

            rowNames = this.getRowNames@internal.matlab.variableeditor.TimeTableViewModel();        
        end

         function updateRowModelInformation(this, startRow, endRow, fullRows)
            arguments
                this (1,1) internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore
                startRow (1,1) double {mustBeNonnegative}
                endRow (1,1) double {mustBeNonnegative}
                fullRows (1,:) double = startRow:endRow
            end
            this.updateRowModelInformation@internal.matlab.variableeditor.peer.RemoteTableViewModel(startRow, endRow, fullRows);
            % Update CornerSpacerTitle
            cornerSpacerTitle = [];
            tt = this.DataModel.getCloneData;
            if (internal.matlab.variableeditor.TimeTableViewModel.hasEvents(tt))
                eventTable = tt.Properties.Events;
                cornerSpacerTitle = eventTable.Properties.EventLabelsVariable;
            end
            currentVal = this.getTableModelProperty('CornerSpacerTitle');
            if ~isequal(currentVal, cornerSpacerTitle)
                if isempty(cornerSpacerTitle)
                    cornerSpacerTitle = '';
                end
                this.EventLabelText = cornerSpacerTitle;
                this.setTableModelProperty('CornerSpacerTitle', this.EventLabelText);
            end
         end
    end
end
