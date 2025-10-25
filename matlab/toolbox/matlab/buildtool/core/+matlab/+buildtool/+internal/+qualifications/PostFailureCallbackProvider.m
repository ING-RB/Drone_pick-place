classdef (Hidden) PostFailureCallbackProvider < handle
    %

    % Copyright 2023 The MathWorks, Inc.

    properties (Transient, NonCopyable, Access = private)
        PostFailureEventCallbacks = {};
    end

    methods (Hidden, Sealed)
        function addPostFailureEventCallback(provider, fcn)
            provider.PostFailureEventCallbacks{end+1} = fcn;
        end
    end

    methods (Hidden, Sealed, Access={?matlab.buildtool.BuildRunner, ?matlab.buildtool.internal.qualifications.QualificationDelegate})
        function invokePostFailureEventCallbacks(provider, info)
            cellfun(@(fcn)fcn(info), provider.PostFailureEventCallbacks);
        end
    end
end