classdef (Abstract, ConstructOnLoad, AllowedSubclasses={?matlab.graphics.chart.PieChart,?matlab.graphics.chart.DonutChart}) ...
        AbstractPieChart < matlab.graphics.chartcontainer.ChartContainer & ...
        matlab.graphics.mixin.DataProperties
    %

    %   Copyright 2023-2024 The MathWorks, Inc.

    properties (Dependent, Resettable=false)
        Data (1,:)
        Names (1,:) string = string.empty(1,0)
        DataVariable = ""
        NamesVariable = ""
    end
    properties (Dependent, UsedInUpdate=false, Resettable=false)
        Labels (1,:) string = string.empty(1,0)
        LabelStyle matlab.internal.datatype.matlab.graphics.datatype.PieChartLabelStyle = 'none'
        StartAngle matlab.internal.datatype.matlab.graphics.datatype.RealWithNoInfs = 0
        Direction matlab.internal.datatype.matlab.graphics.datatype.ClockDirection = 'clockwise'

        ExplodedWedges (1,:) = []

        ColorOrder matlab.internal.datatype.matlab.graphics.datatype.ColorOrder = get(groot,'FactoryAxesColorOrder')
        FaceColor matlab.internal.datatype.matlab.graphics.datatype.RGBFlatNoneColor = 'flat'
        EdgeColor matlab.internal.datatype.matlab.graphics.datatype.RGBFlatNoneColor = get(groot, 'FactoryAxesXColor')
        FaceAlpha matlab.internal.datatype.matlab.graphics.datatype.ZeroToOne = 0.6
        LineWidth matlab.internal.datatype.matlab.graphics.datatype.Positive = .5

        FontSize matlab.internal.datatype.matlab.graphics.datatype.Positive = get(groot, 'FactoryAxesFontSize')
        FontName matlab.internal.datatype.matlab.graphics.datatype.FontName = get(groot, 'FactoryAxesFontName')
        FontColor matlab.internal.datatype.matlab.graphics.datatype.RGBAColor = get(groot, 'FactoryAxesXColor')
        Interpreter matlab.internal.datatype.matlab.graphics.datatype.TextInterpreter = 'tex'

        LegendVisible matlab.lang.OnOffSwitchState = matlab.lang.OnOffSwitchState.off
        LegendTitle matlab.internal.datatype.matlab.graphics.datatype.NumericOrString = ""
        Title matlab.internal.datatype.matlab.graphics.datatype.NumericOrString = ''

        DisplayOrder matlab.internal.datatype.matlab.graphics.datatype.CategoryOrder = "data"
        NumDisplayWedges (1,1) {mustBeOneToInfInteger(NumDisplayWedges)} = Inf
        ShowOthers matlab.internal.datatype.matlab.graphics.datatype.on_off = 'on'
    end

    % Read-only user facing properties
    properties (SetAccess=protected, Dependent, UsedInUpdate=false, Resettable=false)
        Proportions (1,:)
        CategoryCounts
        WedgeDisplayData
        WedgeDisplayNames
    end

    % Underbar_I properties
    properties (Hidden, AbortSet)
        Data_I (1,:) = []
        Names_I (1,:) string = string.empty(1,0)
        Labels_I (1,:) string = string.empty(1,0)
        LabelStyle_I matlab.internal.datatype.matlab.graphics.datatype.PieChartLabelStyle = 'none'

        DataVariable_I = ""
        NamesVariable_I = ""

        StartAngle_I matlab.internal.datatype.matlab.graphics.datatype.RealWithNoInfs = 0 % degrees, default is 12 o'clock noon
        Direction_I matlab.internal.datatype.matlab.graphics.datatype.ClockDirection = 'clockwise'
        ExplodedWedges_I (1,:) = []

        ColorOrder_I matlab.internal.datatype.matlab.graphics.datatype.ColorOrder = get(groot,'FactoryAxesColorOrder')
        FaceColor_I matlab.internal.datatype.matlab.graphics.datatype.RGBFlatNoneColor = 'flat'
        EdgeColor_I matlab.internal.datatype.matlab.graphics.datatype.RGBFlatNoneColor = get(groot, 'FactoryAxesXColor')
        FaceAlpha_I matlab.internal.datatype.matlab.graphics.datatype.ZeroToOne = 0.6
        LineWidth_I matlab.internal.datatype.matlab.graphics.datatype.Positive = .5

        FontSize_I matlab.internal.datatype.matlab.graphics.datatype.Positive = get(groot, 'FactoryAxesFontSize')
        FontName_I matlab.internal.datatype.matlab.graphics.datatype.FontName = get(groot, 'FactoryAxesFontName')
        FontColor_I matlab.internal.datatype.matlab.graphics.datatype.RGBAColor = get(groot, 'FactoryAxesXColor')
        Interpreter_I matlab.internal.datatype.matlab.graphics.datatype.TextInterpreter = 'tex'

        LegendVisible_I matlab.lang.OnOffSwitchState = matlab.lang.OnOffSwitchState.off
        LegendTitle_I matlab.internal.datatype.matlab.graphics.datatype.NumericOrString = ''
        Title_I matlab.internal.datatype.matlab.graphics.datatype.NumericOrString = ''

        DisplayOrder_I matlab.internal.datatype.matlab.graphics.datatype.CategoryOrder = "data"
        NumDisplayWedges_I (1,1) {mustBeOneToInfInteger(NumDisplayWedges_I)} = Inf
        ShowOthers_I matlab.internal.datatype.matlab.graphics.datatype.on_off = 'on'
    end

    % These properties are not user settable, so we do not need to
    % serialize their internal storage properties.
    properties (Transient, Hidden)
        Proportions_I (1,:) double
        CategoryCounts_I (1,:) double
        WedgeDisplayData_I (1,:)
        WedgeDisplayNames_I (1,:) string
        LegendFaceColor_I matlab.internal.datatype.matlab.graphics.datatype.RGBAColor = get(groot, 'FactoryAxesColor')
    end

    % Mode Properties - documented
    properties
        DataMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        FontSizeMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        LabelsMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        LabelStyleMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        NamesMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
    end

    % Mode Properties - undocumented
    properties (Hidden)
        SourceTableMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        DataVariableMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        NamesVariableMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'

        StartAngleMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        DirectionMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'

        ExplodedWedgesMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'

        ColorOrderMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        FaceColorMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        EdgeColorMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        FaceAlphaMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        LineWidthMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'

        FontNameMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        FontColorMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        InterpreterMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'

        LegendVisibleMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        LegendTitleMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        TitleMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'

        DisplayOrderMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        NumDisplayWedgesMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        ShowOthersMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
    end

    % Transient properties for use internally
    properties (Transient, NonCopyable, UsedInUpdate=false, ...
            Access={?tPieChartObject,?tPieChart,?tPieChartInteractions,?tPieChartWedgeDisplayCustomization})
        Axes
        Legend
        Linger
        LingerListeners
        PositionListener
        Wedges = gobjects(0)

        NumPoints = 1000
        OuterRadius = 1
        ExplodeAmount = .075
        Datatip matlab.graphics.shape.internal.GraphicsTip
        HighlightObject = gobjects(0)
    end

    properties (Transient, NonCopyable, Access=protected)
        RadiusInPoints = 0
        HasOthersWedge (1,1) logical = false
        WedgeDisplayInds = [] % indices into Data & Names property for displayed wedges
    end

    properties(Dependent, Access=protected)
        InTableMode % determine if we are using Table syntax for data
        InCategoricalMode % determine if we have categorical data
    end

    properties (Transient, NonCopyable, Access=protected, AbortSet, UsedInUpdate=false)
        FigureAncestorForPlotEditListener
        PlotEditListener
    end

    methods (Access={?tPieChartObject})

        function str = getDatatipString(obj, ind, labelFontColor, textValueColor, interpreter)
            try
                % If there's a size mismatch, the error should be thrown in
                % update and not when trying to produce a datatip
                obj.computeOrValidateNames
                obj.computeOnScreenData
            catch me

                str=sprintf('%s\n%s',message("MATLAB:graphics:piechart:DatatipError").getString,me.message);
                return
            end

            switch interpreter
                case 'none'
                    makerow = @(lbl,val)sprintf("%s %s",string(lbl),string(val));
                    percent = "%";

                case 'tex'
                    if isempty(labelFontColor)
                        labelFontColor = [.25 .25 .25];
                    end
                    if isempty(textValueColor)
                        textValueColor = [0 0.6 1];
                    end

                    labelColor = mat2str(labelFontColor);
                    valueColor = mat2str(textValueColor);
                    texLabel="\color[rgb]{"+labelColor(2:end-1)+"}\rm"';
                    texValue="\color[rgb]{"+valueColor(2:end-1)+"}\bf";

                    makerow = @(lbl,val)sprintf("{%s%s} {%s%s}",texLabel,string(lbl),texValue,string(val));
                    percent = "%";

                case 'latex'
                    makerow = @(lbl,val)sprintf("\\textnormal{%s} \\textbf{%s}",string(lbl), string(val));
                    percent = "\%";

            end

            if obj.InCategoricalMode
                str(1) = makerow("Category:", obj.WedgeDisplayNames_I(ind));
                str(2) = makerow("Proportion:", 100*obj.Proportions_I(ind) + percent);
                str(3) = makerow("Count:", obj.WedgeDisplayData_I(ind));
            else
                rowNum = 1;
                if ~isempty(obj.WedgeDisplayNames_I)
                    str(1) = makerow("Name:", obj.WedgeDisplayNames_I(ind));
                    rowNum = 2;
                end
                str(rowNum) = makerow("Proportion:", 100*obj.Proportions_I(ind) + percent);
                str(rowNum+1) = makerow("Data:", string(obj.WedgeDisplayData_I(ind)));
            end
        end

    end

    methods (Access = protected)
        function setup(obj)
            internalModeStorage = true;
            obj.linkDataPropertyToChannel('Data', 'Data', internalModeStorage);
            obj.linkDataPropertyToChannel('Names', 'Names', internalModeStorage);

            setupAxes(obj)
            setupDatatips(obj)
        end

        function update(obj)
            if isempty(obj.PositionListener)
                obj.PositionListener = event.listener(obj.Axes, 'OuterPositionChanged',@(~,~)obj.changeChartPosition);
            end
            try
                computeOrValidateNames(obj);

                computeOnScreenData(obj);

                computeOrValidateLabelStrings(obj);

                computeColorOrder(obj);
                updateWedges(obj);
                updateLabels(obj);
                updateAxes(obj);
            catch e
                % Disable PositionListener on error to prevent continued
                % warning spew. The listener will be re-enabled on the next
                % dirty/update.
                obj.PositionListener = [];
                warningstatus = warning('OFF', 'BACKTRACE');
                warning(e.identifier, '%s', e.message)
                warning(warningstatus);
                return
            end
        end

        function setupAxes(obj)
            ax = polaraxes(obj.getLayout,'Color','none');
            axtoolbar(ax,'export');
            set(ax, ThetaGrid='off', ...
                RGrid='off', ...
                RTick=[], ...
                ThetaTick=[],...
                HitTest = 'on', ...
                ThetaZeroLocation = 'top', ...
                Interactions = [], ...
                GridAlpha = 0, ...
                RLim = [0 1], ...
                Color = 'none');
            obj.setupLingerListeners

            % Set the string to a non-empty to force title the object to be
            % created before attaching listener
            ax.Title.String=' ';
            addlistener(ax.Title, 'String', 'PostSet', ...
                @(~,~)set(obj, 'Title', ax.Title.String_I));
            ax.Subtitle.HitTest='off';
            obj.Axes=ax;
        end

        function setupDatatips(obj)
            datatip = matlab.graphics.shape.internal.GraphicsTip(...
                'Parent', obj.Axes, 'HitTest','off', 'PickableParts', 'none',...
                'Visible','off');
            datatip.ScribeHost.HitTest = 'off';
            datatip.ScribeHost.PickableParts = 'none';
            datatip.ScribeHost.getScribePeer.HitTest = 'off';
            datatip.ScribeHost.getScribePeer.PickableParts = 'none';
            obj.Datatip=datatip;
        end

        function computeOrValidateNames(obj)
            if obj.InCategoricalMode
                % No validation in the categorical case because manual
                % Names are not honored. Instead, clear out any manual
                % Names.
                if obj.isDataComingFromDataSource("Names")
                    obj.NamesVariable_I = '';
                elseif obj.NamesMode == "manual"
                    obj.NamesMode = "auto";
                end
            else
                % In the non-categorical case, validate that any user-
                % specified Names match the size of the data.
                if (obj.NamesMode == "manual" || obj.isDataComingFromDataSource("Names")) ...
                        && ~isempty(obj.Names_I) && numel(obj.Names_I) ~= numel(obj.Data_I)

                    error(message('MATLAB:graphics:piechart:SizeMismatch',"Data","Names"))
                end
            end

            % Compute automatic Names.
            if obj.NamesMode == "auto"
                if obj.InCategoricalMode
                    if iscategorical(obj.Data_I)
                        obj.Names_I = categories(obj.Data_I);
                    elseif islogical(obj.Data_I)
                        obj.Names_I = categories(categorical(obj.Data_I));
                    end
                else
                    obj.Names_I = "data" + (1:numel(obj.Data_I));
                end
            end
        end

        function computeOnScreenData(obj)
            % This method depends on automatic Names having already been
            % populated.

            % Error if ShowOthers is off and all data is undefined. There
            % is nothing to show in this case.
            if ~obj.ShowOthers_I && all(ismissing(obj.Data_I))
                error(message('MATLAB:graphics:piechart:AllUndefinedData'));
            end

            % Reset internal storage properties that will be computed in
            % this method.
            obj.HasOthersWedge = false;
            obj.WedgeDisplayInds = [];

            % Compute starting values for the properties that need to be
            % computed in this method, namely:
            %    Proportions
            %    WedgeDisplayNames
            %    WedgeDisplayData
            [proportions, obj.CategoryCounts_I] = getCountsAndProportions(obj.Data_I);
            wedgeDisplayNames = obj.Names_I;
            if  obj.InCategoricalMode
                wedgeDisplayData = obj.CategoryCounts_I;
            else
                wedgeDisplayData = obj.Data_I;
            end

            % Check if we need to rearrange/subset the data properties.
            isSorted = ismember(obj.DisplayOrder_I, ["ascend","descend"]);
            hasUndefined = obj.InCategoricalMode && any(ismissing(obj.Data_I));
            hasOthers = obj.NumDisplayWedges_I < numel(proportions);

            % Return early in the basic case.
            if ~isSorted && ~hasOthers && ~(obj.ShowOthers_I && hasUndefined)
                obj.WedgeDisplayNames_I = wedgeDisplayNames;
                obj.WedgeDisplayData_I = wedgeDisplayData;
                obj.Proportions_I = proportions;
                return;
            end

            % Determine new order.
            obj.WedgeDisplayInds = 1:numel(proportions);

            if isSorted
                [~, obj.WedgeDisplayInds] = sort(proportions,obj.DisplayOrder_I);
            end

            % Determine subset.
            numWedges = min(numel(proportions), obj.NumDisplayWedges_I);
            obj.WedgeDisplayInds = obj.WedgeDisplayInds(1:numWedges);

            % Figure out if we need to include an "Others" wedge in our
            % computations or not.
            othersIdx = ~ismember(1:numel(proportions),obj.WedgeDisplayInds);
            undefCount = 0;
            dataprop = "Data_I";
            if obj.InCategoricalMode
                dataprop = "CategoryCounts_I";
                undefCount = sum(ismissing(obj.Data_I));
            end

            % Start computing data and names by indexing directly with the
            % WedgeDisplayInds.
            data = obj.(dataprop)(obj.WedgeDisplayInds);
            names = obj.Names_I(obj.WedgeDisplayInds);

            % Tack on the data and name for the others wedge if needed
            obj.HasOthersWedge = obj.ShowOthers_I && (hasOthers || hasUndefined);
            if obj.HasOthersWedge
                othersString = "Others";
                if ismember(othersString, obj.Names_I)
                    if obj.InCategoricalMode
                        error('MATLAB:graphics:piechart:AmbiguousOthersCategorical', ...
                            message('MATLAB:categorical:histogram:AmbiguousOthers',othersString).string);
                    else
                        error(message('MATLAB:graphics:piechart:AmbiguousOthersNames',othersString));
                    end
                end

                othersData = undefCount;
                if any(othersIdx)
                    othersData = othersData + sum(obj.(dataprop)(othersIdx));
                end
                data=[data othersData];
                names=[names othersString];
            end

            [newproportions,~] = getCountsAndProportions(data);
            obj.WedgeDisplayNames_I = names;
            obj.WedgeDisplayData_I = data;
            obj.Proportions_I = newproportions;

            % In the categorical case, some proportions may be zero, meaning
            % for categories with no observations. Error if all the displayed
            % wedges are zero and ShowOthers is off or if all the "Others"
            % are zero. Error after updating WedgeDisplay... properties to
            % aid in debugging.
            zeroProportions = proportions == 0;
            if all(zeroProportions(obj.WedgeDisplayInds)) && ...
                    (~obj.ShowOthers_I || (hasOthers && all(zeroProportions(othersIdx))))
                error(message('MATLAB:graphics:piechart:AllZeroDisplayData'));
            end
        end

        function computeOrValidateLabelStrings(obj)
            % Auto populate Labels. This method must be called after
            % Names, Proportions, and CategoryCounts have been computed.

            % If user has specified Labels, validate that there are the
            % same number of Labels as WedgeDisplayData.
            if obj.LabelsMode == "manual" && ~isempty(obj.Labels_I) ...
                    && numel(obj.Labels_I) ~= numel(obj.WedgeDisplayData_I)

                error(message('MATLAB:graphics:piechart:WedgeDisplayedMismatch',"Labels"))
            end

            % Compute automatic labels.
            if obj.LabelsMode == "auto"
                if obj.LabelStyleMode == "auto"
                    if ~isempty(obj.Names_I) && ...
                            (obj.NamesMode == "manual" || obj.isDataComingFromDataSource("Names") || ...
                            obj.InCategoricalMode || obj.HasOthersWedge)
                        obj.LabelStyle_I = "namepercent";
                    else
                        obj.LabelStyle_I = "percent";
                    end
                end

                valsToDisplay = obj.WedgeDisplayData_I(:);
                names = obj.WedgeDisplayNames_I;

                switch obj.LabelStyle_I
                    case "name"
                        obj.Labels_I = names(:);
                    case "percent"
                        obj.Labels_I = string(round(obj.Proportions_I,3,'significant')*100);
                        if obj.Interpreter == "latex"
                            obj.Labels_I = obj.Labels_I+"\%";
                        else
                            obj.Labels_I = obj.Labels_I+"%";
                        end
                    case "data"
                        obj.Labels_I = string(valsToDisplay);
                    case "namepercent"
                        obj.Labels_I =  names(:) + " (" + string(round(obj.Proportions_I(:),3,'significant')*100);
                        if obj.Interpreter == "latex"
                            obj.Labels_I = obj.Labels_I+"\%)";
                        else
                            obj.Labels_I = obj.Labels_I+"%)";
                        end
                    case "namedata"
                        obj.Labels_I =  names(:) + " (" + string(valsToDisplay(:))+ ")";
                    case "none"
                        obj.Labels_I = [];
                end
            end
        end

        function computeColorOrder(obj)
            if obj.ColorOrderMode == "auto"
                co = get(obj,'DefaultAxesColorOrder');
                coMode = get(obj,'DefaultAxesColorOrderMode');
                if coMode == "auto"
                    tc = ancestor(obj,'matlab.graphics.mixin.ThemeContainer');
                    if ~isempty(tc) && ~isempty(tc.Theme)
                        co = matlab.graphics.internal.themes.getAttributeValue(tc.Theme,'DiscreteColorList');
                    end
                end
                obj.ColorOrder_I=co;
                obj.ColorOrderMode = coMode;
            end
        end

        function updateWedges(obj)
            % This method must be called after Proportions, Names and
            % ColorOrder have been computed.

            nwedges = numel(obj.Proportions_I);
            angles = nan(nwedges, 2);
            radii = obj.getRadii;

            % Loop through wedges and determine angles.
            startAngs = cumsum([0 obj.Proportions_I]);
            for i = 1:nwedges
                angles(i,:) = [startAngs(i) startAngs(i+1)];
            end

            sa = deg2rad(mod(obj.StartAngle,360));
            if obj.Direction == "clockwise"
                angles =  angles * 2 * pi + sa;
            else
                angles =  angles * 2 * pi - sa;
            end

            delete(obj.Wedges(nwedges+1:end));
            obj.Wedges(nwedges+1:end)=[];
            for i = numel(obj.Wedges)+1:nwedges
                obj.Wedges(i) = matlab.graphics.chart.decoration.PolarRegion( ...
                    Parent = obj.Axes, ...
                    Clipping = 'off');
            end

            offset = getExplodeAmount(obj);

            displayNames = obj.WedgeDisplayNames_I;

            for wedgeNum = 1:nwedges
                fc = obj.FaceColor;
                if strcmp(fc,'flat')
                    fc = obj.ColorOrder_I(mod(wedgeNum-1, height(obj.ColorOrder_I))+1,:);
                end
                ec = obj.EdgeColor;
                if strcmp(ec,'flat')
                    ec = obj.ColorOrder_I(mod(wedgeNum-1, height(obj.ColorOrder_I))+1,:);
                end
                if isempty(displayNames)
                    name = "";
                else
                    name = displayNames(wedgeNum);
                end
                if ismissing(name)
                    % Wedge DisplayName cannot handle <missing>
                    name = "";
                end
                set(obj.Wedges(wedgeNum), ...
                    'ThetaSpan', angles(wedgeNum,:), ...
                    'RadiusSpan', radii, ...
                    'FaceColor', fc, ...
                    'EdgeColor', ec, ...
                    'LineWidth', obj.LineWidth, ...
                    'DisplayName', name, ...
                    'HitTest', 'on',...
                    'FaceAlpha', obj.FaceAlpha, ...
                    'RadiusOffset', offset(wedgeNum));
            end
            if ~isempty(obj.HighlightObject) && isvalid(obj.HighlightObject)
                obj.HighlightObject.FaceAlpha = 1;
            end
        end

        function updateAxes(obj)

            emptyTickAddedAtZero = updateAxesTicks(obj);

            obj.Axes.FontName = obj.FontName;
            obj.Axes.TickLabelInterpreter = obj.Interpreter_I;
            obj.Axes.Title.String_I = obj.Title_I;
            obj.Axes.Title.Color = obj.FontColor_I;
            obj.Axes.Title.Interpreter = obj.Interpreter_I;
            obj.Datatip.TextFormatHelper.Interpreter = obj.Interpreter_I;

            if obj.FontSizeMode == "manual"
                obj.Axes.FontSize = obj.FontSize_I;
            else
                obj.Axes.FontSizeMode = "auto";
                obj.FontSize_I = obj.Axes.FontSize;
            end

            % Use a Subtitle to add additional padding between the Title and
            % the axes when Title is non-empty and we haven't already added
            % an extra empty tick at zero.
            if any(strtrim(obj.Title_I) ~= "") && ~emptyTickAddedAtZero
                obj.Axes.Subtitle.String=' ';
            else
                obj.Axes.Subtitle.String='';
            end
            obj.Axes.Subtitle.FontSize=obj.FontSize_I*.3;
            obj.Axes.ThetaColor = obj.FontColor;

            if isempty(obj.Legend) && obj.LegendVisible
                obj.Legend = legend(obj.Axes,'PickableParts','none','Location','northeastoutside');
            elseif ~obj.LegendVisible
                delete(obj.Legend);
                obj.Legend=[];
            end

            if ~isempty(obj.Legend)
                obj.Legend.Title.String = obj.LegendTitle_I;
                obj.Legend.Color = obj.LegendFaceColor_I;
                obj.Legend.TextColor = obj.FontColor_I;
                obj.Legend.Interpreter = obj.Interpreter_I;
            end

            obj.Axes.ThetaDir = obj.Direction;
        end

        function emptyTickAddedAtZero = updateAxesTicks(obj)
            emptyTickAddedAtZero = false;

            DEFAULT_TICK_OFFSET = 2;
            if isempty(obj.Wedges)
                obj.Axes.ThetaTick = [];
                obj.Axes.ThetaTickLabels = [];
                obj.Axes.ThetaAxis.TickLabelGapOffset = DEFAULT_TICK_OFFSET;
                return;
            end

            % Compute values for the tick locations.
            allangles = vertcat(obj.Wedges.ThetaSpan);
            thetamidpoints = mean(allangles, 2);
            [ticklocations, sortind] = sort(mod(rad2deg(thetamidpoints), 360));

            % When there are multiple zero-sized wedges, piechart should
            % maintain multiple tick values (to associate with labels), but
            % ticks must be increasing. The offset below is less than one
            % ten-thousandth of a degree.
            ticklocations = ticklocations+cumsum([false;diff(ticklocations)==0]*2e-7);

            % Compute tick labels.
            ticklabels = [];
            if ~isempty(obj.Labels_I)
                ticklabels = cellstr(obj.Labels_I);
                ticklabels = ticklabels(sortind);
            end

            % Compute tick label offsets to account for exploded wedges.
            tickoffsets = repmat(DEFAULT_TICK_OFFSET, size(ticklocations));
            wedgeoffsets = [obj.Wedges(sortind).RadiusOffset];
            tickoffsets = ceil(tickoffsets(:) + wedgeoffsets(:) * obj.RadiusInPoints);

            % Determine if any exploded spans start or end at 0 (the
            % top of this PolarAxes.) If so, add an extra empty tick at
            % zero so that title layout takes it into account,
            % preventing overlap between the exploded wedge and the
            % title in most cases.
            spans = vertcat(obj.Wedges.ThetaSpan);
            explodedSpans = mod(spans(wedgeoffsets>0,:),2*pi);
            tolerance = 5; % degrees
            hasExplodeAtZero = any(explodedSpans <= deg2rad(tolerance) | explodedSpans >= deg2rad(360-tolerance),"all");
            alreadyHasTickAtZero = any(ticklocations <= tolerance | ticklocations >= 360-tolerance,"all");
            if ~isempty(explodedSpans) &&  hasExplodeAtZero && ~alreadyHasTickAtZero
                % Insert fake, empty tick at 0.
                emptyTickAddedAtZero = true;
                ticklocations = [0; ticklocations(:)];
                ticklabels = [' '; ticklabels(:)];
                tickoffsets = [DEFAULT_TICK_OFFSET; tickoffsets(:)];
            end

            obj.Axes.ThetaTick = ticklocations;
            obj.Axes.ThetaTickLabels = ticklabels;
            obj.Axes.ThetaAxis.TickLabelGapOffset = tickoffsets;
        end

        function updateLabels(~)
            % No additional behavior by default. DonutChart overrides this
            % method to update the CenterLabel.
        end

        function tf = useGcaBehavior(~)
            tf = false;
        end

        function groups =  getPropertyGroups(obj)
            props = {'ColorOrder','FaceAlpha','EdgeColor','Labels'};

            if ~isempty(obj.CategoryCounts )
                props = [props 'CategoryCounts'];
            end

            if obj.InTableMode
                props = [props 'SourceTable' 'DataVariable' 'NamesVariable'];
            else
                props = [props 'Data' 'Names'];
            end

            groups = matlab.mixin.util.PropertyGroup(props);
        end

        function label = getDescriptiveLabelForDisplay(obj)
            label = [];
            if ~isempty(obj.Title)
                label = obj.Title;
            end
        end

        function offset = getExplodeAmount(obj)
            nwedges = numel(obj.Wedges);

            % default no wedges exploded
            offset = zeros(1,nwedges);
            explode = obj.ExplodedWedges_I;
            nexplode = numel(explode);

            if isempty(explode)
                % return default (no explode)
                return
            end

            if isvector(explode) && islogical(explode)
                % logical indexing
                if nexplode ~= nwedges
                    error(message('MATLAB:graphics:piechart:ExplodedWedges'))
                end
                offset(explode) = obj.ExplodeAmount;
                return
            end

            if isnumeric(explode)
                if any(explode<=0,'all') || any(explode ~= fix(explode),'all')
                    badexplode = find(explode<=0 | explode ~= fix(explode), 1, 'first');
                    error(message('MATLAB:graphics:piechart:ExplodedWedgesIndex',message('MATLAB:matrix:badTypeIndicesPosition', badexplode).getString))
                end
                if any(explode>nwedges,'all')
                    badexplode = find(explode>nwedges, 1, 'first');
                    error(message('MATLAB:graphics:piechart:ExplodedWedgesIndex',message('MATLAB:matrix:indexExceedsDimsPositionSize', badexplode, nwedges).getString))
                end
                offset(explode) = obj.ExplodeAmount;
                return
            end

            if obj.InCategoricalMode
                cats=categories(obj.Data);
                if iscategorical(explode)
                    explode = string(explode);
                end
                if isstring(explode) || iscellstr(explode) || ischar(explode)
                    if all(strlength(explode)==0,'all')
                        % return default (no explode)
                        return
                    elseif all(ismember(explode,cats),'all')
                        offset(ismember(cats,explode)) = obj.ExplodeAmount;
                        return
                    end
                end
                error(message('MATLAB:graphics:piechart:ExplodedWedgesCategorical'))
            end
            error(message('MATLAB:graphics:piechart:ExplodedWedges'))
        end

        function changeChartPosition(obj)
            fig = ancestor(obj,'figure');
            obj.FigureAncestorForPlotEditListener = fig;
            if ~isgraphics(fig)
                % Nothing to do if object is not actually positioned on
                % screen.
                return;
            end

            container = ancestor(obj,'matlab.ui.internal.mixin.CanvasHostMixin','node');
            posPoints = hgconvertunits(fig, obj.Axes.InnerPosition,...
                'normalized','points',container);
            radPoints = posPoints(3)/2;
            if round(obj.RadiusInPoints) ~= round(radPoints)
                obj.RadiusInPoints = radPoints;
            end
        end

        function setupLingerListeners(obj)
            linger=matlab.graphics.interaction.actions.Linger(obj);
            linger.IncludeChildren = true;
            linger.LingerTime = 0.5;
            linger.GetNearestPointFcn=@(~,e)obj.LingerGetPoint(e);

            obj.LingerListeners.EnterListener=addlistener(linger,'EnterObject', @(~,e)obj.LingerEvent(e));
            obj.LingerListeners.ExitListener=addlistener(linger,'ExitObject', @(~,e)obj.LingerEvent(e));
            obj.LingerListeners.LingerListener=addlistener(linger,'LingerOverObject', @(~,e)obj.LingerEvent(e));
            obj.LingerListeners.ResetListener=addlistener(linger,'LingerReset', @(~,e)obj.LingerEvent(e));
            linger.enable;

            obj.Linger=linger;
        end

        function LingerEvent(obj,eventdata)
            switch eventdata.EventName
                case 'EnterObject'
                    hitobj=eventdata.HitObject;
                    if isa(hitobj, 'matlab.graphics.chart.decoration.PolarRegion')
                        hitobj.FaceAlpha = 1;
                        obj.HighlightObject = hitobj;
                    end
                case 'ExitObject'
                    hitobj=eventdata.PreviousObject;
                    if isa(hitobj, 'matlab.graphics.chart.decoration.PolarRegion')
                        hitobj.FaceAlpha = obj.FaceAlpha;
                        obj.HighlightObject = gobjects(0);
                    end
                    obj.Datatip.Visible='off';
                case 'LingerOverObject'
                    hitobj=eventdata.HitObject;

                    if isa(hitobj, 'matlab.graphics.chart.decoration.PolarRegion')
                        theta = mean(hitobj.ThetaSpan);
                        r = mean(hitobj.RadiusSpan);
                        labelFontColor = obj.Datatip.LabelFontColor;
                        textValueColor = obj.Datatip.PinnedValueFontColor;
                        str = obj.getDatatipString(find(hitobj==obj.Wedges),labelFontColor,textValueColor, obj.Interpreter_I);
                        set(obj.Datatip,...
                            'Position', [theta r 0], ...
                            'String', str,...
                            'Visible', 'on');
                    end
                case 'LingerReset'
                    obj.Datatip.Visible='off';
                    obj.HighlightObject = gobjects(0);
            end
        end

        function ind=LingerGetPoint(obj,eventdata)
            ind = find(obj.Wedges==eventdata.HitObject(1),1,'first');
            if isempty(ind)
                ind = nan;
            end
        end

        function autocalcUpdate(obj)
            % Suppress warnings in update so that multiple warnings aren't
            % shown during disp
            warnstate = warning;
            sgwarnstate = onCleanup(@()warning(warnstate));
            [msg,id] = lastwarn;
            sglastwarn = onCleanup(@() lastwarn(msg, id));

            warning off
            obj.update;
        end
    end

    methods(Access={?tPieChartWedgeDisplayCustomization})
        function updateWrapperForTest(obj)
            obj.update;
        end
    end

    methods (Access=protected,Static)
        function map = getThemeMap
            map = struct("ColorOrder","DiscreteColorList",...
                "EdgeColor","--mw-color-primary",...
                "FontColor","--mw-color-primary",...
                "LegendFaceColor_I","--mw-graphics-backgroundColor-axes-primary");
        end
    end

    % Setters & Getters for Dependent Properties
    methods
        function set.Data(obj, value)
            obj.setDataPropertyValue("Data", value, false);
        end
        function set.DataMode(obj, mode)
            obj.setDataPropertyMode("Data", mode);
        end
        function set.Data_I(obj, value)
            obj.setDataPropertyValue("Data", value, true);
        end
        function set.DataVariable(obj, value)
            obj.setVariablePropertyValue("Data", value, false);
        end
        function set.DataVariable_I(obj, value)
            obj.setVariablePropertyValue("Data", value, true);
        end
        function value = get.Data(obj)
            value = obj.getDataPropertyValue("Data", false);
        end
        function mode = get.DataMode(obj)
            mode = obj.getDataPropertyMode("Data");
        end
        function value = get.Data_I(obj)
            value = obj.getDataPropertyValue("Data", true);
        end
        function value = get.DataVariable(obj)
            value = obj.getVariablePropertyValue("Data", false);
        end
        function value = get.DataVariable_I(obj)
            value = obj.getVariablePropertyValue("Data", true);
        end
        function set.Names(obj, value)
            if obj.InCategoricalMode
                error(message('MATLAB:graphics:piechart:NoNamesWithCategorical','Names'));
            end
            obj.setDataPropertyValue("Names", value, false);
        end
        function set.NamesMode(obj, mode)
            if obj.InCategoricalMode && mode == "manual" %#ok<MCSUP>
                error(message('MATLAB:graphics:piechart:NoNamesWithCategorical','Names'));
            end
            obj.setDataPropertyMode("Names", mode);
        end
        function set.Names_I(obj, value)
            obj.setDataPropertyValue("Names", value, true);
        end
        function set.NamesVariable(obj, value)
            if obj.InCategoricalMode
                error(message('MATLAB:graphics:piechart:NoNamesWithCategorical','Names'));
            end
            obj.setVariablePropertyValue("Names", value, false);
        end
        function set.NamesVariable_I(obj, value)
            obj.setVariablePropertyValue("Names", value, true);
        end
        function value = get.Names(obj)
            if obj.NamesMode=="auto" || obj.InCategoricalMode
                obj.autocalcUpdate
            end
            value = obj.getDataPropertyValue("Names", false);
        end
        function mode = get.NamesMode(obj)
            mode = obj.getDataPropertyMode("Names");
        end
        function value = get.Names_I(obj)
            value = obj.getDataPropertyValue("Names", true);
        end
        function value = get.NamesVariable(obj)
            value = obj.getVariablePropertyValue("Names", false);
        end
        function value = get.NamesVariable_I(obj)
            value = obj.getVariablePropertyValue("Names", true);
        end

        function set.Labels(obj,val)
            obj.Labels_I=val;
            obj.LabelsMode='manual';
        end
        function val = get.Labels(obj)
            if obj.LabelsMode == "auto"
                obj.autocalcUpdate
            end
            val = obj.Labels_I;
        end

        function set.LabelStyle(obj,val)
            obj.LabelStyle_I=val;
            obj.LabelStyleMode='manual';
        end
        function val = get.LabelStyle(obj)
            if obj.LabelStyleMode == "auto"
                obj.autocalcUpdate
            end
            val = obj.LabelStyle_I;
        end

        function set.StartAngle(obj,val)
            obj.StartAngle_I=val;
            obj.StartAngleMode='manual';
        end
        function val = get.StartAngle(obj)
            val = obj.StartAngle_I;
        end

        function set.Direction(obj,val)
            obj.Direction_I=val;
            obj.DirectionMode='manual';
        end
        function val = get.Direction(obj)
            val = obj.Direction_I;
        end

        function set.ExplodedWedges(obj,val)
            obj.ExplodedWedges_I=val;
            obj.ExplodedWedgesMode='manual';
        end
        function val = get.ExplodedWedges(obj)
            val = obj.ExplodedWedges_I;
        end

        function set.ColorOrder(obj,val)
            obj.ColorOrder_I=val;
            obj.ColorOrderMode='manual';
        end
        function val = get.ColorOrder(obj)
            if obj.ColorOrderMode == "auto"
                obj.autocalcUpdate
            end
            val = obj.ColorOrder_I;
        end

        function set.FaceColor(obj,val)
            obj.FaceColor_I=val;
            obj.FaceColorMode='manual';
        end
        function val = get.FaceColor(obj)
            val = obj.FaceColor_I;
        end

        function set.EdgeColor(obj,val)
            obj.EdgeColor_I=val;
            obj.EdgeColorMode='manual';
        end
        function val = get.EdgeColor(obj)
            val = obj.EdgeColor_I;
        end

        function set.FaceAlpha(obj,val)
            obj.FaceAlpha_I=val;
            obj.FaceAlphaMode='manual';
        end
        function val = get.FaceAlpha(obj)
            val = obj.FaceAlpha_I;
        end

        function set.LineWidth(obj,val)
            obj.LineWidth_I=val;
            obj.LineWidthMode='manual';
        end
        function val = get.LineWidth(obj)
            val = obj.LineWidth_I;
        end

        function set.FontSize(obj,val)
            obj.FontSize_I=val;
            obj.FontSizeMode='manual';
        end
        function val = get.FontSize(obj)
            if obj.FontSizeMode == "auto"
                obj.autocalcUpdate
            end
            val = obj.FontSize_I;
        end

        function set.FontName(obj,val)
            obj.FontName_I=val;
            obj.FontNameMode='manual';
        end
        function val = get.FontName(obj)
            val = obj.FontName_I;
        end

        function set.Interpreter(obj,val)
            obj.InterpreterMode = 'manual';
            obj.Interpreter_I=val;
        end
        function val = get.Interpreter(obj)
            val = obj.Interpreter_I;
        end

        function set.FontColor(obj,val)
            obj.FontColor_I=val;
            obj.FontColorMode='manual';
        end
        function val = get.FontColor(obj)
            val = obj.FontColor_I;
        end

        function set.LegendVisible(obj,val)
            obj.LegendVisible_I=val;
            obj.LegendVisibleMode='manual';
        end
        function val = get.LegendVisible(obj)
            val = obj.LegendVisible_I;
        end

        function set.LegendTitle(obj,val)
            obj.LegendTitle_I=val;
            obj.LegendTitleMode='manual';
        end
        function val = get.LegendTitle(obj)
            val = obj.LegendTitle_I;
        end

        function set.Title(obj,val)
            obj.Title_I=val;
            obj.TitleMode='manual';
        end
        function val = get.Title(obj)
            val = obj.Title_I;
        end
        function set.Title_I(obj,val)
            obj.Title_I=val;
        end

        function set.CategoryCounts(obj,val)
            obj.CategoryCounts_I=val;
        end
        function val = get.CategoryCounts(obj)
            obj.autocalcUpdate
            val = obj.CategoryCounts_I;
        end

        function set.Proportions(obj,val)
            obj.Proportions_I=val;
        end
        function val = get.Proportions(obj)
            obj.autocalcUpdate
            val = obj.Proportions_I;
        end

        function set.WedgeDisplayData(obj,val)
            obj.WedgeDisplayData_I=val;
        end
        function val = get.WedgeDisplayData(obj)
            obj.autocalcUpdate
            val = obj.WedgeDisplayData_I;
        end

        function set.WedgeDisplayNames(obj,val)
            obj.WedgeDisplayNames_I=val;
        end
        function val = get.WedgeDisplayNames(obj)
            obj.autocalcUpdate
            val = obj.WedgeDisplayNames_I;
        end

        function set.DisplayOrder(obj,val)
            obj.DisplayOrder_I=val;
            obj.DisplayOrderMode="manual";
            resetPropertiesThatMatchOnScreenWedges(obj, "DisplayOrder");
        end
        function val = get.DisplayOrder(obj)
            val = obj.DisplayOrder_I;
        end

        function set.NumDisplayWedges(obj,val)
            obj.NumDisplayWedges_I=val;
            obj.NumDisplayWedgesMode="manual";
            resetPropertiesThatMatchOnScreenWedges(obj, "NumDisplayWedges");
        end
        function val = get.NumDisplayWedges(obj)
            val = obj.NumDisplayWedges_I;
        end

        function set.ShowOthers(obj,val)
            obj.ShowOthers_I=val;
            obj.ShowOthersMode="manual";
            resetPropertiesThatMatchOnScreenWedges(obj, "ShowOthers");
        end
        function val = get.ShowOthers(obj)
            val = obj.ShowOthers_I;
        end

        function val = get.InTableMode(obj)
            val = obj.SourceTableMode == "manual";
        end

        function val = get.InCategoricalMode(obj)
            val = iscategorical(obj.Data_I) || islogical(obj.Data_I);
        end

        function set.FigureAncestorForPlotEditListener(obj,fig)
            % Note that because this property is AbortSet, this function
            % runs only when the ancestor changes
            obj.FigureAncestorForPlotEditListener = fig;
            uigetmodemanager(fig);
            if ~isempty(fig)
                obj.PlotEditListener = fig.ModeManager.listener('CurrentMode', ...
                    'PostSet', @(~,e) obj.updateLingerAndDatatipsForPlotEdit(fig));
            end
        end
    end

    methods (Access=private)
        function updateLingerAndDatatipsForPlotEdit(obj, fig)
            if isscalar(obj.Linger) && isvalid(obj.Linger)
                mode = fig.ModeManager.CurrentMode;
                if isscalar(mode) && mode.Name == "Standard.EditPlot"
                    obj.Linger.disable;
                    obj.Datatip.Visible='off';
                    set(obj.Wedges, 'FaceAlpha', obj.FaceAlpha);
                else
                    obj.Linger.enable;
                end
            end
        end
    end

    methods(Access={?tPieChartObject,?matlab.graphics.chart.DonutChart})
        function radii = getRadii(~)
            radii = [0 1];
        end
    end

    methods(Access=protected)
        function resetPropertiesThatMatchOnScreenWedges(obj, propName)
            % When properties DisplayOrder, NumDisplayWedges and ShowOthers
            % are  specified, the number and order of on-screen wedges may
            % change. Writable properties that must match up with the
            % number or indices of on-screen wedges are reset at this time.

            if obj.LabelsMode == "manual"
                obj.LabelsMode = "auto";
                warning(message('MATLAB:graphics:piechart:LabelsReset',propName));
            end

            if obj.ExplodedWedgesMode == "manual" || ~isempty(obj.ExplodedWedges_I)
                obj.ExplodedWedges_I = [];
                obj.ExplodedWedgesMode = "auto";
                warning(message('MATLAB:graphics:piechart:ExplodedWedgesReset',propName));
            end
        end
    end

    methods(Static, Hidden)
        function validateTableData(dataMap)
            arguments
                dataMap (1,1) matlab.graphics.data.DataMap
            end
            channels = string(fieldnames(dataMap.Map));
            keep = ismember(channels, ["Data" "Names"]);
            channels = channels(keep);
            for c = channels'
                subscript = dataMap.Map.(c);
                data = dataMap.DataSource.getData(subscript);
                for d = 1:numel(data)
                    matlab.graphics.chart.PieChart.validateDataPropertyValue(c, data{d});
                end
            end

            if isfield(dataMap.Map, 'Data') && isfield(dataMap.Map, 'Names')
                data = dataMap.DataSource.getData(dataMap.Map.Data);
                if isscalar(data) && iscategorical(data{1})
                    error(message("MATLAB:graphics:piechart:NoNamesWithCategorical","Names"))
                end
            end
        end
        function validateMatrixData(data,names)
            matlab.graphics.chart.PieChart.validateDataPropertyValue("Data", data);
            if nargin > 1
                if iscategorical(data)
                    error(message("MATLAB:graphics:piechart:NoNamesWithCategorical","Names"))
                end
                matlab.graphics.chart.PieChart.validateDataPropertyValue("Names", names);
                if numel(data) ~= numel(names) && ~isempty(names)
                    error(message("MATLAB:graphics:piechart:SizeMismatch", "Data", "Names"))
                end
            end
        end
    end
    methods(Static, Access=protected)
        function data = validateDataPropertyValue(channelName, data)
            if channelName == "Data"
                emptyOrVector = isempty(data) || isvector(data);
                validCategorical = iscategorical(data);
                validLogical = islogical(data);
                validNumericOrDuration = (isnumeric(data) || isduration(data)) && ...
                    all(data>=0,'all') && all(isfinite(data),'all') && isreal(data);
                isvalid = emptyOrVector && (validCategorical || validLogical || validNumericOrDuration);
                if ~isvalid
                    error(message("MATLAB:graphics:piechart:InvalidData"))
                end
            elseif channelName == "Names"
                try
                    assert(isempty(data) || isvector(data))
                    data=string(data);
                catch
                    error(message("MATLAB:graphics:piechart:InvalidNames"))
                end
            end
        end
    end
end

function mustBeOneToInfInteger(val)
if val ~= Inf
    try
        hgcastvalue('matlab.graphics.datatype.PositiveInteger', val);
    catch
        ex = MException('MATLAB:graphics:piechart:PositiveWholeNumberInf',message('MATLAB:graphics:piechart:PositiveWholeNumberInf'));
        throwAsCaller(ex);
    end
end
end

function [props, counts] = getCountsAndProportions(val)

counts = [];
if issparse(val)
    val = full(val);
end

if iscategorical(val) || islogical(val)
    counts = histcounts(val);
    props = counts/sum(counts);
elseif isnumeric(val) && sum(val)<=1
    props = val;
elseif isduration(val)
    val = val / max(val);
    props = val / sum(val);
elseif isnumeric(val)
    val = double(val);
    val = val / max(val);
    props = val / sum(val);
end
end
