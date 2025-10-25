function h = ltiplot(plotType,hParent,optionalInputs)
% h = ltiplot(plotType)
% h = ltiplot(plotType,ax)
% h = ltiplot(plotType,ax,SystemData=sysDataStruct,...)

% Copyright 2024 The MathWorks, Inc.
arguments
    plotType string
    hParent {validateIfGraphicsObject,mustBeScalarOrEmpty} = []
    optionalInputs.SystemData struct = struct.empty
    optionalInputs.Time = []
    optionalInputs.InputSignal = []
    optionalInputs.InterpolationMethod = 'auto'
    optionalInputs.Frequency = []
    optionalInputs.Parameter = []
    optionalInputs.Config = []
    optionalInputs.Type = []
    optionalInputs.R = []
    optionalInputs.Skew double = []
    optionalInputs.Q = []
    optionalInputs.NInputs double = []
    optionalInputs.NOutputs double = []
    optionalInputs.InputNames string = string.empty
    optionalInputs.OutputNames string = string.empty
    optionalInputs.Visible matlab.lang.OnOffSwitchState = 'on'
    optionalInputs.CreateResponseDataTipsOnDefault (1,1) logical = true
    optionalInputs.CreateToolbarOnDefault (1,1) logical = true
    optionalInputs.Options = []
end

% Create system styles if needed
for k = 1:length(optionalInputs.SystemData)
    if ~isempty(optionalInputs.SystemData(k).Style)
        % Parse line specification string
        [lineStyle,color,markerStyle,msg] = colstyle(optionalInputs.SystemData(k).Style);
        % Throw error if needed
        if ~isempty(msg)
            error(message('Controllib:plots:PlotStyleString',optionalInputs.SystemData(k).Style))
        end
        if isempty(lineStyle) && ~isempty(markerStyle)
            lineStyle = 'none';
        end
        % Specify parameters
        optionalInputs.SystemData(k).LineStyle = lineStyle;
        optionalInputs.SystemData(k).Color = color;
        optionalInputs.SystemData(k).MarkerStyle = markerStyle;
    else
        optionalInputs.SystemData(k).LineStyle = char.empty;
        optionalInputs.SystemData(k).Color = char.empty;
        optionalInputs.SystemData(k).MarkerStyle = char.empty;
    end
end

% Convert ax to handle object (in case numeric value passed in)
hParent = handle(hParent);

% InputNames and OutputNames
if ~isempty(optionalInputs.SystemData)
    allSystems = {optionalInputs.SystemData.System};
    [inputNames,outputNames] = mrgios(allSystems{:});
    optionalInputs.NInputs = length(inputNames);
    optionalInputs.NOutputs = length(outputNames);
else
    if ~isempty(optionalInputs.InputNames)
        optionalInputs.NInputs = length(optionalInputs.InputNames);
    else
        optionalInputs.NInputs = 1;
    end
    if ~isempty(optionalInputs.OutputNames)
        optionalInputs.NOutputs = length(optionalInputs.OutputNames);
    else
        optionalInputs.NOutputs = 1;
    end
end

% Check if system response needs to be added to current chart
chartValuesFromAxes = [];
if isempty(hParent)
    hParent = get(groot,'CurrentFigure');
    if isempty(hParent)
        nextPlotToSet = 'replace';
        ax = matlab.graphics.axis.Axes.empty;
    else
        ax = hParent.CurrentAxes;        
        if isempty(ax)
            nextPlotToSet = 'replace';
            ax = matlab.graphics.axis.Axes.empty;
        else
            hParent = ax.Parent; %could be in tiled layout
            [nextPlotToSet,chartValuesFromAxes,ax] = parseAxes(ax,plotType,optionalInputs);
        end
    end
elseif isa(hParent,'matlab.ui.Figure') || isa(hParent,'matlab.ui.container.Panel') || isa(hParent,'matlab.ui.container.Tab')
    delete(allchild(hParent));
    nextPlotToSet = 'replace';
    ax = matlab.graphics.axis.Axes.empty;
elseif isa(hParent,'matlab.graphics.axis.Axes') || isa(hParent,'matlab.ui.control.UIAxes')
    ax = hParent;
    h = ancestor(ax,'controllib.chart.internal.foundation.AbstractPlot');
    if isempty(h)
        hParent = ax.Parent;
    else
        hParent = h.Parent;
    end
    [nextPlotToSet,chartValuesFromAxes,ax] = parseAxes(ax,plotType,optionalInputs);
else
    nextPlotToSet = 'replace';
    ax = matlab.graphics.axis.Axes.empty;
end
if strcmp(nextPlotToSet,'washeld')
    h = ax;
    return;
end

% Create chart based on plot type
hResponses = controllib.chart.internal.foundation.BaseResponse.empty;
switch lower(plotType)
    case "step"
        % Create responses
        if isempty(optionalInputs.Options)
            options = controllib.chart.StepPlot.createDefaultOptions();
        else
            options = optionalInputs.Options;
        end
        for k = 1:length(optionalInputs.SystemData)
            hResponses(k) = controllib.chart.response.StepResponse(optionalInputs.SystemData(k).System,...
                Time=optionalInputs.Time,...
                Parameter=optionalInputs.Parameter,...
                Config=optionalInputs.Config,...
                RiseTimeLimits=options.RiseTimeLimits,...
                SettlingTimeThreshold=options.SettleTimeThreshold,...
                NumberOfStandardDeviations=options.ConfidenceRegionNumberSD,...
                Name=optionalInputs.SystemData(k).Name);
            if ~isempty(hResponses(k).DataException)
                throw(hResponses(k).DataException);
            end
        end
        % Create chart
        h = controllib.chart.StepPlot(Parent=hParent,Visible=false,Axes=ax,...
            CreateResponseDataTipsOnDefault=optionalInputs.CreateResponseDataTipsOnDefault,...
            CreateToolbarOnDefault=optionalInputs.CreateToolbarOnDefault);
        if strcmp(options.TimeUnits,"auto") && ~isempty(hResponses)
            h.TimeUnit = hResponses(1).TimeUnit;
        end
    case "impulse"
        % Create responses
        if isempty(optionalInputs.Options)
            options = controllib.chart.ImpulsePlot.createDefaultOptions();
        else
            options = optionalInputs.Options;
        end
        for k = 1:length(optionalInputs.SystemData)
            hResponses(k) = controllib.chart.response.ImpulseResponse(optionalInputs.SystemData(k).System,...
                Time=optionalInputs.Time,...
                Parameter=optionalInputs.Parameter,...
                Config=optionalInputs.Config,...
                SettlingTimeThreshold=options.SettleTimeThreshold,...
                NumberOfStandardDeviations=options.ConfidenceRegionNumberSD,...
                Name=optionalInputs.SystemData(k).Name);
            if ~isempty(hResponses(k).DataException)
                throw(hResponses(k).DataException);
            end
        end
        % Create chart
        h = controllib.chart.ImpulsePlot(Parent=hParent,Visible=false,Axes=ax,...
            CreateResponseDataTipsOnDefault=optionalInputs.CreateResponseDataTipsOnDefault,...
            CreateToolbarOnDefault=optionalInputs.CreateToolbarOnDefault);
        if strcmp(options.TimeUnits,"auto") && ~isempty(hResponses)
            h.TimeUnit = hResponses(1).TimeUnit;
        end
    case "bode"
        % Create responses
        if isempty(optionalInputs.Options)
            options = controllib.chart.BodePlot.createDefaultOptions();
        else
            options = optionalInputs.Options;
        end
        for k = 1:length(optionalInputs.SystemData)
            hResponses(k) = controllib.chart.response.BodeResponse(optionalInputs.SystemData(k).System,...
                Frequency=optionalInputs.Frequency,...
                NumberOfStandardDeviations=options.ConfidenceRegionNumberSD,...
                Name=optionalInputs.SystemData(k).Name);
            if ~isempty(hResponses(k).DataException)
                throw(hResponses(k).DataException);
            end
        end
        % Create chart
        h = controllib.chart.BodePlot(Parent=hParent,Visible=false,Axes=ax,...
            CreateResponseDataTipsOnDefault=optionalInputs.CreateResponseDataTipsOnDefault,...
            CreateToolbarOnDefault=optionalInputs.CreateToolbarOnDefault);
        if strcmp(options.FreqUnits,"auto") && ~isempty(hResponses)
            h.FrequencyUnit = hResponses(1).FrequencyUnit;
        end
    case "nyquist"
        % Create responses
        if isempty(optionalInputs.Options)
            options = controllib.chart.NyquistPlot.createDefaultOptions();
        else
            options = optionalInputs.Options;
        end
        for k = 1:length(optionalInputs.SystemData)
            hResponses(k) = controllib.chart.response.NyquistResponse(optionalInputs.SystemData(k).System,...
                Frequency=optionalInputs.Frequency,...
                NumberOfStandardDeviations=options.ConfidenceRegionNumberSD,...
                ConfidenceDisplaySampling=options.ConfidenceRegionDisplaySpacing,...
                Name=optionalInputs.SystemData(k).Name);
            if ~isempty(hResponses(k).DataException)
                throw(hResponses(k).DataException);
            end
        end
        % Create chart
        h = controllib.chart.NyquistPlot(Parent=hParent,Visible=false,Axes=ax,...
            CreateResponseDataTipsOnDefault=optionalInputs.CreateResponseDataTipsOnDefault,...
            CreateToolbarOnDefault=optionalInputs.CreateToolbarOnDefault);
        if strcmp(options.FreqUnits,"auto") && ~isempty(hResponses)
            h.FrequencyUnit = hResponses(1).FrequencyUnit;
        end
    case "nichols"
        % Create responses
        if isempty(optionalInputs.Options)
            options = controllib.chart.NicholsPlot.createDefaultOptions();
        else
            options = optionalInputs.Options;
        end
        for k = 1:length(optionalInputs.SystemData)
            hResponses(k) = controllib.chart.response.NicholsResponse(optionalInputs.SystemData(k).System,...
                Frequency=optionalInputs.Frequency,...
                Name=optionalInputs.SystemData(k).Name);
            if ~isempty(hResponses(k).DataException)
                throw(hResponses(k).DataException);
            end
        end
        % Create chart
        h = controllib.chart.NicholsPlot(Parent=hParent,Visible=false,Axes=ax,...
            CreateResponseDataTipsOnDefault=optionalInputs.CreateResponseDataTipsOnDefault,...
            CreateToolbarOnDefault=optionalInputs.CreateToolbarOnDefault);
        if strcmp(options.FreqUnits,"auto") && ~isempty(hResponses)
            h.FrequencyUnit = hResponses(1).FrequencyUnit;
        end
    case "pzmap"
        % Create responses
        if isempty(optionalInputs.Options)
            options = controllib.chart.PZPlot.createDefaultOptions();
        else
            options = optionalInputs.Options;
        end
        for k = 1:length(optionalInputs.SystemData)
            hResponses(k) = controllib.chart.response.PZResponse(optionalInputs.SystemData(k).System,...
                Name=optionalInputs.SystemData(k).Name);
            if ~isempty(hResponses(k).DataException)
                throw(hResponses(k).DataException);
            end
        end
        % Create chart
        h = controllib.chart.PZPlot(Parent=hParent,Visible=false,Axes=ax,...
            CreateResponseDataTipsOnDefault=optionalInputs.CreateResponseDataTipsOnDefault,...
            CreateToolbarOnDefault=optionalInputs.CreateToolbarOnDefault);
        if strcmp(options.TimeUnits,"auto") && ~isempty(hResponses)
            h.TimeUnit = hResponses(1).TimeUnit;
        end
        if strcmp(options.FreqUnits,"auto") && ~isempty(hResponses)
            h.FrequencyUnit = hResponses(1).FrequencyUnit;
        end
    case "iopzmap"
        % Create responses
        if isempty(optionalInputs.Options)
            options = controllib.chart.IOPZPlot.createDefaultOptions();
        else
            options = optionalInputs.Options;
        end
        for k = 1:length(optionalInputs.SystemData)
            hResponses(k) = controllib.chart.response.IOPZResponse(optionalInputs.SystemData(k).System,...
                NumberOfStandardDeviations=options.ConfidenceRegionNumberSD,...
                Name=optionalInputs.SystemData(k).Name);
            if ~isempty(hResponses(k).DataException)
                throw(hResponses(k).DataException);
            end
        end
        % Create chart
        h = controllib.chart.IOPZPlot(Parent=hParent,Visible=false,Axes=ax,...
            CreateResponseDataTipsOnDefault=optionalInputs.CreateResponseDataTipsOnDefault,...
            CreateToolbarOnDefault=optionalInputs.CreateToolbarOnDefault);
        if strcmp(options.TimeUnits,"auto") && ~isempty(hResponses)
            h.TimeUnit = hResponses(1).TimeUnit;
        end
        if strcmp(options.FreqUnits,"auto") && ~isempty(hResponses)
            h.FrequencyUnit = hResponses(1).FrequencyUnit;
        end
    case "sigma"
        % Create responses
        if isempty(optionalInputs.Options)
            options = controllib.chart.SigmaPlot.createDefaultOptions();
        else
            options = optionalInputs.Options;
        end
        for k = 1:length(optionalInputs.SystemData)
            hResponses(k) = controllib.chart.response.SigmaResponse(optionalInputs.SystemData(k).System,...
                Frequency=optionalInputs.Frequency,...
                SingularValueType=optionalInputs.Type,...
                Name=optionalInputs.SystemData(k).Name);
            if ~isempty(hResponses(k).DataException)
                throw(hResponses(k).DataException);
            end
        end
        % Create chart
        h = controllib.chart.SigmaPlot(Parent=hParent,Visible=false,Axes=ax,...
            CreateResponseDataTipsOnDefault=optionalInputs.CreateResponseDataTipsOnDefault,...
            CreateToolbarOnDefault=optionalInputs.CreateToolbarOnDefault);
        if strcmp(options.FreqUnits,"auto") && ~isempty(hResponses)
            h.FrequencyUnit = hResponses(1).FrequencyUnit;
        end
    case "rlocus"
        % Create responses
        if isempty(optionalInputs.Options)
            options = controllib.chart.RLocusPlot.createDefaultOptions();
        else
            options = optionalInputs.Options;
        end
        for k = 1:length(optionalInputs.SystemData)
            hResponses(k) = controllib.chart.response.RootLocusResponse(optionalInputs.SystemData(k).System,...
                FeedbackGains=optionalInputs.Parameter,...
                Name=optionalInputs.SystemData(k).Name);
            if ~isempty(hResponses(k).DataException)
                throw(hResponses(k).DataException);
            end
        end
        % Create chart
        h = controllib.chart.RLocusPlot(Parent=hParent,Visible=false,Axes=ax,...
            CreateResponseDataTipsOnDefault=optionalInputs.CreateResponseDataTipsOnDefault,...
            CreateToolbarOnDefault=optionalInputs.CreateToolbarOnDefault);
        if strcmp(options.TimeUnits,"auto") && ~isempty(hResponses)
            h.TimeUnit = hResponses(1).TimeUnit;
        end
        if strcmp(options.FreqUnits,"auto") && ~isempty(hResponses)
            h.FrequencyUnit = hResponses(1).FrequencyUnit;
        end
    case "hsv"
        % Create response
        hResponses = controllib.chart.response.HSVResponse(optionalInputs.R,...
            HSVType=optionalInputs.Type);
        if ~isempty(hResponses.DataException)
            throw(hResponses.DataException);
        end
        % Create chart
        h = controllib.chart.HSVPlot(Parent=hParent,Visible=false,Axes=ax,...
            CreateResponseDataTipsOnDefault=optionalInputs.CreateResponseDataTipsOnDefault,...
            CreateToolbarOnDefault=optionalInputs.CreateToolbarOnDefault);
    case "initial"
        % Create responses
        if isempty(optionalInputs.Options)
            options = controllib.chart.InitialPlot.createDefaultOptions();
        else
            options = optionalInputs.Options;
        end
        for k = 1:length(optionalInputs.SystemData)
            hResponses(k) = controllib.chart.response.InitialResponse(optionalInputs.SystemData(k).System,...
                Time=optionalInputs.Time,...
                Parameter=optionalInputs.Parameter,...
                Config=optionalInputs.Config,...
                SettlingTimeThreshold=options.SettleTimeThreshold,...
                Name=optionalInputs.SystemData(k).Name);
            if ~isempty(hResponses(k).DataException)
                throw(hResponses(k).DataException);
            end
        end
        % Create chart
        h = controllib.chart.InitialPlot(Parent=hParent,Visible=false,Axes=ax,...
            CreateResponseDataTipsOnDefault=optionalInputs.CreateResponseDataTipsOnDefault,...
            CreateToolbarOnDefault=optionalInputs.CreateToolbarOnDefault);
        if strcmp(options.TimeUnits,"auto") && ~isempty(hResponses)
            h.TimeUnit = hResponses(1).TimeUnit;
        end
    case "lsim"
        % Create responses
        if isempty(optionalInputs.Options)
            options = controllib.chart.LSimPlot.createDefaultOptions();
        else
            options = optionalInputs.Options;
        end
        sw = ctrlMsgUtils.SuspendWarnings; %prevent undersamping warning twice
        for k = 1:length(optionalInputs.SystemData)
            hResponses(k) = controllib.chart.response.LinearSimulationResponse(optionalInputs.SystemData(k).System,...
                Time=optionalInputs.Time,...
                Parameter=optionalInputs.Parameter,...
                Config=optionalInputs.Config,...
                InputSignal=optionalInputs.InputSignal,...
                InterpolationMethod=optionalInputs.InterpolationMethod,...
                Name=optionalInputs.SystemData(k).Name);
            if ~isempty(hResponses(k).DataException)
                delete(sw);
                throw(hResponses(k).DataException);
            end
        end
        delete(sw);
        % Create chart
        h = controllib.chart.LSimPlot(Parent=hParent,Visible=false,Axes=ax,...
            CreateResponseDataTipsOnDefault=optionalInputs.CreateResponseDataTipsOnDefault,...
            CreateToolbarOnDefault=optionalInputs.CreateToolbarOnDefault);
        if strcmp(options.TimeUnits,"auto") && ~isempty(hResponses)
            h.TimeUnit = hResponses(1).TimeUnit;
        end
    case "sector"
        % Create responses
        if isempty(optionalInputs.Options)
            options = controllib.chart.SectorPlot.createDefaultOptions();
        else
            options = optionalInputs.Options;
        end
        for k = 1:length(optionalInputs.SystemData)
            hResponses(k) = controllib.chart.response.SectorResponse(optionalInputs.SystemData(k).System,...
                optionalInputs.Q,...
                Frequency=optionalInputs.Frequency,...
                Name=optionalInputs.SystemData(k).Name);
            if ~isempty(hResponses(k).DataException)
                throw(hResponses(k).DataException);
            end
        end
        % Create chart
        h = controllib.chart.SectorPlot(Parent=hParent,Visible=false,Axes=ax,...
            CreateResponseDataTipsOnDefault=optionalInputs.CreateResponseDataTipsOnDefault,...
            CreateToolbarOnDefault=optionalInputs.CreateToolbarOnDefault);
        if strcmp(options.FreqUnits,"auto") && ~isempty(hResponses)
            h.FrequencyUnit = hResponses(1).FrequencyUnit;
        end
    case "passive"
        % Create responses
        if isempty(optionalInputs.Options)
            options = controllib.chart.PassivePlot.createDefaultOptions();
        else
            options = optionalInputs.Options;
        end
        for k = 1:length(optionalInputs.SystemData)
            hResponses(k) = controllib.chart.response.PassiveResponse(optionalInputs.SystemData(k).System,...
                PassiveType=optionalInputs.Type,...
                Frequency=optionalInputs.Frequency,...
                Name=optionalInputs.SystemData(k).Name);
            if ~isempty(hResponses(k).DataException)
                throw(hResponses(k).DataException);
            end
        end
        % Create chart
        h = controllib.chart.PassivePlot(Parent=hParent,Visible=false,Axes=ax,...
            CreateResponseDataTipsOnDefault=optionalInputs.CreateResponseDataTipsOnDefault,...
            CreateToolbarOnDefault=optionalInputs.CreateToolbarOnDefault);
        switch optionalInputs.Type
            case 'input'
                h.IndexScale = 'linear';
                h.Title.String = getString(message('Control:analysis:passiveplotTitle1'));
                h.YLabel.String = getString(message('Control:analysis:passiveplotTitle1'));
            case 'output'
                h.IndexScale = 'linear';
                h.Title.String = getString(message('Control:analysis:passiveplotTitle2'));
                h.YLabel.String = getString(message('Control:analysis:passiveplotTitle2'));
            case 'io'
                h.IndexScale = 'linear';
                h.Title.String = getString(message('Control:analysis:passiveplotTitle3'));
                h.YLabel.String = getString(message('Control:analysis:passiveplotTitle3'));
        end
        if strcmp(options.FreqUnits,"auto") && ~isempty(hResponses)
            h.FrequencyUnit = hResponses(1).FrequencyUnit;
        end
    case "diskmargin"
        % Create responses
        if isempty(optionalInputs.Options)
            options = controllib.chart.DiskMarginPlot.createDefaultOptions();
        else
            options = optionalInputs.Options;
        end
        for k = 1:length(optionalInputs.SystemData)
            hResponses(k) = controllib.chart.response.DiskMarginResponse(optionalInputs.SystemData(k).System,...
                Skew=optionalInputs.Skew,...
                Frequency=optionalInputs.Frequency,...
                Name=optionalInputs.SystemData(k).Name);
            if ~isempty(hResponses(k).DataException)
                throw(hResponses(k).DataException);
            end
        end
        % Create chart
        h = controllib.chart.DiskMarginPlot(Parent=hParent,Visible=false,Axes=ax,...
            CreateResponseDataTipsOnDefault=optionalInputs.CreateResponseDataTipsOnDefault,...
            CreateToolbarOnDefault=optionalInputs.CreateToolbarOnDefault);
        if strcmp(options.FreqUnits,"auto") && ~isempty(hResponses)
            h.FrequencyUnit = hResponses(1).FrequencyUnit;
        end
   case "iotime"
       % Create io signal plot
        if isempty(optionalInputs.Options)
            options = controllib.chart.IOTimePlot.createDefaultOptions();
        else
            options = optionalInputs.Options;
        end
        for k = 1:length(optionalInputs.SystemData)
            modelData = idpack.InputOutputData(optionalInputs.SystemData(k).System, ...
                optionalInputs.SystemData(k).System.Name);
            modelSource = controllib.chart.internal.utils.IODataSource(modelData);
            hResponses(k) = controllib.chart.response.IOTimeResponse(...
                modelSource,...
                InputInterSample=options.InputInterSample,...
                Name=optionalInputs.SystemData(k).Name);

            if ~isempty(hResponses(k).DataException)
                throw(hResponses(k).DataException);
            end
        end
        ny = numel(unique(cat(1,hResponses.OutputNames)));
        % Create chart
        h = controllib.chart.IOTimePlot(ny,Parent=hParent,Visible=false,Axes=ax,...
            CreateResponseDataTipsOnDefault=optionalInputs.CreateResponseDataTipsOnDefault,...
            CreateToolbarOnDefault=optionalInputs.CreateToolbarOnDefault);
        if strcmp(options.TimeUnits,"auto") && ~isempty(hResponses)
            h.TimeUnit = hResponses(1).TimeUnit;
        end
   case "iofrequency"
       % Create io frequency signal (DFT) response
        if isempty(optionalInputs.Options)
            options = controllib.chart.BodePlot.createDefaultOptions();
        else
            options = optionalInputs.Options;
        end
        for k = 1:length(optionalInputs.SystemData)
            modelData = idpack.InputOutputData(optionalInputs.SystemData(k).System, ...
                optionalInputs.SystemData(k).System.Name);
            modelSource = controllib.chart.internal.utils.IODataSource(modelData);
            hResponses(k) = controllib.chart.response.IOFrequencyResponse(...
                modelSource,...
                Frequency=optionalInputs.Frequency,...
                NumberOfStandardDeviations=options.ConfidenceRegionNumberSD,...
                Name=optionalInputs.SystemData(k).Name);

            if ~isempty(hResponses(k).DataException)
                throw(hResponses(k).DataException);
            end
        end
        ny = numel(unique(cat(1,hResponses.OutputNames)));
        % Create chart
        h = controllib.chart.IOFrequencyPlot(ny,Parent=hParent,Visible=false,Axes=ax,...
            CreateResponseDataTipsOnDefault=optionalInputs.CreateResponseDataTipsOnDefault,...
            CreateToolbarOnDefault=optionalInputs.CreateToolbarOnDefault);
        if strcmp(options.FreqUnits,"auto") && ~isempty(hResponses)
            h.FrequencyUnit = hResponses(1).FrequencyUnit;
        end
end

for k = 1:length(hResponses)
    if plotType ~= "hsv"
        if ~isempty(optionalInputs.SystemData(k).LineStyle) && isprop(hResponses(k),'LineStyle')
            hResponses(k).LineStyle = optionalInputs.SystemData(k).LineStyle;
        end
        if ~isempty(optionalInputs.SystemData(k).Color) && isprop(hResponses(k),'Color')
            hResponses(k).Color = optionalInputs.SystemData(k).Color;
        end
        if ~isempty(optionalInputs.SystemData(k).MarkerStyle) && isprop(hResponses(k),'MarkerStyle')
            hResponses(k).MarkerStyle = optionalInputs.SystemData(k).MarkerStyle;
        end
    end
    registerResponse(h,hResponses(k));
end

if ~isempty(optionalInputs.Options)
    setoptions(h,optionalInputs.Options);
end

if isprop(h,'OutputNames')
    if isempty(optionalInputs.OutputNames)
        if ~isempty(optionalInputs.SystemData)
            for ii = 1:length(outputNames)
                if strcmp(outputNames{ii},"")
                    h.OutputNames(ii) = "Out(" + ii + ")";
                else
                    h.OutputNames(ii) = outputNames{ii};
                end
            end
        end
    else
        h.OutputNames = optionalInputs.OutputNames;
    end
end
if isprop(h,'InputNames')
    if isempty(optionalInputs.InputNames)
        if ~isempty(optionalInputs.SystemData)
            for ii = 1:length(inputNames)
                if strcmp(inputNames{ii},"")
                    h.InputNames(ii) = "In(" + ii + ")";
                else
                    h.InputNames(ii) = inputNames{ii};
                end
            end
        end
    else
        h.InputNames = optionalInputs.InputNames;
    end
end

if isempty(hParent)
    h.Parent = gcf;
end

if ~isempty(chartValuesFromAxes)
    if isfield(chartValuesFromAxes,'OuterPosition')
        h.Units = chartValuesFromAxes.Units;
        h.OuterPosition = chartValuesFromAxes.OuterPosition;
    else
        h.Layout = chartValuesFromAxes.Layout;
    end

    if isfield(chartValuesFromAxes,'Children') && ~isempty(chartValuesFromAxes.Children)
        h.Visible = true; %force build so axes exist
        addCustomChildrenBeforeResponses(h,chartValuesFromAxes.Children);
    end
end

h.NextPlot = nextPlotToSet;
h.Visible = optionalInputs.Visible;

end

%------------------------------------------------------------------------------------------------
function localAddSystem(h,optionalInputs)
if strcmpi(h.Type,"hsv") % No system data
    addResponse(h,optionalInputs.R,HSVType=optionalInputs.Type);
end
for k = 1:length(optionalInputs.SystemData)
    switch h.Type
        case {"step","impulse"}
            if isempty(optionalInputs.Config)
                optionalInputs.Config = RespConfig;
            end
            addResponse(h,optionalInputs.SystemData(k).System,...
                optionalInputs.Time,...
                optionalInputs.Parameter,...
                Name=optionalInputs.SystemData(k).Name,...
                Config=optionalInputs.Config,...
                Color=optionalInputs.SystemData(k).Color,...
                LineStyle=optionalInputs.SystemData(k).LineStyle,...
                MarkerStyle=optionalInputs.SystemData(k).MarkerStyle);
        case "initial"
            addResponse(h,optionalInputs.SystemData(k).System,...
                optionalInputs.Config,...
                optionalInputs.Time,...
                optionalInputs.Parameter,...
                Name=optionalInputs.SystemData(k).Name,...
                Color=optionalInputs.SystemData(k).Color,...
                LineStyle=optionalInputs.SystemData(k).LineStyle,...
                MarkerStyle=optionalInputs.SystemData(k).MarkerStyle);
        case "lsim"
            addResponse(h,optionalInputs.SystemData(k).System,...
                optionalInputs.InputSignal,...
                optionalInputs.Time,...
                optionalInputs.Config,...
                optionalInputs.Parameter,...
                Name=optionalInputs.SystemData(k).Name,...
                InterpolationMethod=optionalInputs.InterpolationMethod,...
                Color=optionalInputs.SystemData(k).Color,...
                LineStyle=optionalInputs.SystemData(k).LineStyle,...
                MarkerStyle=optionalInputs.SystemData(k).MarkerStyle);
        case "sigma"
            addResponse(h,optionalInputs.SystemData(k).System,...
                optionalInputs.Frequency,...
                optionalInputs.Type,...
                Name=optionalInputs.SystemData(k).Name,...
                Color=optionalInputs.SystemData(k).Color,...
                LineStyle=optionalInputs.SystemData(k).LineStyle,...
                MarkerStyle=optionalInputs.SystemData(k).MarkerStyle);
       case {"bode","nyquist","nichols","iofrequency"}
            addResponse(h,optionalInputs.SystemData(k).System,...
                optionalInputs.Frequency,...
                Name=optionalInputs.SystemData(k).Name,...
                Color=optionalInputs.SystemData(k).Color,...
                LineStyle=optionalInputs.SystemData(k).LineStyle,...
                MarkerStyle=optionalInputs.SystemData(k).MarkerStyle);
        case {"pzmap","iopzmap"}
            addResponse(h,optionalInputs.SystemData(k).System,...
                Name=optionalInputs.SystemData(k).Name,...
                Color=optionalInputs.SystemData(k).Color);
        case "rlocus"
            addResponse(h,optionalInputs.SystemData(k).System,...
                optionalInputs.Parameter,...
                Name=optionalInputs.SystemData(k).Name,...
                Color=optionalInputs.SystemData(k).Color,...
                LineStyle=optionalInputs.SystemData(k).LineStyle,...
                MarkerStyle=optionalInputs.SystemData(k).MarkerStyle);
        case "sector"
            addResponse(h,optionalInputs.SystemData(k).System,...
                optionalInputs.Q,...
                Name=optionalInputs.SystemData(k).Name,...
                Frequency=optionalInputs.Frequency,...
                Color=optionalInputs.SystemData(k).Color,...
                LineStyle=optionalInputs.SystemData(k).LineStyle,...
                MarkerStyle=optionalInputs.SystemData(k).MarkerStyle);
        case "passive"
            addResponse(h,optionalInputs.SystemData(k).System,...
                Type=optionalInputs.Type,...
                Name=optionalInputs.SystemData(k).Name,...
                Frequency=optionalInputs.Frequency,...
                Color=optionalInputs.SystemData(k).Color,...
                LineStyle=optionalInputs.SystemData(k).LineStyle,...
                MarkerStyle=optionalInputs.SystemData(k).MarkerStyle);
        case "diskmargin"
            addResponse(h,optionalInputs.SystemData(k).System,...
                Skew=optionalInputs.Skew,...
                Name=optionalInputs.SystemData(k).Name,...
                Frequency=optionalInputs.Frequency,...
                Color=optionalInputs.SystemData(k).Color,...
                LineStyle=optionalInputs.SystemData(k).LineStyle,...
                MarkerStyle=optionalInputs.SystemData(k).MarkerStyle);
       case "iotime"

    end
end
end

function validateIfGraphicsObject(hParent)
if ~isempty(hParent) && ~isgraphics(hParent)
    error('Input must be a graphics object.');
end
end

%---------------------------------------------------------------------------------------------------
function [nextPlotToSet,chartValuesFromAxes,ax] = parseAxes(ax,plotType,optionalInputs)
nextPlotToSet = 'replace';
chartValuesFromAxes = [];
h = ancestor(ax,'controllib.chart.internal.foundation.AbstractPlot');
fig = ancestor(ax,'figure');
if ~isempty(h)
    nextPlotToSet = h.NextPlot;
    if isHoldEnabled(h)
        % Hold is on, check if plotType is same as existing chart
        if plotType == string(h.Type)
            % Add system to current plot and set createNewChart flag to
            % false
            if isa(h,'controllib.chart.internal.foundation.MixInInputOutputPlot') && ~h.SupportDynamicGridSize &&...
                    ((~isempty(optionalInputs.NInputs) && optionalInputs.NInputs > length(h.InputVisible)) ||...
                    (~isempty(optionalInputs.NOutputs) && optionalInputs.NOutputs > length(h.OutputVisible)))
                error(message('Controllib:plots:hold1'))
            elseif isa(h,'controllib.chart.internal.foundation.OutputPlot') &&  ~h.SupportDynamicGridSize &&...
                    (~isempty(optionalInputs.NOutputs) && optionalInputs.NOutputs > length(h.OutputVisible))
                error(message('Controllib:plots:hold1'))
            end
            localAddSystem(h,optionalInputs);
            nextPlotToSet = 'washeld';
            ax = h;
        else
            % Throw error, new plotType is not compatible with current chart
            error(message('Controllib:plots:hold1'))
        end
    else
        ax = getChartAxes(h);
        ax = ax(1);
        if isempty(h.Layout)
            chartValuesFromAxes.OuterPosition = h.OuterPosition;
            chartValuesFromAxes.Units = h.Units;
        else
            chartValuesFromAxes.Layout = h.Layout;
        end
        ax.Parent = [];
        ax.Visible = false;
        matlab.graphics.internal.clearNotify(fig, ax);
        delete(h);
        delete(allchild(ax));
        cla(ax,'reset');
    end
elseif isa(ax,'matlab.graphics.axis.Axes') || isa(ax,'matlab.ui.control.UIAxes')
    if strcmp(ax.NextPlot,'add') || strcmp(ax.NextPlot,'replace')
        nextPlotToSet = ax.NextPlot;
    end
    isResppack = ~isempty(gcr(ax));
    if isResppack
        chartValuesFromAxes.OuterPosition = ax.OuterPosition;
        chartValuesFromAxes.Units = ax.Units;
        cla(ax,'reset');
        ax.LooseInset = get(groot,"DefaultAxesLooseInset");
    else
        if strcmp(nextPlotToSet,'add')
            chartValuesFromAxes.Children = allchild(ax);
            set(chartValuesFromAxes.Children,Parent=[]);
        end
        if isempty(ax.Layout)
            chartValuesFromAxes.OuterPosition = ax.OuterPosition;
            chartValuesFromAxes.Units = ax.Units;
        else
            chartValuesFromAxes.Layout = ax.Layout;
        end
        cla(ax,'reset');
    end
    ax.Parent = [];
    ax.Visible = false;
else %another chart
    if isempty(ax.Layout)
        chartValuesFromAxes.OuterPosition = ax.OuterPosition;
        chartValuesFromAxes.Units = ax.Units;
    else
        chartValuesFromAxes.Layout = ax.Layout;
    end
    delete(ax);
    ax = matlab.graphics.axis.Axes.empty;
end
end