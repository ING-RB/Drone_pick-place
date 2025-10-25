classdef (Hidden) PostFailureCallbackProvider < handle
    %

    % Copyright 2021-2023 The MathWorks, Inc.

    properties (Transient, NonCopyable, Access=private)
        PostFailureEventCallbacks = {};
    end

    methods (Hidden, Sealed)
        function addPostFailureEventCallback_(provider, fcn)
            provider.PostFailureEventCallbacks{end+1} = fcn;
        end
    end

    methods (Hidden, Sealed, Access={?matlab.unittest.TestRunner, ?matlab.unittest.internal.qualifications.QualificationDelegate})
        function invokePostFailureEventCallbacks_(provider, info)
            cellfun(@(fcn)fcn(info), provider.PostFailureEventCallbacks);
        end
    end
end

