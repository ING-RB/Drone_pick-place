classdef ThrowableDispatchDecorator < matlab.uiautomation.internal.dispatchers.DispatchDecorator
    % This class is undocumented and subject to change in a future release

    % Copyright 2017-2021 The MathWorks, Inc.

    methods

        function decorator = ThrowableDispatchDecorator(dispatcher)
            decorator@matlab.uiautomation.internal.dispatchers.DispatchDecorator(dispatcher);
        end

        function dispatch(decorator, varargin)
            import matlab.ui.internal.HGCallbackErrorLogger;

            feat = feature('SuppressHGCallbackErrors',true);
            clean = onCleanup(@()feature('SuppressHGCallbackErrors', feat));

            logger = HGCallbackErrorLogger;
            logger.start;
            dispatch@ ...
                matlab.uiautomation.internal.dispatchers.DispatchDecorator(...
                decorator, varargin{:});
            logger.stop;

            if ~isempty(logger.Log)
                exception = logger.Log(1);
                % The stack showing the callback source is captured but never shown, due to
                % where the THROW actually occurs. We can push the "report" into a new envelope
                % of an exception to show richer details within the users' code.
                envelope = MException( ...
                    exception.identifier, "%s", exception.getReport);
                throw(envelope);
            end
        end

    end

end