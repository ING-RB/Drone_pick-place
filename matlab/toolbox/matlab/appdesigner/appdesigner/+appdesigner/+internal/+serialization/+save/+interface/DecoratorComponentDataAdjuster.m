classdef DecoratorComponentDataAdjuster < appdesigner.internal.serialization.save.interface.ComponentDataAdjuster
    %DECORDATORCOMPONENTDATADJUSTER A decorator pre-save DataAdjuster that
    % will extend/change the functionality of the DataAdjuster it wraps

    % Copyright 2021 The MathWorks, Inc.

    properties
        DataAdjuster
    end

    methods
        function obj = DecoratorComponentDataAdjuster(dataAdjuster)
            % Constructor
            obj.DataAdjuster = dataAdjuster;
        end

        function adjustComponentDataPostSave(obj, componentsStructure)
            % Default implementation - do not adjust the component data
            % and simply pass it down the chain.
            obj.DataAdjuster.adjustComponentDataPostSave(componentsStructure);
        end
    end
end
