% Copyright 2021 The MathWorks, Inc.

function onSaveSession()
    % Exit command to test normal session end
    % Feval('require("MOTW/motw/MotwApp").wraService.onInactivityTimeout()') to
    % test terminate at timeout

    logger = simulink.online.internal.events.getEventsLogger();
    % TODO: need localization?
    logger.info('Simulink online on save session at session end');

    % TODO: should we turn warning off as MatlabSession does?
    import simulink.online.internal.events.SessionEmitter;
    emitterInst = SessionEmitter.getInstance();
    notify(emitterInst, 'saveSession');
end  % onSaveSession
