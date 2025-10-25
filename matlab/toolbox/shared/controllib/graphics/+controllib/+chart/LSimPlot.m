classdef LSimPlot < controllib.chart.internal.foundation.OutputPlot & ...
                    controllib.chart.internal.foundation.MixInTimeComplexPlot
    % Construct an LSimPlot.
    %
    % h = controllib.chart.LSimPlot("SystemModels",{rss(3,2,2),rss(3,2,2)},"SystemNames",["G","H"],"Axes",gca);
    % h = controllib.chart.LSimPlot("SystemModels",{rss(3,2,2)},"SystemNames","G","Parent",gcf);
    % h = controllib.chart.LSimPlot("NOutputs",2,"OutputLabels",["y1","y2"]);
    % h = controllib.chart.LSimPlot("NOutputs",2);
    %
    %   Example:
    %
    %   sysG = rss(3,2,2);
    %   sysH = rss(3,2,2);
    %   f = figure;
    %   ax = axes(f);
    %   ax.Position = [0.1 0.1 0.5 0.5];
    %   h = controllib.chart.LSimPlot("SystemModels",{sysG,sysH},"SystemNames",["G","H"],"Axes",ax);

    %   Copyright 2023 The MathWorks, Inc.

    %% Properties
    properties (Dependent, AbortSet, SetObservable)
        TimeUnit
        Normalize
        InputVisible
    end

    properties (GetAccess=protected,SetAccess=private)
        TimeUnit_I = "seconds"
        Normalize_I         = matlab.lang.OnOffSwitchState(false)
        InputVisible_I      = matlab.lang.OnOffSwitchState(true)
    end

    properties (Access = protected,Transient,NonCopyable)
        NormalizeMenu
        InputDataMenu
        InputVisibleMenu
        InitialStateMenu

        LinearSimulationDialog
    end

    %% Constructor/destructor
    methods
        function this = LSimPlot(lsimPlotInputs,outputPlotArguments)
            arguments
                lsimPlotInputs.Options (1,1) plotopts.TimeOptions = controllib.chart.LSimPlot.createDefaultOptions()
                outputPlotArguments.?controllib.chart.internal.foundation.AbstractPlotOptionalInputs
            end
            % Extract name-value inputs for AbstractPlot
            this@controllib.chart.internal.foundation.MixInTimeComplexPlot(lsimPlotInputs.Options.ComplexViewType);
            outputPlotArguments = namedargs2cell(outputPlotArguments);
            this@controllib.chart.internal.foundation.OutputPlot(outputPlotArguments{:},...
                Options=lsimPlotInputs.Options);
        end

        function delete(this)
            delete@controllib.chart.internal.foundation.OutputPlot(this);
            delete(this.LinearSimulationDialog);
        end
    end

    %% Public methods
    methods
        function addResponse(this,model,inputSignal,time,config,parameter,optionalInputs,optionalStyleInputs)
            % addResponse adds the lsim response to the chart
            %
            %   addResponse(h,sys)
            %       adds the lsim response of "sys" to the chart "h"
            %
            %   addResponse(h,sys,u,t)
            %   addResponse(h,sys,u,t,x0)
            %   addResponse(h,sys,u,t,x0,p)
            %       u                   vector | matrix
            %       t                   [] (default) | scalar | vector
            %       p                   [] (default) | vector | function_handle
            %       x0                  [] (default) | vector
            %
            %   addResponse(h,_______,Name=Value)            
            %       InterpolationMethod 'auto' (default) | 'zoh' | 'foh'            
            %       Name                "untitled1" (default) | scalar | vector
            %       LineStyle           "-" (default) | "--" | ":" | "-." | "none"
            %       Color               [0 0.4470 0.7410] (default) | RGB triplet | hexadecimal color code | "r" | "g" | "b" | ... 
            %       MarkerStyle         "none" (default) | "o" | "+" | "*" | "." | ...
            %       LineWidth           0.5 (default) | positive value

            arguments
                this (1,1) controllib.chart.LSimPlot
                model DynamicSystem
                inputSignal (:,:) double
                time (:,1) double = []
                config = []
                parameter = []
                optionalInputs.InterpolationMethod (1,1) string {mustBeMember(optionalInputs.InterpolationMethod,["auto","zoh","foh"])} = "auto"
                optionalInputs.Name (1,1) string = ""
                optionalStyleInputs.?controllib.chart.internal.options.AddResponseStyleOptionalInputs
            end
            
            % Define Name
            if strcmp(optionalInputs.Name,"")
                optionalInputs.Name = string(inputname(2));
            end

            % Create LSimResponse
            % Get next name
            if isempty(optionalInputs.Name) || strcmp(optionalInputs.Name,"")
                name = getNextSystemName(this);
            else
                name = optionalInputs.Name;
            end

            if ~isempty(config) && isnumeric(config)
                config = RespConfig(InitialState=config);
            end
            
            % Create LSimResponse
            newResponse = createResponse_(this,model,name,time,inputSignal,...
                optionalInputs.InterpolationMethod,parameter,config);
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
                this (1,1) controllib.chart.LSimPlot
                propertyName string {mustBeScalarOrEmpty,validateOptionPropertyName(this,propertyName)} = string.empty
            end
            if isempty(propertyName)
                options = getoptions@controllib.chart.internal.foundation.OutputPlot(this);
                options.TimeUnits = char(this.TimeUnit);
                options.Normalize = char(this.Normalize);
            else
                switch propertyName
                    case 'TimeUnits'
                        options = char(this.TimeUnit);
                    case 'Normalize'
                        options = char(this.Normalize);
                    case 'SettleTimeThreshold'
                        options = this.createDefaultOptions().SettleTimeThreshold;
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
                this (1,1) controllib.chart.LSimPlot
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
                this (1,1) controllib.chart.LSimPlot
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
                this (1,1) controllib.chart.LSimPlot
                Normalize (1,1) matlab.lang.OnOffSwitchState
            end
            this.Normalize_I = Normalize;

            if ~isempty(this.TimeView) && isvalid(this.TimeView)
                disableListeners(this,"YLimitsChangedinAxesGrid")
                this.TimeView.Normalize = Normalize;
                enableListeners(this,"YLimitsChangedinAxesGrid")
            end
        end

        % InputVisible
        function InputVisible = get.InputVisible(this)
            InputVisible = matlab.lang.OnOffSwitchState(this.InputVisible_I);
        end

        function set.InputVisible(this,InputVisible)
            arguments
                this (1,1) controllib.chart.LSimPlot
                InputVisible (1,1) matlab.lang.OnOffSwitchState
            end
            this.InputVisible_I = InputVisible;

            if ~isempty(this.View) && isvalid(this.View)
                this.View.InputVisible = InputVisible;
                updateFocus(this.View);
            end
        end
    end

    %% Protected methods
    methods (Access = protected)
        function initialize(this)
            initialize@controllib.chart.internal.foundation.OutputPlot(this);
            this.Type = 'lsim';
            this.SynchronizeResponseUpdates = true;
            build(this);
        end

        function response = createResponse_(~,model,name,time,inputSignal,interpolationMethod,parameter,...
                config)
            response = controllib.chart.response.LinearSimulationResponse(model,...
                Name=name,...
                Time=time,...
                InputSignal=inputSignal,...
                InterpolationMethod=interpolationMethod,...
                Parameter=parameter,...
                Config=config);
        end

        %% Characteristics
        function cm = createCharacteristicOptions_(~,charType)
            switch charType
                case "PeakResponse"
                    cm = controllib.chart.options.CharacteristicOption(...
                        MenuLabel=getString(message('Controllib:plots:strPeakResponse')),...
                        Visible=false);
            end
        end

        function [tags,labels] = getCharacteristicTagsToShowInArraySelector(this)
            tags = "PeakResponse";
            labels = [getCharacteristicOption(this,tags).MenuLabelText];
        end

        function updateArrayVisibilityUsingCharacteristicBounds(this)
            idx = find([this.Responses.Name]==this.ArraySelectorDialog.SelectedSystem);
            response = this.Responses(idx);
            data = response.ResponseData;

            arrayVisible = false(size(this.Responses(idx).ArrayVisible));
            for ka = 1:response.NResponses
                compute(data.PeakResponse);

                isPeakResponseWithinBounds = isCharacteristicWithinBounds(this.ArraySelectorDialog,...
                    "PeakResponse",data.PeakResponse.Value{ka});
                arrayVisible(ka) = isPeakResponseWithinBounds(:);
            end
            response.ArrayVisible = arrayVisible;
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
                view = controllib.chart.internal.view.axes.SimulationAxesView(this,...
                    InitializeUsingView=viewForInitialization);
            else
                view = controllib.chart.internal.view.axes.SimulationAxesView(this);
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
                view = controllib.chart.internal.view.axes.SimulationMagnitudePhaseAxesView(this,...
                                InitializeUsingView=viewForInitialization);
            else
                view = controllib.chart.internal.view.axes.SimulationMagnitudePhaseAxesView(this);
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

            this.InputVisibleMenu = uimenu(Parent=[],...
                Text=getString(message('Controllib:plots:strShowInput')),...
                Tag='inputvisible',...
                Checked=logical(this.InputVisible),...
                MenuSelectedFcn=@(es,ed) set(this,InputVisible=~this.InputVisible));
            addMenu(this,this.InputVisibleMenu,Above='rowgrouping',CreateNewSection=true);

            this.InputDataMenu = uimenu(Parent=[],...
                Text=getString(message('Controllib:plots:strInputDataLabel')),...
                Tag='inputdata',...
                Separator='on',...
                MenuSelectedFcn=@(es,ed) openLinearSimulationDialog(this,'inputData'));
            addMenu(this,this.InputDataMenu,Above='propertyeditor',CreateNewSection=false);

            this.InitialStateMenu = uimenu(Parent=[],...
                Text=getString(message('Controllib:plots:strInitialConditionLabel')),...
                Tag='initialstate',...
                MenuSelectedFcn=@(es,ed) openLinearSimulationDialog(this,'initialCondition'));
            addMenu(this,this.InitialStateMenu,Above='propertyeditor',CreateNewSection=false);

            createComplexViewContextMenu(this);
        end

        function cbContextMenuOpening(this)
            % Update state of menu items dynamically when context menu is opened
            cbContextMenuOpening@controllib.chart.internal.foundation.OutputPlot(this);
            this.InputVisibleMenu.Checked = this.InputVisible;
            this.NormalizeMenu.Checked = this.Normalize;
            this.InputDataMenu.Visible = ~isempty(this.Responses);
            this.InitialStateMenu.Visible = ~isempty(this.Responses);

            setComplexViewContextMenuOnOpen(this);
        end

        %% Property editor
        function buildOptionsTab(this)
            % Build layout
            layout = uigridlayout(Parent=[],RowHeight={'fit','fit'},ColumnWidth={'1x'},Padding=0);

            % Build Time Response widget and add to layout
            label = uilabel(layout,'Text',getString(message('Controllib:gui:strNoOptionsForSelectedPlot')));
            label.Layout.Row = 2;
            label.Layout.Column = 1;

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

        %% Linear simulation dialog
        function openLinearSimulationDialog(this,tab)
            arguments
                this (1,1) controllib.chart.LSimPlot
                tab (1,1) string {mustBeMember(tab,["initialCondition","inputData"])}
            end
            % Change pointer to busy
            fig = ancestor(this,'figure');
            if ~isempty(fig)
                currentPointer = fig.Pointer;
                fig.Pointer = 'watch';
            end
            if isempty(this.LinearSimulationDialog) || ~isvalid(this.LinearSimulationDialog)
                % Build linear simulation dialog and widgets if needed
                buildLinearSimulationDialog(this);
            end
            updateUI(this.LinearSimulationDialog);
            selectTab(this.LinearSimulationDialog,tab);
            % Show property editor
            show(this.LinearSimulationDialog);
            % Change pointer back
            if ~isempty(fig)
                fig.Pointer = currentPointer;
            end
        end

        function buildLinearSimulationDialog(this)
            data = controllib.chart.internal.widget.lsim.LinearSimulationData(this);
            this.LinearSimulationDialog = controllib.chart.internal.widget.lsim.LinearSimulationDialog(data,'lsim');
            % Add listeners for data to widget
            registerListeners(this,...
                addlistener(this.LinearSimulationDialog,'SimulateButtonPushed',@(es,ed) cbSimulationButton(this,es,ed)),...
                'SimulateButtonPushed');

            matlab.graphics.internal.drawnow.startUpdate;

            function cbSimulationButton(this,es,~)
                % Process input table
                es.Updating = true;
                numSamples = es.Data.SimulationSamples;
                T = cell(es.Data.NumSystems,1);
                X = cell(es.Data.NumSystems,1);
                for ii = 1:es.Data.NumSystems
                    if numSamples(ii) > 0 && es.Data.Intervals(ii) > 0
                        % Time vector
                        T{ii} = (0:(numSamples(ii)-1))*es.Data.Intervals(ii)+es.Data.StartTimes(ii);

                        % Input vectors
                        inputSignals = es.Data.getInputSignals(ii);
                        numInputs = length(inputSignals);

                        % Create input matrix as a cell array
                        X{ii} = cell(1,numInputs);
                        for k=1:numInputs
                            rawdata = inputSignals(k).Value(:,inputSignals(k).Column);
                            if ~isempty(rawdata)
                                X{ii}{k} = rawdata(inputSignals(k).Interval(1):inputSignals(k).Interval(2));
                            else
                                X{ii}{k} = [];
                            end
                        end

                        % Error if there are insufficient inputs
                        if numInputs < this.Responses(ii).NInputs
                            uiconfirm(getWidget(es),...
                                getString(message('Controllib:gui:LsimIncompleteInputSetSystem',this.Responses(ii).Name)),...
                                getString(message('Controllib:gui:strLinearSimulationTool')),...
                                'Icon','error');
                            return
                        end

                        % Error if inputs do not have sufficient length
                        numSamples(ii) = min(numSamples(ii), min(cellfun(@length,X{ii})));
                        if numSamples(ii)<2
                            uiconfirm(getWidget(es),...
                                getString(message('Controllib:gui:LsimMinSamplesSystem',this.Responses(ii).Name)),...
                                getString(message('Controllib:gui:strLinearSimulationTool')),...
                                'Icon','error');
                            return
                        elseif numSamples(ii)<length(T{ii})
                            uiconfirm(getWidget(es),...
                                getString(message('Controllib:gui:LsimInsufficientInputSamples',this.Responses(ii).Name,length(T{ii}))),...
                                getString(message('Controllib:gui:strLinearSimulationTool')),...
                                'Icon','error');
                            return
                        end
                    else
                        uiconfirm(getWidget(es),...
                            getString(message('Controllib:gui:LsimInvalidTimeIntervalSystem',this.Responses(ii).Name)), ...
                            getString(message('Controllib:gui:strLinearSimulationTool')),...
                            'Icon','error');
                        return
                    end
                end
                
                % Update systems with the specified inputs
                for ii = 1:es.Data.NumSystems
                    time = T{ii}(:);
                    inputCells = X{ii};
                    input = zeros(numSamples(ii),length(inputCells));
                    for jj = 1:length(inputCells)
                        input(:,jj) = inputCells{jj}(1:numSamples(ii));
                    end
                    interpolation = es.Data.Interpolations{ii};
                    initialState = es.Data.InitialStates{ii};
                    this.Responses(ii).SourceData.Time = time;
                    this.Responses(ii).SourceData.InputSignal = input;
                    this.Responses(ii).SourceData.InterpolationMethod = interpolation;
                    this.Responses(ii).InitialState = initialState;
                end                
                es.Updating = false;
            end
        end

        function cbResponseDeleted(this)
            if ~isempty(this.LinearSimulationDialog) && isvalid(this.LinearSimulationDialog)
                idx = ~isvalid(this.Responses);
                removeResponse(this.LinearSimulationDialog.Data,idx);
                updateUI(this.LinearSimulationDialog);
            end
            cbResponseDeleted@controllib.chart.internal.foundation.OutputPlot(this);
        end

        function cbResponseChanged(this,response)
            cbResponseChanged@controllib.chart.internal.foundation.OutputPlot(this,response);
            if ~isempty(this.LinearSimulationDialog) && isvalid(this.LinearSimulationDialog) && ~this.LinearSimulationDialog.Updating
                idx = find(this.Responses==response,1);
                updateResponse(this.LinearSimulationDialog.Data,idx);
                updateUI(this.LinearSimulationDialog);
            end
        end

        function names = getCustomPropertyGroupNames(this)
            names = ["TimeUnit","Normalize","InputVisible"];
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
            options.Title.String = getString(message('Controllib:plots:strLinearSimulationResults'));
        end
    end

    %% Hidden methods
    methods (Hidden)
        function registerResponse(this,newResponse,newResponseView)
            arguments
                this (1,1) controllib.chart.LSimPlot
                newResponse (1,1) controllib.chart.internal.foundation.BaseResponse
                newResponseView controllib.chart.internal.view.wave.BaseResponseView = ...
                    controllib.chart.internal.view.wave.BaseResponseView.empty
            end
            registerResponse@controllib.chart.internal.foundation.OutputPlot(this,newResponse,newResponseView);
            if ~isempty(this.LinearSimulationDialog) && isvalid(this.LinearSimulationDialog)
                addResponses(this.LinearSimulationDialog.Data,newResponse);
                updateUI(this.LinearSimulationDialog);
            end
            % Open lsimgui if input not specified
            if (isempty(this.Responses(end).SourceData.InputSignal) || isempty(this.Responses(end).SourceData.Time))
                openLinearSimulationDialog(this,'inputData');
                this.LinearSimulationDialog.SelectedSystem = length(this.Responses);
            end
        end
        
        function dlg = qeGetLinearSimulationDialog(this)
            dlg = this.LinearSimulationDialog;
        end

        function dlg = qeOpenLinearSimulationDialog(this)
            openLinearSimulationDialog(this,"inputData");
            dlg = this.LinearSimulationDialog;
        end
    end
end