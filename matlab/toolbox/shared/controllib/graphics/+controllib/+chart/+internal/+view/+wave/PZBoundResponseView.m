classdef PZBoundResponseView < controllib.chart.internal.view.wave.BaseResponseView & ...
        controllib.chart.internal.foundation.MixInTimeUnit & ...
        controllib.chart.internal.foundation.MixInFrequencyUnit
    % PZResponseView

    % Copyright 2021-2023 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        SpectralRadiusPatch
        SpectralAbscissaPatch

        RealAxis
        ImaginaryAxis
        UnitCircle
    end

    %% Constructor
    methods
        function this = PZBoundResponseView(response,optionalInputs)
            arguments
                response (1,1) controllib.chart.response.internal.PZBoundResponse
                optionalInputs.ArrayVisible logical = response.ArrayVisible
            end
            this@controllib.chart.internal.foundation.MixInTimeUnit(response.TimeUnit);
            this@controllib.chart.internal.foundation.MixInFrequencyUnit(response.FrequencyUnit);
            optionalInputs = namedargs2cell(optionalInputs);
            this@controllib.chart.internal.view.wave.BaseResponseView(response,optionalInputs{:});
            build(this);
        end
    end

    %% Public methods
    methods
        function updateSpectralLimits(this,XLimits,YLimits)
            response = getResponse(this.Response);
            updateSpectralLimits(response,XLimits,YLimits);
            updateResponseData(this);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function createResponseObjects(this)
            this.SpectralRadiusPatch = createGraphicsObjects(this,"patch",1,1,this.Response.NResponses,...
                Tag='PZBoundResponseSpectralRadius');
            this.disableDataTipInteraction(this.SpectralRadiusPatch);

            this.SpectralAbscissaPatch = createGraphicsObjects(this,"patch",1,1,this.Response.NResponses,...
                Tag='PZBoundResponseSpectralAbscissa');
            this.disableDataTipInteraction(this.SpectralAbscissaPatch);
        end

        function createSupportingObjects(this)
            % Imaginary Axis
            this.ImaginaryAxis = createGraphicsObjects(this,"constantLine",1,1,1,...
                HitTest="off",PickableParts="none",Tag='PZBoundImaginaryAxisLine');
            this.ImaginaryAxis.InterceptAxis = 'x';
            this.ImaginaryAxis.Value = 0;
            this.ImaginaryAxis.LineStyle = ':';
            controllib.plot.internal.utils.setColorProperty(this.ImaginaryAxis,...
                "Color","--mw-graphics-colorNeutral-line-primary");
            % Real Axis
            this.RealAxis = createGraphicsObjects(this,"constantLine",1,1,1,...
                HitTest="off",PickableParts="none",Tag='PZBoundRealAxisLine');
            this.RealAxis.InterceptAxis = 'y';
            this.RealAxis.Value = 0;
            this.RealAxis.LineStyle = ':';
            controllib.plot.internal.utils.setColorProperty(this.RealAxis,...
                "Color","--mw-graphics-colorNeutral-line-primary");
            % Unit Circle
            this.UnitCircle = createGraphicsObjects(this,"rectangle",1,1,1,...
                HitTest="off",PickableParts="none",Tag='PZBoundUnitCircle');
            this.UnitCircle.Position = [-1 -1 2 2];
            this.UnitCircle.Curvature = [1 1];
            this.UnitCircle.LineStyle = ':';
            controllib.plot.internal.utils.setColorProperty(this.UnitCircle,...
                "EdgeColor","--mw-graphics-colorNeutral-line-primary");
        end

        function responseLines = getResponseObjects_(this,~,~,ka)
            responseLines = cat(3,this.SpectralRadiusPatch(ka),this.SpectralAbscissaPatch(ka));
        end

        function supportingLines = getSupportingObjects_(this,~,~,~)
            supportingLines = cat(3,this.ImaginaryAxis,this.RealAxis,this.UnitCircle);
        end

        function updateResponseData(this)
            conversionFcn = getTimeUnitConversionFcn(this,this.TimeUnit,this.Response.TimeUnit);
            for ka = 1:this.Response.NResponses
                this.SpectralRadiusPatch(1,1,ka).XData = 1./conversionFcn(1./real(this.Response.ResponseData.SpectralRadius{ka}));
                this.SpectralRadiusPatch(1,1,ka).YData = 1./conversionFcn(1./imag(this.Response.ResponseData.SpectralRadius{ka}));

                this.SpectralAbscissaPatch(1,1,ka).XData = 1./conversionFcn(1./real(this.Response.ResponseData.SpectralAbscissa{ka}));
                this.SpectralAbscissaPatch(1,1,ka).YData = 1./conversionFcn(1./imag(this.Response.ResponseData.SpectralAbscissa{ka}));
            end
            % Show/hide unit circle
            if this.Response.IsDiscrete
                this.UnitCircle.Visible = 'on';
            else
                this.UnitCircle.Visible = 'off';
            end
        end

        function cbTimeUnitChanged(this,conversionFcn)
            for ka = 1:this.Response.NResponses
                this.SpectralRadiusPatch(1,1,ka).XData = 1./(conversionFcn(1./this.SpectralRadiusPatch(1,1,ka).XData));
                this.SpectralRadiusPatch(1,1,ka).YData = 1./(conversionFcn(1./this.SpectralRadiusPatch(1,1,ka).YData));

                this.SpectralAbscissaPatch(1,1,ka).XData = 1./(conversionFcn(1./this.SpectralAbscissaPatch(1,1,ka).XData));
                this.SpectralAbscissaPatch(1,1,ka).YData = 1./(conversionFcn(1./this.SpectralAbscissaPatch(1,1,ka).YData));
            end
        end
    end
end