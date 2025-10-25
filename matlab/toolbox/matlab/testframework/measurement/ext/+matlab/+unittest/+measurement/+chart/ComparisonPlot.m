classdef (Sealed) ComparisonPlot < matlab.graphics.chartcontainer.ChartContainer & ...
        matlab.graphics.chartcontainer.mixin.Legend
    % ComparisonPlot - Compare two datasets using a scatter plot.
    %
    %   The ComparisonPlot class provides visualization to compare two 
    %   datasets, namely, baseline and measurement data, using a 2-D 
    %   scatter plot. The baseline and measurement datasets are mapped to 
    %   x and y axes, respectively. The plot also includes a border region 
    %   around line y = x. If the relative difference between a measurement
    %   value and a baseline value falls within the border region, the 
    %   corresponding data point is marked as "similar". If the data point
    %   lies below the border region (i.e., the measurement value is 
    %   smaller than the baseline value), it represents an improvement and
    %   is depicted in blue. Conversely, if the data point lies above the 
    %   border region, it represents a regression in performance and is
    %   depicted in orange.
    %
    %   ComparisonPlot properties:
    %       Scale                  - Scale of both x and y axes (default value: 'log')
    %       SimilarityTolerance    - Tolerance specified for disqualifying a data
    %                                point from representing either an improvement
    %                                or a regression in performance. The value 
    %                                of the tolerance determines the width of the
    %                                border region in the scatter plot.

    % Copyright 2018-2021 The MathWorks, Inc.
    
    properties
        Scale (1,1) string {mustBeMember(Scale, {'linear', 'log'})} = 'log';
        SimilarityTolerance (1,1) double {mustBeNumeric, mustBeNonnegative, mustBeLessThan(SimilarityTolerance,1)} = .1;
    end
    
    properties(Hidden)
        SourceTable
        BaselineData (1,:) double = [];
        MeasurementData (1,:) double = [];
        Valid (1,:) logical = [];
        MarkerSize {mustBeNumeric, mustBePositive} = 36;
        BaselineLabel = getString(message('MATLAB:unittest:measurement:ComparisonPlot:BaselineLabel'));
        MeasurementLabel = getString(message('MATLAB:unittest:measurement:ComparisonPlot:MeasurementLabel'));
        TitleLabel = getString(message('MATLAB:unittest:measurement:ComparisonPlot:Title'));
        BaselineDataNames
        MeasurementDataNames
    end
    
    properties(Hidden, SetAccess = immutable)
        RegressedLabel
        ImprovedLabel
    end
    
    properties(Hidden, Constant, Access = private)
        SimilarLabel = getString(message('MATLAB:unittest:measurement:ComparisonPlot:SimilarLabel'));
        InvalidLabel = getString(message('MATLAB:unittest:measurement:ComparisonPlot:InvalidLabel'));
        DataTipNameLabel = getString(message('MATLAB:unittest:measurement:ComparisonPlot:DataTipNameLabel'));
    end
    
    properties(Hidden, Dependent, SetAccess = private)
        OverallStat
        Categories (1,:) categorical
    end
    
    properties(Transient, SetAccess = private, Hidden, NonCopyable)
        % Hidden properties to access the internal graphics objects used
        PatchObject
        ValidScatterObject
        InvalidScatterObject

        XLabelHandle
        YLabelHandle
    end
    
    properties(Hidden, Dependent, Access = private)
        UniqueCategories
    end
    
    properties(Transient, Access=protected, NonCopyable)
        LegendPoints (1,:) matlab.graphics.chart.primitive.Scatter
    end

    properties(Dependent)
        Title matlab.internal.datatype.matlab.graphics.datatype.NumericOrString
    end
    
    methods % Axes Interfaces
        function set.Title(obj,str)
            obj.TitleLabel = str;
        end
        
        function str = get.Title(obj)
            str = obj.TitleLabel;
        end
        
        function set.TitleLabel(obj,str)
            if isvalid(obj.getAxes.Title)
                TitleHandle = obj.getAxes.Title;
                TitleHandle.String_I = str;
            end
            obj.TitleLabel = str;
        end
    end
    
    methods(Hidden)
        function ch = ComparisonPlot(regressedlabel, improvedlabel, varargin)
            % Hide the constructor
            if nargin < 2
                regressedlabel = getString(message('MATLAB:unittest:measurement:ComparisonPlot:RegressedLabel'));
                improvedlabel = getString(message('MATLAB:unittest:measurement:ComparisonPlot:ImprovedLabel'));
            end
            ch = ch@matlab.graphics.chartcontainer.ChartContainer(varargin{:});
            ch.RegressedLabel = regressedlabel;
            ch.ImprovedLabel = improvedlabel;
        end
                
        function v = hasZProperties(~)
            v = false;
        end
    end
    
    methods(Hidden, Access=protected)
        function tf = useGcaBehavior(~)
            % If false create a new object each time
            tf = false;
        end
        
        function varargout =  getPropertyGroups(~)
            varargout{1} = matlab.mixin.util.PropertyGroup(...
                {'Scale', 'SimilarityTolerance'});
        end
    end
    
    methods
        function set.BaselineLabel(obj, value)
            validateattributes(value, {'char', 'string'}, {'scalartext'}, ...
                '', 'BaselineLabel');
            obj.BaselineLabel = value;
        end
        
        function set.MeasurementLabel(obj, value)
            validateattributes(value, {'char', 'string'}, {'scalartext'}, ...
                '', 'MeasurementLabel');
            obj.MeasurementLabel = value;
        end
        
        function set.BaselineDataNames(obj, value)
            validateattributes(value, {'string'}, {}, ...
                '', 'BaselineDataNames');
            obj.BaselineDataNames = value;
        end
        
        function set.MeasurementDataNames(obj, value)
            validateattributes(value, {'string'}, {}, ...
                '', 'MeasurementDataNames');
            obj.MeasurementDataNames = value;
        end
    end
    
    methods(Access = protected, Hidden)
        
        function setup(obj)
            % Create the internal graphics objects. This function is called
            % only during creation. Use this function to do any intial
            % setup and make any one-time customizations.
            grid(obj.getAxes, 'on');
            hold(obj.getAxes, 'on');
            obj.getAxes.MinorGridLineStyle = 'none';
            
            obj.PatchObject = obj.setupReferencePatch();
            obj.ValidScatterObject = obj.setupValidScatter();
            obj.InvalidScatterObject = obj.setupInvalidScatter();
            
            obj.XLabelHandle = obj.getAxes.XLabel;
            obj.YLabelHandle = obj.getAxes.YLabel;
            
            % Add listeners to the axes title and labels so that when they
            % are interactively edited, the chart properties are updated
            
            addlistener(obj.getAxes.Title, 'String', 'PostSet', ...
                @(~,~)set(obj, 'Title', obj.getAxes.Title.String_I));
            
            addlistener(obj.getAxes.XLabel, 'String', 'PostSet', ...
                @(~,~)set(obj, 'BaselineLabel', obj.getAxes.XLabel.String_I));
            
            addlistener(obj.getAxes.YLabel, 'String', 'PostSet', ...
                @(~,~)set(obj, 'MeasurementLabel', obj.getAxes.YLabel.String_I));
            
        end
        
        function update(obj,~)
            % This function is called every time one of the properties in the
            % public properties block changes. Use this function to react
            % to those changes (e.g. resetting properties of the internal
            % graphics objects).
            
            obj.getAxes.InteractionContainer.Enabled = 'on';
            set(obj.getAxes, 'XScale', obj.Scale, 'YScale', obj.Scale)

            obj.XLabelHandle.String = obj.BaselineLabel;
            obj.YLabelHandle.String = obj.MeasurementLabel;
            
            if ~obj.ready2update
                return
            end
            
            xymin = min([obj.BaselineData obj.MeasurementData]) * 0.9;
            xymax = max([obj.BaselineData obj.MeasurementData]) * 1.1;
            if ~isnan(xymin) && ~isnan(xymax)
                xlim(obj.getAxes, [xymin, xymax]);
                ylim(obj.getAxes, [xymin, xymax]);
            end
            
            x = linspace(xymin, xymax, 3); % At least three points to work on log scale
            obj.PatchObject.XData = [x, flip(x)];
            obj.PatchObject.YData = [(1 + obj.SimilarityTolerance) * x, (1 - obj.SimilarityTolerance) * flip(x)];
            
            obj.updateScatterObject();
            
            % Update legend
            if ~isempty(obj.getLegend)
                obj.updateLegendContents(obj.getLegend);
            end
        end
        
        function s = getTypeName(~)
            % Specify the object type.
            s = 'ComparisonPlot';
        end
        
    end
 
    methods (Hidden, Access = protected)
        function leg = createLegend(obj)
            % Create and customize the legend
            leg = matlab.graphics.illustration.Legend('Axes', obj.getAxes);
            leg.Location = 'southeast';
        end
    end
    
    methods (Hidden)
        function updateLegendContents(obj, leg)
            % legend is a handle object
            pctSimilarityTolerance = num2str(obj.SimilarityTolerance * 100);
            legendsForPatch = {getString(message('MATLAB:unittest:measurement:ComparisonPlot:SimilarityToleranceLabel', pctSimilarityTolerance))};

            uniqueCategories = obj.UniqueCategories;
            hold(obj.getAxes, 'on');
            delete(obj.LegendPoints);
            obj.LegendPoints = matlab.graphics.chart.primitive.Scatter.empty;
            for i = 1:numel(uniqueCategories)
                c = uniqueCategories(i);
                if c ~= "Invalid"
                    obj.LegendPoints(i) = obj.setupValidScatter();
                    obj.LegendPoints(i).CData = colorMap(c);
                else
                    obj.LegendPoints(i) = obj.setupInvalidScatter();
                    obj.LegendPoints(i).CData = colorMap(c);
                end
            end
            hold(obj.getAxes,'off');
            leg.PlotChildrenExcluded = [obj.ValidScatterObject, obj.InvalidScatterObject];
            leg.String = [legendsForPatch, obj.mapCategoriesToLegend(obj.UniqueCategories)];
            leg.PlotChildrenSpecified = [obj.LegendPoints, obj.PatchObject];
        end
        
        function reset(~)
            % No-op
        end
    end
    
    methods
        function categories = get.Categories(obj)
            
            if obj.ready2update
                categories = arrayfun(@(b,t,v)assignCategory(b,t,v,obj.SimilarityTolerance), ...
                    obj.BaselineData, obj.MeasurementData, obj.Valid);
            else               
                categories = categorical.empty;
            end
            
            function out = assignCategory(baseline, measurement, valid, tolerance)
                if valid
                    statsDiff = (measurement - baseline)/abs(baseline);
                    if statsDiff > tolerance
                        out = categorical({'Regressed'});
                    elseif statsDiff < -tolerance
                        out = categorical({'Improved'});
                    else
                        out = categorical({'Similar'});
                    end
                else
                    out = categorical({'Invalid'});
                end
            end
        end
        
        function stat = get.OverallStat(obj)
            isvalid = obj.Valid;
            stat = exp(sum(log(obj.MeasurementData(isvalid) ./ obj.BaselineData(isvalid)))...
                ./ numel(obj.BaselineData(isvalid))) - 1;
        end
        
        function categories = get.UniqueCategories(obj)
            uniqueCategories = unique(obj.Categories);
            categories = sort(categorical(uniqueCategories, ...
                {'Improved', 'Regressed', 'Similar', 'Invalid'}, 'ordinal', 1));
        end
    end
    
    methods(Access = private)
        
        function L = setupReferencePatch(obj)
            color = [0.5 0.5 0.5];
            opacity = .15;
            L = fill(obj.getAxes, NaN, NaN, color, 'FaceAlpha', opacity,...
                'EdgeColor','none');
            L.PickableParts = 'none';
        end
        
        function P = setupValidScatter(obj)
            P = scatter(obj.getAxes, NaN, NaN);
            P.Marker = 'o';
            P.MarkerFaceAlpha = 0.8;
            P.MarkerFaceColor = 'flat';
            P.MarkerEdgeColor = 'none';
        end
        
        function P = setupInvalidScatter(obj)
            P = scatter(obj.getAxes, NaN, NaN);
            P.Marker = 'x';
        end
        
        function updateScatterObject(obj)
            isvalid = obj.Valid;
            validRGBTriplets = cell2mat(arrayfun(@colorMap, obj.Categories, 'UniformOutput', false)');
            
            obj.ValidScatterObject.SizeData = obj.MarkerSize;
            obj.InvalidScatterObject.SizeData = obj.MarkerSize;
            
            obj.ValidScatterObject.XData = obj.BaselineData(isvalid);
            obj.ValidScatterObject.YData = obj.MeasurementData(isvalid);
            obj.ValidScatterObject.CData = validRGBTriplets(isvalid, :);
            
            obj.InvalidScatterObject.XData = obj.BaselineData(~isvalid);
            obj.InvalidScatterObject.YData = obj.MeasurementData(~isvalid);
            obj.InvalidScatterObject.CData = validRGBTriplets(~isvalid, :);
            
            if ~isempty(obj.BaselineDataNames) && ~isempty(obj.MeasurementDataNames)
                % Use customized DataTip if names are specified
                obj.updateDataTips;
            end            
        end
        
        function updateDataTips(obj)
            isvalid = obj.Valid;
            
            % Update the datatips of scatters via DataTipTemplate.
            % DataTip value for names must be cellstr otherwise it will 
            % look for variables from workspace. 
            r1 = dataTipTextRow(obj.DataTipNameLabel + ": ", cellstr(obj.BaselineDataNames(isvalid)));
            r2 = dataTipTextRow(obj.BaselineLabel + ": ", obj.BaselineData(isvalid));
            r3 = dataTipTextRow(obj.DataTipNameLabel + ": ", cellstr(obj.MeasurementDataNames(isvalid)));
            r4 = dataTipTextRow(obj.MeasurementLabel + ": ", obj.MeasurementData(isvalid));
            
            ir1 = dataTipTextRow(obj.DataTipNameLabel + ": ", cellstr(obj.BaselineDataNames(~isvalid)));
            ir2 = dataTipTextRow(obj.BaselineLabel + ": ", obj.BaselineData(~isvalid));
            ir3 = dataTipTextRow(obj.DataTipNameLabel + ": ", cellstr(obj.MeasurementDataNames(~isvalid)));
            ir4 = dataTipTextRow(obj.MeasurementLabel + ": ", obj.MeasurementData(~isvalid));
            
            validScatterDataTipTemplate = obj.ValidScatterObject.DataTipTemplate;
            invalidScatterDataTipTemplate = obj.InvalidScatterObject.DataTipTemplate;
            
            % Turn off Tex interpreter
            validScatterDataTipTemplate.Interpreter = 'none';
            invalidScatterDataTipTemplate.Interpreter = 'none';
            
            if all(strcmp(obj.BaselineDataNames, obj.MeasurementDataNames))
                validScatterDataTipTemplate.DataTipRows = [r1; r2; r4];
                invalidScatterDataTipTemplate.DataTipRows = [ir1; ir2; ir4];
            else
                validScatterDataTipTemplate.DataTipRows = [r1; r2; r3; r4];
                invalidScatterDataTipTemplate.DataTipRows = [ir1; ir2; ir3; ir4];
            end
        end
        
        function out = mapCategoriesToLegend(obj, categories)
            % Map the categories of results to legend labels as cellstr
            out = arrayfun(@(c){get(obj, string(c) + "Label")}, categories);
        end
        
        function bool = ready2update(obj)
            % Do not update the plot until all data is in ready state
            if isempty(obj.BaselineData) || isempty(obj.MeasurementData) ...
                    || isempty(obj.Valid) ...
                    || ~isequal(size(obj.BaselineData), size(obj.MeasurementData)) ...
                    || ~isequal(size(obj.BaselineData), size(obj.Valid))
                bool = false;
            else
                bool = true;
            end
        end
        
    end
    
end

function color = colorMap(type)
if type == "Invalid"
    color = [0 0 0]; % Black
elseif  type == "Similar"
    color = [0.5 0.5 0.5]; % Grey
elseif  type == "Improved"
    color = [0, 114, 189]/256; % Blue
elseif  type == "Regressed"
    color = [217, 83, 25]/256; % Orange
end
end
