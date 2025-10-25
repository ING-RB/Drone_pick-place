classdef Version1Loader < appdesigner.internal.serialization.loader.interface.Loader
    %VERSION1LOADER  A class to load older apps (16a-17b), and some 18a
    %apps that were created before the serialization change
    
    % Copyright 2017-2021 The MathWorks, Inc.
    
    properties
        AppData
    end
    
    methods
        
        function obj = Version1Loader(appData)
            obj.AppData = appData;
        end
        
        function appData = load(obj)
            % convert the data to the new format
            appData = obj.convertToCurrentFormat(obj.AppData);
        end
    end
    
    methods(Access='private')
        
        function appData = convertToCurrentFormat(~,olderAppData)
            % converts the older format data to the new format
            
            % return a struct of data
            appData = struct();
            
            % update the components with a structure of design-time data
            componentList = findall(olderAppData.appData.UIFigure, '-property', 'DesignTimeProperties');
            % save all the component Code Names for Callback processing
            % below
            componentCodeNames = cell(size(componentList,1), 1);
            for i = 1:length(componentList)
                childComponent = componentList(i);
                % get the Design time properties MCOS object
                dtp = childComponent.DesignTimeProperties;
                
                % create and add fields to a structure
                designTimeProperties = struct();
                designTimeProperties.CodeName = dtp.CodeName;
                componentCodeNames{i} =  dtp.CodeName;
                designTimeProperties.GroupId = dtp.GroupId;
                designTimeProperties.ComponentCode = dtp.ComponentCode;
                
                % set this design time property structure on the component
                childComponent.DesignTimeProperties = designTimeProperties;
            end
            
            % set the UIFigure oand groups on the struct
            appData.components.UIFigure = olderAppData.appData.UIFigure;
            appData.components.Groups =   olderAppData.appData.Metadata.GroupHierarchy;
            
            % create a CodeData structure
            codeDataStruct = appdesigner.internal.serialization.loader.util.convertVersion1CodeDataToVersion2(olderAppData.appData.CodeData);
            callbacks = olderAppData.appData.CodeData.Callbacks;
            for i=1:length(callbacks)
                callback = callbacks(i);
                % recreate ComponentDatas as a struct
                componentDatas = callback.ComponentData;
                for  j=1:length(componentDatas)
                    cd = componentDatas(j);
                    % find the component this callback is associated with
                    componentIdx = find(strcmp(cd.CodeName, componentCodeNames));
                    if (numel(componentIdx) == 1 && ... check that the component exists
                            isprop(componentList(componentIdx), cd.CallbackPropertyName) && ...
                            ... check that the component's property points to this callback
                            strcmp(get(componentList(componentIdx), cd.CallbackPropertyName), callback.Name))
                        codeDataStruct.Callbacks(i).ComponentData(end+1).CodeName = cd.CodeName;
                        codeDataStruct.Callbacks(i).ComponentData(end).CallbackPropertyName = cd.CallbackPropertyName;
                        codeDataStruct.Callbacks(i).ComponentData(end).ComponentType = cd.ComponentType;
                    end
                end
            end

            % set the code Data
            appData.code = codeDataStruct;
            
        end
    end
end
