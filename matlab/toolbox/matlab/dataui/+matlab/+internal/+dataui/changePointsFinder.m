classdef (Hidden = true, Sealed = true) changePointsFinder < ...
        matlab.internal.dataui.DataPreprocessingTask
    % changePointsFinder Find abrupt changes in data in a Live Script
    %
    %   H = changePointsFinder constructs a Live Script tool for finding
    %   and visualizing abrupt changes in data (change points).
    %
    %   See also ISCHANGE

    %   Copyright 2018-2024 The MathWorks, Inc.

    properties (Access = public, Transient, Hidden)
        % Function parameters
        FindMethodDropDown                  matlab.ui.control.DropDown
        ThresholdOrMaxNumChangesDropDown    matlab.ui.control.DropDown
        ThresholdSpinner                    matlab.ui.control.Spinner
        MaxNumChangesSpinner                matlab.ui.control.Spinner
        % Plot parameters
        PlotInputDataCheckBox               matlab.ui.control.CheckBox
        PlotChangePointsCheckBox            matlab.ui.control.CheckBox
        PlotChangeSegmentsCheckBox          matlab.ui.control.CheckBox
        % Helpers
        DefaultFindMethod                   = "mean" % changes on initialization if keyword is "linear" or "variance"
    end

    properties (Constant, Transient, Hidden)
        % Constants
        OutputsForLinear = {'changeIndices' 'segmentSlope' 'segmentIntercept'};
        OutputsForMeanAndVar = {'changeIndices' 'segmentMean'};
        % Serialization Versions - used for managing forward compatibility
        %     N/A: original ship (R2019b)
        %       2: Add versioning (R2020b)
        %       3: Multi table vars and table output (R2021a)
        %       4: Use Base Class (R2022a)
        %       5: Table output & tiled layout (R2022b)
        %       6: Add find method initialization based on keyword (R2024a)
        Version = 6;
    end

    properties
        Workspace = "base"
        State
        Summary
    end

    methods (Access = protected)
        function createWidgets(app)
            createInputDataSection(app,true);
            createChangeMethodSection(app);
            createPlotSection(app,3);
        end

        function createChangeMethodSection(app)
            % Layout
            h = createNewSection(app,getMsgText(app,'ParametersDelimiter'),{'fit' 'fit' 'fit' 'fit'},1);
            uilabel(h,'Text',getMsgText(app,getMsgId('TypeofChange')));
            app.FindMethodDropDown = uidropdown(h);
            app.ThresholdOrMaxNumChangesDropDown = uidropdown(h);
            app.ThresholdSpinner = uispinner(h);
            app.MaxNumChangesSpinner = uispinner(h);

            % Properties
            app.FindMethodDropDown.Items = cellstr([getMsgText(app,'Mean') getMsgText(app,getMsgId('Variance')) getMsgText(app,getMsgId('Linear'))]);
            app.FindMethodDropDown.ItemsData = {'mean' 'variance' 'linear'};
            app.FindMethodDropDown.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.ThresholdOrMaxNumChangesDropDown.Items = cellstr([getMsgText(app,getMsgId('Threshold')) getMsgText(app,getMsgId('MaxNum'))]);
            app.ThresholdOrMaxNumChangesDropDown.ItemsData = {'threshold' 'maxnum'};
            app.ThresholdOrMaxNumChangesDropDown.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.ThresholdOrMaxNumChangesDropDown.Tooltip = getMsgText(app,getMsgId('ThreshOrMaxTooltip'));
            app.ThresholdSpinner.Value = 1;
            app.ThresholdSpinner.Limits = [0 Inf];
            app.ThresholdSpinner.UpperLimitInclusive = false;
            app.ThresholdSpinner.Step = 0.25;
            app.ThresholdSpinner.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.ThresholdSpinner.Tooltip = getMsgText(app,getMsgId('ThresholdTooltip'));
            app.MaxNumChangesSpinner.Limits = [1 Inf];
            app.MaxNumChangesSpinner.Value = 10;
            app.MaxNumChangesSpinner.Layout.Row = 1;
            app.MaxNumChangesSpinner.Layout.Column = 4;
            app.MaxNumChangesSpinner.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.MaxNumChangesSpinner.RoundFractionalValues = true;
            app.MaxNumChangesSpinner.Tooltip = getMsgText(app,getMsgId('MaxNumTooltip'));
            app.MaxNumChangesSpinner.Tag = 'MaxNumChangesSpinner';
        end

        function createPlotWidgetsRow(app,h)
            % Layout
            app.PlotInputDataCheckBox = uicheckbox(h);
            app.PlotInputDataCheckBox.Layout.Row = 2;
            app.PlotInputDataCheckBox.Layout.Column = 1;
            app.PlotChangePointsCheckBox = uicheckbox(h);
            app.PlotChangeSegmentsCheckBox = uicheckbox(h);

            % Properties
            app.PlotChangePointsCheckBox.Text = getMsgText(app,getMsgId('ChangePoints'));
            app.PlotChangePointsCheckBox.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.PlotChangeSegmentsCheckBox.Text = getMsgText(app,getMsgId('Segments'));
            app.PlotChangeSegmentsCheckBox.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.PlotInputDataCheckBox.Text = getMsgText(app,'InputData');
            app.PlotInputDataCheckBox.ValueChangedFcn = @app.doUpdateFromWidgetChange;
        end

        function updateDefaultsFromKeyword(app,kw)
            % all keywords that are relevant to changing behavior away from
            % default
            keywords = ["variance" "linear"];

            % checks if the input keyword partially matches any target
            % keyword
            kwMatches = startsWith(keywords,kw,'IgnoreCase',true);

            % if not, we don't update anything
            if ~any(kwMatches)
                return;
            end

            % get the corresponding full keyword
            fullKeyword = keywords(kwMatches);

            app.DefaultFindMethod = fullKeyword;
            app.FindMethodDropDown.Value = fullKeyword;
            doUpdate(app);
        end

        function setWidgetsToDefault(app,fromResetMethod)

            % If the X-axis data is of type datetime, it is not compatible
            % with the "linear" method, and removes it from the method
            % dropdown. Thus, even if "linear" is the default value, we
            % cannot set it to that in this case. The "mean" method is
            % valid for all input types.
            if matches(app.DefaultFindMethod,app.FindMethodDropDown.ItemsData)
               app.FindMethodDropDown.Value = app.DefaultFindMethod;
            else
                app.FindMethodDropDown.Value = "mean";
            end

            app.ThresholdOrMaxNumChangesDropDown.Value = 'threshold';
            app.ThresholdSpinner.Value = 1;
            app.MaxNumChangesSpinner.Value = 10;
            app.MaxNumChangesSpinner.Step = 10;

            fromResetMethod = (nargin > 1) && fromResetMethod; % Called from reset()
            if ~fromResetMethod
                % reset() does not reset the input data, therefore, it does
                % not change wether the app supports visualization or not.
                app.SupportsVisualization = true;
            end
            app.PlotInputDataCheckBox.Value = true;
            app.PlotChangeSegmentsCheckBox.Value = true;
            app.PlotChangePointsCheckBox.Value = true;
        end

        function changedWidget(app,context,event)
            % Update widgets' internal values from callbacks
            if isequal(context.Tag,app.MaxNumChangesSpinner.Tag)
                app.MaxNumChangesSpinner.Step = matlab.internal.dataui.getStepSize(...
                    app.MaxNumChangesSpinner.Value,true,event.PreviousValue);
            end
        end

        function updateWidgets(app,doEvalinBase)
            % Update the layout and visibility of the widgets

            updateInputDataAndSamplePointsDropDown(app);
            hasData = hasInputDataAndSamplePoints(app);

            if doEvalinBase && hasDatetimeSamplePoints(app)
                % 'linear' when sample points is a datetime makes ischange error.
                % When input data is a timetable, we need to check if 'Time' is a datetime. Durations will pass through.
                app.FindMethodDropDown.Items = cellstr([getMsgText(app,'Mean') getMsgText(app,getMsgId('Variance'))]);
                app.FindMethodDropDown.ItemsData = {'mean' 'variance'};
            else
                app.FindMethodDropDown.Items = cellstr([getMsgText(app,'Mean') getMsgText(app,getMsgId('Variance')) getMsgText(app,getMsgId('Linear'))]);
                app.FindMethodDropDown.ItemsData = {'mean' 'variance' 'linear'};
            end
            app.FindMethodDropDown.Enable = hasData;
            app.ThresholdOrMaxNumChangesDropDown.Enable = hasData;
            app.ThresholdSpinner.Enable = hasData;
            app.MaxNumChangesSpinner.Enable = hasData;

            doThreshold = isequal(app.ThresholdOrMaxNumChangesDropDown.Value,'threshold');
            app.ThresholdSpinner.Visible = doThreshold;
            app.MaxNumChangesSpinner.Visible = ~doThreshold;

            app.PlotChangePointsCheckBox.Enable = hasData;
            app.PlotInputDataCheckBox.Enable = hasData;
            app.PlotChangeSegmentsCheckBox.Enable = hasData;
            showPlotCheckboxes(app,app.PlotChangePointsCheckBox,...
                app.PlotInputDataCheckBox,app.PlotChangeSegmentsCheckBox);

            if isequal(app.FindMethodDropDown.Value,'linear') && ...
                    doEvalinBase && hasDurationOrDatetimeSamplePoints(app)
                app.PlotChangeSegmentsCheckBox.Enable = false;
                app.PlotChangeSegmentsCheckBox.Value = false;
            end
        end

        function tf = filterInputData(~,A,isTableVar)
            % Keep only Input Data of supported type
            if isa(A,'tabular') % table or timetable
                tf = ~isTableVar; % No tables within tables
            else
                % Copied from ischange.m checkSupportedArray()
                % additional nonempty/nonscalar restriction
                tf = ~isempty(A) && ~isscalar(A) && isfloat(A) && isreal(A);
            end
        end

        function tf = filterSamplePointsType(~,X,isTableVar)
            % Keep only Sample Points (X-axis) of supported type
            if istall(X)
                tf = false;
            elseif isa(X,'tabular') % table or timetable
                tf = ~isTableVar; % No tables within tables
            else
                % Copied from ischange.m checkSamplePoints()
                tf = (isvector(X) || isempty(X)) && ...
                    ((isfloat(X) && isreal(X) && ~issparse(X)) || ...
                    isduration(X) || isdatetime(X));
            end
        end
    end

    methods (Access = public)
        % Required for embedding in a Live Script

        function [code, outputs] = generateScript(app,isForExport)

            if nargin < 2
                % isForExport is used in the app workflow only when
                % exporting the code. In this case, since we are not
                % exporting plot code, we don't want additional outputs or
                % unused temp vars
                isForExport = false;
            end

            if ~hasInputDataAndSamplePoints(app)
                code = '';
                outputs = {};
                return
            end

            % Optional outputs are only needed for plotting
            doOptionalOutputs = app.PlotChangeSegmentsCheckBox.Value && app.SupportsVisualization && ~isForExport;

            code = ['% ' char(getMsgText(app,getMsgId('Findchangepoints')))];
            if app.InputDataHasTableVars && isequal(app.OutputTypeDropDown.Value,'append')
                outputs = {'newTable'};
            elseif isequal(app.FindMethodDropDown.Value,'linear')
                outputs = app.OutputsForLinear(1);
            else
                outputs = app.OutputsForMeanAndVar(1);
            end

            if doOptionalOutputs
                if isequal(app.FindMethodDropDown.Value,'linear')
                    code = [code newline '[' outputs{1} ',' app.OutputsForLinear{2} ',' app.OutputsForLinear{3} '] = ' ];
                else
                    code = [code newline '[' outputs{1} ',' app.OutputsForMeanAndVar{2} '] = ' ];
                end
            else
                code = [code newline outputs{1} ' = ' ];
            end

            code = matlab.internal.dataui.addCharToCode(code,['ischange(' getInputDataVarNameForGeneratedScript(app)]);
            code = [code getSmallTableCode(app)];

            if ~isequal(app.FindMethodDropDown.Value,'mean')
                code = matlab.internal.dataui.addCharToCode(code,[',"' app.FindMethodDropDown.Value '"']);
            end

            if isequal(app.ThresholdOrMaxNumChangesDropDown.Value,'threshold')
                if app.ThresholdSpinner.Value ~= 1
                    code = matlab.internal.dataui.addCharToCode(code,[',Threshold=' num2str(app.ThresholdSpinner.Value,'%.16g')]);
                end
            else
                code = matlab.internal.dataui.addCharToCode(code,[',MaxNumChanges=' num2str(app.MaxNumChangesSpinner.Value)]);
            end

            code = matlab.internal.dataui.addCharToCode(code,getDataVariablesNameValuePair(app));
            code = matlab.internal.dataui.addCharToCode(code,getSamplePointsNameValuePair(app));
            code = matlab.internal.dataui.addCharToCode(code,getOutputFormatNameValuePair(app));
            code = [code ');'];
            code = generateScriptAppendLogical(app,code,outputs{1},'changePts') ;
        end

        function code = generateVisualizationScript(app)

            code = '';
            if ~hasInputDataAndSamplePoints(app) || ~app.SupportsVisualization
                return;
            end
            numPlots = sum([app.PlotInputDataCheckBox.Value app.PlotChangeSegmentsCheckBox.Value app.PlotChangePointsCheckBox.Value]);
            if numPlots == 0
                return;
            end

            resetVariablesToBeCleared(app);
            code = addVisualizeResultsLine(app);
            x = getSamplePointsVarNameForGeneratedScript(app); % 'X' or ''
            didHoldOn = false;
            doTiledLayout = isnumeric(app.TableVarPlotDropDown.Value);
            if isequal(app.FindMethodDropDown.Value,'linear')
                mask = app.OutputsForLinear{1};
                % Plot the linear regime
                S1 = app.OutputsForLinear{2};
                S2 = app.OutputsForLinear{3};
            else
                mask = app.OutputsForMeanAndVar{1};
                % Plot the segment mean
                S1 = app.OutputsForMeanAndVar{2};
                S2 = '';
            end
            if doTiledLayout
                needOutLoc = ~isequal(app.OutputTypeDropDown.Value,'largeMask') && app.PlotChangePointsCheckBox.Value;
                [code,inIndex,outIndex] = generateScriptSetupTiledLayout(app,code,needOutLoc);
                a = [getInputDataVarNameForGeneratedScript(app) '.(' inIndex ')'];
                if isequal(app.OutputTypeDropDown.Value,'append')
                    mask = ['newTable.(' outIndex '+' num2str(app.InputSize(2)) ')'];
                elseif isequal(app.OutputTypeDropDown.Value,'table')
                    mask = [mask '.(' outIndex ')'];
                elseif isequal(app.OutputTypeDropDown.Value,'largeMask')
                    mask = [mask '(:,' inIndex ')'];
                else % largeMask or smallMask
                    mask = [mask '(:,' outIndex ')'];
                end
                S1 = [S1 '.(' outIndex ')'];
                S2 = [S2 '.(' outIndex ')'];
                tab = '    ';
            else
                a = addDotIndexingToTableName(app,getInputDataVarNameForGeneratedScript(app));
                if app.InputDataHasTableVars && isequal(app.OutputTypeDropDown.Value,'append')
                    mask = addIndexingIntoAppendedVar(app,'newTable');
                elseif isequal(app.OutputTypeDropDown.Value,'table')
                    mask = addDotIndexingToTableName(app,mask);
                else
                    mask = addSubscriptIndexingToTableName(app,mask);
                end
                S1 = addDotIndexingToTableName(app,S1);
                S2 = addDotIndexingToTableName(app,S2);
                tab = '';
            end

            if app.PlotInputDataCheckBox.Value
                code = generateScriptPlotInputData(app,code,x,a,tab);
                [code,didHoldOn] = addHold(app,code,'on',didHoldOn,numPlots,tab);
            end

            if app.PlotChangeSegmentsCheckBox.Value
                code = [code newline newline tab '% ' char(getMsgText(app,getMsgId('Plotsegments')))];
                if isequal(app.FindMethodDropDown.Value,'linear')
                    % Plot the linear regime
                    markAsVariablesToBeCleared(app,app.OutputsForLinear{2},app.OutputsForLinear{3});
                    if isempty(x)
                        x2 = ['(1:numel(' a '))'''];
                    else
                        x2 = [x '(:)'];
                    end
                    code = [code newline tab 'plot(' x ];
                    code = matlab.internal.dataui.addCharToCode(code,[addComma(app,x) S1 '(:).*' x2 '+' S2 '(:)'],doTiledLayout);
                    code = matlab.internal.dataui.addCharToCode(code,',SeriesIndex="none",',doTiledLayout);
                    code = addDisplayName(app,code,char(getMsgText(app,getMsgId('LinearRegime'))),doTiledLayout);
                else
                    % Plot the segment mean
                    markAsVariablesToBeCleared(app,app.OutputsForMeanAndVar{2});
                    code = [code newline tab 'plot(' x addComma(app,x) S1];
                    code = matlab.internal.dataui.addCharToCode(code,',SeriesIndex="none",',doTiledLayout);
                    code = addDisplayName(app,code,char(getMsgText(app,getMsgId('SegmentMean'))),doTiledLayout);
                end
                [code,didHoldOn] = addHold(app,code,'on',didHoldOn,numPlots,tab);
            end

            if app.PlotChangePointsCheckBox.Value
                code = [code newline newline tab '% ' char(getMsgText(app,getMsgId('Plotchangepoints')))];
                colorCode = 'SeriesIndex=5,';
                code = addVerticalLines(app,code,mask,x,char(getMsgText(app,getMsgId('ChangePoints'))),colorCode,'1',tab);
                code = [code newline tab 'title("' char(getMsgText(app,getMsgId('NumberofChangePoints'))) ': " + nnz(' mask '))'];
            end

            code = [code newline];
            code = addHold(app,code,'off',didHoldOn,numPlots,tab);
            code = addLegendAndAxesLabels(app,code,tab);
            % if only change points, need to set xaxis limits
            if numPlots == 1 && app.PlotChangePointsCheckBox.Value
                code = addXLimits(app,code,x,tab);
            end
            if doTiledLayout
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
                setValueOfComponents(app,["FindMethodDropDown" ...
                   "ThresholdOrMaxNumChangesDropDown" "ThresholdSpinner" ...
                   "MaxNumChangesSpinner" "PlotInputDataCheckBox" ...
                   "PlotChangePointsCheckBox" "PlotChangeSegmentsCheckBox"],state);

                if isfield(state, "DefaultFindMethod")
                    app.DefaultFindMethod = state.DefaultFindMethod;
                end

                app.MaxNumChangesSpinner.Step = matlab.internal.dataui.getStepSize(...
                    app.MaxNumChangesSpinner.Value,true);
                doUpdate(app,false);
            end
        end
    end

    methods
        function summary = get.Summary(app)
            if ~hasInputDataAndSamplePoints(app)
                summary = getMsgText(app,'Tool_changePointsFinder_Description');
                return;
            end
            varName = getInputDataVarNameForSummary(app);
            findMethod = app.FindMethodDropDown.Value;
            findMethod(1) = upper(findMethod(1));
            msgId = [getMsgId('Summary') findMethod];
            summary = getMsgText(app,msgId,varName);
        end

        function state = get.State(app)
            state = struct();
            state.VersionSavedFrom = app.Version;
            state.MinCompatibleVersion = 1;

            state = getInputDataAndSamplePointsDropDownValues(app,state);
            for k = {'FindMethodDropDown' 'ThresholdOrMaxNumChangesDropDown' ...
                    'ThresholdSpinner' 'MaxNumChangesSpinner' ...
                    'PlotInputDataCheckBox' 'PlotChangePointsCheckBox' ...
                    'PlotChangeSegmentsCheckBox'}
                state.([k{1} 'Value']) = app.(k{1}).Value;
            end

            state.DefaultFindMethod = app.DefaultFindMethod;
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
msgId = ['changePointsFinder' id];
end
