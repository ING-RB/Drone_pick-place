function tf = isHadoopWorker(override)
% isHadoopWorker returns TRUE for any MVM which is a parallel worker as
% part of a Hadoop job.

% Copyright 2024 The MathWorks, Inc.

persistent state
if isempty(state)
    state = false;
    mlock;
end

tf = state;
if nargin
    state = override;
end
end
