classdef (Hidden = true) XRangeSelector < handle
    % @XRangeSelector class definition
    % Author(s): John Glass 17-Mar-2009
    % Revised:

    %   Copyright 2009-2024 The MathWorks, Inc.
 
    %% Properties
    properties (AbortSet,Dependent,SetObservable)
        XRange
        Visible
    end

    properties(Dependent,SetObservable)
        SelectorWindow
        LineColor
        PatchColor
        PatchAlpha
    end

    properties (Access=protected)
        LowerLimitLine
        LowerLimitKnob
        UpperLimitLine
        UpperLimitKnob
        SelectedPatch
    end

    properties (Dependent,Access=protected)
        YMarker
    end

    properties (Access=protected,Transient)
        Listeners
    end

    properties(Access=private)
        XRange_I
        SelectorWindow_I
        LineColor_I = "--mw-graphics-colorNeutral-line-secondary"
        PatchColor_I = controllib.plot.internal.utils.GraphicsColor(8).SemanticName
        PatchAlpha_I = 0.3
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
        function this = XRangeSelector(Parent,XRange,SelectorWindow)
            arguments
                Parent (1,1) matlab.graphics.axis.Axes
                XRange (1,2) double = [0 1]
                SelectorWindow (1,2) double = [-Inf Inf]
            end
            this.Parent = Parent;
            if XRange(2) < XRange(1)
                error('XRange(2) must be greater than or equal to XRange(1).');
            end
            if SelectorWindow(2) < SelectorWindow(1)
                error('SelectorWindow(2) must be greater than or equal to SelectorWindow(1).');
            end
            this.SelectorWindow_I = SelectorWindow;
            this.XRange_I = XRange;
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
            visible = this.SelectedPatch.Visible;
        end

        function set.Visible(this,value)
            arguments
                this (1,1) ctrluis.XRangeSelector
                value (1,1) matlab.lang.OnOffSwitchState
            end
            this.LowerLimitLine.Visible = value;
            this.LowerLimitKnob.Visible = value;
            this.UpperLimitLine.Visible = value;
            this.UpperLimitKnob.Visible = value;
            this.SelectedPatch.Visible = value;
            draw(this);
        end

        % XRange
        function value = get.XRange(this)
            value = this.XRange_I;
        end

        function set.XRange(this,value)
            arguments
                this (1,1) ctrluis.XRangeSelector
                value (1,2) double {ctrluis.XRangeSelector.mustBeRange(value)}
            end
            xLower = min(max(value(1),this.SelectorWindow(1)),this.SelectorWindow(2));
            xUpper = min(max(value(2),this.SelectorWindow(1)),this.SelectorWindow(2));
            this.XRange_I = [xLower xUpper];
            draw(this);
        end

        % YMarker
        function value = get.YMarker(this)
            if strcmpi(this.Parent.YScale,'linear')
                value = mean(this.Parent.YLim);
            else
                space = logspace(log10(this.Parent.YLim(1)),log10(this.Parent.YLim(2)),3);
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
                this (1,1) ctrluis.XRangeSelector
                value (1,2) double {ctrluis.XRangeSelector.mustBeRange(value)}
            end
            this.SelectorWindow_I = value;
            xLower = min(max(this.XRange(1),value(1)),value(2));
            xUpper = min(max(this.XRange(2),value(1)),value(2));
            if xLower == xUpper
                if xLower == value(1)
                    xUpper = min(value(2),xUpper+eps(xUpper));
                else
                    xLower = max(value(1),xLower-eps(xLower));
                end
            end
            this.XRange = [xLower xUpper];
        end

        % PatchColor
        function Color = get.PatchColor(this)
            Color = this.PatchColor_I;
        end     
        
        function set.PatchColor(this,Color)
            controllib.plot.internal.utils.setColorProperty(...
                this.SelectedPatch,"FaceColor",Color);
            controllib.plot.internal.utils.setColorProperty(...
                this.SelectedPatch,"EdgeColor",Color);
            this.PatchColor_I = Color;
        end

        % PatchAlpha
        function val = get.PatchAlpha(this)
            val = this.PatchAlpha_I;
        end     

        function set.PatchAlpha(this,val)
            this.SelectedPatch.FaceAlpha = val;
            this.SelectedPatch.EdgeAlpha = val;
            this.PatchAlpha_I = val;
        end

        % LineColor
        function Color = get.LineColor(this)
            Color = this.LineColor_I;
        end     

        function set.LineColor(this,Color)
            controllib.plot.internal.utils.setColorProperty(...
                this.LowerLimitLine,"Color",Color);
            controllib.plot.internal.utils.setColorProperty(...
                this.LowerLimitKnob,"Color",Color);
            controllib.plot.internal.utils.setColorProperty(...
                this.LowerLimitKnob,"MarkerEdgeColor",Color);
            controllib.plot.internal.utils.setColorProperty(...
                this.LowerLimitKnob,"MarkerFaceColor",Color);
            controllib.plot.internal.utils.setColorProperty(...
                this.UpperLimitLine,"Color",Color);
            controllib.plot.internal.utils.setColorProperty(...
                this.UpperLimitKnob,"Color",Color);
            controllib.plot.internal.utils.setColorProperty(...
                this.UpperLimitKnob,"MarkerEdgeColor",Color);
            controllib.plot.internal.utils.setColorProperty(...
                this.UpperLimitKnob,"MarkerFaceColor",Color);
            this.LineColor_I = Color;
        end
    end

    %% Private methods
    methods (Access = private)
        function constructLines(this)
            weakThis = matlab.lang.WeakReference(this);
            this.SelectedPatch = matlab.graphics.chart.decoration.ConstantRegion(...
                Value=this.XRange,...
                InterceptAxis='x',...
                Parent_I=this.Parent,...
                ContextMenu=this.Parent.ContextMenu,...
                LineWidth=1,...
                FaceAlpha=this.PatchAlpha_I,...
                EdgeAlpha=this.PatchAlpha_I,...
                Visible='off',...
                LegendDisplay='off',...
                XLimInclude='off',...
                YLimInclude='off',...
                HandleVisibility='off');
            controllib.plot.internal.utils.setColorProperty(this.SelectedPatch,"FaceColor",this.PatchColor_I);
            controllib.plot.internal.utils.setColorProperty(this.SelectedPatch,"EdgeColor",this.PatchColor_I);
            this.SelectedPatch.ButtonDownFcn = @(es,ed) drag(weakThis.Handle,'SelectedPatch','init');
            this.LowerLimitLine = matlab.graphics.chart.decoration.ConstantLine(...
                Value=this.XRange(1),...
                InterceptAxis='x',...
                Parent_I=this.Parent,...
                ContextMenu=this.Parent.ContextMenu,...
                LineWidth=1,...
                Visible='off',...
                LegendDisplay='off',...
                XLimInclude='off',...
                YLimInclude='off',...
                HandleVisibility='off');
            controllib.plot.internal.utils.setColorProperty(this.LowerLimitLine,"Color",this.LineColor_I);
            this.LowerLimitLine.ButtonDownFcn = @(es,ed) drag(weakThis.Handle,'LowerLimitLine','init');
            this.UpperLimitLine = matlab.graphics.chart.decoration.ConstantLine(...
                Value=this.XRange(2),...
                InterceptAxis='x',...
                Parent_I=this.Parent,...
                ContextMenu=this.Parent.ContextMenu,...
                LineWidth=1,...
                Visible='off',...
                LegendDisplay='off',...
                XLimInclude='off',...
                YLimInclude='off',...
                HandleVisibility='off');
            controllib.plot.internal.utils.setColorProperty(this.UpperLimitLine,"Color",this.LineColor_I);
            this.UpperLimitLine.ButtonDownFcn = @(es,ed) drag(weakThis.Handle,'UpperLimitLine','init');
            this.LowerLimitKnob = matlab.graphics.chart.primitive.Line(...
                XData=this.XRange(1),...
                YData=this.YMarker,...
                Parent_I=this.Parent,...
                ContextMenu=this.Parent.ContextMenu,...
                LineWidth=1,...
                Marker='<',...
                LegendDisplay='off',...
                Visible='off',...
                XLimInclude='off',...
                YLimInclude='off',...
                HandleVisibility='off');
            controllib.plot.internal.utils.setColorProperty(this.LowerLimitKnob,"MarkerEdgeColor",this.LineColor_I);
            controllib.plot.internal.utils.setColorProperty(this.LowerLimitKnob,"MarkerFaceColor",this.LineColor_I);
            controllib.plot.internal.utils.setColorProperty(this.LowerLimitKnob,"Color",this.LineColor_I);
            this.LowerLimitKnob.ButtonDownFcn = @(es,ed) drag(weakThis.Handle,'LowerLimitLine','init');
            this.UpperLimitKnob = matlab.graphics.chart.primitive.Line(...
                XData=this.XRange(2),...
                YData=this.YMarker,...
                Parent_I=this.Parent,...
                ContextMenu=this.Parent.ContextMenu,...
                LineWidth=1,...
                Marker='>',...
                LegendDisplay='off',...
                Visible='off',...
                XLimInclude='off',...
                YLimInclude='off',...
                HandleVisibility='off');
            controllib.plot.internal.utils.setColorProperty(this.UpperLimitKnob,"MarkerEdgeColor",this.LineColor_I);
            controllib.plot.internal.utils.setColorProperty(this.UpperLimitKnob,"MarkerFaceColor",this.LineColor_I);
            controllib.plot.internal.utils.setColorProperty(this.UpperLimitKnob,"Color",this.LineColor_I);
            this.UpperLimitKnob.ButtonDownFcn = @(es,ed) drag(weakThis.Handle,'UpperLimitLine','init');

            % Create listeners
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
                XScale = this.Parent.XScale;
                XLim = this.Parent.XLim;
                XLower = this.XRange(1);
                XUpper = this.XRange(2);
                switch XScale
                    case 'linear'
                        if isinf(this.XRange(1))
                            XLower = XLim(1);
                        end
                        if isinf(this.XRange(2))
                            XUpper = XLim(2);
                        end
                    case 'log'
                        if this.XRange(1) == 0
                            XLower = XLim(1);
                        end
                        if isinf(this.XRange(2))
                            XUpper = XLim(2);
                        end
                end
                this.LowerLimitLine.Value = XLower;
                this.UpperLimitLine.Value = XUpper;
                set(this.LowerLimitKnob,'XData',XLower,'YData',this.YMarker)
                set(this.UpperLimitKnob,'XData',XUpper,'YData',this.YMarker)
                this.SelectedPatch.Value = [XLower XUpper];
            end
        end

        function registerListeners(this,Listeners)
            this.Listeners = [this.Listeners;Listeners(:)];
        end

        function drag(this,source,action,optionalInputs)
            arguments
                this (1,1) ctrluis.XRangeSelector
                source (1,1) string
                action (1,1) string {mustBeMember(action,["init";"move";"finish"])}
                optionalInputs.StartLocation = []
                optionalInputs.EndLocation = []
            end
            persistent WML WBMClear selectedPoint ptr;

            switch action
                case 'init'
                    optionalInputsCell = namedargs2cell(optionalInputs);
                    L1 = addlistener(this.Figure,'WindowMouseMotion',@(es,ed) drag(this,source,'move',optionalInputsCell{:}));
                    L2 = addlistener(this.Figure,'WindowMouseRelease',@(es,ed) drag(this,source,'finish',optionalInputsCell{:}));
                    WML = [L1;L2];
                    WBMClear = isempty(this.Figure.WindowButtonMotionFcn);
                    if WBMClear
                        this.Figure.WindowButtonMotionFcn = @(es,ed) []; %needs func to update CurrentPoint
                    end
                    % Get the selected point
                    if isempty(optionalInputs.StartLocation)
                        selectedPoint = this.Parent.CurrentPoint(1,1);
                    else
                        selectedPoint = optionalInputs.StartLocation;
                    end
                    ptr = this.Figure.Pointer;
                    this.Figure.Pointer = "left";
                    ed = ctrluis.toolstrip.dataprocessing.GenericEventData(struct('Selector','XRange','Status','Init','Source',source,'Range',this.XRange));
                    notify(this,'SelectorMoved',ed)
                case 'move'
                    oldPoint = selectedPoint;
                    if isempty(optionalInputs.EndLocation)
                        newPoint = this.Parent.CurrentPoint(1,1);
                    else
                        newPoint = optionalInputs.EndLocation;
                    end
                    newRange = computeNewRange(this,source,oldPoint,newPoint);
                    try %#ok<TRYNC>
                        switch source
                            case 'LowerLimitLine'
                                this.XRange(1) = newRange(1);
                            case 'UpperLimitLine'
                                this.XRange(2) = newRange(2);
                            case 'SelectedPatch'
                                this.XRange = newRange;
                        end
                    end
                    selectedPoint = newPoint;
                    ed = ctrluis.toolstrip.dataprocessing.GenericEventData(struct('Selector','XRange','Status','InProgress','Source',source,'Range',this.XRange));
                    notify(this,'SelectorMoved',ed)
                case 'finish'
                    delete(WML);
                    if WBMClear
                        this.Figure.WindowButtonMotionFcn = [];
                    end
                    this.Figure.Pointer = ptr;
                    ed = ctrluis.toolstrip.dataprocessing.GenericEventData(struct('Selector','XRange','Status','Finished','Source',source,'Range',this.XRange));
                    notify(this,'SelectorMoved',ed)
            end
        end

        function newRange = computeNewRange(this,source,oldPoint,newPoint)
            oldRange = this.XRange;
            XScale = this.Parent.XScale;
            XLim = this.Parent.XLim;
            switch XScale
                case 'linear'
                    if isinf(oldRange(1))
                        oldRange(1) = XLim(1);
                    end
                    if isinf(oldRange(2))
                        oldRange(2) = XLim(2);
                    end
                    newRange = oldRange+newPoint-oldPoint;
                case 'log'
                    if oldRange(1) == 0
                        oldRange(1) = XLim(1);
                    end
                    if isinf(oldRange(2))
                        oldRange(2) = XLim(2);
                    end
                    newRange = 10.^(log10(newPoint)-log10(oldPoint)+log10(oldRange));
            end
            switch source
                case 'LowerLimitLine'
                    newRange(1) = max(newRange(1),XLim(1)+eps(XLim(1)));
                    newRange(1) = min(newRange(1),oldRange(2));
                case 'UpperLimitLine'
                    newRange(2) = min(newRange(2),XLim(2)-eps(XLim(2)));
                    newRange(2) = max(newRange(2),oldRange(1));
            end
            switch source
                case 'LowerLimitLine'
                    newRange(1) = max(newRange(1),this.SelectorWindow(1)+eps(this.SelectorWindow(1)));
                    newRange(1) = min(newRange(1),this.SelectorWindow(2)-eps(this.SelectorWindow(2)));
                case 'UpperLimitLine'
                    newRange(2) = max(newRange(2),this.SelectorWindow(1)+eps(this.SelectorWindow(1)));
                    newRange(2) = min(newRange(2),this.SelectorWindow(2)-eps(this.SelectorWindow(2)));
                case 'SelectedPatch'
                    switch XScale
                        case 'linear'
                            oldLeftLim = newRange(1);
                            newRange(1) = max(newRange(1),this.SelectorWindow(1)+eps(this.SelectorWindow(1)));
                            if newRange(1) > oldLeftLim
                                newRange(2) = newRange(2)+newRange(1)-oldLeftLim;
                            end
                            oldRightLim = newRange(1);
                            newRange(2) = max(newRange(2),this.SelectorWindow(2)+eps(this.SelectorWindow(2)));
                            if newRange(2) < oldRightLim
                                newRange(1) = newRange(1)+newRange(2)-oldRightLim;
                            end
                        case 'log'
                            oldLeftLim = newRange(1);
                            newRange(1) = max(newRange(1),this.SelectorWindow(1)+eps(this.SelectorWindow(1)));
                            if newRange(1) > oldLeftLim
                                newRange(2) = 10^(log10(newRange(2))+log10(newRange(1))-log10(oldLeftLim));
                            end
                            oldRightLim = newRange(2);
                            newRange(2) = min(newRange(2),this.SelectorWindow(2)-eps(this.SelectorWindow(2)));
                            if newRange(2) < oldRightLim
                                newRange(1) = 10^(log10(newRange(1))+log10(newRange(2))-log10(oldRightLim));
                            end
                    end
            end
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
            wgts = struct('SelectedPatch',this.SelectedPatch,...
                'LowerLimitLine',this.LowerLimitLine,...
                'UpperLimitLine',this.UpperLimitLine,...
                'LowerLimitKnob',this.LowerLimitKnob,...
                'UpperLimitKnob',this.UpperLimitKnob);
        end

        function qeDrag(this,source,newPoint)
            switch source
                case 'LowerLimitLine'
                    oldPoint = this.XRange(1);
                case 'UpperLimitLine'
                    oldPoint = this.XRange(2);
                case 'SelectedPatch'
                    switch this.Parent.XScale
                        case 'linear'
                            oldPoint = this.XRange(1)*0.5+this.XRange(2)*0.5;
                        case 'log'
                            oldPoint = 10^(log10(this.XRange(1))*0.5+log10(this.XRange(2))*0.5);
                    end
            end
            drag(this,source,'init',StartLocation=oldPoint,EndLocation=newPoint);
            drag(this,source,'move',StartLocation=oldPoint,EndLocation=newPoint);
            drag(this,source,'finish',StartLocation=oldPoint,EndLocation=newPoint);
        end
    end
end
