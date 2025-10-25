classdef ComponentDataLoader < ...
        appdesigner.internal.serialization.loader.apptypedataloader.AbstractAppTypeDataLoader
    %COMPONENTDATALOADER loads the serialized app type data
    %for custom ui components, who expect to have a possible 'update' method
    %saved to disk, and a possible code event array. this class is used to
    %default those values for the client to consume
    
    % Copyright 2021, MathWorks Inc.
    
    properties (Access = private, Constant)
        UpdateKey = 'update';
        PostSetupKey = 'postSetup';
    end
    
    methods
        function codeData = load(obj, loadedData)
            codeData = loadedData;
            
            if ~isfield(codeData, 'AppTypeData')
                codeData.AppTypeData = struct;
            end
            
            if ~isfield(codeData.AppTypeData, 'CallbackPropertyEvents')
                codeData.AppTypeData.CallbackPropertyEvents = struct;
            end

            if ~isfield(codeData.AppTypeData, 'ManagedUserProperties')
                codeData.AppTypeData.ManagedUserProperties = struct;
            else
                value = [];
                dataType = [];
                for i=1:length(codeData.AppTypeData.ManagedUserProperties)
                    if (isfield(codeData.AppTypeData.ManagedUserProperties(i), 'DefaultValue'))
                        value = codeData.AppTypeData.ManagedUserProperties(i).DefaultValue;
                    end

                    if (isfield(codeData.AppTypeData.ManagedUserProperties(i), 'DataType'))
                        dataType = codeData.AppTypeData.ManagedUserProperties(i).DataType;
                    end

                    [inferredDataType, ~, inferredDefaultValue, inferredRenderer] = appdesigner.internal.usercomponent.UserComponentPropertyUtils.getInferredPropertyDetails(value, dataType);
                    codeData.AppTypeData.ManagedUserProperties(i).InferredDataType = inferredDataType;
                    codeData.AppTypeData.ManagedUserProperties(i).InferredDefaultValue = inferredDefaultValue;
                    codeData.AppTypeData.ManagedUserProperties(i).InferredInspectorRenderer = inferredRenderer;
                end
            end
            
            if ~isfield(codeData.AppTypeData, 'AllowTestCaseAccess')
                codeData.AppTypeData.AllowTestCaseAccess = false;
            end
            
            if ~isfield(codeData.AppTypeData, 'Methods')
                codeData.AppTypeData.Methods = struct;
            end
            
            if ~isfield(codeData.AppTypeData.Methods, obj.UpdateKey)
                codeData.AppTypeData.Methods.(obj.UpdateKey) = {};
            end
            
            if ~isfield(codeData.AppTypeData.Methods, obj.PostSetupKey)
                codeData.AppTypeData.Methods.(obj.PostSetupKey) = {};
            end
        end
    end
end
