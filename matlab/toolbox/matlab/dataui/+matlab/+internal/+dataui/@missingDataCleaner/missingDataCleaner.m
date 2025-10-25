classdef (Hidden = true, Sealed = true) missingDataCleaner < ...
        matlab.internal.dataui.DataPreprocessingTask & ...
        matlab.internal.dataui.movwindowWidgets
    % missingDataCleaner Find, fill, or remove missing data in a Live Script
    %
    %   H = missingDataCleaner constructs a Live Script tool for finding,
    %   filling, or removing missing data and visualizing the results.
    %
    %   See also ISMISSING, FILLMISSING, RMMISSING
    
    %   Copyright 2018-2024 The MathWorks, Inc.
    
    properties (Access = public, Transient, Hidden)
        % Function parameters
        StandardizeDropDown                 matlab.ui.control.DropDown
        IndicatorEditField                  matlab.ui.control.EditField
        CleanMethodDropDown                 matlab.ui.control.DropDown
        FillMethodDropDown                  matlab.ui.control.DropDown
        FillConstantSpinner                 matlab.ui.control.Spinner
        FillConstantUnitsDropDown           matlab.ui.control.DropDown % only used for duration/calendarDuration data
        CustomFillMethodSelector            matlab.internal.dataui.FunctionSelector
        EndValueLabel                       matlab.ui.control.Label
        EndValueDropDown                    matlab.ui.control.DropDown
        EndValueConstantSpinner             matlab.ui.control.Spinner
        EndValueConstantUnitsDropDown       matlab.ui.control.DropDown
        KnnKLabel                           matlab.ui.control.Label
        KnnKSpinner                         matlab.ui.control.Spinner
        KnnDistanceDropDown                 matlab.ui.control.DropDown
        CustomKnnDistanceSelector           matlab.internal.dataui.FunctionSelector
        MaxGapLabel                         matlab.ui.control.Label
        MaxGapSpinner                       matlab.ui.control.Spinner
        MaxGapUnitsDropDown                 matlab.ui.control.DropDown
        MinNumMissingLabel                  matlab.ui.control.Label
        MinNumMissingSpinner                matlab.ui.control.Spinner
        % Plot parameters
        PlotDataCheckBox                    matlab.ui.control.CheckBox
        PlotMissingDataCheckBox             matlab.ui.control.CheckBox
        PlotOtherRemovedCheckBox            matlab.ui.control.CheckBox
        % helper parameter
        AverageableData                     = true;
        DefaultCleanMethod                  = "fill"; % changes on initialization if keyword indicates none or remove
        NonstandardByDefault                = false; % only updated if user types standardizeMissing as keyword
        SelectedVarType                     = 'numeric'; % used in plot code
        SelectedVarNumUnique                = NaN; % used in plot code, only calculated for string-based data  
    end
    
    properties (Constant, Transient, Hidden)
        % Constants
        OutputIndices   = 'missingIndices';
        OutputVector    = 'cleanedData';
        OutputTable     = 'newTable';
        TempPlotIndices = 'indicesForPlot';
        % Serialization Versions - used for managing forward compatibility
        %   N/A: original ship                     (R2019b)
        %     2: Add MaxGap and versioning         (R2020b)
        %     3: Multi table vars and table output (R2021a)
        %     4: StandardizeMissing                (R2021b)
        %     5: Use Base Class                    (R2022a)
        %     6: MinNumMissing, Fcn Handle input, Append table vars,
        %        Non-numeric plots, Tiled layout   (R2022b)
        %     7: KNN fill method                   (R2023b)
        %     8: Add clean method/standardizeMissing initialization by 
        %        keyword                           (R2024a)
        Version = 8;
    end

    properties
        Workspace = "base";
        State
        Summary
    end
    
    methods (Access = protected)
        function createWidgets(app)
            createInputDataSection(app);
            createStandardizeSection(app);
            createMethodSection(app);
            createPlotSection(app,3);
        end

        function adj = getAdjectiveForOutputDropDown(~)
            adj = 'Cleaned';
        end
        
        function createStandardizeSection(app)
            h = createNewSection(app,getMsgText(app,getMsgId(app,'StandardizeDelimiter')),{'fit' 'fit' 'fit'},1);
            
            uilabel(h,'Text',getMsgText(app,getMsgId(app,'StandardizeMethod')));
            
            app.StandardizeDropDown = uidropdown(h);
            app.StandardizeDropDown.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.StandardizeDropDown.Items = [getMsgText(app,getMsgId(app,'StandardOnly')), getMsgText(app,getMsgId(app,'NonStandard'))];
            app.StandardizeDropDown.ItemsData = {'standard','nonstandard'};
            app.StandardizeDropDown.Tooltip = getMsgText(app,getMsgId(app,'StandardizeTooltip1'));
            
            app.IndicatorEditField = uieditfield(h);
            app.IndicatorEditField.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.IndicatorEditField.Tooltip = getMsgText(app,getMsgId(app,'StandardizeTooltip2'));
            app.IndicatorEditField.Tag = 'IndicatorEditField';
            
            % startup task with this section collapsed
            h.Parent.Collapsed = true;
        end
        
        function createMethodSection(app)
            h = createNewSection(app,getMsgText(app,'MethodDelimiter'),...
                {'fit' 'fit' 'fit' 'fit' 'fit' 'fit' 'fit' 'fit' 'fit' 'fit'},4);
            
            % Layout - Row 1 - Clean Method Row
            uilabel(h,'Text',getMsgText(app,'CleaningMethod'));
            app.CleanMethodDropDown = uidropdown(h);
            app.FillMethodDropDown = uidropdown(h);
            app.FillMethodDropDown.Layout.Column = [3 4];
            app.FillConstantSpinner = uispinner(h);
            app.FillConstantUnitsDropDown = uidropdown(h);
            app.EndValueLabel = uilabel(h,'Text',getMsgText(app,getMsgId(app,'EndValues')));
            app.EndValueDropDown = uidropdown(h);
            app.EndValueConstantSpinner = uispinner(h);
            app.EndValueConstantUnitsDropDown = uidropdown(h);
            app.CustomFillMethodSelector = matlab.internal.dataui.FunctionSelector(h);
            app.CustomFillMethodSelector.Layout.Row = 1;
            app.CustomFillMethodSelector.Layout.Column = 5;
            app.MinNumMissingLabel = uilabel(h,'Text',getMsgText(app,getMsgId(app,'MinNumMissing')));
            app.MinNumMissingLabel.Layout.Row = 1;
            app.MinNumMissingLabel.Layout.Column = 3;
            app.MinNumMissingSpinner = uispinner(h);
            app.MinNumMissingSpinner.Layout.Row = 1;
            app.MinNumMissingSpinner.Layout.Column = 4;
            
            % Layout - Row 2 - Window Row
            createWindowWidgets(app,h,2,1,@app.doUpdateFromWidgetChange,getMsgText(app,'Movingwindow'),[])

            % Layout - Row 3 - Knn Controls Row
            app.KnnKLabel = uilabel(h,'Text',getMsgText(app,getMsgId(app,'KnnK')));
            app.KnnKLabel.Layout.Row = 3;
            app.KnnKLabel.Layout.Column = 1;
            app.KnnKSpinner = uispinner(h);
            app.KnnDistanceDropDown = uidropdown(h);
            app.KnnDistanceDropDown.Layout.Column = [3 4];
            app.CustomKnnDistanceSelector = matlab.internal.dataui.FunctionSelector(h);
            
            % Layout - Row 4 - MaxGap Row
            app.MaxGapLabel = uilabel(h,'Text',getMsgText(app,getMsgId(app,'MaxGap')));
            app.MaxGapLabel.Layout.Row = 4;
            app.MaxGapLabel.Layout.Column = 1;
            app.MaxGapSpinner = uispinner(h);
            app.MaxGapUnitsDropDown = uidropdown(h);
            app.MaxGapUnitsDropDown.Layout.Column = [3 4];
        
            % Row 1 properties
            app.CleanMethodDropDown.Items = cellstr([getMsgText(app,getMsgId(app,'Fillmissing')) ...
                getMsgText(app,getMsgId(app,'Removemissing')) getMsgText(app,'None')]);
            app.CleanMethodDropDown.ItemsData = {'fill' 'remove' 'none'};
            app.CleanMethodDropDown.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.CleanMethodDropDown.Tag = 'CleanMethodDropDown';
            app.FillMethodDropDown.Items = cellstr([getMsgText(app,'Constantvalue') ...
                getMsgText(app,'Previousvalue') getMsgText(app,'Nextvalue') ...
                getMsgText(app,'Nearestvalue') getMsgText(app,'Linearinterpolation') ...
                getMsgText(app,'Splineinterpolation') getMsgText(app,'Pchip') ...
                getMsgText(app,'Makima') getMsgText(app,'Movingmedian') ...
                getMsgText(app,'Movingmean') getMsgText(app,getMsgId(app,'Knn')) ...
                getMsgText(app,getMsgId(app,'Custom'))]);
            app.FillMethodDropDown.ItemsData = {'constant' 'previous' 'next' ...
                'nearest' 'linear' 'spline' 'pchip' 'makima' 'movmedian' 'movmean' 'knn' 'custom'};
            app.FillMethodDropDown.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.FillMethodDropDown.Tag = 'FillMethodDropDown';
            app.FillConstantSpinner.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.FillConstantSpinner.Tag = 'FillConstantSpinner';
            app.FillConstantUnitsDropDown.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.FillConstantUnitsDropDown.Tooltip = getMsgText(app,getMsgId(app,'ConstantUnitsTooltip'));
            app.FillConstantUnitsDropDown.Items = cellstr([getMsgText(app,'Milliseconds') ...
                getMsgText(app,'Seconds') getMsgText(app,'Minutes') getMsgText(app,'Hours') ...
                getMsgText(app,'Days') getMsgText(app,'Years')]);
            app.FillConstantUnitsDropDown.ItemsData = {'milliseconds' 'seconds' 'minutes' 'hours' 'days' 'years'};
            app.EndValueDropDown.Items = cellstr([getMsgText(app,getMsgId(app,'Sameasfill')) ...
                getMsgText(app,'Previousvalue') getMsgText(app,'Nextvalue') ...
                getMsgText(app,'Nearestvalue') getMsgText(app,'None') ...
                getMsgText(app,'Constantvalue')]);
            app.EndValueDropDown.ItemsData = {'extrap' ...
                'previous' 'next' 'nearest' 'none' 'scalar'};
            app.EndValueDropDown.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.EndValueConstantSpinner.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.EndValueConstantSpinner.Tag = 'EndValueConstantSpinner';
            app.EndValueConstantUnitsDropDown.Tooltip = getMsgText(app,getMsgId(app,'EndValuesTooltip'));
            app.EndValueConstantUnitsDropDown.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.EndValueConstantUnitsDropDown.Items = cellstr([getMsgText(app,'Milliseconds') ...
                getMsgText(app,'Seconds') getMsgText(app,'Minutes') getMsgText(app,'Hours') ...
                getMsgText(app,'Days') getMsgText(app,'Years')]);
            app.EndValueConstantUnitsDropDown.ItemsData = {'milliseconds' 'seconds' 'minutes' 'hours' 'days' 'years'};
            app.CustomFillMethodSelector.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.CustomFillMethodSelector.Tooltip = getMsgText(app,getMsgId(app,'CustomMethodTooltip'));
            app.CustomFillMethodSelector.NewFcnName = 'quadraticFill';
            app.CustomFillMethodSelector.NewFcnText = [newline ...
                'function y = quadraticFill(xs,ts,tq)' newline ...
                '% quadraticFill: ' char(getMsgText(app,getMsgId(app,'NewFcnTxtComment1'))) newline ...
                '% ' char(getMsgText(app,getMsgId(app,'NewFcnTxtComment2'),'xs')) newline ...
                '% ' char(getMsgText(app,getMsgId(app,'NewFcnTxtComment3'),'ts')) newline ...
                '% ' char(getMsgText(app,getMsgId(app,'NewFcnTxtComment4'),'tq')) newline ...
                newline ...
                'if isnumeric(xs)' newline ...
                '    if isduration(ts) || isdatetime(ts)' newline ...
                '        % ' char(getMsgText(app,getMsgId(app,'NewFcnTxtComment5'))) newline ...
                '        ts = seconds(ts - mean(ts));' newline ...
                '        tq = seconds(tq - mean(ts));' newline ...
                '    end' newline ...
                '    % ' char(getMsgText(app,getMsgId(app,'NewFcnTxtComment6'))) newline ...
                '    p = polyfit(ts,xs,2);' newline...
                '    % ' char(getMsgText(app,getMsgId(app,'NewFcnTxtComment7'))) newline ...
                '    y = polyval(p,tq);' newline...
                'else' newline...
                '    % ' char(getMsgText(app,getMsgId(app,'NewFcnTxtComment8'))) newline ...
                '    y = xs(1);' newline....
                'end' newline ...
                'end' newline];
            app.MinNumMissingSpinner.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.MinNumMissingSpinner.Limits = [1 inf];
            app.MinNumMissingSpinner.RoundFractionalValues = true;
            app.MinNumMissingSpinner.Tooltip = getMsgText(app,getMsgId(app,'MinNumMissingTooltip'));
        
            % Row 3 Properties
            app.KnnKSpinner.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.KnnKSpinner.Limits = [1 inf];
            app.KnnKSpinner.RoundFractionalValues = true;
            app.KnnDistanceDropDown.Tooltip = getMsgText(app,getMsgId(app,'KnnDistanceTooltip'));
            app.KnnDistanceDropDown.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.CustomKnnDistanceSelector.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.CustomKnnDistanceSelector.NewFcnName = 'customDistance';
            app.CustomKnnDistanceSelector.NewFcnText = [newline ...
                'function d = customDistance(x,mask)' newline...
                '% ' char(getMsgText(app,getMsgId(app,'CustomDistanceCodeComment1'),'x')) newline ... % 
                '% ' char(getMsgText(app,getMsgId(app,'CustomDistanceCodeComment2'),'mask')) newline ... % 
                '% ' char(getMsgText(app,getMsgId(app,'CustomDistanceCodeComment3'),'d')) newline ... % 
                '% ' char(getMsgText(app,getMsgId(app,'CustomDistanceCodeComment4'))) newline ... %
                'if istabular(x)' newline ...
                '    % ' char(getMsgText(app,getMsgId(app,'CustomDistanceCodeComment5'))) newline ... % 
                '    x = table2array(x);' newline ...
                'end' newline ...
                '% ' char(getMsgText(app,getMsgId(app,'CustomDistanceCodeComment6'))) newline ... % 
                'missingLocationsToIgnore = mask(1,:);' newline ...
                'x = x(:,~missingLocationsToIgnore);' newline ...
                '% ' char(getMsgText(app,getMsgId(app,'CustomDistanceCodeComment7'))) newline ... % 
                'differenceBetweenPoints = diff(x);' newline ...
                'd = norm(differenceBetweenPoints,1);' newline ...
                'end' newline];
            % Row 4 Properties
            app.MaxGapSpinner.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.MaxGapSpinner.Limits = [0 inf];
            app.MaxGapSpinner.LowerLimitInclusive = false;
            app.MaxGapSpinner.Tag = 'MaxGapSpinner';
            app.MaxGapSpinner.Tooltip = getMsgText(app,getMsgId(app,'MaxGapTooltip'));
            app.MaxGapUnitsDropDown.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.MaxGapUnitsDropDown.Items = cellstr([getMsgText(app,'Milliseconds') ...
                getMsgText(app,'Seconds') getMsgText(app,'Minutes') getMsgText(app,'Hours') ...
                getMsgText(app,'Days') getMsgText(app,'Years')]);
            app.MaxGapUnitsDropDown.ItemsData = {'milliseconds' 'seconds' 'minutes' 'hours' 'days' 'years'};
            app.MaxGapUnitsDropDown.Tooltip = getMsgText(app,getMsgId(app,'MaxGapUnitsTooltip'));
        end
        
        function createPlotWidgetsRow(app,h)
            % Layout
            app.PlotDataCheckBox = uicheckbox(h);
            app.PlotDataCheckBox.Layout.Row = 2;
            app.PlotDataCheckBox.Layout.Column = 1;
            app.PlotMissingDataCheckBox = uicheckbox(h);
            app.PlotOtherRemovedCheckBox = uicheckbox(h);
            
            % Properties
            app.PlotDataCheckBox.Text = getMsgText(app,'CleanedData');
            app.PlotDataCheckBox.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.PlotMissingDataCheckBox.Text = getMsgText(app,getMsgId(app,'MissingEntries'));
            app.PlotMissingDataCheckBox.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.PlotOtherRemovedCheckBox.Text = getMsgText(app,'OtherRemovedData');
            app.PlotOtherRemovedCheckBox.ValueChangedFcn = @app.doUpdateFromWidgetChange;
            app.PlotOtherRemovedCheckBox.Tooltip = getMsgText(app,getMsgId(app,'OtherRemovedTooltip'));
        end

        function updateDefaultsFromKeyword(app,kw)
            % all keywords that are relevant to changing behavior away from
            % default
            keywords = ["ismissing" "remove" "rmmissing" "standardizeMissing"];

            % finds first element that the input kw is a prefix for, if any
            kwMatches = startsWith(keywords,kw,'IgnoreCase',true);
            firstMatchIdx = find(kwMatches,1);

            % if not, we don't update anything
            if isempty(firstMatchIdx)
                return;
            end

            % get the corresponding full keyword
            fullKeyword = keywords(firstMatchIdx);

            % for this keyword, we update something other than the 
            % default clean method
            if isequal(fullKeyword,"standardizeMissing")
                app.Accordion.Children(2).Collapsed = false;
                app.NonstandardByDefault = true;
                app.StandardizeDropDown.Value = "nonstandard";
                doUpdate(app);
                return;
            % for these keywords, we need to map them to the corresponding
            % dropdown value
            elseif isequal(fullKeyword,"rmmissing")
                fullKeyword = "remove";
            elseif isequal(fullKeyword,"ismissing")
                fullKeyword = "none";
            end

            app.DefaultCleanMethod = fullKeyword;
            app.CleanMethodDropDown.Value = fullKeyword;
            doUpdate(app);
        end
        
        function setWidgetsToDefault(app,fromResetMethod)
            if (~isequal(app.DefaultCleanMethod, 'fill'))
                % update widgets (specifically the CleanMethodDropDown) in
                % case outputType changes affect them, since some output
                % types are not compatible with non-fill clean methods.
                updateWidgets(app,true);
            end

            app.StandardizeDropDown.Value = app.StandardizeDropDown.ItemsData{1+app.NonstandardByDefault};
            app.IndicatorEditField.Value = '';

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

            updateFillMethodAndKnnDistanceDDs(app);
            app.FillConstantSpinner.Value = 0;
            app.FillConstantSpinner.Step = 1;
            app.FillConstantUnitsDropDown.Value = 'days';
            setWindowDefault(app);
            app.EndValueDropDown.Value = 'extrap';
            app.EndValueConstantSpinner.Value = 0;
            app.EndValueConstantSpinner.Step = 1;
            app.EndValueConstantUnitsDropDown.Value = 'days';
            app.MaxGapSpinner.Value = inf;
            app.MaxGapSpinner.Step = matlab.internal.dataui.getStepSize(app.MaxGapSpinner.Value,true);
            app.MaxGapUnitsDropDown.Value = app.MaxGapUnitsDropDown.ItemsData{end};
            app.KnnKSpinner.Value = 1;
            if isAppWorkflow(app)
                app.CustomFillMethodSelector.FcnType = 'handle';
                app.CustomFillMethodSelector.HandleValue = '@(xs,ts,tq) xs(1)';
            else
                app.CustomFillMethodSelector.FcnType = 'local';
                app.CustomFillMethodSelector.HandleValue = '@(xs,ts,tq) polyval(polyfit(ts,xs,2),tq)';
            end
            app.CustomFillMethodSelector.LocalValue = 'select variable';
            app.CustomKnnDistanceSelector.FcnType = 'local';
            app.CustomKnnDistanceSelector.HandleValue = '@(x,mx) sum(abs(diff(x)),"omitmissing")';
            app.CustomKnnDistanceSelector.LocalValue = 'select variable';

            app.MinNumMissingSpinner.Value = 1;
            updateMinNumMissingSpinnerLimits(app);
            
            fromResetMethod = (nargin > 1) && fromResetMethod; % Called from reset()
            if ~fromResetMethod
                % reset() does not reset the input data, therefore, it does
                % not change whether the app supports visualization or not.
                app.SupportsVisualization = true;
            end
            app.PlotDataCheckBox.Value = true;
            app.PlotMissingDataCheckBox.Value = true;
            app.PlotOtherRemovedCheckBox.Value = true;
        end
        
        function changedWidget(app,context,eventData)
            % Update widgets' internal values from callbacks
            context = context.Tag;
            if matches(context,{app.InputDataDropDown.Tag,'ChangedDataVariables'})
                updateFillMethodAndKnnDistanceDDs(app);
                updateWindowDefault(app);
                updateMinNumMissingSpinnerLimits(app);
                updateSelectedVarType(app);
            elseif matches(context,{app.SamplePointsDropDown.Tag,app.SamplePointsTableVarDropDown.Tag})
                updateWindowDefault(app);
            elseif matches(context,{'changedOutputType','TableVarPlotDropDown'})
                updateSelectedVarType(app);
            elseif isequal(context,app.FillMethodDropDown.Tag)
                % If the previous method was a moving method, don't change
                % to the default window size
                if ~isequal(eventData.PreviousValue,'movmedian') && ...
                   ~isequal(eventData.PreviousValue,'movmean')
                    updateWindowDefault(app);
                end
            elseif isequal(context,app.FillConstantSpinner.Tag)
                app.FillConstantSpinner.Step = matlab.internal.dataui.getStepSize(...
                    app.FillConstantSpinner.Value,false,eventData.PreviousValue);
            elseif isequal(context,app.EndValueConstantSpinner.Tag)
                app.EndValueConstantSpinner.Step = matlab.internal.dataui.getStepSize(...
                    app.EndValueConstantSpinner.Value,false,eventData.PreviousValue);
            elseif isequal(context,app.MaxGapSpinner.Tag)
                app.MaxGapSpinner.Step = matlab.internal.dataui.getStepSize(...
                    app.MaxGapSpinner.Value,app.MaxGapSpinner.RoundFractionalValues,...
                    eventData.PreviousValue);
            elseif isequal(context,app.WindowTypeDropDown.Tag)
                setWindowType(app);
            end
        end
        
        function updateFillMethodAndKnnDistanceDDs(app)
            % Set Items(Data) to full list, then whittle it down
            Items = [getMsgText(app,'Constantvalue') getMsgText(app,'Previousvalue') ...
                getMsgText(app,'Nextvalue') getMsgText(app,'Nearestvalue') ...
                getMsgText(app,'Linearinterpolation') getMsgText(app,'Splineinterpolation') ...
                getMsgText(app,'Pchip') getMsgText(app,'Makima') ...
                getMsgText(app,'Movingmedian') getMsgText(app,'Movingmean') ...
                getMsgText(app,getMsgId(app,'Knn')) getMsgText(app,getMsgId(app,'Custom'))];
            ItemsData = {'constant' 'previous' 'next' 'nearest' 'linear' ...
                'spline' 'pchip' 'makima' 'movmedian' 'movmean' 'knn' 'custom'};
            % Get data to check type
            if ~hasInputData(app)
                % follow the 'numeric' branch
                A = [];
                istabularA = false;
            else
                A = evalin(app.Workspace,getInputDataVarName(app));
                istabularA = isa(A,'tabular');
                if istabularA
                    A = getSelectedSubTable(app,A);
                    % for input is row times, the above returns the vector
                    istabularA = isa(A,'tabular');
                end
            end
            averagable = false;
            % Whittle down Items based on datatype
            if isnumeric(A) || (istabularA && all(varfun(@isnumeric,A,'OutputFormat','uniform')))
                % full list
                defaultVal = 'linear';
                averagable = true;
            elseif isduration(A)
                % remove moving (note for tables with duration, 'constant'
                % is also not supported in the live task, set in next branch)
                Items(9:10) = [];
                ItemsData(9:10) = [];
                defaultVal = 'linear';
                averagable = true;
            elseif isdatetime(A) || (istabularA && ...
                    all(varfun(@(x)isdatetime(x) || isduration(x) || isnumeric(x),A,'OutputFormat','uniform')))
                % remove moving and constant
                Items([1 9 10]) = [];
                ItemsData([1 9 10]) = [];
                defaultVal = 'linear';
                averagable = true;
            elseif iscalendarduration(A)
                % no interp or moving (note for tables with calendarDuration, 'constant'
                % is also not supported in the live task, set in next branch)
                Items(5:10) = [];
                ItemsData(5:10) = [];
                defaultVal = 'previous';
            else
                % no interp, moving, or constant
                Items([1 5:10]) = [];
                ItemsData([1 5:10]) = [];
                defaultVal = 'previous';
            end
            
            knnItems = [getMsgText(app,getMsgId(app,'euclideanDistance')) ...
                getMsgText(app,getMsgId(app,'seuclideanDistance')) ...
                getMsgText(app,getMsgId(app,'customDistance'))];
            knnItemsData = {'euclidean' 'seuclidean' 'custom'};

            if ~ismatrix(A) || isvector(A)
                % all datatypes allow knn, but restrict size to 2D
                % table only has one variable, or array input is vector
                Items(end-1) = [];
                ItemsData(end-1) = [];
            else
                % also set knn distance metrics items
                isnotrealflt = @(x) ~isfloat(x) || ~isreal(x);
                if istimetable(A) || (isnotrealflt(A) && (~istabularA || any(varfun(isnotrealflt,A,'OutputFormat','uniform'))))
                    % euclidean metrics not supported
                    knnItems(1:2) = [];
                    knnItemsData(1:2) = [];
                end
                if isAppWorkflow(app)
                    % Don't support custom distance metric since there is no
                    % local function workflow and it is too difficult to get
                    % a reasonably short one-liner for table inputs
                    knnItems(end) = [];
                    knnItemsData(end) = [];
                    if isempty(knnItems)
                        % neither euclidean nor custom is supported, so remove
                        % knn from the method list
                        Items(end-1) = [];
                        ItemsData(end-1) = [];
                    end
                end
            end
            
            % Set Items/Data
            app.FillMethodDropDown.Items = Items;
            app.FillMethodDropDown.ItemsData = ItemsData;
            app.FillMethodDropDown.Value = defaultVal;
            app.KnnDistanceDropDown.Items = knnItems;
            app.KnnDistanceDropDown.ItemsData = knnItemsData;
            % KnnDistanceDropDown defaults to first Item if it exists

            % If we cannot average the selected data, then we can
            % only compare with one neighbor.
            app.AverageableData = averagable;
        end
        
        function updateWindowDefault(app)
            if isequal(app.CleanMethodDropDown.Value,'fill') && ...
                (isequal(app.FillMethodDropDown.Value,'movmedian') || ...
                 isequal(app.FillMethodDropDown.Value,'movmean'))
                setWindowDefault(app,evalInputDataVarNameWithCheck(app),...
                    evalSamplePointsVarNameWithCheck(app));
            end
        end

        function updateMinNumMissingSpinnerLimits(app)
            if hasInputData(app)
                T = app.InputDataDropDown.WorkspaceValue;
                if istabular(T)
                    T = getSelectedSubTable(app,T);
                end
                app.MinNumMissingSpinner.Limits(2) = max(width(T),2);
            else
                app.MinNumMissingSpinner.Limits(2) = inf;
            end
        end

        
        
        function updateWidgets(app,doEvalinBase)
            % Update the layout and visibility of the widgets
            
            updateInputDataAndSamplePointsDropDown(app);
            hasData = hasInputDataAndSamplePoints(app);
            
            app.StandardizeDropDown.Enable = hasData;
            app.IndicatorEditField.Enable = hasData;
            app.IndicatorEditField.Visible = isequal(app.StandardizeDropDown.Value,'nonstandard');
            if app.IndicatorEditField.Visible
                app.IndicatorEditField.Parent = app.StandardizeDropDown.Parent;
            else
                app.IndicatorEditField.Parent = [];
            end
            
            A = [];
            istabularA = false;
            if hasData && doEvalinBase
                A = evalin(app.Workspace,getInputDataVarName(app));
                istabularA = isa(A,'tabular');
                if istabularA
                    A = getSelectedSubTable(app,A);
                    % for input is row times, the above returns the vector
                    istabularA = isa(A,'tabular');
                end
            end
            if ~ismatrix(A) || (app.InputDataHasTableVars && isequal(app.OutputTypeDropDown.Value,'append')) ||...
                    (istabularA && ~all(varfun(@ismatrix,A,'OutputFormat','uniform')))
                % rmmissing doesn't support ND, and append doesn't make
                % sense with rmmissing so remove "remove"
                app.CleanMethodDropDown.Items = cellstr([getMsgText(app,getMsgId(app,'Fillmissing')) ...
                    getMsgText(app,'None')]);
                app.CleanMethodDropDown.ItemsData = {'fill' 'none'};
            else
                % reset to default
                app.CleanMethodDropDown.Items = cellstr([getMsgText(app,getMsgId(app,'Fillmissing')) ...
                    getMsgText(app,getMsgId(app,'Removemissing')) getMsgText(app,'None')]);
                app.CleanMethodDropDown.ItemsData = {'fill' 'remove' 'none'};
            end
            if app.InputDataHasTableVars && isequal(app.OutputTypeDropDown.Value,'replace') && ...
                    (isequal(app.StandardizeDropDown.Value,'standard') || isempty(app.IndicatorEditField.Value))
                % 'replace' output, 'none' method is only supported if
                % standardizing missing
                app.CleanMethodDropDown.Items(end) = [];
                app.CleanMethodDropDown.ItemsData(end) = [];
            end
            
            app.CleanMethodDropDown.Enable = hasData;
            doFill = isequal(app.CleanMethodDropDown.Value,'fill');
            app.FillMethodDropDown.Enable = hasData;
            app.FillMethodDropDown.Visible = doFill;
            % Dynamic tooltip based on method
            app.FillMethodDropDown.Tooltip = getMsgText(app,getMsgId(app,['FillTooltip' app.FillMethodDropDown.Value]));
            fillMethod = app.FillMethodDropDown.Value;
            doConst = doFill && isequal(fillMethod,'constant');
            
            doMov = doFill && ismember(fillMethod,{'movmedian' 'movmean' 'custom'});
            app.WindowParentGrid.RowHeight{2} = doMov*app.TextRowHeight;
            if doEvalinBase
                hasUnits = hasDurationOrDatetimeSamplePoints(app);
                setWindowVisibility(app,doMov,hasData,hasUnits);
            else
                setWindowVisibility(app,doMov,hasData);
            end
                        
            app.FillConstantSpinner.Visible = doConst;
            app.FillConstantUnitsDropDown.Visible = doConst;
            if doConst
                % Only numeric, duration, or calendarDuration should get here
                % if A is tabular, its all numeric variables
                if isduration(A) || iscalendarduration(A)
                    % need spinner + units
                    app.FillConstantUnitsDropDown.Visible = true;
                    app.FillConstantSpinner.Limits = [0 inf];
                    if isduration(A)
                        app.FillConstantUnitsDropDown.Items = cellstr([getMsgText(app,'Milliseconds') ...
                            getMsgText(app,'Seconds') getMsgText(app,'Minutes') getMsgText(app,'Hours') ...
                            getMsgText(app,'Days') getMsgText(app,'Years')]);
                        app.FillConstantUnitsDropDown.ItemsData = {'milliseconds' 'seconds' 'minutes' 'hours' 'days' 'years'};
                        app.FillConstantSpinner.RoundFractionalValues = 'off';
                    else %is calendarduration
                        app.FillConstantUnitsDropDown.Items = cellstr([ getMsgText(app,'Years') getMsgText(app,'Months') getMsgText(app,'Days')]);
                        app.FillConstantUnitsDropDown.ItemsData = {'years','months','days'};
                        app.FillConstantSpinner.RoundFractionalValues = 'on';
                    end
                else %if isnumeric(A) || istabular(A) && all numeric
                    % need spinner
                    app.FillConstantUnitsDropDown.Visible = false;
                    app.FillConstantSpinner.Limits = [-inf inf];
                    app.FillConstantSpinner.RoundFractionalValues = 'off';
                end
            end
            
            showEndValues = false;
            doKnn = doFill && isequal(fillMethod,'knn');
            if doFill && ~doKnn
                showEndValuesFcn = @(x) ~isempty(A) && (ismissing(x(1)) || ismissing(x(end)));
                if istabularA
                    % all variables
                    showEndValues = any(varfun(showEndValuesFcn,A,'OutputFormat','uniform'));
                else
                    showEndValues = showEndValuesFcn(A);
                end
            end
            app.EndValueLabel.Visible = showEndValues;
            app.EndValueDropDown.Visible = showEndValues;
            app.EndValueConstantSpinner.Visible = showEndValues;
            app.EndValueConstantUnitsDropDown.Visible = showEndValues;
            if showEndValues
                if isduration(A) || isnumeric(A) || (istabularA && all(varfun(@isnumeric,A,'OutputFormat','uniform')))
                    app.EndValueDropDown.ItemsData = union(app.EndValueDropDown.ItemsData, {'scalar'}, 'stable');
                else
                    app.EndValueDropDown.ItemsData = setdiff(app.EndValueDropDown.ItemsData, {'scalar'},'stable');
                end
                
                if isequal(app.EndValueDropDown.Value,'scalar')
                    if isduration(A)
                        % need spinner + units
                        app.EndValueConstantSpinner.Limits = [0 inf];
                    else %isnumeric(A)
                        % need spinner only
                        app.EndValueConstantUnitsDropDown.Visible = false;
                        app.EndValueConstantSpinner.Limits = [-inf inf];
                    end
                else
                    app.EndValueConstantSpinner.Visible = false;
                    app.EndValueConstantUnitsDropDown.Visible = false;
                end
            else
                % Reset to make sure script generates correctly
                app.EndValueDropDown.Value = 'extrap';
            end

            doCustom = doFill && isequal(app.FillMethodDropDown.Value,'custom');
            app.CustomFillMethodSelector.Visible = doCustom;
            app.CustomFillMethodSelector.Enable = hasData;
            if doCustom
                app.WindowLabel.Text = getMsgText(app,getMsgId(app,'GapWindow'));
            else
                app.WindowLabel.Text = getMsgText(app,'Movingwindow');
            end

            app.KnnKLabel.Visible = doKnn;
            app.KnnKSpinner.Visible = doKnn;
            app.KnnDistanceDropDown.Visible = doKnn;
            app.CustomKnnDistanceSelector.Visible = doKnn && isequal(app.KnnDistanceDropDown.Value,'custom');
            if app.AverageableData
                app.KnnKSpinner.Limits(2) = inf;
                app.KnnKSpinner.Tooltip = getMsgText(app,getMsgId(app,'KnnKTooltip'));
            else
                app.KnnKSpinner.Limits(2) = 1;
                app.KnnKSpinner.Tooltip = getMsgText(app,getMsgId(app,'KnnKTooltipDisabled'));
            end
            if istabularA
                app.CustomKnnDistanceSelector.Tooltip = getMsgText(app,getMsgId(app,'CustomKnnTooltipTabular'));
            else
                app.CustomKnnDistanceSelector.Tooltip = getMsgText(app,getMsgId(app,'CustomKnnTooltipArray'));
            end

            doMinNumMissing = isequal(app.CleanMethodDropDown.Value,'remove') && ~isvector(A);
            app.MinNumMissingLabel.Visible = doMinNumMissing;
            app.MinNumMissingSpinner.Visible = doMinNumMissing;
            app.MinNumMissingSpinner.Enable = hasData;

			% Shift end value widgets based on visibility of constant spinner/label
            % necessary so these controls line up with other rows correctly
            doShift = doConst || doCustom;
            app.EndValueLabel.Layout.Column = 5 + 2*doShift;
            app.EndValueDropDown.Layout.Column = 6 + 2*doShift;
            app.EndValueConstantSpinner.Layout.Column = 7 + 2*doShift;
            app.EndValueConstantUnitsDropDown.Layout.Column = 8 + 2*doShift;
            
            % maxgap row
            doMaxGap = isequal(app.CleanMethodDropDown.Value,'fill') && ~doKnn;
            app.WindowParentGrid.RowHeight{4} = doMaxGap*app.TextRowHeight;
            app.MaxGapLabel.Visible = doMaxGap;
            app.MaxGapSpinner.Visible = doMaxGap;
            app.MaxGapSpinner.Enable = hasData;
            % Units
            app.MaxGapUnitsDropDown.Enable = hasData;
            if doEvalinBase
                app.MaxGapUnitsDropDown.Visible = doMaxGap && hasUnits;
                if hasDatetimeSamplePoints(app)
                    % units can be calendarDuration
                    app.MaxGapUnitsDropDown.Items = cellstr([getMsgText(app,'Milliseconds') ...
                        getMsgText(app,'Seconds') getMsgText(app,'Minutes') getMsgText(app,'Hours') ...
                        getMsgText(app,'Days') getMsgText(app,'Weeks') getMsgText(app,'Months') ...
                        getMsgText(app,'Quarters') getMsgText(app,'Years')]);
                    app.MaxGapUnitsDropDown.ItemsData = {'milliseconds' 'seconds' ...
                        'minutes' 'hours' 'days' 'weeks' 'months' 'quarters' 'years'};
                    % cal* functions do not take fractional values
                    doRound = ismember(app.MaxGapUnitsDropDown.Value,...
                        {'days' 'weeks' 'months' 'quarters' 'years'});
                    if doRound && fix(app.MaxGapSpinner.Step) ~= app.MaxGapSpinner.Step
                        % Step size must be round value before setting RoundFractionalValue
                        app.MaxGapSpinner.Step = matlab.internal.dataui.getStepSize(...
                            app.MaxGapSpinner.Value,true);
                    end
                    app.MaxGapSpinner.RoundFractionalValues = doRound;
                else
                    app.MaxGapUnitsDropDown.ItemsData = {'milliseconds' 'seconds' 'minutes' 'hours' 'days' 'years'};
                    app.MaxGapUnitsDropDown.Items = cellstr([getMsgText(app,'Milliseconds') ...
                        getMsgText(app,'Seconds') getMsgText(app,'Minutes') getMsgText(app,'Hours') ...
                        getMsgText(app,'Days') getMsgText(app,'Years')]);
                    app.MaxGapSpinner.RoundFractionalValues = false;
                end                    
            end

            % for best fit width/height, unparent invisible widgets
            matlab.internal.dataui.setParentForWidgets([app.FillMethodDropDown app.FillConstantSpinner ...
                app.FillConstantUnitsDropDown app.EndValueLabel app.EndValueDropDown ...
                app.EndValueConstantSpinner app.EndValueConstantUnitsDropDown ...
                app.CustomFillMethodSelector app.MinNumMissingLabel app.MinNumMissingSpinner ...
                app.MaxGapLabel app.MaxGapSpinner app.MaxGapUnitsDropDown ...
                app.KnnKLabel app.KnnKSpinner app.KnnDistanceDropDown ...
                app.CustomKnnDistanceSelector],app.WindowParentGrid);
            if doFill
                app.WindowParentGrid.ColumnWidth([3 4]) = {70, 70};
            else
                app.WindowParentGrid.ColumnWidth([3 4]) = {'fit','fit'};
            end
            
            app.PlotDataCheckBox.Enable = hasData;
            app.PlotMissingDataCheckBox.Enable = hasData;
            app.PlotOtherRemovedCheckBox.Enable = hasData;
            if isequal(app.CleanMethodDropDown.Value,'fill')
                app.PlotDataCheckBox.Text = getMsgText(app,'CleanedData');
                app.PlotMissingDataCheckBox.Text = getMsgText(app,getMsgId(app,'FilledMissingEntries'));
            elseif isequal(app.CleanMethodDropDown.Value,'remove')
                app.PlotDataCheckBox.Text = getMsgText(app,'CleanedData');
                app.PlotMissingDataCheckBox.Text = getMsgText(app,getMsgId(app,'RemovedMissingEntries'));
            else
                app.PlotDataCheckBox.Text = getMsgText(app,'InputData');
                app.PlotMissingDataCheckBox.Text = getMsgText(app,getMsgId(app,'MissingEntries'));
            end
            doShow = showPlotCheckboxes(app,app.PlotDataCheckBox,app.PlotMissingDataCheckBox,app.PlotOtherRemovedCheckBox);
            app.PlotOtherRemovedCheckBox.Visible = doShow && ...
                isequal(app.CleanMethodDropDown.Value,'remove') && hasMultipleDataVariables(app);
        end
        
        function tf = filterInputData(~,A,isTableVar)
            % Keep only Input Data of supported type
            if isa(A,'tabular') % table or timetable
                tf = ~isTableVar; % No tables within tables
            else
                % Copied from fillmissing.m isSupportedArray()
                % additional nonempty/nonscalar restriction
                tf = ~isempty(A) && ~isscalar(A) && (isnumeric(A) || islogical(A) || ...
                    isstring(A) || iscategorical(A) || iscellstr(A) || ischar(A) || ...
                    isdatetime(A) || isduration(A) || iscalendarduration(A));
            end
        end
        
        function tf = filterSamplePointsType(~,X,isTableVar)
            % Keep only Sample Points (X-axis) of supported type
            if istall(X)
                tf = false;
            elseif isa(X,'tabular') % table or timetable
                tf = ~isTableVar; % No tables within tables
            else
                % Copied from fillmissing.m checkSamplePoints()
                tf = (isvector(X) || isempty(X)) && ...
                    ((isfloat(X) && isreal(X) && ~issparse(X)) || ...
                    isduration(X) || isdatetime(X));
            end
        end

        function tf = waitingOnLocalFunctionSelection(app)
            % waiting on custom fill method or custom knn distance metric
            tf = isequal(app.CleanMethodDropDown.Value,'fill') && ...
                (isequal(app.FillMethodDropDown.Value,'custom') && isempty(app.CustomFillMethodSelector.Value)) || ...
                (isequal(app.FillMethodDropDown.Value,'knn') && isequal(app.KnnDistanceDropDown.Value,'custom') && ...
                isempty(app.CustomKnnDistanceSelector.Value));
        end
        
        function propTable = getLocalPropertyInformation(app)
            Name = ["StandardizeDropDown";"IndicatorEditField";"CleanMethodDropDown";...
                "FillMethodDropDown";"FillConstantSpinner";"FillConstantUnitsDropDown";...
                "CustomFillMethodSelector";...
                "EndValueDropDown";"EndValueConstantSpinner";"EndValueConstantUnitsDropDown"; ...
                "KnnKSpinner"; "KnnDistanceDropDown"; ... %CustomKnnDistanceSelector not supported in app
                "MaxGapSpinner";"MaxGapUnitsDropDown";"MinNumMissingSpinner"];
            Group = [repmat(getMsgText(app,getMsgId(app,'StandardizeDelimiter')),2,1); repmat(getMsgText(app,'MethodDelimiter'),13,1)];
            DisplayName = [getMsgText(app,getMsgId(app,'StandardizeMethod')); getMsgText(app,getMsgId(app,'StandardizeIndicator'));...
                getMsgText(app,'CleaningMethod'); getMsgText(app,'FillMethod');...
                getMsgText(app,'Constantvalue'); getMsgText(app,'Units'); getMsgText(app,getMsgId(app,'Custom'));...
                getMsgText(app,getMsgId(app,'EndValues')); getMsgText(app,'Constantvalue'); getMsgText(app,'Units');...
                getMsgText(app,getMsgId(app,'KnnK')); getMsgText(app,getMsgId(app,'KnnDistance')); ...
                getMsgText(app,getMsgId(app,'MaxGap')); getMsgText(app,'Units'); getMsgText(app,getMsgId(app,'MinNumMissing'))];
            StateName = Name + "Value";
            
            propTable = table(Name,Group,DisplayName,StateName);
            propTable = [propTable; getWindowProperties(app)];
            propTable = addFieldsToPropTable(app,propTable);
            % minimize End Value controls by default
            propTable.InSubgroup(8:10) = true;
            % indicator tooltip needs example with quotes
            propTable.Tooltip{2} = char(getMsgText(app,getMsgId(app,'StandardizeTooltip3')));
        end

        function msgId = getMsgId(~,id)
            msgId = ['missingDataCleaner' id];
        end
    end
    
    methods (Access = public)
        % Required for embedding in a Live Script

        % implemented in generateScript.m
        [code,outputs] = generateScript(app,isForExport,overwriteInput)

        % implemented in generateVisualizationScript.m
        code = generateVisualizationScript(app)
        
        function setTaskState(app,state,updatedWidget)
            % With nargin == 2, setState is used by live editor and App for
            % save/load, undo/redo
            % With nargin == 3, setState is used by the App to change the
            % value of a control from the property inspector
            if nargin < 3
                updatedWidget = '';
            end
            event = struct();
            if ismember(updatedWidget,{'FillMethodDropDown' 'FillConstantSpinner' ...
                    'EndValueConstantSpinner' 'MaxGapSpinner' 'IndicatorEditField' ...
                    'CustomFillMethodSelector'})
                % for these controls, the changedWidget method requires the
                % PreviousValue to make the appropriate update
                event.PreviousValue = app.(updatedWidget).Value;
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
                if isfield(state,'SelectedVarType')
                    app.SelectedVarType = state.SelectedVarType;
                else
                    app.SelectedVarType = 'numeric';
                end
                if isfield(state,'SelectedVarNumUnique')
                    app.SelectedVarNumUnique = state.SelectedVarNumUnique;
                else
                    app.SelectedVarNumUnique = NaN;
                end
                setInputDataAndSamplePointsDropDownValues(app,state);
                setWindowDropDownValues(app,state);
                if isfield(state,'MinNumMissingSpinnerLimits')
                    app.MinNumMissingSpinner.Limits = state.MinNumMissingSpinnerLimits;
                end
                app.KnnKSpinner.Limits(2) = inf; % So KnnKSpinner Value can be set
                if isfield(state,'KnnDistanceDropDownItemsData')
                    app.KnnDistanceDropDown.ItemsData = state.KnnDistanceDropDownItemsData;
                    app.KnnDistanceDropDown.Items = {};
                    for k = 1:numel(state.KnnDistanceDropDownItemsData)
                        app.KnnDistanceDropDown.Items{k} = char(app.getMsgText(app.getMsgId(...
                            [state.KnnDistanceDropDownItemsData{k} 'Distance'])));
                    end
                end
                setValueOfComponents(app,["StandardizeDropDown" "IndicatorEditField"...
                    "CleanMethodDropDown" "FillMethodDropDown" ...
                    "FillConstantSpinner" "EndValueDropDown"  ...
                    "FillConstantUnitsDropDown" "EndValueConstantSpinner" ...
                    "EndValueConstantUnitsDropDown" "MaxGapSpinner" ...
                    "MaxGapUnitsDropDown" "MinNumMissingSpinner" ...
                    "PlotDataCheckBox" "PlotMissingDataCheckBox"...
                    "PlotOtherRemovedCheckBox" "KnnKSpinner" "KnnDistanceDropDown"],state);
                if isfield(state,'IsCustomFillMethod') && state.IsCustomFillMethod
                    app.FillMethodDropDown.Value = 'custom';
                elseif isfield(state,'IsKnnFillMethod') && state.IsKnnFillMethod
                    app.FillMethodDropDown.Value = 'knn';
                end
                if isfield(state,'CustomFillMethodSelectorValue')
                    if isequal(updatedWidget,'CustomFillMethodSelector')
                        app.CustomFillMethodSelector.HandleValue = state.CustomFillMethodSelectorValue;
                    else
                        app.CustomFillMethodSelector.State = state.CustomFillMethodSelectorState;
                    end
                end
                if isfield(state,'CustomKnnDistanceSelectorState')
                    app.CustomKnnDistanceSelector.State = state.CustomKnnDistanceSelectorState;
                end
                if isfield(state,'AverageableData')
                    app.AverageableData = state.AverageableData;
                end

                if isfield(state,'DefaultCleanMethod')
                    app.DefaultCleanMethod = state.DefaultCleanMethod;
                end

                if isfield(state,'NonstandardByDefault')
                    app.NonstandardByDefault = state.NonstandardByDefault;
                end
                
                if isempty(updatedWidget)
                    app.FillConstantSpinner.Step = matlab.internal.dataui.getStepSize(...
                        app.FillConstantSpinner.Value,false);
                    app.EndValueConstantSpinner.Step = matlab.internal.dataui.getStepSize(...
                        app.EndValueConstantSpinner.Value,false);
                    
                    doRound = hasDatetimeSamplePoints(app) &&...
                        ismember(app.MaxGapUnitsDropDown.Value,{'days','weeks','months','quarters','years'});
                    app.MaxGapSpinner.Step = matlab.internal.dataui.getStepSize(...
                        app.MaxGapSpinner.Value,doRound);
                    app.MaxGapSpinner.RoundFractionalValues = doRound;
                    doUpdate(app,false);
                elseif isequal(updatedWidget,'CustomFillMethodSelector')
                    app.CustomFillMethodSelector.validateFcnHandle(app.CustomFillMethodSelector.HandleEditField,event)
                else
                    doUpdateFromWidgetChange(app,app.(updatedWidget),event);
                end
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

        function updateSelectedVarType(app)
            % Get and save data type of variable to be plotted
            % Allow being called by DataPreprocessingTask for getPlotCode
            app.SelectedVarType = 'numeric';
            app.SelectedVarNumUnique = NaN;
            if ~hasInputData(app) || isnumeric(app.TableVarPlotDropDown.Value)
                return
            end
            A = app.InputDataDropDown.WorkspaceValue;
            if istabular(A)
                A = getSelectedSubTable(app,A);
                % A could now be vector if input is row times
                if istabular(A)
                    if ~isempty(app.TableVarPlotDropDown.Value)
                        A = A.(app.TableVarPlotDropDown.Value);
                    else
                        % only one var selected as input, so plot DD doesn't show
                        A = A.(1);
                    end
                end
            end
            if isnumeric(A)
                app.SelectedVarType = 'numeric';
            else
                app.SelectedVarType = class(A);
                if ~matches(app.SelectedVarType,["logical" "datetime" "duration" "categorical"])
                    % numunique
                    app.SelectedVarNumUnique = numel(unique(A(~ismissing(A))));
                end % else we don't need this calculation so it stays NaN
            end
        end
    end

    methods
        function summary = get.Summary(app)
            if ~hasInputDataAndSamplePoints(app)
                summary = getMsgText(app,'Tool_missingDataCleaner_Description');
                return;
            end
            
            varName = getInputDataVarNameForSummary(app);
            cleanMethod = app.CleanMethodDropDown.Value;
            cleanMethod(1) = upper(cleanMethod(1));
            msgId = [getMsgId(app,'Summary') cleanMethod];
            if isequal(cleanMethod,'Fill')
                if isequal(app.FillMethodDropDown.Value,'knn')
                    if app.KnnKSpinner.Value == 1
                        methodStr = app.getMsgText(app.getMsgId('NearestNeighbor'));
                    else
                        methodStr = app.getMsgText(app.getMsgId('NNearestNeighbors'),num2str(app.KnnKSpinner.Value));
                    end
                else
                    method = app.FillMethodDropDown.Value;
                    methodStr = app.FillMethodDropDown.Items{ismember(app.FillMethodDropDown.ItemsData,method)};
                    methodStr(1) = lower(methodStr(1));
                end
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
            for k = {'StandardizeDropDown' 'IndicatorEditField' ...
                    'CleanMethodDropDown' 'FillMethodDropDown' ...
                    'FillConstantSpinner' 'EndValueDropDown' ...
                    'PlotDataCheckBox' 'PlotMissingDataCheckBox' ...
                    'FillConstantUnitsDropDown' 'EndValueConstantSpinner' ...
                    'EndValueConstantUnitsDropDown' 'MaxGapSpinner' ...
                    'MaxGapUnitsDropDown' 'PlotOtherRemovedCheckBox' ...
                    'MinNumMissingSpinner' 'CustomFillMethodSelector' ...
                    'KnnKSpinner' 'KnnDistanceDropDown'}
                state.([k{1} 'Value']) = app.(k{1}).Value;
            end
            state.IsCustomFillMethod = isequal(state.FillMethodDropDownValue,'custom');
            state.IsKnnFillMethod = isequal(state.FillMethodDropDownValue,'knn');
            if (state.IsCustomFillMethod || state.IsKnnFillMethod) && ~isAppWorkflow(app)
                % to be able to save and open in old versions (prior to 22b/23b),
                % set dd value to something always in original ItemsData
                state.FillMethodDropDownValue = 'previous';
            end
            state.MinNumMissingSpinnerLimits = app.MinNumMissingSpinner.Limits;
            state.CustomFillMethodSelectorState = app.CustomFillMethodSelector.State;
            state.CustomKnnDistanceSelectorState = app.CustomKnnDistanceSelector.State;
            state.KnnDistanceDropDownItemsData = app.KnnDistanceDropDown.ItemsData;
            state.AverageableData = app.AverageableData;

            state.DefaultCleanMethod = app.DefaultCleanMethod;
            state.NonstandardByDefault = app.NonstandardByDefault;

            if ~isequal(app.SelectedVarType,'numeric')
                state.SelectedVarType = app.SelectedVarType;
            end
            if ~ismissing(app.SelectedVarNumUnique)
                state.SelectedVarNumUnique = app.SelectedVarNumUnique;
            end
        end

        function set.State(app,state)
            setTaskState(app,state);
        end

        function set.Workspace(app,ws)
            app.Workspace = ws;
            app.InputDataDropDown.Workspace = ws;
            app.SamplePointsDropDown.Workspace = ws;
            if ~isequal(ws,'base')
                % Local functions not supported
                app.CustomFillMethodSelector.FcnType = 'handle'; %#ok<MCSUP>
                % Update default value to one that usually won't throw error
                app.CustomFillMethodSelector.HandleValue = '@(xs,ts,tq) xs(1)'; %#ok<MCSUP>
            end
        end
    end
end