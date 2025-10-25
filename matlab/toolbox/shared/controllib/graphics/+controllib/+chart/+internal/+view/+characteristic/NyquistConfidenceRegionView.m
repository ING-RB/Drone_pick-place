classdef NyquistConfidenceRegionView < controllib.chart.internal.view.characteristic.FrequencyCharacteristicView
    % this = controllib.chart.internal.view.characteristic.TimePeakResponseView(data)
    %
    % Copyright 2021 The MathWorks, Inc.
    
    %% Properties
    properties (SetAccess = protected)
        PositiveFrequencyEllipses
        NegativeFrequencyEllipses
        PositiveFrequencyEllipseCenters
        NegativeFrequencyEllipseCenters
    end
    
    %% Public methods
    methods
        function this = NyquistConfidenceRegionView(responseView,data)
            this@controllib.chart.internal.view.characteristic.FrequencyCharacteristicView(responseView,data);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function build_(this)
            this.PositiveFrequencyEllipses = createGraphicsObjects(this,"line",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='NyquistConfidencePositiveLine');
            this.NegativeFrequencyEllipses = createGraphicsObjects(this,"line",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='NyquistConfidenceNegativeLine');
            this.PositiveFrequencyEllipseCenters = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='NyquistConfidencePositiveScatter');
            set(this.PositiveFrequencyEllipseCenters,Marker='+',SizeData=100);
            this.NegativeFrequencyEllipseCenters = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='NyquistConfidenceNegativeScatter');
            set(this.NegativeFrequencyEllipseCenters,Marker='+',SizeData=100);
        end

        function updateData(this,ko,ki,ka)
            data = this.Response.ResponseData.ConfidenceRegion;
            if data.IsValid(ka)
                if ~isempty(data.EllipseData{ka}(ko,ki))
                    ellipseData = [];
                    for k = 1:size(data.EllipseData{ka},1)
                        ellipseData = [ellipseData; NaN; ...
                            data.EllipseData{ka}(k,ko,ki).Frequencies(:); NaN]; %#ok<AGROW>
                    end

                    % Ellipse data for positive frequencies
                    this.PositiveFrequencyEllipses(ko,ki,ka).XData = real(ellipseData);
                    this.PositiveFrequencyEllipses(ko,ki,ka).YData = imag(ellipseData);
                    % Ellipse center for positive frequencies
                    positiveFrequencyResponse = data.PositiveFrequencyResponse{ka}(:,ko,ki);
                    this.PositiveFrequencyEllipseCenters(ko,ki,ka).XData = ...
                        real(positiveFrequencyResponse);
                    this.PositiveFrequencyEllipseCenters(ko,ki,ka).YData = ...
                        imag(positiveFrequencyResponse);

                    if this.ResponseView.ShowFullContour
                        % Ellipse data for negative frequencies
                        this.NegativeFrequencyEllipses(ko,ki,ka).XData = real(ellipseData);
                        this.NegativeFrequencyEllipses(ko,ki,ka).YData = -imag(ellipseData);
                        % Ellipse center for positive frequencies
                        this.NegativeFrequencyEllipseCenters(ko,ki,ka).XData = ...
                            real(positiveFrequencyResponse);
                        this.NegativeFrequencyEllipseCenters(ko,ki,ka).YData = ...
                            -imag(positiveFrequencyResponse);
                    else
                        % Ellipse data for negative frequencies
                        this.NegativeFrequencyEllipses(ko,ki,ka).XData = NaN;
                        this.NegativeFrequencyEllipses(ko,ki,ka).YData = NaN;
                        % Ellipse center for positive frequencies
                        this.NegativeFrequencyEllipseCenters(ko,ki,ka).XData = NaN;
                        this.NegativeFrequencyEllipseCenters(ko,ki,ka).YData = NaN;
                    end
                end
            end
        end

        function p = getResponseObjects_(this,ko,ki,ka)
            p = cat(3,this.PositiveFrequencyEllipses(ko,ki,ka),...
                this.NegativeFrequencyEllipses(ko,ki,ka),...
                this.PositiveFrequencyEllipseCenters(ko,ki,ka),...
                this.NegativeFrequencyEllipseCenters(ko,ki,ka));
        end
    end
end