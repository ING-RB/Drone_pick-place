function names = getNames(tpdDataSource, outputPropName, upLevelParameters) 
%

%  Copyright 2020 The MathWorks, Inc
names = tpdDataSource.accessNamesForProperty(upLevelParameters,outputPropName);
end

