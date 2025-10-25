function names = accessNamesForProperty(tpdDataSource,upLevelParameters,outputPropName)
%

%  Copyright 2020 The MathWorks, Inc
tpdDataSource.updateCache;
filteredParams = tpdDataSource.getFilteredParameterDependencies(upLevelParameters);
names = tpdDataSource.ParameterCache.accessNamesForProperty(outputPropName,filteredParams);
end

