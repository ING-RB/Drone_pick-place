function [D,isDimSet,dim,omitnan,omitzero,isWeighted,w] = parseTallErrorMetricsInput(forMape,F,A,varargin)
%Helper to parse inputs for tall/RMSE and tall/MAPE.

%   Copyright 2022-2023 The MathWorks, Inc.

% We have to strip off any weights as these require dimension
% checks that might not yet be known.
[nonWeightArgs, w] = iValidateAndExtractWeights(forMape, varargin);
isWeighted = numel(nonWeightArgs) < numel(varargin);

% Weights must be tall.
if isWeighted && ~istall(w)
    error(message("MATLAB:bigdata:array:WeightMustBeTall"))
end

% Use the in-memory argument parsing to get check the remaining syntax and
% get us the options.
[~,isDimSet,dim,omitnan,omitzero] = ...
    tall.validateSyntax(@matlab.internal.math.parseErrorMetricsInput, ...
    [{forMape},{F},{A},nonWeightArgs],'DefaultType','double','NumOutputs',5);

% Create the error array.
D = F-A;

% Now some tall-specific code to make sure the weight vector (if any) has
% NaNs matching the data. If this throws it is likely that the weight
% vector had incompatible size. Since try-catch doesn't work for lazy
% operations we have to live with the standard dimension mismatch error,
% not the RMSE/MAPE-specific ones.
if isWeighted
    w = w + (D.*isnan(D));
end
end


% Validates the syntax of Weights (excluding its dimensions), and extracts
% the the weights value.  
function [args,weights] = iValidateAndExtractWeights(forMape, args)
weightsNamesIdxs = find(cellfun(@(x) matlab.internal.datatypes.isScalarText(x) && startsWith("Weights", x, "IgnoreCase", true), args));
weightsValuesIdxs = weightsNamesIdxs + 1;
weightsValuesIdxs = weightsValuesIdxs(weightsValuesIdxs <= numel(args));
weightsValuesIdxsToOverwrite = weightsValuesIdxs(cellfun(@(x) ~matlab.internal.datatypes.isScalarText(x), args(weightsValuesIdxs)));

if isempty(weightsNamesIdxs)
    weights = [];
else
    % Call matlab.internal.math.parseErrorMetricsInput with all the data
    % inputs and weights values overwritten to 1. This validates that
    % weights has been provided with a value, that it's been specified
    % after all the flags, and that it hasn't been specified with a vector
    % dim argument.
    argsCopy = args;
    if ~isempty(weightsValuesIdxsToOverwrite)
        % Set the weights values to an "in memory" scalar.
        argsCopy(weightsValuesIdxsToOverwrite) = {1};
    end

    try
        matlab.internal.math.parseErrorMetricsInput(forMape,1,1,argsCopy{:});
    catch E
        throwAsCaller(E)
    end

    % We know the weights syntax was valid, and that weights are the only
    % allowable NV pairs.  So extract the last weights value, and then
    % cut off all the Weights NP pairs from args.
    weights = args{weightsValuesIdxs(end)};
    args = args(1:(weightsNamesIdxs(1)-1));
end
end