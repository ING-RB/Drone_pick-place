classdef (Hidden = true, Sealed = true) FindSeasonalTrendsTask < ...
        matlab.internal.dataui.DataPreprocessingTask
    % FindSeasonalTrendsTask - Decompose seasonal and long term trends
    %
    %   H = FindSeasonalTrendsTask constructs a Live Script tool for
    %   decomposing data into seasonal and long term trends
    %
    %   See also TRENDDECOMP

    %   Copyright 2022-2024 The MathWorks, Inc.

    properties (Access = public, Transient, Hidden)
        HomeButton             matlab.ui.control.Image
        OutputWorkflowDropDown matlab.ui.control.DropDown
        % Parameter section -- options depend on algorithm
        % Algorithm: SSA or STL
        % SSA is a useful algorithm when the periods of the seasonal trends
        % are unknown.  STL algorithm is an additive decomposition
        % based on a locally weighted regression. STL requires a period for
        % the seasonal trend.
        AlgorithmDropDown     matlab.ui.control.DropDown
        % Lag value for SSA. Larger values of lag typically provide more
        % separation of the trends. If the period is known, then specify
        % lag as a multiple of the period.
        LagLabel              matlab.ui.control.Label
        LagSpinner            matlab.ui.control.Spinner
        % Number of seasonal trends for SSA
        NumSeasonalLabel      matlab.ui.control.Label
        NumSeasonalSpinner    matlab.ui.control.Spinner
        % Period(s) for STL, with units for timetable inputs
        PeriodLabel           matlab.ui.control.Label
        PeriodSpinners        matlab.ui.control.Spinner
        PeriodUnitsDropDowns  matlab.ui.control.DropDown
        PeriodAddButtons      matlab.ui.control.Image
        PeriodSubtractButtons matlab.ui.control.Image

        % Plot options
        StackedPlotCheckBox   matlab.ui.control.CheckBox
        InputCheckBox         matlab.ui.control.CheckBox
        LongTermCheckBox      matlab.ui.control.CheckBox
        SeasonalCheckBox      matlab.ui.control.CheckBox
        RemainderCheckBox     matlab.ui.control.CheckBox
        DetrendedCheckBox     matlab.ui.control.CheckBox

        % Helpers
        DefaultAlgorithm      = "ssa"; % only changes if keyword is 'stl'
        TimeStep              = duration.empty; % timestep for timetable inputs
        PeriodLimitsStale     = false;
    end

    properties (Constant, Transient, Hidden)
        OutputsForArrays       = {'longterm' 'periodic' 'remainder'};
        OutputsForTabulars     = {'trends'};
        DetrendedOutputArray   = 'detrendedData';
        DetrendedOutputTabular = 'newTable';

        % Serialization Versions - used for managing forward compatibility
        %       1: original ship (R2023a)
        %       2: periods specified by Spinners instead of EditField (R2023b)
        Version double = 2;
    end

    properties
        Workspace = "base"
        State
        Summary
    end

    events
        HomeClicked
    end

    methods (Access = protected)
        function createWidgets(app)
            createInputDataSection(app);
            app.InputDataDropDown.Tooltip = getMsgText(app,getMsgId('InputTooltip'));
            outputLabel = app.Accordion.Children(1).Children.Children(5);
            outputLabel.Text = getMsgText(app,getMsgId('Output'));
            app.OutputWorkflowDropDown = uidropdown(app.Accordion.Children(1).Children,...
                'Items',[getMsgText(app,getMsgId('FindTrends')) getMsgText(app,getMsgId('RemoveLongTerm')) ...
                getMsgText(app,getMsgId('RemoveSeasonal')) getMsgText(app,getMsgId('RemoveAll'))],...
                'ItemsData',{'find' 'removeL' 'removeS' 'removeA'},...
                'ValueChangedFcn',@app.doUpdateFromWidgetChange,...
                'Tag','OutputWorkflowDropDown');
            app.OutputWorkflowDropDown.Layout.Row = 3;
            app.OutputWorkflowDropDown.Layout.Column = 2;
            app.Accordion.Children(1).Children.ColumnWidth{2} = 'fit';
            app.OutputTypeDropDown.Layout.Column = [3 4];

            createParameterSection(app);
            createPlotSection(app,5);
            app.SamplePointsForPlotOnly = true;
            app.AutoRunCutOff = 1e4;

            app.LayoutManager.ColumnWidth = {'1x',16};
            app.HomeButton = uiimage(app.LayoutManager,'ScaleMethod','none',...
                'VerticalAlignment','top',...
                'ImageClickedFcn',@(~,~) notify(app,'HomeClicked'),...
                'Tooltip',string(message('MATLAB:dataui:FindTrendsSelectTrendType')));
            matlab.ui.control.internal.specifyIconID(app.HomeButton,'homeUI',16,16);
        end

        function adj = getAdjectiveForOutputDropDown(~)
            adj = 'Detrended';
        end

        function createParameterSection(app)
            h = createNewSection(app,getMsgText(app,getMsgId('ParameterSection')),...
                {'fit' 'fit' 'fit' app.IconWidth app.IconWidth 'fit'},2);

            % Row 1: Algorithm
            uilabel(h,'Text',getMsgText(app,getMsgId('Algorithm')));
            app.AlgorithmDropDown = uidropdown(h,'ItemsData',{'ssa' 'stl'},...
                'Items',[getMsgText(app,getMsgId('SSA')), getMsgText(app,getMsgId('STL'))],...
                'Tooltip',getMsgText(app,getMsgId('AlgorithmTooltip')),...
                'ValueChangedFcn',@app.doUpdateFromWidgetChange);
            app.AlgorithmDropDown.Layout.Column = [2 6];
            % Row 2: SSA contols - NumSeasonal and Lag
            app.NumSeasonalLabel = uilabel(h,...
                'Text',getMsgText(app,getMsgId('NumSeasonalTrends')));
            app.NumSeasonalSpinner = uispinner(h,'RoundFractionalValues','on',...
                'ValueChangedFcn',@app.doUpdateFromWidgetChange,...
                'Limits',[1 inf],'Tag','NumSeasonalSpinner',...
                'Tooltip',getMsgText(app,getMsgId('NumSeasonalTrendsTooltip')));
            app.LagLabel = uilabel(h,'Text',getMsgText(app,getMsgId('Lag')));
            app.LagSpinner = uispinner(h,'RoundFractionalValues','on',...
                'ValueChangedFcn',@app.doUpdateFromWidgetChange,...
                'Tooltip',getMsgText(app,getMsgId('LagTooltip')));
            app.LagSpinner.Layout.Column = [4 6];
            % Row 3+: STL controls - period with units dd
            app.PeriodLabel = uilabel(h,'Text',getMsgText(app,getMsgId('Period')));
            addRowOfPeriodControls(app,[],[],1);
        end

        function addRowOfPeriodControls(app,src,~,k)
            if nargin < 4
                % comes directly from '+' button
                if waitingOnPeriod(app)
                    % quick return for clicking too fast, not testable
                    return
                end
                k = numel(app.PeriodSpinners) + 1;
            end
            h = app.Accordion.Children(2).Children;
            h.RowHeight{k+2} = 22;
            app.PeriodSpinners(k) = uispinner(h,...
                'ValueChangedFcn',@app.doUpdateFromWidgetChange,...
                'AllowEmpty',true,...
                'Tag',['PeriodSpinners' num2str(k)]);
            app.PeriodSpinners(k).Layout.Row = k+2;
            app.PeriodSpinners(k).Layout.Column = 2;
            app.PeriodUnitsDropDowns(k) = uidropdown(h,...
                'ItemsData',{'milliseconds' 'seconds' 'minutes' 'hours' 'days' 'years'},...
                'Items',cellfun(@(id)char(getMsgText(app,id)),...
                {'Milliseconds' 'Seconds' 'Minutes' 'Hours' 'Days' 'Years'},'UniformOutput',false),...
                'ValueChangedFcn',@app.doUpdateFromWidgetChange,...
                'Tag',['PeriodUnitsDropDowns' num2str(k)]);
            app.PeriodSubtractButtons(k) = uiimage(h,'ScaleMethod','none',...
                'ImageClickedFcn',@app.subtractRowOfPeriodControls,'UserData',k,...
                'Tooltip',getMsgText(app,getMsgId('SubtractPeriod')));
            matlab.ui.control.internal.specifyIconID(app.PeriodSubtractButtons(k),...
                'minusUI',app.IconWidth,app.IconWidth);
            app.PeriodAddButtons(k) = uiimage(h,'ScaleMethod','none',...
                'ImageClickedFcn',@app.addRowOfPeriodControls,...
                'Tooltip',getMsgText(app,getMsgId('AddPeriod')));
            matlab.ui.control.internal.specifyIconID(app.PeriodAddButtons(k),...
                'plusUI',app.IconWidth,app.IconWidth);
            if nargin < 4
                % set the new units same as the previous row
                app.PeriodUnitsDropDowns(k).Value = app.PeriodUnitsDropDowns(k-1).Value;
                app.PeriodSpinners(k).Limits = app.PeriodSpinners(k-1).Limits;
                % set the value to empty. User must provide period
                app.PeriodSpinners(k).Value = [];
                doUpdateFromWidgetChange(app,src,[]);
            end
        end

        function subtractRowOfPeriodControls(app,src,~,k)
            if nargin < 4
                % comes directly from '-' button
                k = src.UserData;
            end
            % shift selection up and delete the last row
            for j = k+1:numel(app.PeriodSpinners)
                app.PeriodSpinners(j-1).Limits = app.PeriodSpinners(j).Limits;
                app.PeriodSpinners(j-1).Value = app.PeriodSpinners(j).Value;
                app.PeriodUnitsDropDowns(j-1).Value = app.PeriodUnitsDropDowns(j).Value;
            end
            % delete last row of widgets and handles
            delete(app.PeriodSpinners(end));
            delete(app.PeriodUnitsDropDowns(end));
            delete(app.PeriodSubtractButtons(end));
            delete(app.PeriodAddButtons(end));
            app.PeriodSpinners(end) = [];
            app.PeriodUnitsDropDowns(end) = [];
            app.PeriodSubtractButtons(end) = [];
            app.PeriodAddButtons(end) = [];
            app.Accordion.Children(2).Children.RowHeight(end) = [];
            if nargin < 4
                % actual src may have been deleted, callback just needs Tag
                src = struct("Tag",'');
                doUpdateFromWidgetChange(app,src,[]);
            end
        end

        function createPlotWidgetsRow(app,h)
            app.StackedPlotCheckBox = uicheckbox(h,'Text',getMsgText(app,getMsgId('StackedPlot')),...
                'ValueChangedFcn',@app.doUpdateFromWidgetChange,...
                'Tooltip',getMsgText(app,getMsgId('StackedPlotTooltip')));

            app.InputCheckBox = uicheckbox(h,'Text',getMsgText(app,getMsgId('InputData')),...
                'ValueChangedFcn',@app.doUpdateFromWidgetChange);
            app.InputCheckBox.Layout.Row = 2;
            app.InputCheckBox.Layout.Column = 1;
            app.LongTermCheckBox = uicheckbox(h,'Text',getMsgText(app,getMsgId('LongTermTrend')),...
                'ValueChangedFcn',@app.doUpdateFromWidgetChange);
            app.SeasonalCheckBox = uicheckbox(h,'Text',getMsgText(app,getMsgId('SeasonalTrends')),...
                'ValueChangedFcn',@app.doUpdateFromWidgetChange);
            app.RemainderCheckBox = uicheckbox(h,'Text',getMsgText(app,getMsgId('Remainder')),...
                'ValueChangedFcn',@app.doUpdateFromWidgetChange);
            app.DetrendedCheckBox = uicheckbox(h,'Text',getMsgText(app,getMsgId('DetrendedData')),...
                'ValueChangedFcn',@app.doUpdateFromWidgetChange);
        end

        function setWidgetsToDefault(app,~)
            app.OutputWorkflowDropDown.Value = 'find';
            setOutputTypeDropDownItemsToDefault(app);
            changedSupportsVisualizationAndUpdatePlotDD(app);
            % Default algorithm is ssa, unless user was typing "stl" to launch task
            app.AlgorithmDropDown.Value = app.DefaultAlgorithm;
            setTimeStep(app);
            setNumSeasonalLimits(app);
            app.NumSeasonalSpinner.Value = 1;
            setLagLimitsAndValue(app);
            setPeriodToDefault(app);
            app.StackedPlotCheckBox.Value = false;
            app.InputCheckBox.Value = true;
            app.LongTermCheckBox.Value = true;
            app.SeasonalCheckBox.Value = true;
            app.RemainderCheckBox.Value = true;
            app.DetrendedCheckBox.Value = true;
        end

        function setTimeStep(app)
            ts = duration.empty;
            if hasInputData(app,false)
                T = app.InputDataDropDown.WorkspaceValue;
                if istimetable(T)
                    [~,ts] = isregular(T);
                end
            end
            app.TimeStep = ts;
        end

        function setNumSeasonalLimits(app)
            if hasInputData(app,false)
                % From trenddecomp, numS must be in [1,lag-2]
                % and lag must be in [3,N/2]
                % Switching the dependence we get
                % lag must be in [numS + 2, N/2]
                % and numS must be in [1,N/2 - 2]
                % numS must also be integer-valued
                heightInput = getNumelAlongDefaultDim(app);
                app.NumSeasonalSpinner.Limits = [1 fix(heightInput/2)-2];
            else
                app.NumSeasonalSpinner.Limits = [1 inf];
            end
        end

        function setLagLimitsAndValue(app)
            if hasInputData(app,false)
                % As above, lag must be in [numS + 2, N/2]
                % lag must also be integer-valued
                heightInput = getNumelAlongDefaultDim(app);
                app.LagSpinner.Limits = [app.NumSeasonalSpinner.Value + 2,fix(heightInput/2)];
                app.LagSpinner.Value = min(fix(heightInput/2),5000);
            else % No input selected
                app.LagSpinner.Limits = [3 inf];
                app.LagSpinner.Value = 3;
            end
        end

        function updateLagLimit(app)
            app.LagSpinner.Limits(1) = app.NumSeasonalSpinner.Value + 2;
        end

        function setPeriodToDefault(app)
            if numel(app.PeriodSpinners) > 1
                % Remove any excess period rows
                for k = numel(app.PeriodSpinners): -1 : 2
                    subtractRowOfPeriodControls(app,[],[],k);
                end
            end
            % User must provide period
            app.PeriodSpinners(1).Value = [];
            if hasInputData(app,false) && ~isempty(app.TimeStep)
                % Pick smallest unit where timestep is not fractional
                secondsInUnit = [1/1000 1 60 3600 86400 31556952];
                index = find(abs(seconds(app.TimeStep)) >= secondsInUnit,1,'last');
                if isempty(index)
                    % less than a millisecond
                    index = 1;
                end
                app.PeriodUnitsDropDowns(1).Value = app.PeriodUnitsDropDowns(1).ItemsData{index};
            else
                app.PeriodUnitsDropDowns(1).Value = 'hours';
            end
            app.PeriodSpinners(1).Limits = getPeriodLimits(app,1);
        end

        function plimits = getPeriodLimits(app,k)
            % period must be in [3,N/2]
            % if timetable, convert this to timetable's timesteps in unit
            % provided by dropdown
            if hasInputData(app,false)
                plimits = [3 floor(getNumelAlongDefaultDim(app)/2)];
                if ~isempty(app.TimeStep)
                    plimits = plimits.*app.TimeStep;
                    % if timetable is decreasing, need sort
                    plimits = sort(feval(app.PeriodUnitsDropDowns(k).Value,plimits));
                end
            else
                plimits = [3 inf];
            end
        end

        function changedWidget(app,context,event)
            % Update widgets' internal values from callbacks
            context = context.Tag;
            if isequal(context,app.InputDataDropDown.Tag)
                setTimeStep(app);
                setNumSeasonalLimits(app);
                setLagLimitsAndValue(app);
                setPeriodToDefault(app);
            elseif isequal(context,app.OutputWorkflowDropDown.Tag)
                setOutputTypeDropDownItemsToDefault(app);
                changedSupportsVisualizationAndUpdatePlotDD(app);
            elseif isequal(context,app.NumSeasonalSpinner.Tag)
                updateLagLimit(app);
            elseif startsWith(context,'PeriodUnitsDropDowns')
                % period limits changed, so value should be updated
                k = str2double(erase(context,'PeriodUnitsDropDowns'));
                val = app.PeriodSpinners(k).Value;
                plimits = getPeriodLimits(app,k);
                app.PeriodSpinners(k).Limits = plimits;
                if ~isempty(val)
                    % Enforce new limits: if value is now outside range,
                    % convert it along with units (e.g. 60 min -> 1 hr), else
                    % don't change it (e.g. 60 min -> 60 hr)
                    if val < plimits(1) || val > plimits(2)
                        % get duration of val in previous units
                        val = feval(event.PreviousValue,val);
                        % convert to number in new unit
                        val = feval(app.PeriodUnitsDropDowns(k).Value,val);
                    end
                    % Either way, units have changed so rounding needed may
                    % have changed. Round value to nearest timestep
                    app.PeriodSpinners(k).Value = roundPeriodValue(app,val,k);
                end
            elseif startsWith(context,'PeriodSpinners')
                % process user-provided period value
                k = str2double(erase(context,'PeriodSpinners'));
                val = app.PeriodSpinners(k).Value;
                if ~isempty(val)
                    % round value to nearest integer or timestep
                    val = roundPeriodValue(app,val,k);
                    app.PeriodSpinners(k).Value = val;
                end
            end
        end

        function val = roundPeriodValue(app,val,k)
            if isempty(app.TimeStep)
                % round to nearest integer
                val = round(val);
            else
                % Convert numeric value to duration of appropriate units
                val = feval(app.PeriodUnitsDropDowns(k).Value,val);
                % Round to the nearset timestep
                val = round(val/app.TimeStep)*app.TimeStep;
                % Convert back to numeric value
                val = feval(app.PeriodUnitsDropDowns(k).Value,val);
            end
        end

        function updateWidgets(app,allowEval)
            % Update the layout and visibility of the widgets

            doRemove = startsWith(app.OutputWorkflowDropDown.Value,'remove');
            if ~doRemove && app.InputDataHasTableVars
                % Make sure outputformat is accurate while hidden
                if ismember('smalltable',app.OutputTypeDropDown.ItemsData)
                    % some but not all table vars selected, need indexing
                    app.OutputTypeDropDown.Value = 'smalltable';
                else
                    % all table vars are selected, so we won't need to index
                    app.OutputTypeDropDown.Value = 'replace';
                end
                % note: timestamps always valid by filter fcn, so one of
                % these two options above will be available
            elseif doRemove && ismember('vector',app.OutputTypeDropDown.ItemsData) && ...
                    istimetable(app.InputDataDropDown.WorkspaceValue)
                % 'vector' not supported for timetables since period is in
                % duration units
                app.OutputTypeDropDown.Items(1) = [];
                app.OutputTypeDropDown.ItemsData(1) = [];
            end
            updateInputDataAndSamplePointsDropDown(app);
            hasInput = hasInputDataAndSamplePoints(app);
            % always show outputformat row for OutputWorkflowDropDown
            app.Accordion.Children(1).Children.RowHeight{3} = app.TextRowHeight;
            app.OutputWorkflowDropDown.Enable = hasInput;
            % if only find, just provide the trend(s), with no output options
            app.OutputTypeDropDown.Visible = app.InputDataHasTableVars && doRemove;
            % always hide xaxis rows
            app.SamplePointsDropDown.Visible = 'off';
            app.SamplePointsTableVarDropDown.Visible = 'off';
            app.SamplePointsDropDown.Parent.RowHeight{4} = 0;

            % Set Enable for all controls
            app.AlgorithmDropDown.Enable = hasInput;
            app.LagSpinner.Enable = hasInput;
            app.NumSeasonalSpinner.Enable = hasInput;
            [app.PeriodSpinners.Enable] = deal(hasInput);
            [app.PeriodUnitsDropDowns.Enable] = deal(hasInput);
            [app.PeriodSubtractButtons.Enable] = deal(hasInput);
            hasInputAndPeriods = hasInput && ~waitingOnPeriod(app);
            [app.PeriodAddButtons.Enable] = deal(hasInputAndPeriods);
            app.TableVarPlotDropDown.Enable = hasInputAndPeriods || ~hasInput;
            app.StackedPlotCheckBox.Enable = hasInputAndPeriods;
            app.InputCheckBox.Enable = hasInputAndPeriods;
            app.LongTermCheckBox.Enable = hasInputAndPeriods;
            app.SeasonalCheckBox.Enable = hasInputAndPeriods;
            app.RemainderCheckBox.Enable = hasInputAndPeriods;
            app.DetrendedCheckBox.Enable = hasInputAndPeriods;

            % Set visibility of parameter controls
            doSSA = isequal(app.AlgorithmDropDown.Value,'ssa');
            app.NumSeasonalLabel.Visible = doSSA;
            app.NumSeasonalSpinner.Visible = doSSA;
            app.LagLabel.Visible = doSSA;
            app.LagSpinner.Visible = doSSA;
            app.PeriodLabel.Visible = ~doSSA;
            [app.PeriodSpinners.Visible] = deal(~doSSA);
            isTimetableInput = ~isempty(app.TimeStep);
            [app.PeriodUnitsDropDowns.Visible] = deal(~doSSA && isTimetableInput);
            [app.PeriodSubtractButtons.Visible] = deal(~doSSA && numel(app.PeriodSpinners)>1);
            [app.PeriodAddButtons.Visible] = deal(~doSSA);
            paramGrid = app.Accordion.Children(2).Children;
            matlab.internal.dataui.setParentForWidgets([app.NumSeasonalLabel, ...
                app.NumSeasonalSpinner,app.LagLabel,app.LagSpinner,...
                app.PeriodLabel,app.PeriodSpinners,app.PeriodUnitsDropDowns,...
                app.PeriodSubtractButtons,app.PeriodAddButtons],paramGrid)
            if doSSA || isTimetableInput
                paramGrid.ColumnWidth{3} = 'fit';
            else
                paramGrid.ColumnWidth{3} = 0;
            end
            paramGrid.ColumnWidth{4} = app.IconWidth*(numel(app.PeriodSpinners)>1);
            paramGrid.RowHeight(3:end) = repmat({app.TextRowHeight*~doSSA},1,numel(app.PeriodSpinners));

            % Set dynamic tooltip for period spinners
            if isempty(app.TimeStep)
                tooltipID = 'PeriodTooltipNumeric';
            else
                tooltipID = 'PeriodTooltipTimetable';
            end
            [app.PeriodSpinners.Tooltip] = deal(getMsgText(app,getMsgId(tooltipID)));
            if allowEval && app.PeriodLimitsStale
                % Period limits could be stale from an old version, reset
                % them, as long as we aren't coming from set.State (in
                % which case we can't be sure data is in the workspace)
                for k = 1:numel(app.PeriodSpinners)
                    app.PeriodSpinners(k).Limits = getPeriodLimits(app,k);
                end
                app.PeriodLimitsStale = false;
            end

            % Update visualization section
            app.StackedPlotCheckBox.Layout.Column = 1 +2*(app.TableVarPlotDropDown.Visible);
            showplots = showPlotCheckboxes(app,app.StackedPlotCheckBox,app.InputCheckBox,...
                app.LongTermCheckBox,app.SeasonalCheckBox,app.RemainderCheckBox,app.DetrendedCheckBox);

            app.RemainderCheckBox.Visible = showplots && ~doRemove;
            app.DetrendedCheckBox.Visible = showplots && doRemove;
            matlab.internal.dataui.setParentForWidgets([app.RemainderCheckBox app.DetrendedCheckBox],...
                app.InputCheckBox.Parent)
        end

        function tf = filterInputData(~,A,isTableVar)
            % Keep only Input Data of supported type and size
            if istable(A)
                % no tables within tables, and disallow 1-row tables
                tf = ~isTableVar && height(A) >= 6;
            elseif istimetable(A)
                % additionally only regular timetables
                tf = ~isTableVar && isregular(A) && height(A) >=6;
            else
                tf = numel(A) >= 6 && isvector(A) && isfloat(A) && isreal(A) && ~issparse(A);
            end
        end

        function tf = filterSamplePointsType(~,X,~)
            % Sample points is hidden, but we auto-select timetable x-axis
            % or keep at default. Tasks that have sample points hidden
            % don't need third input
            tf = ~istall(X) && istimetable(X);
        end

        function updateDefaultsFromKeyword(app,kw)
            % if we uniquely partially/fully match "stl", we choose that
            % algorithm. Just an "s" matches both, including the default of
            % "ssa", so we do not do anything.
            if matches(kw,["stl" "st"],"IgnoreCase",true)
                % change default method to STL, so that task goes back to
                % it on reset
                app.DefaultAlgorithm = "stl";
                % change value now
                app.AlgorithmDropDown.Value = "stl";
                 % call doUpdate to update layout and trigger StateChanged
                doUpdate(app);
            end
        end

        function numS = getNumSeasonal(app)
            if isequal(app.AlgorithmDropDown.Value,'ssa')
                numS = app.NumSeasonalSpinner.Value;
            else
                numS = numel(app.PeriodSpinners);
            end
        end

        function tf = waitingOnPeriod(app)
            tf = isequal(app.AlgorithmDropDown.Value,'stl') && any(cellfun(@isempty,{app.PeriodSpinners.Value}));
        end
    end

    methods (Access = public)
        % Required for embedding in a Live Script
        function [code,outputs] = generateScript(app)
            if ~hasInputData(app) || waitingOnPeriod(app)
                code = '';
                outputs = {};
                return
            end

            code = ['% ' char(getMsgText(app,getMsgId('FindTrendsComment'))) newline];
            if app.outputIsTable
                outputs = app.OutputsForTabulars;
                code = [code outputs{1}];
            else
                outputs = app.OutputsForArrays;
                code = [code '[' outputs{1} ',' outputs{2} ',' outputs{3} ']'];
            end

            code = [code ' = trenddecomp('];
            inName = app.getInputDataVarNameForGeneratedScript;
            code = matlab.internal.dataui.addCharToCode(code,[inName ...
                app.getSmallTableCode(app.outputIsTable && ~isequal(app.DataVarSelectionTypeDropDown.Value,'all'))]);
            code = matlab.internal.dataui.addCharToCode(code,[',"' app.AlgorithmDropDown.Value '",']);

            if isequal(app.AlgorithmDropDown.Value,'ssa')
                % lag
                code = matlab.internal.dataui.addCharToCode(code,num2str(app.LagSpinner.Value));
                % numseasonal + end trenddecomp
                code = matlab.internal.dataui.addCharToCode(code,[',NumSeasonal=' num2str(app.NumSeasonalSpinner.Value) ');']);
            else
                % period
                numP = numel(app.PeriodSpinners);
                if numP > 1
                    % start row vector
                    periodStr = '[';
                    endbracket = ']';
                else
                    periodStr = '';
                    endbracket = '';
                end
                doUnits = app.PeriodUnitsDropDowns(1).Visible;
                for k = 1:numP
                    if doUnits
                        periodStr = [periodStr app.PeriodUnitsDropDowns(k).Value ...
                            '(' num2str(app.PeriodSpinners(k).Value,'%.16g') '),']; %#ok<AGROW>
                    else
                        periodStr = [periodStr num2str(app.PeriodSpinners(k).Value) ',']; %#ok<AGROW>
                    end
                end
                % remove final comma, end vector, and end trenddecomp
                code = matlab.internal.dataui.addCharToCode(code,[periodStr(1:end-1) endbracket ');']);
            end

            if startsWith(app.OutputWorkflowDropDown.Value,'remove')
                code = [code newline newline '% ' char(getMsgText(app,getMsgId('Removetrendfromdata')))];
                resetVariablesToBeCleared(app);
                app.markAsVariablesToBeCleared(outputs{:});
                if ~app.outputIsTable
                    if app.InputSize(1) == 1
                        % Input is row vector, output is col vector. To get
                        % appropriate subtraction, need to transpose input.
                        inName = [inName '.'''];
                    end
                    if isequal(app.OutputWorkflowDropDown.Value,'removeL')
                        code = [code newline app.DetrendedOutputArray ' = ' inName ' - ' outputs{1} ';'];
                    elseif isequal(app.OutputWorkflowDropDown.Value,'removeS')
                        % remove the seasonal trend, or the sum of the seasonal trends
                        numSeasonal = getNumSeasonal(app);
                        if numSeasonal == 1
                            code = [code newline app.DetrendedOutputArray ' = ' inName ' - ' outputs{2} ';'];
                        else
                            code = [code newline app.DetrendedOutputArray ' = ' inName ' - sum(' outputs{2} ',2);'];
                        end
                    else
                        code = [code newline app.DetrendedOutputArray ' = ' outputs{3} ';'];
                    end
                    outputs = {app.DetrendedOutputArray};
                else
                    code = [code newline 'newTable = ' inName ...
                        app.getSmallTableCode(isequal(app.OutputTypeDropDown.Value,'append') && ...
                        ~isequal(app.DataVarSelectionTypeDropDown.Value,'all')) ';'];
                    selectedVars = getSelectedVarNames(app);
                    [~,dvLocations] = ismember(selectedVars,app.AllTableVarNames);
                    if isscalar(selectedVars)
                        % only need to process one variable
                        dv = '1';
                        tab = '';
                        LT = '1';
                        S = '2';
                        R = '3';
                    else
                        % loop through selected variables to process them
                        if isequal(app.OutputTypeDropDown.Value,'replace') && numel(selectedVars) ~= app.InputSize(2)
                            code = [code newline 'dv = ' mat2str(dvLocations) ';'];
                            dv = 'dv(j)';
                            app.markAsVariablesToBeCleared('dv');
                        else
                            dv = 'j';
                        end
                        LT = '3*j - 2';
                        S = '3*j - 1';
                        R = '3*j';
                        code = [code newline 'for j = 1:' num2str(numel(dvLocations))];
                        tab = '    ';
                        app.markAsVariablesToBeCleared('j');
                    end

                    if isequal(app.OutputWorkflowDropDown.Value,'removeL')
                        % remove long term trend
                        code = [code newline tab app.DetrendedOutputTabular '.(' dv ') = ' ...
                            app.DetrendedOutputTabular '.(' dv ') - ' outputs{1} '.(' LT ');'];
                    elseif isequal(app.OutputWorkflowDropDown.Value,'removeS')
                        % remove the seasonal trend, or the sum of the seasonal trends
                        numSeasonal = getNumSeasonal(app);
                        if numSeasonal == 1
                            code = [code newline tab app.DetrendedOutputTabular '.(' dv ') = ' ...
                                app.DetrendedOutputTabular '.(' dv ') - ' outputs{1} '.(' S ');'];
                        else
                            code = [code newline tab app.DetrendedOutputTabular '.(' dv ') = ' ...
                                app.DetrendedOutputTabular '.(' dv ') - sum(' outputs{1} '.(' S '),2);'];
                        end
                    else
                        % replace with remainder
                        code = [code newline tab app.DetrendedOutputTabular '.(' dv ') = ' outputs{1} '.(' R ');'];
                    end

                    if ~isscalar(selectedVars)
                        code = [code newline 'end'];
                    end

                    if isequal(app.OutputTypeDropDown.Value,'append')
                        code = generateScriptAppendLogical(app,code,app.DetrendedOutputTabular,'detrended');
                    end
                    outputs = {app.DetrendedOutputTabular};
                end

                if ~app.SupportsVisualization || ~any([app.InputCheckBox.Value ...
                        app.LongTermCheckBox.Value app.SeasonalCheckBox.Value app.DetrendedCheckBox.Value])
                    code = addClear(app,code);
                end
            end
        end

        function code = generateVisualizationScript(app)
            doRemainder = app.RemainderCheckBox.Value && app.RemainderCheckBox.Visible;
            doDetrended = app.DetrendedCheckBox.Value && app.DetrendedCheckBox.Visible;
            plotInd = [app.InputCheckBox.Value app.LongTermCheckBox.Value ...
                app.SeasonalCheckBox.Value doRemainder doDetrended];
            numPlots = sum(plotInd);
            if ~hasInputData(app) || waitingOnPeriod(app) || ~app.SupportsVisualization || numPlots == 0
                code = '';
                return
            end

            resetVariablesToBeCleared(app);
            if startsWith(app.OutputWorkflowDropDown.Value,'remove')
                % mark vars to be cleared from generateScript
                if app.outputIsTable
                    app.markAsVariablesToBeCleared(app.OutputsForTabulars{1});
                    numSelectedVars = numel(getSelectedVarNames(app));
                    if  numSelectedVars > 1
                        if isequal(app.OutputTypeDropDown.Value,'replace') && numSelectedVars ~= app.InputSize(2)
                            app.markAsVariablesToBeCleared('dv');
                        end
                        app.markAsVariablesToBeCleared('j');
                    end
                else
                    app.markAsVariablesToBeCleared(app.OutputsForArrays{:});
                end
            end

            code = addVisualizeResultsLine(app);
            plotMultipleVars = isnumeric(app.TableVarPlotDropDown.Value);
            if plotMultipleVars
                % setup tiledlayout
                [code,inLocation,outLocation] = generateScriptSetupTiledLayout(app,code,true);
                if isequal(app.OutputTypeDropDown.Value,'append')
                    outLocation = [outLocation '+' num2str(app.InputSize(2))];
                end
                locInTrends = 'k';
                tab = '    ';
            elseif app.outputIsTable
                % get the location of the var to plot
                var = app.TableVarPlotDropDown.Value;
                [~,inLocation] = ismember(var,app.AllTableVarNames);
                inLocation = num2str(inLocation);
                [~,locInTrends] = ismember(var,getSelectedVarNames(app));
                locInTrends = num2str(locInTrends);
                if isequal(app.OutputTypeDropDown.Value,'append')
                    outLocation = num2str(app.InputSize(2) + str2double(locInTrends));
                elseif isequal(app.OutputTypeDropDown.Value,'replace')
                    outLocation = inLocation;
                else %smalltable
                    outLocation = locInTrends;
                end

                tab = '';
            else
                tab = '';
            end

            if app.StackedPlotCheckBox.Value
                % Plot in one line of stackedplot with table input (for
                % both arrays and tables)
                if plotMultipleVars
                    code = [code newline tab '% ' char(getMsgText(app,getMsgId('PlotTiledStacked')))];
                end

                multipleSeasons = plotInd(3) && getNumSeasonal(app) > 1;
                if multipleSeasons
                    storePlot = 's = ';
                    markAsVariablesToBeCleared(app,'s');
                else
                    storePlot = '';
                end

                if app.outputIsTable
                    if plotInd(5)
                        % if necessary, replace "remainder" in trends
                        % with detrended/deseasoned data
                        if ismember(app.OutputWorkflowDropDown.Value,{'removeL' 'removeS'})
                            % trends.(3*locInTrends) = newTable.(outLocation)
                            if plotMultipleVars
                                locRem = ['3*' locInTrends];
                            else
                                locRem = num2str(3*str2double(locInTrends));
                            end
                            code = [code newline tab app.OutputsForTabulars{1} '.(' locRem ') = ' app.DetrendedOutputTabular '.(' outLocation ');'];
                        end
                        plotInd(4) = true;
                    end

                    % Three tabular cases captured here:

                    % Case 1: plot single var, single input selected
                    % stackedplot([inputDataName(:,1) trends])

                    % Case 2: plot single var, multi input selected
                    % stackedplot([inputDataName(:,1) trends(:,[4 5 6])])

                    % Case 3: plot multi var inside tiledlayout loop
                    % stackedplot([inputDataName(:,k) trends(:,3*(k-1)+(1:3))])
                    code = [code newline tab storePlot 'stackedplot('];
                    plotOutput = any(plotInd(2:4));
                    if plotInd(1)
                        % stackedplot([inputDataName(:,index) trends(:,index])
                        if plotOutput
                            code = [code '['];
                        end % else only input and don't need horzcat
                        code = [code getInputDataVarNameForGeneratedScript(app) '(:,' inLocation ')'];
                        if plotOutput
                            code = [code ' '];
                        end
                    end

                    if plotOutput
                        % trends(:,index) -- but how we get index varies
                        code = [code app.OutputsForTabulars{1}];
                        if numel(app.TableVarPlotDropDown.Items) <= 2
                            % single input var selected
                            if ~all(plotInd(2:4))
                                trendsInd = find(plotInd(2:4));
                                code = [code '(:,' mat2str(trendsInd) ')'];
                            end % else, no need to index
                        elseif ~plotMultipleVars
                            % multi vars selected, only plotting one
                            % calculate location among the trend table output
                            trendsInd = 3*(str2double(locInTrends)-1)+(1:3);
                            trendsInd = trendsInd(plotInd(2:4));
                            code = [code '(:,' mat2str(trendsInd) ')'];
                        else
                            % plot multiple vars
                            ind = find(plotInd(2:4));
                            code = [code '(:,3*(' locInTrends '-1)+' mat2str(ind) ')'];
                        end

                        if plotInd(1)
                            code = [code ']'];
                        end % else didn't do input and don't need horzcat
                    end
                else
                    code = [code newline tab storePlot 'stackedplot('];
                    % stackedplot(table(A,longTermTrend,seasonalTrend,remainder/detrendedData))
                    if plotInd(1) && app.InputSize(1) == 1
                        % add a .tick to transpose A
                        trTick = '.''';
                    else
                        trTick = '';
                    end
                    % send vars into stackedplot
                    vars = [{[getInputDataVarNameForGeneratedScript(app) trTick]} app.OutputsForArrays {app.DetrendedOutputArray}];
                    vars = vars(plotInd);
                    code = [code 'table(' strjoin(vars,',') ')'];
                end

                % add labels
                code = matlab.internal.dataui.addCharToCode(code,',"DisplayLabels",');
                plotYLabels = [getMsgText(app,'InputData') getMsgText(app,getMsgId('LongTerm')) ...
                    getMsgText(app,getMsgId('Seasonal')) getMsgText(app,getMsgId('Remainder'))];
                if plotInd(5)
                    plotInd(4) = true;
                    plotYLabels(4) = getMsgText(app,getMsgId('DetrendedData'));
                end
                code = matlab.internal.dataui.addCellStrToCode(code,cellstr(plotYLabels(plotInd(1:4))),plotMultipleVars);
                code = [code ');'];

                if plotMultipleVars
                    % title each tile with the variable name
                    code = [code newline tab 'title(' getInputDataVarNameForGeneratedScript(app) ...
                        '.Properties.VariableNames{' inLocation '})'];
                end

                if multipleSeasons
                    % turn off legend for multiple seasonal trends
                    % legend label will not match y-label
                    code = [code newline tab 's.AxesProperties(' num2str(sum(plotInd(1:3))) ').LegendVisible = "off";'];
                end
            else
                % single set of axes plots, similar to DataPreprocessingTask plots
                x = getSamplePointsVarNameForGeneratedScript(app);
                didHoldOn = false;

                if plotInd(1)
                    % Plot Input Data
                    y = getInputDataVarNameForGeneratedScript(app);
                    if app.outputIsTable
                        y = [y '.(' inLocation ')'];
                    end
                    code = generateScriptPlotInputData(app,code,x,y,tab);
                    [code,didHoldOn] = addHold(app,code,'on',didHoldOn,numPlots,tab);
                end
                if ~isempty(x)
                    x = [x ','];
                end
                if plotInd(2)
                    % Plot Long Term Trend
                    code = [code newline newline tab '% ' char(getMsgText(app,getMsgId('PlotLongTerm')))];
                    code = [code newline tab 'plot(' x ];
                    if plotMultipleVars
                        code = [code app.OutputsForTabulars{1} '.(3*(' locInTrends '-1)+1)'];
                    elseif app.outputIsTable
                        ind = 3*(str2double(locInTrends)-1)+1;
                        code = [code app.OutputsForTabulars{1} '.(' num2str(ind) ')'];
                    else
                        code = [code app.OutputsForArrays{1}];
                    end
                    code = matlab.internal.dataui.addCharToCode(code,',SeriesIndex=2,',plotMultipleVars);
                    code = matlab.internal.dataui.addCharToCode(code,'LineWidth=1,',plotMultipleVars);
                    code = addDisplayName(app,code,char(getMsgText(app,getMsgId('LongTerm'))),plotMultipleVars);
                    [code,didHoldOn] = addHold(app,code,'on',didHoldOn,numPlots,tab);
                end

                if plotInd(3)
                    % Plot Seasonal
                    code = [code newline newline tab '% ' char(getMsgText(app,getMsgId('PlotSeasonal')))];
                    if plotMultipleVars
                        y = [app.OutputsForTabulars{1} '.(3*(' locInTrends '-1)+2)'];
                    elseif app.outputIsTable
                        ind = 3*(str2double(locInTrends)-1)+2;
                        y = [app.OutputsForTabulars{1} '.(' num2str(ind) ')'];
                    else
                        y = app.OutputsForArrays{2};
                    end
                    numSeasonal = getNumSeasonal(app);
                    if numSeasonal == 1
                        code = [code newline tab 'plot(' x y];
                        code = matlab.internal.dataui.addCharToCode(code,',SeriesIndex=3,',plotMultipleVars);
                        code = addDisplayName(app,code,char(getMsgText(app,getMsgId('Seasonal'))),plotMultipleVars);
                        [code,didHoldOn] = addHold(app,code,'on',didHoldOn,numPlots,tab);
                    else
                        numPlots = numPlots + numSeasonal - 1;
                        for kk = 1:numSeasonal
                            code = [code newline tab 'plot(' x y '(:,' num2str(kk) '),']; %#ok<AGROW>
                            % use MATLAB color order to get new colors,
                            % skip blue (1) and red (2)
                            code = matlab.internal.dataui.addCharToCode(code,['SeriesIndex=' num2str(kk+2) ','],plotMultipleVars);
                            code = addDisplayName(app,code,[char(getMsgText(app,getMsgId('Seasonal'))) ' ' num2str(kk)],plotMultipleVars);
                            [code,didHoldOn] = addHold(app,code,'on',didHoldOn,numPlots,tab);
                        end
                    end
                end

                if plotInd(4)
                    code = [code newline newline tab '% ' char(getMsgText(app,getMsgId('PlotRemainder')))];
                    code = [code newline tab 'plot(' x ];
                    if plotMultipleVars
                        code = [code app.OutputsForTabulars{1} '.(3*' locInTrends ')'];
                    elseif app.outputIsTable
                        ind = 3*(str2double(locInTrends)-1)+3;
                        code = [code app.OutputsForTabulars{1} '.(' num2str(ind) ')'];
                    else
                        code = [code app.OutputsForArrays{3}];
                    end
                    code = matlab.internal.dataui.addCharToCode(code,[',Color=' app.MiddleGray ','],plotMultipleVars);
                    code = addDisplayName(app,code,char(getMsgText(app,getMsgId('Remainder'))),plotMultipleVars);
                end

                if plotInd(5) % do detrended
                    code = [code newline newline tab '% ' char(getMsgText(app,getMsgId('PlotDetrended')))];
                    if plotMultipleVars
                        data = [app.DetrendedOutputTabular '.(' outLocation ')'];
                    elseif app.outputIsTable
                        if isequal(app.OutputTypeDropDown.Value,'append')
                            data = addIndexingIntoAppendedVar(app,app.DetrendedOutputTabular);
                        else
                            data = addDotIndexingToTableName(app,app.DetrendedOutputTabular);
                        end
                    else
                        data = app.DetrendedOutputArray;
                    end
                    if ~isempty(x)
                        % remove the comma we added
                        x = x(1:end-1);
                    end
                    code = generateScriptPlotCleanedData(app,code,x,data,tab,char(getMsgText(app,getMsgId('DetrendedData'))));
                end

                code = addHold(app,code,'off',didHoldOn,numPlots,tab);
                code = addLegendAndAxesLabels(app,code,tab);
            end

            if plotMultipleVars
                code = generateScriptEndTiledLayout(app,code);
            end
            code = addClear(app,code);
        end

        function setTaskState(app,state)
            if ~isfield(state,'VersionSavedFrom')
                state.VersionSavedFrom = 1;
                state.MinCompatibleVersion = 1;
            end

            if app.Version < state.MinCompatibleVersion
                % state comes from a future, incompatible version
                % do not set any properties
                doUpdate(app,false);
            else
                setInputDataAndSamplePointsDropDownValues(app,state);
                for w  = ["LagSpinner" "NumSeasonalSpinner"]
                    if isfield(state,w + "Limits")
                        app.(w).Limits = state.(w + "Limits");
                    end
                end
                setValueOfComponents(app,["OutputWorkflowDropDown" "AlgorithmDropDown" "LagSpinner" ...
                        "NumSeasonalSpinner" "StackedPlotCheckBox" "InputCheckBox" ...
                        "LongTermCheckBox" "SeasonalCheckBox" "RemainderCheckBox" "DetrendedCheckBox"],state);
                if isfield(state,"DefaultAlgorithm")
                    app.DefaultAlgorithm = state.DefaultAlgorithm;
                end
                if isfield(state,"TimeStepInSeconds")
                    app.TimeStep = seconds(state.TimeStepInSeconds);
                end
                if isfield(state,"PeriodEditFieldValues")
                    % get the correct num periods
                    numPeriodsHave = numel(app.PeriodSpinners);
                    numPeriodsNeed = numel(state.PeriodEditFieldValues);
                    % go into at most one of these loops
                    for k = (numPeriodsHave + 1):numPeriodsNeed
                        addRowOfPeriodControls(app,[],[],k);
                    end
                    for k = numPeriodsHave:-1:(numPeriodsNeed + 1)
                        subtractRowOfPeriodControls(app,[],[],k)
                    end
                    % assign values
                    for k = 1:numPeriodsNeed
                        app.PeriodSpinners(k).Limits = [0 inf];
                        val = state.PeriodEditFieldValues{k};
                        if isempty(val)
                            app.PeriodSpinners(k).Value = [];
                        else
                            app.PeriodSpinners(k).Value = str2double(val);
                        end
                        app.PeriodUnitsDropDowns(k).Value = state.PeriodUnitsDropDownValues{k};
                    end
                end
                app.PeriodLimitsStale = true;
                doUpdate(app,false);
            end
        end
    end

    methods

        function summary = get.Summary(app)
            if ~hasInputData(app) || waitingOnPeriod(app)
                summary = getMsgText(app,getMsgId('SummaryNoInput'));
            else
                inputName = getInputDataVarNameForSummary(app);
                % instead of translated name for algorithm, use the acronym
                algName = upper(app.AlgorithmDropDown.Value);

                switch app.OutputWorkflowDropDown.Value
                    case 'find'
                        summary = getMsgText(app,getMsgId('SummaryFind'),inputName,algName);
                    case 'removeS'
                        summary = getMsgText(app,getMsgId('SummaryRemoveS'),inputName);
                    case 'removeL'
                        summary = getMsgText(app,getMsgId('SummaryRemoveL'),inputName);
                    case 'removeA'
                        summary = getMsgText(app,getMsgId('SummaryRemoveA'),inputName,algName);
                end
            end
        end

        function state = get.State(app)
            state = struct();
            state.VersionSavedFrom = app.Version;
            state.MinCompatibleVersion = 1;
            state = getInputDataAndSamplePointsDropDownValues(app,state);
            for w = ["OutputWorkflowDropDown" "AlgorithmDropDown" "LagSpinner" ...
                    "NumSeasonalSpinner" "StackedPlotCheckBox" "InputCheckBox"...
                    "LongTermCheckBox" "SeasonalCheckBox" "RemainderCheckBox" "DetrendedCheckBox"]
                state.(w + "Value") = app.(w).Value;
            end
            % For backward compatibility, save spinner values as cellstr
            state.PeriodEditFieldValues = cellfun(@(x)num2str(x,'%.16g'),{app.PeriodSpinners.Value},UniformOutput=false);
            state.PeriodUnitsDropDownValues = {app.PeriodUnitsDropDowns.Value};
            state.DefaultAlgorithm = app.DefaultAlgorithm;
            % durations are not jsonencodeable (g2469850), so save numeric
            state.TimeStepInSeconds = seconds(app.TimeStep);

            state.LagSpinnerLimits = app.LagSpinner.Limits;
            state.NumSeasonalSpinnerLimits = app.NumSeasonalSpinner.Limits;
        end

        function set.State(app,state)
            setTaskState(app,state);
        end

        function set.Workspace(app,ws)
            app.Workspace = ws;
            app.InputDataDropDown.Workspace = ws;
            app.SamplePointsDropDown.Workspace = ws;
        end
    end
end

function msgId = getMsgId(id)
msgId = ['TrendDecomp' id];
end