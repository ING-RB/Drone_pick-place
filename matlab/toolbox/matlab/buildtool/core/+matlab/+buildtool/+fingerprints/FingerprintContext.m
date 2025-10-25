classdef (Hidden) FingerprintContext
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2024 The MathWorks, Inc.

    properties (SetAccess = immutable)
        RootFolder (1,1) string
    end

    methods
        function context = FingerprintContext(options)
            arguments
                options.?matlab.buildtool.fingerprints.FingerprintContext
            end
            for prop = string(fieldnames(options))'
                context.(prop) = options.(prop);
            end
        end
    end
end