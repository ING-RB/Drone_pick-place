classdef RowColumnPlot < controllib.chart.internal.foundation.AbstractPlot
    % controllib.chart.internal.foundation.AbstractPlot is a foundation class that is a node in the graphics
    % tree. All controls charts should subclass from this.
    %
    % h = InputOutputPlot(Name-Value)
    %
    %   NInputs                 number of inputs (used when SystemModels is not provided), default value is 1
    %   NOutputs                number of outputs (used when SystemModels is not provided), default value is 1
    %   InputNames              string array specifying input names (size must be consistent with NInputs)
    %   OutputNames             string array specifying output names (size must be consistent with NOutputs)
    %
    % Public properties:
    %   InputVisible        matlab.lang.OnOffSwitchState vector for setting input visibility
    %   OutputVisible       matlab.lang.OnOffSwitchState vector for setting output visibility
    %   IOGrouping          string specifying how input/outputs are grouped together,
    %                       "none"|"inputs"|"outputs"|"outputs"
    %   InputNames          string array for input names
    %   OutputNames         string array for output names
    %
    % See controllib.chart.internal.foundation.AbstractPlot

    % Copyright 2022-2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent, SetObservable, AbortSet)
        XLimitsSharing
        YLimitsSharing
    end

    properties (Hidden, Dependent, SetObservable, AbortSet)
        % Show or hide specific rows/columns
        RowVisible
        ColumnVisible
        RowColumnGrouping
        RowNames
        ColumnNames
    end

    properties (Hidden, Dependent, SetAccess = protected)
        NRows
        NColumns
        RowLabels
        ColumnLabels
    end

    properties (Hidden,Dependent,SetAccess=private)
        HasCustomRowNames
        HasCustomColumnNames
    end

    properties (GetAccess=protected,SetAccess=private)
        RowColumnGrouping_I = "none"
    end

    properties (Access = private,Transient,NonCopyable)
        XLimitsSharing_I = "all"
        YLimitsSharing_I = "row"
        NRows_I = 1
        NColumns_I = 1
        RowVisible_I = matlab.lang.OnOffSwitchState(true)
        ColumnVisible_I = matlab.lang.OnOffSwitchState(true)
        RowLabels_I
        ColumnLabels_I
    end

    properties (Hidden,Transient,NonCopyable)
        SupportDynamicGridSize (1,1) logical = true
    end

    properties(Access = protected,Transient,NonCopyable)
        RowColumnGroupingMenu
        RowColumnGroupingSubMenu
        RowColumnSelectorMenu
    end

    %% Events
    events
        GridSizeChanged
    end

    %% Constructor and public methods
    methods
        function this = RowColumnPlot(optionalInputs,abstractPlotArguments)
            arguments
                optionalInputs.Options (1,1) plotopts.RespPlotOptions = controllib.chart.internal.foundation.RowColumnPlot.createDefaultOptions()
                abstractPlotArguments.?controllib.chart.internal.foundation.AbstractPlotOptionalInputs
            end
            abstractPlotArguments = namedargs2cell(abstractPlotArguments);
            this@controllib.chart.internal.foundation.AbstractPlot(abstractPlotArguments{:},Options=optionalInputs.Options);
        end

        function options = getoptions(this,propertyName)
            % getoptions: Get options object or specific option.
            %
            %   options = getoptions(h)
            %   optionValue = getoptions(h,optionName)
            arguments
                this (1,1) controllib.chart.internal.foundation.RowColumnPlot
                propertyName string {mustBeScalarOrEmpty,validateOptionPropertyName(this,propertyName)} = string.empty
            end
            if isempty(propertyName)
                options = getoptions@controllib.chart.internal.foundation.AbstractPlot(this);
                labelProps = ["FontSize";"FontWeight";"FontAngle";"Color";"Interpreter"];
                for ii = 1:length(labelProps)
                    if isstring(this.RowLabels.(labelProps(ii)))
                        value = char(this.RowLabels.(labelProps(ii)));
                    else
                        value = this.RowLabels.(labelProps(ii));
                    end
                    options.OutputLabels.(labelProps(ii)) = value;
                    if isstring(this.ColumnLabels.(labelProps(ii)))
                        value = char(this.ColumnLabels.(labelProps(ii)));
                    else
                        value = this.ColumnLabels.(labelProps(ii));
                    end
                    options.InputLabels.(labelProps(ii)) = value;
                end
                options.ColorMode.OutputLabels = this.RowLabels.ColorMode;
                options.ColorMode.InputLabels = this.ColumnLabels.ColorMode;
                options.OutputVisible = cellstr(this.RowVisible);
                options.InputVisible = cellstr(this.ColumnVisible);
                switch char(this.RowColumnGrouping)
                    case 'columns'
                        options.IOGrouping = 'inputs';
                    case 'rows'
                        options.IOGrouping = 'outputs';
                    otherwise
                        options.IOGrouping = char(this.RowColumnGrouping);
                end
            else
                switch propertyName
                    case 'OutputLabels'
                        options = struct('FontSize',   this.RowLabels.FontSize, ...
                            'FontWeight', char(this.RowLabels.FontWeight), ...
                            'FontAngle',  char(this.RowLabels.FontAngle), ...
                            'Color',      this.RowLabels.Color, ...
                            'Interpreter', char(this.RowLabels.Interpreter));
                    case 'InputLabels'
                        options = struct('FontSize',   this.ColumnLabels.FontSize, ...
                            'FontWeight', char(this.ColumnLabels.FontWeight), ...
                            'FontAngle',  char(this.ColumnLabels.FontAngle), ...
                            'Color',      this.ColumnLabels.Color, ...
                            'Interpreter', char(this.ColumnLabels.Interpreter));
                    case 'OutputVisible'
                        options = cellstr(this.RowVisible);
                    case 'InputVisible'
                        options = cellstr(this.ColumnVisible);
                    case 'IOGrouping'
                        switch char(this.RowColumnGrouping)
                            case 'columns'
                                options = 'inputs';
                            case 'rows'
                                options = 'outputs';
                            otherwise
                                options = char(this.RowColumnGrouping);
                        end
                    otherwise
                        options = getoptions@controllib.chart.internal.foundation.AbstractPlot(this,propertyName);
                end
            end
        end

        function setoptions(this,options)
            arguments
                this (1,1) controllib.chart.internal.foundation.RowColumnPlot
                options (1,1) plotopts.RespPlotOptions = getoptions(this)
            end

            options = copy(options);

            % RowLabels
            labelProps = ["FontSize";"FontWeight";"FontAngle";"Color";"Interpreter"];
            for ii = 1:length(labelProps)
                value = options.OutputLabels.(labelProps(ii));
                if ismember(labelProps(ii),["FontWeight";"FontAngle";"Interpreter"])
                    try %#ok<TRYNC>
                        value = lower(value);
                    end
                end
                this.RowLabels.(labelProps(ii)) = value;
            end
            if isfield(options.ColorMode,"OutputLabels")
                this.RowLabels.ColorMode = options.ColorMode.OutputLabels;
            end

            % ColumnLabels
            for ii = 1:length(labelProps)
                value = options.InputLabels.(labelProps(ii));
                if ismember(labelProps(ii),["FontWeight";"FontAngle";"Interpreter"])
                    try %#ok<TRYNC>
                        value = lower(value);
                    end
                end
                this.ColumnLabels.(labelProps(ii)) = value;
            end
            if isfield(options.ColorMode,"InputLabels")
                this.ColumnLabels.ColorMode = options.ColorMode.InputLabels;
            end

            % "Fix" options visibiliy
            if length(options.OutputVisible) > this.NRows
                options.OutputVisible = options.OutputVisible(1:this.NRows);
            end
            if isscalar(options.OutputVisible)
                options.OutputVisible = repmat(options.OutputVisible,this.NRows,1);
            end
            if length(options.InputVisible) > this.NColumns
                options.InputVisible = options.InputVisible(1:this.NColumns);
            end
            if isscalar(options.InputVisible)
                options.InputVisible = repmat(options.InputVisible,1,this.NColumns);
            end

            % RowVisible
            try
                this.RowVisible = options.OutputVisible;
            catch
                warning(message('Controllib:plots:SetOptionsIncorrectSize','OutputVisible'))
            end

            % ColumnVisible
            try
                this.ColumnVisible = options.InputVisible;
            catch
                warning(message('Controllib:plots:SetOptionsIncorrectSize','InputVisible'))
            end

            % RowColumnGrouping
            switch options.IOGrouping
                case 'outputs'
                    this.RowColumnGrouping = "rows";
                case 'inputs'
                    this.RowColumnGrouping = "columns";
                otherwise
                    this.RowColumnGrouping = options.IOGrouping;
            end

            % "Fix" options limits
            sz = getXLimitsSize(this);
            if ~any(sz == 0)
                % XLimMode
                if size(options.XLimMode,1) > sz(1)
                    options.XLimMode = options.XLimMode(1:sz(1),:);
                end
                if size(options.XLimMode,2) > sz(2)
                    options.XLimMode = options.XLimMode(:,1:sz(2));
                end
                szRatio = sz./size(options.XLimMode);
                if szRatio(1) == floor(szRatio(1))
                    options.XLimMode = repmat(options.XLimMode,szRatio(1),1);
                end
                if szRatio(2) == floor(szRatio(2))
                    options.XLimMode = repmat(options.XLimMode,1,szRatio(2));
                end

                % XLim
                if size(options.XLim,1) > sz(1)
                    xLimMode = options.XLimMode;
                    options.XLim = options.XLim(1:sz(1),:);
                    options.XLimMode = xLimMode;
                end
                if size(options.XLim,2) > sz(2)
                    xLimMode = options.XLimMode;
                    options.XLim = options.XLim(:,1:sz(2));
                    options.XLimMode = xLimMode;
                end
                szRatio = sz./size(options.XLim);
                if szRatio(1) == floor(szRatio(1))
                    xLimMode = options.XLimMode;
                    options.XLim = repmat(options.XLim,szRatio(1),1);
                    options.XLimMode = xLimMode;
                end
                if szRatio(2) == floor(szRatio(2))
                    xLimMode = options.XLimMode;
                    options.XLim = repmat(options.XLim,1,szRatio(2));
                    options.XLimMode = xLimMode;
                end
            end

            sz = getYLimitsSize(this);
            if ~any(sz == 0)
                % YLimMode
                if size(options.YLimMode,1) > sz(1)
                    options.YLimMode = options.YLimMode(1:sz(1),:);
                end
                if size(options.YLimMode,2) > sz(2)
                    options.YLimMode = options.YLimMode(:,1:sz(2));
                end
                szRatio = sz./size(options.YLimMode);
                if szRatio(1) == floor(szRatio(1))
                    options.YLimMode = repmat(options.YLimMode,szRatio(1),1);
                end
                if szRatio(2) == floor(szRatio(2))
                    options.YLimMode = repmat(options.YLimMode,1,szRatio(2));
                end

                %YLim
                if size(options.YLim,1) > sz(1)
                    yLimMode = options.YLimMode;
                    options.YLim = options.YLim(1:sz(1),:);
                    options.YLimMode = yLimMode;
                end
                if size(options.YLim,2) > sz(2)
                    yLimMode = options.YLimMode;
                    options.YLim = options.YLim(:,1:sz(2));
                    options.YLimMode = yLimMode;
                end
                szRatio = sz./size(options.YLim);
                if szRatio(1) == floor(szRatio(1))
                    yLimMode = options.YLimMode;
                    options.YLim = repmat(options.YLim,szRatio(1),1);
                    options.YLimMode = yLimMode;
                end
                if szRatio(2) == floor(szRatio(2))
                    yLimMode = options.YLimMode;
                    options.YLim = repmat(options.YLim,1,szRatio(2));
                    options.YLimMode = yLimMode;
                end
            end

            setoptions@controllib.chart.internal.foundation.AbstractPlot(this,options);

            % Update property editor widgets
            updateRowColumnLabelsFontWidget(this);
        end
    end

    %% Get/Set
    methods
        % XLimitsSharing
        function XLimitsSharing = get.XLimitsSharing(this)
            XLimitsSharing = this.XLimitsSharing_I;
        end

        function set.XLimitsSharing(this,XLimitsSharing)
            arguments
                this (1,1) controllib.chart.internal.foundation.RowColumnPlot
                XLimitsSharing (1,1) string {mustBeMember(XLimitsSharing,["all","column","none"])}
            end
            oldSharing = this.XLimitsSharing;
            oldSize = getXLimitsSize(this);

            this.XLimitsSharing_I = XLimitsSharing;

            newSize = getXLimitsSize(this);
            switch oldSharing
                case "all"
                    this.XLimits_I = repmat(this.XLimits_I,newSize./oldSize);
                    this.XLimitsMode_I = repmat(this.XLimitsMode_I,newSize./oldSize);
                case "column"
                    switch XLimitsSharing
                        case "all"
                            this.XLimits_I = repmat({[1 10]},newSize);
                            this.XLimitsMode_I = repmat({"auto"},newSize);
                        case "none"
                            this.XLimits_I = repmat(this.XLimits_I,newSize./oldSize);
                            this.XLimitsMode_I = repmat(this.XLimitsMode_I,newSize./oldSize);
                    end
                case "none"
                    this.XLimits_I = repmat({[1 10]},newSize);
                    this.XLimitsMode_I = repmat({"auto"},newSize);
            end

            % Update View
            if this.SyncChartWithAxesView && ~isempty(this.View) && isvalid(this.View)
                syncAxesGridXLimits(this.View);
            end

            updateXLimitsWidget(this);
        end

        % YLimitsSharing
        function YLimitsSharing = get.YLimitsSharing(this)
            YLimitsSharing = this.YLimitsSharing_I;
        end

        function set.YLimitsSharing(this,YLimitsSharing)
            arguments
                this (1,1) controllib.chart.internal.foundation.RowColumnPlot
                YLimitsSharing (1,1) string {mustBeMember(YLimitsSharing,["all","row","none"])}
            end
            oldSharing = this.YLimitsSharing;
            oldSize = getYLimitsSize(this);

            this.YLimitsSharing_I = YLimitsSharing;

            newSize = getYLimitsSize(this);
            switch oldSharing
                case "all"
                    this.YLimits_I = repmat(this.YLimits_I,newSize./oldSize);
                    this.YLimitsMode_I = repmat(this.YLimitsMode_I,newSize./oldSize);
                case "row"
                    switch YLimitsSharing
                        case "all"
                            this.YLimits_I = repmat({[1 10]},newSize);
                            this.YLimitsMode_I = repmat({"auto"},newSize);
                        case "none"
                            this.YLimits_I = repmat(this.YLimits_I,newSize./oldSize);
                            this.YLimitsMode_I = repmat(this.YLimitsMode_I,newSize./oldSize);
                    end
                case "none"
                    this.YLimits_I = repmat({[1 10]},newSize);
                    this.YLimitsMode_I = repmat({"auto"},newSize);
            end

            % Update View
            if this.SyncChartWithAxesView && ~isempty(this.View) && isvalid(this.View)
                syncAxesGridYLimits(this.View);
            end

            updateYLimitsWidget(this);
        end

        % RowVisible
        function RowVisible = get.RowVisible(this)
            RowVisible = this.RowVisible_I;
        end

        function set.RowVisible(this,RowVisible)
            arguments
                this (1,1) controllib.chart.internal.foundation.RowColumnPlot
                RowVisible (:,1) matlab.lang.OnOffSwitchState {validateRowSize(this,RowVisible)}
            end
            oldXLimitsSize = getXLimitsSize(this);
            oldYLimitsSize = getYLimitsSize(this);

            this.RowVisible_I = RowVisible;

            % Disable Axes ChildAdded listeners
            disableListeners(this,"ChildAddedToAxes");

            newXLimitsSize = getXLimitsSize(this);
            if newXLimitsSize(1) > oldXLimitsSize(1)
                this.XLimits_I = [this.XLimits_I;repmat({[1 10]},newXLimitsSize(1)-oldXLimitsSize(1),newXLimitsSize(2))];
                this.XLimitsMode_I = [this.XLimitsMode_I;repmat({"auto"},newXLimitsSize(1)-oldXLimitsSize(1),newXLimitsSize(2))];
            else
                this.XLimits_I = this.XLimits_I(1:newXLimitsSize(1),:);
                this.XLimitsMode_I = this.XLimitsMode_I(1:newXLimitsSize(1),:);
            end
            newYLimitsSize = getYLimitsSize(this);
            if newYLimitsSize(1) > oldYLimitsSize(1)
                this.YLimits_I = [this.YLimits_I;repmat({[1 10]},newYLimitsSize(1)-oldXLimitsSize(1),newYLimitsSize(2))];
                this.YLimitsMode_I = [this.YLimitsMode_I;repmat({"auto"},newYLimitsSize(1)-oldXLimitsSize(1),newYLimitsSize(2))];
            else
                this.YLimits_I = this.YLimits_I(1:newYLimitsSize(1),:);
                this.YLimitsMode_I = this.YLimitsMode_I(1:newYLimitsSize(1),:);
            end

            % Set RowVisible on View
            if this.SyncChartWithAxesView && ~isempty(this.View) && isvalid(this.View)
                syncAxesGridLayout(this.View);
            end

            % Update legend
            if strcmp(this.LegendAxesMode,"auto")
                updateLegendAxesInAutoMode(this);
            end
            setAxesForLegend(this);

            % Update data axes
            updateDataAxes(this);

            % Enable Axes ChildAdded listeners (for legend)
            enableListeners(this,"ChildAddedToAxes");

            updateYLimitsWidget(this);
        end

        % ColumnVisible
        function ColumnVisible = get.ColumnVisible(this)
            ColumnVisible = this.ColumnVisible_I;
        end

        function set.ColumnVisible(this,ColumnVisible)
            arguments
                this (1,1) controllib.chart.internal.foundation.RowColumnPlot
                ColumnVisible (1,:) matlab.lang.OnOffSwitchState {validateColumnSize(this,ColumnVisible)}
            end
            oldXLimitsSize = getXLimitsSize(this);
            oldYLimitsSize = getYLimitsSize(this);

            this.ColumnVisible_I = ColumnVisible;

            % Disable Axes ChildAdded listeners
            disableListeners(this,"ChildAddedToAxes");

            newXLimitsSize = getXLimitsSize(this);
            if newXLimitsSize(2) > oldXLimitsSize(2)
                this.XLimits_I = [this.XLimits_I repmat({[1 10]},newXLimitsSize(1),newXLimitsSize(2)-oldXLimitsSize(2))];
                this.XLimitsMode_I = [this.XLimitsMode_I repmat({"auto"},newXLimitsSize(1),newXLimitsSize(2)-oldXLimitsSize(2))];
            else
                this.XLimits_I = this.XLimits_I(:,1:newXLimitsSize(2));
                this.XLimitsMode_I = this.XLimitsMode_I(:,1:newXLimitsSize(2));
            end
            newYLimitsSize = getYLimitsSize(this);
            if newYLimitsSize(2) > oldYLimitsSize(2)
                this.YLimits_I = [this.YLimits_I repmat({[1 10]},newYLimitsSize(1),newYLimitsSize(2)-oldXLimitsSize(2))];
                this.YLimitsMode_I = [this.YLimitsMode_I repmat({"auto"},newYLimitsSize(1),newYLimitsSize(2)-oldXLimitsSize(2))];
            else
                this.YLimits_I = this.YLimits_I(:,1:newYLimitsSize(2));
                this.YLimitsMode_I = this.YLimitsMode_I(:,1:newYLimitsSize(2));
            end

            % Set ColumnVisible on View
            if this.SyncChartWithAxesView && ~isempty(this.View) && isvalid(this.View)
                syncAxesGridLayout(this.View);
            end

            % Update legend
            if strcmp(this.LegendAxesMode,"auto")
                updateLegendAxesInAutoMode(this);
            end
            setAxesForLegend(this);

            % Update data axes
            updateDataAxes(this);

            % Enable Axes ChildAdded listeners (for legend)
            enableListeners(this,"ChildAddedToAxes");

            updateXLimitsWidget(this);
        end

        function RowColumnGrouping = get.RowColumnGrouping(this)
            RowColumnGrouping = this.RowColumnGrouping_I;
        end

        function set.RowColumnGrouping(this,RowColumnGrouping)
            arguments
                this (1,1) controllib.chart.internal.foundation.RowColumnPlot
                RowColumnGrouping (1,1) string {mustBeMember(RowColumnGrouping,["none";"all";"columns";"rows"])}
            end
            oldXLimitsSize = getXLimitsSize(this);
            oldYLimitsSize = getYLimitsSize(this);

            this.RowColumnGrouping_I = RowColumnGrouping;

            % Disable Axes ChildAdded listeners
            disableListeners(this,"ChildAddedToAxes");

            newXLimitsSize = getXLimitsSize(this);
            if newXLimitsSize(1) > oldXLimitsSize(1)
                this.XLimits_I = [this.XLimits_I;repmat({[1 10]},newXLimitsSize(1)-oldXLimitsSize(1),oldXLimitsSize(2))];
                this.XLimitsMode_I = [this.XLimitsMode_I;repmat({"auto"},newXLimitsSize(1)-oldXLimitsSize(1),oldXLimitsSize(2))];
            else
                this.XLimits_I = this.XLimits_I(1:newXLimitsSize(1),:);
                this.XLimitsMode_I = this.XLimitsMode_I(1:newXLimitsSize(1),:);
            end
            newYLimitsSize = getYLimitsSize(this);
            if newYLimitsSize(1) > oldYLimitsSize(1)
                this.YLimits_I = [this.YLimits_I;repmat({[1 10]},newYLimitsSize(1)-oldXLimitsSize(1),oldXLimitsSize(2))];
                this.YLimitsMode_I = [this.YLimitsMode_I;repmat({"auto"},newYLimitsSize(1)-oldXLimitsSize(1),oldXLimitsSize(2))];
            else
                this.YLimits_I = this.YLimits_I(1:newYLimitsSize(1),:);
                this.YLimitsMode_I = this.YLimitsMode_I(1:newYLimitsSize(1),:);
            end
            if newXLimitsSize(2) > oldXLimitsSize(2)
                this.XLimits_I = [this.XLimits_I repmat({[1 10]},newXLimitsSize(1),newXLimitsSize(2)-oldXLimitsSize(2))];
                this.XLimitsMode_I = [this.XLimitsMode_I repmat({"auto"},newXLimitsSize(1),newXLimitsSize(2)-oldXLimitsSize(2))];
            else
                this.XLimits_I = this.XLimits_I(:,1:newXLimitsSize(2));
                this.XLimitsMode_I = this.XLimitsMode_I(:,1:newXLimitsSize(2));
            end
            if newYLimitsSize(2) > oldYLimitsSize(2)
                this.YLimits_I = [this.YLimits_I repmat({[1 10]},newYLimitsSize(1),newYLimitsSize(2)-oldXLimitsSize(2))];
                this.YLimitsMode_I = [this.YLimitsMode_I repmat({"auto"},newYLimitsSize(1),newYLimitsSize(2)-oldXLimitsSize(2))];
            else
                this.YLimits_I = this.YLimits_I(:,1:newYLimitsSize(2));
                this.YLimitsMode_I = this.YLimitsMode_I(:,1:newYLimitsSize(2));
            end

            % Update View
            if this.SyncChartWithAxesView && ~isempty(this.View) && isvalid(this.View)
                syncAxesGridLayout(this.View);
            end

            % Update legend
            if strcmp(this.LegendAxesMode,"auto")
                updateLegendAxesInAutoMode(this);
            end
            setAxesForLegend(this);

            % Update data axes
            updateDataAxes(this);

            % Enable Axes ChildAdded listeners (for legend)
            enableListeners(this,"ChildAddedToAxes");

            % Update property editor widget
            updateXLimitsWidget(this);
            updateYLimitsWidget(this);
        end

        % RowNames
        function RowNames = get.RowNames(this)
            RowNames = this.RowLabels.String;
        end

        function set.RowNames(this,RowNames)
            arguments
                this (1,1) controllib.chart.internal.foundation.RowColumnPlot
                RowNames (:,1) string {validateRowSize(this,RowNames)}
            end
            this.RowLabels.String = RowNames;
        end

        % ColumnNames
        function ColumnNames = get.ColumnNames(this)
            ColumnNames = this.ColumnLabels.String';
        end

        function set.ColumnNames(this,ColumnNames)
            arguments
                this (1,1) controllib.chart.internal.foundation.RowColumnPlot
                ColumnNames (1,:) string {validateColumnSize(this,ColumnNames)}
            end
            this.ColumnLabels.String = ColumnNames;
        end

        % NRows
        function NRows = get.NRows(this)
            NRows = this.NRows_I;
        end

        function set.NRows(this,NRows)
            this.NRows_I = NRows;
        end


        % NColumns
        function NColumns = get.NColumns(this)
            NColumns = this.NColumns_I;
        end

        function set.NColumns(this,NColumns)
            arguments
                this (1,1) controllib.chart.internal.foundation.RowColumnPlot
                NColumns (1,1) double {mustBePositive,mustBeInteger}
            end
            this.NColumns_I = NColumns;
        end

        % RowLabels
        function RowLabbels = get.RowLabels(this)
            RowLabbels = this.RowLabels_I;
        end

        function set.RowLabels(this,RowLabels)
            this.RowLabels_I = RowLabels;
        end

        % ColumnLabels
        function ColumnLabels = get.ColumnLabels(this)
            ColumnLabels = this.ColumnLabels_I;
        end

        function set.ColumnLabels(this,ColumnLabels)
            this.ColumnLabels_I = ColumnLabels;
        end
        % HasCustomRowNames
        function flag = get.HasCustomRowNames(this)
            flag = false;
            for ii = 1:length(this.RowNames)
                if ~strcmp(this.RowNames(ii),this.getDefaultRowNameForChannel(ii))
                    flag = true;
                    break;
                end
            end
        end

        % HasCustomColumnNames
        function flag = get.HasCustomColumnNames(this)
            flag = false;
            for ii = 1:length(this.ColumnNames)
                if ~strcmp(this.ColumnNames(ii),this.getDefaultColumnNameForChannel(ii))
                    flag = true;
                    break;
                end
            end
        end

        % SupportDynamicGridSize
        function set.SupportDynamicGridSize(this,SupportDynamicGridSize)
            this.SupportDynamicGridSize = SupportDynamicGridSize;
            for ii = 1:numel(this.Responses)
                if isa(this.Responses(ii),'controllib.chart.internal.foundation.ModelResponse')
                    this.Responses(ii).SupportDynamicIOSize = this.SupportDynamicGridSize;
                end
            end
            updateGridSize(this);
        end
    end

    methods(Access={?matlab.graphics.mixin.internal.Copyable, ?matlab.graphics.internal.CopyContext}, Hidden)
        function thisCopy = copyElement(this)
            if ~this.SupportDynamicGridSize
                error('The chart cannot be copied when SupportDynamicGridSize is false.')
            end
            thisCopy = copyElement@controllib.chart.internal.foundation.AbstractPlot(this);
        end
    end

    %% Protected methods
    methods (Access = protected)

        % Match Row/ColumnNames
        function matchRowNames(this,responses)
            arguments
                this (1,1) controllib.chart.internal.foundation.RowColumnPlot
                responses (:,1) controllib.chart.internal.foundation.BaseResponse
            end
            for k = 1:length(responses)
                if isa(responses(k),'controllib.chart.internal.foundation.MixInRowResponse')
                    matchRowIdx = this.matchChannelNames(responses(k).RowNames,this.RowNames);
                    if isvalid(responses(k))
                        responses(k).ResponseData.PlotOutputIdx = matchRowIdx;
                    end
                end
            end
        end

        function matchColumnNames(this,responses)
            arguments
                this (1,1) controllib.chart.internal.foundation.RowColumnPlot
                responses (:,1) controllib.chart.internal.foundation.BaseResponse
            end
            for k = 1:length(responses)
                if isa(responses(k),'controllib.chart.internal.foundation.MixInColumnResponse')
                    matchColumnIdx = this.matchChannelNames(responses(k).ColumnNames,this.ColumnNames);
                    if isvalid(responses(k))
                        responses(k).ResponseData.PlotInputIdx = matchColumnIdx;
                    end
                end
            end
        end

        function cbResponseChanged(this,response)
            updateGridSize(this);
            matchColumnNames(this,response);
            matchRowNames(this,response);
            cbResponseChanged@controllib.chart.internal.foundation.AbstractPlot(this,response);
        end

        function cbResponseDeleted(this)
            % Need to delete response and response views first before
            % adjusting grid size. Otherwise it triggers listeners on
            % ResponseViews that are being deleted.
            updateGridSize(this);
            cbResponseDeleted@controllib.chart.internal.foundation.AbstractPlot(this);
        end

        function updateGridSize(this,newResponses)
            arguments
                this (1,1) controllib.chart.internal.foundation.RowColumnPlot
                newResponses (:,1) controllib.chart.internal.foundation.BaseResponse = controllib.chart.internal.foundation.BaseResponse.empty
            end
            % Update size
            if ~this.SupportDynamicGridSize || ~isvalid(this)
                return;
            end
            oldSize = [this.NRows,this.NColumns];
            if isempty(this.Responses)
                responses = newResponses;
            else
                responses = [this.Responses(isvalid(this.Responses));newResponses];
            end
            isRCResponse = arrayfun(@(x) isa(x,'controllib.chart.internal.foundation.MixInRowResponse') &&...
                isa(x,'controllib.chart.internal.foundation.MixInColumnResponse'),responses);
            if ~isempty(responses)
                responses = responses(isRCResponse);
            end
            if isempty(responses)
                newSize = [1 1];
            else
                newSize = getAxesGridSize(this,responses);
            end
            if isequal(oldSize,newSize)
                return;
            end

            % Update RowNames and ColumnNames - if no. of
            % rows/columns has increased, use the new responses to
            % get names for the new channel (uses default if all
            % responses do not have same row/column name).
            this.NRows_I = newSize(1);
            this.NColumns_I = newSize(2);
            this.RowLabels.NumStrings = newSize(1);
            this.ColumnLabels.NumStrings = newSize(2);

            if ~isempty(this.View) && isvalid(this.View)
                % View already exists

                updateAxesGridSize(this.View);
                % RowNames
                if newSize(1) > oldSize(1)
                    % Initialize row names because new rows have been added
                    initializeNewRowNames(this,newSize(1),oldSize(1),responses);
                else
                    % Rows have not been added. Notify event of RowLabel
                    % changed. No need to update RowNames
                    ed = controllib.chart.internal.utils.GenericEventData;
                    addprop(ed,"PropertyChanged");
                    ed.PropertyChanged = "String";
                    notify(this.RowLabels,'LabelChanged',ed);
                end
                % ColumnNames
                if newSize(2) > oldSize(2)
                    % Initialize column names because new columns have been
                    % added
                    initializeNewColumnNames(this,newSize(2),oldSize(2),responses);
                else
                    % Columns have not been added. Only notify event of
                    % ColumnLabel changed
                    ed = controllib.chart.internal.utils.GenericEventData;
                    addprop(ed,"PropertyChanged");
                    ed.PropertyChanged = "String";
                    notify(this.ColumnLabels,'LabelChanged',ed);
                end
            else
                % View has not been created
                xLimToSet = this.XLimits_I;
                xLimModeToSet = this.XLimitsMode_I;
                xLimFocusToSet = this.XLimitsFocus;
                yLimToSet = this.YLimits_I;
                yLimModeToSet = this.YLimitsMode_I;
                yLimFocusToSet = this.YLimitsFocus;
                sz = getVisibleAxesSize(this);
                subgridSize = sz./[nnz(this.RowVisible) nnz(this.ColumnVisible)];
                if isinf(subgridSize(1))
                    subgridSize(1) = 0;
                end
                if isinf(subgridSize(2))
                    subgridSize(2) = 0;
                end

                if newSize(1) > oldSize(1)
                    % Rows being added
                    if isempty(this.Responses) && isscalar(responses)
                        % First response being added - set Plot row names
                        % to be same as response row names (if custom)
                        for k = 1:length(responses.RowNames)
                            if ~strcmp(responses.RowNames(k),"")
                                this.RowNames(k) = responses.RowNames(k);
                            end
                        end
                    else
                        % Initialize using row names from new response
                        initializeNewRowNames(this,newSize(1),oldSize(1),responses);
                    end

                    % Initialize ylimits and ylimits focus for new rows
                    nNewRows = newSize(1) - oldSize(1);
                    this.RowVisible = [this.RowVisible;true(nNewRows,1)];
                    if strcmp(this.RowColumnGrouping,"none") || strcmp(this.RowColumnGrouping,"columns")
                        switch this.XLimitsSharing
                            case "none"
                                xLimToSet = [xLimToSet;repmat({[1 10]},nNewRows,size(xLimToSet,2))];
                                xLimModeToSet = [xLimModeToSet;repmat({"auto"},nNewRows,size(xLimModeToSet,2))];
                        end
                        switch this.YLimitsSharing
                            case {"row","none"}
                                yLimToSet = [yLimToSet;repmat({[1 10]},nNewRows*subgridSize(1),size(yLimToSet,2))];
                                yLimModeToSet = [yLimModeToSet;repmat({"auto"},nNewRows*subgridSize(1),size(yLimModeToSet,2))];
                        end
                    end
                    xLimFocusToSet = [xLimFocusToSet;repmat({[1 10]},nNewRows,size(xLimFocusToSet,2))];
                    yLimFocusToSet = [yLimFocusToSet;repmat({[1 10]},nNewRows*subgridSize(1),size(yLimFocusToSet,2))];
                else
                    % No new rows added
                    ed = controllib.chart.internal.utils.GenericEventData;
                    addprop(ed,"PropertyChanged");
                    ed.PropertyChanged = "String";
                    notify(this.RowLabels,'LabelChanged',ed);
                    this.RowVisible = this.RowVisible(1:newSize(1));
                    if strcmp(this.RowColumnGrouping,"none") || strcmp(this.RowColumnGrouping,"columns")
                        switch this.XLimitsSharing
                            case "none"
                                xLimToSet = xLimToSet(1:newSize(1),:);
                                xLimModeToSet = xLimModeToSet(1:newSize(1),:);
                        end
                        switch this.YLimitsSharing
                            case {"row","none"}
                                yLimToSet = yLimToSet(1:newSize(1)*subgridSize(1),:);
                                yLimModeToSet = yLimModeToSet(1:newSize(1)*subgridSize(1),:);
                        end
                    end
                    xLimFocusToSet = xLimFocusToSet(1:newSize(1),:);
                    yLimFocusToSet = yLimFocusToSet(1:newSize(1)*subgridSize(1),:);
                end

                if newSize(2) > oldSize(2)
                    % Columns being added
                    if isempty(this.Responses) && isscalar(responses)
                        % First response being added - set Plot column names
                        % to be same as response column names (if custom)
                        for k = 1:length(responses.ColumnNames)
                            if ~strcmp(responses.ColumnNames(k),"")
                                this.ColumnNames(k) = responses.ColumnNames(k);
                            end
                        end
                    else
                        % Initialize using column names from new response
                        initializeNewColumnNames(this,newSize(2),oldSize(2),responses);
                    end

                    % Initialize xlimits and xlimits focus for new columns
                    nNewColumns = newSize(2) - oldSize(2);
                    this.ColumnVisible = [this.ColumnVisible,true(1,nNewColumns)];
                    if strcmp(this.RowColumnGrouping,"none") || strcmp(this.RowColumnGrouping,"rows")
                        switch this.XLimitsSharing
                            case {"column","none"}
                                xLimToSet = [xLimToSet repmat({[1 10]},size(xLimToSet,1),nNewColumns*subgridSize(2))];
                                xLimModeToSet = [xLimModeToSet repmat({"auto"},size(xLimModeToSet,1),nNewColumns*subgridSize(2))];
                        end
                        switch this.YLimitsSharing
                            case "none"
                                yLimToSet = [yLimToSet repmat({[1 10]},size(yLimToSet,1),nNewColumns)];
                                yLimModeToSet = [yLimModeToSet repmat({"auto"},size(yLimModeToSet,1),nNewColumns)];
                        end
                    end
                    xLimFocusToSet = [xLimFocusToSet repmat({[1 10]},size(xLimFocusToSet,1),nNewColumns*subgridSize(2))];
                    yLimFocusToSet = [yLimFocusToSet repmat({[1 10]},size(yLimFocusToSet,1),nNewColumns)];
                else
                    % No columns added
                    ed = controllib.chart.internal.utils.GenericEventData;
                    addprop(ed,"PropertyChanged");
                    ed.PropertyChanged = "String";
                    notify(this.ColumnLabels,'LabelChanged',ed);
                    this.ColumnVisible = this.ColumnVisible(1:newSize(2));
                    if strcmp(this.RowColumnGrouping,"none") || strcmp(this.RowColumnGrouping,"rows")
                        switch this.XLimitsSharing
                            case {"column","none"}
                                xLimToSet = xLimToSet(:,1:newSize(2)*subgridSize(2));
                                xLimModeToSet = xLimModeToSet(:,1:newSize(2)*subgridSize(2));
                        end
                        switch this.YLimitsSharing
                            case "none"
                                yLimToSet = yLimToSet(:,1:newSize(2));
                                yLimModeToSet = yLimModeToSet(:,1:newSize(2));
                        end
                    end
                    xLimFocusToSet = xLimFocusToSet(:,1:newSize(2)*subgridSize(2));
                    yLimFocusToSet = yLimFocusToSet(:,1:newSize(2));
                end
                this.XLimits = xLimToSet;
                this.XLimitsMode = xLimModeToSet;
                this.YLimits = yLimToSet;
                this.YLimitsMode = yLimModeToSet;
                xFocusFromResponses = this.XLimitsFocusFromResponses;
                this.XLimitsFocus = xLimFocusToSet;
                this.XLimitsFocusFromResponses = xFocusFromResponses;
                yFocusFromResponses = this.YLimitsFocusFromResponses;
                this.YLimitsFocus = yLimFocusToSet;
                this.YLimitsFocusFromResponses = yFocusFromResponses;
            end

            % Match Response I/O names to the chart I/O names
            matchColumnNames(this,responses);
            matchRowNames(this,responses);

            % Update legend position
            if strcmp(this.LegendAxesMode,"auto")
                updateLegendAxesInAutoMode(this);
            else
                this.LegendAxes = [min(this.LegendAxes(1),this.NRows) min(this.LegendAxes(2),this.NColumns)];
            end

            % Update data axes
            updateDataAxes(this);

            notify(this,'GridSizeChanged');
        end

        function newSize = getAxesGridSize(this,responses)
            % getAxesGridSize computes the grid size of axes based on the
            % responses.
            %
            % RowColumnPlot implementation is to look at maximum of NRows
            % and NColumns of all provided responses.
            %
            % Sub classes can override to implement different behavior.
            %
            %   newSize = getAxesGridSize(RowColumnPlot,responses)
            arguments
                this %#ok<INUSA>
                responses = this.Responses
            end
            if isempty(responses)
                newSize = [1 1];
            else
                newSize = max([max(arrayfun(@(x) x.NRows,responses)) max(arrayfun(@(x) x.NColumns,responses))],1);
            end
        end

        function initializeNewRowNames(this,NRows,oldNRows,responses)
            % initializeNewRowNames sets RowNames for the new rows added as
            % a result of registering a new response.
            %
            %   initializeNewRowNames(RowColumnPlot,NRows,oldNRows,responses)
            %
            % RowColumnPlot uses RowNames from new responses if their
            % RowNames for the new rows are same.

            nNewRows = NRows-oldNRows;
            newRowNames = strings(nNewRows,1);
            for k = 1:nNewRows
                responseNRows = arrayfun(@(x) x.NRows,responses);
                responsesForRowName = responses(responseNRows >= k+oldNRows);
                allNewRowNames = [responsesForRowName.RowNames(k+oldNRows)];
                uniqueRowNames = unique(allNewRowNames);
                if isscalar(uniqueRowNames) && ~strcmp(uniqueRowNames,"")
                    newRowNames(k) = uniqueRowNames;
                else
                    newRowNames(k) = this.getDefaultRowNameForChannel(k+oldNRows);
                end
            end
            this.RowNames(end-nNewRows+1:end) = newRowNames;
        end

        function initializeNewColumnNames(this,NColumns,oldNColumns,responses)
            % initializeNewColumnNames sets ColumnNames when AxesView is not built,
            % using the information from the responses.
            %
            % RowColumnPlot uses RowNames from new responses if their
            % ColumnNames for the new rows are same.

            nNewColumns = NColumns-oldNColumns;
            newColumnNames = strings(1,nNewColumns);
            for k = 1:nNewColumns
                responseNColumns = arrayfun(@(x) x.NColumns,responses);
                responsesForColumnName = responses(responseNColumns >= k+oldNColumns);
                allNewColumnNames = [responsesForColumnName.ColumnNames(k+oldNColumns)];
                uniqueColumnNames = unique(allNewColumnNames);
                if isscalar(uniqueColumnNames) && ~strcmp(uniqueColumnNames,"")
                    newColumnNames(k) = uniqueColumnNames;
                else
                    newColumnNames(k) = this.getDefaultColumnNameForChannel(k+oldNColumns);
                end
            end
            this.ColumnNames(end-nNewColumns+1:end) = newColumnNames;
        end

        function postLoadInitialization(thisLoaded)
            % Load visibility
            thisLoaded.RowVisible = thisLoaded.SavedValues.RowVisible;
            thisLoaded.ColumnVisible = thisLoaded.SavedValues.ColumnVisible;
            % Load limits
            thisLoaded.XLimitsSharing = thisLoaded.SavedValues.XLimitsSharing;
            thisLoaded.YLimitsSharing = thisLoaded.SavedValues.YLimitsSharing;
            postLoadInitialization@controllib.chart.internal.foundation.AbstractPlot(thisLoaded);
            % Load labels
            labelProps = controllib.chart.internal.options.AxesLabel.getCopyableProperties();
            for ii = 1:length(labelProps)
                thisLoaded.RowLabels.(labelProps(ii)) = thisLoaded.SavedValues.Labels.RowLabels.(labelProps(ii));
                thisLoaded.ColumnLabels.(labelProps(ii)) = thisLoaded.SavedValues.Labels.ColumnLabels.(labelProps(ii));
            end
        end

        function postCopyInitialization(this,thisCopy)
            % Copy visibility
            thisCopy.RowVisible = this.RowVisible;
            thisCopy.ColumnVisible = this.ColumnVisible;
            % Copy limits
            thisCopy.XLimitsSharing = this.XLimitsSharing;
            thisCopy.YLimitsSharing = this.YLimitsSharing;
            postCopyInitialization@controllib.chart.internal.foundation.AbstractPlot(this,thisCopy);
            % Copy labels
            labelProps = controllib.chart.internal.options.AxesLabel.getCopyableProperties();
            for ii = 1:length(labelProps)
                thisCopy.RowLabels.(labelProps(ii)) = this.RowLabels.(labelProps(ii));
                thisCopy.ColumnLabels.(labelProps(ii)) = this.ColumnLabels.(labelProps(ii));
            end
        end

        function createLabels(this)
            createLabels@controllib.chart.internal.foundation.AbstractPlot(this);
            this.RowLabels_I = controllib.chart.internal.options.AxesLabel(this.NRows,Chart=this,Rotation=90);
            this.ColumnLabels_I = controllib.chart.internal.options.AxesLabel(this.NColumns,Chart=this);

            rowNames = strings(this.NRows,1);
            for ii = 1:this.NRows
                rowNames(ii) = this.getDefaultRowNameForChannel(ii);
            end
            this.RowNames = rowNames;
            columnNames = strings(1,this.NColumns);
            for ii = 1:this.NColumns
                columnNames(ii) = this.getDefaultColumnNameForChannel(ii);
            end
            this.ColumnNames = columnNames;

            L = addlistener(this.RowLabels,"LabelChanged",@(es,ed) cbLabelChanged(this,es,ed,"RowLabels"));
            registerListeners(this,L,"RowLabelsChanged");
            L = addlistener(this.ColumnLabels,"LabelChanged",@(es,ed) cbLabelChanged(this,es,ed,"ColumnLabels"));
            registerListeners(this,L,"ColumnLabelsChanged");
        end

        function cbLabelChanged(this,es,ed,labelType)
            switch labelType
                case 'RowLabels'
                    % Update View
                    if this.SyncChartWithAxesView && ~isempty(this.View) && isvalid(this.View)
                        syncAxesGridLabels(this.View);
                    end
                    if ~isempty(this.Responses)
                        matchRowNames(this,this.Responses);
                    end
                    updateRowColumnLabelsFontWidget(this);
                case 'ColumnLabels'
                    % Update View
                    if this.SyncChartWithAxesView && ~isempty(this.View) && isvalid(this.View)
                        syncAxesGridLabels(this.View);
                    end
                    if ~isempty(this.Responses)
                        matchColumnNames(this,this.Responses);
                    end
                    updateRowColumnLabelsFontWidget(this);
                otherwise
                    cbLabelChanged@controllib.chart.internal.foundation.AbstractPlot(this,es,ed,labelType);
            end
        end

        function createContextMenu(this)
            createContextMenu@controllib.chart.internal.foundation.AbstractPlot(this);

            rowColumnGroupingMenuText = this.getRowColumnGroupingMenuText();
            [inputText,outputText] = this.getRowColumnGroupingSubMenuText();
            rowColumnSelectorMenuText = this.getRowColumnSelectorMenuText();

            % RowColumnGrouping
            this.RowColumnGroupingMenu = uimenu(Parent=[],...
                Text=rowColumnGroupingMenuText,...
                Separator="on",...
                Tag='iogrouping');
            this.RowColumnGroupingSubMenu = matlab.ui.container.Menu.empty;
            this.RowColumnGroupingSubMenu(1) = uimenu(this.RowColumnGroupingMenu,...
                Text=getString(message('Controllib:plots:strNone')),...
                Checked=strcmp(this.RowColumnGrouping,"none"),...
                Tag="none",...
                MenuSelectedFcn=@(es,ed) set(this,RowColumnGrouping="none"));
            this.RowColumnGroupingSubMenu(2) = uimenu(this.RowColumnGroupingMenu,...
                Text=getString(message('Controllib:plots:strAll')),...
                Checked=strcmp(this.RowColumnGrouping,"all"),...
                Tag="all",...
                MenuSelectedFcn=@(es,ed) set(this,RowColumnGrouping="all"));
            this.RowColumnGroupingSubMenu(3) = uimenu(this.RowColumnGroupingMenu,...
                Text=inputText,...
                Checked=strcmp(this.RowColumnGrouping,"columns"),...
                Tag="columns",...
                MenuSelectedFcn=@(es,ed) set(this,RowColumnGrouping="columns"));
            this.RowColumnGroupingSubMenu(4) = uimenu(this.RowColumnGroupingMenu,...
                Text=outputText,...
                Checked=strcmp(this.RowColumnGrouping,"rows"),...
                Tag="rows",...
                MenuSelectedFcn=@(es,ed) set(this,RowColumnGrouping="rows"));

            % RowColumnSelector
            this.RowColumnSelectorMenu = uimenu(Parent=[],...
                Text=rowColumnSelectorMenuText,...
                MenuSelectedFcn=@(es,ed) showRowColumnSelector(this.View),...
                Tag='ioselector');

            % Parent
            addMenu(this,this.RowColumnGroupingMenu,Above='arrayselector',CreateNewSection=false);
            addMenu(this,this.RowColumnSelectorMenu,Above='arrayselector',CreateNewSection=false);
        end

        function cbContextMenuOpening(this)
            % Call base class method
            cbContextMenuOpening@controllib.chart.internal.foundation.AbstractPlot(this);

            this.RowColumnGroupingMenu.Visible = this.NColumns > 1 || this.NRows > 1;
            this.RowColumnSelectorMenu.Visible = this.NColumns > 1 || this.NRows > 1;
            for k = 1:4
                this.RowColumnGroupingSubMenu(k).Checked = ...
                    strcmp(this.RowColumnGrouping,this.RowColumnGroupingSubMenu(k).Tag);
            end
        end

        function groupNames = getGroupNamesForXLimitsWidget(this)
            allStr = string(getString(message('Controllib:gui:strAll')));
            switch this.RowColumnGrouping
                case {"all","rows"}
                    groupNames = allStr;
                otherwise
                    groupNames = [allStr, this.ColumnNames(this.ColumnVisible)];
                    if numel(groupNames) == 2
                        groupNames = allStr;
                    end
            end
        end

        function buildXLimitsWidget(this)
            buildXLimitsWidget@controllib.chart.internal.foundation.AbstractPlot(this);
            names = getGroupNamesForXLimitsWidget(this);
            if length(names) > 1 && ~strcmp(this.XLimitsSharing,"all")
                this.XLimitsWidget.SelectedGroup = names(2);
            end
        end

        % Local callback functions
        function cbXLimitsChangedInPropertyEditor(this,es,ed)
            disableListeners(this,'XLimitsChangedInPropertyEditor');
            this.XLimitsWidget.Enable = false;
            limitsWidget = ed.AffectedObject;
            switch es.Name
                case 'AutoScale'
                    value = limitsWidget.AutoScale;
                    if value
                        xLimMode = "auto";
                    else
                        xLimMode = "manual";
                    end

                    switch limitsWidget.SelectedGroupIdx
                        case 1
                            % Set xLimMode for all
                            this.XLimitsSharing = "all";
                            this.XLimitsMode = xLimMode;
                        otherwise
                            % Set xLimMode for specific column
                            this.XLimitsSharing = "column";
                            this.XLimitsMode{limitsWidget.SelectedGroupIdx-1} = xLimMode;
                    end
                    this.XLimitsWidget.Enable = true;
                    updateXLimitsWidget(this);
                case 'Limits'
                    limits = limitsWidget.Limits{1};
                    % NaN limits indicate the different group limits are not equal and
                    % common group is selected
                    if ~any(isnan(limits))
                        switch limitsWidget.SelectedGroupIdx
                            case 1
                                % Common group selected and all limits are equal
                                this.XLimitsSharing = "all";
                                this.XLimits = limits;
                            otherwise
                                % Set for individual group
                                this.XLimitsSharing = "column";
                                this.XLimits{limitsWidget.SelectedGroupIdx-1} = limits;
                        end
                        this.XLimitsWidget.Enable = true;
                        updateXLimitsWidget(this);
                    else
                        this.XLimitsWidget.Enable = true;
                    end
            end
            enableListeners(this,'XLimitsChangedInPropertyEditor');
        end

        function updateXLimitsWidget(this)
            if ~isempty(this.XLimitsWidget) && isvalid(this.XLimitsWidget) && this.XLimitsWidget.Enable
                names = getGroupNamesForXLimitsWidget(this);
                this.XLimitsWidget.NGroups = length(names);
                this.XLimitsWidget.GroupItems = names;
                if any(this.RowVisible) && any(this.ColumnVisible)
                    switch this.RowColumnGrouping
                        case {"all","rows"}
                            setLimits(this.XLimitsWidget,this.XLimits_I{1});
                            setAutoScale(this.XLimitsWidget,strcmp(this.XLimitsMode_I{1},"auto"));
                        otherwise
                            switch this.XLimitsSharing
                                case "all"
                                    setLimits(this.XLimitsWidget,this.XLimits_I{1});
                                    setAutoScale(this.XLimitsWidget,strcmp(this.XLimitsMode_I{1},"auto"));
                                    for ii = 2:this.XLimitsWidget.NGroups
                                        setLimits(this.XLimitsWidget,this.XLimits_I{1},ii);
                                        setAutoScale(this.XLimitsWidget,false,ii);
                                    end
                                case "column"
                                    if this.XLimitsWidget.NGroups == 1
                                        setLimits(this.XLimitsWidget,this.XLimits_I{1});
                                        setAutoScale(this.XLimitsWidget,strcmp(this.XLimitsMode_I{1},"auto"));
                                    else
                                        setLimits(this.XLimitsWidget,[NaN NaN],1);
                                        setAutoScale(this.XLimitsWidget,false,1);
                                        for ii = 2:this.XLimitsWidget.NGroups
                                            setLimits(this.XLimitsWidget,this.XLimits_I{ii-1},ii);
                                            setAutoScale(this.XLimitsWidget,strcmp(this.XLimitsMode_I{ii-1},"auto"),ii);
                                        end
                                    end
                                case "none"
                                    for ii = 1:this.XLimitsWidget.NGroups
                                        setLimits(this.XLimitsWidget,[NaN NaN],ii);
                                        setAutoScale(this.XLimitsWidget,false,ii);
                                    end
                            end
                    end
                end
            end
        end

        function groupNames = getGroupNamesForYLimitsWidget(this)
            allStr = string(getString(message('Controllib:gui:strAll')));
            switch this.RowColumnGrouping
                case {"all","columns"}
                    groupNames = allStr;
                otherwise
                    groupNames = [allStr; this.RowNames(this.RowVisible)];
                    if numel(groupNames) == 2
                        groupNames = allStr;
                    end
            end
        end

        function buildYLimitsWidget(this)
            buildYLimitsWidget@controllib.chart.internal.foundation.AbstractPlot(this);
            names = getGroupNamesForYLimitsWidget(this);
            if length(names) > 1 && ~strcmp(this.YLimitsSharing,"all")
                this.YLimitsWidget.SelectedGroup = names(2);
            end
        end

        function cbYLimitsChangedInPropertyEditor(this,es,ed)
            disableListeners(this,'YLimitsChangedInPropertyEditor');
            this.YLimitsWidget.Enable = false;
            limitsWidget = ed.AffectedObject;
            switch es.Name
                case 'AutoScale'
                    value = limitsWidget.AutoScale;
                    if value
                        yLimMode = "auto";
                    else
                        yLimMode = "manual";
                    end

                    switch limitsWidget.SelectedGroupIdx
                        case 1
                            % Set yLimMode for all
                            this.YLimitsSharing = "all";
                            this.YLimitsMode = yLimMode;
                        otherwise
                            % Set yLimMode for specific row
                            this.YLimitsSharing = "row";
                            this.YLimitsMode{limitsWidget.SelectedGroupIdx-1} = yLimMode;
                    end
                    this.YLimitsWidget.Enable = true;
                    updateYLimitsWidget(this);
                case 'Limits'
                    limits = limitsWidget.Limits{1};
                    % NaN limits indicate the different group limits are not equal and
                    % common group is selected
                    if ~any(isnan(limits))
                        switch limitsWidget.SelectedGroupIdx
                            case 1
                                % Common group selected and all limits are equal
                                this.YLimitsSharing = "all";
                                this.YLimits = limits;
                            otherwise
                                % Set for individual group
                                this.YLimitsSharing = "row";
                                this.YLimits{limitsWidget.SelectedGroupIdx-1} = limits;
                        end
                        this.YLimitsWidget.Enable = true;
                        updateYLimitsWidget(this);
                    else
                        this.YLimitsWidget.Enable = true;
                    end
            end
            enableListeners(this,'YLimitsChangedInPropertyEditor');
        end

        function updateYLimitsWidget(this)
            if ~isempty(this.YLimitsWidget) && isvalid(this.YLimitsWidget) && this.YLimitsWidget.Enable
                names = getGroupNamesForYLimitsWidget(this);
                this.YLimitsWidget.NGroups = length(names);
                this.YLimitsWidget.GroupItems = names;
                switch this.RowColumnGrouping
                    case {"all","columns"}
                        setLimits(this.YLimitsWidget,this.YLimits_I{1});
                        setAutoScale(this.YLimitsWidget,strcmp(this.YLimitsMode_I{1},"auto"));
                    otherwise
                        if any(this.RowVisible) && any(this.ColumnVisible)
                            switch this.YLimitsSharing
                                case "all"
                                    setLimits(this.YLimitsWidget,this.YLimits_I{1});
                                    setAutoScale(this.YLimitsWidget,strcmp(this.YLimitsMode_I{1},"auto"));
                                    for ii = 2:this.YLimitsWidget.NGroups
                                        setLimits(this.YLimitsWidget,this.YLimits_I{1},ii);
                                        setAutoScale(this.YLimitsWidget,false,ii);
                                    end
                                case "row"
                                    if this.YLimitsWidget.NGroups == 1
                                        setLimits(this.YLimitsWidget,this.YLimits_I{1});
                                        setAutoScale(this.YLimitsWidget,strcmp(this.YLimitsMode_I{1},"auto"));
                                    else
                                        setLimits(this.YLimitsWidget,[NaN NaN],1);
                                        setAutoScale(this.YLimitsWidget,false,1);
                                        for ii = 2:this.YLimitsWidget.NGroups
                                            setLimits(this.YLimitsWidget,this.YLimits_I{ii-1},ii);
                                            setAutoScale(this.YLimitsWidget,strcmp(this.YLimitsMode_I{ii-1},"auto"),ii);
                                        end
                                    end
                                case "none"
                                    for ii = 1:this.YLimitsWidget.NGroups
                                        setLimits(this.YLimitsWidget,[NaN NaN],ii);
                                        setAutoScale(this.YLimitsWidget,false,ii);
                                    end
                            end
                        end
                end
            end
        end

        function buildFontsWidget(this)
            buildFontsWidget@controllib.chart.internal.foundation.AbstractPlot(this);
            this.FontsWidget.LabelTypes = {'Title','XYLabels','IOLabels','AxesLabels'};
            this.FontsWidget.IOLabelsText = getString(message('Controllib:plots:strRowColumnLabels'));

            % Add listeners for change in widget
            registerListeners(this,...
                addlistener(this.FontsWidget,'IOLabelsFontSize',...
                'PostSet',@(es,ed) cbRowColumnLabelsFontSizeChangedInPropertyEditor(this)),...
                'RowColumnLabelsFontSizeChangedInPropertyEditor');
            registerListeners(this,...
                addlistener(this.FontsWidget,'IOLabelsFontWeight',...
                'PostSet',@(es,ed) cbRowColumnLabelsFontWeightChangedInPropertyEditor(this)),...
                'RowColumnLabelsFontWeightChangedInPropertyEditor');
            registerListeners(this,...
                addlistener(this.FontsWidget,'IOLabelsFontAngle',...
                'PostSet',@(es,ed) cbRowColumnLabelsFontAngleChangedInPropertyEditor(this)),...
                'RowColumnLabelsFontAngleChangedInPropertyEditor');

            updateRowColumnLabelsFontWidget(this);

            % Local Callbacks
            function cbRowColumnLabelsFontSizeChangedInPropertyEditor(this)
                disableListeners(this,'RowColumnLabelsFontSizeChangedInPropertyEditor');
                this.RowLabels.FontSize = this.FontsWidget.IOLabelsFontSize;
                this.ColumnLabels.FontSize = this.FontsWidget.IOLabelsFontSize;
                enableListeners(this,'RowColumnLabelsFontSizeChangedInPropertyEditor');
            end

            function cbRowColumnLabelsFontWeightChangedInPropertyEditor(this)
                disableListeners(this,'RowColumnLabelsFontWeightChangedInPropertyEditor');
                this.RowLabels.FontWeight = this.FontsWidget.IOLabelsFontWeight;
                this.ColumnLabels.FontWeight = this.FontsWidget.IOLabelsFontWeight;
                enableListeners(this,'RowColumnLabelsFontWeightChangedInPropertyEditor');
            end

            function cbRowColumnLabelsFontAngleChangedInPropertyEditor(this)
                disableListeners(this,'RowColumnLabelsFontAngleChangedInPropertyEditor');
                this.RowLabels.FontAngle = this.FontsWidget.IOLabelsFontAngle;
                this.ColumnLabels.FontAngle = this.FontsWidget.IOLabelsFontAngle;
                enableListeners(this,'RowColumnLabelsFontAngleChangedInPropertyEditor');
            end
        end

        function updateRowColumnLabelsFontWidget(this)
            if ~isempty(this.FontsWidget) && isvalid(this.FontsWidget)
                this.FontsWidget.IOLabelsFontSize = this.RowLabels_I.FontSize;
                this.FontsWidget.IOLabelsFontWeight = this.RowLabels_I.FontWeight;
                this.FontsWidget.IOLabelsFontAngle = this.RowLabels_I.FontAngle;
            end
        end

        function validateRowSize(this,value)
            controllib.chart.internal.utils.validators.mustBeSize(value,[this.NRows 1])
        end

        function validateColumnSize(this,value)
            controllib.chart.internal.utils.validators.mustBeSize(value,[1 this.NColumns])
        end

        function this = saveobj(this)
            if ~this.SupportDynamicGridSize
                error('The chart cannot be saved when SupportDynamicGridSize is false.')
            end
            this = saveobj@controllib.chart.internal.foundation.AbstractPlot(this);
            this.SavedValues.XLimitsSharing = this.XLimitsSharing;
            this.SavedValues.YLimitsSharing = this.YLimitsSharing;
            this.SavedValues.Labels.RowLabels = this.RowLabels;
            this.SavedValues.Labels.ColumnLabels = this.ColumnLabels;
            this.SavedValues.RowVisible = this.RowVisible;
            this.SavedValues.ColumnVisible = this.ColumnVisible;
        end

        function names = getStylePropertyGroupNames(this)
            names = getStylePropertyGroupNames@controllib.chart.internal.foundation.AbstractPlot(this);
            names = [names, getAdditionalStylePropertyGroupNames(this)];
        end

        function names = getAdditionalStylePropertyGroupNames(this)
            names = ["RowColumnGrouping","RowVisible","ColumnVisible"];
        end

        function focusAxes = mapDataAxesToFocusAxes(this,dataAxes)
            % mapDataAxesToFocusAxes computes the index to update the
            % XLimitsFocus and YLimitsFocus properties (accounting for all
            % axes) based on the index to add the data (accounting for only
            % visible axes)
            if strcmp(this.RowColumnGrouping,"all")
                focusAxes = [1 1];
            elseif strcmp(this.RowColumnGrouping,"column")
                rowIdx = find(this.RowVisible,dataAxes(1),'first');
                rowIdx = rowIdx(end);
                focusAxes = [rowIdx 1];
            elseif strcmp(this.RowColumnGrouping,"row")
                columnIdx = find(this.ColumnVisible,dataAxes(2),'first');
                columnIdx = columnIdx(end);
                focusAxes = [1 columnIdx];
            else
                rowIdx = find(this.RowVisible,dataAxes(1),'first');
                rowIdx = rowIdx(end);
                columnIdx = find(this.ColumnVisible,dataAxes(2),'first');
                columnIdx = columnIdx(end);
                focusAxes = [rowIdx columnIdx];
            end
        end
    end

    %% Static hidden methods
    methods (Static,Hidden)
        function options = createDefaultOptions()
            options = plotopts.RespPlotOptions;
        end
    end

    %% Static protected methods
    methods (Static,Access=protected)
        function names = getLimitPropertyGroupNames()
            names = controllib.chart.internal.foundation.AbstractPlot.getLimitPropertyGroupNames();
            names = [names,"XLimitsSharing","YLimitsSharing","RowLabels","ColumnLabels"];
        end



        function rowName = getDefaultRowNameForChannel(~)
            rowName = "";
        end

        function columnName = getDefaultColumnNameForChannel(~)
            columnName = "";
        end

        function idx = matchChannelNames(channelNames,allChannelNames)
            arguments
                channelNames (1,:) string
                allChannelNames (1,:) string
            end

            idx = 1:length(channelNames);
            if length(channelNames) > length(allChannelNames)
                channelNames = channelNames(1:length(allChannelNames));
            end

            if all(matches(channelNames,allChannelNames)) && ~all(strcmp(channelNames,"")) && ~all(strcmp(allChannelNames,""))
                for k = 1:length(channelNames)
                    idx(k) = find(strcmp(channelNames(k),allChannelNames));
                end
            end

        end

        function rcGroupingText = getRowColumnGroupingMenuText()
            rcGroupingText = getString(message('Controllib:plots:strRowColumnGrouping'));
        end

        function [columnText,rowText] = getRowColumnGroupingSubMenuText()
            columnText = getString(message('Controllib:plots:strColumns'));
            rowText = getString(message('Controllib:plots:strRows'));
        end

        function selectorMenuText = getRowColumnSelectorMenuText()
            selectorMenuText = getString(message('Controllib:plots:strRowColumnSelector'));
        end
    end

    %% Hidden methods
    methods (Hidden)
        function registerResponse(this,newResponse,newResponseView)
            arguments
                this (1,1) controllib.chart.internal.foundation.RowColumnPlot
                newResponse (1,1) controllib.chart.internal.foundation.BaseResponse
                newResponseView controllib.chart.internal.view.wave.BaseResponseView = ...
                    controllib.chart.internal.view.wave.BaseResponseView.empty
            end
            if ~this.SupportDynamicGridSize && (newResponse.NRows > this.NRows || newResponse.NColumns > this.NColumns)
                error(message('Controllib:plots:hold1'));
            end
            updateGridSize(this,newResponse);
            matchColumnNames(this,newResponse);
            matchRowNames(this,newResponse);
            if isa(newResponse,'controllib.chart.internal.foundation.ModelResponse')
                newResponse.SupportDynamicIOSize = this.SupportDynamicGridSize;
            end
            registerResponse@controllib.chart.internal.foundation.AbstractPlot(this,newResponse,newResponseView)
        end

        function dlg = qeOpenRowColumnSelector(this)
            showRowColumnSelector(this.View)
            dlg = qeGetRowColumnSelector(this.View);
        end

        function sz = getVisibleAxesSize(this)
            rowVisible = this.RowVisible;
            columnVisible = this.ColumnVisible;
            switch this.RowColumnGrouping
                case "none"
                    sz = [nnz(rowVisible) nnz(columnVisible)];
                case "columns"
                    sz = [nnz(rowVisible) any(columnVisible)];
                case "rows"
                    sz = [any(rowVisible) nnz(columnVisible)];
                case "all"
                    sz = [any(rowVisible) any(columnVisible)];
            end
            sz = double(sz);
        end

        function sz = getXLimitsSize(this)
            rowVisible = this.RowVisible;
            columnVisible = this.ColumnVisible;
            switch this.XLimitsSharing
                case "all"
                    sz = [any(rowVisible) any(columnVisible)];
                case "column"
                    sz = getVisibleAxesSize(this);
                    sz = [any(rowVisible) sz(2)];
                case "none"
                    sz = getVisibleAxesSize(this);
            end
            sz = double(sz);
        end

        function sz = getYLimitsSize(this)
            rowVisible = this.RowVisible;
            columnVisible = this.ColumnVisible;
            switch this.YLimitsSharing
                case "all"
                    sz = [any(rowVisible) any(columnVisible)];
                case "row"
                    sz = getVisibleAxesSize(this);
                    sz = [sz(1) any(columnVisible)];
                case "none"
                    sz = getVisibleAxesSize(this);
            end
            sz = double(sz);
        end
    end
end