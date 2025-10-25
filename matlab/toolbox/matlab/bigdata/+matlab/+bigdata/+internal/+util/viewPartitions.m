function varargout = viewPartitions(varargin)
%viewPartitions Display tall array data partitioning
%
% Syntax:
%   matlab.bigdata.internal.util.viewPartitions(TX)
%   displays the partitioning of tall array TX as using a bar chart.  By
%   default this will display the size in the tall dimension for each chunk
%   of TX.
%
%   matlab.bigdata.internal.util.viewPartitions(TX,UNITS)
%   displays the partitioning using the supplied UNITS option which can be:
%   'slices' (default), 'bytes', 'KB', 'MB', or 'GB'.
%
%   matlab.bigdata.internal.util.viewPartitions(AX,...)
%   plots into the axes specified by AX instead of the current axes (gca).
%
%   B = matlab.bigdata.internal.util.viewPartitions(...)
%   returns the one or more Bar graph objects used to display partitioning.
%
%   [B,P] = matlab.bigdata.internal.util.viewPartitions(...)
%   returns the partitioning P as a numPartitions x maxNumChunks matrix,
%   where maxNumChunks is determined by the partition with the largest
%   number of chunks of data.  The matrix element P(II,JJ) contains the
%   measurement value for the JJth chunk of the IIth partition in the
%   requested units.  NaN is used as the padding value for any
%   partitions that have fewer chunks than maxNumChunks.

% Copyright 2017-2019 The MathWorks, Inc.

narginchk(1,3);
nargoutchk(0,2);

[cax,args,numargs] = axescheck(varargin{:});
assert(numargs <= 2, message('MATLAB:narginchk:tooManyInputs'));

if numargs < 2
    tX = args{1};
    units = "slices";
elseif numargs == 2
    [tX, units] = deal(args{:});
end

assert(istall(tX), ...
    message('MATLAB:bigdata:array:ArgMustBeTall', 1, upper(mfilename)));


unitsOpts = ["slices", "bytes", "KB", "MB", "GB"];
units = validatestring(units, unitsOpts, mfilename, "units");

infoFcn = iBuildInfoFcn(units);

paX = hGetValueImpl(tX);
[partitionIds, chunkInfo] = partitionfun(@(varargin) iGetChunkInfo(infoFcn, varargin{:}), paX);
[partitionIds, chunkInfo, maxNumChunks] = clientfun(@iPostProc, partitionIds, chunkInfo);
[partitionIds, chunkInfo, maxNumChunks] = gather(partitionIds, chunkInfo, maxNumChunks);

if isscalar(partitionIds)
    % Single-partition data needs massaging to keep the bar chart stacked
    partitionIds = [NaN partitionIds];
    chunkInfo = [NaN(size(chunkInfo)); chunkInfo];
end

total = sum(chunkInfo(:), 'omitnan');

cax = newplot(cax);
ba = bar(cax, partitionIds, chunkInfo, 'stacked');
xlabel('Partition Index');
ylabel(sprintf('Size (%s)', units));
legend(compose("Chunk %d", 1:maxNumChunks), 'Location','bestoutside');
title(sprintf("Total %s %s", num2str(total), units));

if nargout > 0
    P = chunkInfo(~ismissing(partitionIds), :); %undo single-partition hack
    varargout = {ba, P};
end
end

function infoFcn = iBuildInfoFcn(units)
switch units
    case "bytes"
        infoFcn = @(x) getfield(whos('x'), 'bytes');
    case "KB"
        infoFcn = @(x) getfield(whos('x'), 'bytes') / 1024;
    case "MB"
        infoFcn = @(x) getfield(whos('x'), 'bytes') / 1024^2;
    case "GB"
        infoFcn = @(x) getfield(whos('x'), 'bytes') / 1024^3;
    otherwise % slices
        infoFcn = @(x) size(x,1);
end
end

function [hasFinished, partitionIds, out] = iGetChunkInfo(fcn, info, x)
hasFinished = info.IsLastChunk;
partitionIds = [info.PartitionId, info.NumPartitions];
out = fcn(x);
end

function [P, C, maxNumChunks] = iPostProc(partitionIds, chunkInfo)
% partitionIds = [partitionId, numPartitions]
numPartitions = partitionIds(1, 2);
P = 1:numPartitions;
[~, maxNumChunks] = mode(partitionIds(:, 1));
C = NaN(numPartitions, maxNumChunks);

for ii = 1:numel(P)
    f = partitionIds(:, 1) == P(ii);
    C(ii, 1:sum(f)) = chunkInfo(f)';
end
end
