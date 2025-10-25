function validateParallelBigdata(ds, supportedMixins, envName)
%validateParallelBigdata Validate that the given datastore supports
% parallel tall/mapreduce.

%   Copyright 2018 The MathWorks, Inc.

% Return early if the datastore supports a form of parallelism allowed by
% the given parallel environment.
envSupportsHadoopLocationBased = any(supportedMixins == "HadoopLocationBased");
if envSupportsHadoopLocationBased && matlab.io.datastore.internal.shim.isHadoopLocationBased(ds)
    return;
end
envSupportsPartitionable = any(supportedMixins == "Partitionable");
if envSupportsPartitionable && matlab.io.datastore.internal.shim.isPartitionable(ds)
    return;
end

% Unwrap layers of datastore to get to the root of the issue.
if isa(ds, 'matlab.io.datastore.internal.FrameworkDatastore')
    ds = ds.Datastore;
end
if isa(ds, 'matlab.io.datastore.TransformedDatastore')
    ds = ds.UnderlyingDatastore;
end

% Provide a special error for CombinedDatastore an instance might be
% derived from other datastores that might themselves support parallel.
if isa(ds, 'matlab.io.datastore.CombinedDatastore')
    error(message('MATLAB:datastoreio:combineddatastore:parallelUnsupported', envName));
end

datastoreFullName = class(ds);
datastoreSimpleName = strsplit(datastoreFullName, '.');
datastoreSimpleName = datastoreSimpleName{end};

% Any other MathWorks shipped datastore defaults to the unsupported error.
if startsWith(which(datastoreFullName), toolboxdir(''))
    error(message('MATLAB:datastoreio:datastore:parallelUnsupported', ...
        datastoreSimpleName, envName));
end

% Finally, for any user authored datastore, we want to point towards the
% documentation in-case they are willing to add the support necessary.
if matlab.internal.display.isHot()
    linkPre = "<a href=""matlab:helpview('matlab','develop_custom_datastore')"">";
    linkPost = "</a>";
else
    linkPre = '';
    linkPost = '';
end
if ~envSupportsPartitionable
    error(message('MATLAB:datastoreio:datastore:requiresHadoopLocationBased', ...
        datastoreSimpleName, envName, linkPre, linkPost));
elseif ~envSupportsHadoopLocationBased
    error(message('MATLAB:datastoreio:datastore:requiresPartitionable', ...
        datastoreSimpleName, envName, linkPre, linkPost));
else
    error(message('MATLAB:datastoreio:datastore:requiresAnyParallel', ...
        datastoreSimpleName, envName, linkPre, linkPost));
end
