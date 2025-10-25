function [dim, maxNumExtrema, minSep, minProm, flatType, samplePoints, dataVars, pwin, fmt] = parseLocalExtremaInputs(A, is2D, varargin)
% parseLocalExtremaInputs Helper for local extrema functions

% Copyright 2023 The MathWorks, Inc.

% Validate input array type.
if isnumeric(A) || islogical(A)
    if ~isreal(A)
        error(message('MATLAB:isLocalExtrema:ComplexInputArray'));
    end
    AisTabular = false;
elseif is2D
    error(message("MATLAB:isLocalExtrema:FirstInputInvalid2D"));
elseif istabular(A)
    AisTabular = true;
else
    error(message('MATLAB:isLocalExtrema:FirstInputInvalid'));
end

% Set default parameters.
if AisTabular
    dim = 1;
    dataVars = 1:width(A);
else
    dim = matlab.internal.math.firstNonSingletonDim(A);
    dataVars = []; % not supported for arrays
end
minSep = 0;
minProm = 0;
flatType = 'center';
if is2D
    samplePoints = {[],[]};
else
    samplePoints = [];
end
userGaveMinSep = false;
pwin = [];
fmt = 'logical';
maxNumExtrema = inf;

% Parse dim input. Not supported for 2D functions.
argIdx = 1;
if ~is2D && (nargin > 2) && (isnumeric(varargin{argIdx}) || ...
        islogical(varargin{argIdx}))
    if AisTabular
        error(message('MATLAB:isLocalExtrema:DimensionTable'));
    end
    dim = varargin{argIdx};
    argIdx = 2;
    if ~isRealFiniteNonNegativeScalar(dim, true) || (fix(dim) ~= dim)
        error(message('MATLAB:isLocalExtrema:DimensionInvalid'));
    end
end

% Parse Name-Value Pairs.
numRemainingArguments = nargin-2-(argIdx-1);
if rem(numRemainingArguments, 2) ~= 0
    error(message('MATLAB:isLocalExtrema:NameValuePairs'));
end

nameOptions = ["MaxNumExtrema", "MinSeparation", "MinProminence", ...
    "FlatSelection", "SamplePoints", "ProminenceWindow"];
if ~is2D
    tabularOptions = ["DataVariables", "OutputFormat"];
    nameOptions = [nameOptions,tabularOptions];
end

spvar = [];
for i = 1:2:numRemainingArguments
    optionMatches = matlab.internal.math.checkInputName(varargin{argIdx},nameOptions);
    % Note that optionMatches will have a length of 8 for the 1D case and 6
    % for the 2D case

    % Multiple or no matches.
    if sum(optionMatches) ~= 1
        if AisTabular
            error(message('MATLAB:isLocalExtrema:InvalidNameTable'));
        else
            error(message('MATLAB:isLocalExtrema:InvalidNameArray'));
        end
    end
    if optionMatches(1) % MaxNumExtrema
        maxNumExtrema = varargin{argIdx+1};
        if ~(isnumeric(maxNumExtrema) || islogical(maxNumExtrema)) || ...
                ~isscalar(maxNumExtrema) || ~isreal(maxNumExtrema) || ...
                (maxNumExtrema <= 0) || (fix(maxNumExtrema) ~= maxNumExtrema)
            error(message('MATLAB:isLocalExtrema:MaxNumInvalid'));
        end
    elseif optionMatches(2) % MinSeparation
        minSep = varargin{argIdx+1};
        if ~isValidMinSeparation(minSep, is2D)
            if is2D
                error(message('MATLAB:isLocalExtrema:MinSeparationInvalid2D'));
            else
                error(message('MATLAB:isLocalExtrema:MinSeparationInvalid'));
            end
        end
        userGaveMinSep = true;
    elseif optionMatches(3) % MinProminence
        minProm = varargin{argIdx+1};
        if ~(isnumeric(minProm) || islogical(minProm)) || ...
                ~isRealFiniteNonNegativeScalar(minProm, false)
            error(message('MATLAB:isLocalExtrema:MinProminenceInvalid'));
        end
    elseif optionMatches(4) % FlatSelection
        if is2D
            flatOptions = ["all", "first", "center"];
        else
            flatOptions = ["all", "first", "center", "last"];
        end
        opt = varargin{argIdx+1};
        tf = matlab.internal.math.checkInputName(opt,flatOptions);
        if sum(tf) ~= 1 % No or multiple matches.
            if is2D
                error(message('MATLAB:isLocalExtrema:FlatSelectionInvalid2D'))
            else
                error(message('MATLAB:isLocalExtrema:FlatSelectionInvalid'));
            end
        end
        flatType = flatOptions(tf);
    elseif optionMatches(5) % SamplePoints
        if AisTabular && istimetable(A)
            error(message('MATLAB:samplePoints:SamplePointsTimeTable'));
        end
        samplePoints = varargin{argIdx+1};
        [samplePoints,spvar] = checkSamplePoints(samplePoints,A,AisTabular,dim,is2D);
    elseif optionMatches(6) % ProminenceWindow
        pwin = varargin{argIdx+1};
        if is2D
            matlab.internal.math.validate2DWindow(pwin);
        else
            validPwin = (isnumeric(pwin) && isreal(pwin)) || ...
                isduration(pwin);
            if validPwin
                if isscalar(pwin)
                    validPwin = ~isnan(pwin) && (pwin > 0);
                else
                    validPwin = all(~isnan(pwin(:))) && all(pwin(:) >= 0) && ...
                        isvector(pwin) && (numel(pwin) == 2);
                end
            end
            if ~validPwin
                error(message('MATLAB:isLocalExtrema:ProminenceWindowLengthInvalid'));
            end
        end
    elseif optionMatches(7) % DataVariables
        if AisTabular
            dataVars = matlab.internal.math.checkDataVariables(A,...
                varargin{argIdx+1},'isLocalExtrema');
        else
            error(message('MATLAB:isLocalExtrema:DataVariablesArray'));
        end
    else % OutputFormat
        if AisTabular
            fmt = validatestring(varargin{argIdx+1},{'logical','tabular'},'isLocalExtrema','OutputFormat');
        else
            error(message('MATLAB:isLocalExtrema:OutputFormatArray'));
        end
    end
    argIdx = argIdx + 2;
end
if ~isempty(spvar)
    dataVars(dataVars == spvar) = [];
end

% Set default sample points.
if AisTabular && istimetable(A)
    samplePoints = matlab.internal.math.checkSamplePoints(A.Properties.RowTimes,A,false,true,dim);
end

% Generate explicit sample points when no sample points are given unless
% the data is sparse
generateExplicitSamplePoints =  (isempty(samplePoints) || ...
    (is2D && isempty(samplePoints{1}) && isempty(samplePoints{2}))) && ...
    ~issparse(A);


if is2D
    % Scalar minSeparation requires that both sample points vectors be
    % numeric or time types (datetimes or durations)
    if xor(isnumeric(samplePoints{1}),isnumeric(samplePoints{2})) && isscalar(minSep) && userGaveMinSep
        error(message("MATLAB:isLocalExtrema:SeparationMustBeCellForIncompatibleSP"));
    end

    if ~iscell(pwin) % Non-cell values can either be scalar or empty (default)
        pwin = {pwin, pwin};
    end

    if isscalar(minSep)
        minSepTmp{1} = minSep;
        minSepTmp{2} = minSep;
    else
        minSepTmp = minSep;
    end
    [minSepTmp{1}, pwin{1}, samplePoints{1}] = checkMinSepAndPWin( ...
        minSepTmp{1}, userGaveMinSep, pwin{1}, A, samplePoints{1}, 1, generateExplicitSamplePoints, is2D);
    [minSepTmp{2}, pwin{2}, samplePoints{2}] = checkMinSepAndPWin( ...
        minSepTmp{2}, userGaveMinSep, pwin{2}, A, samplePoints{2}, 2, generateExplicitSamplePoints, is2D);
    if ~userGaveMinSep
        minSep = minSepTmp;
    end
else
    [minSep, pwin, samplePoints] = checkMinSepAndPWin(minSep, ...
        userGaveMinSep, pwin, A, samplePoints, dim, generateExplicitSamplePoints, is2D);
end
end

%--------------------------------------------------------------------------
function [minSep, pwin, samplePoints] = checkMinSepAndPWin(minSep, userGaveMinSep, pwin, A, samplePoints, dim, generateExplicitSamplePoints, is2D)
isTimetable = istimetable(A);
minSep = checkMinSepAndPwinUnits(samplePoints,minSep,isTimetable,userGaveMinSep,pwin);

% Remove pwin if the specified prominence window always include all of
% the data
if checkWindowBounds(A, samplePoints, pwin, dim)
    pwin = [];
end

pwin = full(pwin);

% For efficiency, we can check if we can just totally ignore sample
% points and minimum separation.
if (numel(samplePoints) < 2)
    minimumDistance = 1;
else
    minimumDistance = min(diff(samplePoints));
end


if (minSep < minimumDistance) && isempty(pwin)
    minSep = 0;
    if ~is2D % 2D functions use sample points for calculating centroids
        samplePoints = [];
    end
elseif generateExplicitSamplePoints
    samplePoints = 1:size(A,dim);
end
end


%--------------------------------------------------------------------------
function tf = isValidMinSeparation(minSep, is2D)
if is2D
    if iscell(minSep)
        tf = numel(minSep) == 2 && ...
            isRealFiniteNonNegativeScalar(minSep{1},false) && ...
            isRealFiniteNonNegativeScalar(minSep{2},false);
    else
        tf = isRealFiniteNonNegativeScalar(minSep,false);
    end
else
    tf = isRealFiniteNonNegativeScalar(minSep,false);
end
end

%--------------------------------------------------------------------------
function tf = isRealFiniteNonNegativeScalar(A, strictlyPositive)
% Determine if an input is a real, finite, non-negative scalar.
if strictlyPositive
    tf = isreal(A) && isscalar(A) && (A > 0) && isfinite(A);
else
    tf = isreal(A) && isscalar(A) && (A >= 0) && isfinite(A);
end
end

%--------------------------------------------------------------------------
function tf = checkWindowBounds(A, samplePoints, pwin, dim)
% Determines if the prominence window is large enough that it can be
% ignored
if isempty(samplePoints)
    samplePointsBounds = [1 size(A,dim)];
else
    samplePointsBounds = [samplePoints(1), samplePoints(end)];
end
if isscalar(pwin)
    tf = (pwin/2) > (samplePointsBounds(2) - samplePointsBounds(1));
else
    tf = all(pwin > (samplePointsBounds(2)-samplePointsBounds(1)));
end
end

%--------------------------------------------------------------------------
function [samplePoints,spvar] = checkSamplePoints(samplePoints,A,AisTabular,dim,is2D)
if is2D
    matlab.internal.math.validate2DSamplePoints(A,samplePoints);
    spvar = [];
else
    [samplePoints,spvar] = matlab.internal.math.checkSamplePoints(samplePoints,A,AisTabular,false,dim);
    if ~(isfloat(samplePoints) || isduration(samplePoints) || isdatetime(samplePoints))
        error(message('MATLAB:samplePoints:SamplePointsInvalidDatatype'));
    end
    % If A is empty and x is a valid varspec, everything flows through
    % checkSamplePoints but will not flow through checkWindowBounds
    % unless we set x = []
    if isempty(A) && ~isempty(samplePoints)
        samplePoints = [];
    end
end
end

%--------------------------------------------------------------------------
function minSep = checkMinSepAndPwinUnits(samplePoints,minSep,isTimetable,userGaveMinSep,pwin)
% Check that minimum separation is in the correct units.
if isduration(samplePoints) || isdatetime(samplePoints)
    if ~isduration(minSep)
        % Error if user gave a non-duration minimum separation.
        if userGaveMinSep
            if isTimetable
                error(message('MATLAB:isLocalExtrema:SeparationMustBeDurationTimetable'));
            else
                error(message('MATLAB:isLocalExtrema:SeparationMustBeDuration'));
            end
        end
        minSep = milliseconds(0);
    end
    if ~isempty(pwin) && ~isduration(pwin)
        if isTimetable
            error(message('MATLAB:isLocalExtrema:ProminenceWindowMustBeDurationTimetable'));
        else
            error(message('MATLAB:isLocalExtrema:ProminenceWindowMustBeDuration'));
        end
    end
else
    if isduration(minSep)
        % Error if user gave a duration minimum separation.
        error(message('MATLAB:isLocalExtrema:SeparationCannotBeDuration'));
    end
    if isduration(pwin)
        % Error if user gave a duration prominence window.
        error(message('MATLAB:isLocalExtrema:ProminenceWindowCannotBeDuration'));
    end
end
end