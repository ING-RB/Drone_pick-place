function tM = cell2mat(tC)
%CELL2MAT Convert the contents of a cell array into a single matrix.
%   M = CELL2MAT(C)
%
%   See also cell2mat, tall.

% Copyright 2016-2019 The MathWorks, Inc.

tC = tall.validateType(tC, upper(mfilename), {'cell'}, 1);
% Validate that all blocks are vertically concatenable in size and they
% have the same type.
aggregateFcn = @(varargin) createEmptyPrototype(str2func(mfilename), varargin{:});
reduceFcn = @(varargin) validatePrototypeBetweenBlocks(mfilename, varargin{:});
[~, emptyProto] = aggregatefun(aggregateFcn, reduceFcn, tC);
% Call cell2mat for each block and if the input is empty, replace it by the
% empty prototype.
emptyProto = matlab.bigdata.internal.broadcast(emptyProto);
tM = chunkfun(@iCell2mat, tC, emptyProto);
end

function out = iCell2mat(c, emptyProto)
% Wrapper around cell2mat that marks the instances where we cannot be
% certain about size or type.
if size(c, 1) == 0
    % Emit emptyProto when the input cell is empty.
    out = emptyProto{:};
else
    out = cell2mat(c);
end
end