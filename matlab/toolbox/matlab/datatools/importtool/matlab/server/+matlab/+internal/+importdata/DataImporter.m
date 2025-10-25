% This class is unsupported and might change or be removed without
% notice in a future version.

% This class is used in the import workflow to import images, audio, video, MAT
% files, etc. into MATLAB.  For example:
%
%    p = matlab.internal.importdata.ImportProviderFactory.getProvider("peppers.png")
%    d = matlab.internal.importdata.DataImporter(p);
%    d.import()
%
% Or, import can be synchronous, for example:
%
%    s = d.import();

% Copyright 2020-2024 The MathWorks, Inc.

classdef DataImporter < handle
    properties
        % The ImportProvider class
        Provider {mustBeProvider};
        
        % Whether the Import is complete or not.  This is used for synchronous
        % import
        ImportDone logical = false;
        
        % Whether the Import Data window should be modal or not
        IsModal logical = false;
        
        % The custom position for the Import Data window
        Position double = NaN;
        
        % Whether to enforce single selection or not
        SingleSelection logical = false;
        
        % Extra message to show in the dialog, in place of the Don't Show
        % preferences checkbox
        ExtraMessage string = strings(0);

        SupportsDontShowPref logical = true;

        Title string = strings(0);

        WindowClosedFcn function_handle = function_handle.empty;

        DataImportedFcn function_handle = function_handle.empty;

        % Whether the UI participates in desktop theming or not
        UseDesktopTheme (1,1) logical = false;

        DisableImportBtnAtStartup (1,1) logical = false;
    end
    
    properties(Constant = true, Hidden)
        % Default size of the Import Data window
        DEFAULT_WIDTH = 500;
        DEFAULT_HEIGHT = 300;
        
        % Default height when it contains a preview
        HEIGHT_WITH_PREVIEW = 490;

        % Default size with additional options
        HEIGHT_WITH_OPTIONS = 750;
        WIDTH_WITH_OPTIONS = 775;
        
        % Default size of the Import Data window when it contains variable
        % selection
        WIDTH_WITH_VAR_SELECTION = 570;
        HEIGHT_WITH_VAR_SELECTION = 425;
    end
    
    properties(Hidden = true)
        ImportUI = [];
        CodePublisher = [];
    end
    
    properties(Access = protected)
        CloseListener = [];
        DestroyedListener = [];
        SynchronousImport logical = false;
        ImportedData = [];
        SelectAllAtStartup logical = true;
    end
    
    methods
        function this = DataImporter(provider)
            % Construct a DataImporter

            arguments
                provider (1,1) matlab.internal.importdata.ImportProvider
            end
            
            this.Provider = provider;
            this.CodePublisher = internal.matlab.datatoolsservices.CodePublishingService.getInstance;
        end
        
        function varargout = import(this)
            % Called to show the Import Data UI to perform the import.  Creates
            % the UI, and sets up callbacks.  If there is an output argument,
            % then the import is synchronous, and will wait until a result is
            % produced by the import dialog (or it is closed) before continuing.
            
            arguments
                this (1,1) matlab.internal.importdata.DataImporter
            end

            this.ImportDone = false;
            this.ImportedData = [];
            
            % Import is synchronous if there are output arguments
            this.SynchronousImport = (nargout == 1);
            this.Provider.SynchronousImport = (nargout == 1);
            
            if ~isempty(this.Provider.Parent)
                delete(this.Provider.Parent);
            end
            % Create the UI
            h = matlab.internal.importdata.ImportDataUI(...
                this.Provider, ...
                "ImportFcn", @this.importData);
            autoImportNoUI = ~isempty(getenv("TEST_AUTO_IMPORT_NO_UI"));
            if autoImportNoUI
                % Don't even show the UI when testing the synchronous workflow
                h.ImportDataUIFigure.Visible = 'off';
                varNames = this.Provider.getVariables();
            end
            if ~isempty(h.getErrorState)
                % Close the dialog if it was opened, and rethrow the error
                ex = h.getErrorState;
                if ~isempty(h) && isvalid(h)
                    delete(h)
                end
                throwAsCaller(ex)
            end

            this.ImportUI = h;
            h.ImportDataUIFigure.Icon = fullfile(matlabroot, "toolbox/matlab/datatools/importtool/matlab/server/resources/import_16.png");

            if this.UseDesktopTheme
                matlab.graphics.internal.themes.figureUseDesktopTheme(this.ImportUI.ImportDataUIFigure);
            end

            if ~isempty(this.Title) 
                this.ImportUI.ImportDataUIFigure.Name = this.Title;
            end

            % Set the Tag and UserData.  This is used to identify the import
            % data window, so we don't open a 2nd dialog for the same file. (Tag
            % is also used by tests)
            this.ImportUI.ImportDataUIFigure.Tag = "importdata";
            this.ImportUI.ImportDataUIFigure.UserData = this.Provider.getFullFilename;
            
            this.ImportUI.VariablesTable.CellSelectionCallback = @cellSelectCB;
            this.setWindowSize();

            if (this.DisableImportBtnAtStartup)
                this.ImportUI.ImportButton.Enable = false;
            end
            
            if this.IsModal
                % Set the window style to modal
                this.ImportUI.ImportDataUIFigure.WindowStyle = "modal";
            end
            
            % Hide until implemented fully (and supported)
            if ~this.SupportsDontShowPref || ~this.Provider.SupportsSkippingDialog
                this.ImportUI.DontShowCheckBox.Visible = "off";
                
                if ~isempty(this.ExtraMessage)
                    % Position the ExtraMessage in a label, in place of the
                    % Don't Show preference checkbox
                    lbl = uilabel(this.ImportUI.GridLayout);
                    lbl.Text = this.ExtraMessage;
                    lbl.Layout.Row = 7;
                    lbl.Layout.Column = 1;
                end
            else
                this.ImportUI.DontShowCheckBox.Value = ~this.Provider.getShowDialogPref();
            end
            
            if ~this.SelectAllAtStartup
                this.ImportUI.SelectAllCheckBox.Value = false;
                this.ImportUI.SelectAllCheckBox.ValueChangedFcn(this.ImportUI, []);
            end
            
            if this.SingleSelection
                % Hide the select all checkbox in single selection mode
                this.ImportUI.SelectAllCheckBox.Visible = 'off';
                this.ImportUI.GridLayout.RowHeight{3} = 0;
                this.ImportUI.VariablesTable.CellEditCallback = @this.singleSelectionCellEditCB;
                
                % Also adjust the label
                this.ImportUI.VariablesLabel.Text = getString(message(...
                    "MATLAB:datatools:importdata:VariableLabel"));
            end
                        
            % Add listeners for the dialog being closed
            this.CloseListener = addlistener(h.ImportDataUIFigure, ...
                "Visible", "PostSet", @this.windowClosed);
            this.DestroyedListener = listener(h, "ObjectBeingDestroyed", ...
                @this.windowClosed);
            
            if this.SynchronousImport
                if autoImportNoUI
                    if isempty(getenv("TEST_AUTO_IMPORT_NO_UI_CANCEL"))
                        this.importData([], varNames);
                    end
                else
                    % Import is synchronous, so we need to wait for the import to be
                    % completed (or for the window is closed)
                    waitfor(this, "ImportDone", true);
                end
                varargout{1} = this.ImportedData;
            end
        end
        
        function delete(this)
            % Delete the ImportUI, and all the listeners
            
            arguments
                this (1,1) matlab.internal.importdata.DataImporter
            end

            if ~isempty(this.ImportUI)
                delete(this.ImportUI);
            end
            
            delete(this.CloseListener);
            delete(this.DestroyedListener);
        end
        
        function varargout = importWithoutDialog(this)
            % Import the data without showing the dialog.  If there is an output
            % argument, then the import is synchronous, and the result will be a
            % struct with the imported data.
            
            arguments
                this (1,1) matlab.internal.importdata.DataImporter
            end
            
            this.SynchronousImport = (nargout == 1);

            this.importData([], this.Provider.getVariables);
            
            if this.SynchronousImport
                % Import is synchronous, so we need to assign the output
                % argument
                varargout{1} = this.ImportedData;
            end
        end
    end
    
    methods(Access = protected)
        function windowClosed(this, ~, ~)
            % When the window is closed, consider the import to be done

            arguments
                this (1,1) matlab.internal.importdata.DataImporter
                ~
                ~
            end

            this.ImportDone = true;
            
            % Reset the modality flag when the window closes.  Even though it
            % isn't visible, it can still effect the modality of windows.
            this.ImportUI.ImportDataUIFigure.WindowStyle = "normal";

            if ~isempty(this.WindowClosedFcn)
                this.WindowClosedFcn();
            end
        end
        
        function singleSelectionCellEditCB(this, ~, ed)
            if ed.NewData
                % Row was selected
                row = ed.Indices(1);
                tb = this.ImportUI.VariablesTable.Data;
                tb.(1) = false(height(tb), 1);
                tb{row, 1} = true;
                this.ImportUI.VariablesTable.Data = tb;
            end

            selected = this.ImportUI.VariablesTable.Data.(1);
            this.ImportUI.ImportButton.Enable = any(selected);
        end
        
        function importData(this, ~, selectedVarNames)
            % Imports the data by getting the import code from the provider, and
            % either evaling it in the base workspace, or returning the values
            % in a struct (for synchronous import).
            
            arguments
                this (1,1) matlab.internal.importdata.DataImporter
                ~
                selectedVarNames string
            end

            import matlab.internal.capability.Capability;
            
            % Set a busy cursor in the figure while the import takes place, if
            % the UI was shown
            if ~isempty(this.ImportUI) && isvalid(this.ImportUI)
                this.ImportUI.ImportDataUIFigure.Pointer = "watch";
            end
            
            this.Provider.SelectedVarNames = selectedVarNames;
            importCode = this.Provider.getImportCode;

            if ~isempty(importCode)
                % This is called by the Import Data UI when the Import button is
                % clicked.
                if this.SynchronousImport || ~isempty(this.DataImportedFcn)
                    % For synchronous import, get the import code and eval it.
                    % Return the variables created in a struct.
                    eval(importCode);
                    vars = setdiff(who, ["this", "importCode", "selectedVarNames"]);
                    this.ImportedData = struct;
                    for idx = 1:length(vars)
                        this.ImportedData.(vars(idx)) = eval(vars(idx));
                    end

                    if ~isempty(this.DataImportedFcn)
                        this.DataImportedFcn(this.ImportedData);
                    end
                else
                    % For non-synchronous import, eval the import code in the base
                    % workspace.  (Also do this in test environments)
                    if (matlab.internal.feature('webui') == 0 && ...
                        Capability.isSupported(Capability.LocalClient)) || ...
                         ~isempty(getenv("TEST_AUTO_IMPORT"))
                        evalin("base", importCode);
                    else
                        % Publish the code to the CodePublishingService for MOL
                        % and JSD
                        this.CodePublisher.publishCode("ImportData", importCode)
                    end
                end
            end
            
            if ~isempty(this.ImportUI) && isvalid(this.ImportUI) && this.SupportsDontShowPref
                % Update the preference setting if the UI was shown, and if the
                % user selected to don't show this dialog again
                prefSetting = ~this.ImportUI.DontShowCheckBox.Value;
                this.Provider.updateShowDialogPref(prefSetting);
            end
            
            this.ImportDone = true;
        end
    end

    methods(Access = {?matlab.internal.importData.DataImporter, ?matlab.unittest.TestCase})
        function setWindowSize(this)
            if isnan(this.Position)
                width = this.DEFAULT_WIDTH;
                height = this.DEFAULT_HEIGHT;
                
                if isa(this.Provider, "matlab.internal.importdata.ImportVarSelectionProvider")
                     width = this.WIDTH_WITH_VAR_SELECTION;
                     height = this.HEIGHT_WITH_VAR_SELECTION;
                elseif isa(this.Provider, "matlab.internal.importdata.ImportPreviewProvider")
                    height = this.HEIGHT_WITH_PREVIEW;
                elseif isa(this.Provider, "matlab.internal.importdata.ImportOptionsProvider")
                    width = this.WIDTH_WITH_OPTIONS;
                    height = this.HEIGHT_WITH_OPTIONS;
                end

                screenHeight = get(groot, "ScreenSize");
                screenHeight = screenHeight(4);
                this.ImportUI.ImportDataUIFigure.Position(3) = width;
                this.ImportUI.ImportDataUIFigure.Position(4) = height;
                if height > (screenHeight - 100)
                    % If the window is being sized taller than the screensize, cut it down to fit
                    height = screenHeight - 100; % 100 = buffer for OS panes
                    this.ImportUI.ImportDataUIFigure.Position(2) = 50;
                    this.ImportUI.ImportDataUIFigure.Position(4) = height;
                elseif isa(this.ImportUI.ImportDataUIFigure, "matlab.ui.Figure")
                    % Center the dialog.  ImportDataUIFigure will always be the figure, except for 
                    % unit tests
                    centerfig(this.ImportUI.ImportDataUIFigure);
                end
            else
                % Set the position to the values specified
                this.ImportUI.ImportDataUIFigure.Position = this.Position;
            end
        end
    end
end

function mustBeProvider(input)
    % Make sure the property is a matlab.internal.importdata.ImportProvider
    if ~isa(input, "matlab.internal.importdata.ImportProvider") && ~isempty(input)
        throwAsCaller(MException("MATLAB:type:PropSetClsMismatch", "%s", ...
            message("MATLAB:type:PropSetClsMismatch", ...
            "matlab.internal.importdata.ImportProvider").getString));
    end
end

function [style, selectedRow] = cellSelectCB(hObject, eventdata)
    % Update the table styling.  Returns the style and selectedRow for testing
    % purposes only.
    table = hObject;
    selectedRow = eventdata.Indices(:,1);

    % Remove any previous style added to table
    removeStyle(table);

    % Highlight the entire row in the table.  This needs to be done after the
    % removeStyle has a chance to process, otherwise the old style isn't removed
    % before the new one is added.  This is done using a short timer.

    function s = selectRows(tm, ~)
        table.addStyle(matlab.ui.style.internal.SemanticStyle( ...
            "BackgroundColor", ...
            '--mw-backgroundColor-selectedFocus'), ...
            "row", selectedRow);

        % Return value is used for testing
        s = table.StyleConfigurations.Style;

        if nargin > 1 && isvalid(tm)
            tm.stop();
            delete(tm);
        end
    end

    if internal.matlab.datatoolsservices.getSetCmdExecutionTypeIdle
        % Revert to synchronous selection
        style = selectRows();
    else
        tm = timer("TimerFcn", @selectRows, "StartDelay", 0.1, "ExecutionMode", "singleShot");
        tm.start;
        style = [];
    end
end

