classdef PZPlot < controllib.chart.internal.foundation.AbstractPlot
    % Construct a StepPlot.
    %
    % h = controllib.chart.StepPlot("SystemModels",{rss(3,2,2),rss(3,2,2)},"SystemNames",["G","H"],"Axes",gca);
    % h = controllib.chart.StepPlot("SystemModels",{rss(3,2,2)},"SystemNames","G","Parent",gcf);
    % h = controllib.chart.StepPlot("NInputs",2,"NOutputs",2,"InputLabels",["u1","u2"],"OutputLabels",["y1","y2"]);
    % h = controllib.chart.StepPlot("NInputs",2,"NOutputs",2);
    %
    %   Example:
    %
    %   sysG = rss(3,2,2);
    %   sysH = rss(3,2,2);
    %   f = figure;
    %   ax = axes(f);
    %   ax.Position = [0.1 0.1 0.5 0.5];
    %   h = controllib.chart.PZPlot("SystemModels",{sysG,sysH},"SystemNames",["G","H"],"Axes",ax);

    %   Copyright 2021-2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent, AbortSet, SetObservable)
        TimeUnit
        FrequencyUnit    
    end

    properties (GetAccess=protected,SetAccess=private)
        TimeUnit_I = "seconds"
        FrequencyUnit_I = "rad/s"
    end

    %% Constructor/destructor
    methods
        function this = PZPlot(pzPlotInputs,abstractPlotArguments)
            arguments
                pzPlotInputs.Options (1,1) plotopts.PZOptions = controllib.chart.PZPlot.createDefaultOptions()
                abstractPlotArguments.?controllib.chart.internal.foundation.AbstractPlotOptionalInputs
            end 
            % Extract name-value inputs for AbstractPlot
            abstractPlotArguments = namedargs2cell(abstractPlotArguments);
            this@controllib.chart.internal.foundation.AbstractPlot(abstractPlotArguments{:},...
                Options=pzPlotInputs.Options);
        end
    end

    %% Public methods
    methods
        function addResponse(this,models,optionalInputs)
            % addResponse adds the pz response to the chart
            %
            %   addResponse(h,sys)
            %       adds the pz response of "sys to the chart "h"
            %
            %   addResponse(h,sys,Name=Value)
            %       Name            "untitled1" (default) | scalar | vector
            %       LineStyle       "-" (default) | "--" | ":" | "-." | "none"
            %       Color           [0 0.4470 0.7410] (default) | RGB triplet | hexadecimal color code | "r" | "g" | "b" | ... 
            %       MarkerStyle     "none" (default) | "o" | "+" | "*" | "." | ...
            %       LineWidth       0.5 (default) | positive value

            arguments
                this (1,1) controllib.chart.PZPlot
                models DynamicSystem
                optionalInputs.Name (:,1) string = repmat("",length(models),1)
                optionalInputs.Color = []
                optionalInputs.MarkerSize double {mustBeScalarOrEmpty} = []
                optionalInputs.LineWidth double {mustBeScalarOrEmpty} = []                
            end

            % Define Name
            if strcmp(optionalInputs.Name,"")
                optionalInputs.Name = string(inputname(2));
            end

            % Create PZResponse
            % Get next name
            if isempty(optionalInputs.Name) || strcmp(optionalInputs.Name,"")
                name = getNextSystemName(this);
            else
                name = optionalInputs.Name;
            end

            % Create PZResponse
            newResponse = createResponse_(this,models,name);
            if ~isempty(newResponse.DataException) && ~strcmp(this.ResponseDataExceptionMessage,"none")
               if strcmp(this.ResponseDataExceptionMessage,"error")
                   throw(newResponse.DataException);
               else % warning
                   warning(newResponse.DataException.identifier,newResponse.DataException.message);
               end
            end

            if ~isempty(optionalInputs.Color)
                newResponse.Color = optionalInputs.Color;
            end

            if ~isempty(optionalInputs.MarkerSize)
                newResponse.MarkerSize = optionalInputs.MarkerSize;
            end

            if ~isempty(optionalInputs.LineWidth)
                newResponse.Style.LineWidth = optionalInputs.LineWidth;
            end
            
            % Add response to chart
            registerResponse(this,newResponse);
        end

        function options = getoptions(this,propertyName)
            arguments
                this (1,1) controllib.chart.PZPlot
                propertyName string {mustBeScalarOrEmpty,validateOptionPropertyName(this,propertyName)} = string.empty
            end
            if isempty(propertyName)
                options = getoptions@controllib.chart.internal.foundation.AbstractPlot(this);
                options.FreqUnits = char(this.FrequencyUnit);
                options.TimeUnits = char(this.TimeUnit);
            else
                switch propertyName
                    case 'FreqUnits'
                        options = char(this.FrequencyUnit);
                    case 'TimeUnits'
                        options = char(this.TimeUnit);
                    case {'OutputLabels','InputLabels','OutputVisible','InputVisible','IOGrouping','ConfidenceRegionNumberSD'}
                        options = this.createDefaultOptions().(propertyName);
                    otherwise
                        options = getoptions@controllib.chart.internal.foundation.AbstractPlot(this,propertyName);
                end
            end
        end

        %setoptions
        function setoptions(this,options,nameValueInputs)
            arguments
                this (1,1) controllib.chart.PZPlot
                options (1,1) plotopts.PZOptions = getoptions(this)
                nameValueInputs.?plotopts.PZOptions
            end

            options = copy(options);
            
            % Update options with name-value inputs
            nameValueInputsCell = namedargs2cell(nameValueInputs);
            if ~isempty(nameValueInputsCell)
                set(options,nameValueInputsCell{:});
            end

            % Time Unit
            if strcmp(options.TimeUnits,'auto')
                if isempty(this.Responses)
                    this.TimeUnit = "seconds";
                else
                    this.TimeUnit = this.Responses(1).TimeUnit;
                end
            else
                this.TimeUnit = options.TimeUnits;
            end

            % Frequency Unit
            if strcmp(options.FreqUnits,'auto')
                if isempty(this.Responses)
                    this.FrequencyUnit = "rad/s";
                else
                    this.FrequencyUnit = this.Responses(1).FrequencyUnit;
                end
            else
                this.FrequencyUnit = options.FreqUnits;
            end

            % Call base class for limits, style
            setoptions@controllib.chart.internal.foundation.AbstractPlot(this,options);
        end
    end

    %% Get/Set methods
    methods
        % TimeUnit
        function TimeUnit = get.TimeUnit(this)
            TimeUnit = this.TimeUnit_I;
        end

        function set.TimeUnit(this,TimeUnit)
            arguments
                this (1,1) controllib.chart.PZPlot
                TimeUnit (1,1) string {controllib.chart.internal.utils.mustBeValidTimeUnit} 
            end
            this.TimeUnit_I = TimeUnit;

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.TimeUnit = TimeUnit;
            end

            % Update property editor
            if ~isempty(this.UnitsWidget) && isvalid(this.UnitsWidget)
                this.UnitsWidget.TimeUnits = TimeUnit;
            end

            % Update Requirements
            % Syncs constraint props with related Editor props
            for k = 1:length(this.Requirements)
                if contains(getUID(this.Requirements(k)),'pzsettling')
                    this.Requirements(k).setDisplayUnits('xunits',char(TimeUnit));
                    this.Requirements(k).TextEditor.setDisplayUnits('xunits',char(TimeUnit));
                elseif contains(getUID(this.Requirements(k)),'pzfrequency')
                    this.Requirements(k).setDisplayUnits('yunits',char(TimeUnit));
                    this.Requirements(k).TextEditor.setDisplayUnits('yunits',char(TimeUnit));
                elseif contains(getUID(this.Requirements(k)),'pzlocation')
                    this.Requirements(k).setDisplayUnits('xunits',char(TimeUnit));
                    this.Requirements(k).setDisplayUnits('yunits',char(TimeUnit));
                    this.Requirements(k).TextEditor.setDisplayUnits('xunits',char(TimeUnit));
                    this.Requirements(k).TextEditor.setDisplayUnits('yunits',char(TimeUnit));
                end
                update(this.Requirements(k));
            end
        end

        % FrequencyUnit
        function FrequencyUnit = get.FrequencyUnit(this)
            FrequencyUnit = this.FrequencyUnit_I;
        end

        function set.FrequencyUnit(this,FrequencyUnit)
            arguments
                this (1,1) controllib.chart.PZPlot
                FrequencyUnit (1,1) string {controllib.chart.internal.utils.mustBeValidFrequencyUnit}
            end
            this.FrequencyUnit_I = FrequencyUnit;

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.FrequencyUnit = FrequencyUnit;
            end

            % Update property editor
            if ~isempty(this.UnitsWidget) && isvalid(this.UnitsWidget)
                this.UnitsWidget.FrequencyUnits = FrequencyUnit;
            end

            % Update Requirements
            % Syncs constraint props with related Editor props
            for k = 1:length(this.Requirements)
                if contains(getUID(this.Requirements(k)),'pzfrequency')
                    this.Requirements(k).setDisplayUnits('xunits',char(FrequencyUnit));
                    this.Requirements(k).TextEditor.setDisplayUnits('xunits',char(FrequencyUnit));
                end
                update(this.Requirements(k));
            end
        end
    end

    %% Protected methods
    methods (Access = protected)
        function initialize(this)
            initialize@controllib.chart.internal.foundation.AbstractPlot(this);
            this.Type = 'pzmap';
            this.SynchronizeResponseUpdates = true;            
            build(this);
        end

        %% Responses
        function response = createResponse_(~,model,name)
            response = controllib.chart.response.PZResponse(model,Name=name);
        end

        function response = createBoundResponse_(~,name,minDecay,minDamping,maxFrequency,Ts)
            response = controllib.chart.response.internal.PZBoundResponse(...
                MinDecay = minDecay,...
                MinDamping = minDamping,...
                MaxFrequency = maxFrequency,...
                Ts = Ts,...
                Name=name);
        end

        function cbResponseChanged(this,response)
            cbResponseChanged@controllib.chart.internal.foundation.AbstractPlot(this,response);
            updateForCustomGrid(this.AxesStyle);
        end

        function cbResponseDeleted(this)
            cbResponseDeleted@controllib.chart.internal.foundation.AbstractPlot(this);
            updateForCustomGrid(this.AxesStyle);
        end

        %% View
        function view = createView_(this)
            % Create view
            view = controllib.chart.internal.view.axes.PZAxesView(this);
        end

        function tf = hasCustomGrid(this)
            isDiscrete = false(size(this.Responses));
            for ii = 1:length(this.Responses)
                isDiscrete(ii) = this.Responses(ii).IsDiscrete;
            end
            if isempty(isDiscrete)
                tf = false;
            elseif this.AxesStyle.GridType == "default"
                tf = all(isDiscrete) || ~any(isDiscrete);
            else
                tf = true;
            end
        end

        %% Property editor
        function buildUnitsWidget(this)
            % Create UnitsContainer
            this.UnitsWidget = controllib.widget.internal.cstprefs.UnitsContainer('TimeUnits','FrequencyUnits');
            
            % Remove 'auto' from frequency and time unit list
            this.UnitsWidget.ValidFrequencyUnits(1,:) = [];
            this.UnitsWidget.ValidTimeUnits(1,:) = [];
            
            % Set default units
            this.UnitsWidget.FrequencyUnits = this.FrequencyUnit;
            this.UnitsWidget.TimeUnits = this.TimeUnit;

            % Add custom label
            labelLayout = uigridlayout(RowHeight={'fit'},ColumnWidth={'1x'},Parent=[],Padding=[20 0 0 0]);
            uilabel(labelLayout,Text=getString(message('Controllib:gui:PZPlotFrequencyUnitDescriptionLabel')));
            setCustomWidget(this.UnitsWidget,labelLayout);

            % Add listeners for widget to data 
            registerListeners(this,...
                addlistener(this.UnitsWidget,'TimeUnits','PostSet',@(es,ed) cbTimeUnitChangedInPropertyEditor(this,ed)),...
                'TimeUnitChangedInPropertyEditor');
            registerListeners(this,...
                addlistener(this.UnitsWidget,'FrequencyUnits','PostSet',@(es,ed) cbFrequencyUnitChangedInPropertyEditor(this,ed)),...
                'FrequencyUnitChangedInPropertyEditor');

            % Local callback functions
            function cbTimeUnitChangedInPropertyEditor(this,ed)
                this.TimeUnit = ed.AffectedObject.TimeUnits;
            end

            function cbFrequencyUnitChangedInPropertyEditor(this,ed)
                this.FrequencyUnit = ed.AffectedObject.FrequencyUnits;
            end
        end

        function names = getCustomPropertyGroupNames(this) %#ok<MANU>
            names = ["TimeUnit","FrequencyUnit"];
        end
    end

    %% Static protected methods
    methods (Static,Access=protected)
        function mustBeSampleTime(Ts)
            if Ts ~= -1
                mustBePositive(Ts);
            end
        end
    end

    %% Static hidden methods
    methods (Static,Hidden)
        function options = createDefaultOptions()
            options = pzoptions('cstprefs');
        end
    end

    %% Hidden methods
    methods (Hidden)
        function addBoundResponse(this,optionalInputs)
            arguments
                this (1,1) controllib.chart.PZPlot
                optionalInputs.MinDecay (1,1) double = 0
                optionalInputs.MinDamping (1,1) double = 0
                optionalInputs.MaxFrequency (1,1) double = inf
                optionalInputs.Ts (1,1) double = 0
                optionalInputs.Name (1,1) string = ""
                optionalInputs.FaceColor = []
                optionalInputs.EdgeColor = []
                optionalInputs.FaceAlpha double {mustBeScalarOrEmpty} = []
                optionalInputs.EdgeAlpha double {mustBeScalarOrEmpty} = []
                optionalInputs.LineStyle (1,1) string = ""
                optionalInputs.MarkerStyle (1,1) string = ""
                optionalInputs.LineWidth double {mustBeScalarOrEmpty} = []
                optionalInputs.MarkerSize double {mustBeScalarOrEmpty} = []
            end

            % Get next name
            if isempty(optionalInputs.Name) || optionalInputs.Name == ""
                name = getNextSystemName(this);
            else
                name = optionalInputs.Name;
            end

            % Create PZBoundResponse
            newResponse = createBoundResponse_(this,name,optionalInputs.MinDecay,...
                optionalInputs.MinDamping,optionalInputs.MaxFrequency,...
                optionalInputs.Ts);
            if ~isempty(newResponse.DataException)
                throw(newResponse.DataException);
            end

            if ~isempty(optionalInputs.FaceColor)
                newResponse.Style.FaceColor = optionalInputs.FaceColor;
            end

            if ~isempty(optionalInputs.EdgeColor)
                newResponse.Style.EdgeColor = optionalInputs.EdgeColor;
            end

            if ~isempty(optionalInputs.FaceAlpha)
                newResponse.Style.FaceAlpha = optionalInputs.FaceAlpha;
            end

            if ~isempty(optionalInputs.EdgeAlpha)
                newResponse.Style.EdgeAlpha = optionalInputs.EdgeAlpha;
            end

            if ~strcmp(optionalInputs.LineStyle,"")
                newResponse.Style.LineStyle = optionalInputs.LineStyle;
            end

            if ~strcmp(optionalInputs.MarkerStyle,"")
                newResponse.Style.MarkerStyle = optionalInputs.MarkerStyle;
            end

            if ~isempty(optionalInputs.LineWidth)
                newResponse.Style.LineWidth = optionalInputs.LineWidth;
            end

            if~isempty(optionalInputs.MarkerSize)
                newResponse.Style.MarkerSize = optionalInputs.MarkerSize;
            end

            % Add response to chart
            registerResponse(this,newResponse);
        end

        function list = getRequirementList(~)
            list.Type = 'SettlingTime';
            list.Label = getString(message('Controllib:graphicalrequirements:lblSettlingTime'));
            list.Class = 'editconstr.SettlingTime';
            list.DataClass = 'srorequirement.settlingtime';

            list(2).Type = 'PercentOvershoot';
            list(2).Label = getString(message('Controllib:graphicalrequirements:lblPercentOvershoot'));
            list(2).Class = 'editconstr.DampingRatio';
            list(2).DataClass = 'srorequirement.dampingratio';

            list(3).Type = 'DampingRatio';
            list(3).Label = getString(message('Controllib:graphicalrequirements:lblDampingRatio'));
            list(3).Class = 'editconstr.DampingRatio';
            list(3).DataClass = 'srorequirement.dampingratio';

            list(4).Type = 'NaturalFrequency';
            list(4).Label = getString(message('Controllib:graphicalrequirements:lblNaturalFrequency'));
            list(4).Class = 'editconstr.NaturalFrequency';
            list(4).DataClass = 'srorequirement.naturalfrequency';

            list(5).Type = 'RegionConstraint';
            list(5).Label = getString(message('Controllib:graphicalrequirements:lblRegionConstraint'));
            list(5).Class = 'editconstr.PZLocation';
            list(5).DataClass = 'srorequirement.pzlocation';
        end

        function newConstraint = getNewConstraint(this,type,currentConstraint)
            list = getRequirementList(this);
            type = localCheckType(type,list);
            typeIdx = strcmp(type,{list.Type});
            constraintClass = list(typeIdx).Class;
            dataClass = list(typeIdx).DataClass;

            % Create instance
            reuseInstance = nargin > 2 && isa(currentConstraint,constraintClass);
            if reuseInstance && (strcmpi(type,'PercentOvershoot') || strcmpi(type,'DampingRatio'))
                if strcmp(type,'PercentOvershoot') && strcmp(currentConstraint.Type,'damping') || ...
                        strcmp(type,'DampingRatio') && strcmp(currentConstraint.Type,'overshoot')
                    reuseInstance = false;
                end
            end

            if reuseInstance
                % Use current constraint and update type
                newConstraint = currentConstraint;
            else
                % Create new constraint
                requirementData = feval(dataClass);
                %Ensure feedback sign for requirement is zero (i.e., open loop)
                requirementData.FeedbackSign = 0;
                % Create corresponding requirement editor class
                newConstraint = feval(constraintClass,requirementData);
                % Determine sampling time for the constraint
                if ~isempty(this.Responses)
                    newConstraint.Ts = this.Responses(1).Model.Ts;
                else
                    % Default to continuous
                    newConstraint.Ts = 0;
                end

                if strcmp(type,'PercentOvershoot')
                    newConstraint.Type = 'overshoot';
                elseif strcmp(type,'DampingRatio')
                    newConstraint.Type = 'damping';
                elseif strcmp(type,'NaturalFrequency')
                    if newConstraint.Ts
                        newConstraint.Requirement.setData('xdata',1/newConstraint.Ts);
                    end
                    newConstraint.setDisplayUnits('xunits',this.FrequencyUnit);
                elseif strcmp(type,'SettlingTime') && newConstraint.Ts
                    newConstraint.Requirement.setData('xData',10*Constr.Ts);
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
                    'Settling time'; ...
                    'Percent overshoot'; ...
                    'Damping ratio'; ...
                    'Natural frequency'; ...
                    'Region constraint'};
                strTr = {list.Label};
                idx = strcmp(kIn,strTr) | strcmp(kIn,strEng);
                if any(idx)
                    kOut = list(idx).Type;
                else
                    kOut = [];
                end
            end
        end

        function addConstraintView(this,constraint,varargin)
            if contains(getUID(constraint),'pzsettling')
                constraint.setDisplayUnits('xunits',char(this.TimeUnit));
                constraint.TextEditor.setDisplayUnits('xunits',char(this.TimeUnit));
            elseif contains(getUID(constraint),'pzfrequency')
                constraint.setDisplayUnits('xunits',char(this.FrequencyUnit));
                constraint.TextEditor.setDisplayUnits('xunits',char(this.FrequencyUnit));
                constraint.setDisplayUnits('yunits',char(this.TimeUnit));
                constraint.TextEditor.setDisplayUnits('yunits',char(this.TimeUnit));
            elseif contains(getUID(constraint),'pzlocation')
                constraint.setDisplayUnits('xunits',char(this.TimeUnit));
                constraint.setDisplayUnits('yunits',char(this.TimeUnit));
                constraint.TextEditor.setDisplayUnits('xunits',char(this.TimeUnit));
                constraint.TextEditor.setDisplayUnits('yunits',char(this.TimeUnit));
            end
            update(constraint);
            addConstraintView@controllib.chart.internal.foundation.AbstractPlot(this,constraint,varargin{:});
        end

        function registerResponse(this,newResponse,~)
            arguments
                this (1,1) controllib.chart.internal.foundation.AbstractPlot
                newResponse (1,1) controllib.chart.internal.foundation.BaseResponse
                ~
            end
            registerResponse@controllib.chart.internal.foundation.AbstractPlot(this,newResponse);
            updateForCustomGrid(this.AxesStyle);
        end
    end
end