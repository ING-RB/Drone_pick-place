function txt = getFailureSummaryTableText(testResults)
% This function is undocumented and may change in a future release.

% Copyright 2018 The MathWorks, Inc.
import matlab.unittest.internal.diagnostics.indent;

if ~any([testResults.Failed] | [testResults.Incomplete])
    txt = '';
    return;
end

catalog = matlab.internal.Catalog('MATLAB:unittest:DiagnosticsOutputPlugin');
txt = sprintf('%s\n\n%s',...
    catalog.getString('FailureSummary'),...
    indent(getResultSummaryTable(testResults, catalog)));
end


function str = getResultSummaryTable(allResults, catalog)
% getResultSummaryTable - Return a string with information about failed and incomplete tests.
import matlab.unittest.internal.plugins.failureSummaryTable;

% Get the tests that need to be displayed in the table
failureOrIncompleteResults = allResults([allResults.Failed] | [allResults.Incomplete]);
numFailureOrIncomplete = numel(failureOrIncompleteResults);
reasons = cell(numFailureOrIncomplete, 1);
for k = 1:numFailureOrIncomplete
    result = failureOrIncompleteResults(k);
    reasonCell = {};
    if result.AssumptionFailed
        reasonCell{end+1} = catalog.getString('AssumptionFailed'); %#ok<AGROW>
    end
    if result.VerificationFailed
        reasonCell{end+1} = catalog.getString('VerificationFailed'); %#ok<AGROW>
    end
    if result.AssertionFailed
        reasonCell{end+1} = catalog.getString('AssertionFailed'); %#ok<AGROW>
    end
    if result.Errored
        reasonCell{end+1} = catalog.getString('Errored'); %#ok<AGROW>
    end
    reasons{k} = reasonCell;
end

headers = {catalog.getString('Name'), ...
    catalog.getString('Failed'), ...
    catalog.getString('Incomplete'), ...
    catalog.getString('Reasons')};

data = [{failureOrIncompleteResults.Name}.', ...
    {failureOrIncompleteResults.Failed}.', ...
    {failureOrIncompleteResults.Incomplete}.', ...
    reasons];

str = failureSummaryTable(headers, data);
str = regexprep(str,'\n+$','');
end