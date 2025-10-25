classdef MixInTimeComplexPlot < matlab.mixin.SetGet

    properties (Dependent)
        RealVisible                matlab.lang.OnOffSwitchState
        ImaginaryVisible           matlab.lang.OnOffSwitchState
    end

    properties (AbortSet)
        ComplexViewType (1,1) string {mustBeMember(ComplexViewType,...
            ["realimaginary","magnitudephase","complexplane"])} = "realimaginary"
    end

    properties (Access = protected, Transient, NonCopyable)
        TimeView
        PolarView
        MagnitudePhaseView

        ComplexViewMenu
        ShowRealImaginarySubMenu
        ShowTimeMagnitudePhaseSubMenu
        ShowComplexPlaneSubMenu
    end

    properties (Access = protected)
        ActiveViewType = "time"
        TimeViewProperties
        PolarViewProperties
        MagnitudePhaseViewProperties
        ViewLabelPropertiesToStore = ["XLabel","YLabel","Title","Subtitle"];
        ViewLimitPropertiesToStore = ["XLimits","XLimitsMode","XLimitsSharing",...
            "YLimits","YLimitsMode","YLimitsSharing"];
    end

    properties (Access = private, Dependent)
        ActiveView
    end

    properties (Access = private)
        RealVisible_I = matlab.lang.OnOffSwitchState(true)
        ImaginaryVisible_I = matlab.lang.OnOffSwitchState(true)
        MagnitudeVisible_I = matlab.lang.OnOffSwitchState(false)
        ComplexPlaneVisible_I  = matlab.lang.OnOffSwitchState(false)
        % ComplexViewType_I (1,1) string {mustBeMember(ComplexViewType_I,...
        %                                     ["realimaginary","magnitudephase","complexplane"])}
    end

    %% Constructor
    methods (Access = protected)
        function this = MixInTimeComplexPlot(complexViewType)
            this.ComplexViewType = complexViewType;
            mustBeA(this,'controllib.chart.internal.foundation.AbstractPlot');
        end
    end

    %% get/set for dependent
    methods
        % ShowReal
        function ShowReal = get.RealVisible(this)
            ShowReal = matlab.lang.OnOffSwitchState(this.RealVisible_I);
        end

        function set.RealVisible(this,ShowReal)
            arguments
                this (1,1) controllib.chart.internal.foundation.MixInTimeComplexPlot
                ShowReal (1,1) matlab.lang.OnOffSwitchState
            end
            this.RealVisible_I = ShowReal;
            if ~isempty(this.TimeView) && isvalid(this.TimeView)
                this.TimeView.ShowReal = ShowReal;
            end
        end

        % ShowImaginary
        function ShowImaginary = get.ImaginaryVisible(this)
            ShowImaginary = matlab.lang.OnOffSwitchState(this.ImaginaryVisible_I);
        end

        function set.ImaginaryVisible(this,ShowImaginary)
            arguments
                this (1,1) controllib.chart.internal.foundation.MixInTimeComplexPlot
                ShowImaginary (1,1) matlab.lang.OnOffSwitchState
            end
            this.ImaginaryVisible_I = ShowImaginary;
            if ~isempty(this.TimeView) && isvalid(this.TimeView)
                this.TimeView.ShowImaginary = ShowImaginary;
            end
        end

        % ComplexViewType
        function set.ComplexViewType(this,ComplexViewType)
            if ~isempty(this.ActiveView) && isvalid(this.ActiveView)
                switchView(this,ComplexViewType);
            end
            this.ComplexViewType = ComplexViewType;
        end

        % ActiveView
        function ActiveView = get.ActiveView(this)
            ActiveView = getActiveView(this);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function createComplexViewContextMenu(this)
            this.ComplexViewMenu = uimenu(Parent=[],...
                Text="Complex View",...
                Tag="complex",...
                Separator="on");
            this.ShowRealImaginarySubMenu = uimenu(Parent=this.ComplexViewMenu,...
                Text=getString(message('Controllib:plots:lblRealImaginary')),...
                Tag="showRealImaginary",...
                MenuSelectedFcn=@(es,ed) cbShowTimeRealImaginaryMenuSelected(this,es));
            this.ShowTimeMagnitudePhaseSubMenu = uimenu(Parent=this.ComplexViewMenu,...
                Text=getString(message('Controllib:plots:lblMagnitudePhase')),...
                Tag="showMagnitudePhase",...
                MenuSelectedFcn=@(es,ed) cbShowTimeMagnitudePhaseMenuSelected(this,es));
            this.ShowComplexPlaneSubMenu = uimenu(Parent=this.ComplexViewMenu,...
                Text=getString(message('Controllib:plots:lblComplexPlane')),...
                Tag="showComplexPlane",...
                MenuSelectedFcn=@(es,ed) cbShowComplexPlaneMenuSelected(this,es));
            addMenu(this,this.ComplexViewMenu,Above="grid",CreateNewSection=true);
        end

        function setComplexViewContextMenuOnOpen(this)
            isAnyResponseComplex = false;
            for k = 1:length(this.Responses)
                isAnyResponseComplex = isAnyResponseComplex || any(~this.Responses(k).IsReal);
            end
            if isAnyResponseComplex
                this.ComplexViewMenu.Visible = 'on';
            else
                this.ComplexViewMenu.Visible = 'off';
            end

            this.ShowComplexPlaneSubMenu.Checked = 'off';
            this.ShowRealImaginarySubMenu.Checked = 'off';
            this.ShowTimeMagnitudePhaseSubMenu.Checked = 'off';

            if strcmp(this.ComplexViewType,"realimaginary")
                this.ShowRealImaginarySubMenu.Checked = 'on';
            elseif strcmp(this.ComplexViewType,"magnitudephase")
                this.ShowTimeMagnitudePhaseSubMenu.Checked = 'on';
            elseif strcmp(this.ComplexViewType,"complexplane")
                this.ShowComplexPlaneSubMenu.Checked = 'on';
            end
        end

        function names = getPropertyNamesForComplexView(this)
            names = string.empty;

            % Return property names if any of the responses is complex
            isReal = get([this.Responses],'IsReal');
            if iscell(isReal)
                isReal = cell2mat(isReal);
            end
            allIsReal = all(isReal);
            if ~allIsReal
                names = ["ComplexViewType","RealVisible","ImaginaryVisible"];
            end
        end
    end

    %% Abstract methods
    methods (Abstract, Access=protected)
        timeView = createTimeView(this,viewToInitialize)
        polarView = createPolarView(this,viewToInitialize)
        magnitudePhaseView = createMagnitudePhaseView(this,viewForInitialization)
        view = getActiveView(this)
        setActiveView(this,view)
    end

    %% Static methods
    methods (Static, Access=protected)
        function storedProperties = getPropertiesToStoreOnViewSwitch(chart)
            storedProperties.XLabel = chart.XLabel.String;
            storedProperties.YLabel = chart.YLabel.String;
            storedProperties.Title = chart.Title.String;
            storedProperties.Subtitle = chart.Subtitle.String;
            storedProperties.XLimits = chart.XLimits;
            storedProperties.XLimitsMode = chart.XLimitsMode;
            storedProperties.XLimitsSharing = chart.XLimitsSharing;
            storedProperties.YLimits = chart.YLimits;
            storedProperties.YLimitsMode = chart.YLimitsMode;
            storedProperties.YLimitsSharing = chart.YLimitsSharing;
        end

        function applyStoredPropertiesAfterViewSwitch(this,storedProperties)
            this.XLabel.String = storedProperties.XLabel;
            this.YLabel.String = storedProperties.YLabel;
            this.Title.String = storedProperties.Title;
            this.Subtitle.String = storedProperties.Subtitle;
            this.XLimitsSharing = storedProperties.XLimitsSharing;
            this.XLimits = storedProperties.XLimits;
            this.XLimitsMode = storedProperties.XLimitsMode;
            this.YLimitsSharing = storedProperties.YLimitsSharing;
            this.YLimits = storedProperties.YLimits;
            this.YLimitsMode = storedProperties.YLimitsMode;
        end
    end

    %% Private methods
    methods (Access = private)
        function cbShowTimeRealImaginaryMenuSelected(this,es)
            this.ComplexViewType = "realimaginary";
            this.RealVisible = 'on';
            this.ImaginaryVisible = 'on';

            this.ShowTimeMagnitudePhaseSubMenu.Checked = 'off';
            this.ShowComplexPlaneSubMenu.Checked = 'off';
        end

        function cbShowTimeMagnitudePhaseMenuSelected(this,es)

            this.RealVisible_I = 'off';
            this.ImaginaryVisible_I = 'off';

            this.ComplexViewType = "magnitudephase";

            this.ShowRealImaginarySubMenu.Checked = 'off';
            this.ShowComplexPlaneSubMenu.Checked = 'off';
        end

        function cbShowComplexPlaneMenuSelected(this,es)
            this.ComplexViewType = "complexplane";
            this.ShowRealImaginarySubMenu.Checked = 'off';
            this.ShowComplexPlaneSubMenu.Checked = 'off';
        end

        function switchView(this,newViewType)
            arguments
                this        controllib.chart.internal.foundation.AbstractPlot
                newViewType (1,1) string
            end

            if ~strcmp(newViewType,this.ComplexViewType)
                % Only do something if newViewType and ComplexViewType is
                % different
                this.ActiveView.Visible = 'off';
                unregisterListeners(this.ActiveView);
                activeViewProperties = this.getPropertiesToStoreOnViewSwitch(this);
                unparentResponseViews(this.ActiveView);

                switch this.ComplexViewType
                    case "realimaginary"
                        this.TimeViewProperties = activeViewProperties;
                        this.TimeView = this.ActiveView;
                    case "complexplane"
                        this.PolarViewProperties = activeViewProperties;
                        this.PolarView = this.ActiveView;
                    case "magnitudephase"
                        this.MagnitudePhaseViewProperties = activeViewProperties;
                        this.MagnitudePhaseView = this.ActiveView;
                        % Remove all right rulers
                        ax = getAxes(this.ActiveView);
                        cla(ax,'reset');
                        % Force style update
                        axesGrid = qeGetAxesGrid(this.ActiveView);
                        update(axesGrid,UpdateLabels=true);
                end

                createNewResponseViews = false;
                if strcmp(newViewType,"realimaginary")
                    % Set axes aspect ratio to normal
                    ax = getChartAxes(this);
                    axis(ax,'normal');
                    % Create new time view if not already created
                    if isempty(this.TimeView) || ~isvalid(this.TimeView)
                        % Create new AxesView object for polar view
                        % Set defaults on chart
                        this.XLimitsSharing = "all";
                        this.XLimitsMode = "auto";
                        if isa(this,'controllib.chart.internal.foundation.SingleColumnPlot')
                            this.YLimitsSharing = "all";
                        else
                            this.YLimitsSharing = "row";
                        end
                        this.YLimitsMode = "auto";
                        this.XLabel.String = "Time";
                        this.YLabel.String = "Amplitude";
                        % Create polar view
                        this.TimeView = createTimeView(this,this.ActiveView);
                        createNewResponseViews = true;
                    else
                        % Apply stored Polar View properties to chart
                        this.applyStoredPropertiesAfterViewSwitch(this,this.TimeViewProperties);
                        setAxesGrid(this.TimeView,qeGetAxesGrid(this.ActiveView));
                        build(this.TimeView);
                    end
                    setActiveView(this,this.TimeView);
                elseif strcmp(newViewType,"complexplane")
                    % Create new polar view if not already created
                    if isempty(this.PolarView) || ~isvalid(this.PolarView)
                        % Create new AxesView object for polar view
                        % Set defaults on chart
                        if isa(this,'controllib.chart.internal.foundation.SingleColumnPlot')
                            this.XLimitsSharing = "all";
                        else
                            this.XLimitsSharing = "column";
                        end
                        this.XLimitsMode = "auto";
                        if isa(this,'controllib.chart.internal.foundation.SingleColumnPlot')
                            this.YLimitsSharing = "all";
                        else
                            this.YLimitsSharing = "row";
                        end
                        this.YLimitsMode = "auto";
                        this.XLabel.String = getString(message('Controllib:plots:strReal'));
                        this.YLabel.String = getString(message('Controllib:plots:strImaginary'));
                        % Create polar view
                        this.PolarView = createPolarView(this,this.ActiveView);
                        createNewResponseViews = true;
                    else
                        % Apply stored Polar View properties to chart
                        this.applyStoredPropertiesAfterViewSwitch(this,this.PolarViewProperties);
                        setAxesGrid(this.PolarView,qeGetAxesGrid(this.ActiveView));
                        build(this.PolarView);
                    end
                    setActiveView(this,this.PolarView);
                elseif strcmp(newViewType,"magnitudephase")
                    % Set axes aspect ratio to normal
                    ax = getChartAxes(this);
                    axis(ax,'normal');
                    % Create new magphase view if not already created
                    if isempty(this.MagnitudePhaseView) || ~isvalid(this.MagnitudePhaseView)
                        this.XLimitsSharing = "all";
                        this.XLimitsMode = "auto";
                        if isa(this,'controllib.chart.internal.foundation.SingleColumnPlot')
                            this.YLimitsSharing = "all";
                        else
                            this.YLimitsSharing = "row";
                        end
                        this.YLimitsMode = "auto";
                        this.XLabel.String = getString(message('Controllib:plots:strTime'));
                        this.YLabel.String = getString(message('Controllib:plots:strMagnitude'));
                        % Creat magnitude-phase view
                        this.MagnitudePhaseView = createMagnitudePhaseView(this,this.ActiveView);
                        createNewResponseViews = true;
                    else
                        this.applyStoredPropertiesAfterViewSwitch(this,this.MagnitudePhaseViewProperties);
                        setAxesGrid(this.MagnitudePhaseView,qeGetAxesGrid(this.ActiveView));
                        build(this.MagnitudePhaseView);
                    end
                    setActiveView(this,this.MagnitudePhaseView);
                end

                % Build the new view object
                this.ActiveView.Visible = 'on';

                if ~createNewResponseViews
                    % Parent existing response views to the axes
                    parentResponseViews(this.ActiveView);
                end

                for k = 1:length(this.Responses)
                    % Create new response views if the axes view is new, or
                    % if the response does not have a corresponding
                    % response view
                    if createNewResponseViews || ...
                            isempty(getResponseView(this.ActiveView,this.Responses(k)))
                        addResponseView(this.ActiveView,this.Responses(k));
                        rv = getResponseView(this.ActiveView,this.Responses(k));
                    end

                    if ~this.Responses(k).Visible
                        updateResponseVisibility(this.ActiveView,this.Responses(k));
                    end
                end

                % Maintain characteristic visibility and update focus
                this.ActiveView.TimeUnit = this.TimeUnit;
                setCharacteristicVisibility(this);
                updateFocus(this.ActiveView);
                resetPlotChildrenForLegend(this);
            end
        end
    end

    %% Hidden methods
    methods (Hidden)
        function timeView = qeGetTimeView(this)
            timeView = this.TimeView;
        end

        function magnitudePhaseView = qeGetMagnitudePhaseView(this)
            magnitudePhaseView = this.MagnitudePhaseView;
        end

        function polarView = qeGetPolarView(this)
            polarView = this.PolarView;
        end
    end
end