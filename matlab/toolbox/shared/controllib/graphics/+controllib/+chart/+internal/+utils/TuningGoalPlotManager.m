classdef TuningGoalPlotManager < controllib.chart.internal.foundation.MixInListeners & matlab.mixin.Copyable
    %GenericTuningGoalPlot Class for tuning goal plots.

    %   Copyright 1986-2016 The MathWorks, Inc.

    %% Public Properties
    properties
        % The tuning goal that is being plotted
        TuningGoal
        % Active goal (for varying goals)
        GoalIndex = 1;
    end

    properties (SetAccess = private)
        % Add designs that need to be compared. Any design added to
        % this property will be plotted. Any design removed from this
        % property will be deleted from the plot.
        ComparedDesigns = cell(0,1);
    end

    %% Dependent Properties
    properties (Dependent)
        % TuningGoal at GoalIndex
        ActiveGoal
        % System to evaluate the tuning goal on
        System
        % Sampling time
        Ts
        % Time units
        TU
    end

    %% Private Properties
    properties (Access = protected)
        % System to evaluate the tuning goal on
        System_

        % Sampling grid (for varyingGoal only)
        SamplingGrid_

        % Keep track of what styles have already been used by designs.
        DesignStyles_ = cell(0,2);

        % Zoom mode for auto 'Goal' or 'Full'
        AutoZoomMode = 'Goal';

        % Limit focuses for 'Full'
        XLimitsFocus_
        YLimitsFocus_
    end

    properties (Access=protected,Transient,NonCopyable)
        % Listeners for plot handle
        PlotDeleteListener
        PlotContextMenuOpeningListener
        LocalGoalListeners

        % Design point selector (varying goal)
        GoalSelector
        GoalSelectorListener
        GoalSelectorFigureListener
    end

    properties (Access=protected,Dependent)
        % Responses that represents the System. This response gets updated
        % whenever the System property changes
        DesignResponses_

        % Responses that represents the tuning goal. This response gets updated
        % whenever the TuningGoal property changes
        GoalResponses_

        % Responses that represent compared designs.
        ComparedDesignResponses_
    end

    properties (GetAccess = protected, SetAccess=?controllib.chart.internal.foundation.AbstractPlot, WeakHandle, Transient, NonCopyable)
        % Plot handle
        PlotHandle_ controllib.chart.internal.foundation.AbstractPlot {mustBeScalarOrEmpty} = controllib.chart.internal.foundation.AbstractPlot.empty
    end

    properties (Access = protected, WeakHandle, Transient, NonCopyable)
        % Design point selector (varying goal)
        GoalSelectorTopText matlab.graphics.primitive.Text {mustBeScalarOrEmpty} = matlab.graphics.primitive.Text.empty
        GoalSelectorBottomText matlab.graphics.primitive.Text {mustBeScalarOrEmpty} = matlab.graphics.primitive.Text.empty
        % Context menu items
        ZoomGoalMenu matlab.ui.container.Menu {mustBeScalarOrEmpty} = matlab.ui.container.Menu.empty
        FullViewMenu matlab.ui.container.Menu {mustBeScalarOrEmpty} = matlab.ui.container.Menu.empty
    end

    %% Constructor/destructor
    methods
        function this = TuningGoalPlotManager(TG,CL)
            arguments
                TG TuningGoal.Generic
                CL = []
            end
            % Set properties
            this.TuningGoal = TG;
            if ~isequal(CL,[])
                this.System = CL;
            end
        end

        function delete(this)
            delete@controllib.chart.internal.foundation.MixInListeners(this);
            delete(this.LocalGoalListeners);
            delete(this.PlotContextMenuOpeningListener);
            delete(this.PlotDeleteListener);
            delete(this.GoalSelectorListener);
            delete(this.GoalSelectorFigureListener);
            delete(this.GoalSelector);
        end
    end

    %% Get/Set
    methods
        % TuningGoal
        function set.TuningGoal(this, TG)
            % Set TuningGoal property
            this.TuningGoal = TG;
            % REVISIT
            if ~isempty(this.PlotHandle_) && isvalid(this.PlotHandle_) %#ok<*MCSUP>
                % Handle transition fixed/varying goal
                varyingGoalConfig(this)
                % update only if plot already exists. Compute new data from
                % the tuning goal and update the GoalWaveform when the
                % TuningGoal changes
                updatePlot(this)
                % Update Figure name
                fig = ancestor(this.PlotHandle_,'figure');
                fig.Name = sprintf('%s',this.TuningGoal.Name);
            end
        end

        % System
        function Value = get.System(this)
            Value = this.System_;
        end
        
        function set.System(this, sys)
            this.System_ = sys;
            this.SamplingGrid_ = getSamplingGrid(sys);
            if ~isempty(this.PlotHandle_) && isvalid(this.PlotHandle_)
                % Handle change in SamplingGrid
                varyingGoalConfig(this)
                % update only if plot already exists
                updatePlot(this);
            end
        end

        % ActiveGoal
        function ActiveGoal = get.ActiveGoal(this)
            ActiveGoal = this.TuningGoal(this.GoalIndex);
        end

        % GoalResponses_
        function GoalResponses_ = get.GoalResponses_(this)
            GoalResponses_ = getGoalResponses(this.ActiveGoal,this.System_,this.PlotHandle_);
        end

        % DesignResponses_
        function DesignResponses_ = get.DesignResponses_(this)
            DesignResponses_ = getDesignResponses(this.ActiveGoal,this.System_,this.PlotHandle_);
        end

        % ComparedDesignResponses_
        function ComparedDesignResponses_ = get.ComparedDesignResponses_(this)
            ComparedDesignResponses_ = getComparedResponses(this.ActiveGoal,this.System_,this.PlotHandle_);
        end

        % Ts
        function Ts = get.Ts(this)
            Ts = getTs(this.ActiveGoal,this.System_);
        end

        % TU
        function TU = get.TU(this)
            TU = getTU(this.ActiveGoal,this.System_);
        end
    end

    %% Public methods
    methods
        % Create plot
        function createPlot(this,ax)
            % Create the plot
            h = createPlot(this.ActiveGoal,this.System_,ax);
            addTuningGoalPlotManager(h,this);
        end

        function initializePlot(this)
            this.XLimitsFocus_ = this.PlotHandle_.XLimitsFocus;
            this.YLimitsFocus_ = this.PlotHandle_.YLimitsFocus;
            updateMenu(this);
            varyingGoalConfig(this);
            addPlotListeners(this);
            updateLimits(this);
        end

        % Add listeners
        function addPlotListeners(this)
            weakThis = matlab.lang.WeakReference(this);
            registerListeners(this,...
                addlistener(this.PlotHandle_,'XLimitsFocus','PostSet',...
                @(es,ed) updateXLimitFocus(weakThis.Handle)),'XLimitsFocusListener');
            registerListeners(this,...
                addlistener(this.PlotHandle_,'YLimitsFocus','PostSet',...
                @(es,ed) updateYLimitFocus(weakThis.Handle)),'YLimitsFocusListener');
            this.LocalGoalListeners = addLocalPlotListeners(this.ActiveGoal,this.System_,this.PlotHandle_);

            % Local functions
            function updateXLimitFocus(this)
                if this.PlotHandle_.XLimitsFocusFromResponses
                    this.XLimitsFocus_ = this.PlotHandle_.XLimitsFocus;
                end
                if iscell(this.PlotHandle_.XLimitsMode) && all(cellfun(@(x) strcmpi(x,'auto'),this.PlotHandle_.XLimitsMode))
                    updateLimits(this);
                elseif strcmpi(this.PlotHandle_.XLimitsMode,'auto')
                    updateLimits(this);
                end
            end

            function updateYLimitFocus(this)
                if this.PlotHandle_.YLimitsFocusFromResponses
                    this.YLimitsFocus_ = this.PlotHandle_.YLimitsFocus;
                end
                if iscell(this.PlotHandle_.YLimitsMode) && all(cellfun(@(x) strcmpi(x,'auto'),this.PlotHandle_.YLimitsMode))
                    updateLimits(this);
                elseif strcmpi(this.PlotHandle_.YLimitsMode,'auto')
                    updateLimits(this);
                end
            end
        end

        % Add design
        function addDesign(this,Design,DesignName)
            % Set Design names
            if (nargin == 2) || isempty(DesignName) %% REVISIT
                % Assign a name to the design to be used in the legend
                DesignName = strcat('Design',num2str(numel(this.ComparedDesigns)+1));
            end
            % Set Design Styles
            NewStyle = findNextAvailableDesignStyle(this); % Find a style for the design
            Type = getComparisonStyleType(this.ActiveGoal);
            if strcmp(Type,'LineStyle')
                Style = NewStyle{1,1};
            else
                Style = NewStyle{1,2};
            end
            % addDesign is implemented by each tuning goal to compute a
            % data source for the design waveforms
            addDesign(this.ActiveGoal,this.PlotHandle_,Design,DesignName,Style);
            % Keep a record of already used styles
            this.DesignStyles_ = [this.DesignStyles_;NewStyle];
            % Add Design to ComparedDesigns %% REVISIT
            if isempty(this.ComparedDesigns)
                this.ComparedDesigns{1} = Design;
            else
                this.ComparedDesigns{end+1} = Design;
            end
        end

        % Remove design
        function removeDesign(this,idx)
            if idx > numel(this.ComparedDesigns)
                error(message('Controllib:plots:strErrorIndexExceedsNumDesigns'));
            end
            % Remove unwanted designs
            DesignResponses = this.ComparedDesignResponses_(idx);
            name = fieldnames(DesignResponses); % Field names
            for ct=1:numel(name) % Number of fields
                delete(DesignResponses.(name{ct}));
            end
            this.ComparedDesigns(idx) = [];
            this.DesignStyles_(idx,:) = [];
        end

        % Update Plot
        function updatePlot(this)
            % Update Goal
            updateGoal(this.ActiveGoal,this.System_,this.PlotHandle_);
            % Update all data in plot
            if ~isempty(this.System_)
                % Update Current Design
                updateDesign(this.ActiveGoal,this.DesignResponses_,this.System_);
                % Update Compared Designs
                for ct = 1: numel(this.ComparedDesignResponses_)
                    CL = setBlockValue(genss(this.System_),genss(this.ComparedDesigns{ct}));
                    updateDesign(this.ActiveGoal,this.ComparedDesignResponses_(ct),CL);
                end
            end
            updateLimits(this);
        end

        % Update limits
        function updateLimits(this)
            % Need to update the chart responses/data first, so that the
            % TuningGoal limit update happens after that.
            qeUpdate(this.PlotHandle_);
            switch this.AutoZoomMode
                case 'Goal'
                    disableListeners(this,['XLimitsFocusListener';'YLimitsFocusListener']);
                    updateLimits(this.ActiveGoal,this.Ts,this.PlotHandle_,this.XLimitsFocus_,this.YLimitsFocus_);
                    enableListeners(this,['XLimitsFocusListener';'YLimitsFocusListener']);
                case 'Full'
                    disableListeners(this,['XLimitsFocusListener';'YLimitsFocusListener']);
                    this.PlotHandle_.XLimitsFocusFromResponses = true;
                    this.PlotHandle_.YLimitsFocusFromResponses = true;
                    this.XLimitsFocus_ = this.PlotHandle_.XLimitsFocus;
                    this.YLimitsFocus_ = this.PlotHandle_.YLimitsFocus;
                    enableListeners(this,['XLimitsFocusListener';'YLimitsFocusListener']);
            end
            if numel(this.TuningGoal)>1
                % Update text position
                showDesignPoint(this)
            end
        end

        % Update Current Design Data %% REVISIT
        function updateCurrentDesignData(this,NewSys)
            % NOTE: Assumes no change in SamplingGrid
            this.System_ = NewSys;
            updateDesign(this.ActiveGoal,this.DesignResponses_,this.System_);
        end

        % Get PlotHandle_ for tuning goal
        function hPlot = getPlotHandle(this)
            hPlot = this.PlotHandle_;
        end

        % Get Design Styles
        function ds = getDesignStyles(this)
            ds = this.DesignStyles_;
        end

        % Set title for TG plot
        function setTitle(this,NewTitle)
            this.PlotHandle_.Title.String = NewTitle;
        end

        % Set inputName and outputName for TG plot
        function setIONames(this,inputName,outputName)
            this.PlotHandle_.InputNames = inputName;
            this.PlotHandle_.OutputNames = outputName;
        end

        function varyingGoalConfig(this)
            % Setup for fixed vs. varying goal
            NG = numel(this.TuningGoal);
            % First tear down
            delete(this.GoalSelectorTopText);
            delete(this.GoalSelectorBottomText);
            delete(this.GoalSelector);
            delete(this.GoalSelectorListener);
            delete(this.GoalSelectorFigureListener);
            if this.GoalIndex>NG
                this.GoalIndex = 1;
            end
            % Then rebuild
            if NG>1
                % Show first design point
                ax = getChartAxes(this.PlotHandle_);
                fig = ancestor(this.PlotHandle_,'figure');
                v = qeGetView(this.PlotHandle_);
                sz = v.Style.Axes.FontSize;
                weakThis = matlab.lang.WeakReference(this);
                topTxt = text(Parent=ax(1),...
                    Position=[0 0 10],FontSize=sz,...
                    ButtonDownFcn=@(x,y) openDesignPointSelector(weakThis.Handle),...
                    Units='pixels',Tag='DesignPointLabel');
                controllib.plot.internal.utils.setColorProperty(topTxt,'BackgroundColor',"--mw-graphics-backgroundColor-axes-primary")
                this.GoalSelectorTopText = topTxt;
                bottomTxt = text(Parent=ax(1),...
                    Position=[0 0 10],FontSize=sz,...
                    ButtonDownFcn=@(x,y) openDesignPointSelector(weakThis.Handle),...
                    Units='pixels',Tag='DesignPointLabelChange');
                bottomTxt.String = ['\bf{' getString(message('Controllib:plots:strCHANGE')) '}'];
                controllib.plot.internal.utils.setColorProperty(bottomTxt,'Color',"--mw-graphics-colorOrder-9-primary")
                controllib.plot.internal.utils.setColorProperty(bottomTxt,'BackgroundColor',"--mw-graphics-backgroundColor-axes-primary")
                this.GoalSelectorBottomText = bottomTxt;
                this.GoalSelectorFigureListener = addlistener(fig,'SizeChanged',@(x,y) showDesignPoint(weakThis.Handle));
                showDesignPoint(this)
            end
        end

        function showDesignPoint(this)
            % Display sampling grid coordinate in upper left corner
            % Update string
            topTxt = this.GoalSelectorTopText;
            bottomTxt = this.GoalSelectorBottomText;
            SG = structfun(@(x) x(this.GoalIndex),getSamplingGrid(this),'UniformOutput',false);
            C = [fieldnames(SG) struct2cell(SG)]';
            str = sprintf('%s = %0.3g, ',C{:});
            topTxt.String = str(1:end-2);
            ax = getChartAxes(this.PlotHandle_);
            axPos = controllibutils.getPosition(ax(1),'pixels');
            topTxt.Position = [10 axPos(4)-topTxt.Extent(4) 10];
            bottomTxt.Position = [10,axPos(4)-1.5*topTxt.Extent(4)-bottomTxt.Extent(4),10];
        end

        function updateDesignPoint(this)
            % Track selected design point
            this.GoalIndex = this.GoalSelector.Selection;
            % Update plot
            updatePlot(this)
            % Update text
            showDesignPoint(this);
        end

        function openDesignPointSelector(this)
            % Open design point selector widget
            if isempty(this.GoalSelector) || ~isvalid(this.GoalSelector)
                this.GoalSelector = controllib.chart.internal.widget.SamplingGridSelector(getSamplingGrid(this));
                weakThis = matlab.lang.WeakReference(this);
                this.GoalSelectorListener = addlistener(this.GoalSelector,...
                    'SelectionChanged',@(x,y) updateDesignPoint(weakThis.Handle));
                fig = ancestor(this.PlotHandle_,'figure');
                show(this.GoalSelector,fig);
                pack(this.GoalSelector);
            end
            % Set selected point
            this.GoalSelector.Selection = this.GoalIndex;
        end

        function setSamplingGrid(this,SG)
            this.SamplingGrid_ = SG;
        end

        function SG = getSamplingGrid(this)
            % For varying goals only
            SG = this.SamplingGrid_;
            if isempty(SG) || isequal(SG,struct)
                % Generate default grid ignoring singleton dimensions to avoid
                % creating dummy indices and sliders
                gSize = size(this.TuningGoal);
                gSize = gSize(gSize>1);
                NDIM = max(1,numel(gSize));
                if NDIM==1
                    SG = struct('i',(1:prod(gSize))');
                else
                    C = cell(NDIM,1);
                    for ct=1:NDIM
                        C{ct} = (1:gSize(ct))';
                    end
                    [C{:}] = ndgrid(C{:});
                    SG = cell2struct(C,cellstr("i"+(1:NDIM)),1);
                end
            end
        end

    end


    %% Private methods
    methods (Access = private)
        function updateMenu(this)
            removeMenu(this.PlotHandle_,'fullview');
            weakThis = matlab.lang.WeakReference(this);
            zoomGoalMenu = uimenu(Parent=[],...
                Text=getString(message('Controllib:plots:strZoomGoal')),...
                Tag="zoomgoalTG",...
                MenuSelectedFcn=@(es,ed) toggleFullView(weakThis.Handle,'Goal'));
            fullViewMenu = uimenu(Parent=[],...
                Text=getString(message('Controllib:plots:strFullView')),...
                Tag="fullviewTG",...
                MenuSelectedFcn=@(es,ed) toggleFullView(weakThis.Handle,'Full'));
            tags = getMenuTags(this.PlotHandle_);
            if ismember('normalize',tags)
                addMenu(this.PlotHandle_,zoomGoalMenu,Below='normalize')
            else
                addMenu(this.PlotHandle_,zoomGoalMenu,Below='grid')
            end
            addMenu(this.PlotHandle_,fullViewMenu,Below='zoomgoalTG')
            this.ZoomGoalMenu = zoomGoalMenu;
            this.FullViewMenu = fullViewMenu;
            syncFullView(this);
            % Override full view in plot as needed
            ContextMenu = qeGetContextMenu(this.PlotHandle_);
            this.PlotContextMenuOpeningListener = addlistener(ContextMenu,'ContextMenuOpening',...
                @(es,ed) syncFullView(weakThis.Handle));
        end

        function syncFullView(this)
            isXLimitsAuto = contains(cellstr(this.PlotHandle_.XLimitsMode),'auto');
            isYLimitsAuto = contains(cellstr(this.PlotHandle_.YLimitsMode),'auto');
            if all(isXLimitsAuto(:)) && all(isYLimitsAuto(:))
                isAutoZoom = true;
            else
                isAutoZoom = false;
            end
            isZoomGoal = strcmp(this.AutoZoomMode,'Goal');
            this.FullViewMenu.Enable = ~isAutoZoom || isZoomGoal;
            this.FullViewMenu.Checked = isAutoZoom && ~isZoomGoal;
            this.ZoomGoalMenu.Enable = ~isAutoZoom || ~isZoomGoal;
            this.ZoomGoalMenu.Checked = isAutoZoom && isZoomGoal;
        end

        function toggleFullView(this,Type)
            this.AutoZoomMode = Type;
            this.PlotHandle_.XLimitsMode = "auto";
            this.PlotHandle_.YLimitsMode = "auto";
            syncFullView(this);
            updateLimits(this);
        end

        % Find next available Design style
        function Style = findNextAvailableDesignStyle(this)
            % Find the next available unused design to be used for the
            % design waveform
            StyleList = {...
                '--', controllib.plot.internal.utils.GraphicsColor(5,"quaternary").SemanticName;
                '-.', controllib.plot.internal.utils.GraphicsColor(6,"quaternary").SemanticName;
                ':' , controllib.plot.internal.utils.GraphicsColor(10,"quaternary").SemanticName}; % Standard list of design styles

            index = zeros(size(StyleList(:,1)));
            for ct=1:length(this.DesignStyles_(:,1))
                [~,~,match] = intersect(this.DesignStyles_(ct,1),StyleList(:,1));
                index(match) = index(match) + 1;
            end

            [~, StyleIdx] = min(index);
            Style = StyleList(StyleIdx,:);
        end
    end

    %% Hidden methods
    methods (Hidden)
        function dlg = qeOpenDesignSelector(this)
            openDesignPointSelector(this);
            dlg = this.GoalSelector;
        end
    end
end