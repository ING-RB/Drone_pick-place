function syncOnGuiPingPong
    cleanupObj = onCleanup(@performance.cooperativeTaskManager.resumePPE);
    performance.cooperativeTaskManager.pausePPE;
    pingLevel = MG2.Util.servePingPong;
    while (MG2.Util.getPongLevel < pingLevel)
        pause(0.000001); % Use a small number (1e-6) to reduce the overheads of synchronization in Test Driver methods.
    end
end