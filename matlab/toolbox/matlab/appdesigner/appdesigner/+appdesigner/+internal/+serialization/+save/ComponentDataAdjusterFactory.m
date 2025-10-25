classdef ComponentDataAdjusterFactory < handle
    %COMPONENTDATAADJUSTERFACTORY - A factory to instantiate the correct
    % pre-save component data adjusters

    % Copyright 2021 The MathWorks, Inc.

    methods
        function dataAdjuster = createComponentDataAdjuster(~, ComponentsStructure)

            % Create the basic data adjuster interface from the established
            % interface.  The chain must begin with this class.
            % Pre-save adjustment works from innermost to outermost and
            % this class is responsible for preserving that order.
            dataAdjuster = appdesigner.internal.serialization.save.PreSaveComponentDataAdjustmentInitiator(ComponentsStructure);

            % In some situations, we want to swap the values of aliased
            % properties into the component's real properties.  This
            % decorator completes those property swaps
            dataAdjuster = appdesigner.internal.serialization.save.ComponentPropertySwap(dataAdjuster);
            
            % Create a decorator to clear all CreateFcns on any components
            % so the saved components do not have a CreateFcn
            dataAdjuster = appdesigner.internal.serialization.save.CreateFcnRemover(dataAdjuster);

            % Add an adjuster to remove rogue ContextMenus that could have
            % been added by UACs.
            dataAdjuster = appdesigner.internal.serialization.save.RogueContextMenuRemover(dataAdjuster);

            % Add new DataAdjusters here in order to adjust component data
            % before the same procedure

            % End the chain with another basic data adjuster.  This must be
            % last in the chain to preserve correct order when restoring
            % component data post-save.
            % Post-save restoration goes from outermost to innermost and is
            % triggered when the data adjuster is deleted.
            dataAdjuster = appdesigner.internal.serialization.save.PostSaveComponentDataAdjustmentInitiator(dataAdjuster);
        end
    end
end
