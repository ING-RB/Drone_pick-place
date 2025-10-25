function defaultLogger = getEventsLogger()
    import simulink.online.internal.log.Logger;
    persistent s_EventDefaultLogger;
    if isempty(s_EventDefaultLogger)
        s_EventDefaultLogger = Logger('slonline::events');
    end
    defaultLogger = s_EventDefaultLogger;
end  % getEventsLogger
