function values = accessValuesForProperty(tpdDataSource,upLevelParameters,outputPropName)
%

%  Copyright 2020 The MathWorks, Inc
tpdDataSource.updateCache;
filteredParams = tpdDataSource.getFilteredParameterDependencies(upLevelParameters);
values = tpdDataSource.ParameterCache.accessValuesForProperty(outputPropName,filteredParams);
end

