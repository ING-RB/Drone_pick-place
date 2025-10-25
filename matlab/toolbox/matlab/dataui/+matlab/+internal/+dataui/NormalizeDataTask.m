classdef (Hidden = true, Sealed = true) NormalizeDataTask < ...
        matlab.internal.dataui.DataPreprocessingTask
    
    % NormalizeDataTask Normalize data in a Live Script
    %
    %   H = NormalizeDataTask constructs a Live Script tool for normalizing
    %   data and visualizing the results.
    %
    %   See also NORMALIZE
    
    %   Copyright 2021-2024 The MathWorks, Inc.
    
    properties (Access = public, Transient, Hidden)
        % Function parameters
        MethodDropDown                  matlab.ui.control.DropDown
        ZscoreDropDown                  matlab.ui.control.DropDown
        NormSpinner                     matlab.ui.control.Spinner
        ScaleDropDown                   matlab.ui.control.DropDown
        ScaleSpinner                    matlab.ui.control.Spinner
        ScaleWorkspaceDropDown          matlab.ui.control.internal.model.WorkspaceDropDown
        RangeSpinner1                   matlab.ui.control.Spinner
        RangeSpinner2                   matlab.ui.control.Spinner
        CenterDropDown                  matlab.ui.control.DropDown
        CenterSpinner                   matlab.ui.control.Spinner
        CenterWorkspaceDropDown         matlab.ui.control.internal.model.WorkspaceDropDown
        CenterLabel                     matlab.ui.control.Label
        ScaleLabel                      matlab.ui.control.Label
        OutputCheckBox                  matlab.ui.control.CheckBox
        
        % Plot parameters
        PlotNormalizedDataCheckBox      matlab.ui.control.CheckBox
        PlotInputDataCheckBox           matlab.ui.control.CheckBox
        TiledLayoutCheckBox             matlab.ui.control.CheckBox

        % Helpers
        DefaultMethod                   = "zscore" % changes if keyword indicates a different method
    end
    
    properties (Constant, Transient, Hidden)
        OutputForMatrix   = 'normalizedData';
        OutputForTable    = 'newTable';
        AdditionalOutputs = {'centerValue' 'scaleValue'};
        % Serialization Versions - used for managing forward compatibility
        %       1: original ship (R2021b)
        %       2: Use Base Class (R2022a)
        %       3: Append table vars and tiled layout (R2022b)
        %       4: Update default method based on keyword (R2024a)
        Version = 4;
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
            createPlotSection(app,3);
            app.SamplePointsForPlotOnly = true;
        end

        function adj = getAdjectiveForOutputDropDown(~)
            adj = 'Normalized';
        end
        
        function createParameterSection(app)
            h = createNewSection(app,getMsgText(app,'MethodAndParametersDelimiter'),...
                {'fit' 'fit' 'fit' 'fit' 'fit'},2);
            
            % Layout
            uilabel(h,'Text',getMsgText(app,getMsgId('Method')));
            app.MethodDropDown = uidropdown(h);
            app.ZscoreDropDown = uidropdown(h);
            app.NormSpinner = uispinner(h);
            app.NormSpinner.Layout.Column = 3;
            app.RangeSpinner1 = uispinner(h);
            app.RangeSpinner1.Layout.Column = 3;
            app.RangeSpinner1.Layout.Row = 1;
            app.RangeSpinner2 = uispinner(h);
            app.RangeSpinner2.Layout.Column = 4;
            app.RangeSpinner2.Layout.Row = 1;
            app.CenterDropDown = uidropdown(h);
            app.CenterDropDown.Layout.Row = 1;
            app.CenterSpinner = uispinner(h);
            app.CenterSpinner.Layout.Row = 1;
            app.CenterWorkspaceDropDown = matlab.ui.control.internal.model.WorkspaceDropDown('Parent',h);
            app.CenterWorkspaceDropDown.ShowNonExistentVariable = true;
            app.CenterWorkspaceDropDown.Layout.Row = 1;
            app.CenterLabel = uilabel(h,'Text',getMsgText(app,getMsgId('Center')));
            app.CenterLabel.Layout.Column = 3;
            app.CenterLabel.Layout.Row = 1;
            app.ScaleDropDown = uidropdown(h);
            app.ScaleSpinner = uispinner(h);
            app.ScaleWorkspaceDropDown = matlab.ui.control.internal.model.WorkspaceDropDown('Parent',h);
            app.ScaleWorkspaceDropDown.ShowNonExistentVariable = true;
            app.ScaleLabel = uilabel(h,'Text',getMsgText(app,getMsgId('Scale')));
            app.ScaleLabel.Layout.Column = 3;
            app.ScaleLabel.Layout.Row = 2;
            app.OutputCheckBox = uicheckbox(h);
            app.OutputCheckBox.Layout.Column = [1 2];
            
            % Properties
            app.MethodDropDown.Items = [getMsgText(app,getMsgId('Zscore')),getMsgText(app,getMsgId('Norm')),...
                getMsgText(app,getMsgId('Range')),getMsgText(app,getMsgId('MedianIQR')),...
                getMsgText(app,getMsgId('Center')),getMsgText(app,getMsgId('Scale')),getMsgText(app,getMsgId('CenterAndScale'))];
            app.MethodDropDown.ItemsData = {'zscore','norm','range','medianiqr','center','scale','centerAndScale'};
            app.MethodDropDown.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.ZscoreDropDown.Items = [getMsgText(app,getMsgId('STD')),getMsgText(app,getMsgId('MAD'))];
            app.ZscoreDropDown.ItemsData = {'std','robust'};
            app.ZscoreDropDown.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.NormSpinner.Tooltip = getMsgText(app,getMsgId('NormTooltip'));
            app.NormSpinner.Limits = [1 inf];
            app.NormSpinner.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.CenterDropDown.Items = [getMsgText(app,getMsgId('Mean')),getMsgText(app,getMsgId('Median')),...
                getMsgText(app,getMsgId('Numeric')),getMsgText(app,getMsgId('FromWorkspace'))];
            app.CenterDropDown.ItemsData = {'mean','median','numeric','workspace'};
            app.CenterDropDown.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.CenterWorkspaceDropDown.FilterVariablesFcn = @app.filterCenterOrScale;
            app.CenterWorkspaceDropDown.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.ScaleDropDown.Items = [getMsgText(app,getMsgId('STD')),getMsgText(app,getMsgId('MAD')),...
                getMsgText(app,getMsgId('First')),getMsgText(app,getMsgId('IQR')),...
                getMsgText(app,getMsgId('Numeric')),getMsgText(app,getMsgId('FromWorkspace'))];
            app.ScaleDropDown.ItemsData = {'std','mad','first','iqr','numeric','workspace'};
            app.ScaleDropDown.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.ScaleWorkspaceDropDown.FilterVariablesFcn = @app.filterCenterOrScale;
            app.ScaleWorkspaceDropDown.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            for sp = {'RangeSpinner1' 'RangeSpinner2' 'CenterSpinner' 'ScaleSpinner'}
                app.(sp{1}).LowerLimitInclusive = false;
                app.(sp{1}).UpperLimitInclusive = false;
                app.(sp{1}).ValueChangedFcn = @app.doUpdateFromWidgetChange;
            end
            app.RangeSpinner1.Tag = 'RangeSpinner1';
            app.RangeSpinner1.Tooltip = getMsgText(app,getMsgId('RangeLeft'));
            app.RangeSpinner2.Tooltip = getMsgText(app,getMsgId('RangeRight'));
            app.CenterSpinner.Tooltip = getMsgText(app,getMsgId('CenterShift'));
            app.OutputCheckBox.Text = getMsgText(app,getMsgId('OutputCenterAndScale'));
            app.OutputCheckBox.Tooltip = getMsgText(app,getMsgId('OutputCenterAndScaleTooltip'));
            app.OutputCheckBox.ValueChangedFcn = @app.doUpdateFromWidgetChange;
        end
        
        function createPlotWidgetsRow(app,h)
            % Layout
            app.PlotInputDataCheckBox = uicheckbox(h);
            app.PlotInputDataCheckBox.Layout.Row = 2;
            app.PlotInputDataCheckBox.Layout.Column = 1;
            app.PlotNormalizedDataCheckBox = uicheckbox(h);
            app.TiledLayoutCheckBox = uicheckbox(h);
            
            % Properties
            app.PlotNormalizedDataCheckBox.Text = getMsgText(app,getMsgId('NormalizedData'));
            app.PlotNormalizedDataCheckBox.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.PlotInputDataCheckBox.Text = getMsgText(app,'InputData');
            app.PlotInputDataCheckBox.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.TiledLayoutCheckBox.Text = getMsgText(app,getMsgId('TiledLayout'));
            app.TiledLayoutCheckBox.Tooltip = getMsgText(app,getMsgId('TiledLayoutTooltip'));
            app.TiledLayoutCheckBox.ValueChangedFcn = @app.doUpdateFromWidgetChange;
        end

        function updateDefaultsFromKeyword(app,kw)
            % all keywords that are relevant to changing behavior away from
            % default
            keywords = ["range" "medianiqr" "center" "scale" "rescale"];

            % finds first element that the input kw is a prefix for, if any
            kwMatches = startsWith(keywords,kw,'IgnoreCase',true);
            firstMatchIdx = find(kwMatches,1);

            % if not, we don't update anything
            if isempty(firstMatchIdx)
                return;
            end

            % get the corresponding full keyword
            fullKeyword = keywords(firstMatchIdx);

            % the only keyword that doesn't match its corresponding method
            if isequal(fullKeyword,"rescale")
                fullKeyword = "scale";
            end

            app.DefaultMethod = fullKeyword;
            app.MethodDropDown.Value = fullKeyword;
            doUpdate(app);
        end
                
        function setWidgetsToDefault(app,fromResetMethod)
            app.MethodDropDown.Value = app.DefaultMethod;
            app.ZscoreDropDown.Value = 'std';
            app.NormSpinner.Value = 2;
            app.ScaleDropDown.Value = 'std';
            app.ScaleSpinner.Value = 1; % no function default
            app.ScaleWorkspaceDropDown.Value = app.SelectVariable;
            app.RangeSpinner1.Value = 0;
            app.RangeSpinner2.Value = 1;
            app.CenterDropDown.Value = 'mean';
            app.CenterSpinner.Value = 0; % no function default
            app.CenterWorkspaceDropDown.Value = app.SelectVariable;
            
            fromResetMethod = (nargin > 1) && fromResetMethod; % Called from reset()
            if ~fromResetMethod
                % reset() does not reset the input data, therefore, it does
                % not change wether the app supports visualization or not.
                app.SupportsVisualization = true;
            end
            app.OutputCheckBox.Value = false;
            app.PlotNormalizedDataCheckBox.Value = true;
            app.PlotInputDataCheckBox.Value = true;
            app.TiledLayoutCheckBox.Value = ~isAppWorkflow(app);
        end
        
        function changedWidget(app,context,~)
            % Keep range spinners with a < b
            if app.RangeSpinner1.Value >= app.RangeSpinner2.Value
                if isequal(context.Tag,'RangeSpinner1')
                    app.RangeSpinner2.Value = app.RangeSpinner1.Value + 1;
                else
                    app.RangeSpinner1.Value = app.RangeSpinner2.Value - 1;
                end
            end
            % repopulate wsdds on any click in case the variable has been
            % cleared from the workspace or the input has been changed and
            % the variable is no longer valid
            app.CenterWorkspaceDropDown.populateVariables();
            app.ScaleWorkspaceDropDown.populateVariables();
        end
        
        function updateWidgets(app,~)
            % Update the layout and visibility of the widgets
            
            updateInputDataAndSamplePointsDropDown(app);
            % hide sample points, only used for plotting timetable data
            app.SamplePointsDropDown.Visible = 'off';
            app.SamplePointsTableVarDropDown.Visible = 'off';
            app.SamplePointsDropDown.Parent.RowHeight{4} = 0;
            
            hasData = hasInputDataAndSamplePoints(app);
            
            % Enable and Visible
            app.MethodDropDown.Enable = hasData;
            app.ZscoreDropDown.Visible = isequal(app.MethodDropDown.Value,'zscore');
            app.ZscoreDropDown.Enable = hasData;
            app.NormSpinner.Visible = isequal(app.MethodDropDown.Value,'norm');
            app.NormSpinner.Enable = hasData;
            app.RangeSpinner1.Visible = isequal(app.MethodDropDown.Value,'range');
            app.RangeSpinner1.Enable = hasData;
            app.RangeSpinner2.Visible = isequal(app.MethodDropDown.Value,'range');
            app.RangeSpinner2.Enable = hasData;
            doCenterAndScale = isequal(app.MethodDropDown.Value,'centerAndScale');
            doCenter = doCenterAndScale || isequal(app.MethodDropDown.Value,'center');
            app.CenterDropDown.Visible = doCenter;
            app.CenterDropDown.Enable = hasData;
            app.CenterSpinner.Visible = doCenter && isequal(app.CenterDropDown.Value,'numeric');
            app.CenterSpinner.Enable = hasData;
            app.CenterWorkspaceDropDown.Visible = doCenter && isequal(app.CenterDropDown.Value,'workspace');
            app.CenterWorkspaceDropDown.Enable = hasData;
            app.CenterLabel.Visible = doCenterAndScale;
            doScale = doCenterAndScale || isequal(app.MethodDropDown.Value,'scale');
            app.ScaleDropDown.Visible = doScale;
            app.ScaleDropDown.Enable = hasData;
            app.ScaleSpinner.Visible = doScale && isequal(app.ScaleDropDown.Value,'numeric');
            app.ScaleSpinner.Enable = hasData;
            app.ScaleWorkspaceDropDown.Visible = doScale && isequal(app.ScaleDropDown.Value,'workspace');
            app.ScaleWorkspaceDropDown.Enable = hasData;
            app.ScaleLabel.Visible = doCenterAndScale;
            app.OutputCheckBox.Enable = hasData;
            widgets = [app.ZscoreDropDown app.NormSpinner app.RangeSpinner1 ...
                app.RangeSpinner2 app.CenterDropDown app.CenterSpinner ...
                app.CenterWorkspaceDropDown app.ScaleDropDown app.ScaleSpinner ...
                app.ScaleWorkspaceDropDown app.CenterLabel app.ScaleLabel];
            matlab.internal.dataui.setParentForWidgets(widgets,app.MethodDropDown.Parent);
            
            % Layout
            scaleRow = 1 + doCenterAndScale;
            app.ScaleDropDown.Layout.Row = scaleRow;
            app.ScaleSpinner.Layout.Row = scaleRow;
            app.ScaleWorkspaceDropDown.Layout.Row = scaleRow;
            app.CenterDropDown.Layout.Column = 3 + doCenterAndScale;
            app.CenterSpinner.Layout.Column = 4 + doCenterAndScale;
            app.CenterWorkspaceDropDown.Layout.Column = 4 + doCenterAndScale;
            app.ScaleDropDown.Layout.Column = 3 + doCenterAndScale;
            app.ScaleSpinner.Layout.Column = 4 + doCenterAndScale;
            app.ScaleWorkspaceDropDown.Layout.Column = 4 + doCenterAndScale;
            
            % Tooltips
            app.MethodDropDown.Tooltip = getMsgText(app,getMsgId(['MethodTooltip' app.MethodDropDown.Value]));
            app.ZscoreDropDown.Tooltip = getMsgText(app,getMsgId(['ZscoreTooltip' app.ZscoreDropDown.Value]));
            app.CenterDropDown.Tooltip = getMsgText(app,getMsgId(['CenterTooltip' app.CenterDropDown.Value]));
            app.ScaleDropDown.Tooltip = getMsgText(app,getMsgId(['ScaleTooltip' app.ScaleDropDown.Value]));
            if app.InputDataHasTableVars
                wsTT = getMsgText(app,getMsgId('WorkspaceDDTooltipT'));
            else
                wsTT = getMsgText(app,getMsgId('WorkspaceDDTooltipA'));
            end
            app.CenterWorkspaceDropDown.Tooltip = wsTT;
            app.ScaleWorkspaceDropDown.Tooltip = wsTT;
            
            % Checkboxes
            enableCheckboxes = hasData && ~isWaitingOnCenterOrScale(app);
            app.PlotNormalizedDataCheckBox.Enable = enableCheckboxes;
            app.PlotInputDataCheckBox.Enable = enableCheckboxes;
            app.TiledLayoutCheckBox.Enable = enableCheckboxes;
            showCB = showPlotCheckboxes(app,app.PlotNormalizedDataCheckBox,...
                app.PlotInputDataCheckBox);
            app.TiledLayoutCheckBox.Visible = showCB && ...
                app.PlotNormalizedDataCheckBox.Value && app.PlotInputDataCheckBox.Value;
            matlab.internal.dataui.setParentForWidgets(app.TiledLayoutCheckBox,...
                app.PlotNormalizedDataCheckBox.Parent);
        end
        
        function tf = filterInputData(~,A,isTableVar)
            % Keep only Input Data of supported type
            if isa(A,'tabular') % table or timetable
                tf = ~isTableVar; % No tables within tables
            else
                % strictest input for normalize with the non-empty addition
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
                % sample points only used for x-axis in visualization
                tf = isvector(X) && ((isfloat(X) && isreal(X)) || ...
                    isduration(X) || isdatetime(X));
            end
        end
        
        function tf = filterCenterOrScale(app,CS)
            % first, check to see if input/sample points are still in the workspace
            if isempty(app.InputDataDropDown.WorkspaceValue) && ~strcmp(app.InputDataDropDown.Value,app.SelectVariable)
                % input data is no longer in the workspace
                % return false for everything in ws
                tf = false;
                return
            end
            
            tf = (isnumeric(CS) || islogical(CS)) || ...
                (isa(CS,'tabular') && app.InputDataHasTableVars);
            
            if tf && isa(CS,'tabular')
                tf = height(CS) == 1;
                if tf
                    % table must contain selected variables
                    % note - this varies from underlying function in which
                    % you can use c/s to select datavars
                    if isequal(app.DataVarSelectionTypeDropDown.Value,'manual')
                        varNames = getVariablesFromManualSelection(app);
                    else
                        varNames = getAllSupportedVariables(app);
                        % note 'numeric' option is not hittable by this
                        % task since only numeric variables are supported
                    end
                    tf = all(ismember(varNames,CS.Properties.VariableNames));
                end
            end
        end
        
        function tf = isWaitingOnCenterOrScale(app)
            doScale = ismember(app.MethodDropDown.Value,{'scale' 'centerAndScale'});
            doCenter = ismember(app.MethodDropDown.Value,{'center' 'centerAndScale'});
            tf = (doScale && isequal(app.ScaleDropDown.Value,'workspace') && ...
                isequal(app.ScaleWorkspaceDropDown.Value,app.SelectVariable)) || ...
                (doCenter && isequal(app.CenterDropDown.Value,'workspace') && ...
                isequal(app.CenterWorkspaceDropDown.Value,app.SelectVariable));
        end
                
        function propTable = getLocalPropertyInformation(app)
            Name = ["MethodDropDown" "ZscoreDropDown" "NormSpinner" ...
                "RangeSpinner1" "RangeSpinner2" "CenterDropDown" ...
                "CenterSpinner" "ScaleDropDown" "ScaleSpinner"]';
            Group = repmat(getMsgText(app,'MethodAndParametersDelimiter'),9,1);
            DisplayName = [getMsgText(app,getMsgId('Method')),getMsgText(app,getMsgId('ZscoreType')),getMsgText(app,getMsgId('PNorm')),...
                getMsgText(app,getMsgId('RangeLeft')),getMsgText(app,getMsgId('RangeRight')),...
                getMsgText(app,getMsgId('CenterType')),getMsgText(app,getMsgId('CenterShift')),...
                getMsgText(app,getMsgId('ScaleType')),getMsgText(app,getMsgId('ScaleFactor'))]';
            StateName = Name + "Value";
            
            propTable = table(Name,Group,DisplayName,StateName);
            propTable = addFieldsToPropTable(app,propTable);
            % remove "from workspace" options in Center & Scale DDs
            propTable.Items{6} = app.CenterDropDown.Items(1:end-1);
            propTable.ItemsData{6} = app.CenterDropDown.ItemsData(1:end-1);
            propTable.Items{8} = app.ScaleDropDown.Items(1:end-1);
            propTable.ItemsData{8} = app.ScaleDropDown.ItemsData(1:end-1);
        end
        
        function code = addCenterOrScaleMethodType(app,code,cs,defaultVal)
            methodType = app.([cs 'DropDown']).Value;
            if isequal(methodType,'numeric')
                code = matlab.internal.dataui.addCharToCode(code,[',' num2str(app.([cs 'Spinner']).Value,'%.16g')]);
            elseif isequal(methodType,'workspace')
                if isAppWorkflow(app)
                    % app doesn't need ticks
                    code = matlab.internal.dataui.addCharToCode(code,[',' app.([cs 'WorkspaceDropDown']).Value]);
                else
                    % live editor requires ticks
                    code = matlab.internal.dataui.addCharToCode(code,[',`' app.([cs 'WorkspaceDropDown']).Value '`']);
                end                
            elseif ~isequal(methodType,defaultVal)
                code = matlab.internal.dataui.addCharToCode(code,[',"' methodType '"']);
            end
        end
    end

    % required for embedding in a Live Script
    methods (Access = public)
        function [code,outputs] = generateScript(app,isForExport,overwriteInput)
            if nargin < 2
                % Second input is for "cleaned up" export code. E.g., don't
                % introduce temp vars for plotting.
                % No difference for this task.
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
            if ~hasInputDataAndSamplePoints(app) || isWaitingOnCenterOrScale(app)
                return
            end
            
            code = ['% ' char(getMsgText(app,'Tool_NormalizeDataTask_Label'))];
            if overwriteInput
                outputs = {app.getInputDataVarNameForGeneratedScript};
            elseif app.outputIsTable
                outputs = {app.OutputForTable};
            else
                outputs = {app.OutputForMatrix};
            end
            
            if app.OutputCheckBox.Value
                outputs = [outputs app.AdditionalOutputs];
                code = [code newline '[' outputs{1} ',' outputs{2} ',' outputs{3} '] = '];
            else
                code = [code newline outputs{1} ' = '];
            end
            
            code = matlab.internal.dataui.addCharToCode(code,['normalize(' getInputDataVarNameForGeneratedScript(app)]);
            code = [code getSmallTableCode(app)];
            
            % method
            if isequal(app.MethodDropDown.Value,'centerAndScale')
                % do center first
                code = matlab.internal.dataui.addCharToCode(code,',"center"');
            elseif ~isequal(app.MethodDropDown.Value,'zscore') || ~isequal(app.ZscoreDropDown.Value,'std')
                % add code, else is default so no code needed
                code = matlab.internal.dataui.addCharToCode(code,[',"' app.MethodDropDown.Value '"']);
            end
            
            % methodtype
            switch app.MethodDropDown.Value
                case 'zscore'
                    if isequal(app.ZscoreDropDown.Value,'robust')
                        % else default
                        code = matlab.internal.dataui.addCharToCode(code,',"robust"');
                    end
                case 'norm'
                    if app.NormSpinner.Value ~= 2
                        code = matlab.internal.dataui.addCharToCode(code,[',' num2str(app.NormSpinner.Value)]);
                    end
                case 'scale'
                    code = addCenterOrScaleMethodType(app,code,'Scale','std');
                case 'range'
                    if ~all([app.RangeSpinner1.Value app.RangeSpinner2.Value] == [0 1])
                        code = matlab.internal.dataui.addCharToCode(code,[',[' num2str(app.RangeSpinner1.Value,'%.16g') ',' ...
                            num2str(app.RangeSpinner2.Value,'%.16g') ']']);
                    end
                case 'center'
                    code = addCenterOrScaleMethodType(app,code,'Center','mean');
                case 'centerAndScale'
                    code = addCenterOrScaleMethodType(app,code,'Center','mean');
                    code = matlab.internal.dataui.addCharToCode(code,',"scale"');
                    code = addCenterOrScaleMethodType(app,code,'Scale','std');
                % otherwise medianIQR, no methodtype
            end
            
            code = matlab.internal.dataui.addCharToCode(code,getDataVariablesNameValuePair(app));
            code = matlab.internal.dataui.addCharToCode(code,getReplaceValuesNameValuePair(app));
            code = [code ');'];
        end
        
        function code = generateVisualizationScript(app)
            code = '';
            numPlots = sum([app.PlotInputDataCheckBox.Value app.PlotNormalizedDataCheckBox.Value]);
            if ~hasInputDataAndSamplePoints(app) || ~app.SupportsVisualization ...
                    || isWaitingOnCenterOrScale(app) || numPlots == 0
                return;
            end
            resetVariablesToBeCleared(app);

            code = addVisualizeResultsLine(app);
            x = getSamplePointsVarNameForGeneratedScript(app);
            plotMultipleVars = isnumeric(app.TableVarPlotDropDown.Value);
            doSideBySidePlots = app.TiledLayoutCheckBox.Visible && app.TiledLayoutCheckBox.Value;

            if plotMultipleVars
                needOutLoc = ~isequal(app.OutputTypeDropDown.Value,'replace') && app.PlotNormalizedDataCheckBox.Value;
                [code,inIndex,outIndex] = generateScriptSetupTiledLayout(app,code,needOutLoc,doSideBySidePlots);
                y1 = [getInputDataVarNameForGeneratedScript(app) '.(' inIndex ')'];
                if isequal(app.OutputTypeDropDown.Value,'append')
                    outIndex = [outIndex '+' num2str(app.InputSize(2))];
                end
                y2 = [app.OutputForTable '.(' outIndex ')'];
                tab = '    ';
            else
                y1 = addDotIndexingToTableName(app,getInputDataVarNameForGeneratedScript(app));
                if app.outputIsTable
                    if isequal(app.OutputTypeDropDown.Value,'append')
                        y2= addIndexingIntoAppendedVar(app,app.OutputForTable);
                    else
                        y2 = addDotIndexingToTableName(app,app.OutputForTable);
                    end
                else
                    y2 = app.OutputForMatrix;
                end
                tab = '';
            end            
            
            if doSideBySidePlots
                % Plot input on first tile, then output on second tile
                if ~plotMultipleVars                
                    code = [code newline 'tiledlayout(2,1);' newline 'nexttile'];
                end
                code = generateScriptPlotInputData(app,code,x,y1,tab);
                code = addLegendAndAxesLabels(app,code,tab,true,plotMultipleVars);
                if plotMultipleVars
                    code = [code newline tab 'if k == 1'];
                    code = [code newline tab tab 'title("' char(getMsgText(app,'InputData')) '")'];
                    code = [code newline tab 'end'];
                end
                code = [code newline newline tab 'nexttile'];
                code = generateScriptPlotCleanedData(app,code,x,y2,tab,char(getMsgText(app,getMsgId('NormalizedData'))));
                code = addLegendAndAxesLabels(app,code,tab,true,plotMultipleVars);
                if plotMultipleVars
                    code = [code newline tab 'if k == 1'];
                    code = [code newline tab tab 'title("' char(getMsgText(app,getMsgId('NormalizedData'))) '")'];
                    code = [code newline tab 'end'];
                end
                if ~plotMultipleVars
                    % Add so next plot in live editor is not in tiledlayout: g2403932
                    code = [code newline 'set(gcf,NextPlot="new")'];
                end
            else
                % plot input and output on same axes
                didHoldOn = false;
                if app.PlotInputDataCheckBox.Value
                    code = generateScriptPlotInputData(app,code,x,y1,tab);
                    [code,didHoldOn] = addHold(app,code,'on',didHoldOn,numPlots,tab);
                end
                if app.PlotNormalizedDataCheckBox.Value
                    code = generateScriptPlotCleanedData(app,code,x,y2,tab,char(getMsgText(app,getMsgId('NormalizedData'))));
                end
                code = addHold(app,code,'off',didHoldOn,numPlots,tab);
                code = addLegendAndAxesLabels(app,code,tab);
            end

            if plotMultipleVars
                code = generateScriptEndTiledLayout(app,code);
                code = addClear(app,code);
            end
        end
        
        function setTaskState(app,state,updatedWidget)
            % With nargin == 2, setState is used by live editor and App for
            % save/load/undo/redo
            % With nargin == 3, setState is used by the App to change the
            % value of a control from the property inspector
            if nargin < 3
                updatedWidget = '';
            end
            
            if app.Version < state.MinCompatibleVersion
                % state comes from a future, incompatible version
                % do not set any properties
                doUpdate(app,false);
            else
                setInputDataAndSamplePointsDropDownValues(app,state);
                setValueOfComponents(app,["MethodDropDown" "ZscoreDropDown"...
                    "NormSpinner" "CenterWorkspaceDropDown" "ScaleWorkspaceDropDown"...
                    "ScaleDropDown" "ScaleSpinner" "RangeSpinner1"...
                    "RangeSpinner2" "CenterDropDown" "CenterSpinner" ...
                    "OutputCheckBox" "PlotNormalizedDataCheckBox"...
                    "PlotInputDataCheckBox" "TiledLayoutCheckBox"],state);
                if isfield(state, "DefaultMethod")
                    app.DefaultMethod = state.DefaultMethod;
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
    
    % get/set methods for public properties
    methods
        function summary = get.Summary(app)
            summary = getMsgText(app,'Tool_NormalizeDataTask_Description');
            if ~hasInputDataAndSamplePoints(app) || isWaitingOnCenterOrScale(app)
                % return with the purpose line
                return;
            end
            varName = getInputDataVarNameForSummary(app);
            
            if isequal(app.MethodDropDown.Value,'range')
                % quick return for the easiest case
                newrange = mat2str([app.RangeSpinner1.Value,app.RangeSpinner2.Value]);
                summary = getMsgText(app,getMsgId('SummaryRange'),varName,newrange);
                return
            end
            
            scalefactor = [];
            centerval = [];
            if isequal(app.MethodDropDown.Value,'zscore')
                if isequal(app.ZscoreDropDown.Value,'std')
                    centerval = lower(getMsgText(app,getMsgId('Mean')));
                    scalefactor = lower(getMsgText(app,getMsgId('STD')));
                else
                    centerval = lower(getMsgText(app,getMsgId('Median')));
                    scalefactor = lower(getMsgText(app,getMsgId('MAD')));
                end
                summaryType = 'CenterAndScale3';
            elseif isequal(app.MethodDropDown.Value,'norm')
                n = app.NormSpinner.Value;
                if isfinite(n)
                    scalefactor = getMsgText(app,getMsgId('pNorm'),num2str(n));
                else
                    scalefactor = getMsgText(app,getMsgId('InfinityNorm'));
                end
                summaryType = 'Scale';
            elseif isequal(app.MethodDropDown.Value,'medianiqr')
                centerval = lower(getMsgText(app,getMsgId('Median')));
                scalefactor = lower(getMsgText(app,getMsgId('IQR')));
                summaryType = 'CenterAndScale3';
            else % center and/or scale
                centerType = '';
                if ismember(app.MethodDropDown.Value,{'scale','centerAndScale'})
                    scaleval = app.ScaleDropDown.Value;
                    if isequal(scaleval,'numeric')
                        scalefactor = num2str(app.ScaleSpinner.Value);
                    elseif isequal(scaleval,'workspace')
                        scalefactor = ['`' app.ScaleWorkspaceDropDown.Value '`'];
                    else
                        % std, mad, first, or iqr, grab message from dd
                        scalefactor = lower(app.ScaleDropDown.Items{ismember(app.ScaleDropDown.ItemsData,scaleval)});
                    end
                end
                if ismember(app.MethodDropDown.Value,{'center','centerAndScale'})
                    center = app.CenterDropDown.Value;
                    centerType = '2';
                    if isequal(center,'numeric')
                        centerval = num2str(app.CenterSpinner.Value);
                    elseif isequal(center,'workspace')
                        centerval = ['`' app.CenterWorkspaceDropDown.Value '`'];
                    else
                        % mean or median, grab message from dd
                        centerval = lower(app.CenterDropDown.Items{ismember(app.CenterDropDown.ItemsData,center)});
                        centerType = '1';
                    end
                end
                if isequal(app.MethodDropDown.Value,'centerAndScale')
                    summaryType = ['CenterAndScale' centerType];
                elseif isequal(app.MethodDropDown.Value,'center')
                    summaryType = ['Center' centerType];
                else
                    summaryType = 'Scale';
                end
            end
            
            if isempty(scalefactor)
                summary = getMsgText(app,getMsgId(['Summary' summaryType]),varName,centerval);
            elseif isempty(centerval)
                summary = getMsgText(app,getMsgId(['Summary' summaryType]),varName,scalefactor);
            else
                summary = getMsgText(app,getMsgId(['Summary' summaryType]),varName,centerval,scalefactor);
            end
        end
        
        function state = get.State(app)
            state = struct();
            state.VersionSavedFrom = app.Version;
            state.MinCompatibleVersion = 1;
            
            state = getInputDataAndSamplePointsDropDownValues(app,state);
            for k = {'MethodDropDown' 'ZscoreDropDown' 'NormSpinner' ...
                    'ScaleDropDown' 'ScaleSpinner' 'RangeSpinner1' ...
                    'RangeSpinner2' 'CenterDropDown' 'CenterSpinner' ...
                    'CenterWorkspaceDropDown' 'ScaleWorkspaceDropDown' ...
                    'OutputCheckBox' 'PlotNormalizedDataCheckBox' ...
                    'PlotInputDataCheckBox' 'TiledLayoutCheckBox'}
                state.([k{1} 'Value']) = app.(k{1}).Value;
            end

            state.DefaultMethod = app.DefaultMethod;
        end

        function set.State(app,state)
            setTaskState(app,state);
        end
        
        function set.Workspace(app,ws)
            app.Workspace = ws;
            app.InputDataDropDown.Workspace = ws;
            app.SamplePointsDropDown.Workspace = ws;
            app.CenterWorkspaceDropDown.Workspace = ws; %#ok<MCSUP> 
            app.ScaleWorkspaceDropDown.Workspace = ws; %#ok<MCSUP>
            if ~isequal(ws,'base')
                % Workspace is set after setting widgets to default in
                % construction. In app workflow, need to reset this default
                app.TiledLayoutCheckBox.Value = false; %#ok<MCSUP> 
            end
        end
    end
end

function msgId = getMsgId(id)
msgId = ['Normalize' id];
end
