% Copyright 2021 The MathWorks, Inc.

classdef Logger < connector.internal.Logger
    % TODO: consider compositing connector.internal.Logger when we try to extend this class
    methods (Access = public)
        function obj = Logger(namespace)
            % TODO: varify that using a various namespace would really log into Splunk
            % as connector.internal.Logger behind the scenes is using MW_LOG(fl::log::diagnostic_logger)
            % there is a chance that Splunk is filtered by namespace
            obj = obj@connector.internal.Logger(namespace);
        end  % Logger
    end
end
