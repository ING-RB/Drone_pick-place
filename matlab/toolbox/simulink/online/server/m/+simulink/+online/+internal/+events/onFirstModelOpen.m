function onFirstModelOpen()
    initializeOnFirstModelOpen();

    import simulink.online.internal.events.FirstModelOpenEmitter;
    emitterInst = FirstModelOpenEmitter.getInstance();
    notify(emitterInst, 'FirstModelOpen');
end

function initializeOnFirstModelOpen()

    % async process to sync up the quick insert database to tmp folder in client side
    % so that it can speed up quick insert.
    % it will not block the M thread, so all the interaction with the model is responsive
    slblocksearchdb.refresh;

    % Start auto save
    import simulink.online.internal.autosave.Autosave;
    Autosave.getInstance().start();
end
