classdef MixInControlsModelResponse < handle
    methods (Sealed,Access=protected)
        function validateModel(~,model)
            mustBeA(model,'DynamicSystem')
        end
    end
end