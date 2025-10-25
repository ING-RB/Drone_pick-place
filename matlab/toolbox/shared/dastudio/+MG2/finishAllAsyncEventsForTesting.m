function finishAllAsyncEventsForTesting
% Helper function to finish all async tasks in MG2.
    MG2.syncOnGuiPingPong();
    
    sts  = DAS.Studio.getAllStudios();
    for ii = 1:length(sts)
        editors = sts{ii}.App.getAllEditors();
        for jj = 1:length(editors)
            GLUE2.Util.updateInvalidatedGlyphs(editors(jj));
        end
    end
	
	MG2.syncOnGuiPingPong();
end