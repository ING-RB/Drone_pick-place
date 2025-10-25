function varargout = gather(varargin)
%GATHER Execute queued operations and collect tall array into workspace
%   X = GATHER(TX) executes all queued operations required to calculate
%   tall array TX, then collects the results in the local workspace as X.
%
%   Gathering a tall array involves evaluating the underlying operations
%   needed to compute the result. Most operations on tall arrays are
%   deferred until you call GATHER to be efficient for big data. To fully
%   utilize the advantages of tall arrays it is important to use GATHER
%   only when you need to see output.
%
%   The GATHER function returns the entire result into the local memory of
%   MATLAB. Therefore, if the tall array has not been reduced in some way
%   (for example by using a summarizing function such as MIN or SUM), then
%   the call to GATHER can cause MATLAB to run out of memory. If you are
%   unsure whether the result can fit in memory, use GATHER(HEAD(TX)) or
%   GATHER(TAIL(TX)) to bring only a small portion of the result into
%   memory.
%
%   [X1,X2,...] = GATHER(TX1,TX2,...) gathers multiple tall arrays at the
%   same time. This syntax is more efficient than multiple separate calls
%   to GATHER.
%
%   Example:
%      % Create a datastore.
%      varnames = {'ArrDelay', 'DepDelay', 'Origin', 'Dest'};
%      ds = datastore('airlinesmall.csv', 'TreatAsMissing', 'NA', ...
%         'SelectedVariableNames', varnames);
%
%      % Create a tall table from the datastore.
%      tt = tall(ds);
%
%      % Compute the minimum and maximum arrival delays, ignoring NaN values. 
%      % minDelay and maxDelay are unevaluated tall arrays.
%      minDelay = min(tt.ArrDelay, [], 'omitnan'); 
%      maxDelay = max(tt.ArrDelay, [], 'omitnan');
%
%      % Here we gather both values simultaneously, forcing evaluation.
%      [localMin, localMax] = gather(minDelay, maxDelay);
%
%   See also: TALL, TALL/HEAD, TALL/TAIL.

%   Copyright 2015-2023 The MathWorks, Inc.

if nargout > nargin
    error(message('MATLAB:bigdata:array:GatherInsufficientInputs'));
end

varargout = cell(1, nargin);
[varargout{:}, readFailureSummary] = iGather(varargin{:});

if readFailureSummary.NumFailures ~= 0
    firstFewLocations = readFailureSummary.Locations(1:min(3, end));
    warning(message("MATLAB:bigdata:executor:ReadFailureWarning", ...
        strjoin(firstFewLocations, newline)));
end

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = iGather(varargin)

% This prevents this frame and anything below it being added to the gather
% error stack.
frameMarker = matlab.bigdata.internal.InternalStackFrame; %#ok<NASGU>

isArgTall = cellfun(@istall, varargin);

try
    % First gather the tall inputs, and check the adaptors had correct
    % information. Ensure that the adaptor assertion is enabled before
    % unpacking tall arguments.
    prevState = matlab.bigdata.internal.util.enableAdaptorAssertion(true);
    tallArgs = matlab.bigdata.internal.util.unpackTallArguments(varargin(isArgTall));
    matlab.bigdata.internal.util.enableAdaptorAssertion(prevState);
    [gatheredTalls{1:sum(isArgTall)}, readFailureSummary] = gather(tallArgs{:});
    if readFailureSummary.NumFailures == 0
        cellfun(@iAssertAdaptorMatches, gatheredTalls, varargin(isArgTall));
    end

    % Then, gather the non-tall inputs. Here we're presuming a
    % lowest-common-denominator single-input-only form of GATHER.
    otherArgs = cellfun(@gather, varargin(~isArgTall), 'UniformOutput', false);

    % Stitch the various gathered arrays back into a single cell array
    varargout             = cell(1, nargin + 1);
    varargout(isArgTall)  = gatheredTalls;
    varargout(~isArgTall) = otherArgs;
    varargout{end} = readFailureSummary;
catch err
    matlab.bigdata.internal.util.assertNotInternal(err);
    if matlab.internal.display.isHot
        msg = getString(message('MATLAB:bigdata:array:ErrorDuringGather'));
        err = appendToMessage(err, msg);
    end
    updateAndRethrow(err);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function iAssertAdaptorMatches(local, tvar)

assertionFmtPrefix = 'An internal consistency error occurred. Details:\n';

adaptor = matlab.bigdata.internal.adaptors.getAdaptor(tvar);
actualClass = class(local);
expectedClass = adaptor.Class;
if ~isempty(expectedClass)
    assert(strcmp(expectedClass, actualClass), ...
           [assertionFmtPrefix, ...
            '  Class of output incorrect. Expected: %s, actual: %s.'], ...
           expectedClass, actualClass);
else
    assert(~ismember(actualClass, matlab.bigdata.internal.adaptors.getStrongTypes()), ...
           'MATLAB:bigdata:array:AssertStrongType', ..., ...
           [assertionFmtPrefix, ...
            '  Class of output unexpectedly not known. Actual class: %s'], ...
           actualClass);
end

actualNdims = ndims(local);
expectedNdims = adaptor.NDims;
assert(isnan(expectedNdims) || isequal(actualNdims, expectedNdims), ...
       [assertionFmtPrefix, ...
        '  NDIMS of output incorrect. Expected: %d, actual: %d.'], ...
        expectedNdims, actualNdims);
actualSize = size(local);

expectedTallSize = adaptor.TallSize.Size;
if ~isnan(expectedTallSize)
    actualTallSize = actualSize(1);
    if actualTallSize ~= expectedTallSize
        matlab.bigdata.internal.throw( ...
             message('MATLAB:bigdata:array:BadTallSizeKnown', actualTallSize, expectedTallSize));
    end
end

if ~isnan(expectedNdims)
    expectedSize = adaptor.Size;
    ok = (actualSize == expectedSize) | isnan(expectedSize);
    assert(all(ok), ...
           [assertionFmtPrefix, ...
            '  SIZE of output incorrect. Expected: [%s], actual: [%s].'], ...
           num2str(expectedSize), num2str(actualSize));
end

% Recurse to ensure all nested type/sizes are as expected.
if istable(local) || istimetable(local)
    % First check we have the right variable and dimension names
    iAssertPropertiesMatch(class(local), 'variable', ...
        local.Properties.VariableNames, adaptor.getVariableNames());
    iAssertPropertiesMatch(class(local), 'dimension', ...
        local.Properties.DimensionNames, adaptor.getDimensionNames());
    % Now check that each variable also matches
    for ii = 1:width(local)
        iAssertAdaptorMatches(local.(ii), subsref(tvar, substruct('.', ii)));
    end
end

% If the tall adaptor contains the categories (we have a guarantee that all
% partitions have identical categories), check that these match with the
% categories in the local value.
if iscategorical(local) && ~isempty(adaptor.getCategories())
    iAssertPropertiesMatch(class(local), 'categories', ...
        categories(local), adaptor.getCategories());
end

% This will update the TallSize handle behind the scenes so that other arrays
% with the same TallSize get their size populated.
setKnownSize(adaptor, actualSize);
end

function iAssertPropertiesMatch(typename, propname, actual, expected)
% Format the assertion message for two lists of names
assert(isequal(actual, expected), ...
        [sprintf('An internal consistency error occurred. %s %s names are incorrect:', typename, propname), ...
        sprintf('\n    Expected: [%s]',strjoin(expected,',')) ...
        sprintf('\n    Actual: [%s]',strjoin(actual,','))]);
end