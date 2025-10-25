function count = getNumberOfValues(tpdDataSource,outputPropName, upLevelParameters) 
%

% Copyright 2020 The MathWorks, Inc.

values = tpdDataSource.getValues(outputPropName,upLevelParameters);
count = numel(values);
end