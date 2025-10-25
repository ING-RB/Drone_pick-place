classdef TimeTableViewModel < internal.matlab.variableeditor.TableViewModel
    %TimeTableViewModel
    %   TimeTable View Model

    % Copyright 2013-2025 The MathWorks, Inc.

    properties (Access='protected')
        EventLabels
        EventLabelText (1,1) string = ""
    end
    
    % Public Abstract Methods
    methods(Access='public')
        % Constructor
        function this = TimeTableViewModel(dataModel, viewID, userContext)
            arguments
                dataModel
                viewID = ''
                userContext = ''
            end
            this@internal.matlab.variableeditor.TableViewModel(dataModel, viewID, userContext);
            timeTableData = dataModel.getCloneData;
            if (internal.matlab.variableeditor.TimeTableViewModel.hasEvents(timeTableData))
                eventTable = timeTableData.Properties.Events;
                eventLabelsVarName = eventTable.Properties.EventLabelsVariable;
                if ~isempty(eventLabelsVarName)
                    this.EventLabelText = eventLabelsVarName;
                end
            end
        end
        
        % Overrides getDisplaySize from ViewModel
        % For timetables, return the size of the cloneData as that contains
        % the TimeTable data.
        function displaySize = getDisplaySize(this)
            displaySize = internal.matlab.datatoolsservices.FormatDataUtils.dimensionString(this.DataModel.getCloneData);
        end

        function formattedString = getFormattedSelectionStringHelper(this, selectedRows, selectedColumns, ...
                 dataModelName, data)
            sz = this.getSize();

            uci = [];
            for i=1:height(selectedColumns)
                uci = [uci, selectedColumns(i,1):selectedColumns(i,2)];
            end
            nonPrintingHeaders = cellfun(@(c)~isvarname(c), data.Properties.VariableNames(uci));
            origVarNames = data.Properties.VariableNames;
            if any(nonPrintingHeaders)
                nphi = 0;
                for i=1:length(uci)
                    if nonPrintingHeaders(i)
                        nphi = nphi + 1;
                        newVarName = "VE_TEMP_VAR_NAME_" + nphi;
                        data.Properties.VariableNames(uci(i)) = newVarName;
                    end
                end
            end

            formattedString = internal.matlab.variableeditor.TableViewModel.getFormattedSelectionString(selectedRows, ...
                selectedColumns, dataModelName, data, sz, min(sz(2), this.SelectedColumnIntervals), this.GroupedColumnCounts);

            if any(nonPrintingHeaders)
                nphi = 0;
                for i=1:length(uci)
                    if nonPrintingHeaders(i)
                        nphi = nphi + 1;
                        newVarName = "VE_TEMP_VAR_NAME_" + nphi;
                        index = uci(i) - 1;
                        if index == 0
                            formattedString = strrep(formattedString, newVarName, "Properties.RowTimes");
                        else
                            formattedString = strrep(formattedString, newVarName, "(" + index + ")");
                        end
                        data.Properties.VariableNames(uci(i)) = origVarNames(uci(i));
                    end
                end
            end
        end
    end

    methods(Access=protected)

        function populateEventLabels (this)
            this.EventLabels = this.DataModel.getTextEvents(); 
        end     

        function etLabels = getEventTimestamps(this)
            if isempty(this.EventLabels)
                this.populateEventLabels();
            end
            etLabels = this.EventLabels;          
        end

        function handleRowMetaDataChangedOnDataModel(this, ed)
            this.populateEventLabels();
            this.handleRowMetaDataChangedOnDataModel@internal.matlab.variableeditor.TableViewModel(ed);
        end

        % NOTE: RowTimes are part of data and not row labels, return row
        % labels only if events are attached to timetables
        function rowNames = getRowNames(this, data)
            if internal.matlab.variableeditor.TimeTableViewModel.hasEvents(this.DataModel.getCloneData)
                rowNames = this.getEventTimestamps();
            else
                rowNames = {};
            end        
        end
    end

    methods(Static)
        function support = hasEvents(tt)
            props = tt.Properties;
            support = isprop(props, 'Events') && ~isempty(props.Events);
        end
    end
end
