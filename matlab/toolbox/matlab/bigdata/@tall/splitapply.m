function varargout = splitapply(fun,varargin)
%SPLITAPPLY Split data into groups and apply function
%   Y = SPLITAPPLY(FUN,X,G)
%   Y = SPLITAPPLY(FUN,X1,X2,...,G)
%   [Y1,Y2,...] = SPLITAPPLY(FUN,...)
%
%   Limitations:
%   FUN must not rely on any state such as PERSISTENT data or random number
%   generating functions such as RAND.
%
%   See also FINDGROUPS

%   Copyright 2016-2018 The MathWorks, Inc.

narginchk(3,inf);
tall.checkNotTall(upper(mfilename), 0, fun);
if ~isa(fun, 'function_handle')
    error(message('MATLAB:splitapply:InvalidFunction'));
end

if ~all(cellfun(@istall, varargin))
    error(message('MATLAB:bigdata:array:AllArgsTall', upper(mfilename)));
end

gnum = varargin{end};
dataInputs = varargin(1 : end - 1);

gnum = tall.validateType(gnum, upper(mfilename), {'numeric'}, nargin);

% This exists so that a scalar gnum is expanded to the full length. We need
% to do this as bykey and filter do not support singleton expansion.
% Further, this converts gnum to a categorical so that grouped operations
% can use the categories to determine the known groups instead unique of
% of the each chunk.
[dataInputs{:}] = validateSameTallSize(dataInputs{:});
gnum = slicefun(@iExtractGnumAsDouble, dataInputs{:}, gnum);
gnum.Adaptor = setSmallSizes(matlab.bigdata.internal.adaptors.getAdaptorForType('double'), 1);

% This guards against the case where gnum was tall but all data input
% arguments were each a single row. We do this after expanding gnum because
% as above, scalar gnum is supported but data inputs must be full height.
[dataInputs{:}, gnum] = validateSameTallSize(dataInputs{:}, gnum);

% This is to support the syntax splitapply(fun, table(..), gnum)
dataInputs = iFlattenTableInputs(dataInputs);

[varargout{1:nargout}] = iSplitApply(fun, gnum, dataInputs{:});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% The main implementation after input argument parsing.
function varargout = iSplitApply(fun, gnum, varargin)
markerFrame = matlab.bigdata.internal.InternalStackFrame(); %#ok<NASGU>

numGroups = iCheckNumGroups(gnum);
session = matlab.bigdata.internal.splitapply.SplitapplySession(fun, hGetValueImpl(numGroups));
sessionCleanup = onCleanup(@session.close);

try
    [varargin{:}] = iWrapTallAsGroupedTall(gnum, session, varargin{:});
    [varargout{1:nargout}] = matlab.bigdata.internal.splitapply.callGroupedFunction(fun, session, varargin{:});
    for ii = 1:numel(varargout)
        % Some of the outputs might not be grouped, or even tall. We need
        % to resolve things like "{tX}" into grouped tall arrays.
        varargout{ii} = iEnsureIsGroupedTall(gnum, session, varargout{ii});
        % Tall/splitapply requires one slice of output per group.
        varargout{ii} = iValidateScalarHeight(varargout{ii});
        
        [varargout{ii}, outGnum] = iUnwrapGroupedTall(varargout{ii});
        % Tall/splitapply requires all groups 1:max(gnum) to exist in the
        % output.
        varargout{ii} = iValidateHasAllGroups(varargout{ii}, numGroups);
        % Earlier, we converted NaN gnum values into 0. To match in-memory
        % splitaplly, we must error if the NaN group errors during
        % evaluation, then remove the NaN group from the output.
        varargout{ii} = filterslices(outGnum ~= 0, varargout{ii});
    end
catch err
    matlab.bigdata.internal.util.assertNotInternal(err);
    rethrow(err);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Wrap a collection of tall arrays each as a grouped tall array.
function varargout = iWrapTallAsGroupedTall(keys, session, varargin)
import matlab.bigdata.internal.splitapply.GroupedPartitionedArray;
keys = hGetValueImpl(keys);
pv = cellfun(@hGetValueImpl, varargin, 'UniformOutput', false);
[varargout{1:nargout}] = GroupedPartitionedArray.create(keys, session, pv{:});
for ii = 1:numel(varargout)
    varargout{ii} = tall(varargout{ii});
    varargout{ii}.Adaptor = resetTallSize(varargin{ii}.Adaptor);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Unwrap a grouped tall array
function [out, keys] = iUnwrapGroupedTall(in)
gpv = hGetValueImpl(in);
gpv = sortGroups(gpv);
[keys, out] = ungroup(gpv, buildUnknownEmpty(in.Adaptor));
out = tall(out);
out.Adaptor = resetTallSize(in.Adaptor);
keys = tall(keys);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input parsing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Validate and extract the gnum input. This also ensures all non-gnum inputs
% are not singleton in the tall dimension.
function gnum = iExtractGnumAsDouble(varargin)
% All inputs have the same size as per validateSameTallSize above.
sz = size(varargin{1}, 1);

gnum = varargin{end};
gnumIsValid = isnumeric(gnum) && iscolumn(gnum) && all(isnan(gnum) | mod(gnum, 1) == 0 & gnum > 0);
% We set NaN values to hidden group gnum 0. This is so at the end we know
% whether NaN values existed in the input.
gnum(isnan(gnum)) = 0;
if ~gnumIsValid
    % Depending on the partitioning and order of execution, gnum could be invalid
    % either by being a non-scalar row, or a matrix. Here we throw a single
    % error that covers both cases to ensure a consistent error is returned.
    error(message('MATLAB:bigdata:array:SplitApplyUnsupportedGroupNums'));
end
if size(gnum, 1) == 1
    gnum = gnum .* ones(sz, 1);
end

gnum = double(gnum);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get the number of groups in gnum, ensuring the max value matches with the
% actual number of groups in the data. This will also catch instances where
% certain groups just don't exist.
function numGroups = iCheckNumGroups(gnum)
[s, e] = uniqueColonForm(gnum);
numGroups = clientfun(@iCheckNumGroupsImpl, s, e);
numGroups.Adaptor = matlab.bigdata.internal.adaptors.getScalarDoubleAdaptor();
end

function numGroups = iCheckNumGroupsImpl(s, e)
if isempty(s)
    error(message('MATLAB:splitapply:InvalidGroupNums'));
elseif ~isscalar(s) || s > 1
    error(message('MATLAB:splitapply:MissingGroupNums'));
end
numGroups = e;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Helper function that flattens all table inputs.
function flattenedInputs = iFlattenTableInputs(inputs)
flattenedInputs = cell(size(inputs));
for inputIndex = 1:numel(inputs)
    if any(strcmp(tall.getClass(inputs{inputIndex}), {'table', 'timetable'}))
        variableNames = getVariableNames(inputs{inputIndex}.Adaptor);
        flattenedInputs{inputIndex} = cell(1, numel(variableNames));
        for varIndex = 1:numel(variableNames)
            flattenedInputs{inputIndex}{varIndex} = subsref(inputs{inputIndex}, substruct('.', variableNames{varIndex}));
        end
    else
        flattenedInputs{inputIndex} = inputs(inputIndex);
    end
end
flattenedInputs = [flattenedInputs{:}];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Output parsing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Handle cases where the output of the user's function handle is not a
% grouped tall array. The output of this function is guaranteed to be a
% grouped tall array.
function data = iEnsureIsGroupedTall(gnum, session, data)
if iscell(data)
    data = iParseCellOutput(data);
end

% Anything remaining is either a local constant, or an ordinary tall array
% bound into the users function handle. Both of these need to be replicated
% across all groups.
if ~istall(data) || ~isa(hGetValueImpl(data), 'matlab.bigdata.internal.splitapply.GroupedPartitionedArray')
    data = iCreateReplicatedGroupedTall(gnum, session, data);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function data = iParseCellOutput(data)
% Parse a cell array output generated by the function handle.
if ~iscell(data)
    return;
end
data = cellfun(@iParseCellOutput, data, 'UniformOutput', false);
if any(cellfun(@istall, data))
    % If the cell array contains any tall arrays, we need to bring the tall
    % attribute up one level so that the cell array is per group.
    cellSize = size(data);
    data = matlab.bigdata.internal.util.unpackTallArguments(data);
    data = inmemoryfun(@(sz, varargin) reshape(varargin, sz), cellSize, data{:});
    data = tall(data);
    data.Adaptor = matlab.bigdata.internal.adaptors.getAdaptorForType('cell');
    data.Adaptor = setSmallSizes(data.Adaptor, cellSize(2:end));
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function values = iCreateReplicatedGroupedTall(gnum, session, value)
% Create a grouped tall array from a non-grouped array. This will replicate
% the same data for all groups. This is used in syntaxes like
% splitapply(@(~) 42, ..).
values = iWrapTallAsGroupedTall(gnum, session, gnum);

inputs = matlab.bigdata.internal.util.unpackTallArguments({values, matlab.bigdata.internal.broadcast(value)});
values = inmemoryfun(@(k, v) v, inputs{:});
values = tall(values);
values.Adaptor = resetTallSize(matlab.bigdata.internal.adaptors.getAdaptor(value));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function tOut = iValidateScalarHeight(tIn)
% Validate that each group in a grouped tall array has height exactly one.
paValues = hGetValueImpl(tIn);
% We explicitly sort upfront for efficiency purposes. This is done before
% pulling out the keys, whereas inmemoryfun can only do it after.
paValues = sortGroups(paValues);
funStr = func2str(paValues.Session.FunctionHandle);
paKeys = getKeys(paValues);
paValues = inmemoryfun(@(k, v) iValidateScalarHeightImpl(k, v, funStr), paKeys, paValues);
tOut = tall(paValues);
tOut.Adaptor = tIn.Adaptor;
end

function values = iValidateScalarHeightImpl(keys, values, funStr)
if size(values, 1) ~= 1
    % keys can have height > 1 as inmemoryfun of getKey results in 1 key
    % per block per group.
    idx = matlab.internal.datatypes.ordinalString(keys(1));
    error(message('MATLAB:bigdata:array:SplitApplyOutputNotUniform', funStr, idx));
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function tOut = iValidateHasAllGroups(tIn, numGroups)
% Validate that all groups exist. This actually just binds numGroups to the
% output, the calculation of numGroups already checks for missing groups.
tOut = elementfun(@(in, ~) in, tIn, numGroups);
tOut.Adaptor = tIn.Adaptor;
end
