classdef BodeEditor < controllib.chart.BodePlot & controllib.chart.editor.internal.mixin.MixInEditorInteractions
    % BodeEditor

    % Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (Hidden,Dependent,AbortSet,SetObservable)
        ActiveResponseIdx
    end

    properties (Access=private,Transient,NonCopyable)
        ActiveResponseIdx_I = 1
    end

    %% Events
    events        
        CompensatorChanged
    end

    %% Constructor
    methods
        function this = BodeEditor(bodePlotInputs,abstractPlotArguments)
            arguments
                bodePlotInputs.Options (1,1) plotopts.BodeOptions = controllib.chart.editor.BodeEditor.createDefaultOptions();
                abstractPlotArguments.?controllib.chart.internal.foundation.AbstractPlotOptionalInputs
            end
            % Extract name-value inputs for AbstractPlot
            abstractPlotArguments = namedargs2cell(abstractPlotArguments);
            this@controllib.chart.BodePlot(abstractPlotArguments{:},Options=bodePlotInputs.Options);
        end
    end

    %% Get/Set
    methods
        % ActiveResponseIdx
        function ActiveResponseIdx = get.ActiveResponseIdx(this)
            ActiveResponseIdx = this.ActiveResponseIdx_I;
        end

        function set.ActiveResponseIdx(this,ActiveResponseIdx)
            arguments
                this (1,1) controllib.chart.editor.BodeEditor
                ActiveResponseIdx (1,1) double {mustBeNonnegative,mustBeInteger}
            end
            this.ActiveResponseIdx_I = ActiveResponseIdx;
        end
    end

    %% Public methods
    methods
        function addResponse(this,fixedPlant,compensator,optionalInputs,optionalStyleInputs)
            % addResponse adds the bode response to the chart
            %
            %   addResponse(h,sys)
            %       adds the bode responses of "sys"to the chart "h"
            %
            %   addResponse(h,sys,w)
            %       w               [] (default) | vector | cell array
            %
            %   addResponse(h,______,Name-Value)
            %       Name            "untitled1" (default) | scalar | vector
            %       LineStyle       "-" (default) | "--" | ":" | "-." | "none"
            %       Color           [0 0.4470 0.7410] (default) | RGB triplet | hexadecimal color code | "r" | "g" | "b" | ... 
            %       MarkerStyle     "none" (default) | "o" | "+" | "*" | "." | ...
            %       LineWidth       0.5 (default) | positive value

            arguments
                this (1,1) controllib.chart.editor.BodeEditor
                fixedPlant DynamicSystem
                compensator zpk
                optionalInputs.Name (1,1) string = ""
                optionalStyleInputs.?controllib.chart.internal.options.AddResponseStyleOptionalInputs
            end

            % Define Name
            if strcmp(optionalInputs.Name,"")
                optionalInputs.Name = string(inputname(2));
            end

            % Get next style and name
            if isempty(optionalInputs.Name) || strcmp(optionalInputs.Name,"")
                name = getNextSystemName(this);
            else
                name = optionalInputs.Name;
            end

            % Create BodeEditorResponse
            newResponse = createResponse_(this,fixedPlant,compensator,name);
            if ~isempty(newResponse.DataException) && ~strcmp(this.ResponseDataExceptionMessage,"none")
                if strcmp(this.ResponseDataExceptionMessage,"error")
                    throw(newResponse.DataException);
                else % warning
                    warning(newResponse.DataException.identifier,newResponse.DataException.message);
                end
            end

            % Apply user specified style values to style object
            controllib.chart.internal.options.AddResponseStyleOptionalInputs.applyToStyle(...
                newResponse.Style,optionalStyleInputs);

            registerResponse(this,newResponse);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function initialize(this)
            initialize@controllib.chart.BodePlot(this);
            this.Type = 'bodeeditor';
            setCharacteristicVisibility(this,"CompensatorZeros",Visible=true);
            setCharacteristicVisibility(this,"CompensatorPoles",Visible=true);
            setCharacteristicVisibility(this,"CompensatorComplexConjugateZeros",Visible=true);
            setCharacteristicVisibility(this,"CompensatorComplexConjugatePoles",Visible=true);
        end

        function setup(this)
            setup@controllib.chart.BodePlot(this);
            setup@controllib.chart.editor.internal.mixin.MixInEditorInteractions(this);
        end

        function update(this)
            update@controllib.chart.BodePlot(this);
            update@controllib.chart.editor.internal.mixin.MixInEditorInteractions(this);
            if ~isempty(this.View) && isvalid(this.View)
                this.View.InteractionMode = this.InteractionMode;
            end
        end

        function response = createResponse_(~,plant,comp,name)
            response = controllib.chart.editor.response.BodeEditorResponse(plant,comp,...
                Name=name);
        end

        function view = createView_(this)
            % Create View
            view = controllib.chart.editor.internal.bode.BodeEditorAxesView(this);
            weakThis = matlab.lang.WeakReference(this);
            L = addlistener(view,"CompensatorChanged",@(es,ed) cbCompensatorChanged(weakThis.Handle,ed));
            registerListeners(this,L,"CompensatorChangedListener");
            initializeToolbar(this,view.Toolbar);
        end

        function cbCompensatorChanged(this,ed)
            ed = controllib.chart.internal.utils.GenericEventData(ed.Data);
            notify(this,"CompensatorChanged",ed);
        end

        function cm = createCharacteristicOptions_(this,charType)
            switch charType
                case {"CompensatorZeros","CompensatorPoles","CompensatorComplexConjugateZeros","CompensatorComplexConjugatePoles"}
                    cm = [];
                otherwise
                    cm = createCharacteristicOptions_@controllib.chart.BodePlot(this,charType);
            end
        end

        function buildUnitsWidget(this)
            % Create UnitsContainer
            this.UnitsWidget = controllib.widget.internal.cstprefs.UnitsContainer('FrequencyUnits',...
                'MagnitudeUnits','PhaseUnits','MagnitudeScale');
            % Remove 'auto' from frequency unit list
            this.UnitsWidget.ValidFrequencyUnits(1,:) = [];

            this.UnitsWidget.FrequencyUnits = this.FrequencyUnit;
            this.UnitsWidget.MagnitudeUnits = this.MagnitudeUnit;
            this.UnitsWidget.PhaseUnits = this.PhaseUnit;
            this.UnitsWidget.MagnitudeScale = this.MagnitudeScale;

            % Add listeners for widget to data
            L = [addlistener(this.UnitsWidget,'FrequencyUnits','PostSet',...
                @(es,ed) cbFrequencyUnitChangedInPropertyEditor(this,ed)),...
                addlistener(this.UnitsWidget,'MagnitudeUnits','PostSet',...
                @(es,ed) cbMagnitudeUnitChangedInPropertyEditor(this,ed)),...
                addlistener(this.UnitsWidget,'MagnitudeScale','PostSet',...
                @(es,ed) cbMagnitudeScaleChangedInPropertyEditor(this,ed)),...
                addlistener(this.UnitsWidget,'PhaseUnits','PostSet',...
                @(es,ed) cbPhaseUnitChangedInPropertyEditor(this,ed))];
            registerListeners(this,L,["FrequencyUnitChangedInPropertEditor",...
                "MagnitudeUnitChangedInPropertyEditor","MagnitudeScaleChangedInPropertyEditor",...
                "PhaseUnitChangedInPropertyEditor"]);

            % Local callback functions
            function cbFrequencyUnitChangedInPropertyEditor(this,ed)
                this.FrequencyUnit = ed.AffectedObject.FrequencyUnits;
            end

            function cbMagnitudeUnitChangedInPropertyEditor(this,ed)
                this.MagnitudeUnit = ed.AffectedObject.MagnitudeUnits;
            end

            function cbMagnitudeScaleChangedInPropertyEditor(this,ed)
                this.MagnitudeScale = ed.AffectedObject.MagnitudeScale;
            end

            function cbPhaseUnitChangedInPropertyEditor(this,ed)
                this.PhaseUnit = ed.AffectedObject.PhaseUnits;
            end
        end
    end

    %% Static hidden methods
    methods (Static,Hidden)
        function options = createDefaultOptions()
            options = bodeoptions('cstprefs');
            options.Title.String = getString(message('Controllib:plots:strBodeEditor'));
        end
    end

    %% Hidden methods
    methods (Hidden)
        function qeDrag(this,type,startLoc,endLoc,axType)
            arguments
                this (1,1) controllib.chart.editor.BodeEditor
                type (1,1) string {mustBeMember(type,["gain";"zero";"pole";"complexConjugateZero";"complexConjugatePole"])}
                startLoc (1,2) double
                endLoc (1,2) double
                axType (1,1) string {mustBeMember(axType,["Magnitude";"Phase"])}
            end
            qeDrag(this.View,type,this.ActiveResponseIdx,startLoc,endLoc,axType);
        end
    end
end