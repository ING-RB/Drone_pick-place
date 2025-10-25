classdef RemoteTimeTableSpannedViewModel < internal.matlab.variableeditor.peer.RemoteTableSpannedViewModel & ...
        internal.matlab.variableeditor.SpannedTimeTableViewModel
    %PeerTimeTableViewModel Peer TimeTable View Model (Inherits from
    %PeerTable as well as TimeTable views)

    % Copyright 2013-2024 The MathWorks, Inc.
    methods
        function this = RemoteTimeTableSpannedViewModel(document, variable, viewID, usercontext)
            arguments
                document
                variable
                viewID = ''
                usercontext = ''
            end
            this@internal.matlab.variableeditor.SpannedTimeTableViewModel(variable.DataModel, viewID);
            this = this@internal.matlab.variableeditor.peer.RemoteTableSpannedViewModel(document,variable, viewID, usercontext);                        
            this.setColumnModelProperty(1,'DataAttributes','TimeColumn', false);            
        end

        % TableModel Updates that happens during view creation. Disable
        % listeners as this state will be sync'ed once viewport is set.
         function initTableModelInformation (this)
            this.initTableModelInformation@internal.matlab.variableeditor.peer.RemoteTableViewModel();
            this.TableModelChangeListener.Enabled = false;
            this.setTableModelProperty(...
                'CornerSpacerTitle', this.EventLabelText);
            this.TableModelChangeListener.Enabled = true;
         end
        
        % Gets selection indices for the current view. From the current
        % selection, adjust column indices to account for time column.
        function s = getSelectionIndices(this)
            s = this.getSelectionIndices@internal.matlab.variableeditor.peer.RemoteTableSpannedViewModel;
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
    end  
    
    methods(Access='protected')
        function columnIndex = getColumnIndex(this, columnHeaderInfo)
            columnHeaderInfo.column = max(this.getStructValue(columnHeaderInfo,'column') -1, 0);
            columnIndex = this.getColumnIndex@internal.matlab.variableeditor.peer.RemoteTableViewModel(columnHeaderInfo);
        end
        
        % From the computed intervals, adjust selectedColumns such that setSelection will have the 
        % correct indices (incl time column) for a timetable view.
        function intervals = getRangeIntervals(this, rangeVal, dim)
            intervals = this.getRangeIntervals@internal.matlab.variableeditor.peer.RemoteTableSpannedViewModel(rangeVal, dim);
            if strcmp(dim, 'cols')
                intervals = intervals + 1;
            end
        end

        function rowNames = getRowNames(this, data)
            rowNames = this.getRowNames@internal.matlab.variableeditor.TimeTableViewModel();        
        end
    end
end
