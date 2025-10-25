classdef MLDatasetDataModel < internal.matlab.variableeditor.MLArrayDataModel & internal.matlab.variableeditor.DatasetDataModel & ...
        internal.matlab.variableeditor.MLTableDataModelBase
    %MLDatasetDATAMODEL
    %   MATLAB Cell Array Data Model

    % Copyright 2022-2024 The MathWorks, Inc.
    
    events
        MetaDataChanged;
        ColumnMetaDataChanged;
        RowMetaDataChanged;
    end

    methods(Access='public')
        % Constructor
        function this = MLDatasetDataModel(name, workspace)
            this@internal.matlab.variableeditor.MLArrayDataModel(name, workspace);
        end

        % updateData
        function data = updateData(this, varargin)
            newData = varargin{1};
            currentData = this.getCloneData;           
            data = newData;
            % If this is a scalar table, there could possibly be a dataChange, we need to
            % update data/metadata and not perform isequal checks as union
            % between certain types could fail on setdiff/isequal checks.     
            if isscalar(currentData) && isscalar(newData)
                this.Data = newData;
                % Update metadata
                metaDataEvent = internal.matlab.datatoolsservices.data.ModelChangeEventData;
                metaDataEvent.Column = 1;
                this.notify('ColumnMetaDataChanged', metaDataEvent);

                % Update data
                eventdata = internal.matlab.datatoolsservices.data.DataChangeEventData;
                eventdata.StartRow = 1;
                eventdata.StartColumn = 1;
                eventdata.EndRow = 1;
                eventdata.EndColumn = 1;
                this.notify('DataChange',eventdata);
                return;
            end

            % There seems to be a bug in isequal for tables where type
            % changes in properties aren't flagged as differences. If
            % size is same, always check for type change as well.

            if isequal(size(currentData),size(newData))
                % Do not shortcircuit on doCompare here, setdiff does not
                % detect sorted order
                this.handleClassUpdate(currentData, newData);
            end

            % No type or property changes found so call the superclass
            % updateData method to send the actual data change

            % Metadataupdates could have altered the dataModel. Pass in the
            % original data to superclass for data update comparisons.
            varargin{:,end+1} = currentData;
            data = this.updateData@internal.matlab.variableeditor.MLArrayDataModel(varargin{:});
        end      
        
        
        % Define equalityCheck Condition for tables/timetables doCompare if equal as 
        % isequal check is not accurate for these types.
        function eq = equalityCheck(this, oldData, newData)
           eq = this.equalityCheck@internal.matlab.variableeditor.MLTableDataModelBase(oldData, newData);
           if eq
               [I,J] = this.doCompare(newData);
                % Force an update by causing the equality check to fails 
                % even if variables are equal
               eq = isempty(I) && isempty(J) && ~this.ForceUpdate;
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

        function hasChanged = hasRowMetaDataChanged(~, newData, origData)
            hasChanged = ~isequal(newData.Properties.ObsNames, origData.Properties.ObsNames);
        end

        function [columnIndices, varNameIndices, classIndices, dateFormatIndices] = getColDiffIndices(~, origData, newData)
            [~, varNameIndices] = (setdiff(origData.Properties.VarNames, newData.Properties.VarNames));
            compareByOrder = cellfun(@isequal, origData.Properties.VarNames, newData.Properties.VarNames);
            varNameOrder = find(~compareByOrder);
            classIndices = find(~strcmp(datasetfun(@(c)class(c), origData, "UniformOutput",false), datasetfun(@(c)class(c), newData, "UniformOutput",false)));
            dateFormatIndices = [];
            dtItems = find(datasetfun(@(c)isa(c, "datetime"), origData, "UniformOutput", true));
            for i=1:length(dtItems)
                varName = origData.Properties.VarNames{dtItems(i)};
                if contains(newData.Properties.VarNames, varName)
                    currentFormat   = origData.(varName).Format;
                    currentTimeZone = origData.(varName).TimeZone;
                    newFormat       = newData.(varName).Format;
                    newTimeZone     = newData.(varName).TimeZone;
                    if ~strcmp(currentFormat, newFormat) || ~strcmp(currentTimeZone, newTimeZone)
                        dateFormatIndices(end+1) = dtItems(i); %#ok<AGROW>
                    end
                end
            end
            columnIndices = union(union(union(varNameIndices, classIndices), dateFormatIndices), varNameOrder);
        end

        function rowIndices = getRowDiffIndices(~, origData, newData)
            [~, rowIndices] = (setdiff(origData.Properties.ObsNames, newData.Properties.ObsNames));
        end
        
        function [I,J] = doCompare(this, newData)
            % table setdiff doesn't work for cell columns unless they're cellstrs
            cNew = datasetfun(@(var)(iscell(var)) || (isdatetime(var) && isempty(var.TimeZone)), newData,  'UniformOutput', false);
            c = datasetfun(@(var)(iscell(var)) || (isdatetime(var) && isempty(var.TimeZone)), this.Data, 'UniformOutput', false);

            % If we have cell columns, don't bother trying to figure out the differences just assume everything changed
            % ShortCircuit if colNameChanged, this will be handled in
            % handleMetaDataUpdate.
            colNameChanged = ~isempty(setdiff(this.Data.Properties.VarNames, newData.Properties.VarNames));
            
            if any([c{:}]) || any([cNew{:}]) || colNameChanged
                [I,J] = meshgrid(1:height(this.Data),1:width(this.Data)); 
            else
                try
                    % setdiff only returns rows A not in B, this will fail
                    % for same tables with different sort order.
                    [~, I] = setdiff(this.Data, newData);                   
                catch
                    % if datatype has changed, setdiff could fail on
                    % individual columns, refresh the viewport.
                    [I, J] = meshgrid(1:height(this.Data),1:width(this.Data)); 
                    return;
                end
                if isscalar(I) 
                    % If this was a single cell edit, but either of the
                    % views had missing, make I a vector to force update
                    % the viewport(This could be the result of a sort where
                    % missing values are relocated)
                    if anymissing(newData) || anymissing(this.Data)
                        I = [I I];
                    end

                    %Extracting 
                    cellData = dataset2cell(this.Data(I,:));
                    if ~isempty(this.Data.Properties.ObsNames)
                        cellData = cellData(:,2:end);
                    end
                    if ~isempty(this.Data.Properties.VarNames)
                        cellData = cellData(2:end, :);
                    end
                    
                    cellnewData = dataset2cell(newData(I,:));
                    if ~isempty(newData.Properties.ObsNames)
                        cellnewData = cellnewData(:,2:end);
                    end
                    if ~isempty(newData.Properties.VarNames)
                        cellnewData = cellnewData(2:end, :);
                    end
                    [~,J] = find(cellfun(@(a,b) ~isequal(a,b),cellData, cellnewData));
                    if length(J) > 1
                        [I,J] = meshgrid(I,J); 
                    end
                else
                    J = 1:width(this.Data);
                    [I,J] = meshgrid(I,J); 
                end
            end
        end  
    end
end
