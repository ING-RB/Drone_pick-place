classdef CleanCategoriesActionBase < handle
    % CleanCategoriesActionBase
    
    % Copyright 2018-2024 The MathWorks, Inc.
    properties (Constant)
        CategoricalCleanerManager = '/categoricalCleaner';
        ORDER_COLUMN = 1,
        CATEGORIES_COLUMN = 2,
        COUNTS_COLUMN = 3,
        TOTAL_COLUMN_COUNT = 3,
        
        % uncomment with the arbitrary variable names change for tables
        Order_Variable = 'Order';
        Categories_Variable = 'Categories';
        Counts_Variable = 'Counts';
    end
    
    properties (Transient, WeakHandle)
        Manager internal.matlab.variableeditor.MLManager;
    end
    
    methods
        
        % Retrieves the selected rows into an array from the action event
        % info
        function selectedRows = getSelectedRows(~, selection)
            % selection can be multiple ranges, each range consisting of 1
            % or many rows. iterator keeps track of the actual row
            % number. i keeps track of the number of ranges
            iterator = 1;
            selectedRowsCount = size(selection);
            for i=1:selectedRowsCount(1)
                % when the range has many rows
                st = selection(i).rows.start;
                en = selection(i).rows.end;
                if ~isequal(st,en)
                    for j=st+1:en+1
                        selectedRows(iterator) = j;
                        % increment index in our rows array
                        iterator = iterator + 1;
                    end
                % when range has just one row
                else
                    selectedRows(iterator) = st+1;
                    iterator = iterator + 1;
                end
            end
        end
        
        function [categoriesToMerge, selectedRows] = getCategoriesToMerge(this, selectedRows, targetMergedCategory, doc)
            % add the target category as the first entry in the cell array
            % since the merge command merges to the first element of the
            % cell array
            categoriesToMerge = {targetMergedCategory};
            
            % loop through and add the category names to the cell array            
            % NOTE: we make a copy of selectedRows since during the for-loop we modify the actual
            % selectedRows variable to remove entries
            selectedRowsCopy = selectedRows;
            for k=1:length(selectedRowsCopy)
                category = char(doc.DataModel.Data.Categories(selectedRowsCopy(k)));
                if ~isequal(category, targetMergedCategory)
                    categoriesToMerge{end+1} = char(doc.DataModel.Data.Categories(selectedRowsCopy(k)));
                else
                    % if the selected category is the target category to
                    % merge to then set that to empty
                    % since, we will remove all the selected rows from the categories
                    % list except the one to merge into
                    
                    % update this to 'category' to ensure we merge to the value in the data model
                    % and not to a formatted version(targetMergedCategory and formattedCategory 
                    % are the formatted versions) of it
                    categoriesToMerge{1} = category;
                    selectedRows(k) = [];
                end
            end
        end
        
        % updates the categories information in the data cleaning workspace
        function updateCategoriesInfo(this, doc)            
            % update the data model
            dataModel = doc.DataModel;
            startRow = 1;
            endRow = size(dataModel.Data,1);           
            
            eventdata = internal.matlab.datatoolsservices.data.DataChangeEventData;
            eventdata.StartRow = startRow;
            eventdata.EndRow = endRow;
            eventdata.StartColumn = 1;
            eventdata.EndColumn = this.TOTAL_COLUMN_COUNT;           
            
            eventdata.SizeChanged = true;
            dataModel.notify('DataChange', eventdata);
        end
        
        % returns the copy of the actual table output from the data
        % cleaning workspace
        function data = getTableOutputData(~, doc)
            outputName = doc.Workspace.getOutputName();
            data = doc.Workspace.(outputName);
        end
        
        % updates the values of the copy of the actual table output in the
        % data cleaning workspace
        function setTableOutputData(~, data, doc)
            outputName = doc.Workspace.getOutputName();
            doc.Workspace.setVariableValue(outputName, data);  
        end
        
        % retrieves the column index of the column the categorical cleaner
        % is showing
        function index = getCategoricalColumnIndex(this, doc)
            % Get the table Variable Name from the workspace since we need
            % to get the indices for the output table's variable
            colName = doc.Workspace.VariableName;

            outputData = this.getTableOutputData(doc);
            index = find(strcmp(outputData.Properties.VariableNames, colName));
        end
        
        % retrieves the output manager
        function outputManager = getOutputManager(this)
            factory = internal.matlab.variableeditor.peer.MF0VMManagerFactory.getInstance();
            outputManagerChannel = this.Manager.Channel(1: strfind(this.Manager.Channel, '/categoricalCleaner')-1);
            mgrInstances = factory.getManagerInstances();
            outputManager = mgrInstances(outputManagerChannel);
        end
        
        % retrieves the output document using the manager and docID
        function outputDoc = getOutputDocument(this, outputManager, outputDocumentID)
            arguments
                this
                outputManager = []
                outputDocumentID = ''
            end
            if isempty(outputManager)
                outputManager = this.getOutputManager();
            end
            outputDoc = '';
            for i=1:length(outputManager.Documents)
                if isequal(outputManager.Documents(i).DocID, outputDocumentID)
                    outputDoc = outputManager.Documents(i); 
                end
            end
        end        
        
        % Adds the code Generated to the actionStateHandler's code
        % array if boundaryCondition is true then adds as a new element to code
        % array else replaces the last element of the code array
        function generateCode(this, editInfo, codeGenerated, isBoundaryCondition, doc)            
            actionStateHandler = this.getActionStateHandler(editInfo);                        
            colIndex = this.getCategoricalColumnIndex(doc);
            currentCmd = struct('Command', "Clean", 'Index', colIndex, 'commandInfo', codeGenerated.commandInfo, ...
                'generatedCode', {codeGenerated.publishCode}, 'executionCode', {codeGenerated.executeCode}); 
            
            % if it is a boundary condition then generate a new line of
            % code
            if isBoundaryCondition
                actionStateHandler.CommandArray = [actionStateHandler.CommandArray, currentCmd];
            else
                % if it is not a boundary condition then update the last
                % command
                actionStateHandler.CommandArray(end) = currentCmd;
            end            
        end               
        
        % Returns if a boundary condition has been met. If the previous
        % line of code is not of the same action type then returns true 
        function isBoundaryCondition = checkBoundaryCondition(~, categoriesList, actionType, doc)
            workspace = doc.Workspace;
            % Boundary condition implies generation of new line of code
            % this should happen if this is the first command in the array
            % or
            % the previous command is not of the same 'clean' type
            % or
            % if no remove operation has been done till now (case when the cleaner is opened,
            % categories removed, close, re-opened, remove again)
            isBoundaryCondition = false;
            codeGeneratedArray = workspace.getCodeGeneratedArray();
            if isempty(codeGeneratedArray) || ...
                    ~strcmp(codeGeneratedArray(end).commandInfo, actionType) || ...
                    isempty(categoriesList)
                isBoundaryCondition = true;
            end
        end
        
        % utility method to retrieve the action state handler
        function sh = getActionStateHandler(this, editInfo)
            outputManager = this.getOutputManager();            
            outputDocumentID = editInfo.actionInfo.outputDocumentID;
            outputDoc = this.getOutputDocument(outputManager, outputDocumentID);            
            sh = outputDoc.ViewModel.ActionStateHandler;
        end 
        
        % Common code to Merge and Remove actions pulled out
        % loops through and appends the categories to the code strings
        function [publishCode, executeCode] = appendCategoriesToCodeGenerated(~, publishCode, executeCode, categoriesList)
            [quotes, ~, ~] = internal.matlab.variableeditor.peer.PeerUtils.getCodegenConstructsForDatatype("string");
            categoriesList = internal.matlab.variableeditor.peer.PeerUtils.getCleanedNamesForCodegen(categoriesList, quotes, "string"); 
            
            for i = 1:length(categoriesList)
                if ~isequal(i, length(categoriesList))
                    publishCode = [publishCode categoriesList{i} ','];
                    executeCode = [executeCode categoriesList{i} ','];
                else
                    publishCode = [publishCode categoriesList{i} ']);'];
                    executeCode = [executeCode categoriesList{i} ']);'];
                end
            end
            publishCode = {publishCode};
            executeCode = {executeCode};
        end
        
        % common code to Merge and Remove pulled out
        % updates the unsearched table by removing the categories 
        function unsearchedTable = removeFromUnsearchedTable(~, categoriesToRemove, colName, doc)
            workspace = doc.Workspace;
            % get the original indices of the categories to remove
            originalTableIndices = workspace.getUnsearchedIndices(categoriesToRemove, colName);

            % set the originalTableIndices entries in the unsearched
            % table to empty
            unsearchedTable = workspace.getUnsearchedTable(colName);
            unsearchedTable(originalTableIndices, :) = [];
        end
    end    
end
        
        