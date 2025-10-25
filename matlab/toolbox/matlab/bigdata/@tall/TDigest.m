function tDigest = TDigest(tx, varargin)
% Function to create a TDigest object from a partitioned tall array
%   TX      - tall array of doubles
%   delta   - optional compression parameter, pass [] to use default
%   rstream - optional RandStream object for reproducibility
%             NOTE: as of now, RandStream inputs for this tall method are
%             not fully functional or fully tested

% Copyright 2016-2022 The MathWorks, Inc.

par = inputParser;
par.addRequired('tx');
par.addOptional('delta',[],@(x)isempty(x)|| (isscalar(x)&&isnumeric(x)));
par.addOptional('randstream',RandStream('mrg32k3a'));

par.parse(tx,varargin{:});

tx = par.Results.tx;
delta = par.Results.delta;
rs = par.Results.randstream;

tDigest = aggregatefun(callOptsFromRandStream(rs),...
                            @(x)mapTDigest(x,delta),@reduceTDigests,tx);
end

function tDigestArray = mapTDigest(x, delta)
tDigestArray = matlab.internal.math.TDigestArray(x,delta);
end

function tDigest = reduceTDigests(tDigestArray)
tDigest = matlab.internal.math.mergeTDigestArray(tDigestArray);
end

function opts = callOptsFromRandStream(rs)
% Helper to setup appropriate call options for a tall internal API call
% that needs random numbers.
%
% opts = callOptsFromRandStream() or opts = callOptsFromRandStream([])
% returns a default PartitionedArrayOptions options structure.
%
% opts = callOptsFromRandStream(rs) returns a call options structure with a
% RandStream factory based on the supplied RandStream RS (which must
% support streams and substreams).
%
% Example (from datasample):
% [S,nS,chunkSizes] = partitionfun( internal.stats.bigdata.callOptsFromRandstream(rs), ...
%    @(info,x) constantRandSampleFun(info,x,k), data);
%
% See also: matlab.bigdata.internal.PartitionedArrayOptions.

if nargin<1 || isempty(rs)
    opts = matlab.bigdata.internal.PartitionedArrayOptions('RequiresRandState', true);
else
    % Custom RandStream
    opts = matlab.bigdata.internal.PartitionedArrayOptions('RequiresRandState', true);
    opts.RandStreamFactory = matlab.bigdata.internal.RandStreamFactory(rs);
end
end
