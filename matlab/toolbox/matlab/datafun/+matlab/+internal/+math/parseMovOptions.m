function [k,dim,omitnan,endpoints,fillValue,samplePoints,dvars,replace,biased] = parseMovOptions(A,k,hasBiasOption,omitNaNByDefault,varargin)
% parseTabularMovOptions Parse tabular-specific options for moving statistics functions
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%

%   Copyright 2024-2025 The MathWorks, Inc.

if nargin < 2
    error(message("MATLAB:minrhs")) % Match error ID for builtin
end

AIsTabular = istabular(A);
AIsTimeTable = istimetable(A);

% Check k
if ~(isnumeric(k) || islogical(k) || isduration(k)) || ~isreal(k) || ...
        ~((isscalar(k) && k>0) || (numel(k)==2 && k(1)>=0 && k(2)>=0)) || ...
        ~allfinite(k)
    error(message("MATLAB:movfun:wrongWindowLength"));
end

% Default options
if AIsTabular
    dim = 1;
else
    dim = matlab.internal.math.firstNonSingletonDim(A);
end
biased = false;
omitnan = omitNaNByDefault;
endpoints = "shrink";
fillValue = [];
samplePoints = [];
explicitSamplePoints = false;
dvars = 1:width(A);
replace = true;
spvar = 0;

numArgs = numel(varargin);

if numArgs > 0
    currentInd = 1;
    % Parse bias
    if hasBiasOption && isnumeric(varargin{currentInd})
        biasInput = varargin{currentInd};
        if ~isempty(biasInput) % Empty bias is skipped    
            if ~isscalar(biasInput) || ...
                    ~(biasInput == 0 || biasInput == 1)
                error(message("MATLAB:movfun:wrongNormalization"))
            end
            biased = biasInput == 1;
        end
        currentInd = currentInd + 1;
    end

    % Parse dim
    if currentInd <= numArgs && isnumeric(varargin{currentInd})
        if AIsTabular
            error(message("MATLAB:movfun:noDimForTable"));
        end
        dim = varargin{currentInd};
        currentInd = currentInd + 1;
        if ~isscalar(dim) || ~isreal(dim) || dim < 1 || fix(dim) ~= dim
            error(message("MATLAB:getdimarg:dimensionMustBePositiveInteger"));
        end
    end

    validFlags = ["includenan","omitnan","includemissing","omitmissing"];
    validNames = ["Endpoints","SamplePoints"];
    if AIsTabular
        validNames = [validNames,"DataVariables","ReplaceValues"];
    end

    % Parse nan flag
    if currentInd <= numArgs
        matchedFlag = matlab.internal.math.checkInputName(varargin{currentInd},validFlags);
        if any(matchedFlag)
            omitnan = matchedFlag(2) || matchedFlag(4);
            currentInd = currentInd + 1;
        else
            % Check for a valid name argument for consistent erroring
            if(~any(matlab.internal.math.checkInputName(varargin{currentInd},validNames)))
                error(message("MATLAB:movfun:wrongString"));
            end
        end
    end
    
    spvar = [];
    while currentInd <= numArgs
        argName = validNames(matlab.internal.math.checkInputName(varargin{currentInd},validNames));
        if isempty(argName)
            if AIsTabular
                error(message("MATLAB:movfun:wrongNVPairTabular"));
            else
                error(message("MATLAB:movfun:wrongNVPair"));
            end
        end

        noValue = currentInd == numArgs;

        switch argName
            case "Endpoints"
                if noValue
                    error(message("MATLAB:movfun:noEndpointValue"));
                end
                validEndpoints = ["shrink","discard","fill"]; % The order of these is important
                ep = varargin{currentInd+1};
                endpoints = find(matlab.internal.math.checkInputName(ep,validEndpoints));
                % Endpoint options are encoded as integers: "shrink" = 1, "discard" = 2, "fill" = 3
                if isempty(endpoints)
                    % Check for specified fill value
                    if (isnumeric(ep) || islogical(ep)) && isscalar(ep)
                        endpoints = 3;
                        fillValue = ep;
                    else
                        error(message("MATLAB:movfun:wrongEndpoint"));
                    end
                else
                    if AIsTabular && endpoints == 2 % "discard"
                        error(message("MATLAB:movfun:discardWithTabular"));
                    end
                    fillValue = []; % Overwrite previous fill values with default
                end
            case "SamplePoints"
                if noValue
                    error(message("MATLAB:movfun:noSamplePointsValue"));
                end
                if AIsTimeTable
                    error(message("MATLAB:samplePoints:SamplePointsTimeTable"));
                end
                
                explicitSamplePoints = true;
                if AIsTabular
                    [samplePoints,spvar] = matlab.internal.math.checkSamplePoints(varargin{currentInd+1},A,AIsTabular,AIsTimeTable,dim);
                else
                    samplePoints = varargin{currentInd+1};
                    if isnumeric(samplePoints) && ~isreal(samplePoints)
                        error(message('MATLAB:movfun:SamplePointsComplex'));
                    end
                    if ~allfinite(samplePoints)
                        nonfiniteValue = "NaN";
                        if isdatetime(samplePoints)
                            nonfiniteValue = "NaT";
                        end
                        error(message('MATLAB:movfun:SamplePointsNonFinite',"SamplePoints",nonfiniteValue));
                    end
                end
            case "DataVariables"
                if noValue
                    error(message("MATLAB:movfun:noDataVariablesValue"));
                end
                dvars = matlab.internal.math.checkDataVariables(A,varargin{currentInd+1},"movfun");
            case "ReplaceValues"
                if noValue
                    error(message("MATLAB:movfun:noReplaceValuesValue"));
                end
                replace = matlab.internal.datatypes.validateLogical(varargin{currentInd+1},"ReplaceValues");
        end
        currentInd = currentInd + 2;
    end
end

% Extract or generate sample points if needed
if AIsTimeTable
    samplePoints = A.Properties.RowTimes;
    explicitSamplePoints = true;
end

% Checking A after optional arguments for consistent error behavior
if ~(isnumeric(A) || islogical(A) || AIsTabular)
    error(message("MATLAB:movfun:wrongInput"));
end

if ~isempty(dvars) && ~isempty(spvar)
    % Remove sample points variable from data variables
    dvars(dvars == spvar) = [];
end

if isdatetime(samplePoints) || isduration(samplePoints)
    % Check and convert time-type window sizes and sample points
    if ~isduration(k)
        error(message("MATLAB:movfun:winsizeNotDuration",class(samplePoints)));
    end
    k = milliseconds(k);
    if isdatetime(samplePoints)
        samplePoints = datetime.toMillis(samplePoints);
    else % isduration(samplePoints)
        samplePoints = milliseconds(samplePoints);
    end
elseif isduration(k)
        error(message("MATLAB:movfun:wrongWindowLength"));
end

if explicitSamplePoints
    samplePoints = {samplePoints};
else
    samplePoints = {};
end

if AIsTabular
    % Check for valid types
    if ~isempty(dvars)
        for currentInd = 1:numel(dvars)
            currentVar = A.(dvars(currentInd));
            if ~isnumeric(currentVar) && ~islogical(currentVar)
                varNames = A.Properties.VariableNames;
                error(message("MATLAB:movfun:wrongInputTabular",varNames{dvars(currentInd)}));
            end
        end
    end
end
end