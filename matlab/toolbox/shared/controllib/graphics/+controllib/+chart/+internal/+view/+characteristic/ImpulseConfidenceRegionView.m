classdef ImpulseConfidenceRegionView < controllib.chart.internal.view.characteristic.TimeInputOutputCharacteristicView
    % this = controllib.chart.internal.view.characteristic.TimePeakResponseView(data)
    %
    % Copyright 2021 The MathWorks, Inc.
    
    %% Properties
    properties (SetAccess = protected)
        ConfidenceRegionPatch
    end
    
    %% Constructor
    methods
        function this = ImpulseConfidenceRegionView(responseView,data)
            this@controllib.chart.internal.view.characteristic.TimeInputOutputCharacteristicView(responseView,data);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function build_(this)
            this.ConfidenceRegionPatch = createGraphicsObjects(this,"patch",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,HitTest="off",PickableParts="none",Tag='ImpulseConfidencePatch');
            set(this.ConfidenceRegionPatch,FaceAlpha=0.3,EdgeAlpha=0.3);
        end

        function updateData(this,ko,ki,ka)
            data = this.Response.ResponseData.ConfidenceRegion;
            if data.IsValid(ka)
                t = data.Time{ka}(:);
                upperValue = data.UpperBoundaryAmplitude{ka}(:,ko,ki);
                upperValue = upperValue(:);
                idxNaN = find(isnan(upperValue));

                lowerValue = data.LowerBoundaryAmplitude{ka}(:,ko,ki);
                lowerValue = lowerValue(:);
                idxNaN = [idxNaN; find(isnan(lowerValue))];

                t(idxNaN) = [];
                upperValue(idxNaN) = [];
                lowerValue(idxNaN) = [];

                this.ConfidenceRegionPatch(ko,ki,ka).XData = [t', t(end:-1:1)'];
                this.ConfidenceRegionPatch(ko,ki,ka).YData = [upperValue', lowerValue(end:-1:1)'];
            end
        end

        function cbTimeUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        for ka = 1:this.Response.NResponses
                            this.ConfidenceRegionPatch(ko,ki,ka).XData = ...
                                conversionFcn(this.ConfidenceRegionPatch(ko,ki,ka).XData);
                        end
                    end
                end
            end
        end

        function c = getResponseObjects_(this,ko,ki,ka)
            c = this.ConfidenceRegionPatch(ko,ki,ka);
        end
    end
end