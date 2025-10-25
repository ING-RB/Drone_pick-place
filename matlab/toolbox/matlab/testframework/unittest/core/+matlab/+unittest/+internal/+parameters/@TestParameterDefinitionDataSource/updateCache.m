function  updateCache(tpdDataSource)
%

% Copyright 2020 The MathWorks, Inc.

% Create a cache if the data source object doesn't have one already
if isempty(tpdDataSource.ParameterCache)
    mcls = meta.class.fromName(tpdDataSource.TestClassName);
    tpdMethod = findobj(mcls,'Name',tpdDataSource.TestParameterDefinitionMethodName);
    methodHandle = str2func([mcls.Name '.' tpdMethod.Name]);
    tpdDataSource.ParameterCache = matlab.unittest.internal.parameters.TestParameterDefinitionCache(tpdMethod,methodHandle);
end


