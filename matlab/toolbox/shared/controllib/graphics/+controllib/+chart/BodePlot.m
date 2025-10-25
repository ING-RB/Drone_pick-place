classdef BodePlot < controllib.chart.internal.foundation.MagnitudePhaseFrequencyPlot & ...
                    controllib.chart.internal.foundation.MixInInputOutputPlot
    % BodePlot

    % Copyright 2021-2024 The MathWorks, Inc.

    %% Properties
    properties (Access = protected,Transient,NonCopyable)
        NormalizeMenu

        SpecifyFrequencyDialog
        SpecifyFrequencyMenu
    end

    % Removed: MagnitudeLimitsEqual, PhaseLimitsEqual

    %% Events
    events
        FrequencyChanged
    end

    %% Constructor/destructor
    methods
        function this = BodePlot(bodePlotInputs,inputOutputPlotArguments)
            arguments
                bodePlotInputs.Options (1,1) plotopts.BodeOptions = controllib.chart.BodePlot.createDefaultOptions();
                inputOutputPlotArguments.?controllib.chart.internal.foundation.AbstractPlotOptionalInputs
            end
            % Extract name-value inputs for AbstractPlot
            inputOutputPlotArguments = namedargs2cell(inputOutputPlotArguments);
            this@controllib.chart.internal.foundation.MagnitudePhaseFrequencyPlot(inputOutputPlotArguments{:},...
                Options=bodePlotInputs.Options);
        end

        function delete(this)
            delete@controllib.chart.internal.foundation.MagnitudePhaseFrequencyPlot(this);
            delete(this.SpecifyFrequencyDialog);
        end
    end

    %% Public methods
    methods
        function addResponse(this,model,frequency,optionalInputs,optionalStyleInputs)
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
                this (1,1) controllib.chart.BodePlot
                model DynamicSystem
                frequency = []
                optionalInputs.Name (1,1) string = ""
                optionalStyleInputs.?controllib.chart.internal.options.AddResponseStyleOptionalInputs
            end

            % Define Name
            if strcmp(optionalInputs.Name,"")
                optionalInputs.Name = string(inputname(2));
            end

            % Create BodeResponse
            % Get next style and name
            if isempty(optionalInputs.Name) || strcmp(optionalInputs.Name,"")
                name = getNextSystemName(this);
            else
                name = optionalInputs.Name;
            end

            % Create BodeResponse
            newResponse = createResponse_(this,model,name,frequency);
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
            initialize@controllib.chart.internal.foundation.MagnitudePhaseFrequencyPlot(this);
            this.Type = 'bode';
        end

        function response = createResponse_(~,model,name,freq)
            response = controllib.chart.response.BodeResponse(model,...
                Name=name,...
                Frequency=freq);
        end

        function view = createView_(this)
            % Create View
            view = controllib.chart.internal.view.axes.BodeAxesView(this);
        end

        %% Context menu
        function createContextMenu(this)
            createContextMenu@controllib.chart.internal.foundation.MagnitudePhaseFrequencyPlot(this);

            this.SpecifyFrequencyMenu = uimenu(Parent=[],...
                Text=[getString(message('Controllib:plots:strSpecifyFrequency')),'...'],...
                Tag="specifyfrequency",...
                Separator='on',...
                MenuSelectedFcn=@(es,ed) openSpecifyFrequencyDialog(this));
            addMenu(this,this.SpecifyFrequencyMenu,Above='propertyeditor',CreateNewSection=false);
        end        

        function [tags,labels] = getCharacteristicTagsToShowInArraySelector(this)
            tags = "BodePeakResponse";
            labels = string(getString(message('Controllib:plots:strPeakResponse')));

            if this.NInputs == 1 && this.NOutputs == 1
                tags = [tags,"GainMargin","PhaseMargin"];
                labels = [labels, string(getString(message('Controllib:plots:strGainMargin'))),...
                            string(getString(message('Controllib:plots:strPhaseMargin')))];
            end
        end

        function updateArrayVisibilityUsingCharacteristicBounds(this)
            idx = find([this.Responses.Name]==this.ArraySelectorDialog.SelectedSystem);
            response = this.Responses(idx);
            data = response.ResponseData;

            arrayVisible = false(size(this.Responses(idx).ArrayVisible));
            magConversionFcn = controllib.chart.internal.utils.getMagnitudeUnitConversionFcn(response.MagnitudeUnit,...
                this.MagnitudeUnit);
            phaseConversionFcn = controllib.chart.internal.utils.getPhaseUnitConversionFcn(response.PhaseUnit,...
                this.PhaseUnit);
            for ka = 1:response.NResponses
                compute(data.BodePeakResponse);
                if ~isempty(data.MinimumStabilityMargin)
                    compute(data.MinimumStabilityMargin);
                end
                
                isPeakResponseWithinBounds = isCharacteristicWithinBounds(this.ArraySelectorDialog,...
                    "BodePeakResponse",magConversionFcn(data.BodePeakResponse.Magnitude{ka}));
                isGainMarginWithinBounds = isCharacteristicWithinBounds(this.ArraySelectorDialog,...
                    "GainMargin",magConversionFcn(data.MinimumStabilityMargin.GainMargin{ka}));
                isPhaseMarginWithinBounds = isCharacteristicWithinBounds(this.ArraySelectorDialog,...
                    "PhaseMargin",phaseConversionFcn(data.MinimumStabilityMargin.PhaseMargin{ka}));

                arrayVisible(ka) = all(isPeakResponseWithinBounds(:) & ...
                                       isGainMarginWithinBounds(:) & ...
                                       isPhaseMarginWithinBounds(:));
            end
            response.ArrayVisible = arrayVisible;
        end

        function openSpecifyFrequencyDialog(this)
            if any(arrayfun(@(x) issparse(x.Model),this.Responses))
                enableAuto = false;
                enableFrequencyRange = false;
                enableVector = true;
            else
                enableAuto = true;
                enableFrequencyRange = true;
                enableVector = true;
            end
            if isempty(this.SpecifyFrequencyDialog) || ~isvalid(this.SpecifyFrequencyDialog)
                if isempty(this.Responses)
                    f = [];
                else
                    f = this.Responses(end).SourceData.FrequencySpec;
                end
                this.SpecifyFrequencyDialog = controllib.chart.internal.widget.FrequencyEditorDialog(...
                    EnableAuto=enableAuto,EnableRange=enableFrequencyRange,EnableVector=enableVector,...
                    Frequency=f,FrequencyUnits=this.FrequencyUnit);
                this.SpecifyFrequencyDialog.FrequencyChangedFcn = @(es,ed) cbFrequencyChanged(this,ed);
            end
            this.SpecifyFrequencyDialog.EnableAuto = enableAuto;
            this.SpecifyFrequencyDialog.EnableRange = enableFrequencyRange;            
            show(this.SpecifyFrequencyDialog);

            function cbFrequencyChanged(this,ed)
                for k = 1:length(this.Responses)
                    if ~isempty(ed.Data.Frequency)
                        cf = controllib.chart.internal.utils.getFrequencyUnitConversionFcn(...
                            ed.Data.FrequencyUnits,this.Responses(k).FrequencyUnit);
                        if iscell(ed.Data.Frequency)
                            this.Responses(k).SourceData.FrequencySpec = {cf(ed.Data.Frequency{1}), cf(ed.Data.Frequency{2})};
                        else
                            this.Responses(k).SourceData.FrequencySpec = cf(ed.Data.Frequency);
                        end
                    else
                        this.Responses(k).SourceData.FrequencySpec = ed.Data.Frequency;
                    end
                end
                ev = controllib.chart.internal.utils.GenericEventData(ed.Data.Frequency);
                notify(this,'FrequencyChanged',ev);
            end
        end
        function updateFocusWithRequirementsExtent(this,currentXLimitsFocus,currentYLimitsFocus,requirementsExtent)
            % Update XLimitsFocus
            xLimitsFocus = [min(currentXLimitsFocus{1}(1),requirementsExtent(1)),...
                max(currentXLimitsFocus{1}(2),requirementsExtent(2))];
            this.View.XLimitsFocus{1} = xLimitsFocus;
            this.View.XLimitsFocus{2} = xLimitsFocus;

            % Update YLimitsFocus

            yLimitsFocus = [min(currentYLimitsFocus{1}(1),requirementsExtent(3)),...
                max(currentYLimitsFocus{1}(2),requirementsExtent(4))];
            this.View.YLimitsFocus{1} = yLimitsFocus;
        end
    end

    %% Static protected methods
    methods (Static,Access=protected)
        function sz = getPropertyDialogSize()
            sz = [430 410];
        end
    end

    %% Static hidden methods
    methods (Static,Hidden)
        function options = createDefaultOptions()
            options = bodeoptions('cstprefs');
        end
    end

    %% Hidden methods
    methods (Hidden)
        function addMarginSubtitle(this)
            try %#ok<TRYNC>
                unregisterListeners(this,["MarginFrequencyUnitListener";...
                    "MarginMagnitudeUnitListener";...
                    "MarginPhaseUnitListener";...
                    "MarginResponseChangedListener"])
            end
            response = this.Responses(end);
            L1 = addlistener(this,'FrequencyUnit','PostSet',@(es,ed) updateMarginLabel(this,response));
            L2 = addlistener(this,'MagnitudeUnit','PostSet',@(es,ed) updateMarginLabel(this,response));
            L3 = addlistener(this,'PhaseUnit','PostSet',@(es,ed) updateMarginLabel(this,response));
            L4 = addlistener(response,'ResponseChanged',@(es,ed) updateMarginLabel(this,response));
            registerListeners(this,[L1;L2;L3;L4],["MarginFrequencyUnitListener";...
                "MarginMagnitudeUnitListener";...
                "MarginPhaseUnitListener";...
                "MarginResponseChangedListener"])

            updateMarginLabel(this,response);

            function updateMarginLabel(this,response)
                if isvalid(response) && issiso(response.SourceData.Model)
                    m = response.ResponseData.MinimumStabilityMargin;
                    frequencyConversionFcn = controllib.chart.internal.utils.getFrequencyUnitConversionFcn(...
                        response.FrequencyUnit,this.FrequencyUnit);
                    magnitudeConversionFcn = controllib.chart.internal.utils.getMagnitudeUnitConversionFcn(...
                        "abs",this.MagnitudeUnit);
                    phaseConversionFcn = controllib.chart.internal.utils.getPhaseUnitConversionFcn(...
                        "deg",this.PhaseUnit);
                    GM = magnitudeConversionFcn(m.GainMargin{1});
                    wGM = frequencyConversionFcn(m.GMFrequency{1});
                    if isfinite(GM)
                        MagTxt = sprintf('Gm = %0.3g %s (at %0.3g %s)',GM,this.MagnitudeUnit,wGM,this.FrequencyUnit);
                    else
                        MagTxt = 'Gm = Inf';
                    end
                    PM = phaseConversionFcn(m.PhaseMargin{1});
                    wPM = frequencyConversionFcn(m.PMFrequency{1});
                    if isfinite(PM)
                        PhaseTxt = sprintf('Pm = %0.3g %s (at %0.3g %s)',PM,this.PhaseUnit,wPM,this.FrequencyUnit);
                    else
                        PhaseTxt = 'Pm = Inf';
                    end
                    subtitle(this,sprintf('%s,  %s',MagTxt,PhaseTxt));
                end
            end
        end
        
        function list = getRequirementList(this) %#ok<MANU>
            list.Type = 'UpperGainLimit';
            list.Label = getString(message('Controllib:graphicalrequirements:lblUpperGainLimit'));
            list.Class = 'editconstr.BodeGain';
            list.DataClass = 'srorequirement.bodegain';

            list(2).Type = 'LowerGainLimit';
            list(2).Label = getString(message('Controllib:graphicalrequirements:lblLowerGainLimit'));
            list(2).Class = 'editconstr.BodeGain';
            list(2).DataClass = 'srorequirement.bodegain';

            list(3).Type = 'GPMargins';
            list(3).Label = getString(message('Controllib:graphicalrequirements:lblGainPhaseMargins'));
            list(3).Class = 'editconstr.GainPhaseMargin';
            list(3).DataClass = 'srorequirement.gainphasemargin';
         end

        function newConstraint = getNewConstraint(this,type,currentConstraint)
            list = getRequirementList(this);
            type = localCheckType(type,list);
            typeIdx = strcmp(type,{list.Type});
            constraintClass = list(typeIdx).Class;
            dataClass = list(typeIdx).DataClass;

            % Create instance
            switch type
                case 'UpperGainLimit'
                    constraintType = 'upper';
                    xUnits = this.FrequencyUnit;
                    yUnits = this.MagnitudeUnit;
                case 'LowerGainLimit'
                    constraintType = 'lower';
                    xUnits = this.FrequencyUnit;
                    yUnits = this.MagnitudeUnit;
                case 'GPMargins'
                    constraintType = 'both';
                    yUnits = this.MagnitudeUnit;  %Magnitude
                    xUnits = this.PhaseUnit;  %Phase
            end

            % Create instance
            if nargin > 2 && isa(currentConstraint,constraintClass)
                % Use current constraint and update type
                newConstraint = currentConstraint;
                newConstraint.Requirement.setData('type',constraintType);
            else
                % Create new constraint
                requirementData = feval(dataClass);
                requirementData.setData('type',constraintType);
                newConstraint = feval(constraintClass,requirementData);
                newConstraint.setDisplayUnits('xunits',char(xUnits));
                newConstraint.setDisplayUnits('yunits',char(yUnits));
            end

            %Special initialization for bode gain constr
            if strcmp(constraintClass,'editconstr.BodeGain')
                % Set sample time and units
                newConstraint.Ts = this.Responses(1).Model.Ts;
                % Make sure constraint is below Nyquist freq.
                if newConstraint.Ts
                    newConstraint.Requirement.setData('xData',(pi/Constr.Ts) * [0.01 0.1]);
                end
            end

            function kOut = localCheckType(kIn,list)
                %Helper function to check keyword is correct, mainly needed for backwards
                %compatibility with old saved constraints

                if any(strcmp(kIn,{list.Type}))
                    %Quick return is already an identifier
                    kOut = kIn;
                    return
                end

                %Now check display strings for matching keyword, may need to translate kIn
                %from an earlier saved version
                strEng = {...
                    'Upper gain limit'; ...
                    'Lower gain limit'; ...
                    'Gain & Phase margins'};
                strTr = {list.Label};
                idx = strcmp(kIn,strTr) | strcmp(kIn,strEng);
                if any(idx)
                    kOut = list(idx).Type;
                else
                    kOut = [];
                end
            end
        end

        function openPropertyDialog(this)
            openPropertyDialog@controllib.chart.internal.foundation.MagnitudePhaseFrequencyPlot(this);
            this.ConfidenceRegionWidget.Visible = any(arrayfun(@(x) isprop(x,'NumberOfStandardDeviations'),this.Responses));
        end
    
        function widgets = qeGetPropertyEditorWidgets(this)
            widgets = qeGetPropertyEditorWidgets@controllib.chart.internal.foundation.MagnitudePhaseFrequencyPlot(this);
            widgets.MagnitudeResponseWidget = this.MagnitudeResponseWidget;
            widgets.PhaseResponseWidget = this.PhaseResponseWidget;
            widgets.ConfidenceRegionWidget = this.ConfidenceRegionWidget;
        end

        function dlg = qeGetSpecifyFrequencyDialog(this)
            openSpecifyFrequencyDialog(this);
            dlg = this.SpecifyFrequencyDialog;
        end

        function sz = getYLimitsSize(this)
            columnVisible = this.ColumnVisible;
            switch this.YLimitsSharing
                case "all"
                    sz = [this.MagnitudeVisible+this.PhaseVisible any(columnVisible)];
                case "row"
                    sz = getVisibleAxesSize(this);
                    sz = [sz(1) any(columnVisible)];
                case "none"
                    sz = getVisibleAxesSize(this);
            end
            sz = double(sz);
        end
    end
end