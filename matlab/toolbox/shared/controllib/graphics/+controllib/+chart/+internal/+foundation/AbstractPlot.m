classdef (Abstract) AbstractPlot < ...
        matlab.graphics.chartcontainer.ChartContainer & ...
        matlab.graphics.mixin.CustomChildrenContainer & ...
        controllib.chart.internal.foundation.MixInListeners & ...
        matlab.mixin.CustomDisplay & ...
        matlab.mixin.SetGet
    % controllib.chart.internal.foundation.AbstractPlot is a foundation class that is a node in the graphics
    % tree. All controls charts should subclass from this.
    %
    % h = AbstractPlot(Name-Value)
    %
    %   Axes    Any axes objects to use for constructing view
    %   Parent                  Parent object of AbstractPlot (used if Axes is empty)
    %   SystemModels            cell array of DynamicSystem objects used to initialize the chart
    %                           number of inputs/outputs derived from SystemModels provided
    %   SystemNames             string array of names for SystemModels
    %   Title                   string specifying title of chart
    %   XLabel                  string specifying xlabel of chart
    %   YLabel                  string specifying ylabel of chart
    %
    % Public properties:
    %
    %   Responses             array of type controllib.chart.internal.foundation.BaseResponse containing
    %                       DynamicSystem and style of response
    %   Characteristics     array of type controllib.chart.internal.characteristics.AbstractCharacteristic
    %                       managing the visibility and options for specific chart characteristics
    %
    %   Position            [x0,y0,w,h] for inner position
    %   OuterPosition       [x0,y0,w,h] for outer position
    %
    %   Visible             matlab.lang.OnOffSwitchState for setting chart visibility
    %   IOGrouping          string specifying how input/outputs are grouped together,
    %                       "none"|"inputs"|"outputs"|"outputs"
    %
    %   Title               string for chart title
    %   XLabel              string for chart xlabel
    %   YLabel              string for chart ylabel
    %
    %   NextPlot            char array specifying if responses of new charts are added to or replaces
    %                       existing chart, 'add'|'replace'
    %   Grid                matlab.lang.OnOffSwitch for setting visibility of grid lines
    %
    %   XLimits             specify limits of x-axis of all axes in chart
    %   XLimitsMode         specify mode of x-axis of all axes in chart, "auto"|"manual"
    %   XLimitsSharing      string specifying the sharing of x-axis limits in chart, "all"|"column"|"none"
    %
    %                       when XLimitsSharing is "all",
    %                           XLimits is 2 element array specifying
    %                           [xmin, xmax] of all axes and XLimitsMode is
    %                           string scalar of "auto"|"manual" for all
    %                           axes
    %                       when XLimitsSharing is "column"
    %                           XLimits and XLimitsMode are a (1 x n) cell
    %                           array where n is number of columns. k-th
    %                           element of XLimits is [xmin, xmax] and k-th
    %                           element of XLimitsMode is "auto"|"manual"
    %                           for x-limits and x-limits mode for each
    %                           axes in k-th column
    %                       when XLimitsSharing is "none"
    %                           XLimits and XLimitsMode are a (m x n) cell
    %                           array for m rows and n columns of axes
    %                           (k,j) element of XLimits is [xmin, xmax]
    %                           and (k,j) element of XLimitsMode is
    %                           "auto"|"manual" for x-limits and x-limits
    %                           mode of the axes in k-th row and j-th
    %                           column
    %
    %   YLimits             specify limits of y-axis of all axes in chart
    %   YLimitsMode         specify mode of y-axis of all axes in chart, "auto"|"manual"
    %   YLimitsSharing      string specifying the sharing of y-axis limits in chart, "all"|"row"|"none"
    %
    %                       when YLimitsSharing is "all",
    %                           YLimits is 2 element array specifying
    %                           [ymin, ymax] of all axes and YLimitsMode is
    %                           string scalar of "auto"|"manual" for all
    %                           axes
    %                       when YLimitsSharing is "row",
    %                           YLimits and YLimitsMode are a (n x 1) cell
    %                           array where n is number of rows. j-th
    %                           element of YLimits is [ymin, ymax] and j-th
    %                           element of YLimitsMode is "auto"|"manual"
    %                           for y-limits mode for each axes in j-th row
    %                       when YLimitsSharing is "none"
    %                           YLimits and YLimitsMode are a (m x n) cell
    %                           array for m rows and n columns of axes
    %                           (k,j) element of YLimits is [ymin, ymax]
    %                           and (k,j) element of YLimitsMode is
    %                           "auto"|"manual" for y-limits mode of the
    %                           axes in k-th row and j-th column
    %
    %   Type                char array specifying type
    %   Tag                 string
    %
    % Protected properties:
    %
    %   SavedValues         Use in loadobj and saveobj when serializing
    %   View                of type controllib.chart.internal.view.axes.InputOutputAxesView, manages axes and responses
    %
    % Public methods:
    %
    %   updateSystem(this,sys)
    %       - updates the 1st response of the chart based on new DynamicSystem, sys
    %   updateSystem(this,sys,N)
    %       - updates the N-th response of the chart
    %
    %   removeSystem(this,system)
    %       - removes the system (of type controllib.chart.internal.foundation.BaseResponse) and its response
    %   removeSystem(this,N)
    %       - removes the N-th system and its response
    %
    %   options = getoptions(this)
    %       - returns the options object
    %
    %   setoptions(this,options)
    %       - sets chart options (of type plotopts.RespPlotOptions)
    %
    % Protected methods:
    %
    %   addSystem_(this,newSystems,color,lineStyle,markerStyle,lineWidth)
    %       - add newSystems (array of type controllib.chart.internal.foundation.BaseResponse) to the chart
    %       and create responses
    %       - assign color,lineStyle,markerStyle,lineWidth to all new responses
    %
    %   addSystemListeners(this,systems)
    %       - add listeners to SystemDeleted and SystemChanged events on systems
    %       - add listeners to Visible and ArrayVisible properties on systems
    %
    %   setCharacterisiticVisibility(this,characteristicType)
    %       - shows/hides characteristic of specified type based on the Visible value of the corresponding
    %       Characteristics property
    %
    % Protected methods (override in subclass if needed):
    %
    %   buildOptionsTab(this)
    %       - build layout and widgets for options tab (if needed) and add to property editor dialog
    %
    %   buildUnitsWidget(this)
    %       - build widget for units
    %
    %   updateUnitsWidget(this)
    %       - update the units widget when the properties of chart change
    %
    % Abstract methods:
    %
    %   createView(this)
    %       - Create the view (of type controllib.chart.internal.view.axes.InputOutputAxesView)
    %
    %   createSystem(this,systemModels,systemNames)
    %       - Create the system (of type controllib.chart.internal.foundation.BaseResponse)
    %
    %   initializeCharacteristics(this)
    %       - Initialize the characteristics (of type controllib.chart.internal.characteristic.BaseCharacteristic)

    % Copyright 2022-2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent, SetObservable, AbortSet)
        % Data objects
        Responses
        Characteristics

        % Legend
        LegendAxes
        LegendAxesMode
        LegendVisible
        LegendLocation
        LegendOrientation

        % Hold
        NextPlot
    end

    properties (Dependent, SetObservable, AbortSet, UsedInUpdate=false)
        % Hold
        DataAxes
    end

    properties (Dependent, SetObservable) %AbortSet handled after validation
        % Limits
        XLimits
        XLimitsMode
        YLimits
        YLimitsMode
    end

    properties (Hidden, Dependent, SetObservable)
        XLimitsFocus
        YLimitsFocus
    end

    properties (Dependent,SetAccess=private)
        % Labels and Styles
        Title
        Subtitle
        XLabel
        YLabel
        AxesStyle
    end

    properties(Hidden, Dependent, AbortSet, SetObservable)
        XLimitsFocusFromResponses
        YLimitsFocusFromResponses
        XLim
        YLim

        Box
        ResponseDataExceptionMessage
        ChildAddedToAxesListenerEnabled
    end
	
    properties (Hidden, Dependent, AbortSet)
        CurrentInteractionMode
    end

    properties (Dependent,GetAccess=protected,SetAccess=private)
        VisibleResponses
    end

    properties (Hidden,Dependent,SetAccess=private)
        Children
        Theme
        HasCustomGrid
    end

    properties(Hidden,Transient,NonCopyable)
        ContextMenu

        ResponseStyleIndex
        IsResponseDirty (1,1) logical = false
        HasResponseVisibilityChanged (1,1) logical = false
        LegendButton

        Behavior
        ToolbarButtons (:,1) string ...
            {mustBeMember(ToolbarButtons,["default","none","export","brush",...
            "datacursor","zoomin","zoomout","pan","rotate","restoreview"])} = "default"
    end

    properties (Hidden, SetAccess = protected, Transient, NonCopyable)
        % StyleManager
        StyleManager

        % Requirements/Constraints
        Requirements

        % HG objects added to chart
        HGList

        % TuningGoal
        TuningGoalPlotManager

        ID
    end

    properties (Access = protected)
        SavedValues

        SynchronizeResponseUpdates (1,1) logical = false
        CreateResponseDataTipsOnDefault (1,1) logical = true
    end

    properties (Access = {?controllib.chart.internal.foundation.AbstractPlot,...
            ?controllib.chart.internal.view.axes.BaseAxesView}, Transient, NonCopyable)
        SyncChartWithAxesView (1,1) logical = true
    end

    properties (Access = protected,Transient,NonCopyable)
        View
        Legend

        CharacteristicTypes (:,1) string = string.empty

        RequirementDataChangedListeners
        RequirementMouseEventListeners
        RequirementDeletedListeners

        CharacteristicOptions  (1,:)
        CharacteristicManager
        RefreshMode = "normal"

        ResponsesMenu
        CharacteristicsMenu
        ArraySelectorMenu
        GridMenu
        FullViewMenu
        PropertyMenu

        PropertyEditorDialog
        LabelsWidget
        XLimitsWidget
        YLimitsWidget
        GridWidget
        FontsWidget
        ColorWidget
        UnitsWidget

        ArraySelectorDialog

        PlotChildrenForLegend
    end

    properties (GetAccess=protected,SetAccess=private)
        Version = matlabRelease
    end

    properties (GetAccess=protected,SetAccess = private)
        NextPlot_I = "replace"

        XLimitsFocusFromResponses_I = true
        YLimitsFocusFromResponses_I = true

        ResponseDataExceptionMessage_I = "error"

        ChildAddedToAxesListenerEnabled_I = matlab.lang.OnOffSwitchState(true)

        LegendAxes_I = [1 1]
        LegendVisible_I = matlab.lang.OnOffSwitchState(false)
        LegendLocation_I = "northeast"
        LegendOrientation_I = "vertical"
        LegendAxesMode_I = "auto"
    end

    properties (Access = private, Transient, NonCopyable)
        Title_I
        Subtitle_I
        XLabel_I
        YLabel_I
        AxesStyle_I

        Responses_I = controllib.chart.internal.foundation.BaseResponse.empty
        CustomCharacteristicInfo
        UnparentedMenus

        CurrentObjectCandidateType (1,1) string ...
            {mustBeMember(CurrentObjectCandidateType,["chart","axes"])} = "chart"
    end

    properties (Access = private, Transient, NonCopyable, UsedInUpdate=false)
        DataAxes_I = [1 1]
    end

    properties (Access=protected,Transient,NonCopyable)
        XLimits_I = {[1 10]}
        YLimits_I = {[1 10]}
        XLimitsMode_I = {"auto"}
        YLimitsMode_I = {"auto"}
        RequirementsExtent
    end

    properties (Hidden)
        UserData
    end

    properties (Access=?controllib.chart.internal.view.axes.BaseAxesView,Transient,NonCopyable)
        Axes matlab.graphics.axis.Axes {mustBeScalarOrEmpty} = matlab.graphics.axis.Axes.empty
    end

    properties (GetAccess=protected, SetAccess=?controllib.chart.internal.view.axes.BaseAxesView)
        XLimitsFocus_I = {[1 10]}
        YLimitsFocus_I = {[1 10]}
    end

    %% Events
    events
        RequirementAdded
        LegendDeleted
    end

    %% Constructor/destructor
    methods
        function this = AbstractPlot(optionalInputs)
            % Base class for constructing a Controls chart.
            %
            %   ControlsPlot = controllib.chart.internal.foundation.AbstractPlot(Name,Value);
            %       Axes        Provide optional axes array for chart to use when
            %                   constructing AxesView
            %       Parent      Parent of AbstractPlot (figure, uipanel, uitab). Default is gcf.
            %       Title       String for title object
            %       XLabel      String for xlabel object
            %       YLabel      String for ylabel object
            %       Visible     matlab.lang.OnOffSwitchState. Default is 'on'
            %       Options     plotopts.PlotOptions
            arguments
                optionalInputs.Parent {mustBeScalarOrEmpty} = []
                optionalInputs.Visible (1,1) matlab.lang.OnOffSwitchState = true
                optionalInputs.OuterPosition (1,4) double = [0 0 1 1]
                optionalInputs.HandleVisibility (1,1) string {mustBeMember(optionalInputs.HandleVisibility,["on","off","callback"])} = "on"
                optionalInputs.Units (1,1) string {mustBeMember(optionalInputs.Units,["normalized","inches","centimeters","characters","points","pixels"])} = "normalized"

                optionalInputs.Options (1,1) plotopts.PlotOptions = controllib.chart.internal.foundation.AbstractPlot.createDefaultOptions()

                optionalInputs.Axes matlab.graphics.axis.Axes {mustBeScalarOrEmpty} = matlab.graphics.axis.Axes.empty
                optionalInputs.CreateResponseDataTipsOnDefault (1,1) logical = true
                optionalInputs.CreateToolbarOnDefault (1,1) logical = true %unused
            end
            this@matlab.graphics.chartcontainer.ChartContainer(Parent=optionalInputs.Parent,...
                OuterPosition=optionalInputs.OuterPosition,Visible=optionalInputs.Visible,...
                HandleVisibility=optionalInputs.HandleVisibility,Units=optionalInputs.Units);

            this.Axes = optionalInputs.Axes;
            this.CreateResponseDataTipsOnDefault = optionalInputs.CreateResponseDataTipsOnDefault;

            initialize(this);

            setoptions(this,optionalInputs.Options)
        end

        function delete(this)
            delete@controllib.chart.internal.foundation.MixInListeners(this);

            delete(this.View);
            delete(this.Responses);

            delete(this.Legend);
            delete(this.LegendButton);

            delete(this.RequirementDeletedListeners);
            delete(this.RequirementDataChangedListeners);
            delete(this.RequirementMouseEventListeners);

            delete(this.ContextMenu);
            delete(this.TuningGoalPlotManager);

            % Clean up property editor dialog
            if ~isempty(this.PropertyEditorDialog) && isvalid(this.PropertyEditorDialog) && ...
                    isequal(this.ID,this.PropertyEditorDialog.TargetTag)
                close(this.PropertyEditorDialog);
                delete(this.PropertyEditorDialog);
            end

            % Clean up array selector dialog
            if ~isempty(this.ArraySelectorDialog) && isvalid(this.ArraySelectorDialog)
                delete(this.ArraySelectorDialog);
            end

            delete@matlab.graphics.chartcontainer.ChartContainer(this);
        end
    end

    %% Public methods
    methods
        function updateSystem(this,sys,idx)
            % updateSystem: Updates the dynamic system of the chart.
            %
            %   updateSystem(h,sys)     updates the first response of the chart with the
            %                           response of sys
            %   updateSystem(h,sys,N)   updates Nth response of the chart with the response
            %                           of sys
            arguments
                this (1,1) controllib.chart.internal.foundation.AbstractPlot
                sys DynamicSystem
                idx (1,1) double {localValidateUpdateSystemIdx(this,idx)} = 1
            end
            % Waiting for approval, also see HSVPlot
            %warning(message('Controllib:plots:UpdateSystemWarning'));
            this.Responses(idx).SourceData.Model = sys;
        end

        function options = getoptions(this,propertyName)
            % getoptions: Get options object or specific option.
            %
            %   options = getoptions(h)
            %   optionValue = getoptions(h,optionName)
            arguments
                this (1,1) controllib.chart.internal.foundation.AbstractPlot
                propertyName string {mustBeScalarOrEmpty,validateOptionPropertyName(this,propertyName)} = string.empty
            end
            if isempty(propertyName)
                options = this.createDefaultOptions();
                labelTypes = ["Title";"YLabel";"XLabel"];
                labelProps = ["String";"FontSize";"FontWeight";"FontAngle";...
                    "Color";"Interpreter"];
                for ii = 1:length(labelTypes)
                    for jj = 1:length(labelProps)
                        if isstring(this.(labelTypes(ii)).(labelProps(jj)))
                            value = cellstr(this.(labelTypes(ii)).(labelProps(jj)));
                            if isscalar(value)
                                value = value{1};
                            end
                        else
                            value = this.(labelTypes(ii)).(labelProps(jj));
                        end
                        options.(labelTypes(ii)).(labelProps(jj)) = value;
                    end
                    options.ColorMode.(labelTypes(ii)) = this.(labelTypes(ii)).ColorMode;
                end
                labelProps = ["FontSize";"FontWeight";"FontAngle";"RulerColor"];
                for ii = 1:length(labelProps)
                    if isstring(this.AxesStyle.(labelProps(ii)))
                        value = cellstr(this.AxesStyle.(labelProps(ii)));
                        if isscalar(value)
                            value = value{1};
                        end
                    else
                        value = this.AxesStyle.(labelProps(ii));
                    end
                    if labelProps(ii) == "RulerColor"
                        options.TickLabel.Color = value;
                    else
                        options.TickLabel.(labelProps(ii)) = value;
                    end
                end
                options.ColorMode.TickLabel = this.AxesStyle.RulerColorMode;
                options.Grid = char(this.AxesStyle.GridVisible);
                options.GridColor = this.AxesStyle.GridColor;
                options.ColorMode.Grid = this.AxesStyle.GridColorMode;
                options.XLim = this.XLimits_I;
                options.YLim = this.YLimits_I;
                xlimmode = this.XLimitsMode_I;
                for ii = 1:numel(xlimmode)
                    xlimmode{ii} = char(xlimmode{ii});
                end
                options.XLimMode = xlimmode;
                ylimmode = this.YLimitsMode_I;
                for ii = 1:numel(ylimmode)
                    ylimmode{ii} = char(ylimmode{ii});
                end
                options.YLimMode = ylimmode;
            else
                switch propertyName
                    case {'Title','XLabel','YLabel'}
                        options = struct('String', '', ...
                            'FontSize',   this.(propertyName).FontSize, ...
                            'FontWeight', char(this.(propertyName).FontWeight), ...
                            'FontAngle',  char(this.(propertyName).FontAngle), ...
                            'Color',      this.(propertyName).Color, ...
                            'Interpreter', char(this.(propertyName).Interpreter));
                        str = cellstr(this.(propertyName).String);
                        if isscalar(str)
                            str = str{1};
                        end
                        options.String = str;
                    case 'TickLabel'
                        options = struct('FontSize',   this.AxesStyle.FontSize, ...
                            'FontWeight', char(this.AxesStyle.FontWeight), ...
                            'FontAngle',  char(this.AxesStyle.FontAngle), ...
                            'Color',      this.AxesStyle.RulerColor);
                    case 'Grid'
                        options = char(this.AxesStyle.GridVisible);
                    case 'GridColor'
                        options = this.AxesStyle.GridColor;
                    case 'XLim'
                        options = this.XLimits_I;
                    case 'YLim'
                        options = this.YLimits_I;
                    case 'XLimMode'
                        xlimmode = this.XLimitsMode_I;
                        for ii = 1:numel(xlimmode)
                            xlimmode{ii} = char(xlimmode{ii});
                        end
                        options = xlimmode;
                    case 'YLimMode'
                        ylimmode = this.YLimitsMode_I;
                        for ii = 1:numel(ylimmode)
                            ylimmode{ii} = char(ylimmode{ii});
                        end
                        options = ylimmode;
                    otherwise
                        error(message('Controllib:plots:getoptions2'))
                end
            end
        end

        function setoptions(this,options,nameValueInputs)
            % setoptions: Set options to chart.
            %
            %   setoptions(h,options)
            arguments
                this (1,1) controllib.chart.internal.foundation.AbstractPlot
                options (1,1) plotopts.PlotOptions = getoptions(this)
                nameValueInputs.?plotopts.PlotOptions
            end

            options = copy(options);

            % Update options with name-value inputs
            nameValueInputsCell = namedargs2cell(nameValueInputs);
            if ~isempty(nameValueInputsCell)
                set(options,nameValueInputsCell{:});
            end

            % Title, XLabel, YLabel
            labels = ["Title";"XLabel";"YLabel"];
            labelProps = ["String";"FontSize";"FontWeight";"FontAngle";"Color";"Interpreter"];
            for ii = 1:length(labels)
                for jj = 1:length(labelProps)
                    value = options.(labels(ii)).(labelProps(jj));
                    if ismember(labelProps(jj),["FontWeight";"FontAngle";"Interpreter"])
                        try %#ok<TRYNC>
                            value = lower(value);
                        end
                    end
                    this.(labels(ii)).(labelProps(jj)) = value;
                end
                if isfield(options.ColorMode,labels(ii))
                    this.(labels(ii)).ColorMode = options.ColorMode.(labels(ii));
                end
            end

            % AxesStyle
            labelProps = ["FontSize";"FontWeight";"FontAngle"];
            for ii = 1:length(labelProps)
                value = options.TickLabel.(labelProps(ii));
                if ismember(labelProps(ii),["FontWeight";"FontAngle"])
                    try %#ok<TRYNC>
                        value = lower(value);
                    end
                end
                this.AxesStyle.(labelProps(ii)) = value;
            end
            this.AxesStyle.RulerColor = options.TickLabel.Color;
            if isfield(options.ColorMode,'TickLabel')
                this.AxesStyle.RulerColorMode = options.ColorMode.TickLabel;
            end
            this.AxesStyle.GridVisible = options.Grid;
            this.AxesStyle.GridColor = options.GridColor;
            if isfield(options.ColorMode,'Grid')
                this.AxesStyle.GridColorMode = options.ColorMode.Grid;
            end

            % Limits
            sz = getVisibleAxesSize(this);
            if sz(1) ~= 0 && sz(2) ~= 0
                try
                    this.XLimits = options.XLim;
                catch
                    warning(message('Controllib:plots:SetOptionsIncorrectSize','XLim'))
                end
                try
                    this.XLimitsMode = options.XLimMode;
                catch
                    warning(message('Controllib:plots:SetOptionsIncorrectSize','XLimMode'))
                end
                try
                    this.YLimits = options.YLim;
                catch
                    warning(message('Controllib:plots:SetOptionsIncorrectSize','YLim'))
                end
                try
                    this.YLimitsMode = options.YLimMode;
                catch
                    warning(message('Controllib:plots:SetOptionsIncorrectSize','YLimMode'))
                end
            end
        end

        function addResponse(this,varargin)
            % addResponse(h,sys1,sys2)
            %   adds the response of "sys1" and "sys2" to the chart "h"
            %
            % addResponse(h,sys,Name-Value)
            %   See other uses for optional chart specific Name-Value inputs

            error(['Adding responses not supported in ',this.Type]);
        end
    end

    %% Get/Set
    methods
        % StyleManager
        function set.StyleManager(this,StyleManager)
            this.StyleManager = StyleManager;

            try%#ok<TRYNC>
                unregisterListeners(this,"ResponseStyleManagerChangedListener");
            end
            % Add Listener for StyleManager
            L = addlistener(this.StyleManager,"ResponseStyleManagerChanged",...
                @(es,ed) cbResponseStyleManagerChanged(this));
            registerListeners(this,L,"ResponseStyleManagerChangedListener");
        end

        % Responses
        function Responses = get.Responses(this)
            Responses = this.Responses_I;
        end

        function set.Responses(this,responses)
            arguments
                this (1,1) controllib.chart.internal.foundation.AbstractPlot
                responses (:,1) controllib.chart.internal.foundation.BaseResponse
            end

            idxToSave = NaN(1,length(responses));
            for ii = 1:length(responses)
                idxToSave(ii) = find(arrayfun(@(x) isequal(x,responses(ii).Tag),[this.Responses.Tag]),1);
            end
            idxToRemove = setdiff(1:length(this.Responses),idxToSave);
            responsesToRemove = this.Responses(idxToRemove);
            delete(responsesToRemove);

            savedIdxAfterDeletion = 1:length(this.Responses);
            for ii = 1:length(this.Responses)
                savedIdxAfterDeletion(ii) = find(arrayfun(@(x) isequal(x,responses(ii).Tag),[this.Responses.Tag]),1);
            end

            this.Responses_I = this.Responses_I(savedIdxAfterDeletion);
            this.ResponseStyleIndex = this.ResponseStyleIndex(savedIdxAfterDeletion);

            permuteResponseMenus(this);

            if ~isempty(this.View) && isvalid(this.View)
                permuteResponseViews(this.View,savedIdxAfterDeletion);
            end

            permuteLegendObjects(this);
        end

        % Characteristics
        function Characteristics = get.Characteristics(this)
            Characteristics = this.CharacteristicManager;
        end

        function NextPlot = get.NextPlot(this)
            NextPlot = this.NextPlot_I;
        end

        % NextPlot
        function set.NextPlot(this, nextPlot)
            arguments
                this (1,1) controllib.chart.internal.foundation.AbstractPlot
                nextPlot (1,1) string {mustBeMember(nextPlot,["replace","add"])}
            end
            this.NextPlot_I = nextPlot;
            setNextPlotOnAxes(this);
        end

        % Children
        function Children = get.Children(this)
            % Set Children property (to enable findall)
            Children = getLayout(this);
        end

        % Theme
        function Theme = get.Theme(this)
            Theme = getTheme(this);
            if isempty(Theme)
                Theme = matlab.graphics.internal.themes.lightTheme;
            end
        end

        % HasCustomGrid
        function HasCustomGrid = get.HasCustomGrid(this)
            HasCustomGrid = hasCustomGrid(this);
        end

        % Title
        function Title = get.Title(this)
            Title = this.Title_I;
        end

        % Subtitle
        function Subtitle = get.Subtitle(this)
            Subtitle = this.Subtitle_I;
        end

        % XLabel
        function XLabel = get.XLabel(this)
            XLabel = this.XLabel_I;
        end

        % YLabel
        function YLabel = get.YLabel(this)
            YLabel = this.YLabel_I;
        end

        % AxesStyle
        function AxesStyle = get.AxesStyle(this)
            AxesStyle = this.AxesStyle_I;
        end

        % Box
        function Box = get.Box(this)
            Box = this.AxesStyle.Box;
        end

        function set.Box(this,flag)
            arguments
                this (1,1) controllib.chart.internal.foundation.AbstractPlot
                flag (1,1) matlab.lang.OnOffSwitchState
            end
            this.AxesStyle.Box = flag;
        end

        % XLimits
        function XLimits = get.XLimits(this)
            XLimits = this.XLimits_I;
            if isscalar(XLimits)
                XLimits = XLimits{1};
            elseif isempty(XLimits)
                XLimits = {};
            end
        end

        function set.XLimits(this,XLimits)
            try
                XLimits = validateXLimits(this,XLimits);
            catch ME
                throw(ME)
            end
            if isequal(this.XLimits_I,XLimits)
                return;
            end

            xLimMode = this.XLimitsMode_I;
            for ii = 1:min(numel(XLimits),numel(this.XLimits_I))
                if ~isequal(XLimits{ii},this.XLimits_I{ii})
                    xLimMode{ii} = "manual";
                end
            end

            this.XLimits_I = XLimits;
            this.XLimitsMode_I = xLimMode;

            % Update View
            if this.SyncChartWithAxesView && ~isempty(this.View) && isvalid(this.View)
                syncAxesGridXLimits(this.View);
            end

            % Update limits widget
            updateXLimitsWidget(this);
        end

        % YLimits
        function YLimits = get.YLimits(this)
            YLimits = this.YLimits_I;
            if isscalar(YLimits)
                YLimits = YLimits{1};
            elseif isempty(YLimits)
                YLimits = {};
            end
        end

        function set.YLimits(this,YLimits)
            try
                YLimits = validateYLimits(this,YLimits);
            catch ME
                throw(ME)
            end
            if isequal(this.YLimits_I,YLimits)
                return;
            end

            yLimMode = this.YLimitsMode_I;
            for ii = 1:min(numel(YLimits),numel(this.YLimits_I))
                if ~isequal(YLimits{ii},this.YLimits_I{ii})
                    yLimMode{ii} = "manual";
                end
            end

            this.YLimits_I = YLimits;
            this.YLimitsMode_I = yLimMode;

            % Update View
            if this.SyncChartWithAxesView && ~isempty(this.View) && isvalid(this.View)
                syncAxesGridYLimits(this.View);
            end

            % Update limits widget
            updateYLimitsWidget(this);
        end

        % XLimitsMode
        function XLimitsMode = get.XLimitsMode(this)
            XLimitsMode = this.XLimitsMode_I;
            if isscalar(XLimitsMode)
                XLimitsMode = XLimitsMode{1};
            elseif isempty(XLimitsMode)
                XLimitsMode = {};
            end
        end

        function set.XLimitsMode(this,XLimitsMode)
            try
                XLimitsMode = validateXLimitsMode(this,XLimitsMode);
            catch ME
                throw(ME)
            end
            if isequal(this.XLimitsMode_I,XLimitsMode)
                return;
            end

            this.XLimitsMode_I = XLimitsMode;

            % Update View
            if this.SyncChartWithAxesView && ~isempty(this.View) && isvalid(this.View)
                syncAxesGridXLimits(this.View);
            end

            % Update limits widget
            updateXLimitsWidget(this);
        end

        % YLimitsMode
        function YLimitsMode = get.YLimitsMode(this)
            YLimitsMode = this.YLimitsMode_I;
            if isscalar(YLimitsMode)
                YLimitsMode = YLimitsMode{1};
            elseif isempty(YLimitsMode)
                YLimitsMode = {};
            end
        end

        function set.YLimitsMode(this,YLimitsMode)
            try
                YLimitsMode = validateYLimitsMode(this,YLimitsMode);
            catch ME
                throw(ME)
            end
            if isequal(this.YLimitsMode_I,YLimitsMode)
                return;
            end

            this.YLimitsMode_I = YLimitsMode;

            % Update View
            if this.SyncChartWithAxesView && ~isempty(this.View) && isvalid(this.View)
                syncAxesGridYLimits(this.View);
            end

            % Update limits widget
            updateYLimitsWidget(this);
        end

        % XLimitsFocus
        function XLimitsFocus = get.XLimitsFocus(this)
            XLimitsFocus = this.XLimitsFocus_I;
        end

        function set.XLimitsFocus(this,XLimitsFocus)
            arguments
                this (1,1) controllib.chart.internal.foundation.AbstractPlot
                XLimitsFocus (:,:) cell
            end
            this.XLimitsFocus_I = XLimitsFocus;
            this.XLimitsFocusFromResponses_I = false;

            if this.SyncChartWithAxesView && ~isempty(this.View) && isvalid(this.View)
                syncAxesGridXLimits(this.View);
            end
        end

        % XLimitsFocusFromResponses
        function XLimitsFocusFromResponses = get.XLimitsFocusFromResponses(this)
            XLimitsFocusFromResponses = this.XLimitsFocusFromResponses_I;
        end

        function set.XLimitsFocusFromResponses(this,XLimitsFocusFromResponses)
            arguments
                this (1,1) controllib.chart.internal.foundation.AbstractPlot
                XLimitsFocusFromResponses (1,1) logical
            end
            this.XLimitsFocusFromResponses_I = XLimitsFocusFromResponses;
            if XLimitsFocusFromResponses && ~isempty(this.View) && isvalid(this.View) && this.SyncChartWithAxesView
                updateFocus(this.View);
            end
        end

        % YLimitsFocus
        function YLimitsFocus = get.YLimitsFocus(this)
            YLimitsFocus = this.YLimitsFocus_I;
        end

        function set.YLimitsFocus(this,YLimitsFocus)
            arguments
                this (1,1) controllib.chart.internal.foundation.AbstractPlot
                YLimitsFocus (:,:) cell
            end
            this.YLimitsFocus_I = YLimitsFocus;
            this.YLimitsFocusFromResponses_I = false;

            if this.SyncChartWithAxesView && ~isempty(this.View) && isvalid(this.View)
                syncAxesGridYLimits(this.View);
            end
        end

        % YLimitsFocusFromResponses
        function YLimitsFocusFromResponses = get.YLimitsFocusFromResponses(this)
            YLimitsFocusFromResponses = this.YLimitsFocusFromResponses_I;
        end

        function set.YLimitsFocusFromResponses(this,YLimitsFocusFromResponses)
            arguments
                this (1,1) controllib.chart.internal.foundation.AbstractPlot
                YLimitsFocusFromResponses (1,1) logical
            end
            this.YLimitsFocusFromResponses_I = YLimitsFocusFromResponses;
            if YLimitsFocusFromResponses && ~isempty(this.View) && isvalid(this.View) && this.SyncChartWithAxesView
                updateFocus(this.View);
            end
        end

        % XLim
        function XLim = get.XLim(this)
            XLim = xlim(this);
        end

        function set.XLim(this,XLim)
            xlim(this,XLim);
        end

        % YLim
        function YLim = get.YLim(this)
            YLim = ylim(this);
        end

        function set.YLim(this,YLim)
            ylim(this,YLim);
        end

        % Visible Responses
        function VisibleResponses = get.VisibleResponses(this)
            if isempty(this.Responses)
                VisibleResponses = controllib.chart.internal.foundation.BaseResponse.empty;
            else
                VisibleResponses = this.Responses(arrayfun(@(x) isvalid(x) & x.Visible & x.ShowInView,...
                    this.Responses));
            end
        end

        % DataAxes
        function DataAxes = get.DataAxes(this)
            DataAxes = this.DataAxes_I;
        end

        function set.DataAxes(this,DataAxes)
            arguments
                this (1,1)
                DataAxes (1,2) double {mustBeInteger,mustBePositive}
            end
            this.DataAxes_I = DataAxes;
        end

        % LegendAxes
        function legendAxes = get.LegendAxes(this)
            legendAxes = this.LegendAxes_I;
        end

        function set.LegendAxes(this,legendAxes)
            arguments
                this (1,1)
                legendAxes (1,2) double {mustBeInteger,mustBePositive}
            end
            this.LegendAxes_I = legendAxes;
            this.LegendAxesMode = "manual";
            setAxesForLegend(this);
        end

        % LegendAxesMode
        function LegendAxesMode = get.LegendAxesMode(this)
            LegendAxesMode = this.LegendAxesMode_I;
        end

        function set.LegendAxesMode(this,legendAxesMode)
            arguments
                this (1,1) controllib.chart.internal.foundation.AbstractPlot
                legendAxesMode (1,1) string {mustBeMember(legendAxesMode,["auto","manual"])}
            end
            if strcmp(legendAxesMode,"auto")
                if ~isempty(this.View) && isvalid(this.View)
                    updateLegendAxesInAutoMode(this);
                    setAxesForLegend(this);
                else
                    this.LegendAxes_I = [0 0];
                end
            end
            this.LegendAxesMode_I = legendAxesMode;
        end

        % LegendVisible
        function legendVisible = get.LegendVisible(this)
            legendVisible = this.LegendVisible_I;
        end

        function set.LegendVisible(this,legendVisible)
            arguments
                this (1,1) controllib.chart.internal.foundation.AbstractPlot
                legendVisible (1,1) matlab.lang.OnOffSwitchState
            end
            this.LegendVisible_I = legendVisible;
            if isempty(this.Legend) || ~isvalid(this.Legend)
                % Create legend if it doesn't exist and visible is 'on'
                if legendVisible
                    legend(this,legendVisible);
                end
            else
                % Set visible on legend
                this.Legend.Visible = legendVisible;
            end
            % Set toolbar button value if needed
            if ~isempty(this.LegendButton)
            for ct = 1:numel(this.LegendButton)
               this.LegendButton(ct).Value=legendVisible;
            end
            end
        end

        % LegendLocation
        function legendLocation = get.LegendLocation(this)
            legendLocation = this.LegendLocation_I;
        end

        function set.LegendLocation(this,legendLocation)
            arguments
                this (1,1) controllib.chart.internal.foundation.AbstractPlot
                legendLocation (1,1) string {validateLegendLocation(legendLocation)}
            end
            this.LegendLocation_I = legendLocation;
            if ~isempty(this.Legend) && isvalid(this.Legend)
                this.Legend.Location = legendLocation;
            end
        end

        % LegendOrientation
        function legendOrientation = get.LegendOrientation(this)
            legendOrientation = this.LegendOrientation_I;
        end

        function set.LegendOrientation(this,legendOrientation)
            arguments
                this (1,1) controllib.chart.internal.foundation.AbstractPlot
                legendOrientation (1,1) string {mustBeMember(legendOrientation,["vertical","horizontal"])}
            end
            this.LegendOrientation_I = legendOrientation;
            if ~isempty(this.Legend) && isvalid(this.Legend)
                this.Legend.Orientation = legendOrientation;
            end
        end

        % ResponseDataExceptionMessage
        function ResponseDataExceptionMessage = get.ResponseDataExceptionMessage(this)
            ResponseDataExceptionMessage = this.ResponseDataExceptionMessage_I;
        end

        function set.ResponseDataExceptionMessage(this,ResponseDataExceptionMessage)
            arguments
                this (1,1) controllib.chart.internal.foundation.AbstractPlot
                ResponseDataExceptionMessage (1,1) string {mustBeMember(ResponseDataExceptionMessage,...
                    ["error","warning","none"])}
            end
            this.ResponseDataExceptionMessage_I = ResponseDataExceptionMessage;
            for k = 1:length(this.Responses)
                this.Responses(k).DataExceptionMessage = ResponseDataExceptionMessage;
            end
        end

        % ChildAddedToAxesListenerEnabled
        function ChildAddedToAxesListenerEnabled = get.ChildAddedToAxesListenerEnabled(this)
            ChildAddedToAxesListenerEnabled = this.ChildAddedToAxesListenerEnabled_I;
        end

        function set.ChildAddedToAxesListenerEnabled(this,ChildAddedToAxesListenerEnabled)
            arguments
                this (1,1) controllib.chart.internal.foundation.AbstractPlot
                ChildAddedToAxesListenerEnabled (1,1) matlab.lang.OnOffSwitchState
            end
            this.ChildAddedToAxesListenerEnabled_I = ChildAddedToAxesListenerEnabled;
            if ChildAddedToAxesListenerEnabled
                enableListeners(this,'ChildAddedToAxes');
            else
                disableListeners(this,'ChildAddedToAxes');
            end
        end

        % CurrentInteractionMode
        function currentInteractionMode = get.CurrentInteractionMode(this)
            currentInteractionMode = this.View.CurrentInteractionMode;
        end

        function set.CurrentInteractionMode(this,currentInteractionMode)
            this.View.CurrentInteractionMode = currentInteractionMode;
        end
    end

    %% Convenience command methods
    methods (Hidden,Sealed)
        function out = legend(this,varargin)
            arguments
                this (1,1) controllib.chart.internal.foundation.AbstractPlot
            end
            arguments (Repeating)
                varargin
            end
            for k = 1:length(varargin)
                if isstring(varargin{k}) || isa(varargin{k},'matlab.lang.OnOffSwitchState')
                    if isscalar(varargin{k})
                        varargin{k} = char(varargin{k});
                    else
                        varargin = [varargin(1:k-1),cellstr(varargin{k}),varargin(k+1:end)];
                    end
                end
            end

            nvs = varargin;
            nvs = nvs(cellfun(@(x) ~iscell(x),nvs));
            
            % Find the start of NV pairs in input arguments that match legend property names
            nameValueArgStartIdx = [];
            % Get all public, settable, non-hidden properties of legend
            legendMetaClass = ?matlab.graphics.illustration.Legend;
            publicSetAccessIdx = strcmp({legendMetaClass.PropertyList.SetAccess},'public');
            publicGetAccessIdx = strcmp({legendMetaClass.PropertyList.GetAccess},'public');
            nonHiddenIdx = ~[legendMetaClass.PropertyList.Hidden];
            documentedProperties = legendMetaClass.PropertyList(publicGetAccessIdx & publicSetAccessIdx ...
                                                                    & nonHiddenIdx);
            propertyNamesToMatch = {documentedProperties.Name};
            % Loop over all inputs to find the first matche to property names
            for k = 1:numel(nvs)
                if (ischar(nvs{k}) || isstring(nvs{k})) && any(strcmpi(propertyNamesToMatch,nvs{k}))
                    nameValueArgStartIdx = k;
                    break;
                end
            end

            % Split inputs into positional arguments and NV pairs
            if ~isempty(nameValueArgStartIdx)
                labelsOrPositionalOptions = varargin(1:nameValueArgStartIdx-1+(length(varargin)~=length(nvs)));
                nameValueOptions = varargin(nameValueArgStartIdx+(length(varargin)~=length(nvs)):end);
            else
                labelsOrPositionalOptions = varargin;
                nameValueOptions = {};
            end
            labelsOrPositionalOptions = cellfun(@(x) string(x),labelsOrPositionalOptions,UniformOutput=false);

            % Parse nv pairs
            p = inputParser();
            p.FunctionName = 'legend';
            p.CaseSensitive = false;
            p.PartialMatching = false;
            addParameter(p,"Location",this.LegendLocation_I,@validateLegendLocation);
            addParameter(p,"Orientation",this.LegendOrientation_I);
            for k = 1:length(propertyNamesToMatch)
                if ~any(strcmp(propertyNamesToMatch{k},{'Location','Orientation'}))
                    addParameter(p,propertyNamesToMatch{k},[]);
                end
            end
            parse(p,nameValueOptions{:});
            nameValueOptions = p.Results;

            % Parse data labels and positional optional inputs
            deleteLegend = false;
            if ~isempty(labelsOrPositionalOptions) && isscalar(labelsOrPositionalOptions{1}) && ...
                    any(strcmp(labelsOrPositionalOptions{1},["show","on","hide","toggle",...
                    "off","boxoff","boxon"]))
                % Check the first positional argument which is not a data
                % labels. Note that for legend, this takes precedence over NV pairs
                switch string(lower(labelsOrPositionalOptions{1}))
                    case {"show","on"}
                        nameValueOptions.Visible = matlab.lang.OnOffSwitchState("on");
                    case "toggle"
                        nameValueOptions.Visible = ~this.LegendVisible_I;
                    case "hide"
                        nameValueOptions.Visible = matlab.lang.OnOffSwitchState("off");
                    case "off"
                        deleteLegend = true;
                        nameValueOptions.Visible = matlab.lang.OnOffSwitchState("off");
                    case "boxoff"
                        nameValueOptions.Box = "off";
                    case "boxon"
                        nameValueOptions.Box = "on";
                end
                dataLabels = labelsOrPositionalOptions(2:end);
            else
                % Only data labels provided as positional arguments
                dataLabels = labelsOrPositionalOptions;
            end

            if deleteLegend
                delete(this.Legend);
                hLegend = matlab.graphics.GraphicsPlaceholder.empty;
                if ~isempty(this.LegendButton)
               for ct = 1:numel(this.LegendButton)
                  this.LegendButton(ct).Value = 'off';
               end
                end
            else
                if isempty(this.Legend) || ~isvalid(this.Legend)
                    % Create legend and remove context menu
                    this.Legend = matlab.graphics.illustration.Legend(Visible=true);
                    addlistener(this.Legend,'ObjectBeingDestroyed',@(es,ed) cbLegendDeleted(this));

                    % Disable AutoUpdate and set PlotChildren
                    this.Legend.AutoUpdate = 'off';

                    % Add listener to update legend axes when legend
                    % visibility is toggled
                    L = addlistener(this.Legend,'Visible','PostSet',@(es,ed) cbLegendVisibilityChanged(this));
                    registerListeners(this,L,'LegendVisibilityListener');
                end

                setAxesForLegend(this);
               

                % Set Legend properties
                for k = 1:length(propertyNamesToMatch)
                    if ~isempty(nameValueOptions.(propertyNamesToMatch{k}))
                        this.Legend.(propertyNamesToMatch{k}) = nameValueOptions.(propertyNamesToMatch{k});
                    end
                end

                this.LegendLocation_I = nameValueOptions.Location;
                this.LegendOrientation_I = nameValueOptions.Orientation;

                this.LegendVisible_I = this.Legend.Visible;
                if ~isempty(this.LegendButton)
                    for ct = 1:numel(this.LegendButton)
                        this.LegendButton(ct).Value = this.Legend.Visible;
                    end
                end
                updateLegendPlotChildren(this);

                if ~isempty(dataLabels)
                    if isscalar(dataLabels)
                        dataLabels = string(dataLabels{1});
                    else
                        dataLabels = string(dataLabels);
                    end

                    numberOfDataLabelsUsed = updateLegendWithCustomDataLabels(this,dataLabels);

                    % Throw warning if there are extra data labels
                    if numberOfDataLabelsUsed <= length(dataLabels)
                        warning('MATLAB:legend:IgnoringExtraEntries',...
                            getString(message('MATLAB:legend:IgnoringExtraEntries')));
                    end
                end

                % Return legend object
                hLegend = this.Legend;
            end

            if nargout
                out = hLegend;
            end
        end

        % title
        function out = title(this,titleString,varargin)
            arguments
                this controllib.chart.internal.foundation.AbstractPlot
                titleString (:,1) string {mustBeValidLabelString(this,titleString,"Title")}
            end
            arguments (Repeating)
                varargin
            end
            try
                label = setLabelsFromConvenienceCommand(this,"Title",titleString,varargin{:});
            catch ME
                throw(ME);
            end
            if nargout
                out = label;
                if isscalar(out)
                    out = out{1};
                end
            end
        end

        % subtitle
        function out = subtitle(this,subtitleString,varargin)
            arguments
                this controllib.chart.internal.foundation.AbstractPlot
                subtitleString (:,1) string {mustBeValidLabelString(this,subtitleString,"Subtitle")}
            end
            arguments (Repeating)
                varargin
            end
            try
                label = setLabelsFromConvenienceCommand(this,"Subtitle",subtitleString,varargin{:});
            catch ME
                throw(ME);
            end
            if nargout
                out = label;
                if isscalar(out)
                    out = out{1};
                end
            end
        end

        % xlabel
        function out = xlabel(this,xlabelString,varargin)
            arguments
                this controllib.chart.internal.foundation.AbstractPlot
                xlabelString (:,1) string {mustBeValidLabelString(this,xlabelString,"XLabel")}
            end
            arguments (Repeating)
                varargin
            end
            try
                label = setLabelsFromConvenienceCommand(this,"XLabel",xlabelString,varargin{:});
            catch ME
                throw(ME);
            end
            if nargout
                out = label;
                if isscalar(out)
                    out = out{1};
                end
            end
        end

        % ylabel
        function out = ylabel(this,ylabelString,varargin)
            arguments
                this controllib.chart.internal.foundation.AbstractPlot
                ylabelString (:,1) string {mustBeValidLabelString(this,ylabelString,"YLabel")}
            end
            arguments (Repeating)
                varargin
            end
            try
                label = setLabelsFromConvenienceCommand(this,"YLabel",ylabelString,varargin{:});
            catch ME
                throw(ME);
            end
            if nargout
                out = label;
                if isscalar(out)
                    out = out{1};
                end
            end
        end

        % xlim
        function out = xlim(this,limArgs)
            setMode = false;

            if nargin > 1
                if ischar(limArgs) || isstring(limArgs)
                    mustBeMember(limArgs,["auto","manual"]);
                    setMode = true;
                else
                    validateattributes(limArgs,"numeric",{"increasing","size",[1 2]});
                end

                for ii = 1:numel(this)
                    ax = getCurrentAxes(this(ii));
                    if setMode
                        ax.XLimMode = limArgs;
                    else
                        ax.XLim = limArgs;
                    end
                end
            end

            if nargout
                out = cell(size(this));
                for ii = 1:numel(this)
                    ax = getCurrentAxes(this(ii));
                    if setMode
                        out{ii} = ax.XLimMode;
                    else
                        out{ii} = ax.XLim;
                    end
                end
                if isscalar(out)
                    out = out{1};
                end
            end
        end

        % ylim
        function out = ylim(this,limArgs)
            setMode = false;

            if nargin > 1
                if ischar(limArgs) || isstring(limArgs)
                    mustBeMember(limArgs,["auto","manual"]);
                    setMode = true;
                else
                    validateattributes(limArgs,"numeric",{"increasing","size",[1 2]});
                end

                for ii = 1:numel(this)
                    ax = getCurrentAxes(this(ii));
                    if setMode
                        ax.YLimMode = limArgs;
                    else
                        ax.YLim = limArgs;
                    end
                end
            end

            if nargout
                out = cell(size(this));
                for ii = 1:numel(this)
                    ax = getCurrentAxes(this(ii));
                    if setMode
                        out{ii} = ax.YLimMode;
                    else
                        out{ii} = ax.YLim;
                    end
                end
                if isscalar(out)
                    out = out{1};
                end
            end
        end

        % axis
        function out = axis(this,axisArgs)
            if nargin > 1
                for ii = 1:numel(this)
                    if isnumeric(axisArgs)
                        xlim(this,axisArgs(1:2));
                        ylim(this,axisArgs(3:4));
                    else
                        switch axisArgs
                            case {'auto','autoxy'}
                                this(ii).XLimitsMode = "auto";
                                this(ii).YLimitsMode = "auto";
                            case {'autox','autoxz'}
                                this(ii).XLimitsMode = "auto";
                            case {'autoy','autoyz'}
                                this(ii).YLimitsMode = "auto";
                            case 'manual'
                                this(ii).XLimitsMode = "manual";
                                this(ii).YLimitsMode = "manual";
                            case 'equal'
                                ax = getChartAxes(this(ii));
                                if isscalar(ax)
                                    % Apply axis input argument to individual, single axes
                                    enableDisableAxesLimitModeListeners(qeGetAxesGrid(this.View));
                                    axis(ax,'equal');
                                    enableDisableAxesLimitModeListeners(qeGetAxesGrid(this.View));

                                    % Use new limits
                                    this(ii).XLimits = ax.XLim;
                                    this(ii).YLimits = ax.YLim;
                                else
                                    warning('Controllib:plots:axesgroupInvalidAxesOption',...
                                        getString(message('Controllib:plots:axesgroupInvalidAxesOption')));
                                end
                            case 'normal'
                                ax = getChartAxes(this(ii));
                                if isscalar(ax)
                                    % Apply axis input argument to individual, single axes
                                    axis(ax,'normal');

                                    % Reset mode to auto
                                    this(ii).XLimitsMode = "auto";
                                    this(ii).YLimitsMode = "auto";
                                else
                                    warning('Controllib:plots:axesgroupInvalidAxesOption',...
                                        getString(message('Controllib:plots:axesgroupInvalidAxesOption')));
                                end
                            otherwise
                                warning('Controllib:plots:axesgroupInvalidAxesOption',...
                                    getString(message('Controllib:plots:axesgroupInvalidAxesOption')));
                        end
                    end
                end
            end
            if nargout
                out = cell(size(this));
                for ii = 1:numel(this)
                    ax = getCurrentAxes(this(ii));
                    out{ii} = axis(ax);
                end
                if isscalar(out)
                    out = out{1};
                end
            end
        end

        % grid
        function grid(this,gridValue)
            arguments
                this controllib.chart.internal.foundation.AbstractPlot
                gridValue {validateGridValue(gridValue)} = "CSTdefaultGridBehavior"
            end

            for ii = 1:numel(this)
                if strcmp(gridValue,"CSTdefaultGridBehavior")
                    this(ii).AxesStyle.GridVisible = ~this(ii).AxesStyle.GridVisible;
                    this(ii).AxesStyle.MinorGridVisible = false;
                else
                    if strcmp(gridValue,'minor')
                        this(ii).AxesStyle.MinorGridVisible = true;
                        gridValue = true;
                    else
                        this(ii).AxesStyle.MinorGridVisible = false;
                    end
                    this(ii).AxesStyle.GridVisible = gridValue;
                end
            end
        end

        % box
        function box(this,boxValue)
            arguments
                this controllib.chart.internal.foundation.AbstractPlot
                boxValue {validateBoxValue(boxValue)} = "CSTdefaultBoxBehavior"
            end
            for ii = 1:numel(this)
                if strcmp(boxValue,"CSTdefaultBoxBehavior")
                    this(ii).AxesStyle.Box = ~this(ii).AxesStyle.Box;
                else
                    this(ii).AxesStyle.Box = boxValue;
                end
            end
        end

        % hold
        function tf = isHoldEnabled(this)
            tf = false(size(this));
            for ii = 1:numel(this)
                tf(ii) = strcmp(this(ii).NextPlot,'add');
            end
        end

        function setHoldState(this, tf)
            for ii = 1:numel(this)
                if tf
                    this(ii).NextPlot = 'add';
                else
                    this(ii).NextPlot = 'replace';
                end
            end
        end

        function currentAxes = prepareForPlot(this, target)
            currentAxes = getCurrentAxes(this);
            prepareForPlot(currentAxes,target);
        end

        function cla(this,resetFlag)
            arguments
                this controllib.chart.internal.foundation.AbstractPlot
                resetFlag string {mustBeScalarOrEmpty,mustBeMember(resetFlag,"reset")} = string.empty
            end
            for ii = 1:numel(this)
                ax = getChartAxes(this(ii));
                ax = ax(1);
                ax.Parent = [];
                parent = this(ii).Parent;
                layout = this(ii).Layout;
                outerPosition = this(ii).OuterPosition;
                units = this(ii).Units;
                delete(this(ii));
                delete(allchild(ax));
                cla(ax);
                if nargin>1 && strcmpi(resetFlag,'reset')
                    reset(ax);
                end
                ax.Parent = parent;
                if isempty(layout)
                    ax.Units = units;
                    ax.OuterPosition = outerPosition;
                else
                    ax.Layout = layout;
                end
            end
        end

        function reset(this) %#ok<MANU>
            % To be implemented
        end
    end

    %% Protected sealed methods
    methods (Access=protected,Sealed)
        function mustBeValidLabelString(this,str,label)
            for ii = 1:numel(this)
                mustConvertToValidLabelString(this(ii),str,label);
            end
        end

        function out = setLabelsFromConvenienceCommand(this,label,str,nvInputs)
            arguments
                this controllib.chart.internal.foundation.AbstractPlot
                label (1,1) string {mustBeMember(label,["Title","Subtitle","XLabel","YLabel"])}
                str (:,1) string
                nvInputs.FontName (1,1) string
                nvInputs.FontSize (1,1) double {mustBePositive,mustBeFinite}
                nvInputs.FontWeight (1,1) string {mustBeMember(nvInputs.FontWeight,["normal","bold"])}
                nvInputs.FontAngle (1,1) string {mustBeMember(nvInputs.FontAngle,["normal","italic"])}
                nvInputs.Color {validatecolor(nvInputs.Color)}
                nvInputs.Interpreter (1,1) string {mustBeMember(nvInputs.Interpreter,["none","tex","latex"])}
                nvInputs.Rotation (1,1) double {mustBeReal,mustBeNonNan,mustBeFinite}
            end
            fs = fieldnames(nvInputs);
            out = cell(size(this));
            for ii = 1:numel(this)
                this(ii).(label).String = getValidLabelString(this(ii),str,label);
                for jj = 1:length(fs)
                    if strcmp(fs{jj},"Color")
                        if ~isequal(this(ii).(label).Color,validatecolor(nvInputs.Color))
                            this(ii).(label).Color = nvInputs.Color;
                        end
                    else
                        this(ii).(label).(fs{jj}) = nvInputs.(fs{jj});
                    end
                end
                this(ii).(label).Visible = true;
                out{ii} = this(ii).(label);
            end
        end
    end

    methods(Access={?matlab.graphics.mixin.internal.Copyable, ?matlab.graphics.internal.CopyContext}, Hidden)
        function thisCopy = copyElement(this)

            % Initialize chart
            thisCopy = copyElement@matlab.graphics.chartcontainer.ChartContainer(this);
            for ii = 1:length(this.Responses)
                registerResponse(thisCopy,copy(this.Responses(ii)));
            end
            % Copy options overwritten by defaults in constructor
            postCopyInitialization(this,thisCopy);

            % Save focus
            if thisCopy.XLimitsFocusFromResponses
                xLimFocus = [];
            else
                xLimFocus = thisCopy.XLimitsFocus;
                thisCopy.XLimitsFocusFromResponses = true;
            end
            if thisCopy.YLimitsFocusFromResponses
                yLimFocus = [];
            else
                yLimFocus = thisCopy.YLimitsFocus;
                thisCopy.YLimitsFocusFromResponses = true;
            end

            % Set visible state
            thisCopy.Visible = this.Visible;

            % Copy focus
            if ~isempty(xLimFocus)
                thisCopy.XLimitsFocus = xLimFocus;
            end
            if ~isempty(yLimFocus)
                thisCopy.YLimitsFocus = yLimFocus;
            end

            % Copy characteristics
            if ~isempty(this.Characteristics)
                chars = properties(this.Characteristics);
                for ii = 1:length(chars)
                    charProps = properties(thisCopy.Characteristics.(chars{ii}));
                    for jj = 1:length(charProps)
                        thisCopy.Characteristics.(chars{ii}).(charProps{jj}) = this.Characteristics.(chars{ii}).(charProps{jj});
                    end
                end
            end

            % Copy non-response children
            setNextPlotOnAxes(thisCopy);
            if ~isempty(this.PlotChildrenForLegend)
                validPlotChildren = this.PlotChildrenForLegend(isvalid(this.PlotChildrenForLegend));
                if isempty(validPlotChildren)
                    nChildren = 0;
                else
                    legendChildrenTags = arrayfun(@(x) x.Tag,validPlotChildren,UniformOutput=false);
                    legendChildrenTags = legendChildrenTags(:)';
                    nonResponseChildrenLegendIdx = find(~contains(legendChildrenTags,'legendObjectForControlChartResponse'));
                    nonResponseChildren = validPlotChildren(nonResponseChildrenLegendIdx);
                    nChildren = length(nonResponseChildren);
                    nonResponseChildrenParent = zeros(nChildren,1);
                    ax = getChartAxes(this);
                    for ii = 1:nChildren
                        nonResponseChildrenParent(ii) = find(ax==nonResponseChildren(ii).Parent,1);
                    end
                end
                if nChildren > 0
                    holdState = thisCopy.NextPlot;
                    thisCopy.NextPlot = "add";
                    ax = getChartAxes(thisCopy);
                    nChildren = length(nonResponseChildren);
                    newChildren = nonResponseChildren;
                    childrenWithLegend = false(size(newChildren));
                    for ii = 1:nChildren
                        newChildren(ii) = copyobj(nonResponseChildren(ii),ax(nonResponseChildrenParent(ii)));
                        if isprop(nonResponseChildren(ii),'LegendDisplay')
                            childrenWithLegend(ii) = nonResponseChildren(ii).LegendDisplay;
                        end
                    end
                    thisCopy.PlotChildrenForLegend = thisCopy.PlotChildrenForLegend(1:end-nnz(childrenWithLegend));
                    for ii = 1:nChildren
                        idx = nonResponseChildrenLegendIdx(ii);
                        thisCopy.PlotChildrenForLegend = [thisCopy.PlotChildrenForLegend(1:idx-1); ...
                            newChildren(ii); ...
                            thisCopy.PlotChildrenForLegend(idx:end)];
                    end
                    thisCopy.NextPlot = holdState;
                end
            end

            % Show legend
            if this.LegendVisible
                legend(thisCopy,'show');
            end

            % Add legend button to toolbar if needed
            if ~isempty(this.LegendButton)
                addLegendButtonToToolbar(thisCopy);
            end

            for ii = 1:length(this.Requirements)
                addConstraintView(thisCopy,copy(this.Requirements(ii)));
            end

            % Initialize TuningGoal
            if ~isempty(this.TuningGoalPlotManager)
                addTuningGoalPlotManager(thisCopy,copy(this.TuningGoalPlotManager));
            end
        end
    end

    %% Static methods
    methods (Static)
        function thisLoaded = doloadobj(thisLoaded)
            upgradeToLatestVersion(thisLoaded);
            % Initialize chart
            thisLoaded.Visible = false; %delay build
            initialize(thisLoaded);
            for ii = 1:length(thisLoaded.SavedValues.Responses)
                registerResponse(thisLoaded,thisLoaded.SavedValues.Responses(ii));
            end
            postLoadInitialization(thisLoaded)

            % Save focus
            if thisLoaded.XLimitsFocusFromResponses
                xLimFocus = [];
            else
                xLimFocus = thisLoaded.XLimitsFocus;
            end
            if thisLoaded.YLimitsFocusFromResponses
                yLimFocus = [];
            else
                yLimFocus = thisLoaded.YLimitsFocus;
            end

            thisLoaded.Visible = true; % build

            % Load limits focus
            if ~isempty(xLimFocus)
                thisLoaded.XLimitsFocus = xLimFocus;
            end
            if ~isempty(yLimFocus)
                thisLoaded.YLimitsFocus = yLimFocus;
            end

            % Load characteristics
            if isfield(thisLoaded.SavedValues,'Characteristics')
                chars = fieldnames(thisLoaded.SavedValues.Characteristics);
                for ii = 1:length(chars)
                    thisLoaded.Characteristics.(chars{ii}).Visible = thisLoaded.SavedValues.Characteristics.(chars{ii}).Visible;
                end
            end

            % Add non-response children
            setNextPlotOnAxes(thisLoaded);
            if isfield(thisLoaded.SavedValues,'NonResponseChildren')
                holdState = thisLoaded.NextPlot;
                thisLoaded.NextPlot = "add";
                ax = getChartAxes(thisLoaded);
                nChildren = length(thisLoaded.SavedValues.NonResponseChildren);
                childrenWithLegend = false(size(thisLoaded.SavedValues.NonResponseChildren));
                for ii = 1:nChildren
                    thisLoaded.SavedValues.NonResponseChildren(ii).Parent = ax(thisLoaded.SavedValues.NonResponseChildrenParent(ii));
                    if isprop(thisLoaded.SavedValues.NonResponseChildren(ii),'LegendDisplay')
                        childrenWithLegend(ii) = thisLoaded.SavedValues.NonResponseChildren(ii).LegendDisplay;
                    end
                end
                thisLoaded.PlotChildrenForLegend = thisLoaded.PlotChildrenForLegend(1:end-nnz(childrenWithLegend));
                for ii = 1:nChildren
                    idx = thisLoaded.SavedValues.NonResponseChildrenLegendIdx(ii);
                    thisLoaded.PlotChildrenForLegend = [thisLoaded.PlotChildrenForLegend(1:idx-1); ...
                        thisLoaded.SavedValues.NonResponseChildren(ii); ...
                        thisLoaded.PlotChildrenForLegend(idx:end)];
                end
                thisLoaded.NextPlot = holdState;
            end

            % Show legend
            if thisLoaded.LegendVisible
                legend(thisLoaded,'show');
            end

            % Add legend button to toolbar if needed
            if thisLoaded.SavedValues.IsLegendButtonOnToolbar
                addLegendButtonToToolbar(thisLoaded);
            end

            % Add requirements
            if isfield(thisLoaded.SavedValues,'Requirements')
                for ii = 1:length(thisLoaded.SavedValues.Requirements)
                    addConstraintView(this,thisLoaded.SavedValues.Requirements(ii));
                end
            end

            % Initialize TuningGoal
            if isfield(thisLoaded.SavedValues,'TuningGoalPlotManager')
                addTuningGoalPlotManager(thisLoaded,thisLoaded.SavedValues.TuningGoalPlotManager);
            end

            thisLoaded.SavedValues = [];
        end
    end

    %% Protected methods
    methods (Access = protected)
        function initialize(this)
            % Set StyleManager
            this.StyleManager = controllib.chart.internal.options.ResponseStyleManager;

            % Set Visible
            if ~this.Visible
                L = addlistener(this,"Visible","PostSet",@(es,ed) cbVisibilityChanged(this));
                registerListeners(this,L,"VisibilityChanged");
            end

            % Add listener for theme changed
            % L = addlistener(this,'ThemeChanged',@(es,ed) cbFigureThemeChanged(this));
            % registerListeners(this,L,"ThemeChanged");

            % Set Tag
            this.ID = matlab.lang.internal.uuid;


            % Set Labels
            createLabels(this);
        end

        function upgradeToLatestVersion(thisLoaded)
            thisLoaded.Version = matlabRelease;
        end

        function flag = isVersionOlderThan(this,release,stage,update)
            arguments
                this (1,1) controllib.chart.internal.foundation.AbstractPlot
                release (1,1) string {controllib.chart.internal.foundation.AbstractPlot.mustBeValidRelease}
                stage (1,1) string {mustBeMember(stage,["prerelease" "release"])} = "prerelease"
                update (1,1) double {mustBeInteger, mustBeNonnegative} = 0
            end
            if lower(release) == lower(this.Version.Release)
                if stage == this.Version.Stage
                    flag =  update > this.Version.Update;
                else
                    flag =  stage > this.Version.Stage;
                end
            else
                flag =  lower(release) > lower(this.Version.Release);
            end
        end

        function postLoadInitialization(thisLoaded)
            % Load handles
            thisLoaded.StyleManager = thisLoaded.SavedValues.StyleManager;
            % Load labels
            labelProps = controllib.chart.internal.options.AxesLabel.getCopyableProperties();
            for ii = 1:length(labelProps)
                thisLoaded.Title.(labelProps(ii)) = thisLoaded.SavedValues.Labels.Title.(labelProps(ii));
                thisLoaded.Subtitle.(labelProps(ii)) = thisLoaded.SavedValues.Labels.Subtitle.(labelProps(ii));
                thisLoaded.XLabel.(labelProps(ii)) = thisLoaded.SavedValues.Labels.XLabel.(labelProps(ii));
                thisLoaded.YLabel.(labelProps(ii)) = thisLoaded.SavedValues.Labels.YLabel.(labelProps(ii));
            end
            axesProps = controllib.chart.internal.options.AxesStyle.getCopyableProperties();
            for ii = 1:length(axesProps)
                thisLoaded.AxesStyle.(axesProps(ii)) = thisLoaded.SavedValues.Labels.AxesStyle.(axesProps(ii));
            end
            % Load limits
            thisLoaded.XLimits = thisLoaded.SavedValues.XLimits;
            thisLoaded.XLimitsMode = thisLoaded.SavedValues.XLimitsMode;
            thisLoaded.YLimits = thisLoaded.SavedValues.YLimits;
            thisLoaded.YLimitsMode = thisLoaded.SavedValues.YLimitsMode;
        end

        function postCopyInitialization(this,thisCopy)
            % Copy handles
            thisCopy.StyleManager = copy(this.StyleManager);
            thisCopy.CreateResponseDataTipsOnDefault = this.CreateResponseDataTipsOnDefault;
            setoptions(thisCopy,getoptions(this));
            % Copy labels
            labelProps = controllib.chart.internal.options.AxesLabel.getCopyableProperties();
            for ii = 1:length(labelProps)
                thisCopy.Title.(labelProps(ii)) = this.Title.(labelProps(ii));
                thisCopy.Subtitle.(labelProps(ii)) = this.Subtitle.(labelProps(ii));
                thisCopy.XLabel.(labelProps(ii)) = this.XLabel.(labelProps(ii));
                thisCopy.YLabel.(labelProps(ii)) = this.YLabel.(labelProps(ii));
            end
            axesProps = controllib.chart.internal.options.AxesStyle.getCopyableProperties();
            for ii = 1:length(axesProps)
                thisCopy.AxesStyle.(axesProps(ii)) = this.AxesStyle.(axesProps(ii));
            end
            % Copy limits
            thisCopy.XLimits = this.XLimits;
            thisCopy.XLimitsMode = this.XLimitsMode;
            thisCopy.YLimits = this.YLimits;
            thisCopy.YLimitsMode = this.YLimitsMode;
        end

        function setup(this)
            tcl = getLayout(this);
            tcl.Copyable = false;
            tcl.HandleVisibility = 'off';
        end

        function update(this)
            % Parent context menu
            if ~isempty(this.ContextMenu) && isvalid(this.ContextMenu)
                this.ContextMenu.Parent = ancestor(this,'figure');
            end

            % Updates for theme changes
            if ~isempty(this.View) && isvalid(this.View)
                ax = getChartAxes(this);
                if numel(ax(1).YAxis) > 1
                    updateAxesStyle(this.View);
                end
                if ~strcmp(ax(1).YAxisLocation,'right')
                    this.StyleManager.ColorOrder = mat2cell(ax(1).ColorOrder,ones(1,size(ax(1).ColorOrder,1)),3);
                end

                % Need to update color on legend object (if semantic colors
                % used)
                for k = 1:length(this.Responses)
                    if isvalid(this.Responses(k))
                        responseView = getResponseView(this.View,this.Responses(k));
                        if ~isempty(responseView) && isvalid(responseView)
                            updateLegendObjectOnThemeChange(responseView,this.Theme);
                        end
                    end
                end

                refreshLegend(this);
            end

            % Update responses if dirty
            for k = 1:length(this.Responses)
                if ~isempty(this.Responses(k).IsDirty) && this.Responses(k).IsDirty ...
                        && this.Responses(k).Visible && this.Responses(k).ShowInView
                    disableListeners(this,"ResponseDirty_"+this.Responses(k).Tag);
                    this.Responses(k).IsChartUpdatingResponse = true;
                    update(this.Responses(k));
                    this.Responses(k).IsChartUpdatingResponse = false;
                    enableListeners(this,"ResponseDirty_"+this.Responses(k).Tag);
                end
            end
            this.IsResponseDirty = false;

            % Update response visibility
            if this.HasResponseVisibilityChanged
                for k = 1:length(this.Responses)
                    response = this.Responses(k);
                    if ~isempty(this.View)
                        responseView = getResponseView(this.View,response);
                        %protect against changing array size
                        if ~isempty(responseView) && ...
                                isequal(responseView.Response.NResponses,response.NResponses)
                            updateResponseVisibility(this.View,response);
                        end
                    end
                end
                if ~isempty(this.View) && isvalid(this.View)
                    updateFocus(this.View);
                end
                updateXLimitsWidget(this);
                updateYLimitsWidget(this);
                setCharacteristicVisibility(this);
                this.HasResponseVisibilityChanged = false;
            end
        end

        function [style,styleIndex] = dealNextSystemStyle(this)
            % dealNextSystemStyle: Return the style object for the next
            %   response based on StyleManager.
            %
            %   style = dealNextSystemStyle(h)
            if ~isempty(this.Responses)
                styleIndicesInUse = this.ResponseStyleIndex(this.ResponseStyleIndex~=0);
                styleIndicesNotUsed = setdiff((1:length(this.Responses))',sort(styleIndicesInUse(:)));
                if isempty(styleIndicesNotUsed)
                    styleIndex = length(this.Responses)+1;
                else
                    styleIndex = min(styleIndicesNotUsed);
                end
            else
                styleIndex = 1;
            end
            % Generate style
            style = getStyle(this.StyleManager,styleIndex);
        end

        function name = getNextSystemName(this)
            % getNextSystemName: Return the name for the next response
            %   based on existing responses
            %
            %   name = getNextSystemName(h)
            allAutoNames = "untitled" + string(1:length(this.Responses)+1);
            if ~isempty(this.Responses)
                allAutoNames = setdiff(allAutoNames,[this.Responses.Name]);
            end
            name = allAutoNames(1);
        end

        function addResponseToChart(this,newResponses,color,lineStyle,markerStyle,lineWidth,nameValueArguments)
            % To make private. Sub classes can use registerResponse.

            arguments
                this
                newResponses controllib.chart.internal.foundation.BaseResponse
                color               = []
                lineStyle string    = string.empty
                markerStyle string  = string.empty
                lineWidth double    = []
                nameValueArguments.ResponseView = []
            end

            if isempty(this.Responses)
                if isprop(newResponses.ResponseData,"CharacteristicTypes")
                    this.CharacteristicTypes = newResponses.ResponseData.CharacteristicTypes;
                else
                    this.CharacteristicTypes = "";
                end
            end
            this.Responses_I = [this.Responses; newResponses];

            % Disable Axes ChildAdded listeners
            enableOnCleanUp = disableListeners(this,"ChildAddedToAxes",EnableOnCleanUp=true); %#ok<NASGU>

            % Add responses to view
            for k = 1:length(newResponses)
                % Set flag on response whether to throw warning on data
                % exception
                newResponses(k).DataExceptionMessage = this.ResponseDataExceptionMessage;
                % Set color if specified
                if ~isempty(color)
                    if strcmpi(newResponses(k).Style.ViewType,'Line')
                        newResponses(k).Style.Color = color;
                    else
                        newResponses(k).Style.FaceColor = color;
                        newResponses(k).Style.EdgeColor = color;
                        newResponses(k).Style.FaceAlpha = 1;
                        newResponses(k).Style.EdgeAlpha = 1;
                    end
                end
                % Set name if needed
                if strcmp(newResponses(k).Name,"")
                    newResponses(k).Name = getNextSystemName(this);
                end
                % Set linestyle if specified
                if ~strcmp(lineStyle,"")
                    newResponses(k).Style.LineStyle = lineStyle;
                end
                % Set markerstyle if specified
                if ~strcmp(markerStyle,"")
                    newResponses(k).Style.MarkerStyle = markerStyle;
                end
                % Set linewidth if specified
                if ~isempty(lineWidth)
                    newResponses(k).Style.LineWidth = lineWidth;
                end

                % Add response
                if ~isempty(this.View) && isvalid(this.View)
                    if isempty(nameValueArguments.ResponseView)
                        responseView = createResponseView(this,newResponses(k));
                        if isempty(responseView)
                            responseView = addResponseView(this.View,newResponses(k));
                        else
                            if ~responseView.IsResponseViewValid
                                build(responseView);
                            end
                            registerResponseView(this.View,responseView);
                        end
                    else
                        registerResponseView(this.View,nameValueArguments.ResponseView);
                        responseView = nameValueArguments.ResponseView;
                    end

                    % Update response visibility if ShowInView is off
                    if ~newResponses(k).ShowInView
                        updateResponseVisibility(this.View,newResponses(k));
                    end

                    % Update focus
                    updateFocusWithRequirements(this,ForceRequirementFocus=true);

                    % Update Legend PlotChildren
                    addResponseViewToPlotChildrenForLegend(this,responseView);

                    % Create response data tips for responseView if needed
                    if this.CreateResponseDataTipsOnDefault
                        createResponseDataTips(responseView);
                    end
                end

                % Add to systems visible menu in the context menu
                if ~isempty(this.ResponsesMenu)
                    addVisibleMenu(newResponses(k),this.ResponsesMenu);
                end

                % Add listeners to systems
                addResponseListeners(this,newResponses(k));

                % Add characteristics menu if needed
                createCharacteristicOptions(this,newResponses(k));
            end

            % Create custom characteristics for new systems
            for kc = 1:size(this.CustomCharacteristicInfo,1)
                characteristicType = createCustomCharacteristic(this,this.CustomCharacteristicInfo(kc).DataFcn,...
                    this.CustomCharacteristicInfo(kc).ViewFcn,this.CustomCharacteristicInfo(kc).MenuLabel,...
                    Systems=newResponses);
                setCharacteristicVisibility(this,characteristicType);
            end

            setCharacteristicVisibility(this);

            % Call for post-processing
            postAddResponse(this);
        end

        function addResponseListeners(this,responses)
            arguments
                this
                responses = this.Responses
            end
            for k = 1:length(responses)
                L1 = addlistener(responses(k),'ResponseDeleted',...
                    @(es,ed) cbResponseDeleted(this));
                L2 = addlistener(responses(k),'Visible','PostSet',...
                    @(es,ed) set(this,HasResponseVisibilityChanged=true));
                L3 = addlistener(responses(k),'ArrayVisible','PostSet',...
                    @(es,ed) set(this,HasResponseVisibilityChanged=true));
                L4 = addlistener(responses(k),'ResponseChanged',...
                    @(es,ed) cbResponseChanged(this,responses(k)));
                L5 = addlistener(responses(k),'LegendDisplay','PostSet',...
                    @(es,ed) updateLegendPlotChildren(this));
                L1Name = "ResponseDeletedListener_" + responses(k).Tag;
                L2Name = "ResponseVisibleListener_" + responses(k).Tag;
                L3Name = "ResponseArrayVisibleListener_" + responses(k).Tag;
                L4Name = "ResponseChangedListener_" + responses(k).Tag;
                L5Name = "ResponseLegendDisplayListener_" + responses(k).Tag;
                registerListeners(this,[L1;L2;L3;L4;L5],[L1Name;L2Name;L3Name;L4Name;L5Name])

                if this.SynchronizeResponseUpdates
                    responses(k).IsParentedToChart = true;
                    responses(k).IsDirty = false;
                    L = addlistener(responses(k),'IsDirty','PostSet', @(es,ed) cbResponseDirty(this,ed));
                    registerListeners(this,L,"ResponseDirtyListener_"+responses(k).Tag);
                    L = addlistener(responses(k),'ShowInView','PostSet',@(es,ed) set(this,HasResponseVisibilityChanged=true));
                    registerListeners(this,L,"ResponseEnableListener_"+responses(k).Tag);
                end
            end

            function cbResponseDirty(this,ed)
                this.IsResponseDirty = this.IsResponseDirty || ed.AffectedObject.IsDirty;
            end
        end

        function createView(this)
            this.View = createView_(this);
            registerCharacteristicTypes(this.View,this.CharacteristicTypes);
        end

        function connectView(this) %#ok<MANU>
        end

        function tf = hasCustomGrid(~)
            tf = false;
        end

        function createCharacteristicOptions(this,response)
            arguments
                this
                response controllib.chart.internal.foundation.BaseResponse
            end

            if isprop(response.ResponseData,"CharacteristicTypes")
                for k = 1:length(response.ResponseData.CharacteristicTypes)
                    charType = response.ResponseData.CharacteristicTypes(k);
                    data = getCharacteristics(response.ResponseData,charType);
                    if isempty(getCharacteristicOption(this,charType)) && ~isempty(data)
                        cm = createCharacteristicOptions_(this,charType);
                        if ~isempty(cm)
                            cm.Tag = charType;
                            if isempty(cm.VisibilityChangedFcn)
                                cm.VisibilityChangedFcn = @(es,ed) setCharacteristicVisibility(this,charType);
                            end
                            if ~isempty(this.ContextMenu)
                                createCharacteristicsMenu(this,cm);
                            end
                            if ~isempty(this.View) && isvalid(this.View)
                                registerCharacteristicTypes(this.View,charType);
                            end
                            addToCharacteristicManager(this,charType,cm);

                            this.CharacteristicOptions = [this.CharacteristicOptions, cm];

                        end
                    end
                end
            end

            if ~isempty(this.CharacteristicOptions)
                this.CharacteristicTypes = [this.CharacteristicOptions.Tag];
            end
        end

        function value = getCharacteristicOption(this,characteristicType)
            value = [];
            if ~isempty(this.CharacteristicOptions)
                idx = characteristicType == [this.CharacteristicOptions.Tag];
                value = this.CharacteristicOptions(idx);
            end
        end

        function removeCharacteristicOption(this,characteristicType)
            arguments
                this
                characteristicType (1,1) string
            end
            if ~isempty(this.CharacteristicOptions)
                if ~isempty(this.View) && isvalid(this.View)
                    unregisterCharacteristicTypes(this.View,characteristicType);
                end
                idx = characteristicType == [this.CharacteristicOptions.Tag];
                delete(this.CharacteristicOptions(idx));
                this.CharacteristicOptions(idx) = [];
                this.CharacteristicTypes = [this.CharacteristicOptions.Tag];

                removeCharacteristicOption(this.CharacteristicManager,characteristicType);
            end
        end

        function createContextMenu(this)
            % Create ContextMenu

            if isempty(this.Parent)
                parent = [];
            else
                parent = ancestor(this,'figure');
            end

            this.ContextMenu = uicontextmenu(Parent=parent,Internal=true);
            ax = getChartAxes(this);
            for k = 1:length(ax(:))
                ax(k).ContextMenu = this.ContextMenu;
            end

            % Responses Menu
            this.ResponsesMenu = uimenu(this.ContextMenu,...
                "Text",getString(message('Controllib:plots:strResponses')),...
                "Tag","systems");

            % Characteristics Menu (override in subclass)
            createCharacteristicsMenu(this,this.CharacteristicOptions);

            % Array selector menu
            this.ArraySelectorMenu = uimenu(this.ContextMenu,...
                "Text",getString(message('Controllib:plots:strArraySelectorLabel')),...
                "Tag","arrayselector",...
                "Separator","on",...
                "MenuSelectedFcn",@(es,ed) openArraySelectorDialog(this));

            % Grid Menu
            this.GridMenu = uimenu(this.ContextMenu,...
                "Text",getString(message('Controllib:gui:strGrid')),...
                "Tag","grid",...
                "Checked",this.AxesStyle.GridVisible,...
                "Separator","on",...
                "MenuSelectedFcn",@(es,ed) set(this.AxesStyle,GridVisible=~this.AxesStyle.GridVisible));

            % Full View Menu
            this.FullViewMenu = uimenu(this.ContextMenu,...
                "Text",getString(message('Controllib:plots:strFullView')),...
                "Tag","fullview",...
                "Checked",isFullViewEnabled(this),...
                "MenuSelectedFcn",@(es,ed) enableFullView(this));

            % Property Menu create
            this.PropertyMenu = uimenu(this.ContextMenu,...
                "Text",getString(message('Controllib:plots:strPropertiesLabel')),...
                "Tag","propertyeditor",...
                "Separator","on",...
                "MenuSelectedFcn",@(es,ed) openPropertyDialog(this));

            % Add callback on Context Menu opening to update menu item states
            this.ContextMenu.ContextMenuOpeningFcn = @(es,ed) cbContextMenuOpening(this);
        end

        function createCharacteristicsMenu(this,characteristicManagers)
            arguments
                this
                characteristicManagers
            end
            if isempty(this.CharacteristicsMenu)
                this.CharacteristicsMenu = uimenu("Parent",[],...
                    "Text",getString(message('Controllib:plots:strCharacteristics')),"Tag",'characteristics');
                addMenu(this,this.CharacteristicsMenu,Below="systems");
            end

            for k = 1:length(characteristicManagers)
                addVisibleMenu(characteristicManagers(k),this.CharacteristicsMenu);
            end
        end

        function cbContextMenuOpening(this)
            % Overload in subclass if needed
            this.ResponsesMenu.Visible = ~isempty(this.Responses);
            this.GridMenu.Checked = this.AxesStyle.GridVisible;
            this.FullViewMenu.Checked = isFullViewEnabled(this);
            this.FullViewMenu.Enable = ~isFullViewEnabled(this);
            this.CharacteristicsMenu.Visible = ~isempty(this.CharacteristicOptions);

            if ~isempty(this.Responses)
                arrayDimensions = {this.Responses.ArrayDim};
                isArray = any(cellfun(@(x) prod(x)>1,arrayDimensions));
                this.ArraySelectorMenu.Visible = isArray;
            else
                this.ArraySelectorMenu.Visible = false;
            end
        end

        function buildLabelsTab(this)
            % Build Labels Widget
            if isempty(this.LabelsWidget) || ~isvalid(this.LabelsWidget)
                buildLabelsWidget(this);
            end

            % Add widget to tab
            if ~isempty(this.LabelsWidget)
                addTab(this.PropertyEditorDialog,"Labels",getWidget(this.LabelsWidget));
            end
        end

        function buildLimitsTab(this)
            % Widgets
            if isempty(this.XLimitsWidget) || ~isvalid(this.XLimitsWidget)
                buildXLimitsWidget(this);
            end
            disableListeners(this,'XLimitsChangedInPropertyEditor');
            updateXLimitsWidget(this);
            enableListeners(this,'XLimitsChangedInPropertyEditor');

            if isempty(this.YLimitsWidget) || ~isvalid(this.YLimitsWidget)
                buildYLimitsWidget(this);
            end
            disableListeners(this,'YLimitsChangedInPropertyEditor');
            updateYLimitsWidget(this);
            enableListeners(this,'YLimitsChangedInPropertyEditor');

            % Limits layout
            layout = uigridlayout('Parent',[],'RowHeight',{'fit','fit'},'ColumnWidth',{'1x'});
            layout.Padding = 0;

            % Put widgets in layout
            if ~isempty(this.XLimitsWidget)
                w = getWidget(this.XLimitsWidget);
                w.Parent = layout;
                w.Layout.Row = 1;
                w.Layout.Column = 1;
            end
            if ~isempty(this.YLimitsWidget)
                w = getWidget(this.YLimitsWidget);
                w.Parent = layout;
                w.Layout.Row = 2;
                w.Layout.Column = 1;
            end

            % Add tab
            addTab(this.PropertyEditorDialog,"Limits",layout);
        end

        function buildUnitsTab(this)
            % Build widget if needed
            if isempty(this.UnitsWidget) || ~isvalid(this.UnitsWidget)
                buildUnitsWidget(this);
            end
            updateUnitsWidget(this);

            if ~isempty(this.UnitsWidget)
                addTab(this.PropertyEditorDialog,"Units",getWidget(this.UnitsWidget));
            end
        end

        function buildStyleTab(this)
            % Grid widget
            if isempty(this.GridWidget) || ~isvalid(this.GridWidget)
                buildGridWidget(this);
            end

            % Fonts Widget
            if isempty(this.FontsWidget) || ~isvalid(this.FontsWidget)
                buildFontsWidget(this);
            end

            % Color Widget
            if isempty(this.ColorWidget) || ~isvalid(this.ColorWidget)
                buildColorWidget(this);
            end

            % Style Container
            layout = uigridlayout('Parent',[],'RowHeight',{'fit','fit','fit'},'ColumnWidth',{'1x'});
            layout.Padding = 0;

            % Put widgets in layout
            if ~isempty(this.GridWidget)
                w = getWidget(this.GridWidget);
                w.Parent = layout;
                w.Layout.Row = 1;
                w.Layout.Column = 1;
            end
            if ~isempty(this.FontsWidget)
                w = getWidget(this.FontsWidget);
                w.Parent = layout;
                w.Layout.Row = 2;
                w.Layout.Column = 1;
            end
            if ~isempty(this.ColorWidget)
                w = getWidget(this.ColorWidget);
                w.Parent = layout;
                w.Layout.Row = 3;
                w.Layout.Column = 1;
            end

            % Add in tab
            addTab(this.PropertyEditorDialog,"Style",layout);
        end

        function buildOptionsTab(this) %#ok<MANU>
            % Overload in subclass if needed
        end

        function createCharacteristicOptions_(this,response) %#ok<INUSD>
            % Implement in subclass if needed
        end

        function cbResponseChanged(this,response)
            % Check if characteristics need to be removed
            data = [this.Responses.ResponseData];
            dataChars = string.empty;
            for ii = 1:length(data)
                dataChars = union(dataChars,data(ii).CharacteristicTypes);
            end
            charsToRemove = setdiff(this.CharacteristicTypes,dataChars);
            for k = 1:length(charsToRemove)
                removeCharacteristicOption(this,charsToRemove(k));
            end
            % Add new characteristics
            createCharacteristicOptions(this,response);

            if ~isempty(this.View) && isvalid(this.View)
                currentResponseView = getResponseView(this.View,response);
                plotObjectsForLegend = getLegendObjects(currentResponseView);
                plotObjectsForLegendIdx = arrayfun(@(x) find(this.PlotChildrenForLegend==x,1),plotObjectsForLegend);
                updateResponseView(this.View,response);
                % Check if response view was deleted. If so, get the new
                % response view and add to PlotChildren for Legend.
                if ~isvalid(currentResponseView)
                    newResponseView = getResponseView(this.View,response);
                    plotObjectsForLegend = getLegendObjects(newResponseView);
                    for ii = 1:numel(plotObjectsForLegend)
                        this.PlotChildrenForLegend = [this.PlotChildrenForLegend(1:plotObjectsForLegendIdx(ii)-1);...
                            plotObjectsForLegend(ii);this.PlotChildrenForLegend(plotObjectsForLegendIdx(ii):end)];
                    end
                    updateLegendPlotChildren(this);
                end
                if isempty(this.Requirements)
                    updateFocus(this.View);
                else
                    updateFocusWithRequirements(this);
                end
            end
        end

        function cbResponseDeleted(this)
            idx = isvalid(this.Responses);

            % Remove associated responses
            responsesBeingDeleted = this.Responses(~idx);
            if ~isempty(this.View) && isvalid(this.View)
                for k = 1:length(responsesBeingDeleted)
                    responseViewToDelete = getResponseView(this.View,responsesBeingDeleted(k));
                    if ~isempty(responseViewToDelete)
                        deleteResponseView(this.View,responseViewToDelete);
                    end
                end
            end

            this.Responses_I = this.Responses_I(idx);
            this.ResponseStyleIndex(~idx) = [];

            % Check if characteristics need to be removed
            if isempty(this.Responses)
                charsToRemove = this.CharacteristicTypes;
                for k = 1:length(charsToRemove)
                    removeCharacteristicOption(this,charsToRemove(k));
                end
            else
                data = [this.Responses.ResponseData];
                dataChars = string.empty;
                for ii = 1:length(data)
                    dataChars = union(dataChars,data(ii).CharacteristicTypes);
                end
                charsToRemove = setdiff(this.CharacteristicTypes,dataChars);
                for k = 1:length(charsToRemove)
                    removeCharacteristicOption(this,charsToRemove(k));
                end
            end

            % Clear invalid plot children
            if ~isempty(this.PlotChildrenForLegend)
                this.PlotChildrenForLegend = this.PlotChildrenForLegend(isvalid(this.PlotChildrenForLegend));
            end

            % Update view based on remaining valid responses
            if ~isempty(this.View) && isvalid(this.View)
                updateFocus(this.View);
            end
        end

        function postAddResponse(this) %#ok<MANU>
            % Overload in subclass
        end

        function groupNames = getGroupNamesForXLimitsWidget(this) %#ok<MANU>
            groupNames = "";
        end

        function limitNames = getLimitNamesForXLimitsWidget(this) %#ok<MANU>
            limitNames = "";
        end

        function buildXLimitsWidget(this)
            % Create and configure LimitsContainer for xlimits
            groupNames = getGroupNamesForXLimitsWidget(this);
            limitNames = getLimitNamesForXLimitsWidget(this);
            this.XLimitsWidget = controllib.widget.internal.cstprefs.LimitsContainer(...
                NumberOfGroups = length(groupNames),...
                NumberOfLimits = length(limitNames));
            this.XLimitsWidget.GroupItems = groupNames;
            this.XLimitsWidget.LimitsLabelText = limitNames;
            this.XLimitsWidget.ContainerTitle = getString(message('Controllib:gui:strXLimits'));

            % Add listeners for widget to data
            registerListeners(this,addlistener(this.XLimitsWidget,{'AutoScale','Limits'},...
                'PostSet',@(es,ed) cbXLimitsChangedInPropertyEditor(this,es,ed)),'XLimitsChangedInPropertyEditor');
        end

        % Local callback functions
        function cbXLimitsChangedInPropertyEditor(this,es,ed)
            disableListeners(this,'XLimitsChangedInPropertyEditor');
            this.XLimitsWidget.Enable = false;
            limitsWidget = ed.AffectedObject;
            switch es.Name
                case 'AutoScale'
                    if limitsWidget.AutoScale
                        xLimMode = "auto";
                    else
                        xLimMode = "manual";
                    end

                    this.XLimitsMode = xLimMode;
                case 'Limits'
                    this.XLimits = limitsWidget.Limits;
            end
            this.XLimitsWidget.Enable = true;
            updateXLimitsWidget(this);
            enableListeners(this,'XLimitsChangedInPropertyEditor');
        end

        function updateXLimitsWidget(this)
            if ~isempty(this.XLimitsWidget) && isvalid(this.XLimitsWidget) && this.XLimitsWidget.Enable
                setLimits(this.XLimitsWidget,this.XLimits);
                setAutoScale(this.XLimitsWidget,strcmp(this.XLimitsMode,"auto"));
            end
        end

        function groupNames = getGroupNamesForYLimitsWidget(this) %#ok<MANU>
            groupNames = "";
        end

        function limitNames = getLimitNamesForYLimitsWidget(this) %#ok<MANU>
            limitNames = "";
        end

        function buildYLimitsWidget(this)
            % Create and configure LimitsContainer for ylimits
            groupNames = getGroupNamesForYLimitsWidget(this);
            limitNames = getLimitNamesForYLimitsWidget(this);
            this.YLimitsWidget = controllib.widget.internal.cstprefs.LimitsContainer(...
                NumberOfGroups = length(groupNames),...
                NumberOfLimits = length(limitNames));
            this.YLimitsWidget.GroupItems = groupNames;
            this.YLimitsWidget.LimitsLabelText = limitNames;
            this.YLimitsWidget.ContainerTitle = getString(message('Controllib:gui:strYLimits'));

            % Add listeners for widget to data
            registerListeners(this,addlistener(this.YLimitsWidget,{'AutoScale','Limits'},...
                'PostSet',@(es,ed) cbYLimitsChangedInPropertyEditor(this,es,ed)),'YLimitsChangedInPropertyEditor');
        end

        % Local callback functions
        function cbYLimitsChangedInPropertyEditor(this,es,ed)
            disableListeners(this,'YLimitsChangedInPropertyEditor');
            this.YLimitsWidget.Enable = false;
            limitsWidget = ed.AffectedObject;
            switch es.Name
                case 'AutoScale'
                    if limitsWidget.AutoScale
                        yLimMode = "auto";
                    else
                        yLimMode = "manual";
                    end

                    this.YLimitsMode = yLimMode;
                case 'Limits'
                    this.YLimits = limitsWidget.Limits;
            end
            this.YLimitsWidget.Enable = true;
            updateYLimitsWidget(this);
            enableListeners(this,'YLimitsChangedInPropertyEditor');
        end

        function updateYLimitsWidget(this)
            if ~isempty(this.YLimitsWidget) && isvalid(this.YLimitsWidget) && this.YLimitsWidget.Enable
                setLimits(this.YLimitsWidget,this.YLimits);
                setAutoScale(this.YLimitsWidget,strcmp(this.YLimitsMode,"auto"));
            end
        end

        function buildUnitsWidget(this) %#ok<MANU>
            % Overload in subclass if needed
        end

        function updateUnitsWidget(this) %#ok<MANU>
            % Overload in subclass if needed
        end

        function responseView = createResponseView(this,response) %#ok<INUSD>
            responseView = controllib.chart.internal.view.wave.BaseResponseView.empty;
        end

        function [candidateObject, candidateAxes] = processCurrentObjectCandidate(this, candidateObject)
            arguments
                this (1,1)
                candidateObject matlab.graphics.Graphics {mustBeScalarOrEmpty}
            end
            if strcmp(this.CurrentObjectCandidateType,"axes")
                candidateAxes = getCurrentAxes(this);
            else
                candidateAxes = this;
            end
        end

        function addResponseViewToPlotChildrenForLegend(this,responseView)
            plotObjectsForLegend = getLegendObjects(responseView);
            this.PlotChildrenForLegend = [this.PlotChildrenForLegend(:);plotObjectsForLegend(:)];
            updateLegendPlotChildren(this);
        end

        function this = saveobj(this)
            this.SavedValues = [];

            % Responses
            this.SavedValues.Responses = this.Responses;

            % Characteristics
            if ~isempty(this.Characteristics)
                chars = properties(this.Characteristics);
                for ii = 1:length(chars)
                    this.SavedValues.Characteristics.(chars{ii}).Visible = this.Characteristics.(chars{ii}).Visible;
                end
            end

            % Labels
            this.SavedValues.Labels.Title = this.Title;
            this.SavedValues.Labels.Subtitle = this.Subtitle;
            this.SavedValues.Labels.XLabel = this.XLabel;
            this.SavedValues.Labels.YLabel = this.YLabel;
            this.SavedValues.Labels.AxesStyle = this.AxesStyle;

            % Limits
            this.SavedValues.XLimits = this.XLimits;
            this.SavedValues.XLimitsMode = this.XLimitsMode;
            this.SavedValues.YLimits = this.YLimits;
            this.SavedValues.YLimitsMode = this.YLimitsMode;

            % Style Manager
            this.SavedValues.StyleManager = this.StyleManager;

            % Axes Children (for legend)
            if ~isempty(this.View) && isvalid(this.View)
                ax = getChartAxes(this);
                if ~isempty(this.PlotChildrenForLegend)
                    validPlotChildren = this.PlotChildrenForLegend(isvalid(this.PlotChildrenForLegend));
                    if ~isempty(validPlotChildren)
                        legendChildrenTags = arrayfun(@(x) x.Tag,validPlotChildren,UniformOutput=false);
                        legendChildrenTags = legendChildrenTags(:)';
                        this.SavedValues.NonResponseChildrenLegendIdx = ...
                            find(~contains(legendChildrenTags,'legendObjectForControlChartResponse'));
                        this.SavedValues.NonResponseChildren = ...
                            validPlotChildren(this.SavedValues.NonResponseChildrenLegendIdx);
                        this.SavedValues.NonResponseChildrenParent = zeros(size(this.SavedValues.NonResponseChildren));
                        for ii = 1:length(this.SavedValues.NonResponseChildren)
                            this.SavedValues.NonResponseChildrenParent(ii) = find(ax==this.SavedValues.NonResponseChildren(ii).Parent,1);
                        end
                    end
                end
            end

            % Legend button
            this.SavedValues.IsLegendButtonOnToolbar = ~isempty(this.LegendButton);

            % Requirements
            if ~isempty(this.Requirements)
                this.SavedValues.Requirements = this.Requirements;
            end

            % TuningGoal
            if ~isempty(this.TuningGoalPlotManager)
                this.SavedValues.TuningGoalPlotManager = this.TuningGoalPlotManager;
            end
        end
    end

    %% Abstract methods
    methods(Abstract,Access = protected)
        createView_(this);
    end

    %% Protected methods
    methods(Access = protected)
        function cbVisibilityChanged(this)
            % Build the chart if visible and View not created
            if this.Visible
                unregisterListeners(this,'VisibilityChanged');
                build(this);
            end
        end

        function cbResponseStyleManagerChanged(this)
            for k = 1:length(this.Responses)
                % if this.Responses(k).Style.Mode == "auto"
                style = getStyle(this.StyleManager,this.ResponseStyleIndex(k));

                % Copy appropriate values from current response style
                copyPropertiesNotSetByStyleManager(style,this.Responses(k).Style);
                copyPropertiesIfManualMode(style,this.Responses(k).Style);

                % Use existing manual semantic colors if specified in
                % Response Style
                if this.Responses(k).Style.ColorMode == "semantic"
                    style.SemanticColor = this.Responses(k).Style.SemanticColor;
                end
                if this.Responses(k).Style.FaceColorMode == "semantic"
                    style.SemanticFaceColor = this.Responses(k).Style.SemanticFaceColor;
                end
                if this.Responses(k).Style.EdgeColorMode == "semantic"
                    style.SemanticEdgeColor = this.Responses(k).Style.SemanticEdgeColor;
                end

                % Set style object on response
                this.Responses(k).Style = style;
                % end
            end

            ax = getChartAxes(this);
            for k = 1:numel(ax)
                ax(k).ColorOrder = cell2mat(this.StyleManager.ColorOrder);
            end
        end

        function flag = isFullViewEnabled(this)
            isXLimitsAuto = contains(cellstr(this.XLimitsMode),'auto');
            isYLimitsAuto = contains(cellstr(this.YLimitsMode),'auto');
            flag = all(isXLimitsAuto(:)) && all(isYLimitsAuto(:));
        end

        function enableFullView(this)
            this.XLimitsMode = "auto";
            this.YLimitsMode = "auto";
        end

        function permuteResponseMenus(this,~)
            if ~isempty(this.Responses)
                responseNames = [this.Responses.Name];
                menuLabels = string({this.ResponsesMenu.Children.Text});
                % Get the index of menu labels in the order of the response
                % names. Note that some responses might not have a
                % corresponding menu item.
                [~,~,idx] = intersect(responseNames,menuLabels,'stable');
                % Need to flip idx since children are in reverse order
                this.ResponsesMenu.Children = this.ResponsesMenu.Children(flipud(idx(:)));
            end
        end

        function permuteLegendObjects(this)
            this.PlotChildrenForLegend = this.PlotChildrenForLegend(isvalid(this.PlotChildrenForLegend));
            lgdTags = arrayfun(@(x) x.Tag,this.PlotChildrenForLegend,UniformOutput=false);
            lgdIdx = arrayfun(@(x) find(contains(lgdTags,x.Tag)),this.Responses);
            this.PlotChildrenForLegend(sort(lgdIdx)) = this.PlotChildrenForLegend(lgdIdx);
            updateLegendPlotChildren(this);
        end

        function buildPropertyDialog(this)
            this.PropertyEditorDialog = controllib.chart.internal.widget.PropertyEditorDialog.getInstance();
            % Use plot title to set property editor dialog title
            this.PropertyEditorDialog.Title = [getString(message('Controllib:gui:strPropertyEditor')),...
                ' - ', char(this.Title.String)];
            % If property editor dialog is visible, show progress bar
            if this.PropertyEditorDialog.IsVisible
                % this.PropertyEditorDialog.Updating = true;
            end
            %
            % Get selected tab label
            % selectedTabLabel = getSelectedTabLabel(this.PropertyEditorDialog);

            % Remove all tabs
            deleteAllTabs(this.PropertyEditorDialog);

            % Labels Widget
            buildLabelsTab(this);
            % % Limits Widgets
            buildLimitsTab(this);
            % % Units Widget
            buildUnitsTab(this);
            % % Style Tab
            buildStyleTab(this);
            % % Options Tab
            buildOptionsTab(this);
            %
            % % Select Tab
            % selectTab(this.PropertyEditorDialog,selectedTabLabel);

            % Update widgets and remove progress bar
            matlab.graphics.internal.drawnow.startUpdate;
            this.PropertyEditorDialog.Updating = false;
        end

        function buildLabelsWidget(this)
            % Create LabelsContainer
            this.LabelsWidget = controllib.widget.internal.cstprefs.LabelsContainer(...
                NumberOfXLabels=this.getNumXLabels(),NumberOfYLabels=this.getNumYLabels());

            % Initialize Title, XLabel, YLabel
            this.LabelsWidget.Title = this.Title.String;
            for k = 1:this.getNumXLabels()
                this.LabelsWidget.XLabel{k} = this.XLabel.String(k);
            end
            for k = 1:this.getNumYLabels()
                this.LabelsWidget.YLabel{k} = this.YLabel.String(k);
            end

            % Add listeners for widget to data
            registerListeners(this,...
                addlistener(this.LabelsWidget,'Title','PostSet',@(es,ed) cbTitleChangedInPropertyEditor(this,ed)),...
                'TitleChangedInPropertyEditor');
            registerListeners(this,...
                addlistener(this.LabelsWidget,'XLabel','PostSet',@(es,ed) cbXLabelChangedInPropertyEditor(this,ed)),...
                'XLabelChangedInPropertyEditor');
            registerListeners(this,...
                addlistener(this.LabelsWidget,'YLabel','PostSet',@(es,ed) cbYLabelChangedInPropertyEditor(this,ed)),...
                'YLabelChangedInPropertyEditor');

            % Local callback functions
            function cbTitleChangedInPropertyEditor(this,es)
                this.Title.String = es.AffectedObject.(es.Source.Name){1};
            end

            function cbXLabelChangedInPropertyEditor(this,es)
                this.XLabel.String = es.AffectedObject.(es.Source.Name){1};
            end

            function cbYLabelChangedInPropertyEditor(this,es)
                this.YLabel.String = es.AffectedObject.(es.Source.Name);
            end
        end

        function buildGridWidget(this)
            % Build widget
            this.GridWidget = controllib.widget.internal.cstprefs.GridContainer();

            updateGridWidget(this);

            % Setup listeners
            registerListeners(this,...
                addlistener(this.GridWidget,'Value','PostSet',@(es,ed) cbGridChangedInPropertyEditor(this,ed)),...
                'GridChangedInPropertyEditor');

            % Local Callbacks
            function cbGridChangedInPropertyEditor(this,ed)
                this.AxesStyle.GridVisible = ed.AffectedObject.(ed.Source.Name);
            end
        end

        function updateGridWidget(this)
            if ~isempty(this.GridWidget) && isvalid(this.GridWidget)
                this.GridWidget.Value = this.AxesStyle.GridVisible;
            end
        end

        function buildFontsWidget(this)
            % Build widget
            this.FontsWidget = controllib.widget.internal.cstprefs.FontsContainer('Title','XYLabels','AxesLabels');

            updateAllFontsWidget(this);

            % Add listeners for change in widget
            registerListeners(this,...
                addlistener(this.FontsWidget,'TitleFontSize','PostSet',...
                @(es,ed) cbTitleFontSizeChangedInPropertyEditor(this)),'TitleFontSizeChangedInPropertyEditor');
            registerListeners(this,...
                addlistener(this.FontsWidget,'TitleFontWeight','PostSet',...
                @(es,ed) cbTitleFontWeightChangedInPropertyEditor(this)),'TitleFontWeightChangedInPropertyEditor');
            registerListeners(this,...
                addlistener(this.FontsWidget,'TitleFontAngle','PostSet',...
                @(es,ed) cbTitleFontAngleChangedInPropertyEditor(this)),'TitleFontAngleChangedInPropertyEditor');
            registerListeners(this,...
                addlistener(this.FontsWidget,'XYLabelsFontSize',...
                'PostSet',@(es,ed) cbXYLabelsFontSizeChangedInPropertyEditor(this)),'XYLabelsFontSizeChangedInPropertyEditor');
            registerListeners(this,...
                addlistener(this.FontsWidget,'XYLabelsFontWeight',...
                'PostSet',@(es,ed) cbXYLabelsFontWeightChangedInPropertyEditor(this)),'XYLabelsFontWeightChangedInPropertyEditor');
            registerListeners(this,...
                addlistener(this.FontsWidget,'XYLabelsFontAngle',...
                'PostSet',@(es,ed) cbXYLabelsFontAngleChangedInPropertyEditor(this)),'XYLabelsFontAngleChangedInPropertyEditor');
            registerListeners(this,...
                addlistener(this.FontsWidget,'AxesFontSize',...
                'PostSet',@(es,ed) cbAxesFontSizeChangedInPropertyEditor(this)),'AxesFontSizeChangedInPropertyEditor');
            registerListeners(this,...
                addlistener(this.FontsWidget,'AxesFontWeight',...
                'PostSet',@(es,ed) cbAxesFontWeightChangedInPropertyEditor(this)),'AxesFontWeightChangedInPropertyEditor');
            registerListeners(this,...
                addlistener(this.FontsWidget,'AxesFontAngle',...
                'PostSet',@(es,ed) cbAxesFontAngleChangedInPropertyEditor(this)),'AxesFontAngleChangedInPropertyEditor');

            % Local Callbacks
            function cbTitleFontSizeChangedInPropertyEditor(this)
                disableListeners(this,'TitleFontSizeChangedInPropertyEditor');
                this.Title.FontSize = this.FontsWidget.TitleFontSize;
                enableListeners(this,'TitleFontSizeChangedInPropertyEditor');
            end

            function cbTitleFontWeightChangedInPropertyEditor(this)
                disableListeners(this,'TitleFontWeightChangedInPropertyEditor');
                this.Title.FontWeight = this.FontsWidget.TitleFontWeight;
                enableListeners(this,'TitleFontWeightChangedInPropertyEditor');
            end

            function cbTitleFontAngleChangedInPropertyEditor(this)
                disableListeners(this,'TitleFontAngleChangedInPropertyEditor');
                this.Title.FontAngle = this.FontsWidget.TitleFontAngle;
                enableListeners(this,'TitleFontAngleChangedInPropertyEditor');
            end

            function cbXYLabelsFontSizeChangedInPropertyEditor(this)
                disableListeners(this,'XYLabelsFontSizeChangedInPropertyEditor');
                this.XLabel.FontSize = this.FontsWidget.XYLabelsFontSize;
                this.YLabel.FontSize = this.FontsWidget.XYLabelsFontSize;
                enableListeners(this,'XYLabelsFontSizeChangedInPropertyEditor');
            end

            function cbXYLabelsFontWeightChangedInPropertyEditor(this)
                disableListeners(this,'XYLabelsFontWeightChangedInPropertyEditor');
                this.XLabel.FontWeight = this.FontsWidget.XYLabelsFontWeight;
                this.YLabel.FontWeight = this.FontsWidget.XYLabelsFontWeight;
                enableListeners(this,'XYLabelsFontWeightChangedInPropertyEditor');
            end

            function cbXYLabelsFontAngleChangedInPropertyEditor(this)
                disableListeners(this,'XYLabelsFontAngleChangedInPropertyEditor');
                this.XLabel.FontAngle = this.FontsWidget.XYLabelsFontAngle;
                this.YLabel.FontAngle = this.FontsWidget.XYLabelsFontAngle;
                enableListeners(this,'XYLabelsFontAngleChangedInPropertyEditor');
            end

            function cbAxesFontSizeChangedInPropertyEditor(this)
                disableListeners(this,'AxesFontSizeChangedInPropertyEditor');
                this.AxesStyle.FontSize = this.FontsWidget.AxesFontSize;
                enableListeners(this,'AxesFontSizeChangedInPropertyEditor');
            end

            function cbAxesFontWeightChangedInPropertyEditor(this)
                disableListeners(this,'AxesFontWeightChangedInPropertyEditor');
                this.AxesStyle.FontWeight = this.FontsWidget.AxesFontWeight;
                enableListeners(this,'AxesFontWeightChangedInPropertyEditor');
            end

            function cbAxesFontAngleChangedInPropertyEditor(this)
                disableListeners(this,'AxesFontAngleChangedInPropertyEditor');
                this.AxesStyle.FontAngle = this.FontsWidget.AxesFontAngle;
                enableListeners(this,'AxesFontAngleChangedInPropertyEditor');
            end
        end

        function updateAllFontsWidget(this)
            updateTitleFontWidget(this);
            updateXYLabelsFontWidget(this);
            updateAxesLabelWidget(this);
        end

        function updateTitleFontWidget(this)
            if ~isempty(this.FontsWidget) && isvalid(this.FontsWidget)
                this.FontsWidget.TitleFontSize = this.Title.FontSize;
                this.FontsWidget.TitleFontWeight = this.Title.FontWeight;
                this.FontsWidget.TitleFontAngle = this.Title.FontAngle;
            end
        end

        function updateXYLabelsFontWidget(this)
            if ~isempty(this.FontsWidget) && isvalid(this.FontsWidget)
                this.FontsWidget.XYLabelsFontSize = this.XLabel.FontSize;
                this.FontsWidget.XYLabelsFontWeight = this.XLabel.FontWeight;
                this.FontsWidget.XYLabelsFontAngle = this.XLabel.FontAngle;
            end
        end

        function updateAxesLabelWidget(this)
            if ~isempty(this.FontsWidget) && isvalid(this.FontsWidget)
                this.FontsWidget.AxesFontSize = this.AxesStyle.FontSize;
                this.FontsWidget.AxesFontWeight = this.AxesStyle.FontWeight;
                this.FontsWidget.AxesFontAngle = this.AxesStyle.FontAngle;
            end
        end

        function buildColorWidget(this)
            % Build widget
            this.ColorWidget = controllib.widget.internal.cstprefs.ColorContainer();

            updateColorWidget(this);

            % Add listener
            registerListeners(this,...
                addlistener(this.ColorWidget,'Value','PostSet',...
                @(es,ed) cbAxesColorChangedInPropertyEditor(this,ed)),'AxesColorChangedInPropertyEditor');

            % Local callback
            function cbAxesColorChangedInPropertyEditor(this,ed)
                this.AxesStyle.RulerColor = ed.AffectedObject.(ed.Source.Name);
            end
        end

        function updateColorWidget(this)
            if ~isempty(this.ColorWidget) && isvalid(this.ColorWidget)
                this.ColorWidget.Value = this.AxesStyle.RulerColor;
            end
        end

        function openArraySelectorDialog(this)
            if isempty(this.ArraySelectorDialog) || ~isvalid(this.ArraySelectorDialog)
                % Build Array Selector dialog
                [charTags,labels] = getCharacteristicTagsToShowInArraySelector(this);
                if ~isempty(charTags)
                    % Build with characteristic bounds option
                    this.ArraySelectorDialog = controllib.chart.internal.widget.ArraySelectorDialog(...
                        Systems=this.Responses,CharacteristicLabels=labels,CharacteristicTags=charTags);
                else
                    % Build only with array indexing option
                    this.ArraySelectorDialog = controllib.chart.internal.widget.ArraySelectorDialog(...
                        System=this.Responses);
                end
            end

            % Add listener for apply/ok button
            L = addlistener(this.ArraySelectorDialog,'ArraySelectionChanged',...
                @(es,ed) cbArraySelectionChanged(this));
            registerListeners(this,L,"ArraySelectionChangedListener");

            % Show dialog
            show(this.ArraySelectorDialog);
            pack(this.ArraySelectorDialog);

            function cbArraySelectionChanged(this)
                % Local function for array selection callback
                if this.ArraySelectorDialog.IsIndexSelectionEnabled
                    % Toggle array visibility based on selected indices
                    idx = find([this.Responses.Name]==this.ArraySelectorDialog.SelectedSystem);
                    this.Responses(idx).ArrayVisible(:) = false;
                    this.Responses(idx).ArrayVisible(this.ArraySelectorDialog.ArrayIndicesToShow{:}) = true;
                else
                    % Toggle array visibility based on characteristic
                    % bounds (implemented in subclass)
                    updateArrayVisibilityUsingCharacteristicBounds(this);
                end
            end
        end

        function updateArrayVisibilityUsingCharacteristicBounds(this) %#ok<MANU>

        end

        function [tags,labels] = getCharacteristicTagsToShowInArraySelector(this) %#ok<MANU>
            tags = string.empty;
            labels = string.empty;
        end

        function validateOptionPropertyName(this,propertyName)
            mustBeMember(propertyName,fieldnames(this.createDefaultOptions()));
        end

        function createLabels(this)
            this.Title_I = controllib.chart.internal.options.AxesLabel(Chart=this);
            this.Subtitle_I = controllib.chart.internal.options.AxesLabel(Chart=this,Visible=false);
            this.XLabel_I = controllib.chart.internal.options.AxesLabel(this.getNumXLabels(),Chart=this);
            this.YLabel_I = controllib.chart.internal.options.AxesLabel(this.getNumYLabels(),Chart=this,Rotation=90);
            this.AxesStyle_I = controllib.chart.internal.options.AxesStyle(Chart=this);
            L = addlistener(this.Title,"LabelChanged",@(es,ed) cbLabelChanged(this,es,ed,"Title"));
            registerListeners(this,L,"TitleChanged");
            L = addlistener(this.XLabel,"LabelChanged",@(es,ed) cbLabelChanged(this,es,ed,"XLabel"));
            registerListeners(this,L,"XLabelChanged");
            L = addlistener(this.YLabel,"LabelChanged",@(es,ed) cbLabelChanged(this,es,ed,"YLabel"));
            registerListeners(this,L,"YLabelChanged");
            L = addlistener(this.AxesStyle,"AxesStyleChanged",@(es,ed) cbAxesStyleChanged(this,es,ed));
            registerListeners(this,L,"AxesStyleChanged");
        end

        function str = getValidLabelString(~,str,~)
        end

        function mustConvertToValidLabelString(this,str,label)
            controllib.chart.internal.utils.validators.mustBeSize(str,[this.(label).NumStrings 1]);
        end

        function cbLabelChanged(this,es,ed,labelType)
            % cbLabelChanged(this,axesLabel,eventData,labelType)
            %
            %   Callback to update View, LabelsWidget and Options when
            %   Title/XLabel/YLabel/InputLabels/OutputLabels property
            %   changes.
            arguments
                this
                es controllib.chart.internal.options.AxesLabel
                ed controllib.chart.internal.utils.GenericEventData
                labelType (1,1) string {mustBeMember(labelType,["Title","XLabel","YLabel"])}
            end

            % Update Property Editor
            if strcmp(ed.PropertyChanged,"String")
                % Update labels widget
                if ~isempty(this.LabelsWidget) && isvalid(this.LabelsWidget)
                    this.LabelsWidget.(labelType) = es.String;
                end
            end

            % Update property editor font widgets
            switch labelType
                case "Title"
                    updateTitleFontWidget(this);
                case {"XLabel","YLabel"}
                    updateXYLabelsFontWidget(this);
            end
        end

        function cbAxesStyleChanged(this,~,ed)
            switch ed.PropertyChanged
                case {"FontSize","FontWeight","FontAngle"}
                    updateAxesLabelWidget(this);
                case "GridVisible"
                    updateGridWidget(this);
                case "RulerColor"
                    updateColorWidget(this);
            end
        end

        function updateDataAxes(this)
            ax = getChartAxes(this,"visible");
            this.DataAxes_I(1) = min(this.DataAxes(1),size(ax,1));
            this.DataAxes_I(2) = min(this.DataAxes(2),size(ax,2));
        end

        function updateLegendAxesInAutoMode(this)
            ax = getChartAxes(this,"visible");
            this.LegendAxes_I = [1 size(ax,2)];
        end

        function setAxesForLegend(this)
            if all(this.LegendAxes_I)
                % If legend axes mode is auto, legend should be put in
                % top-right visible axes. Otherwise it is put based on
                % LegendAxes and all axes
                if strcmp(this.LegendAxesMode,"auto")
                    ax = getChartAxes(this,"visible");
                else
                    ax = getChartAxes(this);
                end

                if size(ax,1) >= this.LegendAxes_I(1) && size(ax,2) >= this.LegendAxes_I(2)
                    if ~isempty(this.Legend) && isvalid(this.Legend)
                        set(this.Legend,Axes=[],Parent=[]);
                        if ~any(this.LegendAxes_I == 0)
                            ax = ax(this.LegendAxes_I(1),this.LegendAxes_I(2));
                            set(this.Legend,Axes=ax,Parent=ax.Parent);
                        end
                    end
                end
            end
        end

        function updateLegendPlotChildren(this)
            if ~isempty(this.Legend) && isvalid(this.Legend)
                plotChildren = getPlotChildrenToIncludeInLegend(this);
                this.Legend.PlotChildren = plotChildren;
            end
        end

        function plotChildren = getPlotChildrenToIncludeInLegend(this)
            if ~isempty(this.PlotChildrenForLegend)
                plotChildren = this.PlotChildrenForLegend(isvalid(this.PlotChildrenForLegend));
                this.PlotChildrenForLegend = plotChildren;
                if ~isempty(plotChildren)
                    isIncludedInLegend = ...
                        arrayfun(@(c) c.LegendDisplay & ...
                        matlab.lang.OnOffSwitchState(c.HandleVisibility) & ~c.Internal,...
                        plotChildren);
                    plotChildren = plotChildren(isIncludedInLegend);
                end
            else
                plotChildren = this.PlotChildrenForLegend;
            end
        end

        function numberOfLabelsAddedToLegend = updateLegendWithCustomDataLabels(this,dataLabels)
            responseIdx = 1;
            dataLabelIdx = 1;
            numberOfMaxLabels = min(length(this.PlotChildrenForLegend),length(dataLabels));
            plotChildrenIncludedInLegend = getPlotChildrenToIncludeInLegend(this);
            this.Legend.PlotChildren = plotChildrenIncludedInLegend(1:numberOfMaxLabels);
            for k = 1:numberOfMaxLabels
                if isvalid(this.PlotChildrenForLegend(k))
                    if contains(this.PlotChildrenForLegend(k).Tag,"legendObjectForControlChartResponse")
                        % If PlotChildren is a response managed graphics object, set
                        % the appropriate Response Name to the data
                        % label
                        this.Responses(responseIdx).Name = dataLabels(dataLabelIdx);
                        responseIdx = responseIdx + 1;
                        dataLabelIdx = dataLabelIdx + 1;
                    else
                        % If PlotChildren is a
                        plotChildrenIncludedInLegend(k).DisplayName = dataLabels(dataLabelIdx);
                        dataLabelIdx = dataLabelIdx + 1;
                    end
                end
            end

            numberOfLabelsAddedToLegend = dataLabelIdx;
        end

        function visible = getCharacteristicVisibility(this,characteristicType)
            arguments
                this
                characteristicType (1,1) string
            end

            idx = find(this.CharacteristicTypes==characteristicType);
            if ~isempty(idx) && idx <= length(this.CharacteristicOptions)
                visible = this.CharacteristicOptions(idx).Visible;
            else
                visible = matlab.lang.OnOffSwitchState.empty;
            end
        end

        function cbChildAddedToAxes(this,~,ed)
            if ~ed.ChildNode.Internal && isa(ed.ChildNode,'matlab.graphics.mixin.Legendable') && ...
                    strcmp(ed.ChildNode.LegendDisplay,"on") && strcmp(ed.ChildNode.HandleVisibility,'on')

                addlistener(ed.ChildNode,'HandleVisibility',...
                    'PostSet',@(es,ed) updateLegendPlotChildren(this));
                addlistener(ed.ChildNode,'LegendDisplay',...
                    'PostSet',@(es,ed) updateLegendPlotChildren(this));

                this.PlotChildrenForLegend = [this.PlotChildrenForLegend(:);ed.ChildNode];

                updateLegendPlotChildren(this);
            end
        end

        function propertyGroups = getPropertyGroups(this)
            if ~isscalar(this)
                propertyGroups = getPropertyGroups@matlab.mixin.CustomDisplay(this);
            else
                dataGroupNames = this.getDataPropertyGroupNames();
                if isempty(this.Characteristics)
                    idx = contains(dataGroupNames,"Characteristics");
                    dataGroupNames(idx) = [];
                end
                dataPropertyGroup = matlab.mixin.util.PropertyGroup(dataGroupNames);
                if ~isempty(this.getCustomPropertyGroupNames())
                    customPropertyGroup = matlab.mixin.util.PropertyGroup(this.getCustomPropertyGroupNames());
                else
                    customPropertyGroup = matlab.mixin.util.PropertyGroup.empty;
                end
                % labelPropertyGroup = matlab.mixin.util.PropertyGroup(this.getLabelPropertyGroupNames());
                % limitPropertyGroup = matlab.mixin.util.PropertyGroup(this.getLimitPropertyGroupNames());
                stylePropertyGroup = matlab.mixin.util.PropertyGroup(this.getStylePropertyGroupNames());

                propertyGroups = [dataPropertyGroup, customPropertyGroup,stylePropertyGroup];
            end
        end

        function label = getDescriptiveLabelForDisplay(this)
            if isempty(this.Tag)
                label = this.Title.String;
            else
                label = this.Tag;
            end
            label = char(label);
        end

        function applyCharacteristicOptionsToResponse(this,response) %#ok<INUSD>

        end

        function addToCharacteristicManager(this,characteristicType,characteristicOption)
            if isempty(this.CharacteristicManager) || ~isvalid(this.CharacteristicManager)
                this.CharacteristicManager = controllib.chart.options.CharacteristicsManager;
            end
            addCharacteristicOption(this.CharacteristicManager,characteristicType,characteristicOption);
        end

        function names = getStylePropertyGroupNames(this) %#ok<MANU>
            names = "Visible";
        end

        function names = getCustomPropertyGroupNames(this)
            names = string.empty;
        end

        function updateFocusWithRequirementsExtent(this,currentXLimitsFocus,currentYLimitsFocus,requirementsExtent)
            % Update XLimitsFocus
            this.XLimitsFocus{1} = [min(currentXLimitsFocus{1}(1),requirementsExtent(1)),...
                max(currentXLimitsFocus{1}(2),requirementsExtent(2))];

            % Update YLimitsFocus
            this.YLimitsFocus{1} = [min(currentYLimitsFocus{1}(1),requirementsExtent(3)),...
                max(currentYLimitsFocus{1}(2),requirementsExtent(4))];
        end

        function focusAxes = mapDataAxesToFocusAxes(this,dataAxes)
            % mapDataAxesToFocusAxes

            % The index to update XLimitsFocus/YLimitsFocus is same as
            % index to add data for a single axes plot
            focusAxes = dataAxes;
        end
    end

    %% Static protected methods
    methods (Static,Access=protected)
        function mustBeParent(obj)
            mustBeA(obj,["matlab.ui.Figure";"matlab.ui.container.Panel";"matlab.ui.container.Tab";...
                "matlab.ui.container.GridLayout";"matlab.graphics.layout.TiledChartLayout"]);
        end

        function sz = getPropertyDialogSize()
            sz = [430 390];
        end

        function n = getNumXLabels()
            n = 1;
        end

        function n = getNumYLabels()
            n = 1;
        end

        function names = getDataPropertyGroupNames()
            names = ["Responses","Characteristics"];
        end

        function names = getLabelPropertyGroupNames()
            names = ["Title","XLabel","YLabel"];
        end

        function names = getLimitPropertyGroupNames()
            names = ["XLimits","XLimitsMode","YLimits","YLimitsMode"];
        end
    
        function mustBeValidRelease(releaseString)
            % Valid releases include R10 (version 5.2) 1998 and later.
            % Look for patterns like R10, R14SP1, R2006a, R2020a, r2020A, or R2100g
            % Disallow leading and trailing white spaces.

            % See isMATLABReleaseOlderThan
            if ~isempty(regexp(releaseString,'^[Rr][0-9]{4}[A-Za-z]([Ss][Pp]\d)?$', 'once')) ...
                    || ~isempty(regexp(releaseString,'^[Rr]1[0-4](\.\d|[Ss][Pp]\d)?$', 'once'))
                return;
            end
            error(message('MATLAB:isMATLABReleaseOlderThan:invalidReleaseInput'))
        end
    end

    %% Static hidden methods
    methods (Static,Hidden)
        function tf = isHoldSupported()
            tf = true;
        end

        function options = createDefaultOptions()
            options = plotopts.PlotOptions;
        end
    end

    methods(Access = private)
        function characteristicType = createCustomCharacteristic(this,dataCreationFcn,...
                viewCreationFcn,menuLabel,optionalArguments)
            % createCustomCharacteristic uses a data creation and view
            % creation function handle to create characteristic data and
            % view objects. These are associated with the current responses
            % (and corresponding response view).
            %
            %   If it is the first instance of creating the
            %   characteristic, the type is stored and registered so the
            %   the visibility can be set using
            %   "setCharacterisiticVisibility" method.
            arguments
                this
                dataCreationFcn
                viewCreationFcn
                menuLabel string = string.empty
                optionalArguments.Systems = this.Responses
            end

            for k = 1:length(optionalArguments.Systems)
                data = qeGetData(optionalArguments.Systems(k));
                characteristicData = dataCreationFcn(data);
                registerCharacteristic(optionalArguments.Systems(k),characteristicData);

                responseView = getResponseView(this.View,optionalArguments.Systems(k));
                characteristicView = viewCreationFcn(responseView,characteristicData);
                registerCharacteristicView(responseView,characteristicView);
            end
            parentCustomCharacteristics(this.View);

            characteristicType = characteristicData.Type;

            if ~any(contains(this.CharacteristicTypes,characteristicType))
                % Register characteristic type so that it can be turned
                % on/off for responses that are added
                this.CharacteristicTypes = [this.CharacteristicTypes;characteristicType];
                registerCharacteristicTypes(this.View,characteristicType);

                % Check for characteristics manager and context menu
                cm = getCharacteristicOption(this,characteristicType);
                if isempty(cm) && ~isempty(menuLabel)
                    cm = controllib.chart.internal.options.BaseCharacteristicOptions(...
                        MenuLabel=menuLabel,Visible=false);
                    cm.Tag = characteristicType;
                    cm.VisibilityChangedFcn = @(es,ed) setCharacteristicVisibility(this,characteristicType);
                    this.CharacteristicOptions = [this.CharacteristicOptions,cm];
                    if ~isempty(this.ContextMenu)
                        createCharacteristicsMenu(this,cm);
                    end
                end
            end
        end

        function XLimits = validateXLimits(this,XLimits)
            sz = getXLimitsSize(this);
            try
                if iscell(XLimits)
                    controllib.chart.internal.utils.validators.mustBeSize(XLimits,sz);
                else
                    XLimits = repmat({XLimits},sz);
                end
                for ii = 1:numel(XLimits)
                    controllib.chart.internal.utils.validators.mustBeLimit(XLimits{ii});
                end
            catch
                error(message('Controllib:plots:mustBeLimitArray',"numeric",sz(1),sz(2)));
            end
        end

        function XLimitsMode = validateXLimitsMode(this,XLimitsMode)
            sz = getXLimitsSize(this);
            try
                if iscell(XLimitsMode)
                    controllib.chart.internal.utils.validators.mustBeSize(XLimitsMode,sz)
                else
                    XLimitsMode = repmat({XLimitsMode},sz);
                end
                for k = 1:numel(XLimitsMode)
                    mustBeMember(XLimitsMode{k},["auto","manual"]);
                    XLimitsMode{k} = string(XLimitsMode{k});
                    validateattributes(XLimitsMode{k},{'string'},{'size',[1 1]});
                end
            catch
                error(message('Controllib:plots:mustBeLimitModeArray',sz(1),sz(2)));
            end
        end

        function YLimits = validateYLimits(this,YLimits)
            sz = getYLimitsSize(this);
            try
                if iscell(YLimits)
                    controllib.chart.internal.utils.validators.mustBeSize(YLimits,sz)
                else
                    YLimits = repmat({YLimits},sz);
                end
                for k = 1:numel(YLimits)
                    controllib.chart.internal.utils.validators.mustBeLimit(YLimits{k});
                end
            catch
                error(message('Controllib:plots:mustBeLimitArray',"numeric",sz(1),sz(2)));
            end
        end

        function YLimitsMode = validateYLimitsMode(this,YLimitsMode)
            sz = getYLimitsSize(this);
            try
                if iscell(YLimitsMode)
                    controllib.chart.internal.utils.validators.mustBeSize(YLimitsMode,sz)
                else
                    YLimitsMode = repmat({YLimitsMode},sz);
                end
                for k = 1:numel(YLimitsMode)
                    mustBeMember(YLimitsMode{k},["auto","manual"]);
                    YLimitsMode{k} = string(YLimitsMode{k});
                    validateattributes(YLimitsMode{k},{'string'},{'size',[1 1]});
                end
            catch
                error(message('Controllib:plots:mustBeLimitModeArray',sz(1),sz(2)));
            end
        end

        function localValidateUpdateSystemIdx(this,idx)
            try
                mustBeMember(idx,1:length(this.Responses));
            catch
                error(message('Controllib:plots:UpdateSystem1',length(this.Responses)))
            end
        end

        function addAxesListenersAndContextMenu(this)
            try %#ok<TRYNC>
                unregisterListeners(this,"ChildAddedToAxes");
            end
            ax = getChartAxes(this);
            L = event.listener.empty;
            for k = 1:numel(ax)
                L(k) = event.listener(ax(k),'ChildAdded', @(es,ed) cbChildAddedToAxes(this,es,ed));
            end
            registerListeners(this,L,repmat("ChildAddedToAxes",1,numel(ax)));
            if ~this.ChildAddedToAxesListenerEnabled
                disableListeners(this,'ChildAddedToAxes');
            end
            set(ax,ContextMenu=this.ContextMenu);
        end

        function cbLegendVisibilityChanged(this)
            if this.Legend.Visible
                setAxesForLegend(this);
            end
        end

        function cbLegendDeleted(this)
            this.Legend = [];
            this.LegendVisible_I = 'off';
            if ~isempty(this.LegendButton) && any(isvalid(this.LegendButton))
                legendButton = this.LegendButton(isvalid(this.LegendButton));
            for ct = 1:numel(legendButton)
               legendButton(ct).Value = false;
            end
            end
            notify(this,'LegendDeleted');
        end

        function setNextPlotOnAxes(this)
            ax = getChartAxes(this);
            for k = 1:length(ax(:))
                ax(k).NextPlot = this.NextPlot;
            end
        end

    end

    methods (Access=?controllib.chart.internal.view.axes.BaseAxesView)
        function cbViewXLimitsChanged(this,XLimits,XLimitsMode,XLimitsFocus)
            this.XLimits_I = XLimits;
            this.XLimitsMode_I = XLimitsMode;
            if this.XLimitsFocusFromResponses
                this.XLimitsFocus = XLimitsFocus;
                this.XLimitsFocusFromResponses = true;
            end
        end

        function cbViewYLimitsChanged(this,YLimits,YLimitsMode,YLimitsFocus)
            this.YLimits_I = YLimits;
            this.YLimitsMode_I = YLimitsMode;
            if this.YLimitsFocusFromResponses
                this.YLimitsFocus = YLimitsFocus;
                this.YLimitsFocusFromResponses = true;
            end
        end

        function updateXLimitsFocus(this,xLimitsFocus)
            this.XLimitsFocus_I = xLimitsFocus;
        end

        function updateYLimitsFocus(this,yLimitsFocus)
            this.YLimitsFocus_I = yLimitsFocus;
        end
    end

    methods (Access=?matlab.graphics.primitive.world.GroupBase)
        function actualContainer = getContainerForChild(this, newChild)
            actualContainer = this;
            if isa(newChild, 'matlab.graphics.mixin.AxesParentable')
                actualContainer = getCurrentAxes(this);
            end
        end
    end

    %% Hidden methods
    methods(Hidden)
        function refreshLegend(this)
            updateLegendPlotChildren(this);
        end

        function addLegendButtonToToolbar(this)
            legendIcon = fullfile(matlabroot,'toolbox','shared', filesep, 'controllib', ...
                filesep, 'graphics', filesep, '+controllib', filesep, ...
                'resources','legend_normal_16.png');
            tb = getToolbar(this);
            for k = 1:length(tb)
                % Create axestoolbar button and add to toolbar (right most
                % button)
                btn = axtoolbarbtn(tb(k),'state',Icon=legendIcon);
                tb(k).Children = [tb(k).Children(2:end); btn];
                % Set button callback
                btn.ValueChangedFcn = @(es,ed) toggleLegendButton(this);
                btn.Value = this.LegendVisible;
                this.LegendButton = [this.LegendButton,btn];
            end

            function toggleLegendButton(this)
                this.LegendVisible = ~this.LegendVisible;
            end
        end

        function removeLegendButtonFromToolbar(this)
            delete(this.LegendButton);
            this.LegendButton = [];
        end

        function currentAxes = getCurrentAxes(this)
            ax = getChartAxes(this,"visible");
            if isempty(ax)
                currentAxes = matlab.graphics.axis.Axes.empty;
            else
                r = min(this.DataAxes(1),size(ax,1));
                c = min(this.DataAxes(2),size(ax,2));
                currentAxes = ax(r,c);
            end
        end

        function response = getResponse(this,tagOrIdx)
            arguments
                this
                tagOrIdx
            end

            if isnumeric(tagOrIdx)
                % Use numerical index
                response = this.Responses(tagOrIdx);
            else
                % Use string tag
                idx = [this.Responses.Tag] == tagOrIdx;
                response = this.Responses(idx);
            end
        end

        function build(this,forceBuild)
            arguments
                this
                forceBuild (1,1) logical = false
            end
            % Abort if already built
            if ~isempty(this.View) && isvalid(this.View)
                return;
            end
            % Build only if chart is visible
            if this.Visible || forceBuild
                % Create view
                createView(this);

                createContextMenu(this);

                % Add Listener to open property editor dialog on double click
                L = addlistener(this.View,'AxesHitToOpenPropertyEditor',@(es,ed) openPropertyDialog(this));
                registerListeners(this,L,'OpenPropertyEditor');

                % Add responses to view
                if ~isempty(this.Responses)
                    % Create responseView(1) to check if subclass is using
                    % createResponseView()
                    responseViews = cell(size(this.Responses));
                    responseViews{1} = createResponseView(this,this.Responses(1));
                    if isempty(responseViews{1})
                        % If createResponseView() is not implemented, use
                        % addResponseView()
                        rvs = addResponseView(this.View,this.Responses);
                        for ii = 1:length(this.Responses)
                            responseViews{ii} = rvs(ii);
                        end
                    else
                        % createResponseView() implemented, build and
                        % register responseView(1)
                        if ~responseViews{1}.IsResponseViewValid
                            build(responseViews{1});
                        end
                        registerResponseView(this.View,responseViews{1});
                        % Create, build and register remaining
                        % responseViews

                        for k = 2:length(this.Responses)
                            responseView_k = createResponseView(this,this.Responses(k));
                            if ~responseView_k.IsResponseViewValid
                                build(responseView_k);
                            end
                            registerResponseView(this.View,responseView_k);
                            responseViews{k} = responseView_k;
                        end
                    end
                end

                for k = 1:length(this.Responses)
                    addResponseViewToPlotChildrenForLegend(this,responseViews{k});
                    if ~isempty(this.ResponsesMenu)
                        addVisibleMenu(this.Responses(k),this.ResponsesMenu);
                    end

                    if this.CreateResponseDataTipsOnDefault
                        createResponseDataTips(responseViews{k});
                    end
                end

                % Processing after adding all responses/systems
                if ~isempty(this.Responses)
                    postAddResponse(this);
                end

                updateAxesStyle(this.View);

                % Set legend
                if strcmp(this.LegendAxesMode,"auto")
                    updateLegendAxesInAutoMode(this);
                end

                % Set data axes
                ax = getChartAxes(this,"visible");
                this.DataAxes_I = size(ax);

                % Add listener to update PlotChildrenForLegend
                L = addlistener(this.View,'GridSizeChanged',@(es,ed) addAxesListenersAndContextMenu(this));
                registerListeners(this,L,'GridSizeChangedListener');
                addAxesListenersAndContextMenu(this);

                % Add listeners to update chart limits based on View
                % limits (needed for interactive zoom/pan/restore)
                connectView(this);
            end
        end

        function addCustomChildrenBeforeResponses(this,children)
            this.ChildAddedToAxesListenerEnabled = false;

            ax = getChartAxes(this);
            set(children,Parent=ax(1));

            for ii = numel(children):-1:1
                addlistener(children(ii),'HandleVisibility',...
                    'PostSet',@(es,ed) updateLegendPlotChildren(this));
                this.PlotChildrenForLegend = [children(ii);this.PlotChildrenForLegend(:)];
            end

            updateLegendPlotChildren(this);

            this.ChildAddedToAxesListenerEnabled = true;
        end

        function setCharacteristicVisibility(this,characteristicType,optionalArguments)
            arguments
                this
                characteristicType (1,:) string = this.CharacteristicTypes
                optionalArguments.Visible matlab.lang.OnOffSwitchState = matlab.lang.OnOffSwitchState.empty
                optionalArguments.Responses = this.Responses
            end

            enableOnCleanup = disableListeners(this,"ChildAddedToAxes",EnableOnCleanUp=true); %#ok<NASGU>

            for k = 1:length(characteristicType)
                if isempty(optionalArguments.Visible)
                    visible = getCharacteristicVisibility(this,characteristicType(k));
                else
                    visible = optionalArguments.Visible;
                end

                if ~isempty(this.View)
                    if isempty(visible)
                        updateCharacteristic(this.View,characteristicType(k),optionalArguments.Responses);
                    else
                        updateCharacteristic(this.View,characteristicType(k),optionalArguments.Responses,...
                            Visible=visible);
                    end
                    cm = getCharacteristicOption(this,characteristicType(k));
                    if ~isempty(cm)
                        cm.Visible = visible;
                    end
                end
            end
        end

        function view = qeGetView(this)
            view = this.View;
        end

        % Axes
        function ax = getChartAxes(this,option)
            arguments
                this
                option (1,1) string {mustBeMember(option,["all","visible"])} = "all"
            end
            ax = matlab.graphics.axis.Axes.empty;

            if ~isempty(this.View) && isvalid(this.View)
                if strcmp(option,"all")
                    ax = getAxes(this.View);
                else
                    ax = getVisibleAxes(this.View);
                end
            end
        end

        function sz = getVisibleAxesSize(~)
            sz = [1 1];
        end

        function sz = getXLimitsSize(~)
            sz = [1 1];
        end

        function sz = getYLimitsSize(~)
            sz = [1 1];
        end

        % Layout
        function hLayout = getChartLayout(this)
            hLayout = getLayout(this);
        end

        function removeToolbar(this)
            if ~isempty(this.View) && isvalid(this.View)
                removeToolbar(this.View);
            end
        end

        function tb = getToolbar(this)
            if ~isempty(this.View) && isvalid(this.View)
                tb = this.View.Toolbar;
            end
        end

        % For backward compatibility with resppack
        function ax = getaxes(this)
            ax = getChartAxes(this);
        end

        % Property Editor dialog
        function dlg = getPropertyEditorDialog(this)
            dlg = this.PropertyEditorDialog;
        end

        function openPropertyDialog(this)
            % Change pointer to busy
            fig = ancestor(this,'figure');
            currentPointer = fig.Pointer;
            fig.Pointer = 'watch';
            % Build property editor dialog and widgets if needed
            if isempty(this.PropertyEditorDialog) || ~isvalid(this.PropertyEditorDialog) || ...
                    ~isequal(this.PropertyEditorDialog.TargetTag,this.ID)
                buildPropertyDialog(this);
                this.PropertyEditorDialog.TargetTag = this.ID;
                f = getWidget(this.PropertyEditorDialog);
                f.Position(3:4) = this.getPropertyDialogSize();
            end
            % Show property editor
            show(this.PropertyEditorDialog);
            % Change pointer back
            fig.Pointer = currentPointer;
        end

        function printToParent(this,parent)
            arguments
                this (1,1) controllib.chart.internal.foundation.AbstractPlot
                parent (1,1) {controllib.chart.internal.foundation.AbstractPlot.mustBeParent(parent)}
            end
            tcl = getLayout(this);
            tcl.Copyable = true;
            try
                copyobj(tcl,parent);
            catch ME
                tcl.Copyable = false;
                rethrow(ME);
            end
            tcl.Copyable = false;
        end

        function addHG(this,hgObject,optionalInputs)
            % addHG is used to add an HG object (line, patch, stem, stairs)
            % to a specific axes in the chart.
            %
            %   addHG(hChart,hLine) adds hLine to the axes specified in the
            %   DataAxes property of hChart
            %
            %   addHG(hChart,hLine,DataAxes=dataAxes) specifies the axes to
            %   which hLine is added. This does not change the DataAxes
            %   property of the chart.
            arguments
                this
                hgObject
                optionalInputs.DataAxes = this.DataAxes
            end
            currentDataAxes = this.DataAxes_I;
            this.DataAxes_I = optionalInputs.DataAxes;
            ax = getCurrentAxes(this);
            hgObject.Parent = ax;
            this.DataAxes_I = currentDataAxes;

            focusIdx = mapDataAxesToFocusAxes(this,optionalInputs.DataAxes);
            hgWrapper = controllib.chart.internal.utils.HGLimitManager(hgObject,focusIdx);

            this.HGList = [this.HGList; hgWrapper];

            updateHGFocus(this);
        end

        function updateHGFocus(this,optionalArguments)
            % updateHGFocus updates the focus of the chart by based on all
            % HG objects added via the addHG method.
            %
            %   updateHGFocus(hChart) updates XLimitsFocus and YLimitsFocus
            %   based on XData/YData/Visiblility of HG objects without
            %   recomputing the response based focus.
            %
            %   updateHGFocus(hChart,UpdateResponseFocus=true) first
            %   updates the focus based on visible responses, and then
            %   updates it based on XData/YData/Visibility of HG objects.
            arguments
                this
                optionalArguments.UpdateResponseFocus = false
            end

            if optionalArguments.UpdateResponseFocus
                updateFocus(this.View);
            end

            xLimitsFocusChart = this.View.ResponseXLimitsFocus;
            yLimitsFocusChart = this.View.ResponseYLimitsFocus;
            for k = 1:length(this.HGList)
                if isvalid(this.HGList(k).HG) && this.HGList(k).HG.Visible
                    focusAxes = this.HGList(k).FocusAxes;

                    xLimitsFocus = xLimitsFocusChart{focusAxes(1),focusAxes(2)};
                    xLimitsFocus(1) = min(xLimitsFocus(1),this.HGList(k).XLimits(1));
                    xLimitsFocus(2) = max(xLimitsFocus(2),this.HGList(k).XLimits(2));
                    xLimitsFocusChart{focusAxes(1),focusAxes(2)} = xLimitsFocus;

                    yLimitsFocus = yLimitsFocusChart{focusAxes(1),focusAxes(2)};
                    yLimitsFocus(1) = min(yLimitsFocus(1),this.HGList(k).YLimits(1));
                    yLimitsFocus(2) = max(yLimitsFocus(2),this.HGList(k).YLimits(2));
                    yLimitsFocusChart{focusAxes(1),focusAxes(2)} = yLimitsFocus;
                end
            end

            this.XLimitsFocus = xLimitsFocusChart;
            this.YLimitsFocus = yLimitsFocusChart;
        end


        function createResponseDataTips(this)
            createResponseDataTips(this.View);
        end

        function list = getRequirementList(this) %#ok<MANU>
            list = [];
        end

        function labels = getRequirementDialogLabels(this) %#ok<MANU>
            labels = editconstr.ResourceBundle;
        end

        function constraint = getNewConstraint(this) %#ok<MANU>
            constraint = [];
        end

        function addTuningGoalPlotManager(this,manager)
            this.TuningGoalPlotManager = manager;
            this.TuningGoalPlotManager.PlotHandle_ = this;
            initializePlot(this.TuningGoalPlotManager);
        end

        function addConstraintView(this,constraint,varargin)
            if nargin > 2
                doInit = ~strcmp(varargin{1},'NoInitialization');
            else
                doInit = true;
            end

            if doInit
                % REVISIT: should call grapheditor::addconstr to perform generic init

                % Generic init (includes generic interface editor/constraint)
                % initconstr(this,Constr)
                initializeConstraint(this,constraint);

                % Add related listeners
                % L = handle.listener(Axes,Axes.findprop('XUnits'), 'PropertyPostSet', {@LocalSetUnits,Constr});
                % Constr.addlisteners(L);

                % Activate (initializes graphics and targets constr. editor)
                constraint.Activated = 1;

                % Update limits
                % Axes.send('ViewChanged')
            end

            %Add to list of requirements on the plot
            this.Requirements = vertcat(this.Requirements,constraint);

            % Add listener to cleanup
            L = event.listener(constraint,'ObjectBeingDestroyed',@(es,ed) localDeleteConstraint(this,constraint));
            registerListeners(this,L,"ConstraintBeingDestroyed")

            function localDeleteConstraint(this,constraint)
                idx = strcmp(this.Requirements.getUID,constraint.getUID);
                this.Requirements(idx) = [];
                if isvalid(this)
                    updateFocusWithRequirements(this,IsResponseUpdated=false);
                end
            end
            
            % Update focus
            updateFocusWithRequirements(this,IsResponseUpdated=false);
            update(constraint);

            % Modify color
            constraint.PatchColor = controllib.plot.internal.utils.GraphicsColor(8,"tertiary").SemanticName;
            render(constraint);
        end

        function initializeConstraint(this,constraint)
            constraint.Zlevel = -1;
            initialize(constraint);

            % Add listener to update limits.
            %   Note that we need to store listener separately since it is
            %   a handle.listener, and hence not compatible with MixInListeners
            L = event.listener(constraint,'DataChanged',@(es,ed) localUpdateLims(constraint));
            registerListeners(this,L,"ConstraintDataChanged");

            L = handle.listener(constraint.EventManager,'MouseEdit',@(es,ed) localReframe(this,constraint));
            this.RequirementMouseEventListeners = [this.RequirementMouseEventListeners,L];

            function localUpdateLims(constraint)
                updateFocusWithRequirements(this,IsResponseUpdated=false);
                update(constraint);
            end

            function localReframe(this,~)
                updateFocusWithRequirements(this,IsResponseUpdated=false);
            end
        end

        function data = saveConstraints(this)
            % saveConstraint  Saves design constraint.

            Constraints = this.Requirements;
            nc = length(Constraints);
            data = struct('Type',cell(nc,1),'Data',[]);

            for ct=1:nc
                data(ct).Type = Constraints(ct).describe('identifier');
                data(ct).Data = Constraints(ct).save;
            end
        end

        function loadConstraints(this,savedData)
            % loadConstraints  Reloads saved constraint data.

            % Clear existing constraints
            delete(this.Requirements);

            % Create and initialize new constraints
            for ct=1:length(savedData)
                % Use getNewConstraint to recreate the constraint, this creates a
                % constraint editor
                cEditor = getNewConstraint(this,savedData(ct).Type);

                % From the constraint editor construct a view
                ax = getaxes(this);
                hC = cEditor.Requirement.getView(ax(1));
                hC.load(savedData(ct).Data);

                % Add to constraint list (includes rendering)
                addConstraintView(this,hC);

                % Unselect
                hC.Selected = 'off';
            end
        end

        function updateFocusWithRequirements(this,optionalArguments)
            arguments
                this
                optionalArguments.IsResponseUpdated = true
                optionalArguments.ForceRequirementFocus = false
            end

            if optionalArguments.IsResponseUpdated
                updateFocus(this.View);
            end

            if ~isempty(this.Requirements)
                % Combine focus with extent from requiremens
                requirementsExtent = getRequirementsExtent(this);
                % Only update focus if extent from requirements has changed
                if ~isequal(this.RequirementsExtent,requirementsExtent) || optionalArguments.ForceRequirementFocus
                    % Get current xlimits focus
                    if ~isempty(this.View.ResponseXLimitsFocus)
                        currentXLimitsFocus = this.View.ResponseXLimitsFocus;
                    else
                        currentXLimitsFocus = this.XLimitsFocus;
                    end

                    % Get current ylimits focus
                    if ~isempty(this.View.ResponseYLimitsFocus)
                        currentYLimitsFocus = this.View.ResponseYLimitsFocus;
                    else
                        currentYLimitsFocus = this.YLimitsFocus;
                    end

                    % Update focus and store latest requirements extent
                    updateFocusWithRequirementsExtent(this,currentXLimitsFocus,currentYLimitsFocus,requirementsExtent);
                    this.RequirementsExtent = requirementsExtent;
                end
            elseif ~optionalArguments.IsResponseUpdated
                % All requirements are deleted. Set focus back to what was
                % computed from responses.
                this.RequirementsExtent = [];
                if ~isempty(this.View.ResponseXLimitsFocus)
                    this.XLimitsFocus = this.View.ResponseXLimitsFocus;
                end
                if ~isempty(this.View.ResponseYLimitsFocus)
                    this.YLimitsFocus = this.View.ResponseYLimitsFocus;
                end
            end
        end

        function allReqExtent = getRequirementsExtent(this)
            allReqExtent = [Inf,-Inf,Inf,-Inf];
            for k = 1:length(this.Requirements)
                reqExtent = extent(this.Requirements(k));
                allReqExtent(1) = min(allReqExtent(1),reqExtent(1));
                allReqExtent(2) = max(allReqExtent(2),reqExtent(2));
                allReqExtent(3) = min(allReqExtent(3),reqExtent(3));
                allReqExtent(4) = max(allReqExtent(4),reqExtent(4));
            end
        end

        function showCharacteristic(this,characteristicType)
            this.setCharacteristicVisibility(characteristicType,Visible=true)
        end

        function menuTags = getMenuTags(this)
            menuTags = {this.ContextMenu.Children.Tag};
        end

        function addMenu(this,menu,nameValueArgs)
            % addMenu(this,uimenuObject)
            %       Add uimenuObject as last item in context menu of chart (this).
            %
            % addMenu(this,uimenuObject,Above='grid')
            %       Add uimenuObject above the uimenu with tag 'grid' in the context menu of chart.
            %
            % addMenu(this,uimenuObject,Below='grid')
            %       Add uimenuObject below the uimenu with tag 'grid' in the context menu of chart.
            %
            % addMenu(this,uimenuObject,Above='grid',CreateNewSection=true)
            %       Add uimenuObject in the relevant position in the
            %       context menu of chart and add a separator to create a
            %       new section.
            %
            %       Note that when both Above and Below name-value pairs
            %       are specified, then the Above option is chosen.

            arguments
                this
                menu matlab.ui.container.Menu
                nameValueArgs.Above string = string.empty
                nameValueArgs.Below string = string.empty
                nameValueArgs.CreateNewSection logical = logical.empty
            end

            menu.Parent = this.ContextMenu;

            % Reorder if needed
            menuTags = getMenuTags(this);
            idxAbove = find(contains(menuTags,nameValueArgs.Above), 1);
            idxBelow = find(contains(menuTags,nameValueArgs.Below), 1);

            if ~isempty(nameValueArgs.Above) && ~isempty(idxAbove)
                % First check "Above" and place new menu item before the
                % specified menu item already in context menu
                if ~isempty(nameValueArgs.CreateNewSection)
                    if nameValueArgs.CreateNewSection
                        this.ContextMenu.Children(idxAbove).Separator = 'on';
                    else
                        this.ContextMenu.Children(idxAbove).Separator = 'off';
                    end
                end
                this.ContextMenu.Children = [this.ContextMenu.Children(2:idxAbove); menu; ...
                    this.ContextMenu.Children(idxAbove+1:end)];
            elseif ~isempty(nameValueArgs.Below) && ~isempty(idxBelow)
                % Then check "After" and if valid, place new menu item
                % after the specified menu item already in context menu
                if ~isempty(nameValueArgs.CreateNewSection)
                    if nameValueArgs.CreateNewSection
                        this.ContextMenu.Children(idxBelow-1).Separator = 'on';
                    else
                        this.ContextMenu.Children(idxBelow-1).Separator = 'off';
                    end
                end
                this.ContextMenu.Children = [this.ContextMenu.Children(2:idxBelow-1); menu; ...
                    this.ContextMenu.Children(idxBelow:end)];
            end
        end

        function removeMenu(this,menuTag)
            menuToRemove = findMenu(this,menuTag);
            menuToRemove.Parent = [];
            this.UnparentedMenus = [this.UnparentedMenus,menuToRemove];
        end

        function menu = findMenu(this,menuTag)
            idx = find(strcmp({this.ContextMenu.Children.Tag},menuTag));
            menu = this.ContextMenu.Children(idx);
        end

        function restoreMenu(this,menuTag,optionalArguments)
            arguments
                this
                menuTag
                optionalArguments.Above string = string.empty
                optionalArguments.Below string = string.empty
                optionalArguments.CreateNewSection logical = logical.empty
            end

            optionalArguments = namedargs2cell(optionalArguments);
            idx = find(strcmp({this.UnparentedMenus.Tag},menuTag));
            addMenu(this,this.UnparentedMenus(idx),optionalArguments{:});
            this.UnparentedMenus(idx) = [];
        end

        function setRefreshMode(this,refreshMode)
            % setRefreshMode(hChart,refreshMode)
            %
            %   Input Arguments:
            %       refreshMode     "quick"|"normal"
            %
            %   Note that setting refresh mode to normal resets the
            %   XLimitsMode and YLimitsMode to 'auto'.
            arguments
                this
                refreshMode (1,1) string {mustBeMember(refreshMode,["quick","normal"])} = this.RefreshMode
            end

            if strcmp(refreshMode,"quick")
                modeToSet = "manual";
            else
                modeToSet = "auto";
            end

            this.XLimitsMode = modeToSet;
            this.YLimitsMode = modeToSet;
        end

        function refreshMode = getRefreshMode(this)
            refreshMode = this.RefreshMode;
        end

        function qeUpdate(this)
            update(this);
        end

        function dlg = qeOpenPropertyEditorDialog(this)
            openPropertyDialog(this);
            dlg = this.PropertyEditorDialog;
        end

        function dlg = qeOpenArraySelectorDialog(this)
            openArraySelectorDialog(this);
            dlg = this.ArraySelectorDialog;
        end

        function widgets = qeGetPropertyEditorWidgets(this)
            widgets.LabelWidget = this.LabelsWidget;
            widgets.XLimitsWidget = this.XLimitsWidget;
            widgets.YLimitsWidget = this.YLimitsWidget;
            widgets.UnitsWidget = this.UnitsWidget;
            widgets.GridWidget = this.GridWidget;
            widgets.FontsWidget = this.FontsWidget;
            widgets.ColorWidget = this.ColorWidget;
        end

        function cm = qeGetContextMenu(this)
            cm = this.ContextMenu;
        end

        function qeOpenContextMenuCallback(this)
            cbContextMenuOpening(this);
        end

        function characteristicTypes = qeGetCharacteristicTypes(this)
            characteristicTypes = this.CharacteristicTypes;
        end

        function characteristicOptions = qeGetCharacteristicOptions(this,charType)
            arguments
                this (1,1) controllib.chart.internal.foundation.AbstractPlot
                charType (:,1) = this.CharacteristicTypes
            end

            characteristicOptions = controllib.chart.options.CharacteristicOption.empty;
            for k = 1:length(charType)
                characteristicOptions(k) = getCharacteristicOption(this,charType(k));
            end
        end

        function characteristicManager = qeGetCharacteristicManager(this)
            characteristicManager = this.CharacteristicManager;
        end

        function qeSetAllCharacteristicsVisibility(this,visible)
            % qeSetAllCharacteristicVisibility shows or hides all
            % characteristic markers for the chart
            %
            % qeSetAllCharacteristicsVisibility(this,true)
            % qeSetAllCharacteristicsVisibility(this,false)
            characteristicTypes = fieldnames(this.Characteristics);
            for c = characteristicTypes'
                this.Characteristics.(c{1}).Visible = visible;
            end
        end

        function qeAddSystem(this,newSystem)
            addResponseToChart(this,newSystem,[],"","",[]);
        end

        function legendButton = qeGetLegendButton(this)
            legendButton = this.LegendButton;
        end

        function resetFocus(this)
            updateFocus(this.View);
        end

        function registerResponse(this,newResponse,newResponseView)
            arguments
                this (1,1) controllib.chart.internal.foundation.AbstractPlot
                newResponse (1,1) controllib.chart.internal.foundation.BaseResponse
                newResponseView controllib.chart.internal.view.wave.BaseResponseView = ...
                    controllib.chart.internal.view.wave.BaseResponseView.empty
            end

            if strcmp(newResponse.Style.ColorMode,"auto") || strcmp(newResponse.Style.LineStyleMode,"auto") ...
                    || strcmp(newResponse.Style.MarkerStyleMode,"auto")
                [style,styleIndex] = dealNextSystemStyle(this);

                % Copy appropriate values from current response style
                copyPropertiesNotSetByStyleManager(style,newResponse.Style);
                copyPropertiesIfManualMode(style,newResponse.Style);

                % Set new style
                newResponse.Style = style;
            else
                styleIndex = 0;
            end
            applyCharacteristicOptionsToResponse(this,newResponse);
            this.ResponseStyleIndex = [this.ResponseStyleIndex(:); styleIndex];
            addResponseToChart(this,newResponse,[],"","",[],ResponseView=newResponseView);
        end

        function registerCustomCharacteristic(this,dataFcn,viewFcn,optionalArguments)
            arguments
                this
                dataFcn
                viewFcn
                optionalArguments.AddToMenuWithLabel string = string.empty
            end

            this.CustomCharacteristicInfo(end+1).DataFcn = dataFcn;
            this.CustomCharacteristicInfo(end).ViewFcn = viewFcn;
            this.CustomCharacteristicInfo(end).MenuLabel = optionalArguments.AddToMenuWithLabel;

            if ~isempty(this.Responses)
                createCustomCharacteristic(this,dataFcn,viewFcn);
            end
        end

        function addSystem(this,varargin)
            addResponse(this,varargin{:});
        end

        function removeSystem(this,sysOrIdx)
            arguments
                this
                sysOrIdx = this.Responses(end)
            end
            if isnumeric(sysOrIdx)
                sysToRemove = this.Responses(sysOrIdx);
            else
                sysToRemove = sysOrIdx;
            end
            delete(sysToRemove);
        end

        function plotChildren = qeGetPlotChildrenForLegend(this)
            plotChildren = this.PlotChildrenForLegend;
        end

        function hLegend = qeGetLegend(this)
            hLegend = this.Legend;
        end

        function currentObjectCandidateType = setCurrentObjectCandidateType(this,type)
            arguments
                this
                type
            end
            currentObjectCandidateType = this.CurrentObjectCandidateType;
            this.CurrentObjectCandidateType = type;
        end

        function resetPlotChildrenForLegend(this)
            this.PlotChildrenForLegend = [];
            for k = 1:length(this.Responses)
                responseView = getResponseView(this.View,this.Responses(k));
                addResponseViewToPlotChildrenForLegend(this,responseView);
            end
            updateLegendPlotChildren(this);
        end
    end
end

%% Local functions
function validateLegendLocation(legendLocation)
mustBeMember(lower(legendLocation),...
    ["northeast","southeast","southwest","northwest","north","east","south","west","best",...
    "northeastoutside","southeastoutside","southwestoutside","northwestoutside",...
    "northoutside","eastoutside","southoutside","westoutside","bestoutside"]);
end

function validateGridValue(gridValue)
if isstring(gridValue) || ischar(gridValue)
    gridValue = string(gridValue);
    try
        mustBeMember(gridValue,["on","off","minor"]);
    catch ME
        if gridValue ~= "CSTdefaultGridBehavior"
            throw(ME)
        end
    end
elseif ~isa(gridValue,'matlab.lang.OnOffSwitchState') && ~islogical(gridValue)
    msg = getString(message('MATLAB:grid:UnknownOption'));
    error('MATLAB:grid:UnknownOption',msg);
end
mustBeNonempty(gridValue)
mustBeScalarOrEmpty(gridValue)
end

function validateBoxValue(boxValue)
try
    try %#ok<TRYNC>
        boxValue = matlab.lang.OnOffSwitchState(boxValue);
    end
    mustBeA(boxValue,'matlab.lang.OnOffSwitchState')
catch ME
    if boxValue ~= "CSTdefaultBoxBehavior"
        throw(ME)
    end
end
mustBeNonempty(boxValue)
mustBeScalarOrEmpty(boxValue)
end

function copyPropertiesNotSetByStyleManager(style,currentStyle)
% Set properties not managed by StyleManager
style.FaceAlpha = currentStyle.FaceAlpha;
style.EdgeAlpha = currentStyle.EdgeAlpha;
style.LineWidth = currentStyle.LineWidth;
style.MarkerSize = currentStyle.MarkerSize;
style.CharacteristicsMarkerStyle = currentStyle.CharacteristicsMarkerStyle;
style.CharacteristicsMarkerSize = currentStyle.CharacteristicsMarkerSize;
end

function copyPropertiesIfManualMode(style,currentStyle)
% Copy Color/SemanticColor if needed
if strcmp(currentStyle.ColorMode,"semantic")
    style.SemanticColor = currentStyle.SemanticColor;
elseif strcmp(currentStyle.ColorMode,"manual")
    style.Color = currentStyle.Color;
end

% Copy FaceColor and EdgeColor if needed
if currentStyle.FaceColorMode == "semantic"
    style.SemanticFaceColor = currentStyle.SemanticFaceColor;
end
if currentStyle.EdgeColorMode == "semantic"
    style.SemanticEdgeColor = currentStyle.SemanticEdgeColor;
end

% Copy LineStyle if needed
if strcmp(currentStyle.LineStyleMode,"manual")
    style.LineStyle = currentStyle.LineStyle;
end

% Copy MarkerStyle if needed
if strcmp(currentStyle.MarkerStyleMode,"manual")
    style.MarkerStyle = currentStyle.MarkerStyle;
end
end
% LocalWords:  XLabel plotopts lang XLimits xmin xmax YLimits ymin ymax Characterisitic linestyle
% LocalWords:  markerstyle linewidth arrayselector fullview iogrouping ioselector ylimits Lim
% LocalWords:  NOutputs xlimits cb Legendable Parentable boxoff boxon Changedin datatips resppack
% LocalWords:  XUnits Lims
