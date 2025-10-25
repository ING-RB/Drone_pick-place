function out = vertcat(varargin)
%VERTCAT Vertical concatenation
%   Vertical concatenation for tall.
%
%   Limitations:
%   1) Vertical concatenation of character arrays is not supported.
%
%   2) Concatenation of ordinal categorical arrays is not supported.
%
%   3) The output tall array returned by vertcat is based on a different
%      datastore than the input tall array. Therefore, the output returned
%      by vertcat is incompatible with the input for subsequent operations.
%      The one exception to this behavior is if the tall array is only
%      concatenated with in-memory values.
%
%      For example, if you concatenate a difference with a tall scalar to
%      preserve size and subsequently combine it with the original tall
%      array:
%
%      [tX(1); diff(tX,1,1)] + tX
%
%      This produces an error since tX and [tX(1); diff(tX,1,1)] are based
%      on different datastores. However, the command
%
%      [0; diff(tX,1,1)] + tX
%
%      executes as expected since [0; diff(tX,1,1)] only concatenates
%      in-memory values to diff(tX,1,1).

% Copyright 2015-2023 The MathWorks, Inc.

% We cannot support vertical concatenation of tall char arrays.
for ii = 1 : numel(varargin)
    clz = tall.getClass(varargin{ii});
    if clz == "char"
        error(message('MATLAB:bigdata:array:VertcatUnsupportedChar'));
    elseif clz == ""
        varargin{ii} = lazyValidate(varargin{ii}, {@(x) ~ischar(x), 'MATLAB:bigdata:array:VertcatUnsupportedChar'});
    end
end

% Need to ensure everything has the same type before continuing with either
% tall-tall or tall-broadcast.
[args, outAdaptor] = iForceSameType(varargin);

% Deal with any broadcast inputs. These will be combined into one of the
% tall inputs.
args = iDealWithBroadcastInputs(args);

% If we have more than one input left, do a genuine tall-tall vertcat
if isscalar(args)
    out = args{1};
else
    out = iTallTallVertcat(args{:});
end
out.Adaptor = outAdaptor;

% The framework will assume the output is partition dependent because the
% implementation of tall/vertcat uses partitionfun. It is not, so we must
% correct this.
if isPartitionIndependent(varargin{:})
    out = markPartitionIndependent(out);
end

end

function [args, outAdaptor] = iForceSameType(args)
% Force all input arguments to have the same type as the output.
%
% This is important as the output can sometimes depends on the order of how
% you do vertical concatenation. For example, ["1";true;1] results in
% ["1";"true";"1"] yet ["1";[true;1]] results in ["1";"1";"1"].

% We must be careful of missing objects. These cannot be passed into tall
% directly, but they take the same type as outAdaptor.
isMissingObject = cellfun(@(x) isa(x, 'missing'), args);
inAdaptors = cellfun(@(x) matlab.bigdata.internal.adaptors.getAdaptor(x), args(~isMissingObject), ...
    'UniformOutput', false);
% First try to work out the output type and size (will throw if we can detect
% inconsistent sizes)
try
    outAdaptor = matlab.bigdata.internal.adaptors.combineAdaptors(1,inAdaptors);
catch err
    % combineAdaptors can throw a variety of errors that should appear to come from
    % this method.
    throw(err);
end
if any(isMissingObject)
    % The input adaptors of the missing classes can now be filled in.
    inAdaptors(~isMissingObject) = inAdaptors;
    inAdaptors(isMissingObject) = {resetTallSize(outAdaptor)};
    % The tall size needs updating to include the height of missing objects.
    if isfinite(outAdaptor.getSizeInDim(1)) && any(isMissingObject)
        newSize = outAdaptor.getSizeInDim(1) + sum(cellfun(@(x) size(x, 1), args(isMissingObject)));
        outAdaptor = setTallSize(resetTallSize(outAdaptor), newSize);
    end
end

% As vertical concatenation supports combining different types, we need to
% ensure all partitions have the correct output type. If possible, we try
% to do this with as little extra overhead as possible.
if isNestedTypeKnown(outAdaptor)
    % The output is known up-front, either because all inputs knew their
    % type, or at least one input was of a strong type.
    outputSample = outAdaptor.buildUnknownEmpty();
else
    % Otherwise go through each input and extract type using as few as
    % passes as possible.
    isTypeKnown = cellfun(@isNestedTypeKnown, inAdaptors);
    if all(isTypeKnown)
        inputSamples = cellfun(@buildUnknownEmpty, inAdaptors, 'UniformOutput', false);
        outputSample = vertcat(inputSamples{:});
    else
        inputSamples = cell(size(args));
        for ii = 1:numel(args)
            if isNestedTypeKnown(inAdaptors{ii})
                inputSamples{ii} = matlab.bigdata.internal.broadcast(inAdaptors{ii}.buildUnknownEmpty());
            elseif ~isMissingObject(ii)
                inputSamples{ii} = head(args{ii}, 0);
            end
        end
        outputSample = clientfun(@vertcat, inputSamples{~isMissingObject});
    end
end

% Now we have a sample of the output, we force each input argument to have
% the same type as the output. This needs to branch into whether
% input/output is tall or not because different combinations require
% different primitives, even though every branch is effectively doing the
% same thing.
for ii = 1:numel(args)
    if istall(args{ii})
        % Tall input argument. If a preview is available try to trap
        % additional errors by converting that. Then just do the conversion
        % by concatenation of each partition with the output prototype.
        [previewAvailable, previewData] = matlab.bigdata.internal.util.getPreviewIfCheap(args{ii});
        if (previewAvailable && ~istall(outputSample))
            [~] = vertcat(outputSample, previewData);
        end
        % Line up the full conversion for all partitions.
        args{ii} = slicefun(@vertcat, matlab.bigdata.internal.broadcast(outputSample), args{ii});
        args{ii}.Adaptor = resetSizeInformation(outAdaptor);
    elseif istall(outputSample)
        % Local input argument but we don't know type of output upfront
        args{ii} = clientfun(@vertcat, outputSample, matlab.bigdata.internal.broadcast(args{ii}));
        args{ii}.Adaptor = resetSizeInformation(outAdaptor);
    else
        % Local input argument but we know type of output upfront
        args{ii} = [outputSample; args{ii}];
    end
end
end

function out = iTallTallVertcat(varargin)
% Vertically concatenate two or more truly tall arrays.
out = wrapUnderlyingMethod(@vertcatpartitions, {}, varargin{:});
out.Adaptor = resetTallSize(varargin{1}.Adaptor);
end

function args = iDealWithBroadcastInputs(args)
% Helper to combine broadcast data into the tall inputs. The result will be
% one or more tall arrays that need full tall-to-tall concatenation.
isArgToMerge = cellfun(@matlab.bigdata.internal.util.isBroadcast, args);
% If everything is already a broadcast (E.G. everything is the output of a
% reduction), then merge everything into the first tall array.
if all(isArgToMerge)
    firstTallIdx = find(cellfun(@istall, args), 1, 'first');
    isArgToMerge(firstTallIdx) = false;
end

% Loop, combining one broadcast input with its neighbor until the only
% arguments left are tall arrays.
while any(isArgToMerge)
    idx = find(isArgToMerge, 1, 'first');
    if idx<numel(args)
        % Combine with next input
        if isArgToMerge(idx+1)
            % Combine two local inputs
            args{idx+1} = vertcat(args{idx}, args{idx+1});
        else
            args{idx+1} = iCombineTallWithBroadcast(@iPrepend, args{idx+1}, args{idx});
        end
    else
        % Combine with previous input (we know this must be present and
        % must be tall).
        args{idx-1} = iCombineTallWithBroadcast(@iAppend, args{idx-1}, args{idx});
    end
    % Update the arg list
    args(idx) = [];
    isArgToMerge(idx) = [];
end
end

function out = iCombineTallWithBroadcast(mergeFcn, tallData, broadcastData)
% Merge a local input into a tall input
opts = matlab.bigdata.internal.PartitionedArrayOptions;
opts.PassTaggedInputs = true;
out = partitionfun(opts, mergeFcn, tallData, matlab.bigdata.internal.broadcast(broadcastData));
out.Adaptor = resetTallSize(tallData.Adaptor);
end

function [hasFinished, tallData] = iPrepend(info, tallData, localData)
% Prepend localData to the first chunk of the first partition. There's
% probably a much better way to do this, but...

% Check for TaggedArrays: localData is a BroadcastArray.
if isa(localData, 'matlab.bigdata.internal.BroadcastArray')
    localData = getUnderlying(localData);
end

% Only prepend the data to the first chunk in the first partition.
isFirstChunk = info.RelativeIndexInPartition==1 && (size(tallData, 1) > 0 || info.IsLastChunk);
if isFirstChunk && (info.PartitionId==1)
    % If tallData is UnknownEmptyArray, it will be filtered in vertcat.
    tallData = vertcat(localData, tallData);
end
hasFinished = info.IsLastChunk;
end

function [hasFinished, tallData] = iAppend(info, tallData, localData)
% Append localData to the last chunk of the last partition. There's
% probably a much better way to do this, but...

% Check for TaggedArrays: localData is a BroadcastArray.
if isa(localData, 'matlab.bigdata.internal.BroadcastArray')
    localData = getUnderlying(localData);
end

% Only append the data to the last chunk in the last partition.
if (info.IsLastChunk) && (info.PartitionId==info.NumPartitions)
    % If tallData is UnknownEmptyArray, it will be filtered in vertcat.
    tallData = vertcat(tallData, localData);
end
hasFinished = info.IsLastChunk;
end
