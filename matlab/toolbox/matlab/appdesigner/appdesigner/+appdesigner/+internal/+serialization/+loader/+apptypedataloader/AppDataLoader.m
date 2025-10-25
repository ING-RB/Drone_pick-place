classdef AppDataLoader < ...
        appdesigner.internal.serialization.loader.apptypedataloader.AbstractAppTypeDataLoader
    %APPDATALOADER  Loads the serialized app type data for apps.  This includes
    % blank apps, responsive apps, and dialog apps.

    % Copyright 2021, MathWorks Inc.

    methods
        function codeData = load(~, loadedData)
            codeData = loadedData;
        end
    end
end
