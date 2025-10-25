classdef (UseClassDefaultsOnLoad, ConstructOnLoad) DonutChart < matlab.graphics.chart.internal.AbstractPieChart
    %

    %   Copyright 2023-2024 The MathWorks, Inc.

    properties (Dependent, UsedInUpdate=false, Resettable=false)
        InnerRadius matlab.internal.datatype.matlab.graphics.datatype.ZeroToOne = 0.6
        CenterLabel matlab.internal.datatype.matlab.graphics.datatype.NumericOrString = ''
        CenterLabelFontSize matlab.internal.datatype.matlab.graphics.datatype.Positive = 10
    end

    properties (Hidden, AbortSet)
        InnerRadius_I matlab.internal.datatype.matlab.graphics.datatype.ZeroToOne = 0.6
        CenterLabel_I matlab.internal.datatype.matlab.graphics.datatype.NumericOrString = ''
    end

    properties (Hidden, AbortSet, UsedInUpdate=false)
        CenterLabelFontSize_I matlab.internal.datatype.matlab.graphics.datatype.Positive = 10
    end

    % Documented Mode properties
    properties
        CenterLabelFontSizeMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
    end

    % Non-documented Mode properties
    properties (Hidden)
        InnerRadiusMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        CenterLabelMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
    end

    properties (Access={?tPieChartObject}, Transient, NonCopyable, UsedInUpdate=false)
        HoleText
    end

    methods
        function set.InnerRadius(obj,val)
            obj.InnerRadius_I=val;
            obj.InnerRadiusMode='manual';
        end
        function val = get.InnerRadius(obj)
            val = obj.InnerRadius_I;
        end

        function set.CenterLabel(obj,val)
            obj.CenterLabel_I=val;
            obj.CenterLabelMode='manual';
        end
        function val = get.CenterLabel(obj)
            val = obj.CenterLabel_I;
        end

        function set.CenterLabelFontSize(obj,val)
            obj.CenterLabelFontSize_I=val;
            obj.CenterLabelFontSizeMode='manual';
        end
        function val = get.CenterLabelFontSize(obj)
            if obj.CenterLabelFontSizeMode=="auto"
                obj.autocalcUpdate
            end
            val = obj.CenterLabelFontSize_I;
        end
    end

    methods(Access={?tPieChartObject,?matlab.graphics.chart.DonutChart})
        function radii = getRadii(obj)
            radii = [obj.InnerRadius_I 1];
        end
    end

    methods(Access=protected)
        function t = getTypeName(~)
            t = 'donutchart';
        end

        function updateLabels(obj)
            if isempty(obj.HoleText)
                obj.HoleText = text(obj.getAxes(),0,0,'',...
                                'FontSize',10,...
                                'PickableParts','none',...
                                'HorizontalAlignment','center',...
                                'VerticalAlignment','middle',...
                                'Layer','front');
            end
            obj.HoleText.String = obj.CenterLabel;
            obj.HoleText.Color = obj.FontColor;
            obj.HoleText.FontName = obj.FontName;
            obj.HoleText.Interpreter = obj.Interpreter;

            minFontSize = 1;
            usingTeXFontSize = any(contains(obj.CenterLabel,"\fontsize{"));
            if obj.CenterLabelFontSizeMode == "auto" && ~usingTeXFontSize

                % Compute auto-scaled FontSize for center label only when
                % non-empty.
                if ~isempty(obj.CenterLabel)
                    fs = obj.HoleText.FontSize;

                    % Toggle backtrace off before querying the extents, as
                    % this may throw an autocalc warning (i.e. in case of
                    % invalid interpreter markup.)
                    warningstatus = warning('OFF', 'BACKTRACE');
                    textExtents = obj.HoleText.Extent;
                    warning(warningstatus);

                    % Querying HoleText.Extent above may trigger additional
                    % updates, which can result in the stored fs value
                    % becoming stale. In this case, the scaling will have
                    % been taken care of by the other updates, so return
                    % early.
                    if obj.HoleText.FontSize ~= fs
                        return;
                    end

                    r_width = textExtents(2) + textExtents(4);

                    paddingFactor = 0.95; % leave a bit of extra room around label
                    scaleFactor = obj.InnerRadius * paddingFactor/r_width;

                    % Don't proceed to actually rescaling if the factor is
                    % close to 1.
                    if abs(scaleFactor-1) <= 0.02
                        return;
                    end

                    newFS = fs * scaleFactor;
                    newFS = floor(newFS*10)/10;
                    newFS = max(minFontSize, newFS);
                    obj.CenterLabelFontSize_I = newFS;
                    obj.HoleText.FontSize = newFS;
                else
                    obj.CenterLabelFontSize_I = obj.FontSize_I;
                    obj.HoleText.FontSize = obj.FontSize_I;
                end
            else
                % In "manual" case, simply pass through the font size.
                obj.HoleText.FontSize = obj.CenterLabelFontSize_I;
            end
            obj.HoleText.Visible = obj.CenterLabelFontSize_I > minFontSize;
        end
    end
end
