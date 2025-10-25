function out = changeSetfunRowVector(c, isRowVector)
% CHANGESETFUNROWVECTOR Convert the first output of set functions back to a
% row vector if both of the inputs were row vectors.
%
% OUT = CHANGESETFUNROWVECTOR(C,ISROWVECTOR) converts C back to a row
% vector if ISROWVECTOR is true.

%   Copyright 2019 The MathWorks, Inc.

narginchk(2, 2);
nargoutchk(1, 1);

fh = matlab.bigdata.internal.util.StatefulFunction(@iChangeRowVectors);
fh = matlab.bigdata.internal.FunctionHandle(fh);
out = partitionfun(fh, c, isRowVector);
out = copyPartitionIndependence(out, c);
end

function [state, isFinished, out, isRowVector] = iChangeRowVectors(state, info, c, isRowVector)
% Transpose C if ISROWVECTOR is true. SetfunCommon guarantees that the
% result of the set operation on two row vectors is placed in the last
% partition and the rest are empty.

isFinished = info.IsLastChunk;

if ~isempty(state)
    c = [state; c];
end

state = [];
if isRowVector
    if isempty(c) && info.PartitionId ~= info.NumPartitions
        % Transpose empty chunks for vertical concatenation with final
        % chunk. Return 0 slices for empty partitions.
        out = matlab.bigdata.internal.util.indexSlices(c.', []);
        return
    end
    
    if isFinished
        out = c.';
    else
        state = c;
        out = matlab.bigdata.internal.UnknownEmptyArray.build();
    end
else
    out = c;
end
end