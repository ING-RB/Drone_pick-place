classdef (Hidden = true, AllowedSubclasses = ...
        {?matlab.internal.dataui.timetableRetimer ...
        ?matlab.internal.dataui.timetableSynchronizer}) ...
        retimeSynchEmbedder < matlab.task.LiveTask
    % Embedder for retime and synchronize live tasks
    %
    %   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    %   Its behavior may change, or it may be removed in a future release.

    %   Copyright 2019-2024 The MathWorks, Inc.

    properties (Access = public, Transient, Hidden)
        % Widget layout
        UIFigure                  matlab.ui.Figure
        Accordion                 matlab.ui.container.internal.Accordion

        % Table input widgets
        TableDropDowns            matlab.ui.control.internal.model.WorkspaceDropDown

        % New Times widgets
        NewTimesDropdown          matlab.ui.control.DropDown
        BasisTypeDropdown         matlab.ui.control.DropDown
        TimeStepSpinner           matlab.ui.control.Spinner
        TimeStepUnits             matlab.ui.control.DropDown
        SampleRateSpinner         matlab.ui.control.Spinner
        SampleRateUnits           matlab.ui.control.DropDown
        NewTimesWorkspaceDropdown matlab.ui.control.internal.model.WorkspaceDropDown

        % method widgets
        MethodTypeDropdown        matlab.ui.control.DropDown
        ConstantSpinner           matlab.ui.control.Spinner
        CustomAggFcnSelector      matlab.internal.dataui.FunctionSelector

        % override widgets
        FirstAddButton            matlab.ui.control.Button
        OverrideAddButtonHolder   matlab.ui.container.GridLayout
        OverrideGrid              matlab.ui.container.GridLayout
        OverrideDropdownsVar      matlab.ui.control.DropDown
        OverrideDropdownsMethods  matlab.ui.control.DropDown
        OverrideSubtractButtons   matlab.ui.control.Image
        OverrideAddButtons        matlab.ui.control.Image

        % Visualize Row
        OutputTableCheckbox       matlab.ui.control.CheckBox
        InputTablesCheckbox       matlab.ui.control.CheckBox

        % other
        NumInputTables            double
        NumOverrides              double
        MaxOverrides              double
        IsSortedTimes             logical
        SampleRateByDefault       logical = false; % changes if keyword is "upsample" or "downsample"
        OverrideLocations         double = []; % index of each override variable in the output timetable
    end

    properties (Constant, Transient, Hidden)
        % grid heights/widths
        TextRowHeight double = 22; % Same as App Designer default
        DropDownWidth double = 120; % used for input/override dropdowns
        IconColumnWidth double = 16; % Same as width of +/- icons
        FillMethods = {'fillwithmissing','fillwithconstant','previous','next','nearest'};
        InterpMethods = {'linear','spline','pchip','makima'};
        AggMethods = {'sum','mean','prod','min','max','count','firstvalue','lastvalue'};
        OtherMethods = {'Custom','vc'};

        % Default workspace dropdown value
        SelectVariable = 'select variable';
        % numel to trigger turning off AutoRun
        AutoRunCutOff = 1e6;
    end

    properties
        State
        Workspace = "base"
    end

    % Write over constructor so we can keep this API with dataCleaner app
    methods (Access = public)
        function app = retimeSynchEmbedder(fig,workspace)
            arguments
                fig = uifigure;
                workspace = "base";
            end
            app@matlab.task.LiveTask("Parent",fig);
            app.UIFigure = fig;
            app.Workspace = workspace;
        end
    end

    % setup required by base class
    methods (Access = protected)
        function setup(app)
            createComponents(app);
            doUpdate(app);
        end
    end

    % internal app methods
    methods (Access = protected)
        function createComponents(app)
            % Create the ui components and lay them out in the figure
            app.LayoutManager.RowHeight = {'fit'};
            app.LayoutManager.ColumnWidth = {'1x'};
            % the grid is split into accordion panels
            app.Accordion = matlab.ui.container.internal.Accordion('Parent',app.LayoutManager);
            createInputDataSection(app);
            createNewTimesSection(app);
            createMethodSection(app);
            createVisualizationSection(app);
            setWidgetsToDefault(app);
        end

        function G = createNewSection(app,textLabel,c,numRows)
            S = matlab.ui.container.internal.AccordionPanel('Parent',app.Accordion);
            S.Title = textLabel;
            G = uigridlayout(S,'ColumnWidth',c,'RowHeight',repmat({app.TextRowHeight},1,numRows));
        end

        function createNewTimesSection(app)
            h = createNewSection(app,getLocalMsg(app,'NewTimesDelimiter'),{'fit' 'fit' 'fit' 'fit'},1);

            % Layout
            uilabel(h,'Text',getLocalMsg(app,'Selectionmethod'));
            app.NewTimesDropdown = uidropdown(h);
            app.BasisTypeDropdown = uidropdown(h);
            app.TimeStepSpinner = uispinner(h);
            app.TimeStepSpinner.Layout.Column = 3;
            app.TimeStepUnits = uidropdown(h);
            app.SampleRateSpinner = uispinner(h);
            app.SampleRateSpinner.Layout.Row = 1;
            app.SampleRateSpinner.Layout.Column = 3;
            app.SampleRateUnits = uidropdown(h);
            app.SampleRateUnits.Layout.Row = 1;
            app.SampleRateUnits.Layout.Column = 4;
            app.NewTimesWorkspaceDropdown = matlab.ui.control.internal.model.WorkspaceDropDown('Parent',h);
            app.NewTimesWorkspaceDropdown.Layout.Row = 1;
            app.NewTimesWorkspaceDropdown.Layout.Column = 3;

            % Properties
            app.NewTimesDropdown.ValueChangedFcn = @app.doUpdate;
            app.BasisTypeDropdown.ValueChangedFcn = @app.doUpdate;
            app.TimeStepSpinner.Limits = [0 inf];
            app.TimeStepSpinner.LowerLimitInclusive = false;
            app.TimeStepSpinner.UpperLimitInclusive = false;
            app.TimeStepSpinner.ValueChangedFcn = @app.doUpdate;
            app.TimeStepSpinner.Tag = 'TimeStepSpinner';
            app.TimeStepUnits.ValueChangedFcn = @app.doUpdate;
            app.TimeStepUnits.Tag = 'TimeStepUnits';
            app.SampleRateSpinner.Limits = [0 inf];
            app.SampleRateSpinner.LowerLimitInclusive = false;
            app.SampleRateSpinner.UpperLimitInclusive = false;
            app.SampleRateSpinner.ValueChangedFcn = @app.doUpdate;
            app.SampleRateSpinner.Tag = 'SampleRateSpinner';
            app.SampleRateUnits.Items = {'kHz','Hz','mHz'};
            app.SampleRateUnits.ItemsData = [1000,1,1/1000];
            app.SampleRateUnits.ValueChangedFcn = @app.doUpdate;
            app.SampleRateUnits.Tag = 'SampleRateUnits';
            app.NewTimesWorkspaceDropdown.FilterVariablesFcn = @app.filterNewTimes;
            app.NewTimesWorkspaceDropdown.ValueChangedFcn = @app.doUpdate;
            app.NewTimesWorkspaceDropdown.ShowNonExistentVariable = true;
        end

        function isSupported = filterNewTimes(app,newTimes)
            % verify data is still in workspace
            checkForClearedVariables(app);
            if ~hasInputData(app)
                isSupported = false;
                return
            end

            % class must match time vector for input timetable
            firstNonEmptyDD = find(~strcmp({app.TableDropDowns.Value},app.SelectVariable),1);
            supportedClass = class(app.TableDropDowns(firstNonEmptyDD).WorkspaceValue.Properties.RowTimes);
            isSupported = isa(newTimes,supportedClass) && ~isempty(newTimes) && ...
                isvector(newTimes) && issorted(newTimes,'strictmonotonic');
        end

        function createMethodSection(app)
            h = createNewSection(app,getLocalMsg(app,'MethodDelimiter'),...
                {'fit' 2*app.DropDownWidth+10 'fit' 'fit'},3);
            h.RowHeight{3} = 'fit';

            % Row 1, global method
            uilabel(h,'Text',getLocalMsg(app,'MethodType'));
            app.MethodTypeDropdown = uidropdown(h);
            app.ConstantSpinner = uispinner(h);
            app.CustomAggFcnSelector = matlab.internal.dataui.FunctionSelector(h);
         
            app.MethodTypeDropdown.ValueChangedFcn = @app.doUpdate;
            app.MethodTypeDropdown.Tag = 'globalMethodChange';
            app.ConstantSpinner.ValueChangedFcn = @app.doUpdate;
            app.ConstantSpinner.Tag = 'ConstantSpinner';
            app.CustomAggFcnSelector.ValueChangedFcn = @app.doUpdate;
            app.CustomAggFcnSelector.Tooltip = getLocalMsg(app,'CustomAggFcnTooltip');
            app.CustomAggFcnSelector.NewFcnName = 'customAggregator';
            % Create default aggregation function based on which task is used
            app.CustomAggFcnSelector.NewFcnText = [newline ...
                'function y = customAggregator(x)' newline ...
                '% ' char(getLocalMsg(app,'CustomFunctionCodeComment','x')) newline ...
                '% ' char(getLocalMsg(app,'NewFcnTxtComment2','y','x')) newline ...
                newline...
                '% ' char(getLocalMsg(app,'NewFcnTxtComment1')) newline ...
                'if ~isempty(x)' newline...
                '     y = max(x) - min(x);' newline...
                'else' newline...
                '    % ' char(getLocalMsg(app,'NewFcnTxtComment3')) newline...
                '    y = missing;' newline...
                'end' newline...
                'end' newline];

            app.CustomAggFcnSelector.Layout.Row = 1;
            app.CustomAggFcnSelector.Layout.Column = 3;

            % Row 2, overrides
            L = uilabel(h,'Text',getLocalMsg(app,'Overrides'));
            L.Layout.Row = 2;
            L.Layout.Column = 1;
            % This add button gets its own grid so it doesn't have to be
            % the same width as the dropdown above it
            app.OverrideAddButtonHolder = uigridlayout(h,[1 1],'Padding',0,'ColumnWidth',{'fit'});
            app.FirstAddButton = uibutton(app.OverrideAddButtonHolder,'Text',getLocalMsg(app,'Add'),...
                'ButtonPushedFcn',@app.addOverrideRow,'Tooltip',getLocalMsg(app,'AddOverrideTooltip'));

            app.OverrideGrid = uigridlayout(h,'RowHeight',{0},'Padding',0);
            app.OverrideGrid.Layout.Column = [2 4];
            app.OverrideGrid.Layout.Row = [2 3];
            setOverrideGridColumnWidth(app);
        end

        function createVisualizationSection(app)
            h = createNewSection(app,getCommonMsg(app,'Visualizeresults'),{'fit' 'fit'},1);

            app.InputTablesCheckbox = uicheckbox(h,...
                'Text', inputDataName(app),...
                'ValueChangedFcn',@app.doUpdate);
            app.OutputTableCheckbox = uicheckbox(h,...
                'Text', getLocalMsg(app,'Outputtimetable'),...
                'ValueChangedFcn',@app.doUpdate);
        end

        function addOverrideRow(app,~,~,fromMethodChange)
            if app.NumOverrides >= app.MaxOverrides
                % this protects against clicking an override plus button
                % too quickly. If we get here, it means a user clicked an
                % add button just before it became invisible
                return
            end
            if nargin < 4
                fromMethodChange = false;
            end
            if ~fromMethodChange
                % verify data is still in workspace
                if checkForClearedVariables(app)
                    setWidgetsToDefault(app);
                    doUpdate(app);
                    return
                end
            end

            % add widgets
            app.NumOverrides = app.NumOverrides + 1;
            hasTTColumn = app.NumInputTables > 1;
            if hasTTColumn
                addOverrideDropdownTT(app);
            end

            app.OverrideDropdownsVar(app.NumOverrides) = uidropdown(app.OverrideGrid,'Items',{},...
                'ValueChangedFcn',@app.doUpdate,'Tag','OverrideVarChange','UserData',app.NumOverrides,...
                'Tooltip',getLocalMsg(app,'OverrideVarTooltip'));
            app.OverrideDropdownsVar(app.NumOverrides).Layout.Row = app.NumOverrides;
            app.OverrideDropdownsVar(app.NumOverrides).Layout.Column = 1+hasTTColumn;

            app.OverrideDropdownsMethods(app.NumOverrides) = uidropdown(app.OverrideGrid,...
                'Items',{},'ValueChangedFcn',@app.doUpdate);
            app.OverrideDropdownsMethods(app.NumOverrides).Layout.Row = app.NumOverrides;
            app.OverrideDropdownsMethods(app.NumOverrides).Layout.Column = 2+hasTTColumn;

            app.OverrideSubtractButtons(app.NumOverrides) = uiimage(app.OverrideGrid,'ScaleMethod','none',...
                'ImageClickedFcn',@app.subtractOverrideRow,'UserData',app.NumOverrides,...
                'Tooltip',getLocalMsg(app,'SubtractOverrideTooltip'));
            matlab.ui.control.internal.specifyIconID(app.OverrideSubtractButtons(app.NumOverrides),...
                'minusUI',app.IconColumnWidth,app.IconColumnWidth);
            app.OverrideSubtractButtons(app.NumOverrides).Layout.Row = app.NumOverrides;
            app.OverrideSubtractButtons(app.NumOverrides).Layout.Column = 3+hasTTColumn;

            app.OverrideAddButtons(app.NumOverrides) = uiimage(app.OverrideGrid,'ScaleMethod','none',...
                'ImageClickedFcn',@app.addOverrideRow,...
                'Tooltip',getLocalMsg(app,'AddAnotherOverrideTooltip'));
            matlab.ui.control.internal.specifyIconID(app.OverrideAddButtons(app.NumOverrides),...
                'plusUI',app.IconColumnWidth,app.IconColumnWidth);
            app.OverrideAddButtons(app.NumOverrides).Layout.Row = app.NumOverrides;
            app.OverrideAddButtons(app.NumOverrides).Layout.Column = 4+hasTTColumn;

            if ~fromMethodChange
                populateOverrideDropdownsVar(app);
                populateOverrideDropdownsMethod(app,app.NumOverrides);
                updateOverrideLocations(app);
                app.doUpdate;
            end
        end

        function subtractOverrideRow(app,src,~)
            if checkForClearedVariables(app)
                setWidgetsToDefault(app);
                doUpdate(app);
                return
            end
            app.NumOverrides = app.NumOverrides - 1;

            % delete the widgets in the row
            rowToDelete = src.UserData;
            if app.NumInputTables > 1
                delete(app.OverrideDropdownsTT(rowToDelete));
                app.OverrideDropdownsTT(rowToDelete) = [];
            end
            delete(app.OverrideDropdownsVar(rowToDelete));
            app.OverrideDropdownsVar(rowToDelete) = [];
            delete(app.OverrideDropdownsMethods(rowToDelete));
            app.OverrideDropdownsMethods(rowToDelete) = [];
            delete(app.OverrideSubtractButtons(rowToDelete));
            app.OverrideSubtractButtons(rowToDelete) = [];
            delete(app.OverrideAddButtons(rowToDelete));
            app.OverrideAddButtons(rowToDelete) = [];

            for k = rowToDelete : app.NumOverrides
                % shift everything else up
                app.OverrideDropdownsVar(k).Layout.Row = k;
                app.OverrideDropdownsMethods(k).Layout.Row = k;
                app.OverrideSubtractButtons(k).Layout.Row = k;
                app.OverrideAddButtons(k).Layout.Row = k;
                % update the userdata to new row
                app.OverrideDropdownsVar(k).UserData = k;
                app.OverrideSubtractButtons(k).UserData = k;

                if app.NumInputTables > 1
                    app.OverrideDropdownsTT(k).Layout.Row = k;
                    app.OverrideDropdownsTT(k).UserData = k;
                end
            end

            % make sure the items get added back in to other dds
            if app.NumInputTables > 1 && app.NumOverrides > 0
                populateOverrideDropdownsTT(app);
            end
            populateOverrideDropdownsVar(app);
            updateOverrideLocations(app);
            % don't need to redo method dd since this shouldn't change
            % existing dd values, just potentially add items
            app.doUpdate;
        end

        function setHeightForOverrideGrid(app)
            showGrid = app.NumOverrides > 0;
            app.OverrideGrid.Visible = showGrid;
            app.OverrideGrid.RowHeight = repmat({app.TextRowHeight*showGrid},1,max(app.NumOverrides,1));
            if showGrid
                setOverrideGridColumnWidth(app);
                % hide add button column if they aren't visible
                if app.NumOverrides == app.MaxOverrides
                    app.OverrideGrid.ColumnWidth{end} = 0;
                end
            else
                app.OverrideGrid.ColumnWidth = zeros(1,numel(app.OverrideGrid.ColumnWidth));
            end
        end

        function updateDefaultsFromKeyword(app,kw)
            % all keywords that are relevant to changing behavior away from
            % default
            keywords = ["upsample" "downsample"];

            % checks if the input keyword partially matches any target
            % keyword
            kwMatches = startsWith(keywords,kw,'IgnoreCase',true);

            % if not, we don't update anything
            if ~any(kwMatches)
                return;
            end

            app.SampleRateByDefault = true;
            app.NewTimesDropdown.Value = "regularSampleRate";
            doUpdate(app);
        end

        function setWidgetsToDefault(app)
            % set items to default
            resetItemsBasedOnInput(app);

            % set values to default
            setTimeDependentDefaultValues(app);

            if ismember('dedupe',app.NewTimesDropdown.ItemsData)
                app.NewTimesDropdown.Value = 'dedupe';
            elseif app.SampleRateByDefault
                app.NewTimesDropdown.Value = "regularSampleRate";
            elseif ismember('basis',app.NewTimesDropdown.ItemsData)
                app.NewTimesDropdown.Value = 'basis';
            else
                app.NewTimesDropdown.Value = 'regularTimeStep';
            end
            app.BasisTypeDropdown.Value = 'union';
            app.NewTimesWorkspaceDropdown.Value = app.SelectVariable;

            app.ConstantSpinner.Value = 0;
            app.ConstantSpinner.Step = 1;

            % if in app, change custom selector to handle. If not, set to local
            if ~isequal(app.Workspace,'base')
                app.CustomAggFcnSelector.FcnType = 'handle';
            else
                app.CustomAggFcnSelector.FcnType = 'local';
            end
            app.CustomAggFcnSelector.HandleValue = '@sum';
            app.CustomAggFcnSelector.LocalValue = app.SelectVariable;

            resetOverrides(app);
            setMaxNumOverrides(app);

            app.MethodTypeDropdown.Value = 'fillwithmissing';
            triedSum = false;
            if ismember('vc',app.MethodTypeDropdown.ItemsData)
                app.MethodTypeDropdown.Value = 'vc';
            elseif app.NumInputTables == 1
                if ismember('linear',app.MethodTypeDropdown.ItemsData)
                    app.MethodTypeDropdown.Value = 'linear';
                elseif ismember('dedupe',app.NewTimesDropdown.ItemsData) && ...
                        ismember('sum',app.MethodTypeDropdown.ItemsData)
                    app.MethodTypeDropdown.Value = 'sum';
                    triedSum = true;
                end
            end

            % if in app, always suppress output (checkbox is not shown)
            app.OutputTableCheckbox.Value = isequal(app.Workspace,'base');
            app.InputTablesCheckbox.Value = false;

            % check to see if the default method would have required an override
            if hasInputData(app) && autoPopulateOverrides(app,true)
                % find a method that doesn't require an override
                % try fillwithmissing if we haven't already
                if ~isequal(app.MethodTypeDropdown.Value,'fillwithmissing')
                    app.MethodTypeDropdown.Value = 'fillwithmissing';
                    if ~autoPopulateOverrides(app,true)
                        return
                    end
                end
                % try sum if we haven't already
                if ~triedSum
                    app.MethodTypeDropdown.Value = 'sum';
                    if ~autoPopulateOverrides(app,true)
                        return
                    end
                end
                % resign ourselves to count, which errors in the fewest of
                % cases and doesn't override for any datatypes
                app.MethodTypeDropdown.Value = 'count';
            end
        end

        function resetItemsBasedOnInput(app)
            hasInput = hasInputData(app);
            app.IsSortedTimes = true(app.NumInputTables,1);
            firstNonEmptyDD = find(~strcmp({app.TableDropDowns.Value},app.SelectVariable),1);
            isDurationTimes = hasInput && isduration(app.TableDropDowns(firstNonEmptyDD).WorkspaceValue.Properties.RowTimes);
            hasVC = false;

            if hasInput
                for k = 1:app.NumInputTables
                    TT = app.TableDropDowns(k).WorkspaceValue;
                    if ~isempty(TT)
                        %  WorkspaceValue empty means dropdown is 'select'
                        app.IsSortedTimes(k) = app.filterNewTimes(TT.Properties.RowTimes);
                        hasVC = hasVC || ~isempty(TT.Properties.VariableContinuity);
                    end
                end
            end

            % set items to default based on data
            setItemsToFullList(app);
            if ~isequal(app.Workspace,'base')
                % app workflow does not have anything but the timetable in
                % the workspace, so we don't need the 'workspace' option
                app.NewTimesDropdown.Items(end) = [];
                app.NewTimesDropdown.ItemsData(end) = [];
            end

            if app.NumInputTables == 1
                % remove basis (for synchronize only)
                app.NewTimesDropdown.Items(1) = [];
                app.NewTimesDropdown.ItemsData(1) = [];
                if ~hasInput || (numel(unique(TT.Properties.RowTimes)) == height(TT) &&...
                        ~any(ismissing(TT.Properties.RowTimes)))
                    % no dedupe needed either
                    app.NewTimesDropdown.Items(1) = [];
                    app.NewTimesDropdown.ItemsData(1) = [];
                end
            else
                % remove dedupe (for retime only)
                app.NewTimesDropdown.Items(2) = [];
                app.NewTimesDropdown.ItemsData(2) = [];
                if hasInput
                    % need to know actual first and last inputs, given 'select'
                    % may be either
                    indFirst = find(~strcmp({app.TableDropDowns.Value},app.SelectVariable),1,'first');
                    indLast = find(~strcmp({app.TableDropDowns.Value},app.SelectVariable),1,'last');

                    if ~app.IsSortedTimes(indFirst)
                        % remove 'first' option
                        app.BasisTypeDropdown.Items(4) = [];
                        app.BasisTypeDropdown.ItemsData(4) = [];
                    end
                    if ~app.IsSortedTimes(indLast)
                        % remove 'last' option
                        app.BasisTypeDropdown.Items(end) = [];
                        app.BasisTypeDropdown.ItemsData(end) = [];
                    end
                end
            end
            if isDurationTimes
                % remove quarters, months, and weeks
                app.TimeStepUnits.Items(2:4) = [];
                app.TimeStepUnits.ItemsData(2:4) = [];
                % switch from calyears and caldays
                app.TimeStepUnits.ItemsData(1:2) = {'years' 'days'};
                app.NewTimesWorkspaceDropdown.Tooltip = getLocalMsg(app,'NewTimesTooltipDur');
            else
                app.NewTimesWorkspaceDropdown.Tooltip = getLocalMsg(app,'NewTimesTooltipDT');
            end
            if ~hasVC
                % remove VariableContinuity option
                app.MethodTypeDropdown.Items(end) = [];
                app.MethodTypeDropdown.ItemsData(end) = [];
            end
        end

        function setItemsToFullList(app)
            app.NewTimesDropdown.Items = getLocalMsg(app,{'Basis' 'Dedupe' 'Customtimestep' 'Samplerate' 'Selectfromworkspace'});
            app.NewTimesDropdown.ItemsData = {'basis','dedupe','regularTimeStep','regularSampleRate','workspace'};

            app.BasisTypeDropdown.Items = getLocalMsg(app,{'Union' 'Intersection' 'CommonRange' 'First' 'Last'});
            app.BasisTypeDropdown.ItemsData = {'union' 'intersection' 'commonrange' 'first' 'last'};

            app.TimeStepUnits.Items = getCommonMsg(app,{'Years' 'Quarters' 'Months' 'Weeks' ...
                'Days' 'Hours' 'Minutes' 'Seconds' 'Milliseconds'});
            app.TimeStepUnits.ItemsData = {'calyears' 'calquarters' 'calmonths' 'calweeks' ...
                'caldays' 'hours' 'minutes' 'seconds' 'milliseconds'};

            [app.MethodTypeDropdown.Items,app.MethodTypeDropdown.ItemsData] = ...
                getMethodList(app,all(app.IsSortedTimes),false);
        end

        function setTimeDependentDefaultValues(app)
            hasInput = hasInputData(app);
            setGenericDefaults = ~hasInput;
            if hasInput
                timeSteps = [];
                for k = 1:app.NumInputTables
                    if ~strcmp(app.TableDropDowns(k).Value,app.SelectVariable)
                        rowTimes = app.TableDropDowns(k).WorkspaceValue.Properties.RowTimes;
                        rowTimes = rowTimes(~ismissing(rowTimes));
                        if ~app.IsSortedTimes(k) && ~issorted(rowTimes)
                            % Note this issorted check is different from
                            % IsSortedTimes since it allows missing and
                            % dupes. This allows us to still get a
                            % reasonable default TimeStep in such cases
                            setGenericDefaults = true;
                            break
                        end
                        timeSteps = [timeSteps;abs(diff(rowTimes))];
                    end
                end
                avgStepInSec = seconds(mean(timeSteps));
                setGenericDefaults = setGenericDefaults || ~isfinite(avgStepInSec) || avgStepInSec == 0;
            end

            if setGenericDefaults
                app.TimeStepSpinner.Value = 1;
                app.TimeStepUnits.Value = app.TimeStepUnits.ItemsData{end-4};
                app.SampleRateSpinner.Value = 1;
                app.SampleRateUnits.Value = 1/1000;
            else
                % set time step value/units
                secondsInUnit = [3.1536e7 7776000 2628000 604800 86400 3600 60 1 1/1000];
                if ~ismember('calyears',app.TimeStepUnits.ItemsData)
                    % duration time vector, remove quarters/months/weeks
                    secondsInUnit(2:4) = [];
                end

                index = find(avgStepInSec > secondsInUnit,1);
                if isempty(index)
                    % avg time step is smaller than 1/1000 sec, set ms
                    index = numel(secondsInUnit);
                end
                app.TimeStepUnits.Value = app.TimeStepUnits.ItemsData{index};
                % calendar durations need to be whole numbers
                doRound = startsWith(app.TimeStepUnits.Value,'cal');
                % make sure step size is a whole number before setting RoundFractionalValues
                app.TimeStepSpinner.Step = 1;
                % set RoundFractionalValues before Value so Value doesn't get unnecessarily rounded
                app.TimeStepSpinner.RoundFractionalValues = doRound;
                app.TimeStepSpinner.Value = round(avgStepInSec/secondsInUnit(index),2,'significant');
                % now that we have the value, we can set the step size
                app.TimeStepSpinner.Step = matlab.internal.dataui.getStepSize(...
                    app.TimeStepSpinner.Value,doRound);

                % set sample rate value/units
                sampleRateInHz = 1/avgStepInSec;
                if sampleRateInHz < .1
                    % use mHz
                    app.SampleRateSpinner.Value = round(sampleRateInHz*1000,2,'significant');
                    app.SampleRateUnits.Value = 1/1000;
                elseif sampleRateInHz > 500
                    % use kHz
                    app.SampleRateSpinner.Value = round(sampleRateInHz/1000,2,'significant');
                    app.SampleRateUnits.Value = 1000;
                else
                    % Hz
                    app.SampleRateSpinner.Value = round(sampleRateInHz,2,'significant');
                    app.SampleRateUnits.Value = 1;
                end
                app.SampleRateSpinner.Step = matlab.internal.dataui.getStepSize(...
                    app.SampleRateSpinner.Value,false);
            end
        end

        function didClear = checkForClearedVariables(app)
            % check for input variables to be cleared
            isClearedVar = cellfun(@isempty,{app.TableDropDowns.WorkspaceValue}) & ...
                ~strcmp({app.TableDropDowns.Value},app.SelectVariable);
            [app.TableDropDowns(isClearedVar).Value] = deal(app.SelectVariable);
            didClear = any(isClearedVar);

            % check for new times to be cleared (don't need to reset task
            % in this case)
            if isempty(app.NewTimesWorkspaceDropdown.WorkspaceValue)
                app.NewTimesWorkspaceDropdown.Value = app.SelectVariable;
            end
        end

        function doUpdate(app,src,event)

            didClear = nargin > 1 && checkForClearedVariables(app);
            hasInput = hasInputData(app);

            if didClear
                setWidgetsToDefault(app);
            elseif ~hasInput
                if nargin > 1 && app.NumInputTables == 2 && isequal(src,app.TableDropDowns(1)) && ...
                        ~isequal(app.TableDropDowns(1).Value,app.SelectVariable)
                    % In synchronize, tt1 has just been selected and tt2 is unset.
                    % If only one valid selection available for tt2, choose it.
                    app.TableDropDowns(2).populateVariables();
                    if numel(app.TableDropDowns(2).Items) == 2
                        app.TableDropDowns(2).Value = app.TableDropDowns(2).Items{2};
                        hasInput = true;
                        setAutoRun(app);
                    end
                end
                setWidgetsToDefault(app);
            elseif nargin > 1
                if isequal(src.Tag,'Input change')
                    setWidgetsToDefault(app);
                    setAutoRun(app);
                elseif isequal(src.Tag,'TimeStepSpinner')
                    % reset step size
                    app.TimeStepSpinner.Step = matlab.internal.dataui.getStepSize(...
                        app.TimeStepSpinner.Value,...
                        app.TimeStepSpinner.RoundFractionalValues,event.PreviousValue);
                elseif isequal(src.Tag,'TimeStepUnits')
                    % in case we have changed to a unit that requires
                    % rounding, need to reset the step size BEFORE setting
                    % RoundFractionalValues
                    doRound = startsWith(app.TimeStepUnits.Value,'cal');
                    if doRound
                        app.TimeStepSpinner.Step = matlab.internal.dataui.getStepSize(...
                            app.TimeStepSpinner.Value,doRound);
                    end
                elseif isequal(src.Tag,'SampleRateSpinner')
                    % reset step size
                    app.SampleRateSpinner.Step = matlab.internal.dataui.getStepSize(...
                        app.SampleRateSpinner.Value,false,event.PreviousValue);
                elseif isequal(src.Tag,'SampleRateUnits')
                    % convert so value + units are unchanged
                    app.SampleRateSpinner.Value = round(app.SampleRateSpinner.Value*(event.PreviousValue/src.Value),15,'significant');
                    app.SampleRateSpinner.Step = matlab.internal.dataui.getStepSize(...
                        app.SampleRateSpinner.Value,false);
                elseif isequal(src.Tag,'ConstantSpinner')
                    % reset step size
                    app.ConstantSpinner.Step = matlab.internal.dataui.getStepSize(...
                        app.ConstantSpinner.Value,false,event.PreviousValue);
                elseif isequal(src.Tag,'OverrideTTChange')
                    % update variable dropdown items
                    populateOverrideDropdownsTT(app);
                    populateOverrideDropdownsVar(app);
                    populateOverrideDropdownsMethod(app,src.UserData);
                    updateOverrideLocations(app);
                elseif isequal(src.Tag,'OverrideVarChange')
                    populateOverrideDropdownsVar(app);
                    populateOverrideDropdownsMethod(app,src.UserData);
                    updateOverrideLocations(app);
                elseif isequal(src.Tag,'globalMethodChange')
                    % see if we need to auto-add overrides based on
                    % new global method
                    if ~isequal(app.Workspace,'base')
                        % exceptions interface is not shown, need to reset
                        % with each method change
                        resetOverrides(app)
                    end
                    autoPopulateOverrides(app);
                    updateOverrideLocations(app);
                end
            end

            % input section
            if app.NumInputTables > 1
                updateInputSection(app,hasInput);
            end

            % new times section
            % set Enable for all widgets
            app.NewTimesDropdown.Enable = hasInput;
            app.BasisTypeDropdown.Enable = hasInput;
            app.TimeStepSpinner.Enable = hasInput;
            app.TimeStepUnits.Enable = hasInput;
            app.SampleRateSpinner.Enable = hasInput;
            app.SampleRateUnits.Enable = hasInput;
            app.NewTimesWorkspaceDropdown.Enable = hasInput;
            % toggle visibility for all but the main dropdown
            app.BasisTypeDropdown.Visible = isequal(app.NewTimesDropdown.Value,'basis');
            app.TimeStepSpinner.Visible = isequal(app.NewTimesDropdown.Value,'regularTimeStep');
            app.TimeStepUnits.Visible = isequal(app.NewTimesDropdown.Value,'regularTimeStep');
            app.SampleRateSpinner.Visible = isequal(app.NewTimesDropdown.Value,'regularSampleRate');
            app.SampleRateUnits.Visible = isequal(app.NewTimesDropdown.Value,'regularSampleRate');
            app.NewTimesWorkspaceDropdown.Visible = isequal(app.NewTimesDropdown.Value,'workspace');
            % to get correct fit width, unparent all but appropriate widgets
            matlab.internal.dataui.setParentForWidgets([app.BasisTypeDropdown app.TimeStepSpinner...
                app.SampleRateSpinner app.NewTimesWorkspaceDropdown app.TimeStepUnits...
                app.SampleRateUnits],app.NewTimesDropdown.Parent)
            % for calendarDurations, cannot have fractional values
            app.TimeStepSpinner.RoundFractionalValues = startsWith(app.TimeStepUnits.Value,'cal');

            % method section
            % set Enable for all widgets
            app.MethodTypeDropdown.Enable = hasInput;
            app.ConstantSpinner.Enable = hasInput;
            app.CustomAggFcnSelector.Enable = hasInput;
            % toggle visibility for all but the main dropdown
            app.ConstantSpinner.Visible = isequal(app.MethodTypeDropdown.Value,'fillwithconstant');
            app.CustomAggFcnSelector.Visible = isequal(app.MethodTypeDropdown.Value,'Custom');
            matlab.internal.dataui.setParentForWidgets([app.ConstantSpinner app.CustomAggFcnSelector], app.MethodTypeDropdown.Parent)
            % set dynamic tooltips
            app.MethodTypeDropdown.Tooltip = getLocalMsg(app,['Tooltip' app.MethodTypeDropdown.Value]);

            % override section
            app.FirstAddButton.Visible = (app.NumOverrides == 0);
            app.FirstAddButton.Enable = hasInput;
            % note if we don't have input, there are no override widgets,
            % so no need to set enable/visible of these
            [app.OverrideAddButtons.Visible] = deal(app.NumOverrides < app.MaxOverrides);
            setHeightForOverrideGrid(app);
            for k = 1:app.NumOverrides
                % dynamic tooltips for method dropdowns
                app.OverrideDropdownsMethods(k).Tooltip = getLocalMsg(app,['Tooltip' app.OverrideDropdownsMethods(k).Value]);
            end

            % visualize section
            app.OutputTableCheckbox.Enable = hasInput;
            app.InputTablesCheckbox.Enable = hasInput;

            % needed in case this came from a dynamically created widget
            notify(app,'StateChanged');
        end

        function populateOverrideDropdownsMethod(app,k)
            if app.NumInputTables == 1
                T = evalin(app.Workspace,app.TableDropDowns.Value);
            else
                T = evalin(app.Workspace,app.OverrideDropdownsTT(k).Value);
            end
            var = T.(app.OverrideDropdownsVar(k).Value);

            if app.NumInputTables > 1
                isSorted = app.IsSortedTimes(strcmp({app.TableDropDowns.Value},app.OverrideDropdownsTT(k).Value));
            else
                isSorted = app.IsSortedTimes;
            end
            [items,itemsData] = getMethodList(app,isSorted,true);

            if ~(isfloat(var) || isdatetime(var) || isduration(var))
                items = setdiff(items,getLocalMsg(app,app.InterpMethods),'stable');
                itemsData = setdiff(itemsData,app.InterpMethods,'stable');
            end
            if ~(isnumeric(var) || isduration(var))
                items = setdiff(items,{getLocalMsg(app,'sum')},'stable');
                itemsData = setdiff(itemsData,{'sum'},'stable');
            end
            if ~(isnumeric(var) || isdatetime(var) || isduration(var))
                items = setdiff(items,{getLocalMsg(app,'mean')},'stable');
                itemsData = setdiff(itemsData,{'mean'},'stable');
            end
            if ~isnumeric(var)
                items = setdiff(items,{getLocalMsg(app,'prod')},'stable');
                itemsData = setdiff(itemsData,{'prod'},'stable');
            end
            if ~(isnumeric(var) || isdatetime(var) || isduration(var) || (iscategorical(var) && isordinal(var)))
                items = setdiff(items,getLocalMsg(app,{'max' 'min'}),'stable');
                itemsData = setdiff(itemsData,{'max' 'min'},'stable');
            end
            if ~(isfloat(var) || isdatetime(var) || isduration(var) || iscategorical(var) || ...
                    isstring(var) || iscellstr(var) || ischar(var))
                items = setdiff(items,{getLocalMsg(app,'fillwithmissing')},'stable');
                itemsData = setdiff(itemsData,{'fillwithmissing'},'stable');
            end

            app.OverrideDropdownsMethods(k).Items = items;
            app.OverrideDropdownsMethods(k).ItemsData = itemsData;
        end

        function neededOverride = autoPopulateOverrides(app,checkOnly)
            % if checkOnly, then we won't actually populate, just check to see
            %    if we would need to with the currently selected general method
            % if not checkOnly, then we do actually populate overrides
            %    based on the general method
            if nargin < 2
                checkOnly = false;
            end
            if ismember(app.MethodTypeDropdown.Value,{'fillwithconstant' 'prod'})
                filterFcn = @isnumeric;
            elseif ismember(app.MethodTypeDropdown.Value,app.InterpMethods)
                filterFcn = @(x) isfloat(x) || isduration(x) || isdatetime(x);
            elseif isequal(app.MethodTypeDropdown.Value,'mean')
                filterFcn = @(x) isnumeric(x) || isduration(x) || isdatetime(x);
            elseif isequal(app.MethodTypeDropdown.Value,'sum')
                filterFcn = @(x) isnumeric(x) || isduration(x);
            elseif ismember(app.MethodTypeDropdown.Value,{'min' 'max'})
                filterFcn = @(x) isnumeric(x) || isduration(x) || isdatetime(x) ||...
                    (iscategorical(x) && isordinal(x));
            elseif isequal(app.MethodTypeDropdown.Value,'fillwithmissing')
                filterFcn = @(x) isfloat(x) || isdatetime(x) || isduration(x) || iscategorical(x) || ...
                    isstring(x) || iscellstr(x) || ischar(x);
            else
                neededOverride = false;
                return
            end
            neededOverride = localAutoPopulateOverrides(app,filterFcn,checkOnly);
        end

        function setMaxNumOverrides(app)
            maxOverrides = 0;
            if hasInputData(app)
                for k = 1:app.NumInputTables
                    TT = app.TableDropDowns(k).WorkspaceValue;
                    if ~isempty(TT)
                        maxOverrides = maxOverrides + width(TT);
                    end
                end
            end
            app.MaxOverrides = maxOverrides;
        end

        function code = finishGeneratingGlobalCommand(app,code)
            if isequal(app.Workspace,'base')
                tick = '`';
            else
                tick = '';
            end

            % add new times
            if isequal(app.NewTimesDropdown.Value,'basis')
                code = matlab.internal.dataui.addCharToCode(code,['"' app.BasisTypeDropdown.Value '"']);
            elseif startsWith(app.NewTimesDropdown.Value,'regular')
                code = matlab.internal.dataui.addCharToCode(code,'"regular"');
            elseif isequal(app.NewTimesDropdown.Value,'dedupe')
                code = matlab.internal.dataui.addCharToCode(code,...
                    ['unique(rmmissing(' tick app.TableDropDowns.Value tick '.Properties.RowTimes))']);
            else % Select from workspace
                code = matlab.internal.dataui.addCharToCode(code,[tick app.NewTimesWorkspaceDropdown.Value tick]);
            end

            % add method
            if isequal(app.MethodTypeDropdown.Value,'Custom')
                % note: at this point it is known that the selector value is non-empty
                code = matlab.internal.dataui.addCharToCode(code,[',' app.CustomAggFcnSelector.Value]);
            elseif ~isequal(app.MethodTypeDropdown.Value,'vc')
                % note: 'vc' is default, so do not need to specify
                code = matlab.internal.dataui.addCharToCode(code,[',"' app.MethodTypeDropdown.Value '"']);
            end

            % add regular timestep/samplerate
            if isequal(app.NewTimesDropdown.Value,'regularTimeStep')
                code = matlab.internal.dataui.addCharToCode(code,[',TimeStep=' app.TimeStepUnits.Value '(' num2str(app.TimeStepSpinner.Value,'%.16g') ')']);
            elseif isequal(app.NewTimesDropdown.Value,'regularSampleRate')
                % note we must convert sample rate to Hz for the API
                code = matlab.internal.dataui.addCharToCode(code,[',SampleRate=' num2str(app.SampleRateSpinner.Value*app.SampleRateUnits.Value,'%.15g')]);
            end

            % and Constant NV pair
            if isequal(app.MethodTypeDropdown.Value,'fillwithconstant') && app.ConstantSpinner.Value ~= 0
                code = matlab.internal.dataui.addCharToCode(code,[',Constant=' num2str(app.ConstantSpinner.Value,'%.16g')]);
            end

            code = [code ')'];
        end

        function method = getMethodForSummary(app)
            if ismember(app.MethodTypeDropdown.Value,app.FillMethods)
                method =  getLocalMsg(app,'SummaryMethodFill');
            elseif ismember(app.MethodTypeDropdown.Value,app.InterpMethods)
                method = getLocalMsg(app,'SummaryMethodInterp');
            elseif ismember(app.MethodTypeDropdown.Value, [app.AggMethods {'Custom'}])
                method = getLocalMsg(app,'SummaryMethodAggregate');
            else % 'vc'
                method = getLocalMsg(app,'SummaryMethodVariableContinuity');
            end
        end

        function addOverrideDropdownForSetState(app,state,k,DDName,col,tag)
            DDName = ['OverrideDropdowns' DDName];
            app.(DDName)(k) = uidropdown(app.OverrideGrid,'ValueChangedFcn',@app.doUpdate,...
                'Tag',tag,'UserData',k);
            app.(DDName)(k).Layout.Row = k;
            app.(DDName)(k).Layout.Column = col;
            if isequal(DDName,'OverrideDropdownsVar')
                app.(DDName)(k).Tooltip = getLocalMsg(app,'OverrideVarTooltip');
            elseif isequal(DDName,'OverrideDropdownsTT')
                app.(DDName)(k).Tooltip = getLocalMsg(app,'OverrideTTTooltip');
            end
            if isfield(state,[DDName 'Items' num2str(k)])
                items = state.([DDName 'Items' num2str(k)]);
                app.(DDName)(k).Items = items;

                if isfield(state,[DDName 'ItemsData' num2str(k)])
                    app.(DDName)(k).ItemsData = state.([DDName 'ItemsData' num2str(k)]);
                end

                if isfield(state,[DDName 'Value' num2str(k)])
                    val = state.([DDName 'Value' num2str(k)]);
                    app.(DDName)(k).Value = val;
                end
            end
        end
    end

    methods (Abstract,Access = protected)
        createInputDataSection(app)
        setOverrideGridColumnWidth(app)
        name = inputDataName(app)
        resetOverrides(app)
        neededOverride = localAutoPopulateOverrides(app,filterFcn,checkOnly)
        hasInput = hasInputData(app)
        populateOverrideDropdownsVar(app)
        setAutoRun(app)
        [code,outputs,info] = generateScriptSetupAndInputs(app,overwriteInput)
        code = generateOverrideScript(app,code,outputs,doClear,info)
        updateOverrideLocations(app)
    end

    methods (Access = public)
        % methods required for embedding in a Live Script
        function reset(app,~,~)
            checkForClearedVariables(app);
            setWidgetsToDefault(app);
            doUpdate(app);
        end

        function code = generateVisualizationScript(app)
            code = '';
            if ~hasInputData(app) || ...
                    (isequal(app.NewTimesDropdown.Value,'workspace') && ...
                    isequal(app.NewTimesWorkspaceDropdown.Value,app.SelectVariable)) || ...
                    ((~app.OutputTableCheckbox.Value || app.NumOverrides == 0) && ...
                    ~app.InputTablesCheckbox.Value) || ...
                    (isequal(app.MethodTypeDropdown.Value,'Custom') && ...
                    isempty(app.CustomAggFcnSelector.Value))
                return
            end

            code = ['% ' getCommonMsg(app,'Visualizeresults')];

            if app.InputTablesCheckbox.Value
                for k = 1:app.NumInputTables
                    if ~isequal(app.TableDropDowns(k).Value,app.SelectVariable)
                        code = [code newline '`' app.TableDropDowns(k).Value '`']; %#ok<*AGROW>
                    end
                end
            end
            if app.OutputTableCheckbox.Value
                code = [code newline 'newTimetable'];
            end
        end

        function [code,outputs] = generateCode(app)
            [code,outputs] = generateScript(app);
            vcode = generateVisualizationScript(app);
            if ~isempty(vcode)
                code = [code newline newline vcode];
            end
        end

        function [code, outputs] = generateScript(app,isForExport,overwriteInput)
            if nargin < 2
                % Second input is for "cleaned up" export code. E.g., don't
                % introduce temp vars for plotting.
                isForExport = false;
            end
            if nargin < 3
                % Third input is for whether or not we want to overwrite
                % the input with the output
                overwriteInput = isForExport;
            end
            code = '';
            outputs = {};
            if overwriteInput && ~isForExport
                % overwriting input is only supported for export script
                return
            end
            % make sure we have enough info to generate code
            if ~hasInputData(app) || ...
                    (isequal(app.NewTimesDropdown.Value,'workspace') && ...
                    isequal(app.NewTimesWorkspaceDropdown.Value,app.SelectVariable))
                return
            end

            % live task should return code when waiting on a local function
            if isequal(app.MethodTypeDropdown.Value,'Custom') && isempty(app.CustomAggFcnSelector.Value)
                code = ['disp("' char(getLocalMsg(app,'CustomAggFcnTooltip')) '")'];
                return
            end

            [code,outputs,info] = generateScriptSetupAndInputs(app,overwriteInput);
            code = finishGeneratingGlobalCommand(app,code);

            hasOverrides = app.NumOverrides > 0;
            if hasOverrides
                code = generateOverrideScript(app,code,outputs,~isForExport,info);
            elseif app.InputTablesCheckbox.Value || ~app.OutputTableCheckbox.Value
                code = [code ';'];
            end
        end

        function setTaskState(app,state,updatedWidget)
            % With nargin = 2, setTaskState is used for save/load/undo/redo
            % With nargin = 3, setTaskState is used by the App to change
            % the value of a control from the property inspector
            if nargin < 3
                updatedWidget = '';
            end
            event = struct();
            if matches(updatedWidget,{'TimeStepSpinner' 'SampleRateSpinner'...
                    'ConstantSpinner' 'SampleRateUnits' 'CustomAggFcnSelector'})
                % for these controls, the doUpdate requires the
                % PreviousValue to make the appropriate update
                event.PreviousValue = app.(updatedWidget).Value;
            elseif isequal(updatedWidget,'FirstTableDropDown') && isfield(state,'FirstTimetableValue')
                % First input has changed, reset the rest
                state.NumInputTimetables = 2;
                state.TableInputs = {state.FirstTimetableValue app.SelectVariable};
            elseif isequal(updatedWidget,'TableDropDowns') && isfield(state,'TableInputsForApp')
                state.TableInputs = [{state.FirstTimetableValue} state.TableInputsForApp];
                state.NumInputTimetables = numel(state.TableInputs);
                if isempty(state.TableInputsForApp)
                    % Coming from synchronize in app with not enough values
                    % selected in the multiselect dropdown. Need to set at
                    % least one input to 'select'
                    state.TableInputs{2} = app.SelectVariable;
                    state.NumInputTimetables = 2;
                end
            end

            if ~isfield(state,'VersionSavedFrom')
                state.VersionSavedFrom = 1;
                state.MinCompatibleVersion = 1;
            end
            if app.Version < state.MinCompatibleVersion
                % state comes from a future, incompatible version
                % do not set any properties
                doUpdate(app);
            else
                % set input section
                hasNumInputTimetables = isfield(state,'NumInputTimetables');
                if  hasNumInputTimetables || isfield(state,'NumInputTables')
                    if hasNumInputTimetables
                        app.NumInputTables = state.NumInputTimetables;
                    else
                        % comes from an older version
                        app.NumInputTables = state.NumInputTables;
                    end
                    % add or delete input rows as needed
                    for k = numel(app.TableDropDowns)+1 : app.NumInputTables
                        createInputRow(app,k);
                    end
                    for k = numel(app.TableDropDowns): -1 :app.NumInputTables+1
                        % go in reverse order to avoid extra copying
                        deleteInputRow(app,k)
                    end
                end
                hasTableInputsField = isfield(state,'TableInputs');
                if hasTableInputsField || isfield(state,'TableDropDownsValues')
                    if hasTableInputsField
                        % comes from version 4 or later, length == numinputs
                        ddValues = cellstr(state.TableInputs);
                    else
                        % comes from version 3 or earlier, length == 5
                        ddValues = cellstr(state.TableDropDownsValues);
                    end
                    for k = 1:app.NumInputTables
                        app.TableDropDowns(k).Value = ddValues{k};
                    end
                end
                % set other workspace dropdown
                if isfield(state,'NewTimesWorkspaceDropdownValue')
                    app.NewTimesWorkspaceDropdown.Value = state.NewTimesWorkspaceDropdownValue;
                end

                % set items and itemsData
                % get the full translated lists
                setItemsToFullList(app);
                for k = ["NewTimesDropdown" "BasisTypeDropdown" "TimeStepUnits"]
                    if isfield(state,k + "ItemsData")
                        % Trim down translated list to saved itemsdata.
                        % This preserves underlying values but gets latest
                        % translation.
                        [~,ind] = ismember(state.(k + "ItemsData"),app.(k).ItemsData);
                        if any(ind == 0)
                            % time step units need to be updated: e.g.
                            % calyears -> years
                            items = strrep(app.(k).ItemsData,'cal','');
                            [~,ind] = ismember(state.(k + "ItemsData"),items);
                            app.(k).ItemsData = items(ind);
                        else
                            app.(k).ItemsData = app.(k).ItemsData(ind);
                        end
                        app.(k).Items = app.(k).Items(ind);
                    end
                end
                % set updated default flag
                if isfield(state, 'SampleRateByDefault')
                    app.SampleRateByDefault = state.SampleRateByDefault;
                end
                % set values
                if isfield(state,'SampleRateUnitsValue')
                    % data cleaner app can change value to string
                    app.SampleRateUnits.Value = double(state.SampleRateUnitsValue);
                end
                for k = ["NewTimesDropdown" "BasisTypeDropdown"...
                        "TimeStepSpinner" "TimeStepUnits" "SampleRateSpinner"...
                        "ConstantSpinner"...
                        "OutputTableCheckbox" "InputTableCheckbox"]
                    if isfield(state,k + "Value")
                        app.(k).Value = state.(k + "Value");
                    end
                end

                if isfield(state,'CustomAggFcnSelectorState')
                    if isequal(updatedWidget,'CustomAggFcnSelector')
                        app.CustomAggFcnSelector.HandleValue = state.AggFcnEditFieldValue;
                    else
                        app.CustomAggFcnSelector.State = state.CustomAggFcnSelectorState;
                    end
                elseif isfield(state,'AggFcnEditFieldValue')
                     % Comes from an older version
                     app.CustomAggFcnSelector.FcnType = 'handle';
                     app.CustomAggFcnSelector.HandleValue = state.AggFcnEditFieldValue;
                end

                % set method (need issortedtimes first)
                if isfield(state,'IsSortedTimes')
                    app.IsSortedTimes = state.IsSortedTimes;
                end
                if isfield(state,'MethodItemsData')
                    app.MethodTypeDropdown.Items = app.getLocalMsg(state.MethodItemsData);
                    app.MethodTypeDropdown.ItemsData = state.MethodItemsData;
                    app.MethodTypeDropdown.Value = state.MethodValue;
                elseif isfield(state,'MethodTypeDropdownValue')
                    % comes from an older version
                    if isequal(state.MethodTypeDropdownValue,'fill')
                        if isfield(state,'FillTypeDropdownValue') && ...
                                ismember(state.FillTypeDropdownValue,app.MethodTypeDropdown.ItemsData)
                            app.MethodTypeDropdown.Value = state.FillTypeDropdownValue;
                        end
                    elseif isequal(state.MethodTypeDropdownValue,'interp')
                        if isfield(state,'InterpolationTypeDropdownValue') && ...
                                ismember(state.InterpolationTypeDropdownValue,app.MethodTypeDropdown.ItemsData)
                            app.MethodTypeDropdown.Value = state.InterpolationTypeDropdownValue;
                        end
                    elseif isequal(state.MethodTypeDropdownValue,'aggregate')
                        if isfield(state,'AggFcnDropdownValue') && ...
                                ismember(state.AggFcnDropdownValue,app.MethodTypeDropdown.ItemsData)
                            app.MethodTypeDropdown.Value = state.AggFcnDropdownValue;
                        end
                    elseif isequal(state.MethodTypeDropdownValue,'vc')
                        app.MethodTypeDropdown.Value = 'vc';
                    end
                end

                % clear out overrides
                resetOverrides(app);
                % set properties
                for k = ["NumOverrides" "MaxOverrides"]
                    if isfield(state,k)
                        app.(k) = state.(k);
                    end
                end
                % add override widgets/set properties
                for k = 1:app.NumOverrides
                    needsTTdd = app.NumInputTables > 1;
                    if needsTTdd
                        addOverrideDropdownForSetState(app,state,k,'TT',1,'OverrideTTChange');
                    end
                    addOverrideDropdownForSetState(app,state,k,'Var',1+needsTTdd,'OverrideVarChange');
                    addOverrideDropdownForSetState(app,state,k,'Methods',2+needsTTdd,'');

                    app.OverrideSubtractButtons(k) = uiimage(app.OverrideGrid,'ScaleMethod','none',...
                        'ImageClickedFcn',@app.subtractOverrideRow,'UserData',k);
                    matlab.ui.control.internal.specifyIconID(app.OverrideSubtractButtons(k),...
                        'deletedStatus',app.IconColumnWidth,app.IconColumnWidth);
                    app.OverrideSubtractButtons(k).Layout.Row = k;
                    app.OverrideSubtractButtons(k).Layout.Column = 3+needsTTdd;

                    app.OverrideAddButtons(k) = uiimage(app.OverrideGrid,'ScaleMethod','none',...
                        'ImageClickedFcn',@app.addOverrideRow);
                    matlab.ui.control.internal.specifyIconID(app.OverrideAddButtons(k),...
                        'addedStatus',app.IconColumnWidth,app.IconColumnWidth);
                    app.OverrideAddButtons(k).Layout.Row = k;
                    app.OverrideAddButtons(k).Layout.Column = 4+needsTTdd;
                end
                if isfield(state,'OverrideLocations')
                    app.OverrideLocations = state.OverrideLocations;
                elseif app.NumOverrides == 0
                    app.OverrideLocations = [];
                elseif app.NumInputTables > 1
                    % synchronize, comes from older version
                    % No way of calculating where the overrides should go
                    % in the output, just pick something that won't error
                    % when trying to generate code. Running code won't
                    % error but may produce out of order timetable
                    app.OverrideLocations = ones(1,app.NumOverrides);
                else
                    % retime, comes from older version use Items in the
                    % first overrides dropdown to find locations. Should
                    % produce the same results
                    [~,app.OverrideLocations] = ismember({app.OverrideDropdownsVar.Value},app.OverrideDropdownsVar(1).Items);
                end

                if app.NumInputTables > 1
                    if isfield(state,'DedupedOverrideNames')
                        app.DedupedOverrideNames = state.DedupedOverrideNames;
                    else
                        % no overrides or comes from old version prior to
                        % this state field. Use override vars and always
                        % append the table name. Creating generated code
                        % won't error, but running it might, but only if
                        % there is a double naming conflict (e.g. var1_tt1
                        % is already a var name)
                        app.DedupedOverrideNames = join([{app.OverrideDropdownsVar.Value};{app.OverrideDropdownsTT.Value}],'_',1);
                    end
                    if isfield(state,"InputIndexingCode")
                        app.InputIndexingCode = state.InputIndexingCode;
                    else
                        % no overrides or comes from old version prior to
                        % this state field. Use default of '' for each
                        % input. Creating generated code won't error, but
                        % running it might if general method errors for
                        % override vars
                        ind = ~strcmp({app.TableDropDowns.Value},app.SelectVariable);
                        inputs = {app.TableDropDowns(ind).Value};
                        app.InputIndexingCode = repmat({''},numel(inputs),1);
                    end
                end
                app.TimeStepSpinner.Step = matlab.internal.dataui.getStepSize(...
                    app.TimeStepSpinner.Value,startsWith(app.TimeStepUnits.Value,'cal'));
                app.SampleRateSpinner.Step = matlab.internal.dataui.getStepSize(...
                    app.SampleRateSpinner.Value,false);
                app.ConstantSpinner.Step = matlab.internal.dataui.getStepSize(...
                    app.ConstantSpinner.Value,false);
                if isempty(updatedWidget)   
                    doUpdate(app);
                elseif isequal(updatedWidget,'FirstTableDropDown')
                    doUpdate(app,app.TableDropDowns(1));
                elseif isequal(updatedWidget,'CustomAggFcnSelector')
                    app.CustomAggFcnSelector.validateFcnHandle(app.CustomAggFcnSelector.HandleEditField,event);
                    doUpdate(app,app.CustomAggFcnSelector,event);
                else
                    doUpdate(app,app.(updatedWidget),event);
                end
            end
        end

        % Methods for data cleaner app
        function propTable = getPropertyInformation(app)
            % propTable is a list of all the controls visible in the Data
            % Cleaner app along with everything needed to map the uifigure
            % into the property inspector. Properties are in the order they
            % should appear in the property inspector

            Name = ["TableDropDowns" "TableDropDowns" "NewTimesDropdown" "BasisTypeDropdown"...
                "TimeStepSpinner" "TimeStepUnits" "SampleRateSpinner" "SampleRateUnits" ...
                "MethodTypeDropdown" "ConstantSpinner" "CustomAggFcnSelector"]';
            if isscalar(app.TableDropDowns)
                dataGroup = string(getCommonMsg(app,'DataDelimiter'));
            else
                dataGroup = string(getLocalMsg(app,'SelectInputTimetables'));
            end
            newTimesGroup = string(getLocalMsg(app,'NewTimesDelimiter'));
            methodGroup = string(getLocalMsg(app,'MethodDelimiter'));
            Group = [repmat(dataGroup,2,1); repmat(newTimesGroup,6,1); repmat(methodGroup,3,1)];
            DisplayName = string(getLocalMsg(app,{'Inputtimetable','AdditionalTimetables','Selectionmethod',...
                'Basis','Customtimestep','TimeStepUnits','Samplerate','SamplerateUnits',...
                'Method','Constant','FunctionHandle'}))';
            StateName = Name + "Value";
            StateName(9) = "MethodValue";
            % For Data Cleaner App compatibility, the state name associated with 
            % "CustomAggFcnSelector" is set to the state field with the appropriate editfield value
            StateName(11) = "AggFcnEditFieldValue";
            N = numel(Name);
            Type = repmat({''},N,1);
            Tooltip = repmat({''},N,1);
            Items = repmat({[]},N,1);
            ItemsData = repmat({[]},N,1);
            Visible = repmat(matlab.lang.OnOffSwitchState.on,N,1);
            Enable = repmat(matlab.lang.OnOffSwitchState.on,N,1);
            SpinnerProperties = repmat({[]},N,1);
            app.TableDropDowns(1).populateVariables();
            for k = 1:N
                widget = app.(Name(k))(1);
                Type{k} = class(widget); 
                Tooltip{k} = widget.Tooltip;
                if isprop(widget,'Items')
                    Items{k} = widget.Items;
                    ItemsData{k} = widget.ItemsData;
                end
                Visible(k) = widget.Visible;
                Enable(k) = widget.Enable;
                if isa(widget,'matlab.ui.control.Spinner')
                    spinProps = struct;
                    spinProps.Limits = widget.Limits;
                    spinProps.LowerLimitInclusive = logical(widget.LowerLimitInclusive);
                    spinProps.UpperLimitInclusive = logical(widget.UpperLimitInclusive);
                    spinProps.Step = widget.Step;
                    SpinnerProperties{k} = spinProps;
                end
            end
            Type{11} = 'matlab.ui.control.EditField';
            InitializeFlag = zeros(N,1);
            InSubgroup = false(N,1);
            GroupExpanded = true(N,1);

            propTable = table(Name,Group,DisplayName,StateName,Type,Tooltip,...
                Items,ItemsData,Visible,Enable,InitializeFlag,InSubgroup,GroupExpanded,SpinnerProperties);

            if isscalar(app.TableDropDowns)
                % Remove second row of table, show only one dd
                propTable(2,:) = [];
                propTable.StateName(1) = "TableInputs";
            else
                % First control is a regular dd for choosing first tt
                % Second control is a multiselect dd for choosing the rest
                propTable.Name(1) = "FirstTableDropDown";
                propTable.DisplayName(1) = getLocalMsg(app,'FirstTimetable');
                propTable.StateName(1) = "FirstTimetableValue";
                propTable.StateName(2) = "TableInputsForApp";
                % Synchronize input dd should be a multiselect
                propTable.Type{2} = 'MultiselectDropDown';
                % Items should match second dd, except change 'select' to
                % 'Additional timetables' since the first item is used for
                % the title of the multiselect popout
                app.TableDropDowns(2).populateVariables();
                tablenames = app.TableDropDowns(2).ItemsData(2:end);
                propTable.Items{2} = [{getLocalMsg(app,'AdditionalTimetables')} tablenames];
                propTable.ItemsData{2} = [{'select variable'} tablenames];
                % Make sure first tt is chosen first
                propTable.Enable(2) = ~isequal(app.TableDropDowns.Value,app.SelectVariable);
                % For basis type dropdown, update 'first' label to use the
                % same language as the FirstTableDropDown
                [~,ind] = ismember('first',propTable.ItemsData{4});
                if ind
                    propTable.Items{4}{ind} = getLocalMsg(app,'FirstInApp');
                end
            end
        end

        function msg = getInspectorDisplayMsg(app)
            % used in data cleaner app to display when no valid variables,
            % but retime only requires timetable to be non-empty.
            msg = '';
            if app.NumInputTables > 1 && ~strcmp(app.TableDropDowns(1).Value,app.SelectVariable)
                % in synchronize and 1st tt is chosen
                app.TableDropDowns(2).populateVariables();
                if numel(app.TableDropDowns(2).Items) < 2
                    % nothing valid for a second tt, other tts in the app
                    % therefore have rowtimes with wrong datatype
                    msg = app.getLocalMsg('TimetablesMatchRowTimesType');
                end
            end
        end
    end

    methods
        function set.State(app,state)
            % used by live editor for save/load undo/redo
            setTaskState(app,state);
        end

        function state = get.State(app)
            state = struct('VersionSavedFrom',app.Version,...
                'MinCompatibleVersion',1,...
                'TableInputs',{{app.TableDropDowns.Value}},...
                'NewTimesWorkspaceDropdownValue',app.NewTimesWorkspaceDropdown.Value,...
                'NewTimesDropdownItems',{app.NewTimesDropdown.Items},...
                'NewTimesDropdownItemsData',{app.NewTimesDropdown.ItemsData},...
                'NewTimesDropdownValue',app.NewTimesDropdown.Value,...
                'BasisTypeDropdownItems',{app.BasisTypeDropdown.Items},...
                'BasisTypeDropdownItemsData',{app.BasisTypeDropdown.ItemsData},...
                'BasisTypeDropdownValue',app.BasisTypeDropdown.Value,...
                'TimeStepSpinnerValue',app.TimeStepSpinner.Value,...
                'TimeStepUnitsItems',{app.TimeStepUnits.Items},...
                'TimeStepUnitsItemsData',{app.TimeStepUnits.ItemsData},...
                'TimeStepUnitsValue',app.TimeStepUnits.Value,...
                'SampleRateSpinnerValue',app.SampleRateSpinner.Value,...
                'SampleRateUnitsValue',app.SampleRateUnits.Value,...
                'MethodItems',{app.MethodTypeDropdown.Items},...
                'MethodItemsData',{app.MethodTypeDropdown.ItemsData},...
                'MethodValue',app.MethodTypeDropdown.Value,...
                'ConstantSpinnerValue',app.ConstantSpinner.Value,...
                'AggFcnEditFieldValue',app.CustomAggFcnSelector.HandleValue,...
                'CustomAggFcnSelectorState',app.CustomAggFcnSelector.State,...
                'OutputTableCheckboxValue',app.OutputTableCheckbox.Value,...
                'InputTablesCheckboxValue',app.InputTablesCheckbox.Value,...
                'NumInputTimetables',app.NumInputTables,...
                'NumOverrides',app.NumOverrides,...
                'IsSortedTimes',app.IsSortedTimes, ...
                'SampleRateByDefault',app.SampleRateByDefault,...
                'MaxOverrides',app.MaxOverrides);
            if ~isempty(app.OverrideLocations)
                state.OverrideLocations = app.OverrideLocations;
            end

            for k = 1:app.NumOverrides
                if app.NumInputTables > 1
                    state.(['OverrideDropdownsTTValue' num2str(k)]) = app.OverrideDropdownsTT(k).Value;
                    state.(['OverrideDropdownsTTItems' num2str(k)]) = app.OverrideDropdownsTT(k).Items;
                end
                state.(['OverrideDropdownsVarValue' num2str(k)]) = app.OverrideDropdownsVar(k).Value;
                state.(['OverrideDropdownsVarItems' num2str(k)]) = app.OverrideDropdownsVar(k).Items;
                state.(['OverrideDropdownsMethodsValue' num2str(k)]) = app.OverrideDropdownsMethods(k).Value;
                state.(['OverrideDropdownsMethodsItems' num2str(k)]) = app.OverrideDropdownsMethods(k).Items;
                state.(['OverrideDropdownsMethodsItemsData' num2str(k)]) = app.OverrideDropdownsMethods(k).ItemsData;
            end

            % To load in versions before 4, also save inputs in
            % TableDropDownsValues and NumInputTables
            state.NumInputTables = app.NumInputTables;
            if app.NumInputTables == 1 || app.NumInputTables == 5
                % we have the correct amount of inputs
                state.TableDropDownsValues = state.TableInputs;
            elseif app.NumInputTables < 5
                % need to pad with 'select value' to get to 5
                numfill = 5-app.NumInputTables;
                state.TableDropDownsValues = [state.TableInputs repmat({app.SelectVariable},1,numfill)];
            else
                % use only the first 5 dropdown values
                state.NumInputTables = 5;
                state.TableDropDownsValues = state.TableInputs(1:5);
            end
            if app.NumInputTables ~= 1
                % Save first dd value separately for separate control
                state.FirstTimetableValue = state.TableInputs{1};
                % For data cleaner app's multiselect in synchronize, don't
                % save values with 'select variable'
                state.TableInputsForApp = setdiff(state.TableInputs(2:end),app.SelectVariable,'stable');
                if app.NumOverrides > 0
                    state.DedupedOverrideNames = app.DedupedOverrideNames;
                    state.InputIndexingCode = app.InputIndexingCode;
                end
            end

            % For backward compatibility, save some additional method properties
            state.FillTypeDropdownValue = 'fillwithmissing';
            state.InterpolationTypeDropdownValue = 'linear';
            state.AggFcnDropdownValue = 'sum';
            if ismember(app.MethodTypeDropdown.Value,app.FillMethods)
                state.MethodTypeDropdownValue = 'fill';
                state.FillTypeDropdownValue = app.MethodTypeDropdown.Value;
            elseif ismember(app.MethodTypeDropdown.Value,app.InterpMethods)
                state.MethodTypeDropdownValue = 'interp';
                state.InterpolationTypeDropdownValue = app.MethodTypeDropdown.Value;
            elseif ismember(app.MethodTypeDropdown.Value,[app.AggMethods {'Custom'}])
                state.MethodTypeDropdownValue = 'aggregate';
                state.AggFcnDropdownValue = app.MethodTypeDropdown.Value;
            else
                state.MethodTypeDropdownValue = 'vc';
            end
            % also save the full items lists
            state.MethodTypeDropdownItems = getLocalMsg(app,{'Fillvalues' 'Interpolatedata' 'Aggregatedata' 'vc'});
            state.MethodTypeDropdownItemsData = {'fill' 'interp' 'aggregate' 'vc'};
            state.FillTypeDropdownItems = getLocalMsg(app,app.FillMethods);
            state.FillTypeDropdownItemsData = app.FillMethods;
            state.AggFcnDropdownItems = getLocalMsg(app,[app.AggMethods {'Custom'}]);
            state.AggFcnDropdownItemsData = [app.AggMethods {'Custom'}];
        end

        function set.Workspace(app,ws)
            app.Workspace = ws;
            [app.TableDropDowns.Workspace] = deal(ws); %#ok<MCSUP>
            app.NewTimesWorkspaceDropdown.Workspace = ws; %#ok<MCSUP>
            if ~isequal(ws,"base") %return
                % Local functions not supported
                app.CustomAggFcnSelector.FcnType = 'handle'; %#ok<MCSUP>
            end
        end
    end

    % helper functions
    methods (Access = protected)
        function [Items,ItemsData] = getMethodList(app,isSorted,isOverrideDD)
            ItemsData = [app.FillMethods app.InterpMethods app.AggMethods app.OtherMethods];
            if ~isSorted
                ItemsData = setdiff(ItemsData,[{'previous' 'next' 'nearest'} ...
                    app.InterpMethods {'firstvalue' 'lastvalue'}],'stable');
            end
            if isOverrideDD
                ItemsData = setdiff(ItemsData,{'fillwithconstant','Custom','vc'},'stable');
            end
            Items = getLocalMsg(app,ItemsData);
        end

        function s = getLocalMsg(~,msgId,varargin)
            if iscellstr(msgId)
                s = cellfun(@(id)getString(message(['MATLAB:tableui:timetableSynchronizer' id])),...
                    msgId,'UniformOutput',false);
            else
                s = getString(message(['MATLAB:tableui:timetableSynchronizer' msgId],varargin{:}));
            end
        end

        function s = getCommonMsg(~,msgId,varargin)
            if iscellstr(msgId) %#ok<*ISCLSTR>
                s = cellfun(@(id)getString(message(['MATLAB:dataui:' id])),...
                    msgId,'UniformOutput',false);
            else
                s = getString(message(['MATLAB:dataui:' msgId],varargin{:}));
            end
        end
    end
end