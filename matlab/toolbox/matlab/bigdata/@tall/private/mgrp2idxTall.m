function tx = mgrp2idxTall(inclNan,varargin)
% MGRP2IDXTall Convert multiple grouping variables to index vector
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2019-2022 The MathWorks, Inc.
tmpgroups = cell(1,numel(varargin));
if inclNan
    [tmpgroups{1:nargin-1}] = reducefun(@iFindGroupKeysWMiss, varargin{:});
else
    [tmpgroups{1:nargin-1}] = reducefun(@iFindGroupKeys, varargin{:});
end
for ii = 1:nargin-1
    tmpgroups{ii}.Adaptor = resetTallSize(matlab.bigdata.internal.adaptors.getAdaptor(varargin{ii}));
end

broadcastedKeys = cellfun(@matlab.bigdata.internal.broadcast, tmpgroups, 'UniformOutput', false);

% Otherwise, we don't need to worry about output being a different size to input.
if inclNan
    tx = elementfun(@iMapKeyToGnumWMiss, varargin{:}, broadcastedKeys{:});
else
    tx = elementfun(@iMapKeyToGnum, varargin{:}, broadcastedKeys{:});
end
tx.Adaptor = copySizeInformation(matlab.bigdata.internal.adaptors.getAdaptorForType('double'), tx.Adaptor);

%--------------------------------------------------------------------------
function varargout = iFindGroupKeysWMiss(varargin)
% Get the full list of keys, one key per group.
[~,~,~,varargout] = matlab.internal.math.mgrp2idx(varargin,1,true,false,false,true);

%--------------------------------------------------------------------------
function varargout = iFindGroupKeys(varargin)
% Get the full list of keys, one key per group.
[localGnum,~,~,varargout] = matlab.internal.math.mgrp2idx(varargin,1,false,false,false,true);
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

%--------------------------------------------------------------------------
function gnum = iMapKeyToGnumWMiss(varargin)
% Map the inputs to group number GNUM values using the group keys found
% earlier.
%
% This works by using findgroups on the concatenation of unique keys and
% data.
numInputs = numel(varargin) / 2;
keyInputs = varargin(numInputs + 1 : end);
varargin = varargin(1:numInputs);

for ii = 1:numInputs
    numKeys = size(keyInputs{ii}, 1);
    varargin{ii} = [keyInputs{ii}; varargin{ii}];
end

gnum = matlab.internal.math.mgrp2idx(varargin,1,true,false);
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

%--------------------------------------------------------------------------
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
    numKeys = size(keyInputs{ii}, 1);
    varargin{ii} = [keyInputs{ii}; varargin{ii}];
end
% gnum = findgroups(varargin{:});
gnum = matlab.internal.math.mgrp2idx(varargin,1,false,false);
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
