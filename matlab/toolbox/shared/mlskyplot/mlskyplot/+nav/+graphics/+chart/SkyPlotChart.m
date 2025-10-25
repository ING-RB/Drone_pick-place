classdef SkyPlotChart < matlab.graphics.chartcontainer.ChartContainer ...
        & matlab.graphics.chartcontainer.mixin.ColorOrderMixin
    %nav.graphics.chart.SkyPlotChart Sky plot appearance and behavior
    %
    %   The SkyPlotChart properties control the appearance of a sky plot 
    %   chart generated using the skyplot function. To modify the chart 
    %   appearance, use dot notation on the SkyPlotChart object:
    %
    %       h = skyplot;
    %       h.AzimuthData = [45 120 295];
    %       h.ElevationData = [10 45 60];
    %       h.Labels = ["G1" "G4" "G11"];
    %
    %   See also skyplot

    %   Copyright 2020-2023 The MathWorks, Inc.

    properties (Dependent, Resettable = false)
        AzimuthData double;
        ElevationData double;
        LabelData;
        GroupData;
        ColorOrder matlab.internal.datatype.matlab.graphics.datatype.ColorOrder;
        MarkerEdgeAlpha;
        MarkerEdgeColor;
        MarkerFaceAlpha;
        MarkerFaceColor;
        MarkerSizeData;
        LabelFontSize;
        
        MaskElevation double;
        MaskAzimuthEdges double;
        MaskAlpha;
        MaskColor matlab.internal.datatype.matlab.graphics.datatype.RGBAColor;
    end
    
    properties (Transient, NonCopyable)
        LabelFontSizeMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto';
        MaskAzimuthEdgesMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto';
    end
    
    properties (Hidden, Transient, NonCopyable)
        ColorOrderMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto';
        GroupDataMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto';
        MarkerEdgeAlphaMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto';
        MarkerEdgeColorMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto';
        MarkerFaceAlphaMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto';
        MarkerFaceColorMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto';
        MarkerSizeDataMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto';
        MaskElevationMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto';
        MaskAlphaMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto';
        MaskColorMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto';
    end

    properties (Access = private, Transient, NonCopyable)
        LabelMode matlab.lang.OnOffSwitchState = 'off';
    end

    properties (Access = protected, Transient, NonCopyable)
        TextPositionReference;

        LabelDataDisplayValue = [];

        ValidationDirty = true;
        DataDirty = true;
        CategoriesDirty = true;
        LabelsDirty = true;
        ColorDirty = true;
        MarkerSizeDirty = true;
        LabelFontSizeDirty = true;

        PrevDataLength = 0;
        PrevNumLabels = 0;
        
        NeedsUpdate = true;
        pLegendArgs = {};
        LegendLoadDirty = false;
        pTitleArgs = {};
        TitleLoadDirty = false;
        pSubtitleArgs = {};
        SubtitleLoadDirty = false;
    end

    properties (Transient, NonCopyable, Hidden, Access = private)
        Axes matlab.graphics.axis.PolarAxes
        ScatterObjects = gobjects(0);
        TextObjects = gobjects(0);
        MaskShade;
        SatelliteTrackLines = gobjects(0);
    end

    properties (Hidden, SetAccess = private, Dependent, Resettable = false)
        LegendVisible matlab.lang.OnOffSwitchState;
    end

    properties (Access = private, Transient, NonCopyable)
        LegendVisible_I matlab.lang.OnOffSwitchState = 'off';
    end

    properties (Access = private, Transient, NonCopyable)
        AzimuthData_I = [];
        ElevationData_I = [];
        LabelData_I = [];
        GroupData_I = [];
        ColorOrder_I = get(groot, 'FactoryAxesColorOrder');
        MarkerEdgeAlpha_I matlab.internal.datatype.matlab.graphics.datatype.ZeroToOne = 1;
        MarkerEdgeColor_I matlab.internal.datatype.matlab.graphics.datatype.MarkerColor = 'flat';
        MarkerFaceAlpha_I matlab.internal.datatype.matlab.graphics.datatype.ZeroToOne = 0.6;
        MarkerFaceColor_I matlab.internal.datatype.matlab.graphics.datatype.MarkerColor = 'flat';
        MarkerSizeData_I = 100;
        LabelFontSize_I matlab.internal.datatype.matlab.graphics.datatype.Positive = get(groot, 'FactoryAxesFontSize');
        MaskElevation_I = 0;
        MaskAzimuthEdges_I = [0 360];
        MaskAlpha_I matlab.internal.datatype.matlab.graphics.datatype.ZeroToOne = 0.3;
        % Default value is "Primary Border" color from Parula Design System Color Palette.
        MaskColor_I matlab.internal.datatype.matlab.graphics.datatype.RGBAColor = '#7D7D7D';
    end
    
    properties (UsedInUpdate = false, Access = private, Transient, NonCopyable)
        pOuterPosition = [0 0 0 0];
    end

    properties (Access = protected)
        % Used for save/load.
        DataStorage
    end

    methods % Public convenience methods
        function title(obj, varargin)
        % Accept all normal inputs of "title" command.
            ax = getAxes(obj);
            title(ax, varargin{:});
            obj.pTitleArgs = varargin;
        end
        
        function subtitle(obj, varargin)
        % Accept all normal inputs of "subtitle" command.
            ax = getAxes(obj);
            subtitle(ax, varargin{:});
            obj.pSubtitleArgs = varargin;
        end

        function legend(obj, varargin)
        % Accept all normal inputs of "legend" command.
            if obj.NeedsUpdate
                obj.NeedsUpdate = false;
                update(obj);
            end
            ax = getAxes(obj);
            lgd = legend(ax, varargin{:});
            % Set legend visibility for menu figure callback.
            if isvalid(lgd)
                obj.LegendVisible_I = lgd.Visible;
                obj.pLegendArgs = varargin;
            else
                obj.LegendVisible_I = 'off';
            end
        end
    end

    methods % Set/Get methods
        function data = get.DataStorage(obj)
        % Save legend and title.
            ax = getAxes(obj);
            lgd = ax.Legend;
            txt = ax.Title;
            subtxt = ax.Subtitle;
            if isvalid(lgd)
                data.Legend = obj.pLegendArgs;
            end
            if ~isempty(txt.String)
                % Update title string in case it has been edited
                % interactively.
                obj.pTitleArgs{1} = txt.String_I;
                data.Title = obj.pTitleArgs;
            end
            if ~isempty(subtxt.String)
                % Update subtitle string in case it has been edited
                % interactively.
                obj.pSubtitleArgs{1} = subtxt.String_I;
                data.Subtitle = obj.pSubtitleArgs;
            end

            % Save azimuth, elevation, and label data.
            data.AzimuthData = obj.AzimuthData_I;
            data.ElevationData = obj.ElevationData_I;
            data.LabelData = obj.LabelData;

            % Save property if mode is set to 'manual'.
            data = saveProperty(obj, data, 'ColorOrder');
            data = saveProperty(obj, data, 'GroupData');
            data = saveProperty(obj, data, 'MarkerEdgeAlpha');
            data = saveProperty(obj, data, 'MarkerEdgeColor');
            data = saveProperty(obj, data, 'MarkerFaceAlpha');
            data = saveProperty(obj, data, 'MarkerFaceColor');
            data = saveProperty(obj, data, 'MarkerSizeData');
            data = saveProperty(obj, data, 'LabelFontSize');
            data = saveProperty(obj, data, 'MaskElevation');
            data = saveProperty(obj, data, 'MaskAzimuthEdges');
            data = saveProperty(obj, data, 'MaskAlpha');
            data = saveProperty(obj, data, 'MaskColor');
        end

        function data = saveProperty(obj, data, propName)
            propNameMode = [propName 'Mode'];
            if strcmp(obj.(propNameMode), 'manual')
                data.(propName) = obj.(propName);
            end
        end

        function set.DataStorage(obj, data)
            obj.AzimuthData = data.AzimuthData; %#ok<MCSUP>
            obj.ElevationData = data.ElevationData; %#ok<MCSUP>
            obj.LabelData = data.LabelData; %#ok<MCSUP>
            
            % Load property if it exists in saved struct.
            loadProperty(obj, data, 'ColorOrder');
            loadProperty(obj, data, 'GroupData');
            loadProperty(obj, data, 'MarkerEdgeAlpha');
            loadProperty(obj, data, 'MarkerEdgeColor');
            loadProperty(obj, data, 'MarkerFaceAlpha');
            loadProperty(obj, data, 'MarkerFaceColor');
            loadProperty(obj, data, 'MarkerSizeData');
            loadProperty(obj, data, 'LabelFontSize');
            loadProperty(obj, data, 'MaskElevation');
            loadProperty(obj, data, 'MaskAzimuthEdges');
            loadProperty(obj, data, 'MaskAlpha');
            loadProperty(obj, data, 'MaskColor');
            
            if isfield(data, 'Legend')
                obj.pLegendArgs = data.Legend; %#ok<MCSUP>
                obj.LegendLoadDirty = true; %#ok<MCSUP>
            end
            if isfield(data, 'Title')
                obj.pTitleArgs = data.Title; %#ok<MCSUP>
                obj.TitleLoadDirty = true; %#ok<MCSUP>
            end
            if isfield(data, 'Subtitle')
                obj.pSubtitleArgs = data.Subtitle; %#ok<MCSUP>
                obj.SubtitleLoadDirty = true; %#ok<MCSUP>
            end
        end

        function loadProperty(obj, data, propName)
            if isfield(data, propName)
                obj.(propName) = data.(propName);
            end
        end

        function val = get.AzimuthData(obj)
            val = obj.AzimuthData_I;
        end
        function set.AzimuthData(obj, val)
            % Filter
            valNoNaN = val;
            if isnumeric(valNoNaN)
                valNoNaN(isnan(valNoNaN)) = 0;
            end
            validateattributes(valNoNaN, {'numeric'}, ...
                {'2d', 'real', '>=', 0, '<=', 360}, '', 'AzimuthData');
            if iscolumn(val)
                val = val.';
            end
            obj.AzimuthData_I = val;
        end

        function val = get.ElevationData(obj)
            val = obj.ElevationData_I;
        end
        function set.ElevationData(obj, val)
            valNoNaN = val;
            if isnumeric(valNoNaN)
                valNoNaN(isnan(valNoNaN)) = 0;
            end
            validateattributes(valNoNaN, {'numeric'}, ...
                {'2d', 'real', '>=', 0, '<=', 90}, '', 'ElevationData');
            if iscolumn(val)
                val = val.';
            end
            obj.ElevationData_I = val;
        end

        function val = get.MaskElevation(obj)
            val = obj.MaskElevation_I;
        end
        function set.MaskElevation(obj, val)
            validateattributes(val, {'numeric'}, {'vector','real', ...
                '>=', 0, '<=', 90}, '', 'MaskElevation');
            obj.MaskElevation_I = val(:).';
            if strcmp(obj.MaskAzimuthEdgesMode, 'auto')
                obj.MaskAzimuthEdges_I = linspace(0, 360, numel(val)+1);
            else
                obj.ValidationDirty = true;
            end
            obj.MaskElevationMode = 'manual';
        end

        function val = get.MaskAzimuthEdges(obj)
            if strcmp(obj.MaskAzimuthEdgesMode, 'auto')
                val = linspace(0, 360, numel(obj.MaskElevation_I)+1);
            else
                val = obj.MaskAzimuthEdges_I;
            end
        end
        function set.MaskAzimuthEdges(obj, val)
            validateattributes(val, {'numeric'}, {'vector', 'real', ...
                '>=', 0, '<=', 360, 'nondecreasing'}, '', 'MaskAzimuthEdges');
            obj.MaskAzimuthEdges_I = val;
            obj.MaskAzimuthEdgesMode = 'manual';
            obj.ValidationDirty = true;
        end

        function val = get.LabelData(obj)
            val = obj.LabelDataDisplayValue;
        end
        function set.LabelData(obj, val)
            obj.LabelData_I = val(:).';
        end

        function val = get.GroupData(obj)
            val = obj.GroupData_I;
        end
        function set.GroupData(obj, val)
            validateattributes(val, {'categorical'}, {'vector'});
            obj.GroupData_I = val;
            obj.GroupDataMode = 'manual';
        end

        function val = get.ColorOrder(obj)
            val = obj.ColorOrder_I;
        end
        function set.ColorOrder(obj, val)
            validateattributes(val, {'numeric'}, {'2d', 'ncols', 3});
            obj.ColorOrder_I = val;
            obj.ColorOrderMode = 'manual';
        end

        function val = get.MarkerEdgeAlpha(obj)
            val = obj.MarkerEdgeAlpha_I;
        end
        function set.MarkerEdgeAlpha(obj, val)
            validateattributes(val, {'numeric'}, {'scalar', ...
                                '>=', 0, '<=', 1});
            obj.MarkerEdgeAlpha_I = val;
            obj.MarkerEdgeAlphaMode = 'manual';
        end

        function val = get.MarkerEdgeColor(obj)
            val = obj.MarkerEdgeColor_I;
        end
        function set.MarkerEdgeColor(obj, val)
            obj.MarkerEdgeColor_I = val;
            obj.MarkerEdgeColorMode = 'manual';
        end

        function val = get.MarkerFaceAlpha(obj)
            val = obj.MarkerFaceAlpha_I;
        end
        function set.MarkerFaceAlpha(obj, val)
            validateattributes(val, {'numeric'}, {'scalar', ...
                                '>=', 0, '<=', 1});
            obj.MarkerFaceAlpha_I = val;
            obj.MarkerFaceAlphaMode = 'manual';
        end

        function val = get.MaskAlpha(obj)
            val = obj.MaskAlpha_I;
        end
        function set.MaskAlpha(obj, val)
            validateattributes(val, {'numeric'}, {'scalar', ...
                                '>=', 0, '<=', 1});
            obj.MaskAlpha_I = val;
            obj.MaskAlphaMode = 'manual';
        end

        function val = get.MarkerFaceColor(obj)
            val = obj.MarkerFaceColor_I;
        end
        function set.MarkerFaceColor(obj, val)
            obj.MarkerFaceColor_I = val;
            obj.MarkerFaceColorMode = 'manual';
        end

        function val = get.MaskColor(obj)
            val = obj.MaskColor_I;
        end
        function set.MaskColor(obj, val)
            obj.MaskColor_I = val;
            obj.MaskColorMode = 'manual';
        end

        function val = get.MarkerSizeData(obj)
            val = obj.MarkerSizeData_I;
        end
        function set.MarkerSizeData(obj, val)
            validateattributes(val, {'numeric'}, {'positive', 'vector', ...
                                'real', 'finite'});
            obj.MarkerSizeData_I = val(:).';
            obj.MarkerSizeDataMode = 'manual';
        end

        function val = get.LabelFontSize(obj)
            if strcmp(obj.LabelFontSizeMode, 'auto')
                val = [];
            else
                val = obj.LabelFontSize_I;
            end
        end
        function set.LabelFontSize(obj, val)
            validateattributes(val, {'numeric'}, {'scalar', 'positive', ...
                                'real', 'finite'});
            obj.LabelFontSize_I = val;
            obj.LabelFontSizeMode = 'manual';
        end

        function val = get.LegendVisible(obj)
            val = obj.LegendVisible_I;
        end

        function set.GroupData_I(obj, val)
            obj.GroupData_I = val;
            obj.CategoriesDirty = true;
            obj.ValidationDirty = true;
            % Since an update to the GroupData array can change the number
            % of elements in each internal scatter object, the color, data,
            % and marker size need to be updated. Otherwise, the scatter
            % object can throw an error.
            obj.ColorDirty = true;
            obj.DataDirty = true;
            obj.MarkerSizeDirty = true;
        end

        function set.AzimuthData_I(obj, val)
            obj.AzimuthData_I = val;
            obj.DataDirty = true;
            obj.ValidationDirty = true;
        end

        function set.ElevationData_I(obj, val)
            obj.ElevationData_I = val;
            obj.DataDirty = true;
            obj.ValidationDirty = true;
        end

        function set.LabelData_I(obj, val)
            displayVal = val;
            try
                if isempty(val)
                    val = [];
                    displayVal = val;
                    obj.LabelMode = 'off';
                else
                    if iscell(val)
                        val = string(val);
                    end
                    if isa(val, 'numeric')
                        validateattributes(val, {'numeric'}, {'integer', 'nonnegative'});
                        val = num2str(val(:));
                        val = string(cellstr(val));
                        val = val(:).';
                    else
                        validateattributes(val, {'string'}, {'vector'});
                    end
                    obj.LabelMode = 'on';
                end
            catch ME
                error(message('shared_mlskyplot:SkyPlotChart:InvalidLabelData', 'LabelData'));
            end
            obj.LabelData_I = val;
            obj.LabelDataDisplayValue = displayVal;

            obj.DataDirty = true;
            obj.LabelsDirty = true;
            obj.ValidationDirty = true;
        end

        function set.ColorOrder_I(obj, val)
            obj.ColorOrder_I = val;
            obj.ColorDirty = true;
        end

        function set.MarkerEdgeColor_I(obj, val)
            obj.MarkerEdgeColor_I = val;
            obj.ColorDirty = true;
        end
        function set.MarkerFaceColor_I(obj, val)
            obj.MarkerFaceColor_I = val;
            obj.ColorDirty = true;
        end

        function set.MarkerSizeData_I(obj, val)
            obj.MarkerSizeData_I = val;
            obj.MarkerSizeDirty = true;
            obj.ValidationDirty = true;
        end

        function set.LabelFontSize_I(obj, val)
            obj.LabelFontSize_I = val;
            obj.LabelFontSizeDirty = true;
        end
        function set.LabelFontSizeMode(obj, val)
            obj.LabelFontSizeMode = val;
            obj.LabelFontSizeDirty = true;
        end
    end

    methods (Access = protected)
        function setColorOrderInternal(obj, colors)
            obj.ColorOrder = colors;
        end

        function s = getTypeName(~)
        % Specify the object type.
            s = 'skyplot';
        end

        function setup(obj)
            tcl = getLayout(obj);
            ax = polaraxes(tcl);

            % Only use the axes color order if it has not been specified.
            if strcmp(obj.ColorOrderMode, 'auto')
                obj.ColorOrder_I = ax.ColorOrder;
            end

            polar2sky(ax);
            
            % Initial masked area.
            obj.MaskShade = matlab.graphics.chart.primitive.Histogram('Parent', ax, ...
                'BinEdges', [0 2*pi], 'HandleVisibility', 'off', 'LineStyle', 'none');
            dataTip = obj.MaskShade.DataTipTemplate;
            dataTip.DataTipRows = dataTipTextRow('Mask angle', 'BinCounts');
            % Uncomment when g2659210 is fixed. 
            % dataTip.DataTipRows = [
            %     dataTipTextRow('Mask angle', 'BinCounts'); 
            %     dataTipTextRow('Mask azimuth edges', 'BinEdges')];

            ax.Units = 'points';

            addlistener(ax,'OuterPositionChanged',@(~,~)obj.changeChartPosition);

            obj.Axes = ax;
        end

        function initScatters(obj)
            groups = obj.GroupData_I;
            if isempty(groups)
                az = obj.AzimuthData_I;
                dataLength = 0;
                if ~isempty(az)
                    dataLength = size(az(end,:));
                end
                groups = categorical( ...
                    false(dataLength), false, {'data1'});
            end
            catNames = categories(groups);
            scatters = obj.ScatterObjects;
            trackLines = obj.SatelliteTrackLines;
            numCategories = numel(catNames);
            numScatters = numel(scatters);
            if (numScatters ~= numCategories)
                if (numScatters < numCategories)
                    % Create scatter objects and ground track lines.
                    numNewScatters = numCategories - numScatters;
                    for i = 1:numNewScatters
                        h = matlab.graphics.chart.primitive.Scatter( ...
                            'Parent', obj.Axes, ...
                            'Marker', 'o');
                        scatters(end+1,:) = h; %#ok<AGROW> 
                        h = matlab.graphics.chart.primitive.Line( ...
                            'Parent', obj.Axes, 'HandleVisibility', 'off');
                        trackLines(end+1,:) = h; %#ok<AGROW> 
                    end
                elseif (numScatters > numCategories)
                    % Delete scatter objects and ground track lines.
                    delete(scatters(numCategories+1:end));
                    scatters = scatters(1:numCategories);
                    delete(trackLines(numCategories+1:end));
                    trackLines = trackLines(1:numCategories);
                end
            end
            obj.ScatterObjects = scatters;
            obj.SatelliteTrackLines = trackLines;

            % Set display names for scatter objects.
            for c = 1:numCategories
                scatters(c).DisplayName = catNames{c};
                % Change data tips to "Azimuth" and "Elevation" for
                % scatters.
                dataTip = scatters(c).DataTipTemplate;
                dataTip.DataTipRows = [
                    dataTipTextRow('Azimuth', 'ThetaData');
                    dataTipTextRow('Elevation', 'RData')];
                % Change data tips to "Azimuth" and "Elevation" for lines.
                dataTip = trackLines(c).DataTipTemplate;
                dataTip.DataTipRows = [
                    dataTipTextRow('Azimuth', 'ThetaData');
                    dataTipTextRow('Elevation', 'RData')];
            end
        end

        function initTexts(obj)
            labels = obj.LabelData_I;
            numDataPoints = numel(labels);
            texts = obj.TextObjects;
            numTexts = numel(texts);
            if (numTexts < numDataPoints)
                [az, el] = textPosition(obj);
                az = az(numTexts+1:numDataPoints);
                el = el(numTexts+1:numDataPoints);
                % Create text objects.
                texts(numTexts+1:numDataPoints) ...
                    = text(obj.Axes, az, el, ...
                           labels(numTexts+1:numDataPoints), ...
                           'HorizontalAlignment', 'center', ...
                           'VerticalAlignment', 'bottom', ...
                           'PickableParts', 'none');
            elseif (numTexts > numDataPoints)
                % Delete text objects.
                delete(texts(numDataPoints+1:end));
                texts = texts(1:numDataPoints);
            end
            obj.TextObjects = texts;

            if obj.LabelMode
                % Update labels on text objects.
                txts = obj.TextObjects;
                for i = 1:numel(txts)
                    txts(i).String = labels(i);
                end
                
                % Add label to data tips.
                scatters = obj.ScatterObjects;
                groups = obj.GroupData_I;
                if ~isempty(groups)
                    groupIndices = findgroups(groups);
                else
                    groupIndices = ones(1, numel(labels));
                end
                for c = 1:size(scatters, 1)
                    dataTip = scatters(c).DataTipTemplate;
                    rows = dataTip.DataTipRows;
                    if strcmp(rows(1).Label, 'Label')
                        rows = dataTip.DataTipRows;
                    else
                        rows = [matlab.graphics.datatip.DataTipTextRow; ...
                                rows]; %#ok<AGROW>
                        rows(1).Label = 'Label';
                    end
                    ind = (groupIndices == c);
                    catLabels = labels(ind);
                    if ~isscalar(catLabels)
                        val = catLabels;
                    else
                        val = {catLabels};
                    end
                    rows(1).Value = val;
                    dataTip.DataTipRows = rows;
                end
                % Update datatips on track lines.
                trackLines = obj.SatelliteTrackLines;
                for c = 1:size(trackLines, 1)
                    dataTip = trackLines(c).DataTipTemplate;
                    rows = dataTip.DataTipRows;
                    if strcmp(rows(1).Label, 'Label')
                        rows = dataTip.DataTipRows;
                    else
                        rows = [matlab.graphics.datatip.DataTipTextRow; ...
                                rows]; %#ok<AGROW>
                        rows(1).Label = 'Label';
                    end
                    ind = (groupIndices == c);
                    val = labels(ind);
                    numTrackDataPoints = size(obj.AzimuthData_I, 1);
                    val = repmat(val, numTrackDataPoints+1, 1);
                    val = val(:).';
                    rows(1).Value = val;
                    dataTip.DataTipRows = rows;
                end
            end
        end

        function [az, el] = textPosition(obj)
            allAz = obj.AzimuthData_I;
            az = [];
            if ~isempty(allAz)
                az = allAz(end,:);
            end
            allEl = obj.ElevationData_I;
            el = [];
            if ~isempty(allEl)
                el = allEl(end,:);
            end
            % Get text positions.
            th = deg2rad(90-az);
            r = 90-el;
            [xData, yData] = pol2cart(th, r);
            axPos = obj.Axes.Position_I;
            xPoints = (axPos(3))*(0.5 + xData/180);
            yPoints = (axPos(4))*(0.5 + yData/180);
            markerSizes = obj.MarkerSizeData_I;
            if isscalar(markerSizes)
                markerSizes = repmat(markerSizes, ...
                    size(yPoints, 1), size(yPoints, 2));
            end
            dyPoints = sqrt(markerSizes)/2;
            yPoints = yPoints + dyPoints;
            
            % Convert point values to data values. This conversion maps all
            % possible positive point values to +/- 90 data values.
            xData = 180*(xPoints / axPos(3)) - 90;
            yData = 180*(yPoints / axPos(4)) - 90;
            [th, r] = cart2pol(xData, yData);
            az = pi/2 - th;
            while any(az(:) < 0)
                az(az < 0) = az(az < 0) + 2*pi;
            end
            el = 90 - r;
        end
        
        function updateTextPosition(obj)
            [az, el] = textPosition(obj);
            
            texts = obj.TextObjects;
            for i = 1:numel(texts)
                texts(i).Position = [az(i), el(i)];
            end
        end

        function updateScatters(obj)
            scatters = obj.ScatterObjects;
            trackLines = obj.SatelliteTrackLines;
            numCategories = size(scatters, 1);
            groups = obj.GroupData_I;
            if isempty(groups)
                az = obj.AzimuthData_I;
                dataLength = 0;
                if ~isempty(az)
                    dataLength = size(az(end,:));
                end
                groups = categorical( ...
                    false(dataLength), false, {'data1'});
            end
            catNames = categories(groups);
            allAz = obj.AzimuthData_I;
            allEl = obj.ElevationData_I;
            numTimeSteps = size(allAz, 1);
            for c = 1:numCategories
                ind = (groups == catNames{c});
                h = scatters(c);
                az = [];
                if ~isempty(allAz)
                    az = allAz(end,ind);
                end
                el = [];
                if ~isempty(allEl)
                    el = allEl(end,ind);
                end
                set(h, 'RData', el, ...
                    'ThetaData', deg2rad(az));
                if numTimeSteps > 1
                    % Get azimuth and elevation data for current category. Use
                    % only one Line object to improve performance, and insert a
                    % "NaN" between each track to make it appear as multiple
                    % lines on the axes.
                    trackAz = allAz(:,ind);
                    trackAz(end+1,:) = NaN; %#ok<AGROW> 
                    trackAz = trackAz(:).';
                    trackEl = allEl(:,ind);
                    trackEl(end+1,:) = NaN; %#ok<AGROW> 
                    trackEl = trackEl(:).';
                    set(trackLines(c), ...
                        'RData', trackEl, ...
                        'ThetaData', deg2rad(trackAz));
                end
            end
        end

        function updateMarkerSizes(obj)
            if obj.MarkerSizeDirty
                scatters = obj.ScatterObjects;
                numCategories = size(scatters, 1);
                numDataPoints = 0;
                az = obj.AzimuthData_I;
                if ~isempty(az)
                    numDataPoints = numel(az(end,:));
                end
                groups = obj.GroupData_I;
                if isempty(groups)
                    dataLength = 0;
                    if ~isempty(az)
                        dataLength = size(az(end,:));
                    end
                    groups = categorical( ...
                        false(dataLength), false, {'data1'});
                end
                catNames = categories(groups);
                markerSizes = obj.MarkerSizeData;
                if isscalar(markerSizes)
                    markerSizes = repmat(markerSizes, 1, numDataPoints);
                end
                for c = 1:numCategories
                    ind = (groups == catNames{c});
                    h = scatters(c);
                    h.SizeData = markerSizes(ind);
                end

                % Label positions and font sizes are dependent on the marker
                % size. Update if needed.
                if obj.LabelMode
                    updateTextPosition(obj);
                    if strcmp(obj.LabelFontSizeMode, 'auto')
                        updateTextFontSize(obj);
                    end
                end
                obj.MarkerSizeDirty = false;
            end
        end

        function updateTextFontSize(obj)
        % Cache marker sizes and scalar expand if MarkerSizeData is
        % a scalar.
            texts = obj.TextObjects;
            numDataPoints = numel(texts);
            markerSizes = obj.MarkerSizeData;
            if isscalar(markerSizes)
                markerSizes = repmat(markerSizes, 1, numDataPoints);
            end
            if strcmp(obj.LabelFontSizeMode, 'manual')
                fontSizes = obj.LabelFontSize_I * ones(numDataPoints,1);
            else
                fontSizes = 0.7*sqrt(markerSizes);
            end
            for i = 1:numel(texts)
                texts(i).FontSize = fontSizes(i);
            end
        end

        function updateColors(obj)
            if obj.ColorDirty
                numCategories = numel(obj.ScatterObjects);
                % Cache marker colors for all categories.
                colorOrder = obj.ColorOrder_I;
                obj.Axes.ColorOrder = colorOrder;
                numColors = size(colorOrder, 1);
                colorIndices = mod((1:numCategories)-1, numColors)+1;
                if strcmp(obj.MarkerEdgeColor_I, 'flat')
                    edgeColors = colorOrder(colorIndices,:);
                else
                    edgeColors = repmat(obj.MarkerEdgeColor_I, ...
                        numCategories, 1);
                end
                if strcmp(obj.MarkerFaceColor_I, 'flat')
                    faceColors = colorOrder(colorIndices,:);
                else
                    faceColors = repmat(obj.MarkerFaceColor_I, ...
                        numCategories, 1);
                end

                groups = obj.GroupData_I;
                if isempty(groups)
                    dataLength = 0;
                    az = obj.AzimuthData_I;
                    if ~isempty(az)
                        dataLength = size(az(end,:));
                    end
                    groups = categorical( ...
                        false(dataLength), false, {'data1'});
                end
                catNames = categories(groups);
                for c = 1:numCategories
                    h = obj.ScatterObjects(c);
                    h.MarkerEdgeColor = edgeColors(c,:);
                    h.MarkerFaceColor = faceColors(c,:);

                    obj.SatelliteTrackLines(c).Color = faceColors(c,:);
                    if obj.LabelMode
                        ind = (groups == catNames{c});
                        texts = obj.TextObjects(ind);
                        set(texts, 'Color', faceColors(c,:));
                    end
                end
                obj.ColorDirty = false;
            end
        end

        function update(obj)
            updateValidation(obj);

            updateCategories(obj);

            updateLabels(obj);

            updateData(obj);

            updateColors(obj);
            
            updateMarkerSizes(obj);

            if obj.LabelMode && obj.LabelFontSizeDirty
                updateTextFontSize(obj);
                obj.LabelFontSizeDirty = false;
            end
            
            if obj.LegendLoadDirty
                obj.NeedsUpdate = false;
                legend(obj, obj.pLegendArgs{:});
                obj.LegendLoadDirty = false;
            end
            if obj.TitleLoadDirty
                title(obj, obj.pTitleArgs{:});
                obj.TitleLoadDirty = false;
            end
            if obj.SubtitleLoadDirty
                subtitle(obj, obj.pSubtitleArgs{:});
                obj.SubtitleLoadDirty = false;
            end

            if strcmp(obj.MaskElevationMode, 'manual')
                obj.MaskShade.BinEdges = deg2rad(obj.MaskAzimuthEdges_I);
                obj.MaskShade.BinCounts = obj.MaskElevation_I;
                
                maskAlpha = obj.MaskAlpha_I;
                maskColor = obj.MaskColor_I;
                set(obj.MaskShade, ...
                    'FaceColor', maskColor, ...
                    'EdgeColor', maskColor, ...
                    'EdgeAlpha', maskAlpha, ...
                    'FaceAlpha', maskAlpha);
            end

            set(obj.ScatterObjects, ...
                'MarkerEdgeAlpha', obj.MarkerEdgeAlpha, ...
                'MarkerFaceAlpha', obj.MarkerFaceAlpha);
        end
        
        function updateValidation(obj)
            if obj.ValidationDirty
                % Ensure all data arrays have the same number of elements.
                nav.graphics.chart.SkyPlotChart.validateAzElData( ...
                    obj.AzimuthData, obj.ElevationData, obj.LabelData, ...
                    obj.GroupData, obj.MarkerSizeData);

                % Trigger dependent updates if the data length has changed.
                dataLength = 0;
                az = obj.AzimuthData_I;
                if ~isempty(az)
                    dataLength = numel(az(end,:));
                end
                prevDataLength = obj.PrevDataLength;
                if (prevDataLength ~= dataLength)
                    obj.MarkerSizeDirty = true;
                    obj.PrevDataLength = dataLength;
                end

                % Trigger dependent updates if more labels were added.
                numLabels = numel(obj.LabelData_I);
                if obj.LabelMode
                    if (obj.PrevNumLabels < numLabels)
                        obj.ColorDirty = true;
                        obj.LabelFontSizeDirty = true;
                    end
                end
                obj.PrevNumLabels = numLabels;

                % Ensure that the mask elevation and azimuth are compatible
                % sizes.
                if strcmp(obj.MaskAzimuthEdgesMode, 'manual')
                    numMaskEl = numel(obj.MaskElevation_I);
                    numMaskAz = numel(obj.MaskAzimuthEdges_I);
                    assert((numMaskEl+1) == numMaskAz, ...
                        message('shared_mlskyplot:SkyPlotChart:InvalidMaskDataLengths', ...
                        'MaskAzimuthEdges', 'MaskElevation', ...
                        'MaskAzimuthEdgesMode', 'manual'));
                end

                obj.ValidationDirty = false;
            end
        end
        
        function updateCategories(obj)
            if obj.CategoriesDirty
                initScatters(obj);
                obj.CategoriesDirty = false;
            end
        end
        
        function updateLabels(obj)
            if obj.LabelsDirty
                initTexts(obj);
                obj.LabelsDirty = false;
            end
        end
        
        function updateData(obj)
            if obj.DataDirty
                updateScatters(obj);
                if obj.LabelMode
                    updateTextPosition(obj);
                end
                obj.DataDirty = false;
            end
        end
    end

    methods (Access = protected)
        function groups =  getPropertyGroups(obj)
            props = {'AzimuthData','ElevationData','LabelData'};
            if strcmp(obj.MaskElevationMode, 'manual')
                props{end+1} = 'MaskElevation';
            end
            if numel(obj.MaskElevation) > 1
                props{end+1} = 'MaskAzimuthEdges';
            end
            groups = matlab.mixin.util.PropertyGroup(props);
        end
        
        function changeChartPosition(obj)
            oldOuterPosition = obj.pOuterPosition;
            ax = getAxes(obj);
            if any(ax.OuterPosition_I(:) ~= oldOuterPosition(:))
                updateTextPosition(obj);
                obj.pOuterPosition = ax.OuterPosition_I;
            end
        end
    end

    methods (Static, Hidden)
        function validateAzElData(az, el, labels, groups, markerSizes)
            if (nargin < 5)
                markerSizes = 1;
            end
            if (nargin < 4)
                groups = [];
            end
            if (nargin < 3)
                labels = [];
            end
            if iscolumn(az)
                az = az.';
            end
            if iscolumn(el)
                el = el.';
            end
            N = 0;
            if ~isempty(az)
                N = numel(az(end,:));
            end
            Nel = 0;
            if ~isempty(el)
                Nel = numel(el(end,:));
            end
            dataLengthsValid = (numel(az) == numel(el)) ...
                && (N == Nel) ...
                && (isempty(labels) || (N == numel(labels))) ...
                && (isempty(groups) || (N == numel(groups))) ...
                && (isscalar(markerSizes) || (N == numel(markerSizes)));
            assert(dataLengthsValid, message('shared_mlskyplot:SkyPlotChart:InvalidDataLengths'));
        end
    end
    
    methods (Hidden)
        function ignore = mcodeIgnoreHandle(~, ~)
            % Enable code generation.
            ignore = false;
        end
        
        function mcodeConstructor(obj, code)
            
            % Call the superclass mcodeConstructor to handle Position and
            % Parent properties, and subplot.
            mcodeConstructor@matlab.graphics.chart.internal.PositionableChartWithAxes(obj,code)
            
            % Use skyplot() command to create objects.
            setConstructorName(code, 'skyplot');
            
            ignoreProperty(code, 'AzimuthData');
            ignoreProperty(code, 'ElevationData');
            ignoreProperty(code, 'LabelData');
            ignoreProperty(code, 'GroupData');
            
            azArg = codegen.codeargument('Name', 'az', ...
                'Value', obj.AzimuthData, ...
                'IsParameter', true, 'Comment', 'skyplot az');
            addConstructorArgin(code, azArg);
            
            elArg = codegen.codeargument('Name', 'el', ...
                'Value', obj.ElevationData, ...
                'IsParameter', true, 'Comment', 'skyplot el');
            addConstructorArgin(code, elArg);
            
            if ~isempty(obj.LabelData)
                labelArg = codegen.codeargument('Name', 'labels', ...
                    'Value', obj.LabelData, ...
                    'IsParameter', true, 'Comment', 'skyplot labels');
                addConstructorArgin(code, labelArg);
            end
            
            if ~isempty(obj.GroupData)
                groupNameArg = codegen.codeargument( ...
                    'Value', "GroupData", ...
                    'IsParameter', false, ...
                    'ArgumentType', codegen.ArgumentType.PropertyName);
                addConstructorArgin(code, groupNameArg);
                groupArg = codegen.codeargument('Name', 'groups', ...
                    'Value', obj.GroupData, ...
                    'IsParameter', true, ...
                    'ArgumentType', codegen.ArgumentType.PropertyValue, ...
                    'Comment', 'skyplot GroupData');
                addConstructorArgin(code, groupArg);
            end
            
            generateDefaultPropValueSyntax(code);
            
            % Add title.
            titleArgs = obj.pTitleArgs;
            if ~isempty(titleArgs)
                titlefunc = codegen.codefunction('Name', 'title', 'CodeRef', code);
                addPostConstructorFunction(code, titlefunc);
                for i = 1:numel(titleArgs)
                    arg = codegen.codeargument('Value', titleArgs{i});
                    addArgin(titlefunc, arg);
                end
            end
            
            % Add legend.
            legendArgs = obj.pLegendArgs;
            if obj.LegendVisible || ~isempty(legendArgs)
                legendfunc = codegen.codefunction('Name', 'legend', 'CodeRef', code);
                addPostConstructorFunction(code, legendfunc);
                for i = 1:numel(legendArgs)
                    arg = codegen.codeargument('Value', legendArgs{i});
                    addArgin(legendfunc, arg);
                end
            end
        end
        
        function h = getGraphicsPrimitive(obj, prop)
            h = obj.(prop);
        end
    end
end

function polar2sky(ax)
% Convert polar axes to sky plot axes
    ax.ThetaLim = [0 360];
    ax.RLim = [0 90];
    ax.ThetaDir = 'clockwise';
    ax.ThetaZeroLocation = 'top';
    deg = char(176);
    % Add cardinal directions and degrees to azimuth angles.
    thetaTicks = {'N', ['30', deg], ['60', deg], ... 
        'E', ['120', deg], ['150', deg], ...
        'S', ['210', deg], ['240', deg], ...
        'W', ['300', deg], ['330', deg]};
    ax.ThetaTickLabel = thetaTicks;
    % Add degrees to elevation angles.
    rTicks = {['0', deg], ['20', deg], ['40', deg], ['60', deg], ...
        ['80', deg]};
    ax.RTickLabel = rTicks;
    ax.RDir = 'reverse';
    ax.RAxisLocation = 270;
end
