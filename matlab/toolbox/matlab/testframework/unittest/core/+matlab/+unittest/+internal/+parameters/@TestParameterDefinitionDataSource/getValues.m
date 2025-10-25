function values = getValues(tpdDataSource, outputPropName, upLevelParameters) 
%

% Copyright 2020 The MathWorks, Inc.

values = tpdDataSource.accessValuesForProperty(upLevelParameters,outputPropName);
end

