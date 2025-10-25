classdef BodeEditorAxesView < controllib.chart.internal.view.axes.BodeAxesView
    % BodeEditorAxesView

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

    %% Constructor/destructor
    methods
        function this = BodeEditorAxesView(chart)
            arguments
                chart (1,1) controllib.chart.editor.BodeEditor
            end
            this@controllib.chart.internal.view.axes.BodeAxesView(chart);
        end

        function delete(this)
            delete(this.AxesHoveredListener);
            delete@controllib.chart.internal.view.axes.BodeAxesView(this);
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
                this (1,1) controllib.chart.editor.internal.bode.BodeEditorAxesView
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
                updateFocus@controllib.chart.internal.view.axes.BodeAxesView(this);
            end
        end
    end

    %% Protected methods
    methods (Access = protected)
        function responseView = createResponseView(this,response)
            arguments
                this (1,1) controllib.chart.editor.internal.bode.BodeEditorAxesView
                response (1,1) controllib.chart.editor.response.BodeEditorResponse
            end
            responseView = controllib.chart.editor.internal.bode.BodeEditorResponseView(response,...
                PhaseMatchingEnabled=this.PhaseMatchingEnabled,...
                PhaseWrappingEnabled=this.PhaseWrappingEnabled,...
                ColumnVisible=this.ColumnVisible(1:response.NInputs),...
                RowVisible=this.RowVisible(1:response.NOutputs),...
                FrequencyScale=this.FrequencyScale_I);
            responseView.FrequencyUnit = this.FrequencyUnit;
            responseView.MagnitudeUnit = this.MagnitudeUnit;
            responseView.PhaseUnit = this.PhaseUnit;
            responseView.FrequencyScale = this.FrequencyScale;
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
            Ts = abs(response.SourceData.Model.Ts);
            freqConversionFcn = getFrequencyUnitConversionFcn(this,this.FrequencyUnit,response.FrequencyUnit);
            fNew = freqConversionFcn(abs(newPoint(1)));
            if isa(response.SourceData.Model,'FRDModel') %FRD cannot place past data
                fNew = max(fNew,min(response.SourceData.Model.Frequency));
                fNew = min(fNew,max(response.SourceData.Model.Frequency));
            end
            if response.IsDiscrete %discrete cannot place past nyquist
                fNew = min(fNew,pi/Ts-eps(pi/Ts));
            end
            switch InteractionMode
                case "addpole"
                    curPoles = response.Compensator.P{1,1};
                    newPole = -fNew; %always assume stable
                    if response.IsDiscrete
                        newPole = exp(newPole*Ts);
                    end
                    response.Compensator.P{1,1} = [curPoles;newPole];
                    if response.IsDiscrete
                        response.Compensator.K(1,1) = response.Compensator.K(1,1)*(1-newPole(1));
                    else
                        response.Compensator.K(1,1) = -response.Compensator.K(1,1)*newPole(1);
                    end
                case "addzero"
                    curZeros = response.Compensator.Z{1,1};
                    newZero = -fNew; %always assume stable
                    if response.IsDiscrete
                        newZero = exp(newZero*Ts);
                    end
                    response.Compensator.Z{1,1} = [curZeros;newZero];
                    if response.IsDiscrete
                        response.Compensator.K(1,1) = response.Compensator.K(1,1)/(1-newZero(1));
                    else
                        response.Compensator.K(1,1) = -response.Compensator.K(1,1)/newZero(1);
                    end
                case "addccpole"
                    curPoles = response.Compensator.P{1,1};
                    isMag = getAxes(this)==ax;
                    isMag = any(isMag(1:2:end,:));
                    if isMag
                        zetaNew = getNewZeta(this.ResponseViews(this.Chart.ActiveResponseIdx),abs(newPoint(1)),newPoint(2),true);
                    else
                        zetaNew = 0.5;
                    end
                    locReal = -zetaNew*fNew; %always assume stable
                    locImag = sqrt(fNew^2-locReal^2);
                    newPole = [locReal+1j*locImag;locReal-1j*locImag];
                    if response.IsDiscrete
                        newPole = exp(newPole*Ts);
                    end
                    response.Compensator.P{1,1} = [curPoles;newPole];
                    if response.IsDiscrete
                        response.Compensator.K(1,1) = response.Compensator.K(1,1)*abs(1-newPole(1))^2;
                    else
                        response.Compensator.K(1,1) = response.Compensator.K(1,1)*abs(newPole(1))^2;
                    end
                case "addcczero"
                    curZeros = response.Compensator.Z{1,1};
                    isMag = getAxes(this)==ax;
                    isMag = any(isMag(1:2:end,:));
                    if isMag
                        zetaNew = getNewZeta(this.ResponseViews(this.Chart.ActiveResponseIdx),abs(newPoint(1)),newPoint(2),false);
                    else
                        zetaNew = 0.5;
                    end
                    locReal = -zetaNew*fNew; %always assume stable
                    locImag = sqrt(fNew^2-locReal^2);
                    newZero = [locReal+1j*locImag;locReal-1j*locImag];
                    if response.IsDiscrete
                        newZero = exp(newZero*Ts);
                    end
                    response.Compensator.Z{1,1} = [curZeros;newZero];
                    if response.IsDiscrete
                        response.Compensator.K(1,1) = response.Compensator.K(1,1)/abs(1-newZero(1))^2;
                    else
                        response.Compensator.K(1,1) = response.Compensator.K(1,1)/abs(newZero(1))^2;
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
        function qeDrag(this,type,respIdx,startLoc,endLoc,axType)
            arguments
                this (1,1) controllib.chart.editor.internal.bode.BodeEditorAxesView
                type (1,1) string {mustBeMember(type,["gain";"zero";"pole";"complexConjugateZero";"complexConjugatePole"])}
                respIdx (1,1) double {mustBePositive,mustBeInteger}
                startLoc (1,2) double
                endLoc (1,2) double
                axType (1,1) string {mustBeMember(axType,["Magnitude";"Phase"])}
            end
            qeDrag(this.ResponseViews(respIdx),type,startLoc,endLoc,axType);
        end
    end
end