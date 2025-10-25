classdef (Hidden = true, Sealed = true) trendRemover < ...
        matlab.internal.dataui.DataPreprocessingTask
    % trendRemover Remove polynomial trends in a Live Script
    %
    %   H = trendRemover constructs a Live Script tool for removing
    %   polynomial trends from data.
    %
    %   See also DETREND
    
    %   Copyright 2019-2024 The MathWorks, Inc.
    
    properties (Access = public, Transient, Hidden)
        HomeButton                          matlab.ui.control.Image
        % Widgets
        OutputWorkflowDropDown              matlab.ui.control.DropDown
        DegreeDropDown                      matlab.ui.control.DropDown
        DegreeSpinner                       matlab.ui.control.Spinner
        MissingCheckBox                     matlab.ui.control.CheckBox
        BreakPointsDropDown                 matlab.ui.control.DropDown
        ContinuousCheckBox                  matlab.ui.control.CheckBox
        BreakPointsSpinner                  matlab.ui.control.Spinner
        BreakPointsWSDropDown               matlab.ui.control.internal.model.WorkspaceDropDown
        BreakPointsAxes                     matlab.graphics.axis.Axes
        ClearBreakPointsButton              matlab.ui.control.Button
        BreakPointValueLabelNum             matlab.ui.control.NumericEditField
        BreakPointValueLabelDT              matlab.ui.control.EditField
        BreakPointValueLabelDur             matlab.ui.control.NumericEditField
        BreakPointUnitLabelDur              matlab.ui.control.EditField
        DeleteButton                        matlab.ui.control.Button
        
        % Plot CheckBoxes
        PlotInputDataCheckBox               matlab.ui.control.CheckBox
        PlotDetrendedDataCheckBox           matlab.ui.control.CheckBox
        PlotTrendCheckBox                   matlab.ui.control.CheckBox
        PlotBreakPointsCheckBox             matlab.ui.control.CheckBox
    end
    
    properties (Access = public, Transient, Hidden)
        % Used by interactive plot
        SelectedBreakPoints                 double
        AxesStruct                          struct
        replotOnGenerateScript              logical
        UnitToMilliseconds                  double 
        % Used for output plot
        BreakPointsIsLogical                logical
    end
    
    properties (Constant, Transient, Hidden)
        OutputVectorName  = 'detrendedData';
        OutputTableName   = 'newTable';
        TrendOutputName   = 'trends';
        AxesWidth         = 600;
        AxesHeight        = 240;
        LabelFontSize     = 12;
        % Serialization Versions - used for managing forward compatibility
        %   N/A: original ship (R2019b)
        %     2: Add versioning (R2020b)
        %     3: Table output (R2021a)
        %     4: Use Base Class (R2022a)
        %     5: Append table vars and tiled layout (R2022b)
        %     6: Add Find functionality, subtask to FindTrendsTask (R2023a)
        Version = 6;
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
            % UIFigure property not created yet, use LayoutManager.Parent
            app.LayoutManager.Parent.WindowButtonUpFcn = @app.buttonUpFcn;
            app.replotOnGenerateScript = false;
            
            createInputDataSection(app);
            outputLabel = app.Accordion.Children(1).Children.Children(5);
            outputLabel.Text = getMsgText(app,getMsgId('Output'));
            app.OutputWorkflowDropDown = uidropdown(app.Accordion.Children(1).Children,...
                'Items',[getMsgText(app,getMsgId('RemoveTrends')) getMsgText(app,getMsgId('FindTrends'))],...
                'ItemsData',{'remove' 'find'},...
                'ValueChangedFcn',@app.doUpdateFromWidgetChange);
            app.OutputWorkflowDropDown.Layout.Row = 3;
            app.OutputWorkflowDropDown.Layout.Column = 2;
            app.OutputTypeDropDown.Layout.Column = [3 4];
            
            S = createNewSection(app,getMsgText(app,getMsgId('ParametersDelimiter')),{'fit'},2);
            S.RowHeight = {'fit','fit'};
            createParametersRows(app,S);
            createAxesRow(app,S);
            
            createPlotSection(app,4);

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
        
        function createParametersRows(app,S)
            % Layout
            r = app.TextRowHeight;
            h = uigridlayout(S,'Padding',0,'RowHeight',{r r},...
                'ColumnWidth',{'fit','fit','fit','fit'});
            
            uilabel(h,'Text',getMsgText(app,getMsgId('Degree')));
            app.DegreeDropDown = uidropdown(h);
            app.DegreeSpinner = uispinner(h);
            app.MissingCheckBox = uicheckbox(h);
            uilabel(h,'Text',getMsgText(app,getMsgId('Breakpoints')));
            app.BreakPointsDropDown = uidropdown(h);
            app.BreakPointsSpinner = uispinner(h);
            app.BreakPointsWSDropDown = matlab.ui.control.internal.model.WorkspaceDropDown('Parent',h);
            app.BreakPointsWSDropDown.ShowNonExistentVariable = true;
            app.BreakPointsWSDropDown.Layout.Column = 3;
            app.ContinuousCheckBox = uicheckbox(h);
            app.ContinuousCheckBox.Layout.Column = 4;
            app.ClearBreakPointsButton = uibutton(h,'Text',getMsgText(app,getMsgId('ClearBreakpoints')));
            app.ClearBreakPointsButton.Layout.Column = 3;
            app.ClearBreakPointsButton.Layout.Row = 2;
                        
            % Properties
            app.DegreeDropDown.Items = cellstr([getMsgText(app,getMsgId('Constant')),...
                getMsgText(app,getMsgId('Linear')),getMsgText(app,getMsgId('Quadratic')),...
                getMsgText(app,getMsgId('Cubic')),getMsgText(app,getMsgId('Custom'))]);
            app.DegreeDropDown.ItemsData = [0:3 -1];
            app.DegreeDropDown.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            
            app.DegreeSpinner.Step = 1;
            app.DegreeSpinner.RoundFractionalValues = true;
            app.DegreeSpinner.Limits = [0,inf];
            app.DegreeSpinner.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.DegreeSpinner.Tooltip = getMsgText(app,getMsgId('DegreeSpinnerTooltip'));
            
            app.MissingCheckBox.Text = getMsgText(app,getMsgId('FillMissing'));
            app.MissingCheckBox.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.MissingCheckBox.Tooltip = getMsgText(app,getMsgId('MissingTooltip'));
            
            app.BreakPointsDropDown.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.BreakPointsDropDown.Tooltip = getMsgText(app,getMsgId('BreakPointsTooltip'));
            app.BreakPointsDropDown.Items = cellstr([getMsgText(app,'None'),...
                getMsgText(app,getMsgId('Selectfromplot')), getMsgText(app,getMsgId('Linearlyspaced')),...
                getMsgText(app,getMsgId('Choosefromworkspace'))]);
            app.BreakPointsDropDown.ItemsData = {'none' 'interactive' 'linearlyspaced' 'fromworkspace'};
            app.BreakPointsDropDown.Tag = 'BreakPointsDropDown';
            
            app.BreakPointsWSDropDown.FilterVariablesFcn = @app.filterBreakPointsFromWorkspace;
            app.BreakPointsWSDropDown.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.BreakPointsWSDropDown.Tag = 'BreakPointsWSDropDown';
            
            app.BreakPointsSpinner.Limits = [0 inf];
            app.BreakPointsSpinner.RoundFractionalValues = true;
            app.BreakPointsSpinner.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.BreakPointsSpinner.Tooltip = getMsgText(app,getMsgId('BreakPointsSpinnerTooltip'));
            
            app.ContinuousCheckBox.Text = getMsgText(app,getMsgId('Continuous'));
            app.ContinuousCheckBox.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.ContinuousCheckBox.Tooltip = getMsgText(app,getMsgId('ContinuousTooltip'));
            
            app.ClearBreakPointsButton.ButtonPushedFcn = @app.doUpdateFromWidgetChange;
            app.ClearBreakPointsButton.Tag = 'ClearBreakPointsButton';
        end
        
        function createAxesRow(app,S)
            h = uigridlayout(S,'Padding',0,'RowHeight',{app.AxesHeight},'ColumnWidth',{app.AxesWidth});
            
            p = uipanel(h,'BorderType','none');
            p.Tooltip = getMsgText(app,getMsgId('AxesTooltip'));
            app.BreakPointsAxes = axes(p);
            app.BreakPointsAxes.Position(2) = app.BreakPointsAxes.Position(2)+.075; 
            app.BreakPointsAxes.Position(4) = app.BreakPointsAxes.Position(4)-.075;
            app.BreakPointsAxes.ActivePositionProperty = 'outerposition';
            matlab.graphics.interaction.enableInteractivityOnButtonDown(app.BreakPointsAxes);
            matlab.graphics.interaction.enableToolbarOnButtonDown(app.BreakPointsAxes);
            
            app.AxesStruct = struct('highlightedBP','','markForUnselect',true,'idx',[],'shadow','');
            app.BreakPointValueLabelNum = uieditfield(p,'numeric','Visible','off',...
                'HorizontalAlignment','center','ValueChangedFcn',@app.numericLabelChange,...
                'Tooltip',getMsgText(app,getMsgId('BPLabelTooltip')),...
                'LowerLimitInclusive','off','UpperLimitInclusive','off');
            app.BreakPointValueLabelDT = uieditfield(p,'Visible','off',...
                'HorizontalAlignment','center','ValueChangedFcn',@app.datetimeOrDurationLabelChange,...
                'Tooltip',getMsgText(app,getMsgId('BPLabelTooltip')));
            app.BreakPointValueLabelDur = uieditfield(p,'numeric','Visible','off',...
                'HorizontalAlignment','center','ValueChangedFcn',@app.durationLabelChange,...
                'Tooltip',getMsgText(app,getMsgId('BPLabelTooltip')),...
                'LowerLimitInclusive','off','UpperLimitInclusive','off');
            app.BreakPointUnitLabelDur = uieditfield(p,'Visible','off','Editable','off',...
                'FontSize',app.LabelFontSize,'FontName','monospaced');
            app.DeleteButton = uibutton(p,'Text','','ButtonPushedFcn',@app.deleteSelectedBP,...
                'Tooltip',getMsgText(app,getMsgId('DeleteTooltip')),'IconAlignment','center');
            matlab.ui.control.internal.specifyIconID(app.DeleteButton,'deleteBorderlessUI',...
                app.IconWidth,app.IconWidth);
        end
        
        function createPlotWidgetsRow(app,h)
            % Layout
            app.PlotInputDataCheckBox = uicheckbox(h);
            app.PlotInputDataCheckBox.Layout.Row = 2;
            app.PlotInputDataCheckBox.Layout.Column = 1;
            app.PlotDetrendedDataCheckBox = uicheckbox(h);
            app.PlotTrendCheckBox = uicheckbox(h);
            app.PlotBreakPointsCheckBox = uicheckbox(h);
            
            % Properties
            app.PlotDetrendedDataCheckBox.Text = getMsgText(app,getMsgId('DetrendedData'));
            app.PlotDetrendedDataCheckBox.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.PlotInputDataCheckBox.Text = getMsgText(app,'InputData');
            app.PlotInputDataCheckBox.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.PlotTrendCheckBox.Text = getMsgText(app,getMsgId('Trend'));
            app.PlotTrendCheckBox.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.PlotBreakPointsCheckBox.Text = getMsgText(app,getMsgId('Breakpoints'));
            app.PlotBreakPointsCheckBox.ValueChangedFcn = @app.doUpdateFromWidgetChange;
        end
                
        function setWidgetsToDefault(app,fromResetMethod)
            app.OutputWorkflowDropDown.Value = 'remove';
            setSpinnerLimits(app);
            app.DegreeDropDown.Value = 1;
            app.DegreeSpinner.Value = 4;
            app.MissingCheckBox.Value = true;
            app.BreakPointsDropDown.Value = 'none';
            app.ContinuousCheckBox.Value = true;
            app.BreakPointsSpinner.Value = 1;
            app.BreakPointsWSDropDown.Value = app.SelectVariable;
            resetAxes(app);
            
            fromResetMethod = (nargin > 1) && fromResetMethod; % Called from reset()
            if ~fromResetMethod
                % reset() does not reset the input data, therefore, it does
                % not change wether the app supports visualization or not.
                app.SupportsVisualization = true;
            end
            app.PlotInputDataCheckBox.Value = true;
            app.PlotDetrendedDataCheckBox.Value = true;
            app.PlotTrendCheckBox.Value = true;
            app.PlotBreakPointsCheckBox.Value = true;
        end
        
        function changedWidget(app,context,~)
            % Update widgets' internal values from callbacks
            context = context.Tag;
            if isequal(context,app.InputDataDropDown.Tag)
                setSpinnerLimits(app);
                app.BreakPointsWSDropDown.Value = app.SelectVariable;
                resetAxes(app);
                updateBreakPointsIsLogical(app);
            elseif ismember(context,{app.SamplePointsDropDown.Tag,app.SamplePointsTableVarDropDown.Tag})
                app.BreakPointsWSDropDown.Value = app.SelectVariable;
                resetAxes(app);
                updateBreakPointsIsLogical(app);
            elseif isequal(context,app.ClearBreakPointsButton.Tag)
                resetAxes(app);
            elseif ismember(context,{app.TableVarPlotDropDown.Tag,'ChangedDataVariables',app.OutputTypeDropDown.Tag})
                setSpinnerLimits(app);
                % keep the breakpoints, but update y-data
                % if multi var, plot based on plot dd
                if hasInputData(app) && app.SupportsVisualization
                    if ~isempty(app.BreakPointsAxes.Children) && ...
                            (~isa(app.InputDataDropDown.WorkspaceValue,'tabular') || height(app.InputDataDropDown.WorkspaceValue) > 1)
                        % don't want to get here if we are in the table
                        % with 1 row case because XData may also be changed
                        y = evalin(app.Workspace,addDotIndexingToTableName(app,getInputDataVarName(app)));
                        app.BreakPointsAxes.Children(end).YData = y;
                        name = addDotIndexingToTableName(app,'');
                        app.BreakPointsAxes.YLabel.String = name(2:end);
                    else
                        resetAxes(app);
                    end
                else
                    resetAxes(app)
                end
            end
            if ~strcmp(app.BreakPointsWSDropDown.Value,app.SelectVariable) && isempty(app.BreakPointsWSDropDown.WorkspaceValue)
                % the breakpoints variable has been cleared, reset the dd
                app.BreakPointsWSDropDown.Value = app.SelectVariable;
                updateBreakPointsIsLogical(app);
            elseif ismember(context,{app.BreakPointsDropDown.Tag,app.BreakPointsWSDropDown.Tag})
                updateBreakPointsIsLogical(app);
            end
        end
        
        function setSpinnerLimits(app,numElements)
            app.DegreeDropDown.Items = cellstr([getMsgText(app,getMsgId('Constant')),...
                getMsgText(app,getMsgId('Linear')),getMsgText(app,getMsgId('Quadratic')),...
                getMsgText(app,getMsgId('Cubic')),getMsgText(app,getMsgId('Custom'))]);
            app.DegreeDropDown.ItemsData = [0:3  -1];
            if ~isempty(app.InputDataDropDown.WorkspaceValue)
                if nargin < 2
                    numElements = getNumelAlongDefaultDim(app);
                end
                app.DegreeSpinner.Limits(2) = max(4,numElements - 1);
                app.BreakPointsSpinner.Limits(2) = numElements;
                
                if numElements <= 4
                    app.DegreeDropDown.Items = setdiff(app.DegreeDropDown.Items,...
                        getMsgText(app,getMsgId('Custom')),'stable');
                    app.DegreeDropDown.ItemsData = 0:3;
                    if numElements <= 3
                        app.DegreeDropDown.Items = setdiff(app.DegreeDropDown.Items,...
                            getMsgText(app,getMsgId('Cubic')),'stable');
                        app.DegreeDropDown.ItemsData = 0:2;
                        if numElements == 2 % scalars not supported
                            app.DegreeDropDown.Items = setdiff(app.DegreeDropDown.Items,...
                                getMsgText(app,getMsgId('Quadratic')),'stable');
                            app.DegreeDropDown.ItemsData = 0:1;
                        end
                    end
                end
            else
                app.DegreeSpinner.Limits(2) = inf;
                app.BreakPointsSpinner.Limits(2) = inf;
            end            
        end

        function updateBreakPointsIsLogical(app)            
            app.BreakPointsIsLogical = false;
            if isequal(app.BreakPointsDropDown.Value,'fromworkspace')
                app.BreakPointsIsLogical = islogical(app.BreakPointsWSDropDown.WorkspaceValue);
            end
        end
        
        function updateWidgets(app,doEvalinBase)
            % Update the layout and visibility of the widgets

            doRemove = isequal(app.OutputWorkflowDropDown.Value,'remove');            
            if ~doRemove && app.InputDataHasTableVars
                % Make sure outputformat is accurate while hidden
                if ismember('smalltable',app.OutputTypeDropDown.ItemsData)
                    % some but not all table vars selected, need indexing
                    app.OutputTypeDropDown.Value = 'smalltable';
                elseif ismember('replace',app.OutputTypeDropDown.ItemsData)
                    % all table vars are selected, so we won't need to index
                    app.OutputTypeDropDown.Value = 'replace';
                else
                    % edge case, timetable has invalid rowtimes for sp
                    app.OutputTypeDropDown.Value = 'vector';
                end
            end
            updateInputDataAndSamplePointsDropDown(app);
            hasData = hasInputDataAndSamplePoints(app);
            % always show outputformat row
            app.Accordion.Children(1).Children.RowHeight{3} = app.TextRowHeight;
            app.OutputWorkflowDropDown.Enable = hasData;
            % if only find, just provide the trend(s), with no output options            
            app.OutputTypeDropDown.Visible = app.InputDataHasTableVars && doRemove;
            
            % Parameter Row 1: degree and missing checkbox
            app.DegreeDropDown.Enable = hasData;
            app.DegreeSpinner.Enable = hasData;
            [degree,doSpinner] = getDegree(app);
            app.DegreeSpinner.Visible = doSpinner;
            app.MissingCheckBox.Enable = hasData;
            if hasData
                if doEvalinBase
                    A = evalin(app.Workspace, app.getInputDataVarName);
                    if isa(A,'tabular')
                        A = getSelectedSubTable(app,A);
                        hasMissing = any(varfun(@(x) any(ismissing(x),'all'),A,'OutputFormat','uniform'));
                    else
                        hasMissing = any(ismissing(A),'all');
                    end
                    app.MissingCheckBox.Visible = hasMissing;
                else
                    hasMissing = strcmp(app.MissingCheckBox.Visible,'on');
                end
                if hasMissing && ~doSpinner
                    app.MissingCheckBox.Layout.Column = 3;
                else
                    app.MissingCheckBox.Layout.Column = 4;
                end
            else
                app.MissingCheckBox.Visible = 'off';
            end
            
            % Breakpoints Rows
            app.BreakPointsDropDown.Enable = hasData;
            if doEvalinBase && hasData && ~app.SupportsVisualization
                % 'select from plot' should only be available if preview supported
                app.BreakPointsDropDown.Items = cellstr([getMsgText(app,'None'),...
                    getMsgText(app,getMsgId('Linearlyspaced')),...
                    getMsgText(app,getMsgId('Choosefromworkspace'))]);
                app.BreakPointsDropDown.ItemsData = {'none' 'linearlyspaced' 'fromworkspace'};
            else
                app.BreakPointsDropDown.Items = cellstr([getMsgText(app,'None'),...
                    getMsgText(app,getMsgId('Selectfromplot')), getMsgText(app,getMsgId('Linearlyspaced')),...
                    getMsgText(app,getMsgId('Choosefromworkspace'))]);
                app.BreakPointsDropDown.ItemsData = {'none' 'interactive' 'linearlyspaced' 'fromworkspace'};
            end
            axesGrid = app.BreakPointsAxes.Parent.Parent;
            if isequal(app.BreakPointsDropDown.Value,'interactive')
                axesGrid.RowHeight = {app.AxesHeight};
                axesGrid.ColumnWidth = {app.AxesWidth};
                axesGrid.Visible = 'on';
                app.ClearBreakPointsButton.Visible = 'on';
                app.BreakPointsSpinner.Visible = 'off';
                app.BreakPointsWSDropDown.Visible = 'off';
            else
                axesGrid.RowHeight = {0};
                axesGrid.ColumnWidth = {0};
                axesGrid.Visible = 'off';
                app.ClearBreakPointsButton.Visible = 'off';
                if isequal(app.BreakPointsDropDown.Value,'linearlyspaced')
                    app.BreakPointsSpinner.Visible = 'on';
                    app.BreakPointsWSDropDown.Visible = 'off';
                elseif isequal(app.BreakPointsDropDown.Value,'fromworkspace')
                    app.BreakPointsSpinner.Visible = 'off';
                    app.BreakPointsWSDropDown.Visible = 'on';
                else % no breakpoints
                    app.BreakPointsSpinner.Visible = 'off';
                    app.BreakPointsWSDropDown.Visible = 'off';
                end
            end
            
            app.ContinuousCheckBox.Visible = hasBreakPoints(app) && degree ~= 0;
            app.ClearBreakPointsButton.Enable = ~isempty(app.SelectedBreakPoints);
            app.BreakPointsSpinner.Enable = hasData;
            app.BreakPointsWSDropDown.Enable = hasData;
            app.ContinuousCheckBox.Enable = hasData;
            app.PlotInputDataCheckBox.Enable = hasData;
            app.PlotDetrendedDataCheckBox.Enable = hasData;
            app.PlotTrendCheckBox.Enable = hasData;
            app.PlotBreakPointsCheckBox.Enable = hasData;
            
            showPlotCheckboxes(app,app.PlotDetrendedDataCheckBox,...
                app.PlotInputDataCheckBox,app.PlotTrendCheckBox);
            
            app.PlotBreakPointsCheckBox.Visible = hasBreakPoints(app) && app.PlotInputDataCheckBox.Visible;
            
            % set columnwidth of grid
            methodGrid = app.MissingCheckBox.Parent;
            hasMissing = strcmp(app.MissingCheckBox.Visible,'on');
            if (hasMissing && doSpinner) || (hasBreakPoints(app) && degree ~= 0)
                % show column 4
                methodGrid.ColumnWidth{4} = 'fit';
            else
                methodGrid.ColumnWidth{4} = 0;
            end
            if isequal(app.BreakPointsDropDown.Value,'none') && ~doSpinner && ~hasMissing
                % hide column 3
                methodGrid.ColumnWidth{3} = 0;
            else
                methodGrid.ColumnWidth{3} = 'fit';
            end
        end
        
        function tf = filterInputData(~,A,isTableVar)
            % Keep only Input Data of supported type
            if isa(A,'tabular') % table or timetable
                tf = ~isTableVar; % No tables within tables
            elseif isempty(A) || isscalar(A)
                tf = false;
            else
                tf = isfloat(A);
            end
        end
        
        function tf = filterSamplePointsType(~,X,isTableVar)
            % Keep only Sample Points (X-axis) of supported type
            if istall(X)
                tf = false;
            elseif isa(X,'tabular') % table or timetable
                tf = ~isTableVar; % No tables within tables
            else
                tf = (isvector(X) || isempty(X)) && ...
                    ((isfloat(X) && isreal(X) && ~issparse(X)) || ...
                    isduration(X) || isdatetime(X));
            end
        end
        
        function isSupported = filterBreakPointsFromWorkspace(app,bp)
            % first, check to see if input/sample points are still in the
            % workspace
            if isempty(app.InputDataDropDown.WorkspaceValue) && ~strcmp(app.InputDataDropDown.Value,app.SelectVariable)
                % input data is no longer in the workspace
                % return false for everything in ws
                isSupported = false;
                return
            elseif isempty(app.SamplePointsDropDown.WorkspaceValue) && ~strcmp(app.SamplePointsDropDown.Value,app.DefaultValue)
               % sample points is no longer in the workspace
               % reset sample points and filter as if sample points is default
               setSamplePointsToDefault(app);
               changedSamplePointsVarClass(app);
            end
            
            % copied largely from detrend, but additional filtering:
            % * no empties
            % * filter out vectors longer than sample points
            if isempty(bp)
                isSupported = false;
                return
            end
            isSupported = true;
            s = getSamplePointsVarName(app);
            if isempty(s)
                if ~(isnumeric(bp) || islogical(bp))  || ~isreal(bp) || ...
                        ~isvector(bp) || issparse(bp)
                    isSupported = false;
                end
                N = getNumelAlongDefaultDim(app);
            else
                s = evalin(app.Workspace, s);
                if (isnumeric(bp) && ~isreal(bp)) || ...
                        ~isvector(bp) || issparse(bp) || ...
                        (~(islogical(bp) || (isnumeric(bp) && isnumeric(s))) && ...
                        ~(isequal(class(bp), class(s))))
                    isSupported = false;
                end
                N = numel(s);
            end
            if ~islogical(bp) && numel(bp) > N
                isSupported = false;
            end
        end
        
        function x = getSamplePoints(app)
            x = getSamplePointsVarName(app);
            if isempty(x)
                x = 1:getNumelAlongDefaultDim(app);
            else
                x = evalin(app.Workspace,x);
            end
        end
        
        function [degree,useSpinner] = getDegree(app)
            degree = app.DegreeDropDown.Value;
            useSpinner = degree < 0;
            if useSpinner
                degree = app.DegreeSpinner.Value;
            end
        end
        
        function tf = hasBreakPoints(app)
            switch app.BreakPointsDropDown.Value
                case 'fromworkspace'
                    tf = ~isequal(app.BreakPointsWSDropDown.Value,app.SelectVariable);
                case 'interactive'
                    tf = ~isempty(app.SelectedBreakPoints);
                case 'linearlyspaced'
                    tf = app.BreakPointsSpinner.Value > 0;
                otherwise % none
                    tf = false;                    
            end
        end
        
        function var = generateBPVarNameForGeneratedScript(app)
            var = 'breakpoints';
            if isequal(app.BreakPointsDropDown.Value,'fromworkspace')
                var = ['`' app.BreakPointsWSDropDown.Value '`'];
            end
        end
        
        function stopOperation = checkForClearedWorkspaceVariables(app)
            stopOperation = false;
            if isempty(app.InputDataDropDown.WorkspaceValue)
                % input data has been cleared, reset the app
                setInputDataAndWidgetsToDefault(app);
                doUpdate(app);
                stopOperation = true;
            elseif isempty(app.SamplePointsDropDown.WorkspaceValue) &&...
                    ~strcmp(app.SamplePointsDropDown.Value,app.DefaultValue)
                % sample points has been cleared, reset the axes
                setSamplePointsToDefault(app);
                resetAxes(app);
                doUpdate(app);
                stopOperation = true;
            end
        end
        
        function propTable = getLocalPropertyInformation(app)
            Name = ["DegreeDropDown"; "DegreeSpinner"; "MissingCheckBox"; ...
                "BreakPointsDropDown"; "BreakPointsSpinner"; "ContinuousCheckBox"];
            Group = repmat(getMsgText(app,getMsgId('ParametersDelimiter')),6,1);
            DisplayName = [getMsgText(app,getMsgId('Degree')); getMsgText(app,'CustomDegree');...
                getMsgText(app,getMsgId('FillMissing')); getMsgText(app,getMsgId('Breakpoints'));...
                 getMsgText(app,getMsgId('BreakPointsSpinnerTooltip')); getMsgText(app,getMsgId('Continuous'))];                
            StateName = Name + "Value";
            
            propTable = table(Name,Group,DisplayName,StateName);
            propTable = addFieldsToPropTable(app,propTable);
            
            % reset items for BreakPointsDropDown for options allowed in
            % Data Cleaner app: no input plot, no workspace dd
            propTable.Items{4} = cellstr([getMsgText(app,'None'),getMsgText(app,getMsgId('Linearlyspaced'))]);
            propTable.ItemsData{4} = {'none' 'linearlyspaced'};
        end
    end
    
    % Methods for Interactive Plot
    methods (Access = private)
        function addBPtoAxes(app,~,event)
            % Callback for axes click
            if event.Button ~= 1
                % only react to left clicks
                return
            elseif ~strcmp(app.BreakPointsAxes.InteractionContainer.CurrentMode,'none')
                % don't react if we are in pan or zoom mode
                return
            elseif checkForClearedWorkspaceVariables(app)
                % axes gets reset
                return
            end

            bp = event.IntersectionPoint(1);
            % convert to appropriate datatype
            bp = num2ruler(bp,app.BreakPointsAxes.XAxis);
            x = getSamplePoints(app);
            [~,bp] = min(abs(x-bp));
            BPLine = xline(app.BreakPointsAxes,x(bp),'Alpha',1);
            matlab.graphics.internal.themes.specifyThemePropertyMappings(BPLine,...
                'Color','--mw-graphics-colorOrder-5-primary')

            app.SelectedBreakPoints = [app.SelectedBreakPoints; bp];
            app.ClearBreakPointsButton.Enable = 'on';

            highlightBP(app,BPLine);

            doUpdate(app);
            notify(app,'StateChanged');
        end
        
        function highlightBP(app,BPLine,event)
            if nargin > 2
                if event.Button ~= 1
                    % only react to left clicks
                    return
                elseif ~strcmp(app.BreakPointsAxes.InteractionContainer.CurrentMode,'none')
                    % don't react if we are in pan or zoom mode
                    return
                end
            end
            if checkForClearedWorkspaceVariables(app)
                % axes gets reset
                return
            end
            if ~isempty(app.AxesStruct.highlightedBP)
                % need to deselect currently selected BP
                deselectBP(app);
            end
            app.AxesStruct.highlightedBP = BPLine;
            app.AxesStruct.highlightedBP.ButtonDownFcn = @app.setXLineToMove;
            app.AxesStruct.shadow = xline(app.BreakPointsAxes,BPLine.Value,'LineWidth',5,...
                'PickableParts','none','Alpha',.3);
            matlab.graphics.internal.themes.specifyThemePropertyMappings(app.AxesStruct.shadow,...
                'Color','--mw-graphics-colorOrder-5-secondary')
            
            setLabelPositionAndValue(app,BPLine.Value)
            
            app.AxesStruct.markForUnselect = false;
            x = getSamplePoints(app);
            app.AxesStruct.idx = find(BPLine.Value == x(app.SelectedBreakPoints));
        end
        
        function deselectBP(app)
            app.AxesStruct.idx = [];
            app.AxesStruct.highlightedBP.ButtonDownFcn = @app.highlightBP;
            delete(app.AxesStruct.shadow)
            app.AxesStruct.shadow = '';
            app.BreakPointValueLabelNum.Visible = 'off';
            app.BreakPointValueLabelDT.Visible = 'off';
            app.BreakPointValueLabelDur.Visible = 'off';
            app.BreakPointUnitLabelDur.Visible = 'off';
            app.DeleteButton.Visible = 'off';
        end
        
        function setXLineToMove(app,~,event)
            if event.Button ~= 1
                % only react to left clicks
                return
            elseif ~strcmp(app.BreakPointsAxes.InteractionContainer.CurrentMode,'none')
                % don't react if we are in pan or zoom mode
                return
            elseif checkForClearedWorkspaceVariables(app)
                % axes gets reset
                return
            end
            app.UIFigure.WindowButtonMotionFcn = @app.dragXLine;
            app.AxesStruct.markForUnselect = true;
        end
        
        function deleteSelectedBP(app,~,~)
            if checkForClearedWorkspaceVariables(app)
                return
            end            
            app.SelectedBreakPoints(app.AxesStruct.idx) = [];
            deselectBP(app);
            delete(app.AxesStruct.highlightedBP);
            app.AxesStruct.highlightedBP = '';
            doUpdate(app);
        end
        
        function dragXLine(app,~,event)
            bp = event.IntersectionPoint(1);
            if isnan(bp)
                % pointer is outside axes
                return
            end
            bp = num2ruler(bp,app.BreakPointsAxes.XAxis);
            moveHighlightedXLine(app,bp);
            app.AxesStruct.markForUnselect = false;
        end
        
        function moveHighlightedXLine(app,bp)
            x = getSamplePoints(app);
            if bp <= x(1)
                bp = 1;                
            elseif bp >= x(end)
                bp = numel(x);
            else
                [~,bp] = min(abs(x-bp));
            end
            app.AxesStruct.highlightedBP.Value = x(bp);
            app.AxesStruct.shadow.Value = x(bp);
            setLabelPositionAndValue(app,x(bp));
            app.SelectedBreakPoints(app.AxesStruct.idx) = bp;
        end
        
        function numericLabelChange(app,~,event)
            if checkForClearedWorkspaceVariables(app)
                return
            end
            bp = event.Value;
            moveHighlightedXLine(app,bp);
        end
        
        function durationLabelChange(app,~,event)
            if checkForClearedWorkspaceVariables(app)
                return
            end
            bp = milliseconds(event.Value)*app.UnitToMilliseconds;
            moveHighlightedXLine(app,bp);
        end
        
        function datetimeOrDurationLabelChange(app,src,event)
            if checkForClearedWorkspaceVariables(app)
                return
            end
            str = event.Value;
            x = getSamplePoints(app);
            if isduration(x)
                try
                    % this works for strings like '(dd:)hh:mm:ss(.SSS)'
                    bp = duration(str);
                catch
                    src.Value = event.PreviousValue;
                    return
                end
            else % is datetime
                try
                    % first try with input format. This will get ambiguous
                    % dates correct if the user types in same format as was
                    % displayed to them
                    bp = datetime(str,'InputFormat',x.Format);
                catch
                    try
                       % second try without input format, gives user more
                       % flexibility in format to type
                       bp = datetime(str);
                    catch
                        src.Value = event.PreviousValue;
                        return
                    end
                end
            end
            if ~isfinite(bp)
                src.Value = event.PreviousValue;
                return
            end
            moveHighlightedXLine(app,bp);
        end
        
        function setLabelPositionAndValue(app,val)
            % Find pixel position of the breakpoint
            xval = ruler2num(val,app.BreakPointsAxes.XAxis);
            xlimits = ruler2num(xlim(app.BreakPointsAxes),app.BreakPointsAxes.XAxis);
            xval = (xval-xlimits(1))/abs(diff(xlimits))*app.AxesWidth*app.BreakPointsAxes.Position(3)+75;
            if isdatetime(val)
                label = app.BreakPointValueLabelDT;
                % the label value must be char
                val = char(val);
                % estimate how wide we need the label to be
                labelWidth = 8*numel(val);
            elseif isduration(val)
                if ~ismember(val.Format,{'y','d','h','m','s'})
                    % we have a format like '(dd:)hh:mm:ss(.SSS)'
                    % so just use the datetime label
                    val = char(val);
                    label = app.BreakPointValueLabelDT;
                    labelWidth = 8*(numel(val)+1);
                else
                    % we have format like 'num unit', extract the num (we
                    % already have the unit)
                    val = app.parseDuration(val);
                    label = app.BreakPointValueLabelDur;
                    % estimate how wide we need the label to be
                    labelWidth = 10*numel(num2str(val,'%11.4g'))+8;
                end                
            else % numeric
                label = app.BreakPointValueLabelNum;
                % estimate how wide we need the label to be
                labelWidth = 10*numel(num2str(val,'%11.4g'))+8;
                % singles are allowed as sample points, but not as
                % NumericEditField values
                val = double(val);
            end
            if isempty(app.BreakPointUnitLabelDur.Value)
                unitwidth = 0;
            else
                % get number of characters, but add extra width for
                % non-standard characters (g2473486)
                str = app.BreakPointUnitLabelDur.Value;
                strWidth = length(str) + sum(double(str)>256);
                % Most monospace fonts have a less than 3/4 ratio of width
                % to height. Add 4 pixels to account for the
                % editfield's internal buffer
                unitwidth = (3/4)*app.LabelFontSize*(strWidth)+4;
            end
            
            % center the label under the breakpoint
            % except make sure it isn't too far left (30)
            % or too far right (AxesWidth-22(for delete button to fit too))
            xPosition = min(max(xval-labelWidth/2,30),app.AxesWidth-labelWidth-22-unitwidth);
            label.Position = [xPosition 2 labelWidth 22];
            label.Value = val;
            label.Visible = 'on';
            
            app.DeleteButton.Position = [xPosition+labelWidth+unitwidth+2 2 20 22];
            app.DeleteButton.Visible = 'on';
            if unitwidth > 0
                app.BreakPointUnitLabelDur.Position = [xPosition+labelWidth+1 2 unitwidth 22];
                app.BreakPointUnitLabelDur.Visible = 'on';
            end
        end
        
        function buttonUpFcn(app,~,~)
            if ~isempty(app.UIFigure.WindowButtonMotionFcn)
                app.UIFigure.WindowButtonMotionFcn = [];
                doUpdate(app);
                notify(app,'StateChanged');
            end
            if ~isempty(app.AxesStruct.highlightedBP) && app.AxesStruct.markForUnselect
                deselectBP(app);
                app.AxesStruct.highlightedBP = '';
            end
        end
        
        function resetAxes(app)
            cla(app.BreakPointsAxes);
            app.SelectedBreakPoints = [];
            app.BreakPointUnitLabelDur.Value = '';
            app.UnitToMilliseconds = [];
            if hasInputDataAndSamplePoints(app) && app.SupportsVisualization
                plotData(app);
                x = getSamplePoints(app);
                if isduration(x)
                    if ismember(x.Format,{'y','d','h','m','s'})
                        % Sample points x are strictly increasing and not a scalar;
                        % therefore, they will contain at least one non-zero entry.
                        x1 = abs(x(find(x ~= 0,1)));
                        [xnum,unit] = app.parseDuration(x1);
                        app.BreakPointUnitLabelDur.Value = unit;
                        app.UnitToMilliseconds = milliseconds(x1)/xnum;
                    end
                    % else we will be using the datetime label and don't
                    % need to set these properties
                end  
            end
            app.AxesStruct = struct('highlightedBP','','markForUnselect',true,'idx',[],'shadow','');
            app.BreakPointValueLabelNum.Visible = 'off';
            app.BreakPointValueLabelNum.Value = 0;
            app.BreakPointValueLabelDT.Visible = 'off';
            app.BreakPointValueLabelDT.Value = '';
            app.BreakPointValueLabelDur.Visible = 'off';
            app.BreakPointValueLabelDur.Value = 0;
            app.BreakPointUnitLabelDur.Visible = 'off';
            app.DeleteButton.Visible = 'off';
            % Limit items in axes toolbar to only these 4 items
            axtoolbar(app.BreakPointsAxes,{'pan' 'zoomin' 'zoomout' 'restoreview'});
        end
        
        function plotData(app)
            x = getSamplePoints(app);
            y = evalin(app.Workspace,addDotIndexingToTableName(app,getInputDataVarName(app)));
            p = plot(app.BreakPointsAxes,x,y);
            % add ylabel only for table variables
            if app.InputDataHasTableVars
                name = addDotIndexingToTableName(app,'');
                app.BreakPointsAxes.YLabel.String = name(2:end);
            else
                app.BreakPointsAxes.YLabel.String = '';
            end
            % match color to output plot
            matlab.graphics.internal.themes.specifyThemePropertyMappings(p,...
                'Color','--mw-graphics-colorOrder-1-secondary');
            % when user clicks p, want axes callback to run, not p.
            p.PickableParts = 'none';
            app.BreakPointsAxes.ButtonDownFcn = @app.addBPtoAxes;

            matlab.graphics.interaction.enableInteractivityOnButtonDown(app.BreakPointsAxes);
            matlab.graphics.interaction.enableToolbarOnButtonDown(app.BreakPointsAxes);
        end
        
        function replotDataAndBreakpoints(app)
            cla(app.BreakPointsAxes);
            if hasInputDataAndSamplePoints(app) && app.SupportsVisualization
                plotData(app);
                x = getSamplePoints(app);                
                for bp = app.SelectedBreakPoints'
                    xL = xline(app.BreakPointsAxes,x(bp),'ButtonDownFcn',@app.highlightBP,'Alpha',1);
                    matlab.graphics.internal.themes.specifyThemePropertyMappings(xL,...
                        'Color','--mw-graphics-colorOrder-5-primary')
                end
            end
            app.AxesStruct = struct('highlightedBP','','markForUnselect',true,'idx',[],'shadow','');

            matlab.graphics.interaction.enableInteractivityOnButtonDown(app.BreakPointsAxes);
            matlab.graphics.interaction.enableToolbarOnButtonDown(app.BreakPointsAxes);
        end
        
        function markVariablesToBeClearedFromGenerateScript(app)
            if hasBreakPoints(app) && ~isequal(app.BreakPointsDropDown.Value,'fromworkspace')
                markAsVariablesToBeCleared(app,'breakpoints');
            end

            if isequal(app.OutputWorkflowDropDown.Value,'find')
                if app.outputIsTable
                    markAsVariablesToBeCleared(app,app.OutputTableName);
                    if ~isscalar(getSelectedVarNames(app))
                        markAsVariablesToBeCleared(app,'k');
                    end
                else
                    markAsVariablesToBeCleared(app,app.OutputVectorName);
                end
            end
        end
        
        function [xnum,unit] = parseDuration(app,x)
            switch x.Format
                case 'y'
                    xnum = years(x);
                    unit = getMsgText(app,'Years');
                case 'd'
                    xnum = days(x);
                    unit = getMsgText(app,'Days');
                case 'h'
                    xnum = hours(x);
                    unit = getMsgText(app,'Hours');
                case 'm'
                    xnum = minutes(x);
                    unit = getMsgText(app,'Minutes');
                case 's'
                    xnum = seconds(x);
                    unit = getMsgText(app,'Seconds');
                    % other formats should not get here
            end
        end
    end
    
    % Required for embedding in a Live Script
    methods (Access = public)
        function [code, outputs] = generateScript(app,isForExport)
            
            if nargin < 2
                % isForExport is used in the app workflow only when
                % exporting the code. In this case, we want to clear used
                % temp variables here instead of in visualization script.
                % Additionally, want to skip the output = input line and
                % write over the input with output
                isForExport = false;
            end
            
            if ~hasInputDataAndSamplePoints(app)
                code = '';
                outputs = {};
                return
            end
            
            if app.replotOnGenerateScript && ~app.isAppWorkflow
                % user may have re-added variable to workspace
                % e.g. on reopening live script, then running the MLX
                try
                    replotDataAndBreakpoints(app);
                    app.replotOnGenerateScript = false;
                catch
                end
            end

            code = ['% ' char(getMsgText(app,getMsgId('Removetrendfromdata'))) newline];
            
            % select breakpoints
            hasBP = hasBreakPoints(app);
            if hasBP && ~isequal(app.BreakPointsDropDown.Value,'fromworkspace')
                if isequal(app.BreakPointsDropDown.Value,'interactive')
                    bp = mat2str(app.SelectedBreakPoints');
                    bp = regexprep(bp,'.{50,80}\s','$0...\n    ');                    
                    if isequal(app.SamplePointsDropDown.Value,app.DefaultValue)
                        code = [code 'breakpoints = ' bp ';' newline];
                    else
                        code = [code 'breakpoints = ' getSamplePointsVarNameForGeneratedScript(app) '(' bp ');' newline];
                    end
                else % 'Linearlyspaced'
                    x = getSamplePointsVarNameForGeneratedScript(app);
                    if isempty(x)
                        d1 = '1';
                        d2 = num2str(getNumelAlongDefaultDim(app));
                    else
                        d1 = [x '(1)'];
                        d2 = [x '(end)'];
                    end
                    code = [code 'breakpoints = linspace(' d1 ',' d2 ',' num2str(app.BreakPointsSpinner.Value + 2) ');'];
                    code = [code newline 'breakpoints([1 end]) = [];' newline];
                end
            end
            
            % set input and output names, generate code to call detrend
            if isForExport
                outputs = {app.getInputDataVarNameForGeneratedScript};
            elseif app.outputIsTable
                outputs = {app.OutputTableName};
            else
                outputs = {app.OutputVectorName};
            end
            code = [code outputs{1} ' = '];

            doFind = isequal(app.OutputWorkflowDropDown.Value,'find');            
            input = [getInputDataVarNameForGeneratedScript(app) getSmallTableCode(app)];
            code = matlab.internal.dataui.addCharToCode(code,['detrend(' input]);

            degree = getDegree(app);
            if degree ~=1 || hasBP
                code = matlab.internal.dataui.addCharToCode(code,[',' num2str(degree)]);
            end
            if hasBP
                code = matlab.internal.dataui.addCharToCode(code,[',' generateBPVarNameForGeneratedScript(app)]);
            end
            if app.MissingCheckBox.Visible && app.MissingCheckBox.Value
                code = matlab.internal.dataui.addCharToCode(code,',"omitnan"');
            end
            if (~app.ContinuousCheckBox.Value && app.ContinuousCheckBox.Visible) ||...
                    (hasBP && degree == 0)
                code = matlab.internal.dataui.addCharToCode(code,',Continuous=false');
            end
            if ~doFind
                code = matlab.internal.dataui.addCharToCode(code,getDataVariablesNameValuePair(app));
                code = matlab.internal.dataui.addCharToCode(code,getReplaceValuesNameValuePair(app));
            end
            code = matlab.internal.dataui.addCharToCode(code,getSamplePointsNameValuePair(app));
            code = [code ');'];

            if doFind
                outputs = {app.TrendOutputName};
                code = [code newline newline '% ' char(getMsgText(app,getMsgId('FindTrendComment'))) newline];
                if app.outputIsTable
                    code = [code outputs{1} ' = ' input ';' newline];
                    N = numel(getSelectedVarNames(app));
                    if N == 1
                        code = [code outputs{1} '.(1) = ' outputs{1} '.(1) - ' app.OutputTableName '.(1);'];
                    else
                        code = [code 'for k = 1:' num2str(N) newline];
                        code = [code '    ' outputs{1} '.(k) = ' outputs{1} '.(k) - ' app.OutputTableName '.(k);' newline];
                        code = [code 'end'];
                    end
                else
                    code = [code outputs{1} ' = ' input ' - ' app.OutputVectorName ';'];
                end
            end
        end
        
        function code = generateVisualizationScript(app)
            code = '';
            if ~hasInputDataAndSamplePoints(app)
                return
            end
            resetVariablesToBeCleared(app);
            markVariablesToBeClearedFromGenerateScript(app);
            
            clearVariablesOnly = false;
            if ~hasInputDataAndSamplePoints(app) || ~app.SupportsVisualization
                clearVariablesOnly = true;
            end
            numPlots = sum([app.PlotInputDataCheckBox.Value app.PlotDetrendedDataCheckBox.Value ...
                app.PlotTrendCheckBox.Value (app.PlotBreakPointsCheckBox.Value && app.PlotBreakPointsCheckBox.Visible)]);
            if numPlots == 0
                clearVariablesOnly = true;
            end
            % if no vis, still need to clear variables created in generateScript
            if  clearVariablesOnly
                code = addClear(app,code);
                if numel(code) > 1
                    % get rid of the newline
                    code(1) = [];
                end
                return
            end
            
            code = addVisualizeResultsLine(app);            
            x = getSamplePointsVarNameForGeneratedScript(app);
            didHoldOn = false;
            doTiledLayout = isnumeric(app.TableVarPlotDropDown.Value);
            doFind = isequal(app.OutputWorkflowDropDown.Value,'find');

            if doTiledLayout
                needOutLoc = ~isequal(app.OutputTypeDropDown.Value,'replace') && ...
                    (app.PlotDetrendedDataCheckBox.Value || app.PlotTrendCheckBox.Value);
                [code,inIndex,outIndex] = generateScriptSetupTiledLayout(app,code,needOutLoc);
                a1 = [getInputDataVarNameForGeneratedScript(app) '.(' inIndex ')'];
                if ~doFind && isequal(app.OutputTypeDropDown.Value,'append')
                    outIndex = [outIndex '+' num2str(app.InputSize(2))];
                end
                a2 = [app.OutputTableName '.(' outIndex ')'];
                trend = [app.TrendOutputName '.(' outIndex ')'];
                tab = '    ';
            else
                a1 = addDotIndexingToTableName(app,getInputDataVarNameForGeneratedScript(app));
                if app.outputIsTable
                    if ~doFind && isequal(app.OutputTypeDropDown.Value,'append')
                        a2 = addIndexingIntoAppendedVar(app,app.OutputTableName);
                    else
                        a2 = addDotIndexingToTableName(app,app.OutputTableName);
                        trend = addDotIndexingToTableName(app,app.TrendOutputName);
                    end
                else
                    a2 = app.OutputVectorName;
                    trend = app.TrendOutputName;
                end
                tab = '';
            end
            if ~doFind
                trend = [a1 '-' a2];
            end
            
            if app.PlotInputDataCheckBox.Value
                code = generateScriptPlotInputData(app,code,x,a1,tab);
                [code,didHoldOn] = addHold(app,code,'on',didHoldOn,numPlots,tab);
            end
            
            if app.PlotDetrendedDataCheckBox.Value
                code = generateScriptPlotCleanedData(app,code,x,a2,tab,char(getMsgText(app,getMsgId('DetrendedData'))));
                [code,didHoldOn] = addHold(app,code,'on',didHoldOn,numPlots,tab);
            end
            
            if app.PlotTrendCheckBox.Value
                code = [code newline tab 'plot(' x addComma(app,x) trend];
                code = matlab.internal.dataui.addCharToCode(code,',SeriesIndex=2,',doTiledLayout);
                code = matlab.internal.dataui.addCharToCode(code,'LineWidth=1,',doTiledLayout);
                code = addDisplayName(app,code,char(getMsgText(app,getMsgId('Trend'))),doTiledLayout);
                [code,didHoldOn] = addHold(app,code,'on',didHoldOn,numPlots,tab);
            end
            
            if app.PlotBreakPointsCheckBox.Value && app.PlotBreakPointsCheckBox.Visible
                mask = generateBPVarNameForGeneratedScript(app);
                if ~isequal(mask,'[]')
                    code = addVerticalLines(app,code,mask,x,char(getMsgText(app,getMsgId('Breakpoints'))),...
                        'SeriesIndex=5,','1',tab,app.BreakPointsIsLogical,'xbreakpoints','ybreakpoints');
                end
            end
            
            if ~doTiledLayout && ~isempty(app.InputDataDropDown.WorkspaceValue)
                numMissing = evalin(app.Workspace,['nnz(ismissing(' strrep(a1,'`','') '))']);
                if numMissing > 0
                    code = [code newline 'title("' char(getMsgText(app,getMsgId('NumMissing'))) ': ' num2str(numMissing) '")'];
                end
            end
            
            code = addHold(app,code,'off',didHoldOn,numPlots,tab);
            code = addLegendAndAxesLabels(app,code,tab);
            % if only breakpoints, need to set xaxis limits
            if numPlots == 1 && app.PlotBreakPointsCheckBox.Value &&...
                    app.PlotBreakPointsCheckBox.Visible
                code = addXLimits(app,code,x,tab);
            end
            if doTiledLayout
                code = generateScriptEndTiledLayout(app,code);
            end
            if ~isAppWorkflow(app)
                % if we are in app mode, do not clear since we may want to
                % plot multiple variables with one call to generateScript
                code = addClear(app,code);
            end
        end
                
        function setTaskState(app,state,updatedWidget)
            % With nargin == 2, setState is used by live editor and App for
            % save/load, undo/redo
            % With nargin == 3, setState is used by the App to change the
            % value of a control from the property inspector
            if nargin < 3
                updatedWidget = '';
            end
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
                if isfield(state,'numElements')
                    setSpinnerLimits(app,state.numElements)
                end
                setValueOfComponents(app,["OutputWorkflowDropDown" "DegreeDropDown" ...
                    "BreakPointsWSDropDown" "DegreeSpinner" "MissingCheckBox"...
                    "BreakPointsDropDown" "ContinuousCheckBox" "BreakPointsSpinner"...
                    "PlotInputDataCheckBox" "PlotDetrendedDataCheckBox"...
                    "PlotTrendCheckBox" "PlotBreakPointsCheckBox"],state);
                if ~isfield(state,'OutputWorkflowDropDownValue')
                    % comes from an old version, workflow should be remove
                    app.OutputWorkflowDropDown.Value = 'remove';
                end
                if isfield(state,'MissingCheckBoxVisible')
                    app.MissingCheckBox.Visible = state.MissingCheckBoxVisible;
                end
                if isfield(state,'SelectedBreakPoints')
                    app.SelectedBreakPoints = state.SelectedBreakPoints;
                end
                if isfield(state,'UnitToMilliseconds')
                    app.UnitToMilliseconds = state.UnitToMilliseconds;
                end
                if isfield(state,'BreakPointsIsLogical')
                    app.BreakPointsIsLogical = state.BreakPointsIsLogical;
                else
                    app.BreakPointsIsLogical = false;
                end
                app.AxesStruct = struct('highlightedBP','','markForUnselect',true,'idx',[],'shadow','');
                app.BreakPointValueLabelNum.Visible = 'off';
                app.BreakPointValueLabelDT.Visible = 'off';
                app.BreakPointValueLabelDur.Visible = 'off';
                app.BreakPointUnitLabelDur.Visible = 'off';
                app.DeleteButton.Visible = 'off';
                
                
                if isempty(updatedWidget)
                    % The chosen data may or may not be in the workspace
                    try
                        replotDataAndBreakpoints(app);
                        app.replotOnGenerateScript = false;
                    catch
                        app.replotOnGenerateScript = true;
                        app.BreakPointsAxes.ButtonDownFcn = @app.addBPtoAxes;
                    end
                    doUpdate(app,false);
                else
                    doUpdateFromWidgetChange(app,app.(updatedWidget),[]);
                end
            end
        end
    end
    
    % get/set methods for public properties
    methods
        function summary = get.Summary(app)

            if ~hasInputDataAndSamplePoints(app)
                summary = getMsgText(app,getMsgId('SummaryNoInput'));
                return;
            end

            varName = getInputDataVarNameForSummary(app);

            if isequal(app.OutputWorkflowDropDown.Value,'find')
                type = 'Find';
            else
                type = 'Remove';
            end

            degree = getDegree(app);
            if degree < 4
                switch degree
                    case 0
                        method = 'Constant';
                    case 1
                        method = 'Linear';
                    case 2
                        method = 'Quadratic';
                    case 3
                        method =  'Cubic';
                end
                summary = char(getMsgText(app,getMsgId(['SummarySmallDegree' type method]),varName));
            else
                summary = char(getMsgText(app,getMsgId(['SummaryLargeDegree' type]),num2str(degree),varName));
            end
        end

        function state = get.State(app)
            state = struct();
            state.VersionSavedFrom = app.Version;
            state.MinCompatibleVersion = 1;
            
            state = getInputDataAndSamplePointsDropDownValues(app,state);
            for k = {'OutputWorkflowDropDown' 'DegreeDropDown' 'DegreeSpinner' 'MissingCheckBox'...
                     'BreakPointsDropDown'  'ContinuousCheckBox' 'BreakPointsSpinner'...
                     'BreakPointsWSDropDown' 'PlotInputDataCheckBox' 'PlotDetrendedDataCheckBox' ...
                     'PlotTrendCheckBox' 'PlotBreakPointsCheckBox'}
                state.([k{1} 'Value']) = app.(k{1}).Value;
            end
            state.MissingCheckBoxVisible = char(app.MissingCheckBox.Visible);
            state.SelectedBreakPoints = app.SelectedBreakPoints;
            state.numElements = app.BreakPointsSpinner.Limits(2);
            state.UnitToMilliseconds = app.UnitToMilliseconds;
            if app.BreakPointsIsLogical
                state.BreakPointsIsLogical = true;
            end
        end
        
        function set.State(app,state)
            setTaskState(app,state);
        end

        function set.Workspace(app,ws)
            app.Workspace = ws;
            app.InputDataDropDown.Workspace = ws;
            app.SamplePointsDropDown.Workspace = ws;
            app.BreakPointsWSDropDown.Workspace = ws; %#ok<MCSUP> 
        end
    end
end

function msgId = getMsgId(id)
msgId = ['trendRemover' id];
end
