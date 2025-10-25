classdef IOPZConfidenceRegionView < controllib.chart.internal.view.characteristic.InputOutputCharacteristicView
    % this = controllib.chart.internal.view.characteristic.TimePeakResponseView(data)
    %
    % Copyright 2021 The MathWorks, Inc.
    
    %% Properties
    properties (SetAccess = protected)
        ZeroEllipses
        PoleEllipses
    end
    
    %% Public methods
    methods
        function this = IOPZConfidenceRegionView(responseView,data)
            this@controllib.chart.internal.view.characteristic.InputOutputCharacteristicView(responseView,data);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function build_(this)
            this.ZeroEllipses = createGraphicsObjects(this,"line",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='IOPZConfidenceZeroLine');
            this.PoleEllipses = createGraphicsObjects(this,"line",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='IOPZConfidencePoleLine');
        end

        function updateData(this,ko,ki,ka)
            data = this.Response.ResponseData.ConfidenceRegion;
            if data.IsValid(ka)
                if ~isempty(data.EllipseZeroData{ka}{ko,ki})
                    ellipseZeroData = [];
                    for ct = 1:length(data.EllipseZeroData{ka}{ko,ki})
                        ellipseZeroData = [ellipseZeroData; NaN; ...
                            data.EllipseZeroData{ka}{ko,ki}{ct}(:); NaN]; %#ok<AGROW>
                    end

                    % Ellipse data for positive frequencies
                    this.ZeroEllipses(ko,ki,ka).XData = real(ellipseZeroData);
                    this.ZeroEllipses(ko,ki,ka).YData = imag(ellipseZeroData);
                end
                if ~isempty(data.EllipsePoleData{ka}{ko,ki})
                    ellipsePoleData = [];
                    for ct = 1:length(data.EllipsePoleData{ka}{ko,ki})
                        ellipsePoleData = [ellipsePoleData; NaN; ...
                            data.EllipsePoleData{ka}{ko,ki}{ct}(:); NaN]; %#ok<AGROW>
                    end

                    % Ellipse data for positive frequencies
                    this.PoleEllipses(ko,ki,ka).XData = real(ellipsePoleData);
                    this.PoleEllipses(ko,ki,ka).YData = imag(ellipsePoleData);
                end
            end
        end

        function p = getResponseObjects_(this,ko,ki,ka)
            p = cat(3,this.ZeroEllipses(ko,ki,ka),...
                this.PoleEllipses(ko,ki,ka));
        end
    end
end