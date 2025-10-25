classdef (Hidden = true, Sealed = true) outlierDataCleaner < ...
        matlab.internal.dataui.DataPreprocessingTask & ...
        matlab.internal.dataui.movwindowWidgets
    % outlierDataCleaner Find, fill, or remove outliers in a Live Script
    %
    %   H = outlierDataCleaner constructs a Live Script tool for finding,
    %   filling, or removing outliers and visualizing the results.
    %
    %   See also ISOUTLIER, FILLOUTLIERS, RMOUTLIERS

    %   Copyright 2018-2024 The MathWorks, Inc.

    properties (Access = public, Transient, Hidden)
        % Function parameters
        FindMethodDropDown                  matlab.ui.control.DropDown
        CleanMethodDropDown                 matlab.ui.control.DropDown
        FillMethodDropDown                  matlab.ui.control.DropDown
        FillConstantSpinner                 matlab.ui.control.Spinner
        ThresholdLabel                      matlab.ui.control.Label
        ThresholdSpinner                    matlab.ui.control.Spinner
        PercentilesRangeGrid                matlab.ui.container.GridLayout
        LowerPercentileSpinner              matlab.ui.control.Spinner
        UpperPercentileSpinner              matlab.ui.control.Spinner
        LowerRangeEditField                 matlab.ui.control.EditField
        UpperRangeEditField                 matlab.ui.control.EditField
        OutlierLocationsWSDD                matlab.ui.control.internal.model.WorkspaceDropDown
        % Plot parameters
        PlotTypeLabel                       matlab.ui.control.Label
        PlotTypeDropDown                    matlab.ui.control.DropDown
        PlotFilledCheckBox                  matlab.ui.control.CheckBox
        PlotCleanedDataCheckBox             matlab.ui.control.CheckBox
        PlotInputDataCheckBox               matlab.ui.control.CheckBox
        PlotOutliersCheckBox                matlab.ui.control.CheckBox
        PlotThresholdsCheckBox              matlab.ui.control.CheckBox
        PlotCenterCheckBox                  matlab.ui.control.CheckBox
        PlotOtherRemovedCheckBox            matlab.ui.control.CheckBox
        % Helper: changes on initialize if keyword indicates none or remove
        DefaultCleanMethod  = "fill";
    end

    properties (Constant, Transient, Hidden)
        % Constants
        OutputForArray    = 'cleanedData';
        OutputForTable    = 'newTable';
        OutputIndices     = 'outlierIndices';
        AdditionalOutputs = {'lo' 'hi' 'center'};
        TempIndices       = 'outliersForPlot';
        % Serialization Versions - used for managing forward compatibility
        %     N/A: original ship (R2019b)
        %       2: Add versioning and 'percentiles' find method (R2020b)
        %       3: Multi table vars, table output, histogram plot (R2021a)
        %       4: Use Base Class (R2022a)
        %       5: ConvertToMissing, Append table var, tiledlayout (R2022b)
        %       6: Update clean method initialization by keyword (R2024a)
        %       7: Add 'range' and 'from workspace' detection methods (R2024b)
        Version = 7;
    end

    properties
        Workspace = "base"
        State
        Summary
    end

    methods (Access = protected)
        function createWidgets(app)
            createInputDataSection(app);
            createCleanMethodSection(app);
            createFindMethodSection(app);
            createPlotSection(app,7);
        end

        function adj = getAdjectiveForOutputDropDown(~)
            adj = 'Cleaned';
        end

        function createCleanMethodSection(app)
            h = createNewSection(app,getMsgText(app,getMsgId(app,'ParametersDelimiter1')),{'fit' 'fit' 140 'fit'},1);
            % don't use fit for 3rd column since 'pchip' label is so wide

            % Layout
            uilabel(h,'Text',getMsgText(app,'CleaningMethod'));
            app.CleanMethodDropDown = uidropdown(h);
            app.FillMethodDropDown = uidropdown(h);
            app.FillConstantSpinner = uispinner(h);

            % Properties
            app.CleanMethodDropDown.Items = cellstr([getMsgText(app,getMsgId(app,'Filloutliers')) ...
                getMsgText(app,getMsgId(app,'Removeoutliers')) getMsgText(app,'None')]);
            app.CleanMethodDropDown.ItemsData = {'fill' 'remove' 'none'};
            app.CleanMethodDropDown.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.FillMethodDropDown.Items = cellstr([getMsgText(app,'Constantvalue') ...
                getMsgText(app,getMsgId(app,'ConvertToMissing')) ...
                getMsgText(app,getMsgId(app,'Centervalue')) getMsgText(app,getMsgId(app,'Clipvalue')) ...
                getMsgText(app,'Previousvalue') getMsgText(app,'Nextvalue') ...
                getMsgText(app,'Nearestvalue') getMsgText(app,'Linearinterpolation') ...
                getMsgText(app,'Splineinterpolation') getMsgText(app,'Pchip') getMsgText(app,'Makima')]);
            app.FillMethodDropDown.ItemsData = {'constant' 'convertToMissing' 'center' 'clip' 'previous' 'next' ...
                'nearest' 'linear' 'spline' 'pchip' 'makima'};
            app.FillMethodDropDown.Tooltip = getMsgText(app,getMsgId(app,'FillTooltip'));
            app.FillMethodDropDown.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.FillConstantSpinner.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.FillConstantSpinner.Tag = 'FillConstantSpinner';
        end

        function createFindMethodSection(app)
            h = createNewSection(app,getMsgText(app,getMsgId(app,'ParametersDelimiter2')),{'fit' 125 'fit' 'fit' 'fit'},2);

            % Layout - Row 1
            uilabel(h,'Text',getMsgText(app,getMsgId(app,'DetectionMethod')));
            app.FindMethodDropDown = uidropdown(h);
            app.ThresholdLabel = uilabel(h,'Text',getMsgText(app,getMsgId(app,'ThresholdFactor')));
            app.ThresholdSpinner = uispinner(h);
            app.PercentilesRangeGrid = uigridlayout(h,[1 4],'ColumnWidth',{'fit' 65 'fit' 65},'Padding',0);
            app.PercentilesRangeGrid.Layout.Row = 1;
            app.PercentilesRangeGrid.Layout.Column = 3;
            uilabel(app.PercentilesRangeGrid,'Text',getMsgText(app,getMsgId(app,'LowerThreshold')));
            app.LowerPercentileSpinner = uispinner(app.PercentilesRangeGrid);
            app.LowerRangeEditField = uieditfield(app.PercentilesRangeGrid);
            app.LowerRangeEditField.Layout.Column = 2;
            uilabel(app.PercentilesRangeGrid,'Text',getMsgText(app,getMsgId(app,'UpperThreshold')));
            app.UpperPercentileSpinner = uispinner(app.PercentilesRangeGrid);
            app.UpperRangeEditField = uieditfield(app.PercentilesRangeGrid);
            app.UpperRangeEditField.Layout.Column = 4;
            app.UpperRangeEditField.Layout.Row = 1;
            app.OutlierLocationsWSDD = matlab.ui.control.internal.model.WorkspaceDropDown(Parent = h);
            app.OutlierLocationsWSDD.Layout.Row = 1;
            app.OutlierLocationsWSDD.Layout.Column = 3;

            % Layout - Row 2 - Window widgets
            createWindowWidgets(app,h,2,1,@app.doUpdateFromWidgetChange,getMsgText(app,'Movingwindow'),[]);

            % Properties
            app.FindMethodDropDown.Items = cellstr([getMsgText(app,'Median') ...
                getMsgText(app,'Mean') getMsgText(app,getMsgId(app,'Quartiles')) ...
                getMsgText(app,getMsgId(app,'Grubbs')) getMsgText(app,getMsgId(app,'Gesd')) ...
                getMsgText(app,'Movingmedian') getMsgText(app,'Movingmean') ...
                getMsgText(app,getMsgId(app,'Percentiles')) getMsgText(app,getMsgId(app,'Range')) ...
                getMsgText(app,getMsgId(app,'Workspace'))]);
            app.FindMethodDropDown.ItemsData = {'median' 'mean' 'quartiles' 'grubbs' ...
                'gesd' 'movmedian' 'movmean' 'percentiles' 'range' 'workspace'};
            app.FindMethodDropDown.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.FindMethodDropDown.Tag = 'FindMethodDropDown';
            app.ThresholdSpinner.Limits = [0 Inf];
            app.ThresholdSpinner.Step = 0.25;
            app.ThresholdSpinner.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.LowerPercentileSpinner.Limits = [0 100];
            app.LowerPercentileSpinner.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.LowerPercentileSpinner.Tooltip = getMsgText(app,getMsgId(app,'LowerTooltip'));
            app.LowerPercentileSpinner.Tag = 'LowerPercentileSpinner';
            app.UpperPercentileSpinner.Limits = [0 100];
            app.UpperPercentileSpinner.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.UpperPercentileSpinner.Tooltip = getMsgText(app,getMsgId(app,'UpperTooltip'));
            app.UpperPercentileSpinner.Tag = 'UpperPercentileSpinner';
            app.LowerRangeEditField.ValueChangedFcn = @app.validateRangeValueAndDoUpdate;
            app.LowerRangeEditField.Tag = 'LowerRangeEditField';
            app.LowerRangeEditField.Tooltip = getMsgText(app,getMsgId(app,'Range1Tooltip'));
            app.LowerRangeEditField.HorizontalAlignment = 'right';
            app.UpperRangeEditField.ValueChangedFcn = @app.validateRangeValueAndDoUpdate;
            app.UpperRangeEditField.Tag = 'UpperRangeEditField';
            app.UpperRangeEditField.Tooltip = getMsgText(app,getMsgId(app,'Range2Tooltip'));
            app.UpperRangeEditField.HorizontalAlignment = 'right';
            app.OutlierLocationsWSDD.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.OutlierLocationsWSDD.FilterVariablesFcn = @app.filterOutlierLocations;
            app.OutlierLocationsWSDD.Tooltip = getMsgText(app,getMsgId(app,'WorkspaceTooltip'));
        end

        function createPlotWidgetsRow(app,h)
            % Layout
            app.PlotTypeLabel = uilabel(h);
            app.PlotTypeLabel.Layout.Column = 1;
            app.PlotTypeDropDown = uidropdown(h);
            app.PlotTypeDropDown.Layout.Column = 2;
            app.PlotInputDataCheckBox = uicheckbox(h);
            app.PlotInputDataCheckBox.Layout.Row = 2;
            app.PlotInputDataCheckBox.Layout.Column = 1;
            app.PlotCleanedDataCheckBox = uicheckbox(h);
            app.PlotOutliersCheckBox = uicheckbox(h);
            app.PlotFilledCheckBox = uicheckbox(h);
            app.PlotOtherRemovedCheckBox = uicheckbox(h);
            app.PlotThresholdsCheckBox = uicheckbox(h);
            app.PlotCenterCheckBox = uicheckbox(h);

            % Properties
            app.PlotTypeLabel.Text = getMsgText(app,getMsgId(app,'PlotTypeLabel'));
            app.PlotTypeDropDown.Items = [getMsgText(app,getMsgId(app,'Line')) getMsgText(app,getMsgId(app,'Histogram'))];
            app.PlotTypeDropDown.ItemsData = {'line' 'histogram'};
            app.PlotTypeDropDown.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.PlotFilledCheckBox.Text = getMsgText(app,getMsgId(app,'FilledOutliers'));
            app.PlotFilledCheckBox.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.PlotCleanedDataCheckBox.Text = getMsgText(app,'CleanedData');
            app.PlotCleanedDataCheckBox.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.PlotInputDataCheckBox.Text = getMsgText(app,'InputData');
            app.PlotInputDataCheckBox.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.PlotOutliersCheckBox.Text = getMsgText(app,getMsgId(app,'Outliers'));
            app.PlotOutliersCheckBox.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.PlotThresholdsCheckBox.Text = getMsgText(app,getMsgId(app,'OutlierThresholds'));
            app.PlotThresholdsCheckBox.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.PlotCenterCheckBox.Text = getMsgText(app,getMsgId(app,'OutlierCenter'));
            app.PlotCenterCheckBox.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.PlotOtherRemovedCheckBox.Text = getMsgText(app,'OtherRemovedData');
            app.PlotOtherRemovedCheckBox.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.PlotOtherRemovedCheckBox.Tooltip = getMsgText(app,getMsgId(app,'OtherRemovedTooltip'));
        end

        function updateDefaultsFromKeyword(app,kw)
            % all keywords that are relevant to changing behavior away from
            % default
            keywords = ["isoutlier" "remove" "rmoutliers"];

            % finds first element that the input kw is a prefix for, if any
            kwMatches = startsWith(keywords,kw,'IgnoreCase',true);
            firstMatchIdx = find(kwMatches,1);

            % if not, we don't update anything
            if isempty(firstMatchIdx)
                return;
            end

            % get the corresponding full keyword
            fullKeyword = keywords(firstMatchIdx);

            % for these keywords, we need to map them to the corresponding
            % dropdown value
            if isequal(fullKeyword,"rmoutliers")
                fullKeyword = "remove";
            elseif isequal(fullKeyword,"isoutlier")
                fullKeyword = "none";
            end
            app.DefaultCleanMethod = fullKeyword;
            app.CleanMethodDropDown.Value = fullKeyword;
            doUpdate(app);
        end

        function setWidgetsToDefault(app,fromResetMethod)
            resetCleanMethodItems(app);

            % For tabular data, the default output type is "replace", which
            % does not work with the "none" cleaning method (and removes it
            % from the dropdown) when the task is reset to default. Thus,
            % even if "none" is the default cleaning method, it cannot be
            % chosen. "fill" works for all output types.
            if matches(app.DefaultCleanMethod,app.CleanMethodDropDown.ItemsData)
                app.CleanMethodDropDown.Value = app.DefaultCleanMethod;
            else
                app.CleanMethodDropDown.Value = 'fill';
            end

            app.FillMethodDropDown.Value = 'linear';
            app.FillConstantSpinner.Value = 0;
            app.FillConstantSpinner.Step = 1;
            setWindowDefault(app,evalInputDataVarNameWithCheck(app),...
                evalSamplePointsVarNameWithCheck(app));
            app.FindMethodDropDown.Value = 'movmedian';
            app.ThresholdSpinner.Limits = [0 Inf];
            app.ThresholdSpinner.Value = 3;
            app.LowerPercentileSpinner.Value = 10;
            app.UpperPercentileSpinner.Value = 90;
            app.LowerRangeEditField.Value = '-Inf';
            app.UpperRangeEditField.Value = 'Inf';
            app.OutlierLocationsWSDD.Value = app.SelectVariable;

            fromResetMethod = (nargin > 1) && fromResetMethod; % Called from reset()
            if ~fromResetMethod
                % reset() does not reset the input data, therefore, it does
                % not change wether the app supports visualization or not.
                app.SupportsVisualization = true;
            end
            app.PlotTypeDropDown.Value = 'line';
            app.PlotFilledCheckBox.Value = true;
            app.PlotCleanedDataCheckBox.Value = true;
            app.PlotInputDataCheckBox.Value = true;
            app.PlotOutliersCheckBox.Value = true;
            app.PlotThresholdsCheckBox.Value = true;
            app.PlotCenterCheckBox.Value = false;
            app.PlotOtherRemovedCheckBox.Value = true;
        end

        function resetCleanMethodItems(app,doEval)
            if nargin < 2
                doEval = true;
            end
            % reset to full list
            items = cellstr([getMsgText(app,getMsgId(app,'Filloutliers')) ...
                getMsgText(app,getMsgId(app,'Removeoutliers')) getMsgText(app,'None')]);
            itemsData = {'fill' 'remove' 'none'};
            % Potentially remove option 2 or 3
            optionsToOmit = false(3,1);
            % rmoutliers doesn't make sense with 'append'
            optionsToOmit(2) = app.InputDataHasTableVars && isequal(app.OutputTypeDropDown.Value,'append');
            if doEval && ~optionsToOmit(2)
                % rmoutliers doesn't support ND
                % (note ND table vars are already disallowed)
                A = evalInputDataVarNameWithCheck(app);
                optionsToOmit(2) = optionsToOmit(2) || ~ismatrix(A);
            end
            % isoutlier doesn't make sense with 'replace'
            optionsToOmit(3) = app.InputDataHasTableVars && isequal(app.OutputTypeDropDown.Value,'replace');
            items(optionsToOmit) = [];
            itemsData(optionsToOmit) = [];

            app.CleanMethodDropDown.Items = items;
            app.CleanMethodDropDown.ItemsData = itemsData;
        end

        function changedWidget(app,context,eventData)
            % Update widgets' internal values from callbacks
            context = context.Tag;
            if matches(context,{app.InputDataDropDown.Tag,app.InputDataTableVarDropDown.Tag})
                resetCleanMethodItems(app);
                updateWindowDefault(app);
                app.LowerRangeEditField.Value = '-Inf';
                app.UpperRangeEditField.Value = 'Inf';
                app.OutlierLocationsWSDD.Value = app.SelectVariable;
            elseif isequal(context,app.OutputTypeDropDown.Tag)
                resetCleanMethodItems(app);
                updateWindowDefault(app);
                app.OutlierLocationsWSDD.Value = app.SelectVariable;
            elseif matches(context,{app.SamplePointsDropDown.Tag,app.SamplePointsTableVarDropDown.Tag})
                updateWindowDefault(app);
            elseif isequal(context,app.FillConstantSpinner.Tag)
                app.FillConstantSpinner.Step = matlab.internal.dataui.getStepSize(...
                    app.FillConstantSpinner.Value,false,eventData.PreviousValue);
            elseif isequal(context,app.WindowTypeDropDown.Tag)
                setWindowType(app);
            elseif isequal(context,app.FindMethodDropDown.Tag)
                if ~isequal(app.FindMethodDropDown.Value,'percentiles')
                    if isequal(app.FindMethodDropDown.Value,'gesd') || isequal(app.FindMethodDropDown.Value,'grubbs')
                        app.ThresholdSpinner.Limits = [0 1];
                        if ~(isequal(eventData.PreviousValue,'gesd') || isequal(eventData.PreviousValue,'grubbs'))
                            % only need to reset the value if the meaning of
                            % the threshold is changing
                            app.ThresholdSpinner.Value = 0.5;
                        end
                    else
                        app.ThresholdSpinner.Limits = [0 Inf];
                        if isequal(app.FindMethodDropDown.Value,'quartiles')
                            app.ThresholdSpinner.Value = 1.5;
                        elseif ~ismember(eventData.PreviousValue,{'median' 'mean' 'movmedian' 'movmean'})
                            % only need to reset the value if the meaning of
                            % the threshold is changing
                            app.ThresholdSpinner.Value = 3;
                        end
                    end
                end
            elseif isequal(context,app.LowerPercentileSpinner.Tag)
                app.UpperPercentileSpinner.Value = max(app.LowerPercentileSpinner.Value,...
                    app.UpperPercentileSpinner.Value);
            elseif isequal(context,app.UpperPercentileSpinner.Tag)
                app.LowerPercentileSpinner.Value = min(app.LowerPercentileSpinner.Value,...
                    app.UpperPercentileSpinner.Value);
            end
        end

        function updateWindowDefault(app)
            setWindowDefault(app,evalInputDataVarNameWithCheck(app),...
                evalSamplePointsVarNameWithCheck(app));
        end

        function updateWidgets(app,doEvalinBase)
            % Update the layout and visibility of the widgets

            updateInputDataAndSamplePointsDropDown(app);
            hasData = hasInputDataAndSamplePoints(app);

            % Clean section
            app.CleanMethodDropDown.Enable = hasData;
            doFill = isequal(app.CleanMethodDropDown.Value,'fill');
            app.FillMethodDropDown.Visible = doFill;
            app.FillMethodDropDown.Enable = hasData;
            doConst = doFill && isequal(app.FillMethodDropDown.Value,'constant');
            app.FillConstantSpinner.Visible = doConst;
            matlab.internal.dataui.setParentForWidgets([app.FillMethodDropDown app.FillConstantSpinner],...
                app.CleanMethodDropDown.Parent);

            % Find section
            % Update items list based on previous selections
            items = cellstr([getMsgText(app,'Median') ...
                getMsgText(app,'Mean') getMsgText(app,getMsgId(app,'Quartiles')) ...
                getMsgText(app,getMsgId(app,'Grubbs')) getMsgText(app,getMsgId(app,'Gesd')) ...
                getMsgText(app,'Movingmedian') getMsgText(app,'Movingmean') ...
                getMsgText(app,getMsgId(app,'Percentiles')) getMsgText(app,getMsgId(app,'Range')) ...
                getMsgText(app,getMsgId(app,'Workspace'))]);
            itemsData = {'median' 'mean' 'quartiles' 'grubbs' ...
                'gesd' 'movmedian' 'movmean' 'percentiles' 'range' 'workspace'};
            if doFill && isequal(app.FillMethodDropDown.Value,"center")
                % Range and Workspace-defined outliers not valid for
                % 'center' fill method
                items(end-1:end) = [];
                itemsData(end-1:end) = [];
            elseif isAppWorkflow(app) || (doFill && isequal(app.FillMethodDropDown.Value,"clip")) ||...
                    isequal(app.CleanMethodDropDown.Value,'none')
                items(end) = [];
                itemsData(end) = [];
            end
            app.FindMethodDropDown.Items = items;
            app.FindMethodDropDown.ItemsData = itemsData;
            app.FindMethodDropDown.Enable = hasData;
            app.ThresholdSpinner.Enable = hasData;
            app.LowerPercentileSpinner.Enable = hasData;
            app.UpperPercentileSpinner.Enable = hasData;
            app.LowerRangeEditField.Enable = hasData;
            app.UpperRangeEditField.Enable = hasData;
            app.OutlierLocationsWSDD.Enable = hasData;
            findMethod = app.FindMethodDropDown.Value;
            ispercentiles = isequal(findMethod,"percentiles");
            isrange = isequal(findMethod,"range");
            isworkspace = isequal(findMethod,"workspace");
            app.ThresholdLabel.Visible = ~(ispercentiles || isrange || isworkspace);
            app.ThresholdSpinner.Visible = ~(ispercentiles || isrange || isworkspace);
            app.PercentilesRangeGrid.Visible = ispercentiles || isrange; % Contains upper/lower labels
            app.LowerPercentileSpinner.Visible = ispercentiles;
            app.UpperPercentileSpinner.Visible = ispercentiles;
            app.LowerRangeEditField.Visible = isrange;
            app.UpperRangeEditField.Visible = isrange;
            app.OutlierLocationsWSDD.Visible = isworkspace;
            matlab.internal.dataui.setParentForWidgets([app.ThresholdLabel ...
                app.ThresholdSpinner app.PercentilesRangeGrid app.OutlierLocationsWSDD],...
                app.FindMethodDropDown.Parent);
            % Update threshold spinner tooltip dynamically based on defn
            if isequal(findMethod,'grubbs') || isequal(findMethod,'gesd')
                app.ThresholdSpinner.Tooltip = getMsgText(app,getMsgId(app,'ThresholdTooltipG'));
            elseif isequal(findMethod,'median') || isequal(findMethod,'movmedian')
                app.ThresholdSpinner.Tooltip = getMsgText(app,getMsgId(app,'ThresholdTooltipMedian'));
            elseif isequal(findMethod,'mean') || isequal(findMethod,'movmean')
                app.ThresholdSpinner.Tooltip = getMsgText(app,getMsgId(app,'ThresholdTooltipMean'));
            elseif isequal(findMethod,'quartiles')
                app.ThresholdSpinner.Tooltip = getMsgText(app,getMsgId(app,'ThresholdTooltipQ'));
            end
            % Show hide moving window controls
            doMov = isequal(findMethod,'movmedian') || isequal(findMethod,'movmean');
            app.FindMethodDropDown.Parent.RowHeight{2} = doMov*app.TextRowHeight;
            if doEvalinBase
                hasUnits = hasDurationOrDatetimeSamplePoints(app);
                setWindowVisibility(app,doMov,hasData,hasUnits);
            else
                setWindowVisibility(app,doMov,hasData);
            end

            % Plot section
            if doMov
                app.PlotTypeDropDown.Value = 'line';
            end
            % Enable
            app.PlotTypeDropDown.Enable = hasData;
            app.PlotFilledCheckBox.Enable = hasData;
            app.PlotCleanedDataCheckBox.Enable = hasData;
            app.PlotInputDataCheckBox.Enable = hasData;
            app.PlotOutliersCheckBox.Enable = hasData;
            app.PlotThresholdsCheckBox.Enable = hasData;
            app.PlotCenterCheckBox.Enable = hasData;
            app.PlotOtherRemovedCheckBox.Enable = hasData;
            % Visible
            doShow = showPlotCheckboxes(app,...
                app.PlotTypeLabel,app.PlotTypeDropDown,...
                app.PlotInputDataCheckBox,app.PlotCleanedDataCheckBox,...
                app.PlotFilledCheckBox,app.PlotOutliersCheckBox,...
                app.PlotThresholdsCheckBox, app.PlotCenterCheckBox,...
                app.PlotOtherRemovedCheckBox);
            if isrange || isworkspace
                % Center not defined
                app.PlotCenterCheckBox.Visible = false;
                app.PlotCenterCheckBox.Value = false;
            end
            if isworkspace
                % Thresholds not defined
                app.PlotThresholdsCheckBox.Visible = false;
                app.PlotThresholdsCheckBox.Value = false;
            end
            showPlotType = doShow && ~doMov;
            app.PlotTypeLabel.Visible = showPlotType;
            app.PlotTypeDropDown.Visible = showPlotType;
            showCleaned = doShow && isequal(app.CleanMethodDropDown.Value,'fill') || ...
                (isequal(app.CleanMethodDropDown.Value,'remove') && isequal(app.PlotTypeDropDown.Value,'line'));
            app.PlotCleanedDataCheckBox.Visible = showCleaned;
            app.PlotFilledCheckBox.Visible = doShow && isequal(app.CleanMethodDropDown.Value,'fill') && ...
                isequal(app.PlotTypeDropDown.Value,'line');
            app.PlotOtherRemovedCheckBox.Visible = doShow && ...
                isequal(app.CleanMethodDropDown.Value,'remove') && ...
                hasMultipleDataVariables(app) && numel(app.TableVarNamesForDD) > 1;
            % Shift some controls due to others being invisible
            app.DisplayVariableLabel.Layout.Column = 1 + 2*showPlotType;
            app.TableVarPlotDropDown.Layout.Column = 2 + 2*showPlotType;
            app.PlotOutliersCheckBox.Layout.Column = 2 + showCleaned;
            app.PlotFilledCheckBox.Layout.Column = 3 + showCleaned;
            app.PlotOtherRemovedCheckBox.Layout.Column = 3 + showCleaned;
            showFilledOrRemoved = app.PlotFilledCheckBox.Visible || app.PlotOtherRemovedCheckBox.Visible;
            app.PlotThresholdsCheckBox.Layout.Column = 3 + showCleaned + showFilledOrRemoved;
            app.PlotCenterCheckBox.Layout.Column = 4 + showCleaned + showFilledOrRemoved;
            % Unparent invisible widgets so the checkbox spacing is correct
            plotGrid = app.Accordion.Children(end).Children.Children(1);
            matlab.internal.dataui.setParentForWidgets([app.PlotTypeLabel ...
                app.PlotTypeDropDown app.PlotCleanedDataCheckBox app.PlotFilledCheckBox ...
                app.PlotOtherRemovedCheckBox app.PlotThresholdsCheckBox app.PlotCenterCheckBox],plotGrid);
        end

        function tf = filterInputData(~,A,isTableVar)
            % Keep only Input Data of supported type
            if isa(A,'tabular') % table or timetable
                tf = ~isTableVar; % No tables within tables
            else
                % Copied from filloutliers.m
                % additional nonempty restriction
                tf = ~isempty(A) && isfloat(A) && isreal(A);
            end
        end

        function tf = filterSamplePointsType(~,X,isTableVar)
            % Keep only Sample Points (X-axis) of supported type
            if istall(X)
                tf = false;
            elseif isa(X,'tabular') % table or timetable
                tf = ~isTableVar; % No tables within tables
            else
                % Copied from filloutliers.m checkSamplePoints()
                tf = (isvector(X) || isempty(X)) && ...
                    ((isfloat(X) && isreal(X) && ~issparse(X)) || ...
                    isduration(X) || isdatetime(X));
            end
        end

        function tf = filterOutlierLocations(app,loc)
            % Filter function for OutlierLocationsWSDD. Called on workspace
            % variables to determine if they are allowed in the Items list.
            tf = false;
            didClear = checkForClearedWorkspaceVariables(app);
            if ~hasInputData(app)
                if didClear
                    doUpdate(app);
                end
                return
            end
            % Matches requirements found in filloutliers
            if ~(islogical(loc) || istabular(loc))
                % Input must be logical or tabular containing only logicals
                % Check for logical types inside tabular later after
                % varname and size check
                return
            end
            % Else, also check the size requirement
            sizeLoc = size(loc);
            A = evalInputDataVarNameWithCheck(app);
            if istabular(A)
                smalltable = getSelectedSubTable(app,A);
                if istabular(loc)
                    dvnames = smalltable.Properties.VariableNames;
                    if ~isequal(sort(dvnames),sort(loc.Properties.VariableNames))
                        % All selected vars must have a corresponding var
                        % in loc. And because sometimes we use indexing
                        % instead of dataVar NV pair, the reverse must also
                        % be true so the OutlierLocations accurately
                        % defines the data vars.
                        tf = false;
                    else
                        % the corresponding var must be logical vector
                        for k = string(dvnames)
                            tf = islogical(loc.(k)) && isvector(loc.(k));
                            if ~tf
                                return
                            end
                        end
                    end
                elseif isequal(app.OutputTypeDropDown.Value,'smalltable')
                    % logical loc must match size of smalltable since that
                    % is what is passed into *outliers
                    tf = isequal(sizeLoc,size(smalltable));
                else % replace or append
                    % logical loc must match size of A
                    tf = isequal(sizeLoc,size(A));
                end
            else
                % non-tabular input to *outliers
                tf = islogical(loc) && isequal(sizeLoc,size(A));
            end
        end

        function validateRangeValueAndDoUpdate(app,src,ev)
            % Callback for upper and lower range editfields. Note, we do
            % this validation here rather than changedWidget like other
            % control-specific actions to avoid the full doUpdate when
            % the Value is just going to get reverted anyway
            val = str2num(src.Value,Evaluation = "restricted"); %#ok<ST2NM>
            if isempty(val) || ~isvector(val) || ~isreal(val) || anymissing(val)
                % Not a number or a valid vector
                src.Value = ev.PreviousValue;
                return
            elseif ~isscalar(val)
                % Calculate input width
                A = evalInputDataVarNameWithCheck(app);
                if istabular(A)
                    A = getSelectedSubTable(app,A);
                end
                if numel(val) ~= width(A) || isrow(A)
                    % Vector size does not match input size. Note: dim is
                    % always 1 except for row vector inputs. But in the
                    % case of row vector input, then val must be scalar
                    src.Value = ev.PreviousValue;
                    return
                end
            end
            % Use mat2str for correct display, this may add brackets if
            % user left them off which is necessary for generateScript
            src.Value = mat2str(val(:)');
            % Disallow lower > upper (clip requirement) by resetting the
            % editfield that is not currently being touched by the user
            lowerThreshold = str2num(app.LowerRangeEditField.Value); %#ok<ST2NM>
            upperThreshold = str2num(app.UpperRangeEditField.Value); %#ok<ST2NM>
            if any(lowerThreshold > upperThreshold)
                if isequal(src.Tag,"LowerRangeEditField")
                    % User touched lower, so manually update upper
                    upperThreshold = max(lowerThreshold,upperThreshold);
                    app.UpperRangeEditField.Value = mat2str(upperThreshold);
                else
                    % User touched upper, so manually update lower
                    lowerThreshold = min(lowerThreshold,upperThreshold);
                    app.LowerRangeEditField.Value = mat2str(lowerThreshold);
                end
            end
            % Continue with the standard callback
            doUpdateFromWidgetChange(app,src,ev);
        end

        function propTable = getLocalPropertyInformation(app)
            windowTable = getWindowProperties(app);
            Name = ["CleanMethodDropDown"; "FillMethodDropDown"; "FillConstantSpinner";...
                "FindMethodDropDown"; "ThresholdSpinner"; ...
                "LowerPercentileSpinner"; "UpperPercentileSpinner";...
                "LowerRangeEditField"; "UpperRangeEditField";
                windowTable.Name; "PlotTypeDropDown"];
            Group = [repmat(getMsgText(app,getMsgId(app,'ParametersDelimiter1')),3,1);...
                repmat(getMsgText(app,getMsgId(app,'ParametersDelimiter2')),6,1);...
                windowTable.Group; getMsgText(app,'Visualizeresults')];
            DisplayName = [getMsgText(app,'CleaningMethod'); getMsgText(app,'FillMethod'); getMsgText(app,'Constantvalue');...
                getMsgText(app,getMsgId(app,'DetectionMethod')); getMsgText(app,getMsgId(app,'ThresholdFactor'));...
                getMsgText(app,getMsgId(app,'LowerThreshold')); getMsgText(app,getMsgId(app,'UpperThreshold'));...
                getMsgText(app,getMsgId(app,'LowerThreshold')); getMsgText(app,getMsgId(app,'UpperThreshold'));...
                windowTable.DisplayName; getMsgText(app,getMsgId(app,'PlotTypeLabel'))];
            StateName = Name + "Value";
            StateName(10:end-1) = windowTable.StateName;

            propTable = table(Name,Group,DisplayName,StateName);
            propTable = addFieldsToPropTable(app,propTable);
            % Coerce range editfields to show up as numeric in app
            propTable.StateName([8 9]) = ["LowerRangeEditFieldNumValue" "UpperRangeEditFieldNumValue"];
            propTable.Type([8 9]) = {'matlab.ui.control.NumericEditField' 'matlab.ui.control.NumericEditField'};
        end

        function rhs = generateOptionalOutputNames(app,doCommasAndTildas)
            % Used by generateScript to know which outputs to generate
            % Used by generateVisualizationScript to know which outputs to
            % clear
            findmethod = app.FindMethodDropDown.Value;
            isrange = isequal(findmethod,"range");
            if (isrange && doCommasAndTildas) || isequal(findmethod,'workspace')
                % Center not supported and thresholds come from editfield
                % values, so no extra outputs needed for outlier functions
                % OR both center and thresholds not supported (or defined!)
                rhs = {};
                return
            end
            mask = [app.PlotThresholdsCheckBox.Value app.PlotCenterCheckBox.Value];
            if isequal(app.PlotTypeDropDown.Value,'histogram')
                % need thresholds for bin edges
                mask(1) = mask(1) || app.PlotInputDataCheckBox.Value || app.PlotOutliersCheckBox.Value || ...
                    (app.PlotCleanedDataCheckBox.Value && app.PlotCleanedDataCheckBox.Visible) || ...
                    (app.PlotOtherRemovedCheckBox.Value && app.PlotOtherRemovedCheckBox.Visible);
            end
            % separate out thresholds
            mask = [mask(1) mask(1) mask(2)];
            if isrange
                % Only need threshold in a variable if vector-valued
                % Otherwise no temp var needed so nothing to clear
                mask(1) = mask(1) && startsWith(app.LowerRangeEditField.Value,'[');
                mask(2) = mask(2) && startsWith(app.UpperRangeEditField.Value,'[');
            end
            ind = find(mask);
            rhs(ind) = app.AdditionalOutputs(ind);
            if doCommasAndTildas
                % Set outputs to ~ without consecutive trailing ~
                rhs(cellfun(@isempty,rhs)) = {'~'};
                % Add commas in between variables
                rhs(2*(1:numel(rhs))) = rhs;
                rhs(1:2:end) = {','};
            else
                rhs(cellfun(@isempty,rhs)) = [];
            end
        end

        function msgId = getMsgId(~,id)
            msgId = ['outlierDataCleaner' id];
        end
    end

    methods (Access = public)
        % Required for embedding in a Live Script

        % implemented in generateScript.m
        [code,outputs] = generateScript(app,isForExport,overwriteInput);

        % implemented in generateVisualizationScript.m
        code = generateVisualizationScript(app);

        function setTaskState(app,state,updatedWidget)
            if nargin < 3
                % With nargin == 2, setState is used by live editor and
                % Data Cleaner App for save/load, undo/redo
                updatedWidget = '';
            else
                % With nargin == 3, setState is used by the Data Cleaner
                % App to change the value of a control from the property
                % inspector

                % App changes state values directly rather than using the
                % Is* state fields that exist for save/load
                state.IsPercentiles = isequal(state.FindMethodDropDownValue,'percentiles');
                state.IsRange = isequal(state.FindMethodDropDownValue,'range');
                state.IsConvertToMissing = isequal(state.FillMethodDropDownValue,'convertToMissing');
                % App uses numeric Values for Range instead of text like
                % the live task UI
                state.LowerRangeEditFieldValue = mat2str(state.LowerRangeEditFieldNumValue);
                state.UpperRangeEditFieldValue = mat2str(state.UpperRangeEditFieldNumValue);
                event = struct();
                if matches(updatedWidget,{'FillConstantSpinner' 'FindMethodDropDown' ...
                        'UpperRangeEditField' 'LowerRangeEditField'})
                    % For these controls, the changedWidget method requires the
                    % PreviousValue to make the appropriate update
                    event.PreviousValue = app.(updatedWidget).Value;
                end
            end            

            if ~isfield(state,'VersionSavedFrom')
                % From initial ship
                state.VersionSavedFrom = 1;
                state.MinCompatibleVersion = 1;
            end
            if app.Version < state.MinCompatibleVersion
                % state comes from a future, incompatible version do not
                % set any properties
                doUpdate(app,false);
                return
            end

            setInputDataAndSamplePointsDropDownValues(app,state);
            setWindowDropDownValues(app,state);
            setValueOfComponents(app,["FindMethodDropDown" ...
                "CleanMethodDropDown" "FillMethodDropDown" ...
                "FillConstantSpinner" "ThresholdSpinner" ...
                "LowerPercentileSpinner" "UpperPercentileSpinner" ...
                "LowerRangeEditField" "UpperRangeEditField" ...
                "PlotFilledCheckBox" "PlotCleanedDataCheckBox" ...
                "PlotInputDataCheckBox" "PlotOutliersCheckBox" ...
                "PlotThresholdsCheckBox" "PlotCenterCheckBox" ...
                "PlotTypeDropDown" "PlotOtherRemovedCheckBox"],state);

            if isfield(state,'DefaultCleanMethod')
                app.DefaultCleanMethod = state.DefaultCleanMethod;
            end

            if isfield(state,'IsPercentiles') && state.IsPercentiles
                app.FindMethodDropDown.Value = 'percentiles';
            elseif isfield(state,'IsRange') && state.IsRange
                app.FindMethodDropDown.Value = 'range';
            elseif isfield(state,'IsLocFromWorkspace') && state.IsLocFromWorkspace
                app.FindMethodDropDown.Value = 'workspace';
            end

            if isfield(state,'IsConvertToMissing') && state.IsConvertToMissing
                app.FillMethodDropDown.Value = 'convertToMissing';
            end
            if ~isfield(state,'PlotTypeDropDownValue')
                % comes from a previous version, set to default
                app.PlotTypeDropDown.Value = 'line';
            end

            if isempty(updatedWidget)
                resetCleanMethodItems(app,false);
                app.FillConstantSpinner.Step = matlab.internal.dataui.getStepSize(...
                    app.FillConstantSpinner.Value,false);
                doUpdate(app,false);
            elseif matches(updatedWidget,["LowerRangeEditField" "UpperRangeEditField"])
                validateRangeValueAndDoUpdate(app,app.(updatedWidget),event);
            else
                doUpdateFromWidgetChange(app,app.(updatedWidget),event);
            end
        end

        function msg = getInspectorDisplayMsg(app)
            msg = '';
            if hasInputData(app,false) && isscalar(app.InputDataTableVarDropDown(1).Items)
                % display a message indicating that there are no valid
                % variables in the table
                msg = getMsgText(app,getMsgId(app,'NoValidVars'));
            end
        end
    end

    methods
        function summary = get.Summary(app)
            if ~hasInputDataAndSamplePoints(app)
                summary = getMsgText(app,'Tool_outlierDataCleaner_Description');
                return;
            end
            varName = getInputDataVarNameForSummary(app);
            cleanMethod = app.CleanMethodDropDown.Value;
            cleanMethod(1) = upper(cleanMethod(1));
            msgId = [getMsgId(app,'Summary') cleanMethod];
            if isequal(cleanMethod,'Fill')
                method = app.FillMethodDropDown.Value;
                methodStr = app.FillMethodDropDown.Items{ismember(app.FillMethodDropDown.ItemsData,method)};
                methodStr(1) = lower(methodStr(1));
                summary = getMsgText(app,msgId,varName,methodStr);
            else
                summary = getMsgText(app,msgId,varName);
            end
        end

        function state = get.State(app)
            state = struct();
            state.VersionSavedFrom = app.Version;
            state.MinCompatibleVersion = 1;

            state = getInputDataAndSamplePointsDropDownValues(app,state);
            state = getWindowDropDownValues(app,state);
            for k = {'FindMethodDropDown' ...
                    'CleanMethodDropDown' 'FillMethodDropDown' ...
                    'FillConstantSpinner' 'ThresholdSpinner' ...
                    'LowerPercentileSpinner' 'UpperPercentileSpinner' ...
                    'LowerRangeEditField' 'UpperRangeEditField' ...
                    'OutlierLocationsWSDD' ...
                    'PlotFilledCheckBox' 'PlotCleanedDataCheckBox' ...
                    'PlotInputDataCheckBox' 'PlotOutliersCheckBox' ...
                    'PlotThresholdsCheckBox' 'PlotCenterCheckBox' ...
                    'PlotTypeDropDown' 'PlotOtherRemovedCheckBox'}
                state.([k{1} 'Value']) = app.(k{1}).Value;
            end
            state.IsPercentiles = isequal(state.FindMethodDropDownValue,'percentiles');
            state.IsRange = isequal(state.FindMethodDropDownValue,'range');
            state.IsLocFromWorkspace = isequal(state.FindMethodDropDownValue,'workspace');
            state.IsConvertToMissing = isequal(state.FillMethodDropDownValue,'convertToMissing');
            if ~isAppWorkflow(app) && (state.IsPercentiles || state.IsRange || state.IsLocFromWorkspace)
                % to be able to save and open in older versions, set dd
                % value to value in old ItemsData, median was default
                state.FindMethodDropDownValue = 'median';
            end
            if state.IsConvertToMissing && ~isAppWorkflow(app)
                state.FillMethodDropDownValue = 'linear';
            end
            if isAppWorkflow(app)
                % We can use the numeric editfield in app since vectors are
                % supported
                state.UpperRangeEditFieldNumValue = str2num(app.UpperRangeEditField.Value); %#ok<ST2NM>
                state.LowerRangeEditFieldNumValue = str2num(app.LowerRangeEditField.Value); %#ok<ST2NM>
            end

            state.DefaultCleanMethod = app.DefaultCleanMethod;
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
