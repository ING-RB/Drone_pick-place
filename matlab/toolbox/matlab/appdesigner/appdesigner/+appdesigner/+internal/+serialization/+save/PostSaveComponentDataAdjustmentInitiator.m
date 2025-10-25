classdef PostSaveComponentDataAdjustmentInitiator < appdesigner.internal.serialization.save.interface.DecoratorComponentDataAdjuster
    %POSTSAVECOMPONENTDATAADJUSTMENTINITIATOR  A class to provide a basic data
    %adjuster to kick off the post-save data adjustment.

    % Copyright 2021 The MathWorks, Inc.

    properties (Access = private)
        ComponentsStructure
    end

    methods
        function componentsStructure = adjustComponentDataPreSave(obj)
            % This method exists to help setup the decorators
            % properly and to easily end the decoration procedure.

            componentsStructure = obj.DataAdjuster.adjustComponentDataPreSave();
            % Store the components structure for cleanup later.
            obj.ComponentsStructure = componentsStructure;
        end

        function adjustComponentDataPostSave(obj, componentsStructure)
            % no-op.  This method exists to help setup the decorators
            % properly and to easily end the decoratoration
            obj.DataAdjuster.adjustComponentDataPostSave(componentsStructure);
        end

        function delete(obj)
            if ~isempty(obj.ComponentsStructure)
                % If the ComponentsStructure property is empty, the
                % component data was never adjusted before a save, so do
                % not try to perform the post-save adjustment.
                obj.adjustComponentDataPostSave(obj.ComponentsStructure);
            end
        end
    end
end
