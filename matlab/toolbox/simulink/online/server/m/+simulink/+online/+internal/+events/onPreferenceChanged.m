% Copyright 2021 The MathWorks, Inc.

function onPreferenceChanged()
    logger = simulink.online.internal.events.getEventsLogger();
    % TODO: localization
    logger.info('Simulink online preference changed');

    import simulink.online.internal.events.PreferenceChangeEmitter;
    emitter = PreferenceChangeEmitter.getInstance();
    notify(emitter, PreferenceChangeEmitter.EVT_CHANGE_ON_SL_PREF_DIALOG);
end  % onPreferenceChanged
