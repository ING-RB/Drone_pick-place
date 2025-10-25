classdef ModelFactory
    %This class is for internal use only. It may be removed in the future.

    %ModelFactory creates motion models according to user specifications. 
    %   All the motion models must be implementing ModelBase class and
    %   support construction a single argument |dataType| that
    %   indicates the type of the numeric values stored in the model
    %   configuration.

    %   Copyright 2018-2024 The MathWorks, Inc.
    
    %#codegen
    
    methods (Static)
        
        function model = getMotionModel(modelType, dataType, numInstances)
            %getMotionModel constructs a motion model instance of given |modelType|.
            
            coder.extrinsic('strcat');
            coder.const(modelType);
            coder.const(dataType);
            coder.const(numInstances);
            
            modelList = coder.const(robotics.core.internal.navigation.ModelListSingleton.getInstance().Models);
            
            model = coder.const(feval('eval',...
                strcat(modelList.(modelType), '(''', dataType,'''', ',', int2str(numInstances),')')...
                ));
        end
        
    end
end
