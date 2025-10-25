function generatedCode = generateControlsPlotCode(chartName, outputs, channels, parameters, doGenerateLabels)

% This function returns the generated code when visualizing a Controls
% Toolbox plot: stepplot, impulseplot, bodeplot, nicholsplot, nyquistplot,
% sigmaplot, pzplot, iopzplot, rlocus, hsvplot

% FOR INTERNAL USE ONLY -- This function is intentionally undocumented
% and is intended for use only with the scope of function in the MATLAB
% Engine APIs.  Its behavior may change, or the function itself may be
% removed in a future release.

% Copyright 2022-2024 The MathWorks, Inc.

%% generatedCode - initialize
% Initial value of code and summaryLine (to be used if no input provided)
code='';
summaryLine = getString(message('MATLAB:graphics:visualizedatatask:ChartInPurposeLine',chartName));
generatedCode = {code,summaryLine};

%% outputVar
% Generate outputVar based on specified outputs
outputVar = '';
if doGenerateLabels && ~isempty(outputs)
    numOutputs = numel(outputs);
    if numOutputs == 1
        outputVar = [outputs.name,' = '];
    else
        outputVar = '[';
        for i=1:numOutputs
            outputVar = [outputVar outputs(i).name ',']; %#ok<AGROW>
        end
        outputVar(end) = '';
        outputVar = [outputVar '] = '];
    end
end

%% inputArgs
% Generate inputArgs based on channels. Each channel corresonds to an
% input (required and optional) in the Live Task. This does not include the
% "Optional visualization parameters" section.
inputArgs = [];
annotationVarNames = {};
for i=1:numel(channels)
    channel = channels(i);
    
    dataMapped = channel.DataMapped;
    if strcmpi(dataMapped,'select variable') || strcmpi(dataMapped,'default value')
        if channel.IsRequired
            % Return if channel is required and input not provided
            return;
        end
    else
        annotationVarNames{end+1} = replace(dataMapped,'''',''''''); %#ok<AGROW>
        inputArgs = [inputArgs ,'`',dataMapped,'`,']; %#ok<AGROW>
    end
end
if isempty(annotationVarNames)
    annotationVarNames = {''};
end

%% summaryLine
% Get summary line from utility function (without legend)
zlabel = '';
[summaryLine, ~] = matlab.visualize.task.internal.codegen.defaults.generateNoLegend(chartName,...
    annotationVarNames, zlabel);

%% code - intialize
% Initialize code using output variable, chart name and input arguments
if strcmp(chartName,'hsvplot')
    sysName = ['`' channels(1).DataMapped '`'];
    if strcmpi(channels(2).DataMapped,'select variable') || strcmpi(channels(3).DataMapped,'default value')
        optName = '';
    else
        optName = ['`' channels(2).DataMapped '`'];
    end
    code = sprintf('R = reducespec(%s,''balanced'');',sysName);
    if isempty(optName)
        code = [code,newline,outputVar,'view(R)'];
        code = [code,newline,newline,'clear R'];
    else
        code = [code,newline,sprintf('viewOpts = namedargs2cell(get(%s));',optName)];
        code = [code,newline,outputVar,'view(R,viewOpts{:})'];
        code = [code,newline,newline,'clear R viewOpts'];
    end
else
    code = [outputVar,chartName,'(',inputArgs(1:end-1)];

    %% visualizationCode
    % Create visualization code based on specified parameters in "Optional
    % Visualization Parameters" section. Initialize defaults as empty character
    % arrays.
    numOfOptions = numel(parameters);
    optionalVisualizationParameterValue.LineStyle = '';
    optionalVisualizationParameterValue.Color = '';
    optionalVisualizationParameterValue.Marker = '';
    % Loop through all parameters
    for i=1:numOfOptions
        paramName = parameters(i).Name;
        paramVal = parameters(i).SelectedValue;
        if ~isempty(paramVal) && ~strcmpi(paramVal,'none') && ~strcmpi(paramVal,'default')
            % Assign value if parameter value is not empty, 'none' or 'default'
            optionalVisualizationParameterValue.(paramName) = paramVal;
        end
    end
    % Concatenate all parameter values to generate code string. For e.g.: 'r:o'
    optionalVisualizationCode = [optionalVisualizationParameterValue.LineStyle,...
        optionalVisualizationParameterValue.Marker,optionalVisualizationParameterValue.Color];

    %% code - finalize
    if ~isempty(optionalVisualizationCode)
        % Add single quotes if not empty. Append code with optional visualization code.
        optionalVisualizationCode = [',''',optionalVisualizationCode,''''];
        code = [code optionalVisualizationCode,');'];
    else
        code = [code ');'];
    end
end

%% generatedCode
% Return code and summaryLine
generatedCode = {code,summaryLine};
end