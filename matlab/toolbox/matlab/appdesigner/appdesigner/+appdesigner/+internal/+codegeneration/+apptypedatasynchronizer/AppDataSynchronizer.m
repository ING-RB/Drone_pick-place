classdef AppDataSynchronizer < appdesigner.internal.codegeneration.apptypedatasynchronizer.AbstractAppTypeDataSynchronizer
    %APPDATASYNCHRONIZER app type data synchronizer used for apps,
    %including regular blank apps, responsive apps, and dialog apps.
    %Does not apply to Custom UI Components, Live Tasks, etc.

    % Applies incoming data from the client to the codeModel

    % Copyright 2021, MathWorks Inc.

    methods
        function syncAppTypeData(~, codeModel, codeData)
            % no op for R2022a
        end
    end
end
