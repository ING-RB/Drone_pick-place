% Copyright 2024 The MathWorks, Inc.
function diagText = generateClassIDDiagnosticText(cid)
    diag = matlab.unittest.diagnostics.ConstraintDiagnostic;
    diag.ActValHeader = getString(message('MATLAB:unittest:generateClassIDDiagnosticText:ActValHeader'));
    diag.ExpValHeader = getString(message('MATLAB:unittest:generateClassIDDiagnosticText:ExpValHeader'));
    diag.ActVal = cid.Name;
    diag.ExpVal = cid.DefiningPackage;
    diag.DisplayActVal = true;
    diag.DisplayExpVal = feature("packages");
    diag.diagnose;
    diagText = diag.DiagnosticText;
end