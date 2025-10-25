classdef RootLocusEditorAxesView < controllib.chart.internal.view.axes.RootLocusAxesView
    % RootLocusEditorAxesView

    % Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent,AbortSet,SetObservable)
        InteractionMode
    end

    properties (Access=private,Transient,NonCopyable)
        IsCompensatorChanging = false
        InteractionMode_I = "default"
        AxesHoveredListener
        SavedCursor
    end

    %% Events
    events
        CompensatorChanged
    end

    %% Constructor
    methods
        function this = RootLocusEditorAxesView(chart)
            arguments
                chart (1,1) controllib.chart.editor.RLocusEditor
            end
            this@controllib.chart.internal.view.axes.RootLocusAxesView(chart);
        end
    end

    %% Get/Set
    methods
        % InteractionMode
        function InteractionMode = get.InteractionMode(this)
            InteractionMode = this.InteractionMode_I;
        end
        
        function set.InteractionMode(this,InteractionMode)
            arguments
                this (1,1) controllib.chart.editor.internal.rlocus.RootLocusEditorAxesView
                InteractionMode (1,1) string {mustBeMember(InteractionMode,["default","addpole","addzero","addccpole","addcczero","removepz"])}
            end
            for ii = 1:length(this.ResponseViews)
                this.ResponseViews(ii).InteractionMode = InteractionMode;
            end
            ax = getAxes(this);
            switch InteractionMode
                case "default"
                    set(ax,ButtonDownFcn=[]);
                    delete(this.AxesHoveredListener);
                    if ~isempty(this.SavedCursor)
                        fig = ancestor(this.Chart,'figure');
                        fig.Pointer = this.SavedCursor.Pointer;
                        fig.PointerShapeCData = this.SavedCursor.PointerShapeCData;
                        fig.PointerShapeHotSpot = this.SavedCursor.PointerShapeHotSpot;
                        this.SavedCursor = [];
                    end
                otherwise
                    weakThis = matlab.lang.WeakReference(this);
                    set(ax,ButtonDownFcn=@(es,ed) doInteraction(weakThis.Handle,es,InteractionMode));
                    fig = ancestor(this.Chart,'figure');
                    if ~isempty(this.SavedCursor)
                        fig = ancestor(this.Chart,'figure');
                        fig.Pointer = this.SavedCursor.Pointer;
                        fig.PointerShapeCData = this.SavedCursor.PointerShapeCData;
                        fig.PointerShapeHotSpot = this.SavedCursor.PointerShapeHotSpot;
                        this.SavedCursor = [];
                    end
                    delete(this.AxesHoveredListener)
                    this.AxesHoveredListener = addlistener(fig,'WindowMouseMotion',@(es,ed) setInteractionCursor(weakThis.Handle,InteractionMode,ed));
            end
            this.InteractionMode_I = InteractionMode;
        end
    end

    %% Public methods
    methods
        function updateFocus(this)
            if ~this.IsCompensatorChanging
                updateFocus@controllib.chart.internal.view.axes.RootLocusAxesView(this);
            end
        end
    end

    %% Protected methods
    methods (Access = protected)
        function responseView = createResponseView(this,response)
            arguments
                this (1,1) controllib.chart.editor.internal.rlocus.RootLocusEditorAxesView
                response (1,1) controllib.chart.editor.response.RootLocusEditorResponse
            end
            responseView = controllib.chart.editor.internal.rlocus.RootLocusEditorResponseView(response);
            responseView.FrequencyUnit = this.FrequencyUnit;
            responseView.TimeUnit = this.TimeUnit;
            responseView.InteractionMode = this.InteractionMode;
            weakThis = matlab.lang.WeakReference(this);
            L = addlistener(responseView,"CompensatorChanged",@(es,ed) cbCompensatorChanged(weakThis.Handle,es,ed));
            registerListeners(this,L,"CompensatorChangedListeners");
        end    

        function doInteraction(this,ax,InteractionMode)
            if InteractionMode == "removepz" %handled in response views
                return;
            end
            fig = ancestor(ax,'figure');
            if ~strcmp(fig.SelectionType,"normal")
                return;
            end
            newPoint = ax.CurrentPoint(1,1:2);
            response = this.Chart.Responses(this.Chart.ActiveResponseIdx);
            timeConversionFcn = getTimeUnitConversionFcn(this,response.TimeUnit,this.TimeUnit);
            re = 1/timeConversionFcn(1/newPoint(1));
            im = max(abs(1/timeConversionFcn(1/newPoint(2))),eps);
            switch InteractionMode
                case "addpole"
                    curPoles = response.Compensator.P{1,1};
                    newPole = re;
                    response.Compensator.P{1,1} = [curPoles;newPole];
                    if response.IsDiscrete
                        if newPole ~= 1
                            response.Compensator.K(1,1) = response.Compensator.K(1,1)*(1-newPole);
                        end
                    else
                        if newPole ~= 0
                            response.Compensator.K(1,1) = -response.Compensator.K(1,1)*newPole;
                        end
                    end
                case "addzero"
                    curZeros = response.Compensator.Z{1,1};
                    newZero = re;
                    response.Compensator.Z{1,1} = [curZeros;newZero];
                    if response.IsDiscrete
                        if newZero ~= 1
                            response.Compensator.K(1,1) = response.Compensator.K(1,1)/(1-newZero);
                        end
                    else
                        if newZero ~= 0
                            response.Compensator.K(1,1) = -response.Compensator.K(1,1)/newZero;
                        end
                    end
                case "addccpole"
                    curPoles = response.Compensator.P{1,1};
                    newPole = [re+im*1j;re-im*1j];
                    response.Compensator.P{1,1} = [curPoles;newPole];
                    if response.IsDiscrete
                        if abs(newPole(1)) ~= 1
                            response.Compensator.K(1,1) = response.Compensator.K(1,1)*abs(1-newPole(1))^2;
                        end
                    else
                        if abs(newPole(1)) ~= 0
                            response.Compensator.K(1,1) = response.Compensator.K(1,1)*abs(newPole(1))^2;
                        end
                    end
                case "addcczero"
                    curZeros = response.Compensator.Z{1,1};
                    newZero = [re+im*1j;re-im*1j];
                    response.Compensator.Z{1,1} = [curZeros;newZero];
                    if response.IsDiscrete
                        if abs(newZero(1)) ~= 1
                            response.Compensator.K(1,1) = response.Compensator.K(1,1)/abs(1-newZero(1))^2;
                        end
                    else
                        if abs(newZero(1)) ~= 0
                            response.Compensator.K(1,1) = response.Compensator.K(1,1)/abs(newZero(1))^2;
                        end
                    end
            end
            Data.ResponseIdx = this.Chart.ActiveResponseIdx;
            Data.Status = 'Finished';
            ed = controllib.chart.internal.utils.GenericEventData(Data);
            notify(this,"CompensatorChanged",ed);
        end

        function setInteractionCursor(this,InteractionMode,ed)
            fig = ancestor(this.Chart,'figure');
            if isempty(fig)
                return;
            end
            ax = ancestor(ed.HitObject,'axes');
            if ~isempty(ax) && ismember(ax,getAxes(this)) && ~strcmp(ed.HitObject.Type,'text')
                if isempty(this.SavedCursor)
                    this.SavedCursor.Pointer = fig.Pointer;
                    this.SavedCursor.PointerShapeCData = fig.PointerShapeCData;
                    this.SavedCursor.PointerShapeHotSpot = fig.PointerShapeHotSpot;
                end
                switch InteractionMode
                    case {'addpole','addccpole'}
                        setptr(fig,'addpole')
                    case {'addzero','addcczero'}
                        setptr(fig,'addzero')
                    case 'removepz'
                        setptr(fig,'eraser')
                end
            else
                if ~isempty(this.SavedCursor)
                    fig.Pointer = this.SavedCursor.Pointer;
                    fig.PointerShapeCData = this.SavedCursor.PointerShapeCData;
                    fig.PointerShapeHotSpot = this.SavedCursor.PointerShapeHotSpot;
                    this.SavedCursor = [];
                end
            end
        end    
    end

    %% Private methods
    methods (Access=private)
        function cbCompensatorChanged(this,es,ed)
            switch ed.Data.Status
                case {"Init","InProgress"}
                    this.IsCompensatorChanging = true;
                case "Finished"
                    this.IsCompensatorChanging = false;
                    updateFocus(this);
            end
            idx = find(es==this.ResponseViews,1);
            Data = ed.Data;
            Data.ResponseIdx = idx;
            ed = controllib.chart.internal.utils.GenericEventData(Data);
            notify(this,"CompensatorChanged",ed);
        end
    end

    %% Hidden methods
    methods (Hidden)
        function qeDrag(this,type,respIdx,startLoc,endLoc)
            arguments
                this (1,1) controllib.chart.editor.internal.rlocus.RootLocusEditorAxesView
                type (1,1) string {mustBeMember(type,["gain";"zero";"pole";"complexConjugateZero";"complexConjugatePole"])}
                respIdx (1,1) double {mustBePositive,mustBeInteger}
                startLoc (1,2) double
                endLoc (1,2) double
            end
            qeDrag(this.ResponseViews(respIdx),type,startLoc,endLoc);
        end
    end
end