classdef (Hidden = true, Sealed = true) localExtremaFinder < ...
        matlab.internal.dataui.DataPreprocessingTask & ...
        matlab.internal.dataui.movwindowWidgets
    % localExtremaFinder Find local maxima and minima in a Live Script
    %
    %   H = localExtremaFinder constructs a Live Script tool for finding
    %   and visualizing local maxima and minima.
    %
    %   See also ISLOCALMAX, ISLOCALMIN
    
    %   Copyright 2018-2024 The MathWorks, Inc.
    
    properties (Access = public, Transient, Hidden)
        % Function parameters
        FindMethodDropDown                  matlab.ui.control.DropDown
        MinProminenceSpinner                matlab.ui.control.Spinner
        FlatSelectionDropDown               matlab.ui.control.DropDown
        MinSeparationSpinner                matlab.ui.control.Spinner
        MaxNumSpinner                       matlab.ui.control.Spinner
        % Plot parameters
        PlotInputDataCheckBox               matlab.ui.control.CheckBox
        PlotMaxCheckBox                     matlab.ui.control.CheckBox
        PlotMinCheckBox                     matlab.ui.control.CheckBox
        % Helpers
        DefaultFindMethod                   = "max" % changes on initialization if keyword indicates min or both
    end
    
    properties (Constant, Transient, Hidden)
        % Constants
        Outputs = {'maxIndices' 'minIndices' 'newTable'};
        % Serialization Versions - used for managing forward compatibility
        %     N/A: original ship (R2019b)
        %       2: Add versioning (R2020b)
        %       3: Multi table vars and table output (R2021a)
        %       4: Use Base Class (R2022a)
        %       5: Table output & tiled layout (R2022b)
        %       6: Add find method initialization by keyword (R2024a)
        Version = 6;
    end

    properties (Access = private)
        AppendedVarNames string
    end

    properties
        Workspace = "base"
        State
        Summary
    end
    
    methods (Access = protected)
        function createWidgets(app)
            createInputDataSection(app,true);
            createParameterRows(app);
            createPlotSection(app,3);
        end
        
        function createParameterRows(app)
            h = createNewSection(app,getMsgText(app,getMsgId('ParametersDelimiter')),...
                {'fit' 80 'fit' 'fit' 70 70 70},3);
            
            % createExtremaTypeRow
            % Layout
            uilabel(h,'Text',getMsgText(app,getMsgId('ExtremaType')));
            app.FindMethodDropDown = uidropdown(h);
            uilabel(h,'Text',getMsgText(app,getMsgId('FlatSelection')));
            app.FlatSelectionDropDown = uidropdown(h);
            
            % Properties
            app.FindMethodDropDown.Items = cellstr([getMsgText(app,getMsgId('Maxima')) ...
                getMsgText(app,getMsgId('Minima')) getMsgText(app,getMsgId('Both'))]);
            app.FindMethodDropDown.ItemsData = {'max' 'min' 'both'};
            app.FindMethodDropDown.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.FindMethodDropDown.Tag = 'FindMethodDropDown';
            app.FlatSelectionDropDown.Items = cellstr([getMsgText(app,getMsgId('Center')) ...
                getMsgText(app,getMsgId('First')) getMsgText(app,getMsgId('Last')) getMsgText(app,getMsgId('All'))]);
            app.FlatSelectionDropDown.ItemsData = {'center' 'first' 'last' 'all'};
            app.FlatSelectionDropDown.Tooltip = getMsgText(app,getMsgId('FlatTooltip'));
            app.FlatSelectionDropDown.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.FlatSelectionDropDown.Tag = 'FlatSelectionDropDown';
            
            % createExtremaNumberRow
            % Layout
            L = uilabel(h,'Text',getMsgText(app,getMsgId('MaxNumExtrema')));
            L.Layout.Row = 2;
            L.Layout.Column = 1;
            app.MaxNumSpinner = uispinner(h);
            uilabel(h,'Text',getMsgText(app,getMsgId('MinProminence')));
            app.MinProminenceSpinner = uispinner(h);
            
            % Properties
            app.MaxNumSpinner.Tooltip = getMsgText(app,getMsgId('MaxNumTooltip'));
            app.MaxNumSpinner.Limits = [1 Inf];
            app.MaxNumSpinner.Step = 1;
            app.MaxNumSpinner.RoundFractionalValues = true;
            app.MaxNumSpinner.ValueDisplayFormat = '%.0f';
            app.MaxNumSpinner.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.MaxNumSpinner.Tag = 'MaxNumSpinner';
            app.MinProminenceSpinner.Tooltip = getMsgText(app,getMsgId('MinProminenceTooltip'));
            app.MinProminenceSpinner.Limits = [0 Inf];
            app.MinProminenceSpinner.UpperLimitInclusive = false;
            app.MinProminenceSpinner.ValueDisplayFormat = '%g';
            app.MinProminenceSpinner.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.MinProminenceSpinner.Tag = 'MinProminenceSpinner';
        
            % createExtremaProminenceRow
            % Layout
            L = uilabel(h,'Text',getMsgText(app,getMsgId('MinSeparation')));
            L.Layout.Row = 3;
            L.Layout.Column = 1;
            app.MinSeparationSpinner = uispinner(h);
            uilabel(h,'Text',getMsgText(app,getMsgId('ProminenceWindow')));
            createWindowWidgets(app,h,3,4,@app.doUpdateFromWidgetChange,[],getMsgText(app,getMsgId('UnitTooltip')));
            
            % Properties
            app.MinSeparationSpinner.Tooltip = getMsgText(app,getMsgId('MinSeparationTooltip'));
            app.MinSeparationSpinner.Limits = [0 Inf];
            app.MinSeparationSpinner.UpperLimitInclusive = false;
            app.MinSeparationSpinner.ValueDisplayFormat = '%g';
            app.MinSeparationSpinner.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.MinSeparationSpinner.Tag = 'MinSeparationSpinner';
            app.WindowSizeSpinner1.UpperLimitInclusive = true;
            app.WindowSizeSpinner2.UpperLimitInclusive = true;
        end
        
        function createPlotWidgetsRow(app,h)
            % Layout
            app.PlotInputDataCheckBox = uicheckbox(h);
            app.PlotInputDataCheckBox.Layout.Row = 2;
            app.PlotInputDataCheckBox.Layout.Column = 1;
            app.PlotMaxCheckBox = uicheckbox(h);
            app.PlotMinCheckBox = uicheckbox(h);

            % Properties
            app.PlotMaxCheckBox.Text = getMsgText(app,getMsgId('LocalMaxima'));
            app.PlotMaxCheckBox.Value = true;
            app.PlotMaxCheckBox.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.PlotMinCheckBox.Text = getMsgText(app,getMsgId('LocalMinima'));
            app.PlotMinCheckBox.Value = false;
            app.PlotMinCheckBox.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.PlotInputDataCheckBox.Text = getMsgText(app,'InputData');
            app.PlotInputDataCheckBox.Value = true;
            app.PlotInputDataCheckBox.ValueChangedFcn = @app.doUpdateFromWidgetChange;
        end

        function updateDefaultsFromKeyword(app,kw)
            % all keywords relevant to changing default behavior, in
            % priority order. We also include default behavior keywords
            % that have the same initial characters as non-default keywords
            % at higher priority to break ties in favor of the default
            % behavior.
            keywords = ["localmax", "islocalmax", "max", "localmin", ...
                "islocalmin", "min", "valleys", "extrema"];

            % finds first element that the input kw is a prefix for, if any
            kwMatches = startsWith(keywords,kw,'IgnoreCase',true);
            firstMatchIdx = find(kwMatches,1);

            % if not, we don't update anything
            if isempty(firstMatchIdx)
                return;
            end

            % get the corresponding full keyword
            fullKeyword = keywords(firstMatchIdx);

            % These keywords match with the existing default behavior of
            % "max"
            if matches(fullKeyword,["localmax", "islocalmax", "max"])
                return;
            % for these keywords, we need to map them to the corresponding
            % dropdown value
            elseif matches(fullKeyword,["localmin","islocalmin","valleys"])
                fullKeyword = "min";
            elseif isequal(fullKeyword,"extrema")
                fullKeyword = "both";
            end

            app.DefaultFindMethod = fullKeyword;
            app.FindMethodDropDown.Value = fullKeyword;

            % for methods that are not "max", we need to select the correct
            % plotting checkboxes
            resetMethodPlotCheckboxes(app);

            doUpdate(app);
        end
        
        function setWidgetsToDefault(app,fromResetMethod)
            app.FindMethodDropDown.Value = app.DefaultFindMethod;
            app.MinProminenceSpinner.Value = 0;
            app.MinProminenceSpinner.Step = 1;
            app.WindowSizeSpinner1.Value = 100;
            app.WindowSizeSpinner1.LowerLimitInclusive = false;
            app.WindowSizeSpinner2.Value = 50;
            app.WindowUnitDropDown.Value = 'days';
            app.WindowTypeDropDown.Value = 'full';
            app.FlatSelectionDropDown.Value = 'center';
            app.MinSeparationSpinner.Value = 0;
            app.MinSeparationSpinner.Step = 1;
            
            fromResetMethod = (nargin > 1) && fromResetMethod; % Called from reset()
            if ~fromResetMethod
                % reset() does not reset the input data, therefore, it does
                % not change wether the app supports visualization or not.
                app.SupportsVisualization = true;
            end

            resetMethodPlotCheckboxes(app);
            app.PlotInputDataCheckBox.Value = true;

            app.MaxNumSpinner.Value = getDefaultMaxNum(app);
            app.MaxNumSpinner.Step = matlab.internal.dataui.getStepSize(...
                app.MaxNumSpinner.Value,true);
        end

        function resetMethodPlotCheckboxes(app)
            % Set the PlotMin/PlotMax checkboxes to the correct default
            % values for the current FindMethod.
            findMethod = app.FindMethodDropDown.Value;
            app.PlotMaxCheckBox.Value = ~isequal(findMethod, 'min');
            app.PlotMinCheckBox.Value = ~isequal(findMethod, 'max');
        end

        function m = getDefaultMaxNum(app)
            m = max(getNumelAlongDefaultDim(app),1);
        end
        
        function changedWidget(app,context,event)
            % Update widgets' internal values from callbacks
            context = context.Tag;
            if isequal(context,app.InputDataDropDown.Tag)
                % Depends on the input data
                app.MaxNumSpinner.Value = getDefaultMaxNum(app);
                app.MaxNumSpinner.Step = matlab.internal.dataui.getStepSize(...
                    app.MaxNumSpinner.Value,true);
            elseif isequal(context,app.FindMethodDropDown.Tag)
                resetMethodPlotCheckboxes(app);
            elseif isequal(context,app.WindowTypeDropDown.Tag)
                setWindowType(app);
            elseif isequal(context,app.MaxNumSpinner.Tag)
                app.MaxNumSpinner.Step = matlab.internal.dataui.getStepSize(...
                    app.MaxNumSpinner.Value,true,event.PreviousValue);
            elseif isequal(context,app.MinProminenceSpinner.Tag)
                app.MinProminenceSpinner.Step = matlab.internal.dataui.getStepSize(...
                    app.MinProminenceSpinner.Value,false,event.PreviousValue);
            elseif isequal(context,app.MinSeparationSpinner.Tag)
                app.MinSeparationSpinner.Step = matlab.internal.dataui.getStepSize(...
                    app.MinSeparationSpinner.Value,false,event.PreviousValue);
            end
        end
        
        function updateWidgets(app,doEvalinBase)
            % Update the layout and visibility of the widgets
            updateInputDataAndSamplePointsDropDown(app);
            hasData = hasInputDataAndSamplePoints(app);
            
            app.FindMethodDropDown.Enable = hasData;
            app.MinProminenceSpinner.Enable = hasData;
            
            % Prominence window is always on
            if doEvalinBase
                hasUnits = hasDurationOrDatetimeSamplePoints(app);
                setWindowVisibility(app,true,hasData,hasUnits);
            else
                setWindowVisibility(app,true,hasData);
                hasUnits = app.WindowUnitVisible;
            end
            has2spinners = app.WindowSizeSpinner2.Visible;
            app.WindowParentGrid.ColumnWidth{6} = 70*(has2spinners || hasUnits);
            app.WindowParentGrid.ColumnWidth{7} = 70*(has2spinners && hasUnits);
            
            app.FlatSelectionDropDown.Enable = hasData;
            app.MinSeparationSpinner.Enable = hasData;
            app.MaxNumSpinner.Enable = hasData;
            
            app.PlotMaxCheckBox.Enable = hasData;
            app.PlotMinCheckBox.Enable = hasData;
            app.PlotInputDataCheckBox.Enable = hasData;

            app.PlotMinCheckBox.Layout.Column = 2 + isequal(app.FindMethodDropDown.Value,'both');
            showBoxes = showPlotCheckboxes(app,app.PlotMaxCheckBox,...
                app.PlotMinCheckBox,app.PlotInputDataCheckBox);
       
            app.PlotMaxCheckBox.Visible = ismember(app.FindMethodDropDown.Value,{'max' 'both'}) && showBoxes;
            app.PlotMinCheckBox.Visible = ismember(app.FindMethodDropDown.Value,{'min' 'both'}) && showBoxes;
        end
        
        function code = generateScriptImpl(app,code,outname,funName,isBoth)
            code = [code newline outname ' = '];            
            code = matlab.internal.dataui.addCharToCode(code,['islocal' funName '(' getInputDataVarNameForGeneratedScript(app)]);
            code = [code getSmallTableCode(app)];
            if app.MinProminenceSpinner.Value ~= 0
                code = matlab.internal.dataui.addCharToCode(code,[',MinProminence=' num2str(app.MinProminenceSpinner.Value,'%.16g')]);
            end
            
            if (isequal(app.WindowTypeDropDown.Value,'full') && (app.WindowSizeSpinner1.Value ~= 100)) || ...
                    (~isequal(app.WindowTypeDropDown.Value,'full') && (app.WindowSizeSpinner1.Value ~= 50 || app.WindowSizeSpinner2.Value ~= 50))
                code = matlab.internal.dataui.addCharToCode(code,[',ProminenceWindow=' generateScriptForWindowSize(app)]);
            end
            
            if ~isequal(app.FlatSelectionDropDown.Value,'center')
                code = matlab.internal.dataui.addCharToCode(code,[',FlatSelection="' app.FlatSelectionDropDown.Value '"']);
            end
            if app.MinSeparationSpinner.Value ~= 0
                s = num2str(app.MinSeparationSpinner.Value,'%.16g');
                if hasDurationOrDatetimeSamplePoints(app)
                    s = [app.WindowUnitDropDown.Value '(' s ')'];
                end
                code = matlab.internal.dataui.addCharToCode(code,[',MinSeparation=' s]);
            end
            
            if app.MaxNumSpinner.Value ~= getDefaultMaxNum(app)
                code = matlab.internal.dataui.addCharToCode(code,[',MaxNumExtrema=' num2str(app.MaxNumSpinner.Value)]);
            end
            
            code = matlab.internal.dataui.addCharToCode(code,getDataVariablesNameValuePair(app));
            code = matlab.internal.dataui.addCharToCode(code,getSamplePointsNameValuePair(app));
            code = matlab.internal.dataui.addCharToCode(code,getOutputFormatNameValuePair(app));
            code = [code ');'];

            if isequal(app.OutputTypeDropDown.Value,'append')
                if ~isBoth
                    code = generateScriptAppendLogical(app,code,outname,funName);
                elseif isequal(funName,'max')
                    % first time through, add rename to max vars only
                    [code,app.AppendedVarNames] = adjustVarNames(app,code,outname,funName);
                else
                    % second time through,add rename to min vars
                    % but need to take into account max var names
                    code = adjustVarNames(app,code,outname,funName,[app.AllTableVarNames app.AppendedVarNames]);
                    % append both sets of vars
                    tick = '`';
                    if isAppWorkflow(app)
                        tick = '';
                    end
                    code = [code newline app.Outputs{3} ' = [' tick app.InputDataDropDown.Value tick ...
                        ' ' app.Outputs{1} ' ' app.Outputs{2} '];'];
                    % clear extra vars
                    resetVariablesToBeCleared(app);
                    markAsVariablesToBeCleared(app,app.Outputs{1},app.Outputs{2});
                    code = addClear(app,code);
                end
            end            
        end
        
        function tf = filterInputData(~,A,isTableVar)
            % Keep only Input Data of supported type
            if isa(A,'tabular') % table or timetable
                tf = ~isTableVar; % No tables within tables
            else
                % Copied from localmax.m validDataVariableType()
                % additional nonempty restriction
                tf = ~isempty(A) && (isnumeric(A) || islogical(A)) && isreal(A);
            end
        end
        
        function tf = filterSamplePointsType(~,X,isTableVar)
            % Keep only Sample Points (X-axis) of supported type
            if istall(X)
                tf = false;
            elseif isa(X,'tabular') % table or timetable
                tf = ~isTableVar; % No tables within tables
            else
                % Copied from localmax.m checkSamplePoints()
                tf = (isvector(X) || isempty(X)) && ...
                    ((isfloat(X) && isreal(X) && ~issparse(X)) || ...
                    isduration(X) || isdatetime(X));
            end
        end
        
        function num = numberOfPlots(app)
            num = sum([app.PlotInputDataCheckBox.Value app.PlotMaxCheckBox.Value app.PlotMinCheckBox.Value]);
        end
    end
    
    % Required for embedding in a Live Script
    methods (Access = public)
        function [code,outputs] = generateScript(app,~)
            % Second input is the isForExport flag, but for this task,
            % there is no change
            
            outputs = {};
            if ~hasInputDataAndSamplePoints(app)
                code = '';                
                return
            end            
            findMethod = app.FindMethodDropDown.Value;
            isBoth = isequal(findMethod,'both');
            if isequal(app.OutputTypeDropDown.Value,'append')
                outputs = app.Outputs(3);
            end
            if isBoth
                code = ['% ' char(getMsgText(app,'Tool_localExtremaFinder_Description'))];
                if isempty(outputs)
                    outputs = app.Outputs(1:2);
                end
                code = generateScriptImpl(app,code,app.Outputs{1},'max',isBoth);
                code = generateScriptImpl(app,code,app.Outputs{2},'min',isBoth);                
            elseif isequal(findMethod,'max')
                code = ['% ' char(getMsgText(app,getMsgId('Findlocalmaxima')))];
                if isempty(outputs)
                    outputs = app.Outputs(1);
                end
                code = generateScriptImpl(app,code,outputs{1},'max',isBoth);
            else
                code = ['% ' char(getMsgText(app,getMsgId('Findlocalminima')))];
                if isempty(outputs)
                    outputs = app.Outputs(2);
                end
                code = generateScriptImpl(app,code,outputs{1},'min',isBoth);
            end
        end
        
        function code = generateVisualizationScript(app)
            code = '';
            if ~hasInputDataAndSamplePoints(app) || ~app.SupportsVisualization || numberOfPlots(app) == 0
                return;
            end
            
            resetVariablesToBeCleared(app);
            code = addVisualizeResultsLine(app);
            
            x = getSamplePointsVarNameForGeneratedScript(app); % 'X' or ''
            didHoldOn = false;
            doTiledLayout = isnumeric(app.TableVarPlotDropDown.Value);

            if doTiledLayout
                needOutLoc = ~isequal(app.OutputTypeDropDown.Value,'largeMask') && (app.PlotMaxCheckBox.Value || app.PlotMinCheckBox.Value);
                [code,inIndex,outIndex] = generateScriptSetupTiledLayout(app,code,needOutLoc);
                a = [getInputDataVarNameForGeneratedScript(app) '.(' inIndex ')'];
                if isequal(app.OutputTypeDropDown.Value,'append')
                    W = num2str(app.InputSize(2));
                    outputs{1} = [app.Outputs{3} '.(' outIndex '+' W ')'];
                    if isequal(app.FindMethodDropDown.Value,'both')
                        W = num2str(app.InputSize(2) + numel(app.getSelectedVarNames));                        
                    end
                    outputs{2} = [app.Outputs{3} '.(' outIndex '+' W ')'];
                elseif isequal(app.OutputTypeDropDown.Value,'table')
                    outputs{1} = [app.Outputs{1} '.(' outIndex ')'];
                    outputs{2} = [app.Outputs{2} '.(' outIndex ')'];
                elseif isequal(app.OutputTypeDropDown.Value,'largeMask')
                    outputs{1} = [app.Outputs{1} '(:,' inIndex ')'];
                    outputs{2} = [app.Outputs{2} '(:,' inIndex ')'];                    
                else % smallMask
                    outputs{1} = [app.Outputs{1} '(:,' outIndex ')'];
                    outputs{2} = [app.Outputs{2} '(:,' outIndex ')'];
                end
                tab = '    ';
            else
                a = addDotIndexingToTableName(app,getInputDataVarNameForGeneratedScript(app));
                if isequal(app.OutputTypeDropDown.Value,'append')
                    outputs{1} = addIndexingIntoAppendedVar(app,app.Outputs{3});
                    if isequal(app.FindMethodDropDown.Value,'both')
                        % need to find location of min indices
                        [~,subscript] = addSubscriptIndexingToTableName(app,[]);
                        subscript = subscript + numel(app.getSelectedVarNames);
                        outputs{2} = [app.Outputs{3} '.(' num2str(subscript) ')'];
                    else
                        outputs{2} = addIndexingIntoAppendedVar(app,app.Outputs{3});
                    end
                elseif isequal(app.OutputTypeDropDown.Value,'table')
                    outputs{1} = addDotIndexingToTableName(app,app.Outputs{1});
                    outputs{2} = addDotIndexingToTableName(app,app.Outputs{2});
                else
                    [outputs{1},subscript] = addSubscriptIndexingToTableName(app,app.Outputs{1});
                    outputs{2} = app.Outputs{2};
                    if ~isempty(subscript)
                        outputs{2} = [outputs{2} '(:,' num2str(subscript) ')'];
                    end
                end
                tab = '';
            end

            if app.PlotInputDataCheckBox.Value
                code = generateScriptPlotInputData(app,code,x,a,tab);
                [code,didHoldOn] = addHold(app,code,'on',didHoldOn,numberOfPlots(app),tab);
            end
            
            if app.PlotMaxCheckBox.Value
                code = [code newline newline tab '% ' char(getMsgText(app,getMsgId('Plotlocalmaxima')))];
                if ~isempty(x)
                    x2 = [x '(' outputs{1} ')'];
                else
                    x2 = ['find(' outputs{1} ')'];
                end
                % Use scatter instead of plot to fill marker with the color
                % identified by SeriesIndex
                code = [code newline tab 'scatter(' x2 ','];
                code = matlab.internal.dataui.addCharToCode(code,[a '(' outputs{1} '),'],doTiledLayout);
                code = matlab.internal.dataui.addCharToCode(code,'"^",',doTiledLayout);
                code = matlab.internal.dataui.addCharToCode(code,'"filled",',doTiledLayout);
                code = matlab.internal.dataui.addCharToCode(code,'SeriesIndex=2,',doTiledLayout);
                code = addDisplayName(app,code,char(getMsgText(app,getMsgId('LocalMaxima'))),doTiledLayout);
                [code,didHoldOn] = addHold(app,code,'on',didHoldOn,numberOfPlots(app),tab);
            end
            
            if app.PlotMinCheckBox.Value
                code = [code newline newline tab '% ' char(getMsgText(app,getMsgId('Plotlocalminima')))];
                if ~isempty(x)
                    x2 = [x '(' outputs{end} ')'];
                else
                    x2 = ['find(' outputs{end} ')'];
                end
                % Use scatter instead of plot to fill marker with the color
                % identified by SeriesIndex
                code = [code newline tab 'scatter(' x2 ','];
                code = matlab.internal.dataui.addCharToCode(code,[a '(' outputs{end} '),'],doTiledLayout);
                code = matlab.internal.dataui.addCharToCode(code,'"v",',doTiledLayout);
                code = matlab.internal.dataui.addCharToCode(code,'"filled",',doTiledLayout);
                code = matlab.internal.dataui.addCharToCode(code,'SeriesIndex=3,',doTiledLayout);
                code = addDisplayName(app,code,char(getMsgText(app,getMsgId('LocalMinima'))),doTiledLayout);
            end
            
            if app.PlotMaxCheckBox.Value && app.PlotMinCheckBox.Value
                code = [code newline tab 'title("' char(getMsgText(app,getMsgId('NumberofExtrema'))) ': " + (nnz(' outputs{1} ')+nnz(' outputs{2} ')))'];
            elseif app.PlotMaxCheckBox.Value
                code = [code newline tab 'title("' char(getMsgText(app,getMsgId('NumberofExtrema'))) ': " + nnz(' outputs{1} '))'];
            elseif app.PlotMinCheckBox.Value
                code = [code newline tab 'title("' char(getMsgText(app,getMsgId('NumberofExtrema'))) ': " + nnz(' outputs{end} '))'];
            end
            
            code = addHold(app,code,'off',didHoldOn,numberOfPlots(app),tab);
            code = addLegendAndAxesLabels(app,code,tab);            
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
                setWindowDropDownValues(app,state);
                setValueOfComponents(app,["FindMethodDropDown" "MinProminenceSpinner" ...
                    "FlatSelectionDropDown" "MinSeparationSpinner" ...
                    "MaxNumSpinner" "PlotInputDataCheckBox" ...
                    "PlotMaxCheckBox" "PlotMinCheckBox"],state);
                if isfield(state, "DefaultFindMethod")
                    app.DefaultFindMethod = state.DefaultFindMethod;
                end
                
                app.MaxNumSpinner.Step = matlab.internal.dataui.getStepSize(...
                    app.MaxNumSpinner.Value,true);
                app.MinProminenceSpinner.Step = matlab.internal.dataui.getStepSize(...
                    app.MinProminenceSpinner.Value,false);
                app.MinSeparationSpinner.Step = matlab.internal.dataui.getStepSize(...
                    app.MinSeparationSpinner.Value,false);
                
                doUpdate(app,false);
            end
        end
    end

    methods
        function summary = get.Summary(app)
            
            if ~hasInputDataAndSamplePoints(app)
                summary = getMsgText(app,'Tool_localExtremaFinder_Description');
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
            state = getWindowDropDownValues(app,state);
            for k = {'FindMethodDropDown' 'MinProminenceSpinner' ...
                    'FlatSelectionDropDown' 'MinSeparationSpinner' ...
                    'MaxNumSpinner' 'PlotInputDataCheckBox' ...
                    'PlotMaxCheckBox' 'PlotMinCheckBox'}
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
msgId = ['localExtremaFinder' id];
end
