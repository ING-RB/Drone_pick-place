classdef TaskTrace
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % TaskTrace - Record of task state

    % Copyright 2022-2024 The MathWorks, Inc.

    properties (SetAccess = immutable)
        ActionsFingerprint matlab.buildtool.fingerprints.Fingerprint {mustBeScalarOrEmpty}
        ClassInputFingerprints (1,1) dictionary = dictionary(string.empty(), matlab.buildtool.fingerprints.Fingerprint.empty())
        DynamicInputFingerprints (1,1) dictionary = dictionary(string.empty(), matlab.buildtool.fingerprints.Fingerprint.empty())
        ClassOutputFingerprints (1,1) dictionary = dictionary(string.empty(), matlab.buildtool.fingerprints.Fingerprint.empty())
        DynamicOutputFingerprints (1,1) dictionary = dictionary(string.empty(), matlab.buildtool.fingerprints.Fingerprint.empty())
        ArgumentsFingerprint matlab.buildtool.fingerprints.Fingerprint {mustBeScalarOrEmpty}
    end

    methods
        function trace = TaskTrace(options)
            arguments
                options.?matlab.buildtool.internal.fingerprints.TaskTrace
            end
            
            for prop = string(fieldnames(options))'
                value = options.(prop);
                if isa(value, "dictionary")
                    trace.(prop) = trace.(prop).insert(value.keys(), value.values());
                else
                    trace.(prop) = options.(prop);
                end
            end
        end
    end
end