classdef (Hidden = true) YLevelSelector < handle
    % YLevelSelector is a widget that allows users to select a Y level
    % on a plot by dragging a line

    % Copyright 2023-2024 The MathWorks, Inc.
 
    %% Properties
    properties(AbortSet,Dependent,SetObservable)
        YLevel
        Visible
    end

    properties(Dependent,SetObservable)
        SelectorWindow
        LineColor
    end

    properties (Access=protected)
        LimitLine
        LimitKnob
    end

    properties (Dependent,Access=protected)
        XMarker
    end

    properties (Access=protected,Transient)
        Listeners
    end

    properties(Access=private)
        YLevel_I
        SelectorWindow_I
        LineColor_I = "--mw-graphics-colorNeutral-line-secondary"
    end

    properties (SetAccess=private,WeakHandle)
        Parent (1,1) matlab.graphics.axis.Axes
    end

    properties (Dependent,SetAccess=protected)
        Figure
    end

    %% Events
    events
        SelectorMoved
    end

    %% Constructor/destructor
    methods
        function this = YLevelSelector(Parent,YLevel,SelectorWindow)
            arguments
                Parent (1,1) matlab.graphics.axis.Axes
                YLevel (1,1) double = 1
                SelectorWindow (1,2) double = [-Inf Inf]
            end
            this.Parent = Parent;
            this.YLevel_I = YLevel;
            if SelectorWindow(2) < SelectorWindow(1)
                error('SelectorWindow(2) must be greater than or equal to SelectorWindow(1).');
            end
            this.SelectorWindow_I = SelectorWindow;
            % Create the widgets
            constructLines(this)
        end

        function delete(this)
            delete(this.Listeners);
        end
    end

    %% Get/Set
    methods
        % Visible
        function visible = get.Visible(this)
            visible = this.LimitLine.Visible;
        end

        function set.Visible(this,value)
            arguments
                this (1,1) ctrluis.YLevelSelector
                value (1,1) matlab.lang.OnOffSwitchState
            end
            this.LimitLine.Visible = value;
            this.LimitKnob.Visible = value;
            draw(this);
        end

        % YLevel
        function value = get.YLevel(this)
            value = this.YLevel_I;
        end

        function set.YLevel(this,value)
            arguments
                this (1,1) ctrluis.YLevelSelector
                value (1,1) double
            end
            this.YLevel_I = min(max(value,this.SelectorWindow(1)),this.SelectorWindow(2));
            draw(this);
        end

        % XMarker
        function value = get.XMarker(this)
            if strcmpi(this.Parent.XScale,'linear')
                value = mean(this.Parent.XLim);
            else
                space = logspace(log10(this.Parent.XLim(1)),log10(this.Parent.XLim(2)),3);
                value = space(2);
            end
        end

        % Figure
        function fig = get.Figure(this)
            fig = ancestor(this.Parent,'Figure');
        end

        % SelectorWindow
        function value = get.SelectorWindow(this)
            value = this.SelectorWindow_I;
        end

        function set.SelectorWindow(this,value)
            arguments
                this (1,1) ctrluis.YLevelSelector
                value (1,2) double {ctrluis.YLevelSelector.mustBeRange(value)}
            end
            this.SelectorWindow_I = value;
            this.YLevel = min(max(this.YLevel,value(1)),value(2));
        end

        % LineColor
        function Color = get.LineColor(this)
            Color = this.LineColor_I;
        end     

        function set.LineColor(this,Color)
            controllib.plot.internal.utils.setColorProperty(...
                this.LimitLine,"Color",Color);
            controllib.plot.internal.utils.setColorProperty(...
                this.LimitKnob,"Color",Color);
            controllib.plot.internal.utils.setColorProperty(...
                this.LimitKnob,"MarkerEdgeColor",Color);
            controllib.plot.internal.utils.setColorProperty(...
                this.LimitKnob,"MarkerFaceColor",Color);
            this.LineColor_I = Color;
        end
    end

    %% Private methods
    methods (Access = private)
        function constructLines(this)
            weakThis = matlab.lang.WeakReference(this);
            this.LimitLine = matlab.graphics.chart.decoration.ConstantLine(...
                Value=this.YLevel,...
                InterceptAxis='y',...
                Parent_I=this.Parent,...
                ContextMenu=this.Parent.ContextMenu,...
                LineWidth=1,...
                Visible='off',...
                LegendDisplay='off',...
                XLimInclude='off',...
                YLimInclude='off');
            controllib.plot.internal.utils.setColorProperty(this.LimitLine,"Color",this.LineColor_I);
            this.LimitLine.ButtonDownFcn = @(es,ed) drag(weakThis.Handle,'init');
            this.LimitKnob = matlab.graphics.chart.primitive.Line(...
                XData=this.XMarker,...
                YData=this.YLevel,...
                Parent_I=this.Parent,...
                ContextMenu=this.Parent.ContextMenu,...
                LineWidth=1,...
                Marker='d',...
                LegendDisplay='off',...
                Visible='off',...
                XLimInclude='off',...
                YLimInclude='off');
            controllib.plot.internal.utils.setColorProperty(this.LimitKnob,"MarkerEdgeColor",this.LineColor_I);
            controllib.plot.internal.utils.setColorProperty(this.LimitKnob,"MarkerFaceColor",this.LineColor_I);
            controllib.plot.internal.utils.setColorProperty(this.LimitKnob,"Color",this.LineColor_I);
            this.LimitKnob.ButtonDownFcn = @(es,ed) drag(weakThis.Handle,'init');

            % Create listeners
            % Workaround Ylim property changed event in auto mode
            RespPlot = gcr(this.Parent);
            if isempty(RespPlot)
                registerListeners(this,addlistener(this.Parent,'XLim','PostSet',@(es,ed) draw(weakThis.Handle)))
                registerListeners(this,addlistener(this.Parent,'YLim','PostSet',@(es,ed) draw(weakThis.Handle)))
            else
                if controllib.chart.internal.utils.isChart(RespPlot)
                    axGrid = qeGetAxesGrid(qeGetView(RespPlot));
                    registerListeners(this,addlistener(axGrid,'XLimitsChanged',@(es,ed) draw(weakThis.Handle)))
                    registerListeners(this,addlistener(axGrid,'YLimitsChanged',@(es,ed) draw(weakThis.Handle)))
                else
                    registerListeners(this,handle.listener(RespPlot.AxesGrid,'PostLimitChanged',@(es,ed) draw(weakThis.Handle)))
                    registerListeners(this,handle.listener(RespPlot.AxesGrid,'PostLimitChanged',@(es,ed) draw(weakThis.Handle)))
                end

            end
        end

        function draw(this)
            if this.Visible
                YScale = this.Parent.YScale;
                YLim = this.Parent.YLim;
                value = this.YLevel;
                switch YScale
                    case 'linear'
                        if isinf(value)
                            if value < 0
                                value = YLim(1);
                            else
                                value = YLim(2);
                            end
                        end
                    case 'log'
                        if value == 0
                            value = YLim(1);
                        elseif isinf(value)
                            value = YLim(2);
                        end
                end
                this.LimitLine.Value = value;
                set(this.LimitKnob,'XData',this.XMarker,'YData',value)
            end
        end

        function registerListeners(this,Listeners)
            this.Listeners = [this.Listeners;Listeners(:)];
        end

        function drag(this,action,optionalInputs)
            arguments
                this (1,1) ctrluis.YLevelSelector
                action (1,1) string {mustBeMember(action,["init";"move";"finish"])}
                optionalInputs.StartLocation = []
                optionalInputs.EndLocation = []
            end
            persistent WML WBMClear selectedPoint ptr;

            switch action
                case 'init'
                    optionalInputsCell = namedargs2cell(optionalInputs);
                    L1 = addlistener(this.Figure,'WindowMouseMotion',@(es,ed) drag(this,'move',optionalInputsCell{:}));
                    L2 = addlistener(this.Figure,'WindowMouseRelease',@(es,ed) drag(this,'finish',optionalInputsCell{:}));
                    WML = [L1;L2];
                    WBMClear = isempty(this.Figure.WindowButtonMotionFcn);
                    if WBMClear
                        this.Figure.WindowButtonMotionFcn = @(es,ed) []; %needs func to update CurrentPoint
                    end
                    % Get the selected point
                    if isempty(optionalInputs.StartLocation)
                        selectedPoint = this.Parent.CurrentPoint(1,2);
                    else
                        selectedPoint = optionalInputs.StartLocation;
                    end
                    ptr = this.Figure.Pointer;
                    this.Figure.Pointer = "top";
                    ed = ctrluis.toolstrip.dataprocessing.GenericEventData(struct('Selector','YLevel','Status','Init','Level',this.YLevel));
                    notify(this,'SelectorMoved',ed)
                case 'move'
                    oldPoint = selectedPoint;
                    if isempty(optionalInputs.EndLocation)
                        newPoint = this.Parent.CurrentPoint(1,2);
                    else
                        newPoint = optionalInputs.EndLocation;
                    end
                    this.YLevel = computeNewLevel(this,oldPoint,newPoint);
                    selectedPoint = newPoint;
                    ed = ctrluis.toolstrip.dataprocessing.GenericEventData(struct('Selector','YLevel','Status','InProgress','Level',this.YLevel));
                    notify(this,'SelectorMoved',ed)
                case 'finish'
                    delete(WML);
                    if WBMClear
                        this.Figure.WindowButtonMotionFcn = [];
                    end
                    this.Figure.Pointer = ptr;
                    ed = ctrluis.toolstrip.dataprocessing.GenericEventData(struct('Selector','YLevel','Status','Finished','Level',this.YLevel));
                    notify(this,'SelectorMoved',ed)
            end
        end

        function newLevel = computeNewLevel(this,oldPoint,newPoint)
            oldLevel = this.YLevel;
            YScale = this.Parent.YScale;
            YLim = this.Parent.YLim;
            switch YScale
                case 'linear'
                    if isinf(oldLevel)
                        if oldLevel < 0
                            oldLevel = YLim(1);
                        else
                            oldLevel = YLim(2);
                        end
                    end
                    newLevel = oldLevel+newPoint-oldPoint;
                case 'log'
                    if oldLevel == 0
                        oldLevel = YLim(1);
                    elseif isinf(oldLevel)
                        oldLevel = YLim(2);
                    end
                    newLevel = 10.^(log10(newPoint)-log10(oldPoint)+log10(oldLevel));
            end
            newLevel = max(newLevel,YLim(1)+eps(YLim(1)));
            newLevel = min(newLevel,YLim(2)-eps(YLim(2)));
            newLevel = max(newLevel,this.SelectorWindow(1)+eps(this.SelectorWindow(1)));
            newLevel = min(newLevel,this.SelectorWindow(2)-eps(this.SelectorWindow(2)));
        end
    end

    %% Static private methods
    methods (Static,Access=private)
        function mustBeRange(range)
            arguments
                range (1,2) double
            end
            mustBeLessThan(range(1),range(2));
        end
    end

    %% Hidden methods
    methods (Hidden)
        function wgts = qeGetWidgets(this)
            wgts = struct('LimitLine',this.LimitLine,...
                'LimitKnob',this.LimitKnob);
        end

        function qeDrag(this,newPoint)
            oldPoint = this.YLevel;
            drag(this,'init',StartLocation=oldPoint,EndLocation=newPoint);
            drag(this,'move',StartLocation=oldPoint,EndLocation=newPoint);
            drag(this,'finish',StartLocation=oldPoint,EndLocation=newPoint);
        end
    end
end
