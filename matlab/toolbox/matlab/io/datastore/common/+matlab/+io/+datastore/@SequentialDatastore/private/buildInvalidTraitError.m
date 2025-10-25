function buildInvalidTraitError(ds, invalidMethodName, traitMethodName, traitDescription)
%
%
%

%   Copyright 2022 The MathWorks, Inc.

traitTable = ds.buildTraitTable(); %#ok<NASGU>

% Render the table display into a string.
fh = feature('hotlinks');
if fh
    traitsDisp = evalc('disp(traitTable);');
else
    % For no desktop, use hotlinks off on evalc to get rid of
    % xml attributes for display, like, <strong>Var1</strong>, etc.
    traitsDisp = evalc('feature hotlinks off; disp(traitTable);');
    feature('hotlinks', fh);
end

msgid = "MATLAB:datastoreio:combineddatastore:invalidTraitValue";
msg = message(msgid, invalidMethodName, "SequentialDatastore", traitDescription, traitsDisp, traitMethodName);
throwAsCaller(MException(msg));
end