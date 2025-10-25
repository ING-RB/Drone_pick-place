classdef (Hidden = true) RRangeSelector < handle
    % RRangeSelector is a widget to add pzmap plots and shows a circular
    % patch defined by inner radius Ri and outer radius Ro where the
    % property RRange = [Ri Ro]
    %
    % Example Code:
    % h=pzplot(rss(4,1,1)); 
    % rsel=ctrluis.RRangeSelector(gca,[1.2 2]);
    % rsel.Visible = 'on';
    %
    % Author(s): Suat Gumussoy 26-Aug-2015

    %   Copyright 2009-2024 The MathWorks, Inc.
 
    %% Properties
    properties(AbortSet,Dependent,SetObservable)
        RRange
        Visible
    end

    properties(Dependent,SetObservable)
        PatchColor
        PatchAlpha
        LineColor
    end


    properties(Access = protected)
        Ts
        LowerLimitRadius
        LowerLimitKnob
        UpperLimitRadius
        UpperLimitKnob
        SelectedPatch
    end

    properties (Dependent,Access=protected)
        Figure
    end

    properties (Access=protected,Transient)
        Listeners
    end

    properties (Constant,Access=private)
        AngleGridX = cos(pi*[(0+1e-10:1/128:2) 2])
        AngleGridY = sin(pi*[(0+1e-10:1/128:2) 2])
    end

    properties(Access=private)
        RRange_I
        LineColor_I = "--mw-graphics-colorNeutral-line-secondary"
        PatchColor_I = controllib.plot.internal.utils.GraphicsColor(8).SemanticName
        PatchAlpha_I = 0.3
    end

    properties (Access=private,WeakHandle)
        Parent (1,1) matlab.graphics.axis.Axes
    end

    %% Events
    events
        SelectorMoved
    end   

    %% Constructor/destructor
    methods
        function this = RRangeSelector(Parent,RRange,Ts)
            arguments
                Parent (1,1) matlab.graphics.axis.Axes
                RRange (1,2) double {mustBeNonnegative(RRange)} = [0 1]
                Ts (1,1) double {mustBeNonnegative(Ts)} = 0
            end
            this.Parent = Parent;
            if RRange(2) < RRange(1)
                error('RRange(2) must be greater than or equal to RRange(1).');
            end
            this.RRange_I = RRange;
            this.Ts = Ts;
            if this.Ts>0 && any(RRange>pi/this.Ts)
                error('Frequency range for discrete systems is limited to [0,%g]',pi/this.Ts);
            end                        
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
                this (1,1) ctrluis.RRangeSelector
                value (1,1) matlab.lang.OnOffSwitchState
            end
            this.LowerLimitRadius.Visible = value;
            this.LowerLimitKnob.Visible = value;
            this.UpperLimitRadius.Visible = value;
            this.UpperLimitKnob.Visible = value;
            this.SelectedPatch.Visible = value;
            draw(this);
        end

        % RRange
        function value = get.RRange(this)
            value = this.RRange_I;
        end

        function set.RRange(this,value)
            arguments
                this (1,1) ctrluis.RRangeSelector
                value (1,2) double {ctrluis.RRangeSelector.mustBeRange(value)}
            end
            this.RRange_I = value;
            draw(this);
        end

        % Figure
        function fig = get.Figure(this)
            fig = ancestor(this.Parent,'Figure');
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
                this.LowerLimitRadius,"Color",Color);
            controllib.plot.internal.utils.setColorProperty(...
                this.LowerLimitKnob,"Color",Color);
            controllib.plot.internal.utils.setColorProperty(...
                this.LowerLimitKnob,"MarkerEdgeColor",Color);
            controllib.plot.internal.utils.setColorProperty(...
                this.LowerLimitKnob,"MarkerFaceColor",Color);
            controllib.plot.internal.utils.setColorProperty(...
                this.UpperLimitRadius,"Color",Color);
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
            [pX,pY] = createPatchData(this);
            this.SelectedPatch = matlab.graphics.primitive.Patch(...
                XData=pX,...
                YData=pY,...
                Parent_I=this.Parent,...
                ContextMenu=this.Parent.ContextMenu,...
                FaceAlpha=this.PatchAlpha_I,...
                EdgeAlpha=this.PatchAlpha_I,...
                Visible='off',...
                LegendDisplay='off',...
                XLimInclude='off',...
                YLimInclude='off');
            controllib.plot.internal.utils.setColorProperty(this.SelectedPatch,"FaceColor",this.PatchColor_I);
            controllib.plot.internal.utils.setColorProperty(this.SelectedPatch,"EdgeColor",this.PatchColor_I);
            this.SelectedPatch.ButtonDownFcn = @(es,ed) drag(weakThis.Handle,'SelectedPatch','init');
            
            [pXL,pYL,pXU,pYU] = createLimitRadiusData(this);
            this.LowerLimitRadius = matlab.graphics.chart.primitive.Line(...
                XData=pXL,...
                YData=pYL,...
                Parent_I=this.Parent,...
                ContextMenu=this.Parent.ContextMenu,...
                LineWidth=1,...
                LegendDisplay='off',...
                Visible='off',...
                XLimInclude='off',...
                YLimInclude='off');
            controllib.plot.internal.utils.setColorProperty(this.LowerLimitRadius,"Color",this.LineColor_I);
            this.LowerLimitRadius.ButtonDownFcn = @(es,ed) drag(weakThis.Handle,'LowerLimitRadius','init');
            this.UpperLimitRadius = matlab.graphics.chart.primitive.Line(...
                XData=pXU,...
                YData=pYU,...
                Parent_I=this.Parent,...
                ContextMenu=this.Parent.ContextMenu,...
                LineWidth=1,...
                LegendDisplay='off',...
                Visible='off',...
                XLimInclude='off',...
                YLimInclude='off');
            controllib.plot.internal.utils.setColorProperty(this.UpperLimitRadius,"Color",this.LineColor_I);
            this.UpperLimitRadius.ButtonDownFcn = @(es,ed) drag(weakThis.Handle,'UpperLimitRadius','init');

            [pL,pU] = setKnobLocations(this);
            this.LowerLimitKnob = matlab.graphics.chart.primitive.Line(...
                XData=pL(1),...
                YData=pL(2),...
                Parent_I=this.Parent,...
                ContextMenu=this.Parent.ContextMenu,...
                LineWidth=1,...
                Marker='>',...
                LegendDisplay='off',...
                Visible='off',...
                XLimInclude='off',...
                YLimInclude='off');
            controllib.plot.internal.utils.setColorProperty(this.LowerLimitKnob,"MarkerEdgeColor",this.LineColor_I);
            controllib.plot.internal.utils.setColorProperty(this.LowerLimitKnob,"MarkerFaceColor",this.LineColor_I);
            controllib.plot.internal.utils.setColorProperty(this.LowerLimitKnob,"Color",this.LineColor_I);
            this.LowerLimitKnob.ButtonDownFcn = @(es,ed) drag(weakThis.Handle,'LowerLimitRadius','init');
            this.UpperLimitKnob = matlab.graphics.chart.primitive.Line(...
                XData=pU(1),...
                YData=pU(2),...
                Parent_I=this.Parent,...
                ContextMenu=this.Parent.ContextMenu,...
                LineWidth=1,...
                Marker='<',...
                LegendDisplay='off',...
                Visible='off',...
                XLimInclude='off',...
                YLimInclude='off');
            controllib.plot.internal.utils.setColorProperty(this.UpperLimitKnob,"MarkerEdgeColor",this.LineColor_I);
            controllib.plot.internal.utils.setColorProperty(this.UpperLimitKnob,"MarkerFaceColor",this.LineColor_I);
            controllib.plot.internal.utils.setColorProperty(this.UpperLimitKnob,"Color",this.LineColor_I);
            this.UpperLimitKnob.ButtonDownFcn = @(es,ed) drag(weakThis.Handle,'UpperLimitRadius','init');

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
                end
            end
        end

        function drag(this,source,action,optionalInputs)
            arguments
                this (1,1) ctrluis.RRangeSelector
                source (1,1) string
                action (1,1) string {mustBeMember(action,["init";"move";"finish"])}
                optionalInputs.StartLocation = []
                optionalInputs.EndLocation = []
            end
            persistent WML WBMClear selectedPoint ptr

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
                        point = this.Parent.CurrentPoint;
                    else
                        point = optionalInputs.StartLocation;
                    end
                    if this.Ts>0
                        selectedPoint = atan2(point(1,2),point(1,1));
                    else
                        selectedPoint = point(1,1);
                    end
                    switch source
                        case 'SelectedPatch'
                            x = mean([min(this.SelectedPatch.XData) max(this.SelectedPatch.XData)]);
                            y = mean([min(this.SelectedPatch.YData) max(this.SelectedPatch.YData)]);
                        case 'LowerLimitRadius'
                            x = mean([min(this.LowerLimitRadius.XData) max(this.LowerLimitRadius.XData)]);
                            y = mean([min(this.LowerLimitRadius.YData) max(this.LowerLimitRadius.YData)]);
                        case 'UpperLimitRadius'
                            x = mean([min(this.UpperLimitRadius.XData) max(this.UpperLimitRadius.XData)]);
                            y = mean([min(this.UpperLimitRadius.YData) max(this.UpperLimitRadius.YData)]);
                    end
                    xdiff = point(1,1)-x;
                    ydiff = point(1,2)-y;
                    ptr = this.Figure.Pointer;
                    if (xdiff > 0 && ydiff > 0) || (xdiff < 0 && ydiff < 0) %quadrant 1 or 3
                        this.Figure.Pointer = "topr";
                    else %quadrant 2 or 4
                        this.Figure.Pointer = "topl";
                    end
                    ed = ctrluis.toolstrip.dataprocessing.GenericEventData(struct('Selector','RRange','Status','Init','Source',source,'Range',this.RRange));
                    notify(this,'SelectorMoved',ed)
                case 'move'
                    if isempty(optionalInputs.EndLocation)
                        point = this.Parent.CurrentPoint;
                    else
                        point = optionalInputs.EndLocation;
                    end
                    if this.Ts>0
                        CurrentPoint = atan2(point(1,2),point(1,1));
                    else
                        CurrentPoint = point(1,1);
                    end
                    deltaX = (CurrentPoint-selectedPoint)*sign(CurrentPoint(1));
                    if this.Ts>0
                        deltaX = deltaX*3; % multiply to speed up angle move
                    end
                    oldRange = this.RRange;
                    XScale = this.Parent.XScale;
                    switch XScale
                        case 'linear'
                            newRange = this.RRange + deltaX;
                        case 'log'
                            newRange = 10.^(log10(CurrentPoint)-log10(selectedPoint)+log10(oldRange));
                    end
                    switch source
                        case 'LowerLimitRadius'
                            newRange(1) = max(newRange(1),eps(0));
                            newRange(1) = min(newRange(1),oldRange(2));
                        case 'UpperLimitRadius'
                            if this.Ts ~= 0
                                newRange(2) = min(newRange(2),pi/abs(this.Ts)-eps(pi/abs(this.Ts)));
                            end
                            newRange(2) = max(newRange(2),oldRange(1));
                        case 'SelectedPatch'
                            newRange(1) = max(newRange(1),eps(0));
                            if this.Ts ~= 0
                                newRange(2) = min(newRange(2),pi/abs(this.Ts)-eps(pi/abs(this.Ts)));
                            end
                    end
                    switch source
                        case 'LowerLimitRadius'
                            this.RRange(1) = newRange(1);
                        case 'UpperLimitRadius'
                            this.RRange(2) = newRange(2);
                        case 'SelectedPatch'
                            this.RRange = newRange;
                    end
                    selectedPoint = CurrentPoint;
                    ed = ctrluis.toolstrip.dataprocessing.GenericEventData(struct('Selector','RRange','Status','InProgress','Source',source,'Range',this.RRange));
                    notify(this,'SelectorMoved',ed)
                case 'finish'
                    delete(WML);
                    if WBMClear
                        this.Figure.WindowButtonMotionFcn = [];
                    end
                    this.Figure.Pointer = ptr;
                    ed = ctrluis.toolstrip.dataprocessing.GenericEventData(struct('Selector','RRange','Status','Finished','Source',source,'Range',this.RRange));
                    notify(this,'SelectorMoved',ed)
            end
        end

        function draw(this)
            if this.Visible
                [pX,pY] = createPatchData(this);
                set(this.SelectedPatch, 'XData',pX,'YData',pY);
                [pXL,pYL,pXU,pYU] = createLimitRadiusData(this);
                set(this.LowerLimitRadius,'XData',pXL,'YData',pYL)
                set(this.UpperLimitRadius,'XData',pXU,'YData',pYU)
                [pL,pU] = setKnobLocations(this);
                set(this.LowerLimitKnob,'XData',pL(1),'YData',pL(2))
                set(this.UpperLimitKnob,'XData',pU(1),'YData',pU(2))
            end
        end

        function registerListeners(this,Listeners)
            this.Listeners = [this.Listeners;Listeners(:)];
        end

        function [pX,pY] = createPatchData(this)
            pX = [this.RRange(1)*this.AngleGridX, ...         % inside circle
                  this.RRange(2)*fliplr(this.AngleGridX), ... % outside circle
                 ];
            
            pY = [this.RRange(1)*this.AngleGridY, ...         % inside circle
                  this.RRange(2)*fliplr(this.AngleGridY), ... % outside circle
                 ];
            if this.Ts > 0
                [pX,pY] = ctrluis.RRangeSelector.convertToDiscreteMapping(pX,pY,this.Ts);
            end
        end

        function [pXL,pYL,pXU,pYU] = createLimitRadiusData(this)
            pXL = this.RRange(1)*this.AngleGridX;
            pYL = this.RRange(1)*this.AngleGridY;
            pXU = this.RRange(2)*this.AngleGridX;
            pYU = this.RRange(2)*this.AngleGridY;
            if this.Ts >0
                [pXL,pYL] = ctrluis.RRangeSelector.convertToDiscreteMapping(pXL,pYL,this.Ts);
                [pXU,pYU] = ctrluis.RRangeSelector.convertToDiscreteMapping(pXU,pYU,this.Ts);
            end
        end

        function [pL,pU] = setKnobLocations(this)
            if this.Ts > 0
                [pL(1),pL(2)] = ctrluis.RRangeSelector.convertToDiscreteMapping(-this.RRange(1),0,this.Ts);
                [pU(1),pU(2)] = ctrluis.RRangeSelector.convertToDiscreteMapping(-this.RRange(2),0,this.Ts);
            else
                pL = [-this.RRange(1) 0];
                pU = [-this.RRange(2) 0];
            end
        end
    end

    %% Static private methods
    methods (Static,Access=private)
        function [pX,pY] = convertToDiscreteMapping(pX,pY,Ts)
            s = exp((1j*pX+pY)*Ts);
            pX = real(s);
            pY = imag(s);
        end

        function mustBeRange(range)
            arguments
                range (1,2) double
            end
            mustBeLessThanOrEqual(range(1),range(2));
        end
    end

    %% Hidden methods
    methods (Hidden)
        function wgts = qeGetWidgets(this)
            wgts = struct('SelectedPatch',this.SelectedPatch,...
                'LowerLimitRadius',this.LowerLimitRadius,...
                'UpperLimitRadius',this.UpperLimitRadius,...
                'LowerLimitKnob',this.LowerLimitKnob,...
                'UpperLimitKnob',this.UpperLimitKnob);
        end              
    end
end


