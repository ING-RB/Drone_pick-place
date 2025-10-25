classdef (Hidden = true, Sealed = true) dataSmoother < ...
        matlab.internal.dataui.DataPreprocessingTask & ...
        matlab.internal.dataui.movwindowWidgets
    % dataSmoother Smooth noisy data in a Live Script
    %
    %   H = dataSmoother constructs a Live Script tool for smoothing noisy
    %   data and visualizing the results.
    %
    %   See also SMOOTHDATA
    
    %   Copyright 2018-2024 The MathWorks, Inc.
    
    properties (Access = public, Transient, Hidden)
        % Function parameters
        SmoothMethodDropDown                matlab.ui.control.DropDown
        WindowOrSmoothingFactorDropdown     matlab.ui.control.DropDown
        SmoothingFactorSpinner              matlab.ui.control.Spinner
        DegreeLabel                         matlab.ui.control.Label
        DegreeSpinner                       matlab.ui.control.Spinner
        ReturnWindowCheckbox                matlab.ui.control.CheckBox
        % Plot parameters
        PlotSmoothedDataCheckBox            matlab.ui.control.CheckBox
        PlotInputDataCheckBox               matlab.ui.control.CheckBox
        % Helpers
        DefaultSmoothMethod                    = "movmean"; % changes on initialization if keyword indicates a different smoothing method
    end
    
    properties (Constant, Transient, Hidden)
        OutputForVector = 'smoothedData';
        OutputForTable = 'newTable';
        WindowOutput = 'winSize';
        % Serialization Versions - used for managing forward compatibility
        %     N/A: original ship (R2019b)
        %       2: Add versioning (R2020b)
        %       3: Multi table vars and table output (R2021a)
        %       4: Use Base Class (R2022a)
        %       5: Append table vars and tiled layout (R2022b)
        %       6: Return window length and add smoothing method initialization based on keyword (R2024a)
        Version = 6;
    end

    properties
        Workspace = "base"
        State
        Summary
    end
    
    methods (Access = protected)
        function createWidgets(app)
            createInputDataSection(app);
            createParameterSection(app);
            createPlotSection(app,2);
        end

        function adj = getAdjectiveForOutputDropDown(~)
            adj = 'Smoothed';
        end
        
        function createParameterSection(app)
            h = createNewSection(app,getMsgText(app,'MethodAndParametersDelimiter'),{'fit' 125 65 65 'fit' 65},3);
            
            % Layout - Row 1
            uilabel(h,'Text',getMsgText(app,getMsgId('SmoothingMethod')));
            app.SmoothMethodDropDown = uidropdown(h);
            app.SmoothMethodDropDown.Layout.Column = [2 4];
            app.DegreeLabel = uilabel(h,'Text',getMsgText(app,getMsgId('PolynomialDegree')));
            app.DegreeSpinner = uispinner(h);
            
            % Layout - Row 2
            app.WindowOrSmoothingFactorDropdown = uidropdown(h);
            app.WindowOrSmoothingFactorDropdown.Layout.Row = 2;
            app.WindowOrSmoothingFactorDropdown.Layout.Column = 1;
            app.SmoothingFactorSpinner = uispinner(h);
            createWindowWidgets(app,h,2,2,@app.doUpdateFromWidgetChange,[],[])

            % Layout - Row 3
            app.ReturnWindowCheckbox = uicheckbox(h);
            app.ReturnWindowCheckbox.Layout.Row = 3;
            app.ReturnWindowCheckbox.Layout.Column = [1 4];

            % Properties - Row 1
            app.SmoothMethodDropDown.Items = cellstr([getMsgText(app,'Movingmean') ...
                getMsgText(app,'Movingmedian') getMsgText(app,getMsgId('Gaussianfilter')) ...
                getMsgText(app,getMsgId('Locallinearregression')) getMsgText(app,getMsgId('Localquadraticregression')) ...
                getMsgText(app,getMsgId('Robustlocallinearregression')) getMsgText(app,getMsgId('Robustlocalquadraticregression')) ...
                getMsgText(app,getMsgId('SavitzkyGolaypolynomialfilter'))]);
            app.SmoothMethodDropDown.ItemsData = {'movmean' 'movmedian', ...
                'gaussian' 'lowess' 'loess' 'rlowess' 'rloess' 'sgolay'};
            app.SmoothMethodDropDown.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.SmoothMethodDropDown.Tag = 'SmoothMethodDropDown';
            
            app.DegreeSpinner.Step = 1;
            app.DegreeSpinner.RoundFractionalValues = true;
            app.DegreeSpinner.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.DegreeSpinner.Tooltip = getMsgText(app,getMsgId('DegreeTooltip'));
            app.DegreeSpinner.Limits = [0 inf];
            app.DegreeSpinner.UpperLimitInclusive = false;
            
            % Properties - Row 2
            app.WindowOrSmoothingFactorDropdown.Items = cellstr([getMsgText(app,getMsgId('Smoothingfactor')) ...
                getMsgText(app,'Movingwindow')]);
            app.WindowOrSmoothingFactorDropdown.ItemsData = {'factor' 'window'};
            app.WindowOrSmoothingFactorDropdown.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.WindowOrSmoothingFactorDropdown.Tag = 'WindowOrSmoothingFactorDropdown';
            app.SmoothingFactorSpinner.Limits = [0 1];
            app.SmoothingFactorSpinner.Step = 0.05;
            app.SmoothingFactorSpinner.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.SmoothingFactorSpinner.Tooltip = getMsgText(app,getMsgId('SmoothingFactorTooltip'));
            app.SmoothingFactorSpinner.Tag = 'SmoothingFactorSpinner';

            % Properties - Row 3
            app.ReturnWindowCheckbox.Text = getMsgText(app,getMsgId('ReturnWindow'));
            app.ReturnWindowCheckbox.ValueChangedFcn = @app.doUpdateFromWidgetChange;
        end
        
        function createPlotWidgetsRow(app,h)
            % Layout
            app.PlotInputDataCheckBox = uicheckbox(h);
            app.PlotSmoothedDataCheckBox = uicheckbox(h);
            
            % Properties
            app.PlotSmoothedDataCheckBox.Text = getMsgText(app,getMsgId('SmoothedData'));
            app.PlotSmoothedDataCheckBox.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.PlotInputDataCheckBox.Text = getMsgText(app,'InputData');
            app.PlotInputDataCheckBox.ValueChangedFcn = @app.doUpdateFromWidgetChange;
        end

        function updateDefaultsFromKeyword(app,kw)
            % all keywords relevant to changing default behavior, in
            % priority order; e.g. rlowess is chosen over rloess if "rlo"
            % is the input
            keywords = ["movmean" "movmedian" "gaussian" "lowess" "loess" ...
                        "rlowess" "rloess" "sgolay" "Savitzky" "Golay"];

            % finds first element that the input kw is a prefix for, if any
            kwMatches = startsWith(keywords,kw,'IgnoreCase',true);
            firstMatchIdx = find(kwMatches,1);

            % if not, we don't update anything
            if isempty(firstMatchIdx)
                return;
            end

            % get the corresponding full keyword
            fullKeyword = keywords(firstMatchIdx);

            % movmean is already the default, so we don't have to do
            % anything
            if isequal(fullKeyword,"movmean")
                return;
            % unlike most of the keywords, these two correspond to a
            % smoothing method that is different than their actual text
            elseif matches(fullKeyword,["Savitzky" "Golay"])
                fullKeyword = "sgolay";
            end

            app.DefaultSmoothMethod = fullKeyword;
            app.SmoothMethodDropDown.Value = fullKeyword;
            doUpdate(app);
        end
        
        function setWidgetsToDefault(app,fromResetMethod)
            % the default is moving mean, unless set by keyword
            app.SmoothMethodDropDown.Value = app.DefaultSmoothMethod;
            app.WindowOrSmoothingFactorDropdown.Value = 'factor';
            if hasInputData(app)
                setWindowDefault(app,app.InputDataDropDown.WorkspaceValue,...
                    evalSamplePointsVarNameWithCheck(app));
            else
                setWindowDefault(app);
            end
            app.SmoothingFactorSpinner.Value = 0.25;
            app.DegreeSpinner.Limits(2) = inf;
            app.DegreeSpinner.Value = 2;
                       
            fromResetMethod = (nargin > 1) && fromResetMethod; % Called from reset()
            if ~fromResetMethod
                % reset() does not reset the input data, therefore, it does
                % not change wether the app supports visualization or not.
                app.SupportsVisualization = true;
            end
            app.ReturnWindowCheckbox.Value = false;
            app.PlotSmoothedDataCheckBox.Value = true;
            app.PlotInputDataCheckBox.Value = true;
        end
        
        function changedWidget(app,context,~)
            % Update widgets' internal values from callbacks
            context = context.Tag;
            if ismember(context,{app.InputDataDropDown.Tag,...
                    app.SamplePointsDropDown.Tag,app.SamplePointsTableVarDropDown.Tag})
                setWindowDefault(app,app.InputDataDropDown.WorkspaceValue,...
                    evalSamplePointsVarNameWithCheck(app));
            elseif isequal(context,app.WindowTypeDropDown.Tag)
                setWindowType(app);
            end
            
            if isequal(app.SmoothMethodDropDown.Value,'sgolay') && ...
                    (ismember(context,{app.InputDataDropDown.Tag,'ChangedDataVariables',...
                    app.SamplePointsDropDown.Tag,app.SamplePointsTableVarDropDown.Tag,...
                    app.SmoothMethodDropDown.Tag,app.SmoothingFactorSpinner.Tag}) || ...
                    startsWith(context,'Window'))
                % Set sgolay degree limits only when user has chosen this method.
                % Limit is based on input (with datavars), samplepoints,
                % and window size (or smoothing factor)
                setDegreeLimit(app);
            end
        end
        
        function updateWidgets(app,doEvalinBase)
            % Update the layout and visibility of the widgets
            
            updateInputDataAndSamplePointsDropDown(app);
            hasData = hasInputDataAndSamplePoints(app);
            
            app.SmoothMethodDropDown.Enable = hasData;
            app.WindowOrSmoothingFactorDropdown.Enable = hasData;
            
            showFactor = ~isequal(app.WindowOrSmoothingFactorDropdown.Value,'window');
            app.SmoothingFactorSpinner.Visible = showFactor;
            app.SmoothingFactorSpinner.Enable = hasData;
            if showFactor
                app.SmoothingFactorSpinner.Parent = app.WindowParentGrid;
            else
                app.SmoothingFactorSpinner.Parent = [];
            end
            if doEvalinBase
                hasUnits = ~showFactor && hasDurationOrDatetimeSamplePoints(app);
                setWindowVisibility(app,~showFactor,hasData,hasUnits);
            else
                setWindowVisibility(app,~showFactor,hasData);
            end
            
            needDegree = isequal(app.SmoothMethodDropDown.Value,'sgolay');
            app.DegreeLabel.Visible = needDegree;
            app.DegreeSpinner.Visible = needDegree;
            app.DegreeSpinner.Enable = hasData;
            if needDegree
                app.DegreeLabel.Parent = app.WindowParentGrid;
                app.DegreeSpinner.Parent = app.WindowParentGrid;
            else
                app.DegreeLabel.Parent = [];
                app.DegreeSpinner.Parent = [];
            end
            app.ReturnWindowCheckbox.Enable = hasData;

            app.PlotSmoothedDataCheckBox.Enable = hasData;
            app.PlotInputDataCheckBox.Enable = hasData;            
            showPlotCheckboxes(app,app.PlotSmoothedDataCheckBox,app.PlotInputDataCheckBox);
        end
        
        function setDegreeLimit(app)
            % set upper limit of DegreeSpinner based on samplepoints and
            % window size
            if ~hasInputDataAndSamplePoints(app)
                app.DegreeSpinner.Limits(2) = inf;
                return
            end
            x = evalSamplePointsVarNameWithCheck(app);
            % get the window size
            if isequal(app.WindowOrSmoothingFactorDropdown.Value,'factor')
                % calculate the window size based on chosen factor
                A = evalin(app.Workspace,getInputDataVarName(app));
                if isa(A,'tabular')
                    A = getSelectedSubTable(app,A);
                    dv = 1:width(A);
                    dim = 1;
                else
                    dv = [];
                    dim = matlab.internal.math.firstNonSingletonDim(A);
                end
                winsz = matlab.internal.math.chooseWindowSize(A, dim, x, ...
                    1-app.SmoothingFactorSpinner.Value, dv);
            else
                % window size provided by user
                if strcmp(app.WindowTypeDropDown.Value,'full')
                    winsz = app.WindowSizeSpinner1.Value;
                else
                    winsz = [app.WindowSizeSpinner1.Value app.WindowSizeSpinner2.Value];
                end
                if hasDurationOrDatetimeSamplePoints(app)
                    winsz = feval(app.WindowUnitDropDown.Value,winsz);
                end
            end

            % Compute the max degree
            if ~isempty(x)
                idx = 1:numel(x);
                left = movmin(idx, winsz, 'SamplePoints', x);
                right = movmax(idx, winsz, 'SamplePoints', x);
                upperLimit = max(right - left) + 1;
            else
                if numel(winsz) > 1
                    winsz = sum(winsz) + 1;
                end
                upperLimit = winsz;
            end
            % Set the spinner limits, must be greater than 0 given "Limits"
            % must be increasing
            app.DegreeSpinner.Limits(2) = max(upperLimit,1);
        end
        
        function tf = filterInputData(~,A,isTableVar)
            % Keep only Input Data of supported type
            if isa(A,'tabular') % table or timetable
                tf = ~isTableVar; % No tables within tables
            else
                % Copied from smoothdata.m validDataVariableType()
                % additional nonempty restriction
                tf = ~isempty(A) && (isnumeric(A) || islogical(A)) && ~(isinteger(A) && ~isreal(A));
            end
        end
        
        function tf = filterSamplePointsType(~,X,isTableVar)
            % Keep only Sample Points (X-axis) of supported type
            if istall(X)
                tf = false;
            elseif isa(X,'tabular') % table or timetable
                tf = ~isTableVar; % No tables within tables
            else
                % Copied from smoothdata.m checkSamplePoints()
                tf = (isvector(X) || isempty(X)) && ...
                    ((isnumeric(X) && isreal(X) && ~issparse(X)) || ...
                    isduration(X) || isdatetime(X));
            end
        end
        
        function propTable = getLocalPropertyInformation(app)
            Name = ["SmoothMethodDropDown";"DegreeSpinner";"WindowOrSmoothingFactorDropdown";"SmoothingFactorSpinner"];
            Group = repmat(getMsgText(app,'MethodAndParametersDelimiter'),4,1);
            DisplayName = [getMsgText(app,getMsgId('SmoothingMethod'));...
                getMsgText(app,getMsgId('PolynomialDegree'));...
                getMsgText(app,'SmoothingParameter');...
                getMsgText(app,getMsgId('Smoothingfactor'))];                
            StateName = Name + "Value";
            
            propTable = table(Name,Group,DisplayName,StateName);
            propTable = [propTable; getWindowProperties(app)];
            propTable = addFieldsToPropTable(app,propTable);
        end
    end
    
    methods (Access = public)
        % Required for embedding in a Live Script
        function [code,outputs] = generateScript(app,isForExport,overwriteInput)
            if nargin < 2
                % Second input is for "cleaned up" export code. E.g., don't
                % introduce temp vars for plotting.
                % For this task, don't return winSize
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
                % overwriting input is only supported for export script and
                % should not be used internally prior to plotting
                return
            end            
            if ~hasInputDataAndSamplePoints(app)
                return
            end
            
            code = ['% ' char(getMsgText(app,getMsgId('Smoothinputdata')))];
            if overwriteInput
                outputs = {app.getInputDataVarNameForGeneratedScript};
            elseif app.outputIsTable
                outputs = {app.OutputForTable};
            else
                outputs = {app.OutputForVector};
            end

            if app.ReturnWindowCheckbox.Value
                outputs{2} = app.WindowOutput;
                needsWindow = true;
            else
                % Window used in plot title
                needsWindow = app.SupportsVisualization && ~isForExport &&...
                    (app.PlotInputDataCheckBox.Value || app.PlotSmoothedDataCheckBox.Value);
            end

            if needsWindow
                code = [code newline '[' outputs{1} ',' app.WindowOutput '] = '];
            else
                code = [code newline outputs{1} ' = '];
            end

            code = matlab.internal.dataui.addCharToCode(code,['smoothdata(' getInputDataVarNameForGeneratedScript(app)]);
            code = [code getSmallTableCode(app)];
            if isequal(app.WindowOrSmoothingFactorDropdown.Value,'window')
                code = matlab.internal.dataui.addCharToCode(code,[',"' app.SmoothMethodDropDown.Value ...
                    '",' generateScriptForWindowSize(app)]);
            else
                code = matlab.internal.dataui.addCharToCode(code,[',"' app.SmoothMethodDropDown.Value ...
                    '",SmoothingFactor=' num2str(app.SmoothingFactorSpinner.Value,'%.16g')]);
            end
            if isequal(app.SmoothMethodDropDown.Value,'sgolay') && (app.DegreeSpinner.Value ~= 2)
                code = matlab.internal.dataui.addCharToCode(code,[',Degree=' num2str(app.DegreeSpinner.Value)]);
            end
            
            code = matlab.internal.dataui.addCharToCode(code,getDataVariablesNameValuePair(app));
            code = matlab.internal.dataui.addCharToCode(code,getSamplePointsNameValuePair(app));
            code = matlab.internal.dataui.addCharToCode(code,getReplaceValuesNameValuePair(app));
            code = [code ');'];
        end
        
        function code = generateVisualizationScript(app)
            
            code = '';
            if ~hasInputDataAndSamplePoints(app)
                return;
            end
            if ~app.SupportsVisualization
                return;
            end
            numPlots = sum([app.PlotInputDataCheckBox.Value app.PlotSmoothedDataCheckBox.Value]);
            if numPlots == 0
                return;
            end

            resetVariablesToBeCleared(app);
            if ~app.ReturnWindowCheckbox.Value
                markAsVariablesToBeCleared(app,app.WindowOutput);
            end

            code = addVisualizeResultsLine(app);
            x = getSamplePointsVarNameForGeneratedScript(app);
            didHoldOn = false;
            doTiledLayout = isnumeric(app.TableVarPlotDropDown.Value);

            if doTiledLayout
                needOutLoc = ~isequal(app.OutputTypeDropDown.Value,'replace') && app.PlotSmoothedDataCheckBox.Value;
                [code,inIndex,outIndex] = generateScriptSetupTiledLayout(app,code,needOutLoc);
                a1 = [getInputDataVarNameForGeneratedScript(app) '.(' inIndex ')'];
                if isequal(app.OutputTypeDropDown.Value,'append')
                    outIndex = [outIndex '+' num2str(app.InputSize(2))];
                end
                a2 = [app.OutputForTable '.(' outIndex ')'];
                tab = '    ';
            else
                a1 = addDotIndexingToTableName(app,getInputDataVarNameForGeneratedScript(app));
                if app.InputDataHasTableVars && isequal(app.OutputTypeDropDown.Value,'append')
                    a2 = addIndexingIntoAppendedVar(app,app.OutputForTable);
                elseif app.outputIsTable
                    a2 = addDotIndexingToTableName(app,app.OutputForTable);
                else
                    a2 = app.OutputForVector;
                end
                tab = '';
            end
            if app.PlotInputDataCheckBox.Value                
                code = generateScriptPlotInputData(app,code,x,a1,tab);
                [code,didHoldOn] = addHold(app,code,'on',didHoldOn,numPlots,tab);
            end
            if app.PlotSmoothedDataCheckBox.Value
                code = generateScriptPlotCleanedData(app,code,x,a2,tab,char(getMsgText(app,getMsgId('SmoothedData'))));
            end
            code = addHold(app,code,'off',didHoldOn,numPlots,tab);

            % Window size is displayed via axes title
            code = [code newline tab 'title("' char(getMsgText(app,getMsgId('MovingWindowSize'))) ': '];
            if isequal(app.WindowTypeDropDown.Value,'full') || ...
                    isequal(app.WindowOrSmoothingFactorDropdown.Value,'factor')
                % e.g. "Moving window size: 3 hr"
                code = [code '" + string(' app.WindowOutput '));'];
            else
                % e.g. "Moving window size: [2 hr,6 hr]"
                code = [code '[" + string(' app.WindowOutput '(1)) + "," + string(' app.WindowOutput '(2)) + "]");'];
            end
            code = addLegendAndAxesLabels(app,code,tab);

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
                setWindowDropDownValues(app,state);
                setValueOfComponents(app,["SmoothMethodDropDown" "WindowOrSmoothingFactorDropdown" ...
                    "SmoothingFactorSpinner" "DegreeSpinner" "ReturnWindowCheckbox"...
                    "PlotSmoothedDataCheckBox" "PlotInputDataCheckBox"],state);

                if isfield(state,"DefaultSmoothMethod")
                    app.DefaultSmoothMethod = state.DefaultSmoothMethod;
                end
                
                if isempty(updatedWidget)
                    doUpdate(app,false);
                else
                    doUpdateFromWidgetChange(app,app.(updatedWidget),[]);
                end
            end
        end

        function msg = getInspectorDisplayMsg(app)
            msg = '';
            if hasInputData(app,false) && isscalar(app.InputDataTableVarDropDown(1).Items)
                % display a message indicating that there are no valid
                % variables in the table
                msg = getMsgText(app,getMsgId('NoValidVars'));
            end
        end
    end

    methods
        function summary = get.Summary(app)
            if ~hasInputDataAndSamplePoints(app)
                summary = getMsgText(app,'Tool_dataSmoother_Description');
                return;
            end
            varName = getInputDataVarNameForSummary(app);
            % Get the English name of the method (not the nv pair name)
            method = app.SmoothMethodDropDown.Items{strcmp(app.SmoothMethodDropDown.ItemsData,app.SmoothMethodDropDown.Value)};
            if ~isequal(app.SmoothMethodDropDown.Value,'sgolay') && ~isequal(app.SmoothMethodDropDown.Value,'gaussian')
                method(1) = lower(method(1));
            end
            summary = getMsgText(app,getMsgId('Summary'),varName,method);
        end
        
        function state = get.State(app)
            state = struct();
            state.VersionSavedFrom = app.Version;
            % save the default smoothing method in the state in case it has
            % been changed from moving mean because of a keyword
            state.DefaultSmoothMethod = app.DefaultSmoothMethod;
            state.MinCompatibleVersion = 1;
            state = getInputDataAndSamplePointsDropDownValues(app,state);
            state = getWindowDropDownValues(app,state);
            for k = {'SmoothMethodDropDown' 'WindowOrSmoothingFactorDropdown' ...
                    'SmoothingFactorSpinner' 'DegreeSpinner' 'ReturnWindowCheckbox'...
                    'PlotSmoothedDataCheckBox' 'PlotInputDataCheckBox'}
                state.([k{1} 'Value']) = app.(k{1}).Value;
            end
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
msgId = ['dataSmoother' id];
end
