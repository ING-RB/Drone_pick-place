classdef SingleColumnPlot < controllib.chart.internal.foundation.AbstractPlot
    % controllib.chart.internal.foundation.OutputPlot is a foundation class that is a node in the graphics
    % tree. All controls charts should subclass from this.
    %
    % h = OutputPlot(Name-Value)
    %
    %   NOutputs                number of outputs (used when SystemModels is not provided), default value is 1
    %   OutputNames             string array specifying output names (size must be consistent with NOutputs)
    %
    % Public properties:
    %   OutputVisible       matlab.lang.OnOffSwitchState vector for setting output visibility
    %   IOGrouping          string specifying how input/outputs are grouped together,
    %                       "none"|"outputs"
    %   OutputNames         string array for output names
    %
    % See controllib.chart.internal.foundation.AbstractPlot

    % Copyright 2023-2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent, SetObservable, AbortSet)
        XLimitsSharing
        YLimitsSharing
    end

    properties(Hidden, Dependent, SetObservable, AbortSet)
        % Show or hide specific inputs/outputs
        RowVisible
        RowGrouping

        RowNames
    end

    properties (Hidden, Dependent, SetAccess = private)
        NRows
        RowLabels
    end

    properties (Hidden,Dependent,SetAccess=private)
        HasCustomRowNames
    end

    properties (GetAccess=protected,SetAccess=private)
        RowGrouping_I = "none"
    end

    properties (Access = private,Transient,NonCopyable)
        XLimitsSharing_I = "all"
        YLimitsSharing_I = "none"
        NRows_I = 1
        RowVisible_I = matlab.lang.OnOffSwitchState(true)
        RowLabels_I
    end

    properties (Hidden,Transient,NonCopyable)
        SupportDynamicGridSize (1,1) logical = true
    end

    properties (Access=protected,Transient,NonCopyable)
        RowGroupingMenu
        RowGroupingSubMenu
        RowSelectorMenu
    end

    %% Events
    events
        GridSizeChanged
    end

    %% Constructor and public methods
    methods
        function this = SingleColumnPlot(optionalInputs,abstractPlotArguments)
            arguments
                optionalInputs.Options (1,1) plotopts.RespPlotOptions = controllib.chart.internal.foundation.SingleColumnPlot.createDefaultOptions()
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
                this (1,1) controllib.chart.internal.foundation.SingleColumnPlot
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
                end
                options.ColorMode.OutputLabels = this.RowLabels.ColorMode;
                options.OutputVisible = cellstr(this.RowVisible);
                options.IOGrouping = char(this.RowGrouping);
            else
                switch propertyName
                    case 'OutputLabels'
                        options = struct('FontSize',   this.RowLabels.FontSize, ...
                            'FontWeight', char(this.RowLabels.FontWeight), ...
                            'FontAngle',  char(this.RowLabels.FontAngle), ...
                            'Color',      this.RowLabels.Color, ...
                            'Interpreter', char(this.RowLabels.Interpreter));
                    case 'OutputVisible'
                        options = cellstr(this.RowVisible);
                    case 'IOGrouping'
                        options = char(this.RowGrouping);
                    case {'InputLabels','InputVisible'}
                        options = this.createDefaultOptions().(propertyName);
                    otherwise
                        options = getoptions@controllib.chart.internal.foundation.AbstractPlot(this,propertyName);
                end
            end
        end

        function setoptions(this,options)
            arguments
                this (1,1) controllib.chart.internal.foundation.SingleColumnPlot
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

            % "Fix" options visibiliy
            if length(options.OutputVisible) > this.NRows
                options.OutputVisible = options.OutputVisible(1:this.NRows);
            end
            if isscalar(options.OutputVisible)
                options.OutputVisible = repmat(options.OutputVisible,this.NRows,1);
            end

            % RowVisible
            try
                this.RowVisible = options.OutputVisible;
            catch
                warning(message('Controllib:plots:SetOptionsIncorrectSize','OutputVisible'))
            end

            % RowGrouping
            try %#ok<TRYNC>
                this.RowGrouping = options.IOGrouping;
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
            updateRowLabelsFontWidget(this);
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
                this (1,1) controllib.chart.internal.foundation.SingleColumnPlot
                XLimitsSharing (1,1) string {mustBeMember(XLimitsSharing,["all","none"])}
            end
            oldSharing = this.XLimitsSharing;
            oldSize = getXLimitsSize(this);

            this.XLimitsSharing_I = XLimitsSharing;

            newSize = getXLimitsSize(this);
            switch oldSharing
                case "all"
                    this.XLimits_I = repmat(this.XLimits_I,newSize./oldSize);
                    this.XLimitsMode_I = repmat(this.XLimitsMode_I,newSize./oldSize);
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
                this (1,1) controllib.chart.internal.foundation.SingleColumnPlot
                YLimitsSharing (1,1) string {mustBeMember(YLimitsSharing,["all","none"])}
            end
            oldSharing = this.YLimitsSharing;
            oldSize = getYLimitsSize(this);

            this.YLimitsSharing_I = YLimitsSharing;

            newSize = getYLimitsSize(this);
            switch oldSharing
                case "all"
                    this.YLimits_I = repmat(this.YLimits_I,newSize./oldSize);
                    this.YLimitsMode_I = repmat(this.YLimitsMode_I,newSize./oldSize);
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

        % NRows
        function NRows = get.NRows(this)
            NRows = this.NRows_I;
        end

        % RowNames
        function RowNames = get.RowNames(this)
            RowNames = this.RowLabels.String;
        end

        function set.RowNames(this,RowNames)
            arguments
                this (1,1) controllib.chart.internal.foundation.SingleColumnPlot
                RowNames (:,1) string {validateRowSize(this,RowNames)}
            end
            this.RowLabels.String = RowNames;
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

        % RowVisible
        function RowVisible = get.RowVisible(this)
            RowVisible = this.RowVisible_I;
        end

        function set.RowVisible(this,RowVisible)
            arguments
                this (1,1) controllib.chart.internal.foundation.SingleColumnPlot
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

            % Set OutputVisible on View
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

        % RowLabels
        function RowLabels = get.RowLabels(this)
            RowLabels = this.RowLabels_I;
        end

        % RowGrouping
        function RowGrouping = get.RowGrouping(this)
            RowGrouping = this.RowGrouping_I;
        end

        function set.RowGrouping(this,RowGrouping)
            arguments
                this (1,1) controllib.chart.internal.foundation.SingleColumnPlot
                RowGrouping (1,1) string {mustBeMember(RowGrouping,["none";"all"])}
            end
            oldXLimitsSize = getXLimitsSize(this);
            oldYLimitsSize = getYLimitsSize(this);
            
            this.RowGrouping_I = RowGrouping;

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
            updateYLimitsWidget(this);
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
        function matchRowNames(this,responses)
            arguments
                this (1,1) controllib.chart.internal.foundation.SingleColumnPlot
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

        function cbResponseChanged(this,response)
            updateGridSize(this);
            matchRowNames(this,response);
            cbResponseChanged@controllib.chart.internal.foundation.AbstractPlot(this,response);
        end

        function cbResponseDeleted(this)
            updateGridSize(this);
            cbResponseDeleted@controllib.chart.internal.foundation.AbstractPlot(this);
        end  

        function updateGridSize(this,newResponses)
            arguments
                this (1,1) controllib.chart.internal.foundation.SingleColumnPlot
                newResponses (:,1) controllib.chart.internal.foundation.BaseResponse = controllib.chart.internal.foundation.BaseResponse.empty
            end
            % Update size
            if ~this.SupportDynamicGridSize || ~isvalid(this)
                return;
            end
            oldSize = this.NRows;
            if isempty(this.Responses)
                responses = newResponses;
            else
                responses = [this.Responses(isvalid(this.Responses));newResponses];
            end
            isRowResponse = arrayfun(@(x) isa(x,'controllib.chart.internal.foundation.MixInRowResponse'),responses);
            if ~isempty(responses)
                responses = responses(isRowResponse);
            end
            if isempty(responses)
                newSize = 1;
            else
                newSize = max(max(arrayfun(@(x) x.NRows,responses)),1);
            end
            if isequal(oldSize,newSize)
                return;
            end

            % Update RowNames - if no. of rows has increased, use the new responses to
            % get names for the new channel (uses default if all
            % responses do not have same row name).
            this.NRows_I = newSize;
            this.RowLabels.NumStrings = newSize;

            if ~isempty(this.View) && isvalid(this.View)
                updateAxesGridSize(this.View);
                if newSize > oldSize
                    nNewRows = newSize-oldSize;
                    newRowNames = strings(nNewRows,1);
                    for k = 1:nNewRows
                        responseNRows = arrayfun(@(x) x.NRows,responses);
                        responsesForRowName = responses(responseNRows >= k+oldSize);
                        allNewRowNames = [responsesForRowName.RowNames(k+oldSize)];
                        uniqueRowNames = unique(allNewRowNames);
                        if isscalar(uniqueRowNames) && ~strcmp(uniqueRowNames,"")
                            newRowNames(k) = uniqueRowNames;
                        else
                            newRowNames(k) = this.getDefaultRowNameForChannel(k+oldSize);
                        end
                    end
                    this.RowNames(end-nNewRows+1:end) = newRowNames;
                else
                    ed = controllib.chart.internal.utils.GenericEventData;
                    addprop(ed,"PropertyChanged");
                    ed.PropertyChanged = "String";
                    notify(this.RowLabels,'LabelChanged',ed);
                end
            else
                xLimToSet = this.XLimits_I;
                xLimModeToSet = this.XLimitsMode_I;
                xLimFocusToSet = this.XLimitsFocus;
                yLimToSet = this.YLimits_I;
                yLimModeToSet = this.YLimitsMode_I;
                yLimFocusToSet = this.YLimitsFocus;
                sz = getVisibleAxesSize(this);
                subgridSize = sz./[nnz(this.RowVisible) 1];
                if isinf(subgridSize(1))
                    subgridSize(1) = 0;
                end
                if isinf(subgridSize(2))
                    subgridSize(2) = 0;
                end
                if newSize > oldSize
                    nNewRows = newSize-oldSize;
                    newRowNames = strings(nNewRows,1);
                    for k = 1:nNewRows
                        responseNRows = arrayfun(@(x) x.NRows,responses);
                        responsesForRowName = responses(responseNRows >= k+oldSize);
                        allNewRowNames = [responsesForRowName.RowNames(k+oldSize)];
                        uniqueRowNames = unique(allNewRowNames);
                        if isscalar(uniqueRowNames) && ~strcmp(uniqueRowNames,"")
                            newRowNames(k) = uniqueRowNames;
                        else
                            newRowNames(k) = this.getDefaultRowNameForChannel(k+oldSize);
                        end
                    end
                    this.RowNames(end-nNewRows+1:end) = newRowNames;
                    this.RowVisible = [this.RowVisible;true(nNewRows,1)];
                    if strcmp(this.RowGrouping,"none")
                        switch this.XLimitsSharing
                            case "none"
                                xLimToSet = [xLimToSet;repmat({[1 10]},nNewRows,size(xLimToSet,2))];
                                xLimModeToSet = [xLimModeToSet;repmat({"auto"},nNewRows,size(xLimModeToSet,2))];
                        end
                        switch this.YLimitsSharing
                            case "none"
                                yLimToSet = [yLimToSet;repmat({[1 10]},nNewRows*subgridSize(1),size(yLimToSet,2))];
                                yLimModeToSet = [yLimModeToSet;repmat({"auto"},nNewRows*subgridSize(1),size(yLimModeToSet,2))];
                        end
                    end
                    xLimFocusToSet = [xLimFocusToSet;repmat({[1 10]},nNewRows,size(xLimFocusToSet,2))];
                    yLimFocusToSet = [yLimFocusToSet;repmat({[1 10]},nNewRows*subgridSize(1),size(yLimFocusToSet,2))];
                else
                    ed = controllib.chart.internal.utils.GenericEventData;
                    addprop(ed,"PropertyChanged");
                    ed.PropertyChanged = "String";
                    notify(this.RowLabels,'LabelChanged',ed);
                    this.RowVisible = this.RowVisible(1:newSize);
                    if strcmp(this.RowGrouping,"none")
                        switch this.XLimitsSharing
                            case "none"
                                xLimToSet = xLimToSet(1:newSize(1),:);
                                xLimModeToSet = xLimModeToSet(1:newSize(1),:);
                        end
                        switch this.YLimitsSharing
                            case "none"
                                yLimToSet = yLimToSet(1:newSize(1)*subgridSize(1),:);
                                yLimModeToSet = yLimModeToSet(1:newSize(1)*subgridSize(1),:);
                        end
                    end
                    xLimFocusToSet = xLimFocusToSet(1:newSize(1),:);
                    yLimFocusToSet = yLimFocusToSet(1:newSize(1)*subgridSize(1),:);
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
            matchRowNames(this,responses);

            % Update legend position
            if strcmp(this.LegendAxesMode,"auto")
                updateLegendAxesInAutoMode(this);
            else
                this.LegendAxes(1) = min(this.LegendAxes(1),this.NRows);
            end

            % Update data axes
            updateDataAxes(this);

            notify(this,'GridSizeChanged');
        end

        function upgradeToLatestVersion(thisLoaded)
            if isVersionOlderThan(thisLoaded,"R2025a")
                % 25a - XLimitsSharing = "column" and YLimitsSharing = "row"
                % removed
                if strcmp(thisLoaded.SavedValues.XLimitsSharing,"column")
                    thisLoaded.SavedValues.XLimitsSharing = "all";
                end
                if strcmp(thisLoaded.SavedValues.YLimitsSharing,"row")
                    thisLoaded.SavedValues.YLimitsSharing = "none";
                end
            end
            upgradeToLatestVersion@controllib.chart.internal.foundation.AbstractPlot(thisLoaded);
        end

        function postLoadInitialization(thisLoaded)
            % Load visibility
            thisLoaded.RowVisible = thisLoaded.SavedValues.RowVisible;
            % Load limits
            thisLoaded.XLimitsSharing = thisLoaded.SavedValues.XLimitsSharing;
            thisLoaded.YLimitsSharing = thisLoaded.SavedValues.YLimitsSharing;
            postLoadInitialization@controllib.chart.internal.foundation.AbstractPlot(thisLoaded);
            % Load labels
            labelProps = controllib.chart.internal.options.AxesLabel.getCopyableProperties();
            for ii = 1:length(labelProps)
                thisLoaded.RowLabels.(labelProps(ii)) = thisLoaded.SavedValues.Labels.RowLabels.(labelProps(ii));
            end
        end

        function postCopyInitialization(this,thisCopy)
            % Copy visibility
            thisCopy.RowVisible = this.RowVisible;
            % Copy limits
            thisCopy.XLimitsSharing = this.XLimitsSharing;
            thisCopy.YLimitsSharing = this.YLimitsSharing;
            postCopyInitialization@controllib.chart.internal.foundation.AbstractPlot(this,thisCopy);
            % Copy labels
            labelProps = controllib.chart.internal.options.AxesLabel.getCopyableProperties();
            for ii = 1:length(labelProps)
                thisCopy.RowLabels.(labelProps(ii)) = this.RowLabels.(labelProps(ii));
            end
        end

        function createLabels(this)
            createLabels@controllib.chart.internal.foundation.AbstractPlot(this);
            this.RowLabels_I = controllib.chart.internal.options.AxesLabel(this.NRows,Chart=this,Rotation=90);

            rowNames = strings(this.NRows,1);
            for ii = 1:this.NRows
                rowNames(ii) = this.getDefaultRowNameForChannel(ii);
            end
            this.RowNames = rowNames;

            L = addlistener(this.RowLabels,"LabelChanged",@(es,ed) cbLabelChanged(this,es,ed,"RowLabels"));
            registerListeners(this,L,"RowLabelsChanged");
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
                    updateRowLabelsFontWidget(this);
                otherwise
                    cbLabelChanged@controllib.chart.internal.foundation.AbstractPlot(this,es,ed,labelType);
            end
        end

        function createContextMenu(this)
            createContextMenu@controllib.chart.internal.foundation.AbstractPlot(this);

            % OutputGrouping
            this.RowGroupingMenu = uimenu(Parent=[],...
                Text=getString(message('Controllib:plots:strRowGrouping')),...
                Tag='rowgrouping',...
                Separator="on");
            this.RowGroupingSubMenu = matlab.ui.container.Menu.empty;
            this.RowGroupingSubMenu(1) = uimenu(this.RowGroupingMenu,...
                Text=getString(message('Controllib:plots:strNone')),...
                Checked=strcmp(this.RowGrouping,"none"),...
                Tag="none",...
                MenuSelectedFcn=@(es,ed) set(this,RowGrouping="none"));
            this.RowGroupingSubMenu(2) = uimenu(this.RowGroupingMenu,...
                Text=getString(message('Controllib:plots:strAll')),...
                Checked=strcmp(this.RowGrouping,"all"),...
                Tag="all",...
                MenuSelectedFcn=@(es,ed) set(this,RowGrouping="all"));
            % OutputSelector
            this.RowSelectorMenu = uimenu(Parent=[],...
                Text=getString(message('Controllib:plots:strRowSelector')),...
                Tag='rowselector',...
                MenuSelectedFcn=@(es,ed) showRowSelector(this.View));

            % Parent
            addMenu(this,this.RowGroupingMenu,Above='arrayselector',CreateNewSection=false);
            addMenu(this,this.RowSelectorMenu,Above='arrayselector',CreateNewSection=false);
        end

        function cbContextMenuOpening(this)
            % Call base class method
            cbContextMenuOpening@controllib.chart.internal.foundation.AbstractPlot(this);

            this.RowGroupingMenu.Visible = this.NRows > 1;
            this.RowSelectorMenu.Visible = this.NRows > 1;
            for k = 1:2
                this.RowGroupingSubMenu(k).Checked = ...
                    strcmp(this.RowGrouping,this.RowGroupingSubMenu(k).Tag);
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

                    % Set xLimMode for all
                    this.XLimitsSharing = "all";
                    this.XLimitsMode = xLimMode;
                    
                    this.XLimitsWidget.Enable = true;
                    updateXLimitsWidget(this);
                case 'Limits'
                    limits = limitsWidget.Limits{1};
                    % NaN limits indicate the different group limits are not equal and
                    % common group is selected
                    if ~any(isnan(limits))
                        % Common group selected and all limits are equal
                        this.XLimitsSharing = "all";
                        this.XLimits = limits;
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
                switch this.RowGrouping
                    case "all"
                        setLimits(this.XLimitsWidget,this.XLimits_I{1});
                        setAutoScale(this.XLimitsWidget,strcmp(this.XLimitsMode_I{1},"auto"));
                    otherwise
                        if any(this.RowVisible)
                            switch this.XLimitsSharing
                                case "all"
                                    setLimits(this.XLimitsWidget,this.XLimits_I{1});
                                    setAutoScale(this.XLimitsWidget,strcmp(this.XLimitsMode_I{1},"auto"));
                                case "none"
                                    setLimits(this.XLimitsWidget,[NaN NaN]);
                                    setAutoScale(this.XLimitsWidget,false);
                            end
                        end
                end
            end
        end

        function groupNames = getGroupNamesForYLimitsWidget(this)
            allStr = string(getString(message('Controllib:gui:strAll')));
            switch this.RowGrouping
                case "all"
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
                            this.YLimitsSharing = "none";
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
                                this.YLimitsSharing = "none";
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
                switch this.RowGrouping
                    case "all"
                        setLimits(this.YLimitsWidget,this.YLimits_I{1});
                        setAutoScale(this.YLimitsWidget,strcmp(this.YLimitsMode_I{1},"auto"));
                    otherwise
                        if any(this.RowVisible)
                            switch this.YLimitsSharing
                                case "all"
                                    setLimits(this.YLimitsWidget,this.YLimits_I{1});
                                    setAutoScale(this.YLimitsWidget,strcmp(this.YLimitsMode_I{1},"auto"));
                                    for ii = 2:this.YLimitsWidget.NGroups
                                        setLimits(this.YLimitsWidget,this.YLimits_I{1},ii);
                                        setAutoScale(this.YLimitsWidget,false,ii);
                                    end
                                case {"row","none"}
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
                            end
                        end
                end
            end
        end

        function buildFontsWidget(this)
            % Build base class widget
            buildFontsWidget@controllib.chart.internal.foundation.AbstractPlot(this);
            this.FontsWidget.LabelTypes = {'Title','XYLabels','IOLabels','AxesLabels'};
            this.FontsWidget.IOLabelsText = getString(message('Controllib:plots:strRowLabels'));

            % Add listeners for change in widget
            registerListeners(this,...
                addlistener(this.FontsWidget,'IOLabelsFontSize',...
                'PostSet',@(es,ed) cbRowLabelsFontSizeChangedInPropertyEditor(this)),...
                'RowLabelsFontSizeChangedInPropertyEditor');
            registerListeners(this,...
                addlistener(this.FontsWidget,'IOLabelsFontWeight',...
                'PostSet',@(es,ed) cbRowLabelsFontWeightChangedInPropertyEditor(this)),...
                'RowLabelsFontWeightChangedInPropertyEditor');
            registerListeners(this,...
                addlistener(this.FontsWidget,'IOLabelsFontAngle',...
                'PostSet',@(es,ed) cbRowLabelsFontAngleChangedInPropertyEditor(this)),...
                'RowLabelsFontAngleChangedInPropertyEditor');

            updateRowLabelsFontWidget(this);

            % Local Callbacks
            function cbRowLabelsFontSizeChangedInPropertyEditor(this)
                disableListeners(this,'RowLabelsFontSizeChangedInPropertyEditor');
                this.RowLabels.FontSize = this.FontsWidget.IOLabelsFontSize;
                enableListeners(this,'RowLabelsFontSizeChangedInPropertyEditor');
            end

            function cbRowLabelsFontWeightChangedInPropertyEditor(this)
                disableListeners(this,'RowLabelsFontWeightChangedInPropertyEditor');
                this.RowLabels.FontWeight = this.FontsWidget.IOLabelsFontWeight;
                enableListeners(this,'RowLabelsFontWeightChangedInPropertyEditor');
            end

            function cbRowLabelsFontAngleChangedInPropertyEditor(this)
                disableListeners(this,'RowLabelsFontAngleChangedInPropertyEditor');
                this.RowLabels.FontAngle = this.FontsWidget.IOLabelsFontAngle;
                enableListeners(this,'RowLabelsFontAngleChangedInPropertyEditor');
            end
        end

        function updateRowLabelsFontWidget(this)
            if ~isempty(this.FontsWidget) && isvalid(this.FontsWidget)
                this.FontsWidget.IOLabelsFontSize = this.RowLabels_I.FontSize;
                this.FontsWidget.IOLabelsFontWeight = this.RowLabels_I.FontWeight;
                this.FontsWidget.IOLabelsFontAngle = this.RowLabels_I.FontAngle;
            end
        end

        function validateRowSize(this,value)
            controllib.chart.internal.utils.validators.mustBeSize(value,[this.NRows 1])
        end

        function this = saveobj(this)
            if ~this.SupportDynamicGridSize
                error('The chart cannot be saved when SupportDynamicGridSize is false.')
            end
            this = saveobj@controllib.chart.internal.foundation.AbstractPlot(this);
            this.SavedValues.XLimitsSharing = this.XLimitsSharing;
            this.SavedValues.YLimitsSharing = this.YLimitsSharing;
            this.SavedValues.Labels.RowLabels = this.RowLabels;
            this.SavedValues.RowVisible = this.RowVisible;
        end

        function names = getStylePropertyGroupNames(this)
            names = getStylePropertyGroupNames@controllib.chart.internal.foundation.AbstractPlot(this);
            names = [names,"RowGrouping","RowVisible"];
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
            names = [names,"XLimitsSharing","YLimitsSharing","RowLabels"];
        end

        function rowName = getDefaultRowNameForChannel(~)
            rowName = "";
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
    end

    %% Hidden methods
    methods (Hidden)
        function registerResponse(this,newResponse,newResponseView)
            arguments
                this (1,1) controllib.chart.internal.foundation.SingleColumnPlot
                newResponse (1,1) controllib.chart.internal.foundation.BaseResponse
                newResponseView controllib.chart.internal.view.wave.BaseResponseView = ...
                    controllib.chart.internal.view.wave.BaseResponseView.empty
            end
            if ~this.SupportDynamicGridSize && newResponse.NRows > this.NRows
                error(message('Controllib:plots:hold1'));
            end
            updateGridSize(this,newResponse);
            matchRowNames(this,newResponse);
            if isa(newResponse,'controllib.chart.internal.foundation.ModelResponse')
                newResponse.SupportDynamicIOSize = this.SupportDynamicGridSize;
            end
            registerResponse@controllib.chart.internal.foundation.AbstractPlot(this,newResponse,newResponseView)
        end

        function dlg = qeOpenRowSelector(this)
            showRowSelector(this.View)
            dlg = qeGetRowSelector(this.View);
        end

        function sz = getVisibleAxesSize(this)
            rowVisible = this.RowVisible;
            switch this.RowGrouping
                case "none"
                    sz = [nnz(rowVisible) 1];
                case "all"
                    sz = [any(rowVisible) 1];
            end
            sz = double(sz);
        end

        function sz = getXLimitsSize(this)
            switch this.XLimitsSharing
                case "all"
                    sz = [1 1];
                case "none"
                    sz = getVisibleAxesSize(this);
            end
        end

        function sz = getYLimitsSize(this)
            switch this.YLimitsSharing
                case "all"
                    sz = [1 1];
                case "none"
                    sz = getVisibleAxesSize(this);
            end
        end
    end
end