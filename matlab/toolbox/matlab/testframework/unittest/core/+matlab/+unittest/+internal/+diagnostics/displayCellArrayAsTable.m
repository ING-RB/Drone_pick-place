function displayCellArrayAsTable(encodedCell, variableNames)
%

% Copyright 2014-2021 The MathWorks, Inc.

import matlab.unittest.internal.diagnostics.TableDiagnostic;

tags = cellfun(@char, encodedCell, UniformOutput=false);
t = cell2table(tags, VariableNames=variableNames);
diag = TableDiagnostic(t);
diag.diagnose;
disp(diag.DiagnosticText);
end
