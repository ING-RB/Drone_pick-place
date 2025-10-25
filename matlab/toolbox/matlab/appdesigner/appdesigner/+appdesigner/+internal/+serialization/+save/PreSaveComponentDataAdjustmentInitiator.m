classdef PreSaveComponentDataAdjustmentInitiator < appdesigner.internal.serialization.save.interface.ComponentDataAdjuster
    %PRESAVECOMPONENTDATAADJUSTMENTINITIATOR  A class to provide a basic,
    %non-decorated, pre-save, data adjuster.  This is responsible for
    %kicking off the pre-save data adjustment.

    % Copyright 2021 The MathWorks, Inc.

    properties
        ComponentsStructure
    end

    methods
        function obj = PreSaveComponentDataAdjustmentInitiator(componentsStructure)
            % Constructor
            obj.ComponentsStructure = componentsStructure;
        end

        function componentsStructure = adjustComponentDataPreSave(obj)
            % This method exists to help setup the decorators
            % properly and to easily end the pre-save adjustment procedure.
            % Pre-save adjustment works from innermost to outermost
            % decorator, and as this is the innermost decorator it begins
            % the adjustment here.
            nargoutchk(1,1);

            componentsStructure = obj.ComponentsStructure;
        end

        function adjustComponentDataPostSave(obj, ~)
            % no-op.  This method exists to help setup the decorators
            % properly and to easily end the post-save adjustment procedure
            % Post-save adjustment works from outermost to innermost
            % decorator, and as this is the innermost decorator it ends
            % the adjustment here.
        end
    end
end
