classdef IOPZResponseView < controllib.chart.internal.view.wave.BaseResponseView & ...
        controllib.chart.internal.foundation.MixInTimeUnit & ...
        controllib.chart.internal.foundation.MixInFrequencyUnit
    % Class for managing lines and markers for an iopzplot
    
    % Copyright 2022-2023 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        PoleMarkers
        ZeroMarkers
        
        LegendLines
        RealAxes
        ImaginaryAxes
        UnitCircles
    end
    
    %% Constructor
    methods
        function this = IOPZResponseView(response,optionalInputs)            
            arguments
                response (1,1) controllib.chart.response.IOPZResponse
                optionalInputs.ColumnVisible (1,:) logical = true(1,response.NColumns);
                optionalInputs.RowVisible (:,1) logical = true(response.NRows,1);
                optionalInputs.ArrayVisible logical = response.ArrayVisible
            end
            this@controllib.chart.internal.foundation.MixInTimeUnit(response.TimeUnit);
            this@controllib.chart.internal.foundation.MixInFrequencyUnit(response.FrequencyUnit);

            optionalInputs.NRows = response.NRows;
            optionalInputs.NColumns = response.NColumns;

            optionalInputs = namedargs2cell(optionalInputs);
            this@controllib.chart.internal.view.wave.BaseResponseView(response,optionalInputs{:});
            build(this);
        end
    end
    
    %% Protected methods
    methods (Access = protected)
        function createCharacteristics(this,data)
            c = controllib.chart.internal.view.characteristic.BaseCharacteristicView.empty;
            % ConfidenceRegion
            if isprop(data,"ConfidenceRegion") && ~isempty(data.ConfidenceRegion)
                c = [c; controllib.chart.internal.view.characteristic.IOPZConfidenceRegionView(this,...
                        data.ConfidenceRegion)];
            end
            this.Characteristics = c;
        end

        function createResponseObjects(this)
            this.PoleMarkers = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='IOPZPoleScatter');
            set(this.PoleMarkers,'Marker','x');

            this.ZeroMarkers = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='IOPZZeroScatter');
            set(this.ZeroMarkers,'Marker','o');
        end

        function createSupportingObjects(this)
            % Imaginary Axis
            this.ImaginaryAxes = createGraphicsObjects(this,"constantLine",this.Response.NRows,...
                this.Response.NColumns,1,HitTest="off",PickableParts="none",Tag='IOPZImaginaryAxisLine');
            set(this.ImaginaryAxes,'InterceptAxis','x');
            set(this.ImaginaryAxes,'Value',0);
            set(this.ImaginaryAxes,'LineStyle',':');
            controllib.plot.internal.utils.setColorProperty(this.ImaginaryAxes,...
                "Color","--mw-graphics-colorNeutral-line-primary");
            % Real Axis
            this.RealAxes = createGraphicsObjects(this,"constantLine",this.Response.NRows,...
                this.Response.NColumns,1,HitTest="off",PickableParts="none",Tag='IOPZRealAxisLine');
            set(this.RealAxes,'InterceptAxis','y');
            set(this.RealAxes,'Value',0);
            set(this.RealAxes,'LineStyle',':');
            controllib.plot.internal.utils.setColorProperty(this.RealAxes,...
                "Color","--mw-graphics-colorNeutral-line-primary");
            % Unit Circle
            this.UnitCircles = createGraphicsObjects(this,"rectangle",this.Response.NRows,...
                this.Response.NColumns,1,HitTest="off",PickableParts="none",Tag='IOPZUnitCircle');
            set(this.UnitCircles,'Position',[-1 -1 2 2]);
            set(this.UnitCircles,'Curvature',[1 1]);
            set(this.UnitCircles,'LineStyle',':');
            controllib.plot.internal.utils.setColorProperty(this.UnitCircles,...
                "EdgeColor","--mw-graphics-colorNeutral-line-primary");
        end

        function legendLines = createLegendObjects(this)
            legendLines = createGraphicsObjects(this,"line",1,...
                1,1,DisplayName=strrep(this.Response.Name,'_','\_'));
        end

        function responseObjects = getResponseObjects_(this,ko,ki,ka)
            responseObjects = cat(3,this.PoleMarkers(ko,ki,ka),this.ZeroMarkers(ko,ki,ka));
        end

        function supportingObjects = getSupportingObjects_(this,ko,ki,~)
            supportingObjects = cat(3,this.ImaginaryAxes(ko,ki),this.RealAxes(ko,ki),this.UnitCircles(ko,ki));
        end

        function updateResponseData(this)
            conversionFcn = getTimeUnitConversionFcn(this,this.Response.TimeUnit,this.TimeUnit);
            for ka = 1:this.Response.NResponses
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        this.PoleMarkers(ko,ki,ka).XData = 1./conversionFcn(1./real(this.Response.ResponseData.Poles{ko,ki,ka}));
                        this.PoleMarkers(ko,ki,ka).YData = 1./conversionFcn(1./imag(this.Response.ResponseData.Poles{ko,ki,ka}));
                        this.ZeroMarkers(ko,ki,ka).XData = 1./conversionFcn(1./real(this.Response.ResponseData.Zeros{ko,ki,ka}));
                        this.ZeroMarkers(ko,ki,ka).YData = 1./conversionFcn(1./imag(this.Response.ResponseData.Zeros{ko,ki,ka}));
                        if this.IsResponseDataTipsCreated
                            poleValue = this.Response.ResponseData.Poles{ko,ki,ka};
                            [dampingRow,frequencyRow,overshootRow] = getDampingFrequencyOvershootRows(this,...
                                poleValue,this.Response.ResponseData.Ts);
                            this.replaceDataTipRowValue(this.PoleMarkers(ko,ki,ka),...
                                getString(message('Controllib:plots:strDamping')),dampingRow.Value);
                            this.replaceDataTipRowValue(this.PoleMarkers(ko,ki,ka),...
                                getString(message('Controllib:plots:strFrequency')),frequencyRow.Value);
                            this.replaceDataTipRowValue(this.PoleMarkers(ko,ki,ka),...
                                getString(message('Controllib:plots:strOvershoot')),overshootRow.Value);
                            zeroValue = this.Response.ResponseData.Zeros{ko,ki,ka};
                            [dampingRow,frequencyRow,overshootRow] = getDampingFrequencyOvershootRows(this,...
                                zeroValue,this.Response.ResponseData.Ts);
                            this.replaceDataTipRowValue(this.ZeroMarkers(ko,ki,ka),...
                                getString(message('Controllib:plots:strDamping')),dampingRow.Value);
                            this.replaceDataTipRowValue(this.ZeroMarkers(ko,ki,ka),...
                                getString(message('Controllib:plots:strFrequency')),frequencyRow.Value);
                            this.replaceDataTipRowValue(this.ZeroMarkers(ko,ki,ka),...
                                getString(message('Controllib:plots:strOvershoot')),overshootRow.Value);
                        end
                    end
                end
            end
            % Show/hide unit circle
            set(this.UnitCircles,Visible=this.Response.IsDiscrete);
        end

        function createResponseDataTips_(this,ko,ki,ka,nameDataTipRow,ioDataTipRow,customDataTipRows)
            % Create data tip for all lines
            % Pole value row
            poleValue = this.Response.ResponseData.Poles{ko,ki,ka};
            poleValueRow = dataTipTextRow(getString(message('Controllib:plots:strPole')),...
                @(x,y) this.getPZString(x,y));
            % Damping, Overshoot, Frequency
            [dampingRow,frequencyRow,overshootRow] = ...
                getDampingFrequencyOvershootRows(this,poleValue,this.Response.ResponseData.Ts);
            % Assign data tip template
            this.PoleMarkers(ko,ki,ka).DataTipTemplate.DataTipRows = [nameDataTipRow; ioDataTipRow; poleValueRow;...
                dampingRow; overshootRow; frequencyRow; customDataTipRows(:)];

            % Pole value row
            zeroValue = this.Response.ResponseData.Zeros{ko,ki,ka};
            zeroValueRow = dataTipTextRow(getString(message('Controllib:plots:strZero')),...
                @(x,y) this.getPZString(x,y));
            % Damping, Overshoot, Frequency
            [dampingRow,frequencyRow,overshootRow] = ...
                getDampingFrequencyOvershootRows(this,zeroValue,this.Response.ResponseData.Ts);
            % Assign data tip template
            this.ZeroMarkers(ko,ki,ka).DataTipTemplate.DataTipRows = [nameDataTipRow; ioDataTipRow; zeroValueRow;...
                dampingRow; overshootRow; frequencyRow; customDataTipRows(:)];
        end

        function cbTimeUnitChanged(this,conversionFcn)
            for ko = 1:this.Response.NRows
                for ki = 1:this.Response.NColumns
                    for ka = 1:this.Response.NResponses
                        % Pole markers
                        this.PoleMarkers(ko,ki,ka).XData = 1./(conversionFcn(1./this.PoleMarkers(ko,ki,ka).XData));
                        this.PoleMarkers(ko,ki,ka).YData = 1./(conversionFcn(1./this.PoleMarkers(ko,ki,ka).YData));

                        % Zero markers
                        this.ZeroMarkers(ko,ki,ka).XData = 1./(conversionFcn(1./this.ZeroMarkers(ko,ki,ka).XData));
                        this.ZeroMarkers(ko,ki,ka).YData = 1./(conversionFcn(1./this.ZeroMarkers(ko,ki,ka).YData));
                    end
                end

            end
        end

        function cbFrequencyUnitChanged(this,conversionFcn)
            if this.IsResponseDataTipsCreated
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        for ka = 1:this.Response.NResponses
                            row = this.replaceDataTipRowLabel(this.PoleMarkers(ko,ki,ka),...
                                getString(message('Controllib:plots:strFrequency')),...
                                getString(message('Controllib:plots:strFrequency')) + ...
                                " (" + this.FrequencyUnit + ")");
                            this.replaceDataTipRowValue(this.PoleMarkers(ko,ki,ka),...
                                getString(message('Controllib:plots:strFrequency')),...
                                conversionFcn(this.PoleMarkers(ko,ki,ka).DataTipTemplate.DataTipRows(row).Value));
                            row = this.replaceDataTipRowLabel(this.ZeroMarkers(ko,ki,ka),...
                                getString(message('Controllib:plots:strFrequency')),...
                                getString(message('Controllib:plots:strFrequency')) + ...
                                " (" + this.FrequencyUnit + ")");
                            this.replaceDataTipRowValue(this.ZeroMarkers(ko,ki,ka),...
                                getString(message('Controllib:plots:strFrequency')),...
                                conversionFcn(this.ZeroMarkers(ko,ki,ka).DataTipTemplate.DataTipRows(row).Value));
                        end
                    end
                end
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
