function vardisambiguate(hFig,varNames,varValues,mfile,fcnname,okAction,appDataString)

% Utility method for brushing/linked plots. May change in a future release.

% Copyright 2007-2020 The MathWorks, Inc.

% Build table entries
totalBrushedPoints = strings(length(varNames),1);
varDescriptions = strings(length(varNames),1);
brushMgr = datamanager.BrushManager.getInstance();
for i=1:length(varNames)
    I = brushMgr.getBrushingProp(varNames{i},mfile,fcnname,'I');
    totalBrushedPoints(i) = sprintf('%d out of %d',sum(I(:)),numel(I));
    varDesc = workspacefunc('getabstractvaluesummariesj',{varValues{i}});
    varDescriptions(i) = varDesc(1);
end


tableData = table(varNames,totalBrushedPoints,varDescriptions,...
    'VariableNames',{getString(message('MATLAB:datamanager:vardisambiguate:Name')),getString(message('MATLAB:datamanager:disambiguate:NumberOfBrushedPoints')),getString(message('MATLAB:datamanager:vardisambiguate:Size'))
    });

diambiguateDialog = getappdata(hFig,appDataString);
if isempty(diambiguateDialog) ||  ~isvalid(diambiguateDialog)
    % Build and show Disambiguation dialog to resolve ambiguity
    diambiguateDialog = uifigure('Visible', 'off', ...
        'Internal', true, ...
        'WindowStyle', 'modal', ...
        'Position', [hFig.Position(1) hFig.Position(2) 400 200], ...
        'Name', getString(message('MATLAB:datamanager:vardisambiguate:DialogName')),...
        'CloseRequestFcn', @(e,d) closeDialog());
    mainGrid = uigridlayout(diambiguateDialog, 'ColumnWidth', {'1x'}, ...
        'RowHeight', {30, '1x', 40}, ...
        'ColumnSpacing', 5, ...
        'RowSpacing', 5);
    
    dialogLabel = uilabel(mainGrid);
    dialogLabel.Layout.Row = 1;
    dialogLabel.Layout.Column = 1;
    dialogLabel.Text = getString(message('MATLAB:datamanager:vardisambiguate:DialogLabel'));
    
    % Create DataSourceTable
    uit = uitable(mainGrid, ...
        'RowName', {}, ...
        'RowStriping', 'off', ...        
        'CellSelectionCallback', @(e,d) localSelectObj(e,d));
    uit.Layout.Row = 2;
    uit.Layout.Column = 1;
    
    % Highlight the first row in the table.
    selectedRow = 1;
    % Highlight the entire row in the table.
    addRowHighlight(uit,selectedRow);
    
    subGrid = uigridlayout(mainGrid, 'ColumnWidth', {'2x', '1x', '1x'}, ...
        'RowHeight', {'1x'}, ...
        'Padding', [5 5 5 5], ...
        'RowSpacing', 5);
    subGrid.Layout.Row = 3;
    subGrid.Layout.Column = 1;
    
    % Create ok button to copy data to clipboard and close the dialog
    okButton = uibutton(subGrid, 'push', ...
        'Text', getString(message('MATLAB:datamanager:disambiguate:OKButton')),...
        'ButtonPushedFcn', @(e,d) evaluateOkAction());
    
    okButton.Layout.Row = 1;
    okButton.Layout.Column = 2;
    
    % Cancel button will simply close the dialog
    cancelButton = uibutton(subGrid, 'push','ButtonPushedFcn', @(e,d) closeDialog());
    cancelButton.Layout.Row = 1;
    cancelButton.Layout.Column = 3;
    cancelButton.Text = getString(message('MATLAB:datamanager:vardisambiguate:CancelButton'));
end

% Show the figure after all components are created
uit = diambiguateDialog.Children.Children(2);
uit.Data = tableData;
diambiguateDialog.Visible = 'on';
figure(diambiguateDialog);

setappdata(hFig,appDataString,diambiguateDialog);
addlistener(hFig,'ObjectBeingDestroyed', @(e,d) closeDialog());

% Copy to clipboard and close the dialog
    function evaluateOkAction()
        index = selectedRow;
        feval(okAction{1},index,okAction{2:end});
        % Copy and close the dialog
        closeDialog();
    end

% This function highlights the row based on use selection
    function localSelectObj(table,d)
        % Find the selected row index
        selectedRow = d.Indices(1);
        
        % Highlight the entire row in the table.
        addRowHighlight(table,selectedRow);
    end

    function closeDialog()
        setappdata(hFig,appDataString,[]);
        delete(diambiguateDialog);
    end
end

function addRowHighlight(table, selectedRow)
% Remove any previous style added to table
removeStyle(table);
% Highlight the entire row in the table.
s = uistyle('BackgroundColor',[0.84 0.95 1]);
addStyle(table,s,'row',selectedRow);
end