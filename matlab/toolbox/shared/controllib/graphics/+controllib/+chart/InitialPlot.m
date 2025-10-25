classdef InitialPlot < controllib.chart.internal.foundation.OutputPlot & ...
                       controllib.chart.internal.foundation.MixInTimeComplexPlot
    % Construct an InitialPlot.
    %
    % h = controllib.chart.InitialPlot("SystemModels",{rss(3,2,2),rss(3,2,2)},"SystemNames",["G","H"],"Axes",gca);
    % h = controllib.chart.InitialPlot("SystemModels",{rss(3,2,2)},"SystemNames","G","Parent",gcf);
    % h = controllib.chart.InitialPlot("NOutputs",2,"OutputLabels",["y1","y2"]);
    % h = controllib.chart.InitialPlot("NOutputs",2);
    %
    %   Example:
    %
    %   sysG = rss(3,2,2);
    %   sysH = rss(3,2,2);
    %   f = figure;
    %   ax = axes(f);
    %   ax.Position = [0.1 0.1 0.5 0.5];
    %   h = controllib.chart.InitialPlot("SystemModels",{sysG,sysH},"SystemNames",["G","H"],"Axes",ax);

    %   Copyright 2023-2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent, AbortSet, SetObservable)
        TimeUnit
        Normalize
    end

    properties (Dependent,Access=private)
        SettlingTimeThreshold
    end

    properties (GetAccess=protected,SetAccess=private)
        TimeUnit_I = "seconds"
        Normalize_I         = matlab.lang.OnOffSwitchState(false)
        InputVisible_I      = matlab.lang.OnOffSwitchState(true)

        SettlingTimeThreshold_I = controllib.chart.InitialPlot.createDefaultOptions().SettleTimeThreshold
    end

    properties (Access = protected,Transient,NonCopyable)
        NormalizeMenu
        InitialStateMenu
        TimeResponseWidget
        
        InitialStateDialog
        SpecifyTimeDialog
        SpecifyTimeMenu
    end

    %% Events
    events
        TimeChanged
    end
    
    %% Constructor/destructor
    methods
        function this = InitialPlot(initialPlotInputs,outputPlotArguments)
            arguments
                initialPlotInputs.Options (1,1) plotopts.TimeOptions = controllib.chart.InitialPlot.createDefaultOptions()
                outputPlotArguments.?controllib.chart.internal.foundation.AbstractPlotOptionalInputs
            end
            % Set up complex time plot mixin
            this@controllib.chart.internal.foundation.MixInTimeComplexPlot(initialPlotInputs.Options.ComplexViewType);
            % Extract name-value inputs for AbstractPlot
            outputPlotArguments = namedargs2cell(outputPlotArguments);
            this@controllib.chart.internal.foundation.OutputPlot(outputPlotArguments{:},...
                Options=initialPlotInputs.Options);
        end

        function delete(this)
            delete@controllib.chart.internal.foundation.OutputPlot(this);
            delete(this.InitialStateDialog);
            delete(this.SpecifyTimeDialog);
        end
    end

    %% Public methods
    methods
        function addResponse(this,model,initialState,time,parameter,optionalInputs,optionalStyleInputs)
            % addResponse adds the initial response to the chart
            %
            %   addResponse(h,sys,x0)
            %       adds the initial response of "sys" with initial states
            %       "x0" to the chart "h"
            %
            %   addResponse(h,sys,x0,t)
            %   addResponse(h,sys,x0,t,p)
            %       x0              vector
            %       t               [] (default) | scalar | vector
            %       p               [] (default) | vector | function_handle
            %
            %   addResponse(h,_______,Name=Value)
            %       Name            "untitled1" (default) | scalar | vector
            %       LineStyle       "-" (default) | "--" | ":" | "-." | "none"
            %       Color           [0 0.4470 0.7410] (default) | RGB triplet | hexadecimal color code | "r" | "g" | "b" | ... 
            %       MarkerStyle     "none" (default) | "o" | "+" | "*" | "." | ...
            %       LineWidth       0.5 (default) | positive value

            arguments
                this (1,1) controllib.chart.InitialPlot
                model DynamicSystem
                initialState
                time (:,1) = []
                parameter = []
                optionalInputs.Name (1,1) string = ""
                optionalStyleInputs.?controllib.chart.internal.options.AddResponseStyleOptionalInputs
            end

            % Define Name
            if strcmp(optionalInputs.Name,"")
                optionalInputs.Name = string(inputname(2));
            end

            % Create InitialResponse
            % Get next and name
            if isempty(optionalInputs.Name) || strcmp(optionalInputs.Name,"")
                name = getNextSystemName(this);
            else
                name = optionalInputs.Name;
            end

            if isnumeric(initialState)
                initialState = RespConfig(InitialState=initialState);
            end

            % Create InitialResponse
            newResponse = createResponse_(this,model,name,time,parameter,initialState);
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
                this (1,1) controllib.chart.InitialPlot
                propertyName string {mustBeScalarOrEmpty,validateOptionPropertyName(this,propertyName)} = string.empty
            end
            if isempty(propertyName)
                options = getoptions@controllib.chart.internal.foundation.OutputPlot(this);
                options.TimeUnits = char(this.TimeUnit);
                options.Normalize = char(this.Normalize);

                options.SettleTimeThreshold = this.SettlingTimeThreshold;
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
                        options = this.createDefaultOptions().ConfidenceRegionNumberSD;
                    otherwise
                        options = getoptions@controllib.chart.internal.foundation.OutputPlot(this,propertyName);
                end
            end
        end

        %setoptions
        function setoptions(this,options,nameValueInputs)
            arguments
                this (1,1) controllib.chart.InitialPlot
                options (1,1) plotopts.TimeOptions = getoptions(this)
                nameValueInputs.?plotopts.TimeOptions
            end

            options = copy(options);
            
            % Update options with name-value inputs
            nameValueInputsCell = namedargs2cell(nameValueInputs);
            if ~isempty(nameValueInputsCell)
                set(options,nameValueInputsCell{:});
            end
            
            % ComplexViewType
            this.ComplexViewType = options.ComplexViewType;
            
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

            % Set characteristic options
            this.SettlingTimeThreshold = options.SettleTimeThreshold;

            % Call base class for limits, style
            setoptions@controllib.chart.internal.foundation.OutputPlot(this,options);
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
                this (1,1) controllib.chart.InitialPlot
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
        end

        % Normalize
        function Normalize = get.Normalize(this)
            Normalize = matlab.lang.OnOffSwitchState(this.Normalize_I);
        end

        function set.Normalize(this,Normalize)
            arguments
                this (1,1) controllib.chart.InitialPlot
                Normalize (1,1) matlab.lang.OnOffSwitchState
            end
            this.Normalize_I = Normalize;

            if ~isempty(this.TimeView) && isvalid(this.TimeView)
                disableListeners(this,"YLimitsChangedinAxesGrid")
                this.TimeView.Normalize = Normalize;
                enableListeners(this,"YLimitsChangedinAxesGrid")
            end
        end

        % SettlingTimeThreshold
        function SettlingTimeThreshold = get.SettlingTimeThreshold(this)
            SettlingTimeThreshold = this.SettlingTimeThreshold_I;
        end

        function set.SettlingTimeThreshold(this,SettlingTimeThreshold)
            arguments
                this (1,1) controllib.chart.InitialPlot
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
            initialize@controllib.chart.internal.foundation.OutputPlot(this);
            this.Type = 'initial';
            this.SynchronizeResponseUpdates = true;
            build(this);
        end

        function response = createResponse_(~,model,name,time,parameter,config)
            % Create system
            response = controllib.chart.response.InitialResponse(model,...
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
            end
        end

        function applyCharacteristicOptionsToResponse(this,response)
            response.SettlingTimeThreshold = this.SettlingTimeThreshold;
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

                arrayVisible(ka) = any(isPeakResponseWithinBounds(:) & ...
                                       isTransientTimeWithinBounds(:));

            end
            response.ArrayVisible = arrayVisible;
        end

        function updateTransientTime(this,value)
            arguments
                this (1,1) controllib.chart.InitialPlot
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
                view = controllib.chart.internal.view.axes.InitialAxesView(this,...
                    InitializeUsingView=viewForInitialization);
            else
                view = controllib.chart.internal.view.axes.InitialAxesView(this);
            end
        end

        function view = createPolarView(this,viewForInitialization)
            if nargin > 1
                view = controllib.chart.internal.view.axes.TimePhasorOutputAxesView(this,...
                                InitializeUsingView=viewForInitialization);
            else
                view = controllib.chart.internal.view.axes.TimePhasorOutputAxesView(this);
            end
        end

        function view = createMagnitudePhaseView(this,viewForInitialization)
            if nargin > 1
                view = controllib.chart.internal.view.axes.TimeMagnitudePhaseOutputAxesView(this,...
                                InitializeUsingView=viewForInitialization);
            else
                view = controllib.chart.internal.view.axes.TimeMagnitudePhaseOutputAxesView(this);
            end
        end

        function view = getActiveView(this)
            view = this.View;
        end

        function setActiveView(this,view)
            this.View = view;
        end

        % Context menu
        function createContextMenu(this)
            createContextMenu@controllib.chart.internal.foundation.OutputPlot(this);

            this.NormalizeMenu = uimenu(Parent=[],...
                Text=getString(message('Controllib:plots:strNormalize')),...
                Tag="normalize",...
                Checked=logical(this.Normalize),...
                MenuSelectedFcn=@(es,ed) set(this,Normalize=~this.Normalize));
            addMenu(this,this.NormalizeMenu,Above='fullview',CreateNewSection=false);

            this.InitialStateMenu = uimenu(Parent=[],...
                Text=getString(message('Controllib:plots:strInitialConditionLabel')),...
                Tag='initialstate',...
                Separator='on',...
                MenuSelectedFcn=@(es,ed) openInitialStateDialog(this));
            addMenu(this,this.InitialStateMenu,Above='propertyeditor',CreateNewSection=false);

            this.SpecifyTimeMenu = uimenu(Parent=[],...
                Text=[getString(message('Controllib:plots:strSpecifyTime')),'...'],...
                Tag="specifytime",...
                MenuSelectedFcn=@(es,ed) openSpecifyTimeDialog(this));
            addMenu(this,this.SpecifyTimeMenu,Above='propertyeditor',CreateNewSection=false);

            createComplexViewContextMenu(this);
        end

        function cbContextMenuOpening(this)
            % Update state of menu items dynamically when context menu is opened
            cbContextMenuOpening@controllib.chart.internal.foundation.OutputPlot(this);
            this.NormalizeMenu.Checked = this.Normalize;
            this.InitialStateMenu.Visible = ~isempty(this.Responses);

            setComplexViewContextMenuOnOpen(this);
        end

        %% Property editor
        function buildOptionsTab(this)
            % Build layout
            layout = uigridlayout(Parent=[],RowHeight={'fit','fit'},ColumnWidth={'1x'},Padding=0);

            % Build Time Response widget and add to layout
            buildTimeResponseWidget(this);
            w = getWidget(this.TimeResponseWidget);
            w.Parent = layout;
            w.Layout.Row = 1;
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

        %% Initial state dialog
        function openInitialStateDialog(this)
            % Change pointer to busy
            fig = ancestor(this,'figure');
            if ~isempty(fig)
                currentPointer = fig.Pointer;
                fig.Pointer = 'watch';
            end
            if isempty(this.InitialStateDialog) || ~isvalid(this.InitialStateDialog)
                % Build initial state dialog and widgets if needed
                buildInitialStateDialog(this);
            end
            updateUI(this.InitialStateDialog);
            % Show property editor
            show(this.InitialStateDialog);
            % Change pointer back
            if ~isempty(fig)
                fig.Pointer = currentPointer;
            end
        end

        function buildInitialStateDialog(this)
            data = controllib.chart.internal.widget.lsim.LinearSimulationData(this);
            this.InitialStateDialog = controllib.chart.internal.widget.lsim.LinearSimulationDialog(data,'initial');

            % Add listeners for data to widget
            registerListeners(this,...
                addlistener(this.InitialStateDialog,'SimulateButtonPushed',@(es,ed) cbSimulationButton(this,es,ed)),...
                'SimulateButtonPushed');

            matlab.graphics.internal.drawnow.startUpdate;

            function cbSimulationButton(this,es,~)
                % Process initial states
                es.Updating = true;
                for ii=1:es.Data.NumSystems
                    this.Responses(ii).InitialState = es.Data.InitialStates{ii};
                end
                es.Updating = false;
            end
        end

        function cbResponseDeleted(this)
            if ~isempty(this.InitialStateDialog) && isvalid(this.InitialStateDialog)
                idx = ~isvalid(this.Responses);
                removeResponse(this.InitialStateDialog.Data,idx);
                updateUI(this.InitialStateDialog);
            end
            cbResponseDeleted@controllib.chart.internal.foundation.OutputPlot(this);
        end

        function cbResponseChanged(this,response)
            cbResponseChanged@controllib.chart.internal.foundation.OutputPlot(this,response);
            if ~isempty(this.InitialStateDialog) && isvalid(this.InitialStateDialog) && ~this.InitialStateDialog.Updating
                idx = find(this.Responses==response,1);
                updateResponse(this.InitialStateDialog.Data,idx);
                updateUI(this.InitialStateDialog);
            end
        end

        function buildTimeResponseWidget(this)
            % Build Time Response widget
            this.TimeResponseWidget = controllib.widget.internal.cstprefs.TimeResponseContainer(ShowRiseTime=false);

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
            storedProperties.OutputGrouping = chart.OutputGrouping;
            storedProperties.OutputVisible = chart.OutputVisible;
        end

        function applyStoredPropertiesAfterViewSwitch(this,storedProperties)
            controllib.chart.internal.foundation.MixInTimeComplexPlot.applyStoredPropertiesAfterViewSwitch(this,storedProperties);
            this.OutputGrouping = storedProperties.OutputGrouping;
            this.OutputVisible = storedProperties.OutputVisible;
        end
    end

    %% Static hidden methods
    methods (Static,Hidden)
        function options = createDefaultOptions()
            options = timeoptions('cstprefs');
            options.Title.String = getString(message('Controllib:plots:strResponseToInitialConditions'));
        end
    end

    %% Hidden methods
    methods (Hidden)
        function registerResponse(this,newResponse,newResponseView)
            arguments
                this (1,1) controllib.chart.InitialPlot
                newResponse (1,1) controllib.chart.internal.foundation.BaseResponse
                newResponseView controllib.chart.internal.view.wave.BaseResponseView = ...
                    controllib.chart.internal.view.wave.BaseResponseView.empty
            end
            registerResponse@controllib.chart.internal.foundation.OutputPlot(this,newResponse,newResponseView);
            if ~isempty(this.InitialStateDialog) && isvalid(this.InitialStateDialog)
                addResponses(this.InitialStateDialog.Data,newResponse);
                updateUI(this.InitialStateDialog);
            end
        end

        function widgets = qeGetPropertyEditorWidgets(this)
            widgets = qeGetPropertyEditorWidgets@controllib.chart.internal.foundation.OutputPlot(this);
            widgets.TimeResponseWidget = this.TimeResponseWidget;
        end

        function dlg = qeOpenInitialStateDialog(this)
            openInitialStateDialog(this);
            dlg = this.InitialStateDialog;
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
                view = controllib.chart.internal.view.axes.TimePhasorOutputAxesView(this);
                setAxesGrid(view,axesGrid);
                build(view);
                % Set default limits and label configuration
                view.XLimitsSharing = "all";
                view.XLimitsMode = "auto";
                view.YLimitsSharing = "none";
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
                view = controllib.chart.internal.view.axes.InitialAxesView(this);
                setAxesGrid(view,axesGrid);
                build(view);
                % Set default limits and label configuration
                view.XLimitsSharing = "all";
                view.XLimitsMode = "auto";
                view.YLimitsSharing = "none";
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