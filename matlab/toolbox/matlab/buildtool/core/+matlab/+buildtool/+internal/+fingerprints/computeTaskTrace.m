function trace = computeTaskTrace(task, taskArguments, options)
% This function is unsupported and might change or be removed without 
% notice in a future version.

% Copyright 2022-2024 The MathWorks, Inc.

arguments
    task (1,1) matlab.buildtool.Task
    taskArguments (1,:) cell
    options.Fingerprinters (1,:) matlab.buildtool.fingerprints.Fingerprinter = matlab.buildtool.fingerprints.Fingerprinter.default()
    options.FingerprintContext (1,1) matlab.buildtool.fingerprints.FingerprintContext = matlab.buildtool.fingerprints.FingerprintContext()
end

import matlab.buildtool.internal.fingerprints.TaskTrace;

inputs = task.inputList();
classInputs = inputs([inputs.Dynamic]==false);
dynamicInputs = inputs([inputs.Dynamic]==true);

outputs = task.outputList();
classOutputs = outputs([outputs.Dynamic]==false);
dynamicOutputs = outputs([outputs.Dynamic]==true);

printers = options.Fingerprinters;
context = options.FingerprintContext;

actionsPrint = printers.fingerprint(task.Actions, context);
argumentsPrint = printers.fingerprint(taskArguments, context);

classInputPrints = fingerprintsDictionary(classInputs, printers, context);
dynamicInputPrints = fingerprintsDictionary(dynamicInputs, printers, context);
classOutputPrints = fingerprintsDictionary(classOutputs, printers, context);
dynamicOutputPrints = fingerprintsDictionary(dynamicOutputs, printers, context);

trace = TaskTrace( ...
    ActionsFingerprint=actionsPrint, ...
    ClassInputFingerprints=classInputPrints, ...
    DynamicInputFingerprints=dynamicInputPrints, ...
    ClassOutputFingerprints=classOutputPrints, ...
    DynamicOutputFingerprints=dynamicOutputPrints, ...
    ArgumentsFingerprint=argumentsPrint);
end

function prints = fingerprintsDictionary(list, fingerprinters, context)
import matlab.buildtool.fingerprints.Fingerprint;

prints = dictionary(string.empty(), Fingerprint.empty());
for io = list
    prints(io.Name) = fingerprinters.fingerprint(io.Value, context);
end
end