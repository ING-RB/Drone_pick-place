classdef MLTimeTableDataModel < internal.matlab.variableeditor.MLArrayDataModel & internal.matlab.variableeditor.TimeTableDataModel & ...
        internal.matlab.variableeditor.MLTableDataModelBase
    %MLTimeTableDataModel
    %   MATLAB TimeTable Data Model

    % Copyright 2013-2024 The MathWorks, Inc.
    
    events
        MetaDataChanged;
        ColumnMetaDataChanged;
        RowMetaDataChanged;
    end

    methods(Access='public')
        % Constructor
        function this = MLTimeTableDataModel(name, workspace)
            this@internal.matlab.variableeditor.MLArrayDataModel(name, workspace);
        end
        % updateData
        function data = updateData(this, varargin)
            newData = varargin{1};
            currentData = this.getCloneData;
            data = newData;

             % There seems to be a bug in isequal for tables where type
            % changes in properties aren't flagged as differences. If
            % size is same, always check for type change as well.
            if isequal(size(currentData),size(newData))
                % If we know straightaway that currentData and newData are
                % same, return;
                if ~isequal(currentData,newData)
                    [I,J] = this.doCompare(newData);
                    if isempty(I) && isempty(J)
                        this.Data = newData;
                        return;
                    end
                end
                this.handleClassUpdate(currentData, newData);
                %handle the RowTime format change condition, g1610416
                %This is needed because changes to the RowTimes format aren't picked up by the isequal() check above.
                if isprop(currentData.Properties, 'RowTimes') && isprop(newData.Properties, 'RowTimes') && ...
                            ~strcmp(currentData.Properties.RowTimes.Format, newData.Properties.RowTimes.Format)
                    % Rowtime is part of the data, refresh first column.
                    this.Data = newData;
                    eventdata = internal.matlab.datatoolsservices.data.DataChangeEventData;
                    eventdata.StartColumn = 1;
                    eventdata.EndColumn = 1;
                    eventdata.StartRow = 1;
                    eventdata.EndRow = height(newData);
                    this.notify('DataChange',eventdata);
                end  
            end                
          
            % No type or property changes found so call the superclass
            % updateData method to send the actual data change
                        
            % Metadataupdates could have altered the dataModel. Pass in the
            % original data to superclass for data update comparisons.
            varargin{:,end+1} = currentData;
            data = this.updateData@internal.matlab.variableeditor.MLArrayDataModel(varargin{:});
        end
        
        % Define equalityCheck Condition for tables/timetables
        function eq = equalityCheck(this, oldData, newData)
           eq = this.equalityCheck@internal.matlab.variableeditor.MLTableDataModelBase(oldData, newData);
           if (eq)
               % Force an update by causing the equality check to fails
               % even if variables are equal
               eq = ~this.ForceUpdate;
            end
        end
    end %methods
    
    methods(Access='protected')
        
        % handleMetaDataUpdate is used to refresh metadata whenever data changes warrants a metadata change. 
        % params: newData: incoming new data after the update
        %         originalData: original data from DataModel before the workspace update. 
        %         sizeChanged: boolean flag to tell us whether size changed along with data.
        %         rowDiff & columnDiff: result of doCompare. 
        function handleMetaDataUpdate(this, newData, originalData, sizeChanged, rowDiff, columnDiff)
            this.handleMetaDataUpdate@internal.matlab.variableeditor.MLTableDataModelBase(newData, originalData, sizeChanged, rowDiff, columnDiff);
        end    
        
        % Row metadata changes when event labels have changed. No need to
        % compare RowTimes here, RowTimes are part of data and are compared
        % in updateData block.
        function hasChanged = hasRowMetaDataChanged(this, newData, origData)
            hasChanged = ~isequal(this.getTextEvents(newData), this.getTextEvents(origData));
        end
        
        function [I,J] = doCompare(this, newData)
            % table setdiff doesn't work for cell columns unless they're cellstrs
            c = varfun(@(var)(iscell(var)) || (isdatetime(var) && isempty(var.TimeZone)), this.Data, 'OutputFormat', 'cell');
            cNew = varfun(@(var)(iscell(var)) || (isdatetime(var) && isempty(var.TimeZone)), newData, 'OutputFormat', 'cell');

            % If we have cell columns OR if the table variable names have changed
            % don't bother trying to figure out the differences just assume everything changed
            colNameChanged = ~isempty(setdiff(this.Data.Properties.VariableNames, newData.Properties.VariableNames));
            
            if any([c{:}]) || any([cNew{:}]) || colNameChanged
                [I,J] = meshgrid(1:height(this.Data),1:width(this.Data)); 
            else
                try
                    [~, I] = setdiff(this.Data, newData);
                 catch
                    % if datatype has changed, setdiff could fail on
                    % individual columns, refresh the viewport.
                    [I, J] = meshgrid(1:height(this.Data),1:width(this.Data)); 
                    return;
                end
                if length(I) == 1
                    [~,J] = find(cellfun(@(a,b) ~isequal(a,b), table2cell(this.Data(I,:)), table2cell(newData(I,:))));
                    if length(J) > 1
                        [I,J] = meshgrid(I,J); 
                    end
                else
                    J = 1:width(this.Data);
                    [I,J] = meshgrid(I,J); 
                end
            end
        end
        
        
        % For timetables, viewmodel updates are done from the 'table' version. Adjust metadata indices.
        function [columnIndices, varNameIndices, classIndices, dateFormatIndices] = getColDiffIndices(this, origData, newData)
            [columnIndices, varNameIndices, classIndices, dateFormatIndices] = this.getColDiffIndices@internal.matlab.variableeditor.MLTableDataModelBase(origData, newData);  
            columnIndices = columnIndices + 1;
            varNameIndices = varNameIndices + 1;
            classIndices = classIndices + 1;
            dateFormatIndices = dateFormatIndices + 1;
        end       
       
        % For timetables, RowTimes is part of data, no need to publish
        % RowMetaDataChanged for change in RowTimes.
        function rowIndices = getRowDiffIndices(this, origData, newData)
            rowIndices = [];
        end
        
        % Adjust overall indices to be updated so that the full viewport is
        % refreshed for the new changed size.
        function columnIndices = getColFullIndices(this, newData)
            columnIndices = this.getColFullIndices@internal.matlab.variableeditor.MLTableDataModelBase(newData);  
            columnIndices(2) = columnIndices(2) + 1;
        end       
    end
end
