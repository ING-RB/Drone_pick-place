classdef SamplingGridSelector < controllib.ui.internal.dialog.AbstractDialog
    % Widget for selecting point in sampling grid.

    %   Copyright 1986-2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent)
        % Selected value (absolute index into SamplingGrid arrays)
        Selection
    end

    properties (Access = protected,Transient,NonCopyable)
        Labels (:,1) matlab.ui.control.Label
        Sliders (:,1) matlab.ui.control.Slider
        ValueEditFields (:,1) matlab.ui.control.NumericEditField
    end

    properties (GetAccess = protected,SetAccess=immutable)
        % Number of grid variables
        NVAR_
        % Number of grid dimensions
        NDIM_
        % Grid size
        GridSize_
        % Grid vectors (NVAR-by-3 cell array: dim, variable, data).
        % NOTE:
        % 1) Grid vectors are always sorted in increasing order
        % 2) There can be several variables associated with a given grid dimension
        GridVectors_
        % Sample permutation (re-orders samples as NDGRID(GV1,...,GVN) where
        % the grid vectors GVj are monotonically increasing)
        SamplePerm_
        % Inverse sample permutation
        iSamplePerm_
    end

    %% Events
    events (NotifyAccess=protected)
        SelectionChanged
    end

    %% Constructor
    methods
        function this = SamplingGridSelector(SG)
            arguments
                SG (1,1) struct
            end
            this = this@controllib.ui.internal.dialog.AbstractDialog;
            this.Title = getString(message('Controllib:plots:selectDesignPoint'));
            this.CloseMode = 'destroy';
            this.Name = 'SamplingGridSelector';

            % Parse sampling grid
            GridInfo = ltipack.SamplingGrid.getGridStructure(SG);
            GV = GridInfo.GridVectors;
            NDIM = numel(GV);
            for ct=1:numel(GV)
                GV{ct} = [repmat({ct},size(GV{ct},1),1) GV{ct}];
            end
            GV = cat(1,GV{:});
            NVAR = size(GV,1);
            this.NDIM_ = NDIM;
            this.NVAR_ = NVAR;
            this.GridSize_ = GridInfo.GridSize;
            this.GridVectors_ = GV;
            perm = GridInfo.SamplePerm;
            this.SamplePerm_ = perm;
            this.iSamplePerm_(perm,1) = (1:numel(perm))';
        end
    end

    %% Get/Set
    methods
        % Selection
        function Value = get.Selection(this)
            isub = cell(1,this.NDIM_);
            GV = this.GridVectors_;
            for ii=1:this.NVAR_
                samplingGrid = this.Sliders(ii).UserData.Data;
                value = this.Sliders(ii).Value;
                if this.Sliders(ii).UserData.Scale == "log"
                    value = 10^value;
                end
                [~,idx] = min(abs(samplingGrid-value));
                isub{GV{ii,1}} = idx;
            end
            % Compute absolute index into original grid
            k = sub2ind(this.GridSize_,isub{:});
            Value = this.SamplePerm_(k);
        end

        function set.Selection(this,Value)
            arguments
                this (1,1) controllib.chart.internal.widget.SamplingGridSelector
                Value (1,1) double {mustBePositive,mustBeInteger}
            end
            gsize = this.GridSize_;
            Npts = prod(gsize);
            if Value>Npts
                error(message('Controllib:widget:GridSelector1',Npts))
            end
            % Convert absolute index into subscripts into grid vectors.
            % K is the absolute index into NDGRID(GV1,...,GVN).
            k = this.iSamplePerm_(Value);
            isub = cell(1,numel(gsize));
            [isub{:}] = ind2sub(gsize,k);
            GV = this.GridVectors_;
            for ii=1:this.NVAR_
                value = this.Sliders(ii).UserData.Data(isub{GV{ii,1}});
                this.ValueEditFields(ii).Value = value;
                switch this.Sliders(ii).UserData.Scale
                    case "linear"
                        this.Sliders(ii).Value = value;
                    case "log"
                        this.Sliders(ii).Value = log10(value);
                end
            end
        end
    end

    %% Protected methods
    methods (Access=protected)
        function figureGrid = buildUI(this)
            % GridLayout
            figureGrid = uigridlayout(this.UIFigure,[this.NVAR_ 3]);
            figureGrid.RowHeight = repmat({'fit'},this.NVAR_,1);
            figureGrid.ColumnWidth = {'fit','1x','fit'};

            this.Labels = createArray([this.NVAR_ 1],'matlab.ui.control.Label');
            this.Sliders = createArray([this.NVAR_ 1],'matlab.ui.control.Slider');
            this.ValueEditFields = createArray([this.NVAR_ 1],'matlab.ui.control.NumericEditField');
            for ii = 1:this.NVAR_
                this.Labels(ii).Parent = figureGrid;
                this.Labels(ii).Text=this.GridVectors_{ii,2};
                this.Labels(ii).Layout.Row = ii;
                this.Labels(ii).Layout.Column = 1;
                this.Sliders(ii).Parent = figureGrid;
                this.Sliders(ii).Layout.Row = ii;
                this.Sliders(ii).Layout.Column = 2;
                data = this.GridVectors_{ii,3};
                this.Sliders(ii).UserData.Data = data;
                scale = this.getSliderScale(data);
                this.Sliders(ii).UserData.Scale = scale;
                switch scale
                    case "linear"
                        this.Sliders(ii).Limits = [data(1) data(end)];
                        this.Sliders(ii).MajorTicks = [data(1) data(end)];
                        this.Sliders(ii).Value = data(floor(length(data)/2));
                        if length(data) < 10
                            this.Sliders(ii).MinorTicks = data;
                        end
                    case "log"
                        logData = log10(data);
                        this.Sliders(ii).Limits = [logData(1) logData(end)];
                        this.Sliders(ii).MajorTicks = [logData(1) logData(end)];
                        this.Sliders(ii).Value = logData(floor(length(logData)/2));
                        if length(logData) < 10
                            this.Sliders(ii).MinorTicks = logData;
                        end
                end
                leftTick = {sprintf('%0.3g',data(1))};
                rightTick = {sprintf('%0.3g',data(end))};
                this.Sliders(ii).MajorTickLabels = [leftTick rightTick];
                this.ValueEditFields(ii).Parent = figureGrid;
                this.ValueEditFields(ii).Layout.Row = ii;
                this.ValueEditFields(ii).Layout.Column = 3;
                this.ValueEditFields(ii).Value = data(floor(length(data)/2));
                this.ValueEditFields(ii).Editable = false;
                this.ValueEditFields(ii).ValueDisplayFormat = '%0.3g';
            end
        end

        function connectUI(this)
            weakThis = matlab.lang.WeakReference(this);
            for ii = 1:this.NVAR_
                this.Sliders(ii).ValueChangedFcn = @(es,ed) cbSliderValueChanged(weakThis.Handle,ii,ed.Value);
                this.Sliders(ii).ValueChangingFcn = @(es,ed) cbSliderValueChanging(weakThis.Handle,ii,ed.Value);
            end
        end

        function cbSliderValueChanged(this,sliderIdx,value)
            % Synchronize all sliders for affected dimension
            samplingGrid = this.Sliders(sliderIdx).UserData.Data;
            if this.Sliders(sliderIdx).UserData.Scale == "log"
                value = 10^value;
            end
            [~,idx] = min(abs(samplingGrid-value));
            dims = cat(1,this.GridVectors_{:,1});
            idim = dims(sliderIdx);
            for ii = 1:this.NVAR_
                if dims(ii)==idim
                    value = this.Sliders(ii).UserData.Data(idx);
                    this.ValueEditFields(ii).Value = value;
                    switch this.Sliders(ii).UserData.Scale
                        case "linear"
                            this.Sliders(ii).Value = value;
                        case "log"
                            this.Sliders(ii).Value = log10(value);
                    end
                end
            end
            % Send notification
            notify(this,'SelectionChanged')
        end

        function cbSliderValueChanging(this,sliderIdx,value)
            % Synchronize all sliders for affected dimension
            samplingGrid = this.Sliders(sliderIdx).UserData.Data;
            if this.Sliders(sliderIdx).UserData.Scale == "log"
                samplingGrid = log10(samplingGrid);
            end
            [~,idx] = min(abs(samplingGrid-value));
            dims = cat(1,this.GridVectors_{:,1});
            idim = dims(sliderIdx);
            for ii = 1:this.NVAR_
                if dims(ii)==idim
                    value = this.Sliders(ii).UserData.Data(idx);
                    this.ValueEditFields(ii).Value = value;
                    if ii ~= sliderIdx
                        switch this.Sliders(ii).UserData.Scale
                            case "linear"
                                this.Sliders(ii).Value = value;
                            case "log"
                                this.Sliders(ii).Value = log10(value);
                        end
                    end
                end
            end
        end
    end

    %% Static private methods
    methods (Static,Access=private)
        function scale = getSliderScale(data)
            % Infers scale from data distribution
            scale = "linear";
            if all(data>0)
                % Compare skewness of linear and log distributions
                N = numel(data);
                m1 = mean(data);
                m3 = sum((data-m1).^3)/N;
                m2 = sum((data-m1).^2)/(N-1);
                SkewLin = m3/m2^1.5;
                data = log(data);
                m1 = mean(data);
                m3 = sum((data-m1).^3)/N;
                m2 = sum((data-m1).^2)/(N-1);
                SkewLog = m3/m2^1.5;
                if SkewLin>0.5 && abs(SkewLog)<0.5*SkewLin
                    % Use log scale when linear distribution is leaning to the left
                    % (right/positive skew) and has higher skew than log distribution
                    scale = "log";
                end
            end
        end
    end

    %% Hidden methods
    methods (Hidden)
        function wdgts = qeGetWidgets(this)
            % For QE testing
            wdgts = struct('Labels',this.Labels,...
                'Sliders',this.Sliders,...
                'ValueEditFields',this.ValueEditFields);
        end
    end
end