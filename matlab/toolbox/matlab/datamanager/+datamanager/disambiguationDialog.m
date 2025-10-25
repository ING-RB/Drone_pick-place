function disambiguationDialog(hFig,brushedObjects,tableData,okActionCallback,doExport)

% This function creates a disambiguation dialog which resolves ambiguity
% caused when attempting to create a variable from multiple brushed objects

% Copyright 2019 The MathWorks, Inc.

% Initially brushedData is empty. It is set when user makes a selection in
% the table
brushedData = [];

% Create identifyDialog and hide until all components are created
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
    'CellSelectionCallback', @(e,d) localSelectObj(e,d,brushedObjects));

% Create ExportButton
okButton = uibutton(identifyDialog, 'push', ...
    'Position', [280 10 80 22], ...
    'Tooltip', {getString(message('MATLAB:datamanager:brushobj:ExportToWorkspace'))}, ...
    'Text', getString(message('MATLAB:datamanager:disambiguate:OKButton')),...
    'Enable', 'off', ...
    'ButtonPushedFcn', @(e,d) pressOKCallback());

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
    function pressOKCallback()
        closeDialog();
        if doExport
            export2wsdlg({getString(message('MATLAB:datamanager:brushobj:EnterVariableName'))}, ...
                {'brushedData'}, ...
                {brushedData}, ...
                getString(message('MATLAB:datamanager:brushobj:ExportToWorkspace')));
        else
            feval(okActionCallback,brushedData);
        end
    end

    function localSelectObj(table,d,objs)
        
        % There have been cases in automated testing where the graphics objects
        % were deleted by the time this callback fired (g576643). Test to make
        % sure that objects are all valid before updating the dialog. Since this
        % dialog is modal this should never happen during manual operation.
        if ~all(ishghandle(objs))
            return
        end
        
        % Enable the export button when a table row is selected and set the
        % currently brushed object
        selectedRow = d.Indices(1);
        okButton.Enable = 'on';
        % Get the brushed data from the selected object
        if doExport
            brushedData = feval(okActionCallback,brushedObjects(selectedRow));
        else
            brushedData = brushedObjects(selectedRow);
        end
        
        removeStyle(table);
        % Restore cached widths
        localRestoreCachedWidths(objs)
        
        % Highlight the entire row in the table. This is done here manually
        % because uitable doesn't offers any mechanism such as click
        % listener on a row. The only thing available is cell selection
        % listener
        s = uistyle('BackgroundColor',[0.84 0.95 1]);
        addStyle(table,s,'row',selectedRow);
        
        % Change the linewidth of the selected object
        lw = get(objs(selectedRow),'LineWidth');
        setappdata(objs(selectedRow),'CacheWidth',lw);
        set(objs(selectedRow),'LineWidth',lw*3);
    end

% Restore line width of brushed objects
    function localRestoreCachedWidths(ls)
        
        for k=1:length(ls)
            cacheWidth = getappdata(ls(k),'CacheWidth');
            if ~isempty(cacheWidth)
                set(ls(k),'LineWidth',cacheWidth);
            end
        end
    end

% Fired when user closes the dialog or closes the parent figure.
% Clean-up the listener and restore line width of brushed objects
    function closeDialog()
        setappdata(hFig,'brushing_disambiguateDlg',[]);
        localRestoreCachedWidths(brushedObjects);
        
        delete(dialogListeners);
        delete(identifyDialog);
    end
end