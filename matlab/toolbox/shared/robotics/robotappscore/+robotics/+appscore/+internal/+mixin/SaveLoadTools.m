classdef SaveLoadTools < handle
    %This class is for internal use only. It may be removed in the future.
    
    %SaveLoadTools Collection of tools for saving and loading app models
    %   Used primarily to support app sessions
        
    % Copyright 2018 The MathWorks, Inc.
    
    methods
        function infoStruct = saveProperties(obj)
            %saveProperties Save poublic properties that are not
            %   set-observable, not constant and not transient, to struct
            classInfo = metaclass(obj);
            for i = 1:length(classInfo.PropertyList)
                prop = classInfo.PropertyList(i);
                
                if ~prop.SetObservable && ...
                   strcmp(prop.SetAccess, 'public') && ...
                   ~prop.Constant && ...
                   ~prop.Transient
                    pn = prop.Name;
                    infoStruct.(pn) = obj.(pn);
                end
            end
        end
        
        
        function loadProperties(obj, infoStruct)
            %loadProperties Load properties from infoStruct
            fnames = fieldnames(infoStruct);
            for i = 1:length(fnames)
                fn = fnames{i};
                obj.(fn) = infoStruct.(fn);
            end
        end
    end
end

