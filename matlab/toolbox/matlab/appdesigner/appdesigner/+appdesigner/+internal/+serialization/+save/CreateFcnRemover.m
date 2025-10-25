classdef CreateFcnRemover < appdesigner.internal.serialization.save.interface.DecoratorComponentDataAdjuster
    %CREATEFCNREMOVER This data adjuster removes any CreateFcns that are
    %set on components before saving them to disk.  This prevents the
    %propagation of apps where CreateFcns are executed on load.

    % Copyright 2021-2024 The MathWorks, Inc.

    methods
        function componentsStructure = adjustComponentDataPreSave(obj)
            componentsStructure = obj.DataAdjuster.adjustComponentDataPreSave();

            fig = componentsStructure.UIFigure;

            componentsWithCreateFcnSet = findall(fig, '-property', 'CreateFcn', '-and', '-not', 'CreateFcn', []);

            if isempty(componentsWithCreateFcnSet)
                return;
            end

            set(componentsWithCreateFcnSet, 'CreateFcn', []);
        end

        function adjustComponentDataPostSave(obj, componentsStructure)
            % no-op - we do not want to restore CreateFcns to any
            % components.
            obj.DataAdjuster.adjustComponentDataPostSave(componentsStructure);
        end
    end
end