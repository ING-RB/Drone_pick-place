classdef MLTableDataModelBase < handle
    %MLTABLEDATAMODELBASE 
    % Base class for MLTableDataModel and MLTimeTableDataModel
    % This class is used to compare and notify on dataChanged and
    % metaDataChanged for table types.
    
    % Copyright 2019-2024 The MathWorks, Inc.
    
    methods(Access='public')        
        % The base class(MLArrayDataModel) does a isequaln check that fails for certain types. 
        function eq = equalityCheck(this, oldData, newData)
            if istall(newData) || istall(oldData)
                eq = internal.matlab.variableeditor.areVariablesEqual(oldData, newData);
            else
                % This is to guard against datatype (datetime) check
                % warnings g3466810 we already have our own datatype checks
                % in our meta data updates that check for individual
                % variables changing types
                w = warning("off");
                revertWarning = onCleanup(@() warning(w));
                eq = isequal(oldData, newData);
                warning(w);
            end
        end

        function handleRowMetaDataUpdate(this, newData)           
            metaDataEvent = internal.matlab.datatoolsservices.data.ModelChangeEventData;
            metaDataEvent.Row = [min(1, height(newData)), height(newData)];
            this.notify('RowMetaDataChanged', metaDataEvent);           
        end
    end
    
    methods (Access='protected')
        
        function handleClassUpdate(this, currentData, newData)
            [~, ~, classIndices, dateFormatIndices] = this.getColDiffIndices(currentData, newData);
            % Check for datatype differences only when columnnames are
            % same.
             % Return if a type change was found
            if ~isempty(classIndices) || ~isempty(dateFormatIndices)
                % Force a data update because the data itself may
                % have changed if it's type has changed
                this.Data = newData;
                eventdata = internal.matlab.datatoolsservices.data.DataChangeEventData;
                eventdata.EventSource = 'InternalDmUpdate';
                this.notify('DataChange',eventdata);
                return;
            end         
        end
       
        % On metadata differences, check to see if VariableNames or
        % rowNames have changed and notify [type]MetadataChanged on DataModel. 
        function handleMetaDataUpdate(this, newData, origData, sizeChanged, ~, ~)
            rowsChanged = false;
            colsChanged = false;
            rowMetaDataEvent = internal.matlab.datatoolsservices.data.ModelChangeEventData;
            colMetaDataEvent = internal.matlab.datatoolsservices.data.ModelChangeEventData;
            if sizeChanged
                % On sizechanged, data could have possibly changed. Blow up entire metadata
                if ~isequal(height(newData), height(origData))
                    rowsChanged = true;
                    rowMetaDataEvent.Row = this.getRowFullIndices(newData);
                    internal.matlab.datatoolsservices.logDebug('variableeditor::MLTableDataModelBase::handleMetaDataUpdate:',"Rows Changed on Size Change");
                end
                if ~isequal(width(newData), width(origData))
                    colsChanged = true;                    
                    % Do not set column indices to size(newData) as size will be re-computed on the view. Set to [] and
                    % TableviewModel will compute column indices to be updated (handleColumnMetaDataChangedOnDataModel)
                    colMetaDataEvent.Column = [];
                    internal.matlab.datatoolsservices.logDebug('variableeditor::MLTableDataModelBase::handleMetaDataUpdate:',"Columns Changed on Size Change");
                end
            end

            % If we detected a col changed with sizechanged, no need to update further.
            if ~colsChanged
                % 1. For column name changes, just detect the actual changes. 
                % Data change can also affect ColumnMetaData, renderer per
                % column changes. detect any data chnages as well
                colDiffIndices = this.getColDiffIndices(origData, newData);
                internal.matlab.datatoolsservices.logDebug('variableeditor::MLTableDataModelBase::handleMetaDataUpdate',mat2str(colDiffIndices));
                if ~isempty(colDiffIndices)                   
                    colMetaDataEvent.Column = colDiffIndices;
                    colsChanged = true;
                end
            end
            % If we detected a row changed with sizechanged, no need to update further.
            if ~rowsChanged
                rowDiffIndices = this.getRowDiffIndices(origData, newData);
                if ~isempty(rowDiffIndices)                    
                    rowMetaDataEvent.Row = rowDiffIndices;
                    rowsChanged = true;
                end
            end
            if rowsChanged
                this.notify('RowMetaDataChanged', rowMetaDataEvent);
            end

            if colsChanged
                this.notify('ColumnMetaDataChanged', colMetaDataEvent);
            end
            % Update rowmetadata when RowNames/RowTimes are different on a DataChange (after a sort).
            if this.hasRowMetaDataChanged(newData, origData)
                this.handleRowMetaDataUpdate(newData);
            end
        end
        
        function hasChanged = hasRowMetaDataChanged(~, newData, origData)
            hasChanged = ~isequal(newData.Properties.RowNames, origData.Properties.RowNames);
        end

        function output = funcCall(~, funcHandle, data, isuniformOutput)
            if isuniformOutput
                output = varfun(funcHandle, data, "OutputFormat", "uniform");
            else
                output = varfun(funcHandle, data, "OutputFormat", "cell");
            end
        end

        function varnames = getVarNameHelper(~, data)
            varnames = data.Properties.VariableNames;
        end

        function cellOutput = convertToCell(~, data)
            cellOutput = table2cell(data);
        end
        
        function [columnIndices, varNameIndices, classIndices, dateFormatIndices] = getColDiffIndices(this, origData, newData)
            try
            origVarNames = origData.Properties.VariableNames;
            newVarNames = newData.Properties.VariableNames;
            % 1. Check if varnames have changed.
            [~, varNameIndices] = (setdiff(origVarNames, newVarNames));
            % 2. Check if the order of varnames have changed
            varNameOrderIndices = find(~strcmp(origVarNames, newVarNames));
            varNameIndices = union(varNameIndices, varNameOrderIndices);
            classIndices = find(~strcmp(varfun(@(c)class(c), origData, "OutputFormat","cell"), varfun(@(c)class(c), newData, "OutputFormat","cell")));
            dateFormatIndices = [];
            dtDuItemsOrigData = find(varfun(@(c)(isa(c, "datetime") || isa(c, "duration")), origData, "OutputFormat", "uniform"));
            dtDuItemsNewData = find(varfun(@(c)(isa(c, "datetime") || isa(c, "duration")), newData, "OutputFormat", "uniform"));

            dtDuItemsWithSameDataType = intersect(dtDuItemsOrigData, dtDuItemsNewData);

            for i=1:length(dtDuItemsWithSameDataType)
                varNameOrig = origVarNames{dtDuItemsWithSameDataType(i)};
                varNameNew = newVarNames{dtDuItemsWithSameDataType(i)};
                if any(contains(newVarNames, varNameNew))
                    currentTimeZone = [];
                    newTimeZone = [];
                    if isa(origData.(varNameOrig),'datetime') && isa(newData.(varNameNew),'datetime')
                        currentTimeZone = origData.(varNameOrig).TimeZone;
                        newTimeZone = newData.(varNameNew).TimeZone;
                    end
                    currentFormat   = origData.(varNameOrig).Format;
                    newFormat       = newData.(varNameNew).Format;

                    if ~strcmp(currentFormat, newFormat) || ~strcmp(currentTimeZone, newTimeZone)
                        dateFormatIndices(end+1) = dtDuItemsWithSameDataType(i); %#ok<AGROW>
                    end
                end
            end

            columnIndices = union(union(varNameIndices, classIndices), dateFormatIndices);
            catch ex
                internal.matlab.datatoolsservices.logDebug('variableeditor::MLTableDataModelBase', "getColDiffIndices " + ex.message);
            end
        end
        
        function rowIndices = getRowDiffIndices(~, origData, newData)
            [~, rowIndices] = (setdiff(origData.Properties.RowNames, newData.Properties.RowNames));
        end
        
        % This method returns all the column indices(full size) to be updated 
        % in case of a size change. 
        function columnIndices = getColFullIndices(~, newData)
            newWidth = width(newData);
            columnIndices = [min(1, newWidth), newWidth];
        end
        
        % This method returns all row indices(full size) to be updated 
        % in case of a size change. 
        function rowIndices = getRowFullIndices(~, newData)
            rowIndices = [min(1, height(newData)), height(newData)];
        end
    end

    methods (Access = ?matlab.unittest.TestCase)
        function [columnIndices, varNameIndices, classIndices, dateFormatIndices] = testGetColDiffIndices(this, origData, newData)
            [columnIndices, varNameIndices, classIndices, dateFormatIndices] = this.getColDiffIndices(origData, newData);
        end
    end
end

