classdef TimeInputOutputBoundaryRegionView < controllib.chart.internal.view.characteristic.TimeInputOutputCharacteristicView
    % this = controllib.chart.internal.view.characteristic.TimePeakResponseView(data)
    %
    % Copyright 2021 The MathWorks, Inc.
    
    %% Properties
    properties (SetAccess = protected)
        TimeBoundaryRegionPatch
    end
    
    %% Constructor
    methods
        function this = TimeInputOutputBoundaryRegionView(responseView,data)
            this@controllib.chart.internal.view.characteristic.TimeInputOutputCharacteristicView(responseView,data);
        end
    end

    %% Public methods
    methods
        function setVisible(this,visible,optionalInputs)
            arguments
                this
                visible matlab.lang.OnOffSwitchState = this.Visible
                optionalInputs.InputVisible logical = true(1,this.Response.NColumns)
                optionalInputs.OutputVisible logical = true(this.Response.NRows,1)
                optionalInputs.ArrayVisible logical = true(1,this.Response.NResponses)
            end

            % Set visibility
            for kr = 1:this.Response.NRows
                for kc = 1:this.Response.NColumns
                    visibleFlag = visible & any(optionalInputs.ArrayVisible) & ...
                        optionalInputs.OutputVisible(kr) & optionalInputs.InputVisible(kc);
                    this.TimeBoundaryRegionPatch(kr,kc).Visible = visibleFlag;
                end
            end
            this.Visible = visible;
        end
    end

    %% Protected methods
    methods (Access = protected)
        function build_(this)
            this.TimeBoundaryRegionPatch = createGraphicsObjects(this,"patch",this.Response.NRows,...
                this.Response.NColumns,1,HitTest="off",PickableParts="none",Tag='TimeBoundarRegionPatch');
            set(this.TimeBoundaryRegionPatch,FaceAlpha=0.3,EdgeAlpha=0.3);
        end

        function updateData(this,ko,ki,~)
            data = getCharacteristics(this.Response.ResponseData,this.Type);
            t = data.Time(:);
            upperValue = data.UpperBoundaryAmplitude(:,ko,ki);
            upperValue = upperValue(:);
            idxNaN = find(isnan(upperValue));

            lowerValue = data.LowerBoundaryAmplitude(:,ko,ki);
            lowerValue = lowerValue(:);
            idxNaN = [idxNaN; find(isnan(lowerValue))];

            t(idxNaN) = [];
            upperValue(idxNaN) = [];
            lowerValue(idxNaN) = [];

            this.TimeBoundaryRegionPatch(ko,ki).XData = [t', t(end:-1:1)'];
            this.TimeBoundaryRegionPatch(ko,ki).YData = [upperValue', lowerValue(end:-1:1)'];
        end


        function p = getResponseObjects_(this,ko,ki,~)
            p = this.TimeBoundaryRegionPatch(ko,ki);
        end

        function cbTimeUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        this.TimeBoundaryRegionPatch(ko,ki).XData = ...
                            conversionFcn(this.TimeBoundaryRegionPatch(ko,ki).XData);
                    end
                end
            end
        end
    end
end