classdef TimeSingleColumnPlot < controllib.chart.internal.foundation.SingleColumnPlot & ...
                                controllib.chart.internal.foundation.MixInTimeUnit
    % TimeSingleColumnPlot

    %   Copyright 2023-2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent, SetObservable, AbortSet)
        Normalize
    end

    properties (GetAccess=protected,SetAccess=private)
        Normalize_I = matlab.lang.OnOffSwitchState(false)
    end

    properties (Access = protected,Transient,NonCopyable)
        NormalizeMenu
    end

    %% Constructor
    methods
        function this = TimeSingleColumnPlot(optionalInputs,abstractPlotArguments)
            arguments
                optionalInputs.Options (1,1) plotopts.TimeOptions = controllib.chart.internal.foundation.TimeSingleColumnPlot.createDefaultOptions()
                abstractPlotArguments.?controllib.chart.internal.foundation.AbstractPlotOptionalInputs
            end
            singleColumnPlotArguments = namedargs2cell(optionalInputs);
            abstractPlotArguments = namedargs2cell(abstractPlotArguments);
            this@controllib.chart.internal.foundation.SingleColumnPlot(singleColumnPlotArguments{:},...
                abstractPlotArguments{:});
            this@controllib.chart.internal.foundation.MixInTimeUnit(optionalInputs.Options.TimeUnits);
        end
    end

    %% Public methods
    methods
        function options = getoptions(this,propertyName)
            % getoptions: Get options object or specific option.
            %
            %   options = getoptions(h)
            %   optionValue = getoptions(h,optionName)
            arguments
                this (1,1) controllib.chart.internal.foundation.TimeSingleColumnPlot
                propertyName string {mustBeScalarOrEmpty,validateOptionPropertyName(this,propertyName)} = string.empty
            end
            if isempty(propertyName)
                options = getoptions@controllib.chart.internal.foundation.SingleColumnPlot(this);
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
                        options = getoptions@controllib.chart.internal.foundation.SingleColumnPlot(this,propertyName);
                end
            end
        end

        %setoptions
        function setoptions(this,options,nameValueInputs)
            arguments
                this (1,1) controllib.chart.internal.foundation.TimeSingleColumnPlot
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

            % Call base class for limits, style
            setoptions@controllib.chart.internal.foundation.SingleColumnPlot(this,options);
        end
    end

    %% Get/Set methods
    methods
        % Normalize
        function Normalize = get.Normalize(this)
            Normalize = this.Normalize_I;
        end

        function set.Normalize(this,Normalize)
            arguments
                this (1,1) controllib.chart.internal.foundation.TimeSingleColumnPlot
                Normalize (1,1) matlab.lang.OnOffSwitchState
            end
            this.Normalize_I = Normalize;

            if ~isempty(this.View) && isvalid(this.View)
                disableListeners(this,"YLimitsChangedinAxesGrid")
                this.View.Normalize = Normalize;
                enableListeners(this,"YLimitsChangedinAxesGrid")
            end
        end
    end

    %% Protected methods
    methods (Access = protected)
        function initialize(this)
            initialize@controllib.chart.internal.foundation.SingleColumnPlot(this);
            this.Type = 'timesinglecolumn';
        end

        %% View
        function view = createView_(this)
            view = controllib.chart.internal.view.axes.TimeSingleColumnAxesView(this);
        end

        function cbTimeUnitChanged(this,~)
            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.TimeUnit = this.TimeUnit;
            end

            % Modify property editor widgets
            if ~isempty(this.UnitsWidget) && isvalid(this.UnitsWidget)
                this.UnitsWidget.TimeUnits = this.TimeUnit;
            end
        end

        %% Context menu
        function createContextMenu(this)
            createContextMenu@controllib.chart.internal.foundation.SingleColumnPlot(this);
            
            this.NormalizeMenu = uimenu(Parent=[],...
                Text=getString(message('Controllib:plots:strNormalize')),...
                Tag="normalize",...
                Checked=logical(this.Normalize),...
                MenuSelectedFcn=@(es,ed) set(this,Normalize=~this.Normalize));
            addMenu(this,this.NormalizeMenu,Above='fullview',CreateNewSection=false);
        end

        function cbContextMenuOpening(this)
            % Update state of menu items dynamically when context menu is opened
            cbContextMenuOpening@controllib.chart.internal.foundation.SingleColumnPlot(this);
            this.NormalizeMenu.Checked = this.Normalize;
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

            % Add listeners for widget to data
            registerListeners(this,...
                addlistener(this.UnitsWidget,'TimeUnits','PostSet',@(es,ed) cbTimeUnitChangedInPropertyEditor(this,ed)),...
                'TimeUnitChangedInPropertyEditor');

            % Local callback functions
            function cbTimeUnitChangedInPropertyEditor(this,ed)
                this.TimeUnit = ed.AffectedObject.TimeUnits;
            end
        end

        function updateUnitsWidget(this)
            if ~isempty(this.UnitsWidget) && isvalid(this.UnitsWidget)
                this.UnitsWidget.TimeUnits = this.TimeUnit;
            end
        end

        function names = getCustomPropertyGroupNames(this)
            names = ["TimeUnit","Normalize"];
        end
    end

    %% Static hidden methods
    methods (Static,Hidden)
        function options = createDefaultOptions()
            options = timeoptions('cstprefs');
            options.TimeUnits = 'seconds';
        end
    end
end