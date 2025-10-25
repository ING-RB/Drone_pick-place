function isEnabled = isLocalClusterEnabled()
%  Predicate for determining if this configuration supports the use of Local Clusters for parpool / parcluster
%  Note: The Local cluster is supported unless an environment variable is set to 'false' (e.g. in MATLAB Online)

% Copyright 2019-2021 The MathWorks, Inc.

value = getenv('MATLAB_WORKER_CONFIG_ENABLE_LOCAL_PARCLUSTER');
isEnabled = ~strcmp(value, 'false');
end
