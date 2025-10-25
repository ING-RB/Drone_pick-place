function newvardisambiguateVariables(hFig,varNames,varValues,mfile,fcnname,okAction,~)
%

% Copyright 2007-2019 The MathWorks, Inc.

% Disambiguate variables in linked plots when creating new variables from
% brushing annotations.

% Copyright 2008-2011 The MathWorks, Inc.

% Find linked variable names
% Build table entries
dlg = getappdata(hFig,'brushing_disambiguateDlg');
if ~isempty(dlg) && isvalid(dlg)
    figure(dlg);
    return;
end
totalBrushedPoints = zeros(length(varNames),1);
brushMgr = datamanager.BrushManager.getInstance();
for i=1:length(varNames)
    I = brushMgr.getBrushingProp(varNames{i},mfile,fcnname,'I');
    totalBrushedPoints(i) = sum(I(:));
end

varDescriptions = internal.matlab.datatoolsservices.FormatDataUtils.formatDataBlockForMixedView(1,...
    length(varValues),1,length(varValues),varValues);
tableData = table(varNames,totalBrushedPoints,varDescriptions,...
    'VariableNames',{'Name',getString(message('MATLAB:datamanager:disambiguate:NumberOfBrushedPoints')),'Size'});
% Build and show Disambiguation dialog to resolve ambiguity
brushedData = [];

identifyDialog = uifigure('Visible', 'off', ...
    'Internal', true, ...
    'Position', [hFig.Position(1) hFig.Position(2) 372 200], ...
    'Name', getString(message('MATLAB:datamanager:disambiguate:ExportDialogTitle')), ...
    'CloseRequestFcn', @(e,d) closeDialog());

% Create DataSourceTable
uitable(identifyDialog, ...
    'RowName', {}, ...
    'Position', [12 47 347 124], ...
    'RowStriping', 'off', ...
    'Data', tableData, ...
    'CellSelectionCallback', @(e,d) localSelectObj(e,d,okAction));

% Create ExportButton
okButton = uibutton(identifyDialog, 'push', ...
    'Position', [280 10 80 22], ...
    'Tooltip', {getString(message('MATLAB:datamanager:brushobj:ExportToWorkspace'))}, ...
    'Text', getString(message('MATLAB:datamanager:disambiguate:OKButton')),...
    'Enable', 'off', ...
    'ButtonPushedFcn', @(e,d) showExportDialog());

% Create TableLabel
uilabel(identifyDialog, ...
    'Position', [13 175 347 22], ...
    'Text', getString(message('MATLAB:datamanager:disambiguate:TableLabel')));

% Show the figure after all components are created
identifyDialog.Visible = 'on';
setappdata(hFig,'brushing_disambiguateDlg',identifyDialog);

% Close this dialog when the parent figure is closed
dialogListeners = addlistener(hFig,'ObjectBeingDestroyed',@(e,d) closeDialog());
uiwait(identifyDialog);
    function showExportDialog()
        closeDialog();
        export2wsdlg({getString(message('MATLAB:datamanager:brushobj:EnterVariableName'))}, ...
            {'brushedData'}, ...
            {brushedData}, ...
            getString(message('MATLAB:datamanager:brushobj:ExportToWorkspace')));
    end

    function localSelectObj(table,d,okAction)
        % Enable the export button when a table row is selected and set the
        % currently brushed object
        selectedRow = d.Indices(:,1);
        okButton.Enable = 'on';
        % Get the brushed data from the selected object
        brushedData = feval(okAction,  ...
            varNames(selectedRow,:), ...
            varValues(selectedRow,:),mfile,fcnname);        
        removeStyle(table);
        
        % Highlight the entire row in the table. This is done here manually
        % because uitable doesn't offers any mechanism such as click
        % listener on a row. The only thing available is cell selection
        % listener
        s = uistyle('BackgroundColor',[0.84 0.95 1]);
        addStyle(table,s,'row',selectedRow);
    end

% Fired when user closes the dialog or closes the parent figure.
% Clean-up the listener and restore line width of brushed objects
    function closeDialog()
        setappdata(hFig,'brushing_disambiguateDlg',[]);
        
        delete(dialogListeners);
        delete(identifyDialog);
    end
end