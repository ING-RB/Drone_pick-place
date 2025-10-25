function changes = detectTaskChanges(previousTrace, currentTrace)
% This function is unsupported and might change or be removed without 
% notice in a future version.

% Copyright 2024 The MathWorks, Inc.

arguments
    previousTrace (1,1) matlab.buildtool.internal.fingerprints.TaskTrace
    currentTrace (1,1) matlab.buildtool.internal.fingerprints.TaskTrace
end

import matlab.buildtool.fingerprints.TaskChanges;

actionsChange = changeWith(previousTrace.ActionsFingerprint, currentTrace.ActionsFingerprint);
argumentsChange = changeWith(previousTrace.ArgumentsFingerprint, currentTrace.ArgumentsFingerprint);

classInputChanges = changesDictionary(previousTrace.ClassInputFingerprints, currentTrace.ClassInputFingerprints);
dynamicInputChanges = changesDictionary(previousTrace.DynamicInputFingerprints, currentTrace.DynamicInputFingerprints);
classOutputChanges = changesDictionary(previousTrace.ClassOutputFingerprints, currentTrace.ClassOutputFingerprints);
dynamicOutputChanges = changesDictionary(previousTrace.DynamicOutputFingerprints, currentTrace.DynamicOutputFingerprints);

changes = TaskChanges( ...
    ActionsChange=actionsChange, ...
    ClassInputChanges=classInputChanges, ...
    DynamicInputChanges=dynamicInputChanges, ...
    ClassOutputChanges=classOutputChanges, ...
    DynamicOutputChanges=dynamicOutputChanges, ...
    ArgumentsChange=argumentsChange);
end

function changes = changesDictionary(previousFingerprints, currentFingerprints)
import matlab.buildtool.fingerprints.Fingerprint;
import matlab.buildtool.fingerprints.FingerprintChange;

changes = dictionary(string.empty(), FingerprintChange.empty());

currentNames = currentFingerprints.keys();
previousNames = previousFingerprints.keys();

common = intersect(currentNames, previousNames);
for n = common(:)'
    changes(n) = changeWith(previousFingerprints(n), currentFingerprints(n));
end

added = setdiff(currentNames, previousNames);
for n = added(:)'
    changes(n) = changeWith(Fingerprint.empty(), currentFingerprints(n));
end

removed = setdiff(previousNames, currentNames);
for n = removed(:)'
    changes(n) = changeWith(previousFingerprints(n), Fingerprint.empty());
end
end