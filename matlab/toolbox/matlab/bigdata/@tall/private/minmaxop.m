function [outY, outI] = minmaxop(fcn, arg1, arg2, varargin)
%MINMAXOP Common helper for MIN and MAX.

% Copyright 2015-2023 The MathWorks, Inc.

import matlab.internal.datatypes.isScalarText;
import matlab.bigdata.internal.util.isAllFlag;

narginchk(2, 8);

FCN_NAME = upper(func2str(fcn));

tall.checkNotTall(FCN_NAME, 2, varargin{:});

% Perform a basic in-memory syntax check. We can't do this for the
% two-input categorical case because the correctness depends on the
% (potentially unknown) categories.
outProto = []; % leave empty for categorical cases - it won't be used anyway!
if nargin>2
    if ~iIsTallCategorical(arg1) && ~iIsTallCategorical(arg2)
        outProto = tall.validateSyntax(fcn, [{arg1, arg2} varargin], ...
            'DefaultType', 'double', 'NumOutputs', nargout);
    end
else
    if ~iIsTallCategorical(arg1)
        outProto = tall.validateSyntax(fcn, {arg1}, ...
            'DefaultType', 'double', 'NumOutputs', nargout);
    end
end

ALLOWED_TYPES = {'numeric', 'logical', 'categorical', 'duration', 'datetime', 'char'};
% We can check 'arg1' right now - we can't check arg2 until we've worked out
% whether it is intended to be data or not.
allowTabularMaths = true;
arg1 = tall.validateType(arg1, FCN_NAME, ALLOWED_TYPES, 1, allowTabularMaths);

% Was index output requested?
wantI = nargout>1;

% Parse "ComparisonMethod" name-value pair and error if needed. This
% name-value pair is not supported for datetime, duration or categoricals.
% These are strong types and we always know their class upfront.
% tall.validateSyntax has already captured duration and datetime inputs,
% now we need to check for categoricals (tall and in-memory inputs).
isArg1NotCategorical = tall.getClass(arg1) ~= "categorical";
isArg2NotCategorical = true;
if nargin>2
    isArg2NotCategorical = tall.getClass(arg2) ~= "categorical";
end
compMethodCell = {};
numInputs = nargin;
ii = 1;
while ~isempty(varargin) && ii < numel(varargin)
    if matlab.internal.math.checkInputName(varargin{ii}, {'ComparisonMethod'})
        if isArg1NotCategorical && isArg2NotCategorical
            % Extract comparison method. No parsing is required,
            % tall.validateSyntax has already done it for us.
            compMethodCell = [{'ComparisonMethod'}, varargin(ii+1)];
            % Remove the name-value pair from varargin to later interpret
            % all the remaining flags.
            varargin(ii:ii+1) = [];
            numInputs = numInputs - 2;
        else
            error(message(sprintf('MATLAB:%s:InvalidAbsRealType', lower(FCN_NAME))));
        end
    else
        ii = ii + 1;
    end
end

% If we have a second argument, it might be: a tall data argument; a small data
% argument; [] to indicate we're in reduction mode (provided a dimension is
% specified); or (erroneously) a flag.
if numInputs > 2
    if numInputs >= 4 && (~isScalarText(varargin{1}) || isAllFlag(varargin{1}))
        dim = varargin{1};
        flags = varargin(2:end);
        operation = 'ReduceInDim';
        if ~iIsSmallEmpty(arg2) % Must be [] or some kind of empty
            error(message(sprintf('MATLAB:%s:caseNotSupported', lower(FCN_NAME))));
        end
        if ~matlab.bigdata.internal.util.isValidReductionDimension(dim)
            % Datetime has its own special error message
            if strcmp(arg1.Adaptor.Class, "datetime")
                error(message('MATLAB:datetime:InvalidDim'));
            else
                error(message('MATLAB:getdimarg:invalidDim'));
            end
        end
        % DIM is allowed to be a column or row vector. We want a row vector.
        if iscolumn(dim)
            dim = dim';
        end
    elseif iIsSmall0x0Empty(arg2) && (numInputs > 3 || ~isempty(compMethodCell))
        % If the third input was a dimension it would be captured above.
        % The second input is guaranteed to be a small [] and we have more
        % extra arguments [] is simply a placeholder and we have to reduce
        % in the default dimension.
        operation = 'ReduceInDefaultDim';
        flags = varargin;
    elseif iIsSmallEmpty(arg2)
        % If the third input was a dimension it would be captured above.
        % The second input is some kind of empty input. It's likely that
        % arg1 is also a tall empty of the same shape (edge case), or we
        % only have 2 inputs with the second being []. Since no dim has
        % been specified, here we have to do a comparison.
        operation = 'Comparison';
        flags = varargin;
    else
        % Treat as comparison
        operation = 'Comparison';
        flags = varargin;
    end
else
    % Must be reduction in default dimension. No flags permitted.
    operation = 'ReduceInDefaultDim';
    flags = {};
end

% Can we convert ReduceInDefaultDim to ReduceInDim by observing the size?
if strcmp(operation, 'ReduceInDefaultDim')
    deducedDim = matlab.bigdata.internal.util.deduceReductionDimension(arg1.Adaptor);
    if ~isempty(deducedDim)
        dim = deducedDim;
        operation = 'ReduceInDim';
    end
end

% Derive the output adaptor - need this to interpret reduction flags
switch operation
    case 'Comparison'
        % Take the opportunity to validate arg2 now that we know it is data.
        arg2       = tall.validateType(arg2, FCN_NAME, ALLOWED_TYPES, 2, allowTabularMaths);
        outYAdaptor = iDeriveComparisonAdaptor(arg1, arg2, outProto);
    case 'ReduceInDim'
        outYAdaptor = iDeriveReduceInDimAdaptor(arg1, dim, outProto);
    case 'ReduceInDefaultDim'
        outYAdaptor = iDeriveReduceInDefaultDimAdaptor(arg1);
end

[nanFlagCell, precisionFlagCell] = interpretReductionFlags(outYAdaptor, FCN_NAME, flags);

if wantI && istabular(arg1) && operation ~= "Comparison"
    % Limitation: index output for tabular inputs not supported for
    % reductions. In-memory min/max does not support it for comparison.
    error(message("MATLAB:bigdata:array:TabularMinMaxIndexUnsupported", "tall"));
elseif wantI
    % Also check for 'linear' flag
    linearI = any(cellfun(@(x) iIsFlag(x, "linear"), flags));
    % Return linear indices if dim=="all" (dim exists only if "ReduceInDim")
    if ~linearI && strcmp(operation, "ReduceInDim")
        linearI = iIsFlag(dim, "all");
    end
    
    % Index output is always double and same size as value output
    outIAdaptor = matlab.bigdata.internal.adaptors.getAdaptorForType('double');
    outIAdaptor = copySizeInformation(outIAdaptor, outYAdaptor);
else
    linearI = false;
    outIAdaptor = [];
end

% Note that by this point we know that in the reduction cases the first
% input is tall since the second must be a non-tall empty.
assert(ismember(operation, {'Comparison','ReduceInDim','ReduceInDefaultDim'}), ...
    'Unexpected reduction case.');
switch operation
    case 'Comparison'
        % Take care over time types with local char inputs since we need to
        % treat char vectors as a single element when comparing.
        if ismember(outYAdaptor.Class, ["categorical", "duration", "datetime"])
            if ischar(arg1)
                arg1 = string(arg1);
            end
            if ischar(arg2)
                arg2 = string(arg2);
            end
        end
        
        % Validate as well the 'linear' flag with categorical inputs since
        % this hasn't been validated with validateSyntax above. 'linear' is
        % not allowed when comparing two inputs.
        if (~isArg1NotCategorical || ~isArg2NotCategorical) ...
                && any(cellfun(@(x) iIsFlag(x, "linear"), flags))
            error(message(sprintf('MATLAB:%s:linearNotSupported', lower(FCN_NAME))));
        end

        % Perform the elementwise comparison (we know that one of arg1 or arg2
        % is tall since no other argument is allowed to be).
        outY = iTallComparison(fcn, arg1, arg2, nanFlagCell, precisionFlagCell, compMethodCell);
        % Preserve the size information produced by elementfun
        outY.Adaptor = copySizeInformation(outYAdaptor, outY.Adaptor);
        
    case 'ReduceInDim'
        if isReducingTallDimension(dim)
            % Try to use metadata if present (which doesn't support precision)
            if isempty(precisionFlagCell) && ~wantI && isempty(compMethodCell)
                if isequal(fcn, @min)
                    fcnPiece = 'Min1';
                else
                    fcnPiece = 'Max1';
                end
                if isempty(nanFlagCell) || strcmpi('omitnan', nanFlagCell{1})
                    nanPiece = 'OmitNaN';
                else
                    nanPiece = 'IncludeNaN';
                end
                metadataName = [fcnPiece, nanPiece];
                metadata = hGetMetadata(hGetValueImpl(arg1));
                if ~isempty(metadata)
                    [gotValue, value] = getValue(metadata, metadataName);
                    if gotValue
                        outY = tall.createGathered(value);
                        return
                    end
                end
            end
            % If we get here the metadata isn't available. Do the
            % calculation.
            if wantI
                [outY, outI] = iTallReduction(fcn, arg1, dim, nanFlagCell, precisionFlagCell, ...
                    compMethodCell, wantI, linearI);
            else
                outY = iTallReduction(fcn, arg1, dim, nanFlagCell, precisionFlagCell, ...
                    compMethodCell, wantI);
            end
        else
            if wantI
                [outY, outI] = iSlicewiseReduction(fcn, arg1, dim, nanFlagCell, precisionFlagCell, ...
                    compMethodCell, wantI, linearI);
            else
                outY = iSlicewiseReduction(fcn, arg1, dim, nanFlagCell, precisionFlagCell, ...
                    compMethodCell, wantI);
            end
        end
        % computeReducedSize will already have computed the correct size information, so
        % no need to respect the size information set up by SLICEFUN.
        outY.Adaptor = outYAdaptor;
        if wantI
            outI.Adaptor = outIAdaptor;
        end
        
    case 'ReduceInDefaultDim'
        % Dimension is unknown
        if wantI
            [outY, outI] = iReduceInDefaultDim(fcn, arg1, nanFlagCell, precisionFlagCell, ...
                compMethodCell, wantI, linearI);
        else
            outY = iReduceInDefaultDim(fcn, arg1, nanFlagCell, precisionFlagCell, ...
                compMethodCell, wantI, linearI);
        end
        % computeReducedSize will already have computed the correct size information, so
        % no need to respect the size information set up by SLICEFUN.
        outY.Adaptor = outYAdaptor;
        if wantI
            outI.Adaptor = outIAdaptor;
        end
end

end

function outY = iTallComparison(fcn, x, y, nanFlagCell, precisionFlagCell, compMethodCell)
outY = elementfun(@(a,b) fcn(a, b, nanFlagCell{:}, precisionFlagCell{:}, ...
            compMethodCell{:}), x, y);
end

function [outY, outI] = iTallReduction(fcn, arg1, dim, nanFlagCell, precisionFlagCell, ...
    compMethodCell, wantI, linearI)
if wantI
    % Value and index. In this case the per-block function and
    % the function to combine block results are different.
    flags = [nanFlagCell, precisionFlagCell];
    absoluteIndices = getAbsoluteSliceIndices(arg1);
    sizeX = size(arg1);
    blockFcn = @(X,idx,szX) iPerBlockFcn(fcn, X, idx, szX, dim, flags, compMethodCell, linearI);
    mergeFcn = @(Y,I) iMergeBlocksFcn(fcn, Y, I, flags, compMethodCell, linearI);
    [outY, outI] = aggregatefun(blockFcn, mergeFcn, ...
        arg1, absoluteIndices, matlab.bigdata.internal.broadcast(sizeX));
else
    % Value only
    outY = reducefun(@(x) fcn(x, [], dim, nanFlagCell{:}, precisionFlagCell{:}, ...
        compMethodCell{:}), arg1);
end
end

function [outY, outI] = iSlicewiseReduction(fcn, arg1, dim, nanFlagCell, precisionFlagCell, ...
    compMethodCell, wantI, linearI)
% Reduce only in small dims
if wantI
    % Value and index
    if linearI
        % For linear indices we will need the size to convert local to global.
        absoluteIndices = getAbsoluteSliceIndices(arg1);
        sizeX = size(arg1);
        blockFcn = @(X,idx,szX) iPerBlockFcn(fcn, X, idx, szX, dim, [nanFlagCell, precisionFlagCell], ...
            compMethodCell, linearI);
        [outY, outI] = slicefun(blockFcn, ...
            arg1, absoluteIndices, matlab.bigdata.internal.broadcast(sizeX));
    else
        [outY, outI] = slicefun(@(x) fcn(x, [], dim, nanFlagCell{:}, precisionFlagCell{:}, ...
            compMethodCell{:}), arg1);
    end
else
    % Value only
    outY = slicefun(@(x) fcn(x, [], dim, nanFlagCell{:}, precisionFlagCell{:}, ...
        compMethodCell{:}), arg1);
end
end

function [outY, outI] = iReduceInDefaultDim(fcn, arg1, nanFlagCell, precisionFlagCell, ...
    compMethodCell, wantI, linearI)
% Reduce in the default dimension.
if wantI
    % Value and index. In this case the per-block function and
    % the function to combine block results are different.
    flags = [nanFlagCell, precisionFlagCell];
    absoluteIndices = getAbsoluteSliceIndices(arg1);
    sizeX = size(arg1);
    blockFcn = @(X,idx,szX) iPerBlockUnknownDimFcn(fcn, X, idx, szX, flags, compMethodCell, linearI);
    mergeFcn = @(Y,I) iMergeBlocksFcn(fcn, Y, I, flags, compMethodCell, linearI);
    [outY, outI] = aggregatefun(blockFcn, mergeFcn, ...
        arg1, absoluteIndices, matlab.bigdata.internal.broadcast(sizeX));
else
    % One output.
    outPA = reduceInDefaultDim(@(x, dim) fcn(x, [], dim, ...
        nanFlagCell{:}, precisionFlagCell{:}, compMethodCell{:}), arg1);
    outY = tall(outPA, resetSizeInformation(arg1.Adaptor));
end

end

function [Y,I] = iPerBlockUnknownDimFcn(fcn, X, rowIdx, szX, flags, compNVPair, linearI)
% Reduce a block in the first non-singleton dimension of szX.
dim = find(szX~=1, 1, 'first');
if isempty(dim)
    dim = 1;
end
[Y,I] = iPerBlockFcn(fcn, X, rowIdx, szX, dim, flags, compNVPair, linearI);
end

function [Y,I] = iPerBlockFcn(fcn, X, rowIdx, szX, dim, flags, compNVPair, linearI)
% Reduce a block in the specified dimension, correcting local indices or
% subscripts to be global.

if linearI
    % Convert linear indices into local part into global indices using
    % subscripts.
    [Y,I] = fcn(X, [], dim, flags{:}, "linear", compNVPair{:});
    localSubs = cell(1,ndims(X));
    [localSubs{:}] = ind2sub(size(X), I);
    % Adjust the tall subscript
    localSubs{1} = reshape(rowIdx(localSubs{1}), size(localSubs{1}));
    % Convert back to linear using global size
    I = sub2ind(szX, localSubs{:});
else
    % Single dimension
    [Y,I] = fcn(X, [], dim, flags{:}, compNVPair{:});
    % If reducing tall dimension, convert to global indices.
    if dim==1
        I = rowIdx(I);
    end
end
% Make sure I and Y have the same size.
I = reshape(I, size(Y));
end

function [Y,I] = iMergeBlocksFcn(fcn, Y, I, flags, compNVPair, linearI)
% Merge results from two block that have been vertically concatenated.

% The input will have been concatenated vertically in correct order.
% However, to resolve ties with linear indices we need to sort into linear
% index order.
if linearI && ~isempty(I) && size(I,1)>1
    [I,idx] = sort(I, 1);
    Y = iApplySortResult(Y, idx);
end
[Y,idxIntoFirst] = fcn(Y, [], 1, flags{:}, "linear", compNVPair{:});
I = reshape(I(idxIntoFirst), size(Y));
end

function x = iApplySortResult(x, idx)
% As per example in sort help. Note that in this case the simple for-loop
% is faster than a vectorized version using sub2ind etc.
sz = size(x);
n = prod(sz(2:end));
for j = 1:n
    x(:,j) = x(idx(:,j),j);
end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function adaptor = iDeriveComparisonAdaptor(arg1, arg2, outProto)
% Calculate the output type for a comparison MIN/MAX.

% We must be careful to consider that arg1 and arg2 aren't necessarily both
% tall, and that char inputs are immediately cast to double.
adaptor1 = iConvertCharAdaptorsToDouble(matlab.bigdata.internal.adaptors.getAdaptor(arg1));
adaptor2 = iConvertCharAdaptorsToDouble(matlab.bigdata.internal.adaptors.getAdaptor(arg2));

if ismember(adaptor1.Class, ["table" "timetable"]) || ismember(adaptor2.Class, ["table" "timetable"])
    % If the first input or the second input is tabular, keep the adaptor
    % of the in-memory prototype. That will keep properties as defined by
    % tabular min/max.
    adaptor = resetSizeInformation(matlab.bigdata.internal.adaptors.getAdaptor(outProto));
elseif isequal(adaptor1.Class, adaptor2.Class) && ~isempty(adaptor1.Class)
    % Same - pick one, remembering that the size can be influenced by
    % singleton expansion.
    adaptor = resetSizeInformation(adaptor1);
elseif isempty(adaptor1.Class) && isempty(adaptor2.Class)
    % Both empty - default to generic.
    adaptor = matlab.bigdata.internal.adaptors.GenericAdaptor();
else
    % Got some information. In this case, we need to propagate
    % datetime/duration/calendarDuration. We preferentially pick the first
    % adaptor.
    timeClasses = {'datetime', 'duration', 'calendarDuration'};
    if ismember(adaptor1.Class, timeClasses)
        adaptor = resetSizeInformation(adaptor1);
    elseif ismember(adaptor2.Class, timeClasses)
        adaptor = resetSizeInformation(adaptor2);
    elseif strcmp(adaptor1.Class, 'categorical')
        % Handle categoricals: if either is categorical, copy that adaptor.
        adaptor = resetSizeInformation(adaptor1);
    elseif strcmp(adaptor2.Class, 'categorical')
        adaptor = resetSizeInformation(adaptor2);
    else
        % Don't know how to combine classes. This might result in a run-time error.
        adaptor = matlab.bigdata.internal.adaptors.GenericAdaptor();
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function adaptor = iDeriveReduceInDefaultDimAdaptor(arg1)
tmp = iConvertCharAdaptorsToDouble(arg1.Adaptor);
% We might one day add size information here.
adaptor = resetSizeInformation(tmp);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function adaptor = iDeriveReduceInDimAdaptor(arg1, dim, outProto)
% Reduction has modified the table variables or updated the tabular
% properties. For timetables, min and max return a table. Copy from the
% in-memory prototype.
if istabular(arg1)
    adaptor = copyTallSize(...
        matlab.bigdata.internal.adaptors.getAdaptor(outProto), ...
        arg1.Adaptor);
else
    adaptor = iConvertCharAdaptorsToDouble(arg1.Adaptor);
end
% Update both tall and small sizes in the adaptor
allowEmpty = true;
adaptor = computeReducedSize(adaptor, arg1.Adaptor, dim, allowEmpty);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% min/max on char data always returns double. All other types are preserved.
function newAdaptor = iConvertCharAdaptorsToDouble(oldAdaptor)
if strcmp(oldAdaptor.Class, 'char')
    newAdaptor = matlab.bigdata.internal.adaptors.getAdaptorForType('double');
    newAdaptor = copySizeInformation(newAdaptor, oldAdaptor);
else
    newAdaptor = oldAdaptor;
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tf = iIsSmall0x0Empty(arg)
% Check for a non-tall [] empty array
tf = ~istall(arg) && ismatrix(arg) && all(size(arg) == 0);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tf = iIsSmallEmpty(arg)
% Check for a non-tall empty array
tf = ~istall(arg) && isempty(arg);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tf = iIsTallCategorical(arg)
tf = istall(arg) && isequal(arg.Adaptor.Class, 'categorical');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tf = iIsFlag(arg, flagName)
% Returns true if partial case-insensitive match for flag, false otherwise.
tf = matlab.internal.datatypes.isScalarText(arg) ...
    && strlength(arg)>0 ...
    && startsWith(flagName, arg, "IgnoreCase", true);
end
