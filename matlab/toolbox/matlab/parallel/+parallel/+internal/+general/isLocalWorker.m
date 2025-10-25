function tf = isLocalWorker()
% isLocalWorker returns TRUE for workers that are part of a Local cluster, FALSE otherwise.

% Copyright 2022 The MathWorks, Inc.

if ~system_dependent('isdmlworker')
    % Client
    tf = false;
else
    tf = isa(getCurrentCluster(), 'parallel.cluster.Local');
end

end

