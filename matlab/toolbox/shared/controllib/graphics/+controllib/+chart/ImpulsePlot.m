classdef ImpulsePlot < controllib.chart.internal.foundation.RowColumnPlot & ...
                       controllib.chart.internal.foundation.MixInInputOutputPlot & ...
                       controllib.chart.internal.foundation.MixInTimeComplexPlot
    % Construct an ImpulsePlot

    %   Copyright 2021-2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent, AbortSet, SetObservable)
        TimeUnit
        Normalize
    end

    properties (Dependent,Access=private)
        SettlingTimeThreshold
        NumberOfStandardDeviations
    end

    properties (GetAccess=protected,SetAccess=private)
        TimeUnit_I = "seconds"
        Normalize_I = matlab.lang.OnOffSwitchState(false)

        SettlingTimeThreshold_I = controllib.chart.ImpulsePlot.createDefaultOptions().SettleTimeThreshold
        NumberOfStandardDeviations_I = controllib.chart.ImpulsePlot.createDefaultOptions().ConfidenceRegionNumberSD
    end

    properties(Access = protected,Transient,NonCopyable)
        NormalizeMenu
        TimeResponseWidget
        ConfidenceRegionWidget

        SpecifyTimeDialog
        SpecifyTimeMenu
    end

    %% Events
    events
        TimeChanged
    end

    %% Constructor/destructor
    methods
        function this = ImpulsePlot(impulsePlotInputs,inputOutputPlotArguments)
            arguments
                impulsePlotInputs.Options (1,1) plotopts.TimeOptions = controllib.chart.ImpulsePlot.createDefaultOptions()
                inputOutputPlotArguments.?controllib.chart.internal.foundation.AbstractPlotOptionalInputs
            end
            % Extract name-value inputs for AbstractPlot
            inputOutputPlotArguments = namedargs2cell(inputOutputPlotArguments);
            this@controllib.chart.internal.foundation.MixInTimeComplexPlot(impulsePlotInputs.Options.ComplexViewType);
            this@controllib.chart.internal.foundation.RowColumnPlot(inputOutputPlotArguments{:},...
                Options=impulsePlotInputs.Options);
        end

        function delete(this)
            delete@controllib.chart.internal.foundation.RowColumnPlot(this);
            delete(this.SpecifyTimeDialog);
        end
    end

    %% Public methods
    methods
        function addResponse(this,model,time,parameter,optionalInputs,optionalStyleInputs)
            % addResponse adds the impulse response to the chart
            %
            %   addResponse(h,sys)
            %       adds the impulse response of "sys" to the chart "h"
            %
            %   addResponse(h,sys,t)
            %   addResponse(h,sys,t,p)
            %       t               [] (default) | scalar | vector
            %       p               [] (default) | vector | function_handle
            %
            %   addResponse(h,_______,Name-Value)
            %       Config          RespConfig object
            %       Name            "untitled1" (default) | scalar | vector
            %       LineStyle       "-" (default) | "--" | ":" | "-." | "none"
            %       Color           [0 0.4470 0.7410] (default) | RGB triplet | hexadecimal color code | "r" | "g" | "b" | ... 
            %       MarkerStyle     "none" (default) | "o" | "+" | "*" | "." | ...
            %       LineWidth       0.5 (default) | positive value

            arguments
                this (1,1) controllib.chart.ImpulsePlot
                model DynamicSystem
                time (:,1) double = []
                parameter = []
                optionalInputs.Config (1,1) RespConfig = RespConfig
                optionalInputs.Name (1,1) string = ""
                optionalStyleInputs.?controllib.chart.internal.options.AddResponseStyleOptionalInputs
            end

            % Define Name
            if strcmp(optionalInputs.Name,"")
                optionalInputs.Name = string(inputname(2));
            end

            % Create ImpulseResponse
            % Get next and name
            if isempty(optionalInputs.Name) || strcmp(optionalInputs.Name,"")
                name = getNextSystemName(this);
            else
                name = optionalInputs.Name;
            end
            % Create ImpulseResponse
            newResponse = createResponse_(this,model,name,time,parameter,...
                optionalInputs.Config);
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

            % Add response to chart
            registerResponse(this,newResponse);
        end

        function options = getoptions(this,propertyName)
            arguments
                this (1,1) controllib.chart.ImpulsePlot
                propertyName string {mustBeScalarOrEmpty,validateOptionPropertyName(this,propertyName)} = string.empty
            end
            if isempty(propertyName)
                options = getoptions@controllib.chart.internal.foundation.RowColumnPlot(this);
                options.TimeUnits = char(this.TimeUnit);
                options.Normalize = char(this.Normalize);

                options.SettleTimeThreshold = this.SettlingTimeThreshold;
                options.ConfidenceRegionNumberSD = this.NumberOfStandardDeviations;
            else
                switch propertyName
                    case 'TimeUnits'
                        options = char(this.TimeUnit);
                    case 'Normalize'
                        options = char(this.Normalize);
                    case 'SettleTimeThreshold'
                        options = this.SettlingTimeThreshold;
                    case 'RiseTimeLimits'
                        options = this.createDefaultOptions().RiseTimeLimits;
                    case 'ConfidenceRegionNumberSD'
                        options = this.NumberOfStandardDeviations;
                    otherwise
                        options = getoptions@controllib.chart.internal.foundation.RowColumnPlot(this,propertyName);
                end
            end
        end

        %setoptions
        function setoptions(this,options,nameValueInputs)
            arguments
                this (1,1) controllib.chart.ImpulsePlot
                options (1,1) plotopts.TimeOptions = getoptions(this)
                nameValueInputs.?plotopts.TimeOptions
            end

            options = copy(options);
            
            % Update options with name-value inputs
            nameValueInputsCell = namedargs2cell(nameValueInputs);
            if ~isempty(nameValueInputsCell)
                set(options,nameValueInputsCell{:});
            end

            % Set TimeUnit
            if strcmp(options.TimeUnits,'auto')
                if isempty(this.Responses)
                    this.TimeUnit = "seconds";
                else
                    this.TimeUnit = this.Responses(1).TimeUnit;
                end
            else
                this.TimeUnit = options.TimeUnits;
            end

            % Normalize
            this.Normalize = options.Normalize;

            % ComplexViewType
            this.ComplexViewType = options.ComplexViewType;

            % Set characteristic options
            this.SettlingTimeThreshold = options.SettleTimeThreshold;
            this.NumberOfStandardDeviations = options.ConfidenceRegionNumberSD;

            % Call base class for limits, style
            setoptions@controllib.chart.internal.foundation.RowColumnPlot(this,options);
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
                this (1,1) controllib.chart.ImpulsePlot
                TimeUnit (1,1) string {controllib.chart.internal.utils.mustBeValidTimeUnit}
            end
            this.TimeUnit_I = TimeUnit;

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.TimeUnit = TimeUnit;
            end

            % Modify property editor widgets
            if ~isempty(this.UnitsWidget) && isvalid(this.UnitsWidget)
                this.UnitsWidget.TimeUnits = TimeUnit;
            end

            % Update Requirements
            % Syncs constraint props with related Editor props
            for k = 1:length(this.Requirements)
                this.Requirements(k).setDisplayUnits('XUnits',TimeUnit);
                this.Requirements(k).TextEditor.setDisplayUnits('XUnits',TimeUnit);
                update(this.Requirements(k));
            end
        end

        % Normalize
        function Normalize = get.Normalize(this)
            Normalize = matlab.lang.OnOffSwitchState(this.Normalize_I);
        end

        function set.Normalize(this,Normalize)
            arguments
                this (1,1) controllib.chart.ImpulsePlot
                Normalize (1,1) matlab.lang.OnOffSwitchState
            end
            this.Normalize_I = Normalize;

            if ~isempty(this.TimeView) && isvalid(this.TimeView)                    
                disableListeners(this,"YLimitsChangedinAxesGrid")
                this.TimeView.Normalize = Normalize;
                enableListeners(this,"YLimitsChangedinAxesGrid")
            end
        end

        % NumberOfStandardDeviations
        function NumberOfStandardDeviations = get.NumberOfStandardDeviations(this)
            NumberOfStandardDeviations = this.NumberOfStandardDeviations_I;
        end

        function set.NumberOfStandardDeviations(this,NumberOfStandardDeviations)
            arguments
                this (1,1) controllib.chart.ImpulsePlot
                NumberOfStandardDeviations (1,1) double {mustBePositive,mustBeFinite}
            end
            this.NumberOfStandardDeviations_I = NumberOfStandardDeviations;
            if ~isempty(this.Characteristics) && isprop(this.Characteristics,'ConfidenceRegion')
                this.Characteristics.ConfidenceRegion.NumberOfStandardDeviations = NumberOfStandardDeviations;
            end
        end

        % SettlingTimeThreshold
        function SettlingTimeThreshold = get.SettlingTimeThreshold(this)
            SettlingTimeThreshold = this.SettlingTimeThreshold_I;
        end

        function set.SettlingTimeThreshold(this,SettlingTimeThreshold)
            arguments
                this (1,1) controllib.chart.ImpulsePlot
                SettlingTimeThreshold (1,1) double {mustBeInRange(SettlingTimeThreshold,0,1)}
            end
            this.SettlingTimeThreshold_I = SettlingTimeThreshold;
            if ~isempty(this.Characteristics) && isprop(this.Characteristics,'TransientTime')
                this.Characteristics.TransientTime.Threshold = SettlingTimeThreshold;
            end
        end
    end

    %% Protected methods
    methods (Access = protected)
        function initialize(this)
            initialize@controllib.chart.internal.foundation.RowColumnPlot(this);
            this.Type = 'impulse';
            this.SynchronizeResponseUpdates = true;
            build(this);
        end

        function response = createResponse_(~,model,name,time,parameter,config)
            response = controllib.chart.response.ImpulseResponse(model,...
                Name=name,...
                Time=time,...
                Parameter=parameter,...
                Config=config);
        end

        %% Characteristics
        function cm = createCharacteristicOptions_(this,charType)
            switch charType
                case "PeakResponse"
                    cm = controllib.chart.options.CharacteristicOption(...
                        MenuLabel=getString(message('Controllib:plots:strPeakResponse')),...
                        Visible=false);
                case "TransientTime"
                    cm = controllib.chart.options.CharacteristicOption(...
                        MenuLabel=getString(message('Controllib:plots:strTransientTime')),...
                        Visible=false);
                    addCharacteristicProperty(cm,"Threshold",...
                        this.SettlingTimeThreshold);
                    p = findprop(cm,"Threshold");
                    p.SetMethod = @(~,value) updateTransientTime(this,value);
                case "ConfidenceRegion"
                    cm = controllib.chart.options.CharacteristicOption(...
                        MenuLabel=getString(message('Controllib:plots:strConfidenceRegion')),...
                        Visible=false);
                    cm.VisibilityChangedFcn = @(es,ed) cbConfidenceRegionVisibility(this);
                    addCharacteristicProperty(cm,"NumberOfStandardDeviations",...
                        this.NumberOfStandardDeviations);
                    p = findprop(cm,"NumberOfStandardDeviations");
                    p.SetMethod = @(~,value) updateNumberOfStandardDeviations(this,value);
            end
        end

        function applyCharacteristicOptionsToResponse(this,response)
            response.SettlingTimeThreshold = this.SettlingTimeThreshold;
            if isprop(response,"NumberOfStandardDeviations")
                response.NumberOfStandardDeviations = this.NumberOfStandardDeviations;
            end
        end

        function cbConfidenceRegionVisibility(this)
            setCharacteristicVisibility(this,"ConfidenceRegion");
            updateFocus(this.View);
        end

        function [tags,labels] = getCharacteristicTagsToShowInArraySelector(this)
            tags = ["PeakResponse","TransientTime"];
            labels = [getCharacteristicOption(this,tags).MenuLabelText];
        end

        function updateArrayVisibilityUsingCharacteristicBounds(this)
            idx = find([this.Responses.Name]==this.ArraySelectorDialog.SelectedSystem);
            response = this.Responses(idx);
            data = response.ResponseData;

            arrayVisible = false(size(this.Responses(idx).ArrayVisible));
            conversionFcn = controllib.chart.internal.utils.getTimeUnitConversionFcn(response.TimeUnit,...
                this.TimeUnit);
            for ka = 1:response.NResponses
                compute(data.PeakResponse);
                compute(data.TransientTime);

                isPeakResponseWithinBounds = isCharacteristicWithinBounds(this.ArraySelectorDialog,...
                    "PeakResponse",data.PeakResponse.Value{ka});
                isTransientTimeWithinBounds = isCharacteristicWithinBounds(this.ArraySelectorDialog,...
                    "TransientTime",conversionFcn(data.TransientTime.Time{ka}));

                arrayVisible(ka) = all(isPeakResponseWithinBounds(:) & ...
                                       isTransientTimeWithinBounds(:));

            end
            response.ArrayVisible = arrayVisible;
        end

        function updateTransientTime(this,value)
            arguments
                this (1,1) controllib.chart.ImpulsePlot
                value (1,1) double {mustBeInRange(value,0,1)}
            end
            this.SettlingTimeThreshold_I = value;
            this.Characteristics.TransientTime.Threshold_I = value;

            % Update responses
            for k = 1:length(this.Responses)
                this.Responses(k).SettlingTimeThreshold = this.Characteristics.TransientTime.Threshold;
            end

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                updateCharacteristic(this.View,"TransientTime",this.Responses);
            end

            % Update property editor widget
            if ~isempty(this.TimeResponseWidget) && isvalid(this.TimeResponseWidget)
                disableListeners(this,'SettlingTimeThresholdChangedInPropertyEditor');
                this.TimeResponseWidget.SettlingTimeThreshold = this.Characteristics.TransientTime.Threshold;
                enableListeners(this,'SettlingTimeThresholdChangedInPropertyEditor');
            end
        end

        function updateNumberOfStandardDeviations(this,value)
            arguments
                this (1,1) controllib.chart.ImpulsePlot
                value (1,1) double {mustBePositive,mustBeFinite}
            end
            this.NumberOfStandardDeviations_I = value;
            this.Characteristics.ConfidenceRegion.NumberOfStandardDeviations_I = value;

            % Update responses
            for k = 1:length(this.Responses)
                if isprop(this.Responses(k),'NumberOfStandardDeviations')
                    this.Responses(k).NumberOfStandardDeviations = this.Characteristics.ConfidenceRegion.NumberOfStandardDeviations;
                end
            end

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                updateCharacteristic(this.View,"ConfidenceRegion",this.Responses);
            end

            % Update property editor widget
            if ~isempty(this.ConfidenceRegionWidget) && isvalid(this.ConfidenceRegionWidget)
                disableListeners(this,'ConfidenceNumSDChangedInPropertyEditor');
                this.ConfidenceRegionWidget.ConfidenceNumSD = this.Characteristics.ConfidenceRegion.NumberOfStandardDeviations;
                enableListeners(this,'ConfidenceNumSDChangedInPropertyEditor');
            end
        end

        %% View
        function view = createView_(this)
            switch this.ComplexViewType
                case "realimaginary"
                    view = createTimeView(this);
                    this.TimeView = view;
                case "magnitudephase"
                    view = createMagnitudePhaseView(this);
                    this.MagnitudePhaseView = view;
                case "complexplane"
                    view = createPolarView(this);
                    this.PolarView = view;
            end
        end

        function view = createTimeView(this,viewForInitialization)
            if nargin > 1
                view = controllib.chart.internal.view.axes.ImpulseAxesView(this,...
                    InitializeUsingView=viewForInitialization);
            else
                view = controllib.chart.internal.view.axes.ImpulseAxesView(this);
            end
        end

        function view = createPolarView(this,viewForInitialization)
            if nargin > 1
                view = controllib.chart.internal.view.axes.TimePhasorInputOutputAxesView(this,...
                                InitializeUsingView=viewForInitialization);
            else
                view = controllib.chart.internal.view.axes.TimePhasorInputOutputAxesView(this);
            end
        end

        function view = createMagnitudePhaseView(this,viewForInitialization)
            if nargin > 1
                view = controllib.chart.internal.view.axes.TimeMagnitudePhaseInputOutputAxesView(this,...
                                InitializeUsingView=viewForInitialization);
            else
                view = controllib.chart.internal.view.axes.TimeMagnitudePhaseInputOutputAxesView(this);
            end
        end

        function view = getActiveView(this)
            view = this.View;
        end

        function setActiveView(this,view)
            this.View = view;
        end

        %% Context menu
        function createContextMenu(this)
            createContextMenu@controllib.chart.internal.foundation.RowColumnPlot(this);
            
            this.NormalizeMenu = uimenu(Parent=[],...
                Text=getString(message('Controllib:plots:strNormalize')),...
                Tag="normalize",...
                Checked=logical(this.Normalize),...
                MenuSelectedFcn=@(es,ed) set(this,Normalize=~this.Normalize));
            addMenu(this,this.NormalizeMenu,Above='fullview',CreateNewSection=false);
            
            this.SpecifyTimeMenu = uimenu(Parent=[],...
                Text=[getString(message('Controllib:plots:strSpecifyTime')),'...'],...
                Tag="specifytime",...
                Separator='on',...
                MenuSelectedFcn=@(es,ed) openSpecifyTimeDialog(this));
            addMenu(this,this.SpecifyTimeMenu,Above='propertyeditor',CreateNewSection=false);

            createComplexViewContextMenu(this);
        end

        function cbContextMenuOpening(this)
            % Update state of menu items dynamically when context menu is opened
            cbContextMenuOpening@controllib.chart.internal.foundation.RowColumnPlot(this);
            this.NormalizeMenu.Checked = this.Normalize;

            setComplexViewContextMenuOnOpen(this);
        end

        %% Property editor
        function buildOptionsTab(this)
            % Build layout
            layout = uigridlayout(Parent=[],RowHeight={'fit','fit'},ColumnWidth={'1x'},Padding=0);

            % Build Time Response widget and add to layout
            buildTimeResponseWidget(this);
            buildConfidenceRegionWidget(this);

            w = getWidget(this.TimeResponseWidget);
            w.Parent = layout;
            w.Layout.Row = 1;
            w.Layout.Column = 1;

            w = getWidget(this.ConfidenceRegionWidget);
            w.Parent = layout;
            w.Layout.Row = 2;
            w.Layout.Column = 1;

            % Add layout/widget to tab
            addTab(this.PropertyEditorDialog,getString(message('Controllib:gui:strOptions')),layout);
        end

        function buildUnitsWidget(this)
            % Create UnitsContainer
            this.UnitsWidget = controllib.widget.internal.cstprefs.UnitsContainer('TimeUnits');
            % Remove 'auto' from time unit list
            this.UnitsWidget.ValidTimeUnits(1,:) = [];

            this.UnitsWidget.TimeUnits = this.TimeUnit;

            % Add listeners for widget to data
            registerListeners(this,...
                addlistener(this.UnitsWidget,'TimeUnits','PostSet',@(es,ed) cbTimeUnitChangedInPropertyEditor(this,ed)),...
                'TimeUnitChangedInPropertyEditor');

            % Local callback functions
            function cbTimeUnitChangedInPropertyEditor(this,ed)
                this.TimeUnit = ed.AffectedObject.TimeUnits;
            end
        end

        function buildTimeResponseWidget(this)
            % Build Time Response widget
            this.TimeResponseWidget = controllib.widget.internal.cstprefs.TimeResponseContainer(ShowRiseTime = false);

            this.TimeResponseWidget.SettlingTimeThreshold = this.SettlingTimeThreshold;

            % Add listeners
            registerListeners(this,addlistener(this.TimeResponseWidget,'SettlingTimeThreshold','PostSet',...
                @(es,ed) cbSettlingTimeThresholdChangedInPropertyEditor(this,ed)),...
                'SettlingTimeThresholdChangedInPropertyEditor');

            % Local callback functions
            function cbSettlingTimeThresholdChangedInPropertyEditor(this,ed)
                this.Characteristics.TransientTime.Threshold = ed.AffectedObject.SettlingTimeThreshold;
            end
        end

        function buildConfidenceRegionWidget(this)
            % Build Time Response widget
            this.ConfidenceRegionWidget = controllib.widget.internal.cstprefs.ConfidenceRegionContainer();

            this.ConfidenceRegionWidget.ConfidenceNumSD = this.NumberOfStandardDeviations;

            % Add listeners
            registerListeners(this,addlistener(this.ConfidenceRegionWidget,'ConfidenceNumSD','PostSet',...
                @(es,ed) cbConfidenceNumSDChangedInPropertyEditor(this,ed)),...
                'ConfidenceNumSDChangedInPropertyEditor');

            % Local callback functions
            function cbConfidenceNumSDChangedInPropertyEditor(this,ed)
                this.Characteristics.ConfidenceRegion.NumberOfStandardDeviations = ed.AffectedObject.ConfidenceNumSD;
            end
        end

        function openSpecifyTimeDialog(this)
            if any(arrayfun(@(x) issparse(x.Model) || isTimeVarying(x.Model),this.Responses))
                enableAuto = false;
                enableFinalTime = true;
                enableVector = true;
            else
                enableAuto = true;
                enableFinalTime = true;
                enableVector = true;
            end
            if isempty(this.SpecifyTimeDialog) || ~isvalid(this.SpecifyTimeDialog)
                if isempty(this.Responses)
                    t = [];
                else
                    t = this.Responses(end).SourceData.TimeSpec;
                end
                this.SpecifyTimeDialog = controllib.chart.internal.widget.TimeEditorDialog(...
                    EnableAuto=enableAuto,EnableFinal=enableFinalTime,EnableVector=enableVector,...
                    Time=t,TimeUnits=this.TimeUnit);
                this.SpecifyTimeDialog.TimeChangedFcn = @(es,ed) cbTimeChanged(this,ed);
            end
            this.SpecifyTimeDialog.EnableAuto = enableAuto;    
            show(this.SpecifyTimeDialog);

            function cbTimeChanged(this,ed)
                for k = 1:length(this.Responses)
                    cf = controllib.chart.internal.utils.getTimeUnitConversionFcn(...
                        ed.Data.TimeUnits,this.Responses(k).TimeUnit);
                    this.Responses(k).SourceData.TimeSpec = cf(ed.Data.Time);
                end
                ev = controllib.chart.internal.utils.GenericEventData(ed.Data.Time);
                notify(this,'TimeChanged',ev);
            end
        end

        function names = getCustomPropertyGroupNames(this)
            names = ["TimeUnit","Normalize"];
            names = [names,getPropertyNamesForComplexView(this)];
        end
    end

    %% Static, protected methods
    methods (Static, Access = protected)
        function storedProperties = getPropertiesToStoreOnViewSwitch(chart)
            storedProperties = ...
                controllib.chart.internal.foundation.MixInTimeComplexPlot.getPropertiesToStoreOnViewSwitch(chart);
            storedProperties.IOGrouping = chart.IOGrouping;
            storedProperties.InputVisible = chart.InputVisible;
            storedProperties.OutputVisible = chart.OutputVisible;
        end

        function applyStoredPropertiesAfterViewSwitch(this,storedProperties)
            controllib.chart.internal.foundation.MixInTimeComplexPlot.applyStoredPropertiesAfterViewSwitch(this,storedProperties);
            this.IOGrouping = storedProperties.IOGrouping;
            this.InputVisible = storedProperties.InputVisible;
            this.OutputVisible = storedProperties.OutputVisible;
        end
    end
    
    %% Static hidden methods
    methods (Static,Hidden)
        function options = createDefaultOptions()
            options = timeoptions('cstprefs');
            options.Title.String = getString(message('Controllib:plots:strImpulseResponse'));
        end
    end

    %% Hidden methods
    methods (Hidden)
        function list = getRequirementList(this) %#ok<MANU>
            list.Type = 'UpperTimeResponse';
            list.Label = getString(message('Controllib:graphicalrequirements:lblUpperTimeBound'));
            list.Class = 'editconstr.TimeResponse';
            list.DataClass = 'srorequirement.timeresponse';

            list(2).Type = 'LowerTimeResponse';
            list(2).Label = getString(message('Controllib:graphicalrequirements:lblLowerTimeBound'));
            list(2).Class = 'editconstr.TimeResponse';
            list(2).DataClass = 'srorequirement.timeresponse';
        end

        function newConstraint = getNewConstraint(this,type,currentConstraint)
            list = getRequirementList(this);
            type = localCheckType(type,list);
            typeIdx = strcmp(type,{list.Type});
            constraintClass = list(typeIdx).Class;
            dataClass = list(typeIdx).DataClass;

            switch type
                case 'UpperTimeResponse'
                    constraintType = 'upper';
                case 'LowerTimeResponse'
                    constraintType = 'lower';
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
                newConstraint.setDisplayUnits('xunits',char(this.TimeUnit));
                newConstraint.setDisplayUnits('yunits','abs');
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
                    'Upper time response bound'; ...
                    'Lower time response bound'};
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
            constraint.setDisplayUnits('yunits','');
            constraint.setDisplayUnits('xunits',char(this.TimeUnit));
            addConstraintView@controllib.chart.internal.foundation.RowColumnPlot(this,constraint,varargin{:});
        end

        function openPropertyDialog(this)
            openPropertyDialog@controllib.chart.internal.foundation.RowColumnPlot(this);
            this.ConfidenceRegionWidget.Visible = any(arrayfun(@(x) isprop(x,'NumberOfStandardDeviations'),this.Responses));
        end

        function widgets = qeGetPropertyEditorWidgets(this)
            widgets = qeGetPropertyEditorWidgets@controllib.chart.internal.foundation.RowColumnPlot(this);
            widgets.TimeResponseWidget = this.TimeResponseWidget;
            widgets.ConfidenceRegionWidget = this.ConfidenceRegionWidget;
        end

        function dlg = qeGetSpecifyTimeDialog(this)
            openSpecifyTimeDialog(this);
            dlg = this.SpecifyTimeDialog;
        end

         function switchToPolarView(this)
            % Hide TimeView and delete ResponseViews
            this.TimeView.Visible = 'off';
            for k = 1:length(this.Responses)
                rv = getResponseView(this.TimeView,this.Responses(k));
                deleteResponseView(this.TimeView,rv);
            end

            axesGrid = qeGetAxesGrid(this.View);
            if isempty(this.PolarView) || ~isvalid(this.PolarView)
                % Create polar view if needed
                view = controllib.chart.internal.view.axes.TimePhasorInputOutputAxesView(this);
                setAxesGrid(view,axesGrid);
                build(view);
                % Set default limits and label configuration
                view.XLimitsSharing = "column";
                view.XLimitsMode = "auto";
                view.YLimitsSharing = "row";
                view.YLimitsMode = "auto";
                view.XLabel = "Real";
                view.YLabel = "Imaginary";
                view.Visible = 'on';
                this.PolarView = view;
            else
                % Use AxesGrid from TimeView on existing PolarView
                setAxesGrid(this.PolarView,axesGrid);
                this.PolarView.Visible = 'on';
            end
            this.View = this.PolarView;
            
            % Create response views and update focus
            for k = 1:length(this.Responses)
                addResponseView(this.PolarView,this.Responses(k));
            end
            updateFocus(this.PolarView);
            
            % Propagate view settings to chart
            this.XLimitsSharing = this.PolarView.XLimitsSharing;
            this.XLimitsMode = this.PolarView.XLimitsMode;
            this.YLimitsSharing = this.PolarView.YLimitsSharing;
            this.YLimitsMode = this.PolarView.YLimitsMode;
            this.XLabel.String = this.PolarView.XLabel;
            this.YLabel.String = this.PolarView.YLabel;
        end

        function switchToTimeView(this)
            % Hide PolarView and delete ResponseViews
            this.PolarView.Visible = 'off';
            for k = 1:length(this.Responses)
                rv = getResponseView(this.PolarView,this.Responses(k));
                deleteResponseView(this.PolarView,rv);
            end

            axesGrid = qeGetAxesGrid(this.View);
            if isempty(this.TimeView) || ~isvalid(this.TimeView)
                % Create polar view if needed
                view = controllib.chart.internal.view.axes.StepAxesView(this);
                setAxesGrid(view,axesGrid);
                build(view);
                % Set default limits and label configuration
                view.XLimitsSharing = "column";
                view.XLimitsMode = "auto";
                view.YLimitsSharing = "row";
                view.YLimitsMode = "auto";
                options = getoption(this);
                view.XLabel = options.XLabel.String;
                view.YLabel = options.YLabel.String;
                view.Visible = 'on';
                this.TimeView = view;
            else
                % Use AxesGrid from TimeView on existing PolarView
                setAxesGrid(this.TimeView,axesGrid);
                this.TimeView.Visible = 'on';
            end
            this.View = this.TimeView;
            
            % Create response views and update focus
            for k = 1:length(this.Responses)
                addResponseView(this.TimeView,this.Responses(k));
            end
            updateFocus(this.TimeView);
            
            % Propagate view settings to chart
            this.XLimitsSharing = this.TimeView.XLimitsSharing;
            this.XLimitsMode = this.TimeView.XLimitsMode;
            this.YLimitsSharing = this.TimeView.YLimitsSharing;
            this.YLimitsMode = this.TimeView.YLimitsMode;
            this.XLabel.String = this.TimeView.XLabel;
            this.YLabel.String = this.TimeView.YLabel;
        end
    end
end