function propToDataSourceMap = generateParameterPropertyToDataSourceMap(parmeterPropertyArray)
%

% Copyright 2020 The MathWorks, Inc.

propToDataSourceMap = containers.Map('KeyType','char','ValueType','any');

if isempty(parmeterPropertyArray)
    return;
end

dataSourceArray = [parmeterPropertyArray.ParameterData];

[sortedDataSource,sortIdx] = sort(dataSourceArray);
sortedParamProps = parmeterPropertyArray(sortIdx);

idx =1; 
while idx <= numel(sortedDataSource)    
    % Create fresh copy of the ParameterDataSource instance each time a
    % test suite is created.
    freshCopy = sortedDataSource(idx).copyForSuiteCreation;
    propToDataSourceMap(sortedParamProps(idx).Name) = freshCopy;
    dupCtr =1;
    while idx + dupCtr <= numel(sortedDataSource) && (sortedDataSource(idx) == sortedDataSource(idx+dupCtr)) 
        propToDataSourceMap(sortedParamProps(idx+dupCtr).Name) = freshCopy;
        dupCtr = dupCtr+1;
    end
    idx = idx+dupCtr;
end
end

