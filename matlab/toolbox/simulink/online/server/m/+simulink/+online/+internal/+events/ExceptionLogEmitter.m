% Copyright 2021 The MathWorks, Inc.
% Wrap callbacks with logExceptionForCallbacks to
% always log exceptions to (splunk) logger

classdef ExceptionLogEmitter < handle
    properties (Constant)
        % Event strings
    end

    methods (Access = public)
        function obj = ExceptionLogEmitter(logger)
            % assert(~isempty(logger))
            obj.m_exceptionLogger = logger;
        end  % ExceptionLogEmitter

        function hListener = connect(this, eventString, callback, varargin)
            % assert(~isempty(eventString))
            % assert(~isempty(callback))

            import simulink.online.internal.log.Utils;
            hListener = addlistener(...
                this, ...
                eventString, ...
                @(src, evtData)Utils.logExceptionForCallback( ...
                    callback, this.m_exceptionLogger, src, evtData, varargin{:} ...
                )...
            );
        end  % connect
    end

    methods (Access = protected)
    end

    properties (Access = protected)
        m_exceptionLogger;
    end

    events
        % ListenAccess = protected
    end
end
