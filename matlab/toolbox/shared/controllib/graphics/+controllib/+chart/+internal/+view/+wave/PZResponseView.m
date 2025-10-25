classdef PZResponseView < controllib.chart.internal.view.wave.BaseResponseView & ...
        controllib.chart.internal.foundation.MixInTimeUnit & ...
        controllib.chart.internal.foundation.MixInFrequencyUnit
    % PZResponseView

    % Copyright 2021-2023 The MathWorks, Inc.

    %% Protected properties
    properties (SetAccess = protected)
        PoleMarkers
        ZeroMarkers

        RealAxis
        ImaginaryAxis
        UnitCircle
    end

    %% Public methods
    methods
        function this = PZResponseView(response,optionalInputs)            
            arguments
                response (1,1) controllib.chart.response.PZResponse
                optionalInputs.ArrayVisible logical = response.ArrayVisible
            end
            this@controllib.chart.internal.foundation.MixInTimeUnit(response.TimeUnit);
            this@controllib.chart.internal.foundation.MixInFrequencyUnit(response.FrequencyUnit);
            optionalInputs = namedargs2cell(optionalInputs);
            this@controllib.chart.internal.view.wave.BaseResponseView(response,optionalInputs{:});
            build(this);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function createResponseObjects(this)
            this.PoleMarkers = createGraphicsObjects(this,"scatter",1,1,this.Response.NResponses,...
                Tag='PZPoleScatter');
            set(this.PoleMarkers,'Marker','x');

            this.ZeroMarkers = createGraphicsObjects(this,"scatter",1,1,this.Response.NResponses,...
                Tag='PZZeroScatter');
            set(this.ZeroMarkers,'Marker','o');
        end

        function createSupportingObjects(this)
            % Imaginary Axis
            this.ImaginaryAxis = createGraphicsObjects(this,"constantLine",1,1,1,...
                HitTest="off",PickableParts="none",Tag='PZImaginaryAxisLine');            
            this.ImaginaryAxis.InterceptAxis = 'x';
            this.ImaginaryAxis.Value = 0;
            this.ImaginaryAxis.LineStyle = ':';
            controllib.plot.internal.utils.setColorProperty(this.ImaginaryAxis,...
                "Color","--mw-graphics-colorNeutral-line-primary");
            % Real Axis
            this.RealAxis = createGraphicsObjects(this,"constantLine",1,1,1,...
                HitTest="off",PickableParts="none",Tag='PZRealAxisLine');
            this.RealAxis.InterceptAxis = 'y';
            this.RealAxis.Value = 0;
            this.RealAxis.LineStyle = ':';
            controllib.plot.internal.utils.setColorProperty(this.RealAxis,...
                "Color","--mw-graphics-colorNeutral-line-primary");
            % Unit Circle
            this.UnitCircle = createGraphicsObjects(this,"rectangle",1,1,1,...
                HitTest="off",PickableParts="none",Tag='PZUnitCircle');
            this.UnitCircle.Position = [-1 -1 2 2];
            this.UnitCircle.Curvature = [1 1];
            this.UnitCircle.LineStyle = ':';
            controllib.plot.internal.utils.setColorProperty(this.UnitCircle,...
                "EdgeColor","--mw-graphics-colorNeutral-line-primary");
        end

        function legendLine = createLegendObjects(this)
            % Create empty line for legend
            legendLine = createGraphicsObjects(this,"line",1,1,1,...
                DisplayName=strrep(this.Response.Name,'_','\_'));
        end

        function responseObjects = getResponseObjects_(this,~,~,ka)
            responseObjects = cat(3,this.PoleMarkers(ka),this.ZeroMarkers(ka));
        end

        function supportingObjects = getSupportingObjects_(this,~,~,~)
            supportingObjects = cat(3,this.ImaginaryAxis,this.RealAxis,this.UnitCircle);
        end

        function updateResponseData(this)
            conversionFcn = getTimeUnitConversionFcn(this,this.TimeUnit,this.Response.TimeUnit);
            for ka = 1:this.Response.NResponses
                this.PoleMarkers(1,1,ka).XData = 1./conversionFcn(1./real(this.Response.ResponseData.Poles{ka}));
                this.PoleMarkers(1,1,ka).YData = 1./conversionFcn(1./imag(this.Response.ResponseData.Poles{ka}));

                this.ZeroMarkers(1,1,ka).XData = 1./conversionFcn(1./real(this.Response.ResponseData.Zeros{ka}));
                this.ZeroMarkers(1,1,ka).YData = 1./conversionFcn(1./imag(this.Response.ResponseData.Zeros{ka}));
                if this.IsResponseDataTipsCreated
                    poleValue = this.Response.ResponseData.Poles{ka};
                    [dampingRow,frequencyRow,overshootRow] = getDampingFrequencyOvershootRows(this,...
                        poleValue,this.Response.ResponseData.Ts);
                    this.replaceDataTipRowValue(this.PoleMarkers(1,1,ka),...
                        getString(message('Controllib:plots:strDamping')),dampingRow.Value);
                    this.replaceDataTipRowValue(this.PoleMarkers(1,1,ka),...
                        getString(message('Controllib:plots:strFrequency')),frequencyRow.Value);
                    this.replaceDataTipRowValue(this.PoleMarkers(1,1,ka),...
                        getString(message('Controllib:plots:strOvershoot')),overshootRow.Value);
                    zeroValue = this.Response.ResponseData.Zeros{ka};
                    [dampingRow,frequencyRow,overshootRow] = getDampingFrequencyOvershootRows(this,...
                        zeroValue,this.Response.ResponseData.Ts);
                    this.replaceDataTipRowValue(this.ZeroMarkers(1,1,ka),...
                        getString(message('Controllib:plots:strDamping')),dampingRow.Value);
                    this.replaceDataTipRowValue(this.ZeroMarkers(1,1,ka),...
                        getString(message('Controllib:plots:strFrequency')),frequencyRow.Value);
                    this.replaceDataTipRowValue(this.ZeroMarkers(1,1,ka),...
                        getString(message('Controllib:plots:strOvershoot')),overshootRow.Value);
                end
            end
            % Show/hide unit circle
            this.UnitCircle.Visible = this.Response.IsDiscrete;
        end

        function createResponseDataTips_(this,~,~,ka,nameDataTipRow,~,customDataTipRows)
            % Create data tip for all lines
            % Pole value row
            poleValue = this.Response.ResponseData.Poles{ka};
            poleValueRow = dataTipTextRow(getString(message('Controllib:plots:strPole')),...
                @(x,y) this.getPZString(x,y));
            % Damping, Overshoot, Frequency
            [dampingRow,frequencyRow,overshootRow] = ...
                getDampingFrequencyOvershootRows(this,poleValue,this.Response.ResponseData.Ts);
            % Assign data tip template
            this.PoleMarkers(ka).DataTipTemplate.DataTipRows = [nameDataTipRow; poleValueRow; dampingRow;...
                overshootRow; frequencyRow; customDataTipRows(:)];

            % Zero value row
            zeroValue = this.Response.ResponseData.Zeros{ka};
            zeroValueRow = dataTipTextRow(getString(message('Controllib:plots:strZero')),...
                @(x,y) this.getPZString(x,y));
            % Damping, Overshoot, Frequency
            [dampingRow,frequencyRow,overshootRow] = ...
                getDampingFrequencyOvershootRows(this,zeroValue,this.Response.ResponseData.Ts);
            % Assign data tip template
            this.ZeroMarkers(ka).DataTipTemplate.DataTipRows = [nameDataTipRow; zeroValueRow; dampingRow;...
                overshootRow;frequencyRow; customDataTipRows(:)];
        end

        function cbTimeUnitChanged(this,conversionFcn)
            for ka = 1:this.Response.NResponses
                % Pole markers
                this.PoleMarkers(ka).XData = 1./(conversionFcn(1./this.PoleMarkers(ka).XData));
                this.PoleMarkers(ka).YData = 1./(conversionFcn(1./this.PoleMarkers(ka).YData));

                % Zero markers
                this.ZeroMarkers(ka).XData = 1./(conversionFcn(1./this.ZeroMarkers(ka).XData));
                this.ZeroMarkers(ka).YData = 1./(conversionFcn(1./this.ZeroMarkers(ka).YData));
            end
        end

        function cbFrequencyUnitChanged(this,conversionFcn)
            for ka = 1:this.Response.NResponses
                % Pole Markers
                this.PoleMarkers(ka).DataTipTemplate.DataTipRows(end).Label = getString(message('Controllib:plots:strFrequency')) + ...
                    " (" + this.FrequencyUnit + ")";
                this.PoleMarkers(ka).DataTipTemplate.DataTipRows(end).Value = ...
                    conversionFcn(this.PoleMarkers(ka).DataTipTemplate.DataTipRows(end).Value);
                % Zero Markers
                this.ZeroMarkers(ka).DataTipTemplate.DataTipRows(end).Label = getString(message('Controllib:plots:strFrequency')) + ...
                    " (" + this.FrequencyUnit + ")";
                this.ZeroMarkers(ka).DataTipTemplate.DataTipRows(end).Value = ...
                    conversionFcn(this.ZeroMarkers(ka).DataTipTemplate.DataTipRows(end).Value);
            end
        end
    end

    %% Private methods
    methods (Access=private)
        function [dampingRow,frequencyRow,overshootRow] = getDampingFrequencyOvershootRows(this,value,Ts)
            [wn,zeta] = damp(value,abs(Ts));
            % Convert frequency
            conversionFcn = getFrequencyUnitConversionFcn(this,'rad/s',this.FrequencyUnit);
            wn = conversionFcn(wn);
            dampingRow = dataTipTextRow(getString(message('Controllib:plots:strDamping')),zeta,'%0.3g');
            frequencyRow = dataTipTextRow(getString(message('Controllib:plots:strFrequency')) + ...
                " (" + this.FrequencyUnit + ")",wn,'%0.3g');
            % Percentage Peak Overshoot
            ppo = exp(-pi*zeta./sqrt((1-zeta).*(1+zeta))); % equiv to exp(-z*pi/sqrt(1-z^2))
            ppo = round(1e6*ppo)/1e4; % round off small values
            ppo(abs(zeta)==1) = 0;
            overshootRow = dataTipTextRow(getString(message('Controllib:plots:strOvershoot')) + " (%)",ppo,'%0.3g');
        end
    end

    %% Static sealed protected methods
    methods (Static,Sealed,Access=protected)
        function poleLabel = getPZString(realPart,imagPart)
            if realPart == 0 && imagPart == 0
                poleLabel = '0';
            elseif imagPart == 0
                poleLabel = sprintf('%0.3g',realPart);
            else
                if imagPart > 0
                    poleLabel = [sprintf('%0.3g',realPart) ' + ' sprintf('%0.3g',imagPart) 'i'];
                else
                    poleLabel = [sprintf('%0.3g',realPart) ' - ' sprintf('%0.3g',abs(imagPart)) 'i'];
                end
            end
        end
    end
end