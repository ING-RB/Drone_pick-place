function [tx, varargout] = findgroups(varargin)
%FINDGROUPS Find groups and return group numbers
%   Supported syntaxes for tall arrays:
%   G = FINDGROUPS(A)
%   G = FINDGROUPS(A1,A2,...)
%   [G,GID1,GID2,...] = FINDGROUPS(A1,A2,...)
%
%   Limitations:
%   1) G the group number may be in different order from non-tall implementation.
%
%   See also FINDGROUPS.

%   Copyright 2016-2018 The MathWorks, Inc.

narginchk(1,inf);
nargoutchk(0, nargin+1);
hasTabularInput = false;
for k = 1:nargin
    if any(tall.getClass(varargin{k}) == ["table", "timetable"])
        hasTabularInput = true;
        if tall.getClass(varargin{k}) == "timetable"
            varargin{k} = timetable2table(varargin{k}, 'ConvertRowTimes', false);
        end
    else
        varargin{k} = tall.validateVector(varargin{k}, ...
            'MATLAB:findgroups:GroupingVarNotVector');
    end
end
[varargout{1:nargin}] = reducefun(@iFindGroupKeys, varargin{:});
for ii = 1:nargin
    adaptor = resetTallSize(matlab.bigdata.internal.adaptors.getAdaptor(varargin{ii}));
    % If input is a row vector, output can have a different width.
    if ~hasTabularInput && adaptor.getSizeInDim(2) ~= 1
        adaptor = setSmallSizes(resetSmallSizes(adaptor), nan);
    end
    varargout{ii}.Adaptor = adaptor;
end

broadcastedKeys = cellfun(@matlab.bigdata.internal.broadcast, varargout, 'UniformOutput', false);
if hasTabularInput
    % Use slicefun when output is based on tabular data, where it is
    % guaranteed column vector.
    tx = slicefun(@iMapKeyToGnum, varargin{:}, broadcastedKeys{:});
    tx.Adaptor = setSmallSizes(tx.Adaptor, 1);
else
    % Otherwise, we don't need to worry about output being a different size
    % to input.
    tx = elementfun(@iMapKeyToGnum, varargin{:}, broadcastedKeys{:});
end
tx.Adaptor = copySizeInformation(...
    matlab.bigdata.internal.adaptors.getAdaptorForType('double'), tx.Adaptor);
end

function varargout = iFindGroupKeys(varargin)
% Get the full list of keys, one key per group.
[localGnum, varargout{1:nargout}] = findgroups(varargin{:});
if isscalar(localGnum) && isnan(localGnum)
    % For scalar data, findgroups doesn't know whether keys should be a row
    % vector or a column vector. The unique key output depends on type,
    % sometimes it is 0x0, sometimes it is 1x0. We force 0x1 to as tall
    % blocking makes this more likely to be a column vector.
    for ii = 1:nargout
        if ~istable(varargout{ii}) && ~istimetable(varargout{ii})
            varargout{ii} = reshape(varargout{ii}, 0, 1);
        end
    end
end
end

function gnum = iMapKeyToGnum(varargin)
% Map the inputs to group number GNUM values using the group keys found
% earlier.
%
% This works by using findgroups on the concatenation of unique keys and
% data.
numInputs = numel(varargin) / 2;
keyInputs = varargin(numInputs + 1 : end);
varargin = varargin(1:numInputs);

for ii = 1:numInputs
    % As the data could be a row vector, we switch to that version if we
    % detect it. If both are scalar, we could use either version as the
    % output is also scalar.
    if istable(keyInputs{ii}) || (iscolumn(keyInputs{ii}) && iscolumn(varargin{ii}))
        numKeys = size(keyInputs{ii}, 1);
        varargin{ii} = [keyInputs{ii}; varargin{ii}];
    else
        numKeys = size(keyInputs{ii}, 2);
        varargin{ii} = [keyInputs{ii}, varargin{ii}];
    end
end
gnum = findgroups(varargin{:});
if isscalar(gnum) && numKeys == 1
    % For scalar data, findgroups doesn't know whether keys should be a row
    % vector or a column vector. We force 0x1 to as tall blocking makes
    % this more likely to be a column vector.
    gnum = zeros(0, 1);
else
    % Otherwise we simply discard the gnum values that correspond to
    % keyInputs. This will have the correct orientation (row vs column).
    gnum = gnum(numKeys+1:end);
end
end
