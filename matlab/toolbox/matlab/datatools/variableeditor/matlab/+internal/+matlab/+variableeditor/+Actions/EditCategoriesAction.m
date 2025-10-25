classdef EditCategoriesAction < internal.matlab.datatoolsservices.actiondataservice.Action
    % EditCategoriesAction

    % Copyright 2018-2024 The MathWorks, Inc.

    properties (Constant)
        ActionType = 'EditCategoriesAction';
        CategoricalCleanerManager = '/categoricalCleaner';
        ActionManagerNamespace = '_CategoricalCleaningActions';
        startPath = 'internal.matlab.variableeditor.Actions.CategoricalCleaning';

        % uncomment with the arbitrary variable names change for tables
        Order_Variable = 'Order';
        Categories_Variable = 'Categories';
        Counts_Variable = 'Counts';
    end

    properties (Access = {?internal.matlab.datatoolsservices.actiondataservice.EditCategoriesAction, ?matlab.unittest.TestCase}, WeakHandle)
        Manager internal.matlab.variableeditor.MLManager;
    end

    methods
        function this = EditCategoriesAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.EditCategoriesAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.datatoolsservices.actiondataservice.Action(props);
            this.Callback = @this.EditCategories;
            this.Manager = manager;
        end

        function EditCategories(this, editInfo)
            % get the categorical cleaner manager
            mgr = internal.matlab.variableeditor.Actions.EditCategoriesAction.getCategoricalCleanerManager(this.Manager.Channel);

            % init actions on the manager
            mgr.initActions([mgr.Channel this.ActionManagerNamespace], this.startPath, [], true);

            % get the document using the docID
            doc = '';
            for i=1:length(this.Manager.Documents)
                if isequal(this.Manager.Documents(i).DocID, editInfo.docID)
                    doc = this.Manager.Documents(i);
                    break;
                end
            end

           % if the action information has revertFilters to true then
           % revert all the filtering on the output
           if isfield(editInfo.actionInfo, 'revertFilters') && editInfo.actionInfo.revertFilters
               eventData = struct('actionInfo', editInfo.actionInfo, 'docID', editInfo.docID);
               clearAllActionArgs = struct('EventData',eventData);
               action = this.Manager.ActionManager.ActionDataService.getAction('ClearAllFiltersAction');
               actionInstance = action.Action;
               actionInstance.ClearAllFilters(eventData);
           end

            % create the summary data
            fullData = doc.DataModel.Data;
            categoricalVariableName = editInfo.actionInfo.columnName;
            categoricalData = internal.matlab.variableeditor.Actions.EditCategoriesAction.getCategoricalData(fullData, categoricalVariableName);
            undefinedCategoriesCount = length(find(isundefined(fullData.(categoricalVariableName))));
            isOrdinal = isordinal(fullData.(categoricalVariableName));

            % create a data cleaning workspace and call openvar using it
            dataCleaningWorkspace = internal.matlab.variableeditor.DataCleaningWorkspace(doc.DataModel.Name, fullData, categoricalVariableName, categoricalData);
            categoriesDoc = mgr.openvar(dataCleaningWorkspace.InternalTableProp, dataCleaningWorkspace, categoricalData, UserContext='peer,categoricalCleaner');
            categoriesDoc.IgnoreScopeChange = true;
            categoriesDoc.ViewModel.setTableModelProperty('UndefinedCount', undefinedCategoriesCount);
            categoriesDoc.ViewModel.setTableModelProperty('isOrdinal', isOrdinal);
        end
    end

    methods(Static)
        function mgr = getCategoricalCleanerManager(outputManagerChannel)
            channel = [outputManagerChannel internal.matlab.variableeditor.Actions.EditCategoriesAction.CategoricalCleanerManager];
            mgr = internal.matlab.variableeditor.peer.MF0VMManagerFactory.createInstance(channel, false);
            %mgr = mgrInstances([outputManagerChannel internal.matlab.variableeditor.Actions.EditCategoriesAction.CategoricalCleanerManager]);
        end

        function categoricalData = getCategoricalData(fulldata, categoricalVariableName)
            % based on column class compute the summary
            categoricalData = [];
            fulldata.(categoricalVariableName) = categorical(fulldata.(categoricalVariableName));

            if iscategorical(fulldata.(categoricalVariableName))
                if isequal(size(fulldata.(categoricalVariableName), 2), 1) && isvarname(categoricalVariableName)
                    categoricalData = groupsummary(fulldata, categoricalVariableName, 'IncludeEmptyGroups', true, 'IncludeMissingGroups', false);
                else
                    counts = countcats(fulldata.(categoricalVariableName));
                    % for grouped columns, we need to compute the sum of
                    % occurrences of a category in each of the groups
                    for i=1:size(counts,1)
                        counts(i) = sum(counts(i,:));
                    end
                    counts = counts(:,1);
                    if ~isempty(categories(fulldata.(categoricalVariableName)))
                        categoricalData = table(categories(fulldata.(categoricalVariableName)), counts);
                    else
                        categoricalData = array2table(zeros(0,2));
                    end
                end

                categoricalData.Properties.VariableNames = {internal.matlab.variableeditor.Actions.EditCategoriesAction.Categories_Variable, ...
                    internal.matlab.variableeditor.Actions.EditCategoriesAction.Counts_Variable};
                categoricalData.Categories = string(categoricalData.Categories);
                rowCount = length(categoricalData.Categories);
                orderVariable = table([1:rowCount]', 'VariableNames', {internal.matlab.variableeditor.Actions.EditCategoriesAction.Order_Variable});
                categoricalData = [orderVariable categoricalData];
            end
        end
    end
end
