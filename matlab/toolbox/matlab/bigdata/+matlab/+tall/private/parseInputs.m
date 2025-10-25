function [dataArguments, outputsLike, options] = parseInputs(name, numOutputs, varargin)
% Parse input arguments into data arguments and option parameters.
%
% This will handle the varargin and "OutputsLike" input arguments of
% TRANSFORM, REDUCE, MOVINGWINDOW and BLOCKMOVINGWINDOW.

%   Copyright 2018 The MathWorks, Inc.

try
    nvParser = inputParser;
    nvParser.FunctionName = name;
    nvParser.addParameter('OutputsLike', {});
    isMovingWindow = strcmpi(name, 'matlab.tall.movingWindow') || strcmpi(name, 'matlab.tall.blockMovingWindow');
    if isMovingWindow
        % Default stride value for matlab.tall.movingWindow: 1
        nvParser.addParameter('Stride', 1);
        % Default 'EndPoints' option for matlab.tall.movingWindow: 'shrink'
        % Compute the result only with existing elements, even if there are
        % less than the window length.
        nvParser.addParameter('EndPoints', 'shrink');
    end
    nvNames = nvParser.Parameters;
    
    % We want to avoid parsing data arguments as name-value parameters
    % unless one of them exactly matches "OutputsLike".
    numDataArguments = numel(varargin);
    for ii = 1 : numel(varargin)
        in = varargin{ii};
        isStringInput = matlab.internal.datatypes.isScalarText(in);
        if isStringInput && any(startsWith(nvNames, in, 'IgnoreCase', true))
            numDataArguments = ii - 1;
            break;
        end
    end
    
    if numDataArguments == 0
        error(message('MATLAB:bigdata:custom:DataInputsRequired'));
    end
    dataArguments = varargin(1 : numDataArguments);
    nvParser.parse(varargin{numDataArguments + 1 : end});
    
    outputsLike = nvParser.Results.OutputsLike;
    options.IsDefaultOutputsLike = contains('OutputsLike', nvParser.UsingDefaults);
    if options.IsDefaultOutputsLike
        outputsLike(1:numOutputs) = dataArguments(1);
    elseif ~iscell(outputsLike) || numel(outputsLike) ~= numOutputs
        error(message('MATLAB:bigdata:custom:OutputsLikeIncorrect', numOutputs));
    end
    for ii = 1:numel(outputsLike)
        % To avoid communicating data where possible, flatten local inputs
        % to height zero.
        if ~istall(outputsLike{ii})
            outputsLike{ii} = matlab.bigdata.internal.util.indexSlices(outputsLike{ii}, []);
        end
    end
    
    if isMovingWindow
        % Extract extra name-value pairs of matlab.tall.movingWindow
        % Stride
        stride = nvParser.Results.Stride;
        isDefaultStride = contains('Stride', nvParser.UsingDefaults);
        if ~isDefaultStride
            tall.checkNotTall(name, 2, stride);
            validateattributes(stride, {'numeric'}, ...
                {'scalar', 'nonempty', 'nonsparse', 'finite', 'integer', 'positive'}, ...
                name, 'stride');
        end
        
        % EndPoints
        endPoints = nvParser.Results.EndPoints;
        options.IsDefaultEndPoints = contains('EndPoints', nvParser.UsingDefaults);
        
        % Use double.empty as default fillValue for "shrink" and "discard",
        % it will not be used in matlab.tall.movingWindow.
        fillValue(1:numDataArguments) = {double.empty};
        
        % endPoints can be "shrink", "discard" or a sample value of the
        % same type as the input. 
        if ~options.IsDefaultEndPoints
            isStringEndPoints = matlab.internal.datatypes.isScalarText(endPoints);
            if isStringEndPoints
                if startsWith("shrink", endPoints, 'IgnoreCase', true)
                    endPoints = "shrink";
                elseif startsWith("discard", endPoints, 'IgnoreCase', true)
                    endPoints = "discard";
                else
                    % String value for padding
                    fillValue(1:numDataArguments) = {endPoints};
                    endPoints = "fill";
                end
            else
                % Sample value for padding
                fillValue(1:numDataArguments) = {endPoints};
                endPoints = "fill";
            end
        end
        
        % Add Stride, EndPoints and FillValue to options struct
        options.Stride = stride;
        options.EndPoints = endPoints;
        options.FillValue = fillValue;
    end
catch err
    throwAsCaller(err);
end
end
