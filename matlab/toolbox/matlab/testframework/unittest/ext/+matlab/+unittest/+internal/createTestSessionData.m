%This function is unsupported and might change or be removed without notice
%in a future version.

% Copyright 2021-2024 The MathWorks, Inc.

function [testSessionData] = createTestSessionData(results,namedArgs)
arguments
    results matlab.unittest.TestResult
    namedArgs.DetailsLabel = "DiagnosticRecord"
end

import matlab.unittest.internal.TestSessionData;
import matlab.unittest.internal.eventrecords.EventRecord;

results = reshape(results,1,[]);
suite = [matlab.unittest.Test.empty(1,0), results.TestElement];
detailsLabel = namedArgs.DetailsLabel;

if(numel(suite) ~= numel(results))
    error(message('MATLAB:unittest:TestResult:LoadedResults'));
end

eventRecordsList = cell(1,numel(results));

for i=1:numel(results)
    details=results(i).Details;
    eventArray=matlab.unittest.internal.eventrecords.EventRecord.empty(1,0);

    if (isfield(details,detailsLabel))
        eventArray = details.(detailsLabel).toEventRecord;
    end
    eventRecordsList{i}=eventArray;
end

testSessionData = TestSessionData(suite,results,'EventRecordsList',eventRecordsList);
end
