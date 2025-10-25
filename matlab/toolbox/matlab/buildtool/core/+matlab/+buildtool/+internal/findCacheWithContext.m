function cacheFolder = findCacheWithContext(context)
import matlab.buildtool.internal.cacheRoot;

if isfield(context.BuildOptions, "CacheFolder")
    cacheFolder = context.BuildOptions.CacheFolder;
else
    cacheFolder = cacheRoot(context.Plan.RootFolder);
end
end