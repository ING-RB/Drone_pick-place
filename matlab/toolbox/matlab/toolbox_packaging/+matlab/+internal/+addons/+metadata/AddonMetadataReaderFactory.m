classdef AddonMetadataReaderFactory
    
    methods (Static)
        function reader = getAddonMetadataReader(path)
            %should be responsible for checking that the thing exists
            if endsWith(path,".mltbx")
                %if the path is an mltbx, use a toolbox reader
                reader = matlab.internal.addons.metadata.MltbxMetadataReader(path);
            elseif endsWith(path,".mlappinstall")
                %if path leads to an app, use app reader that uses java
                reader = matlab.internal.addons.metadata.MlappinstallMetadataReader(path);
            else
                reader = [];
                %path could otherwise be a metadata.xml/zip, a resource
                %folder, or install location
                msg = "Reader factory does not handle that type of add-on.";
                error(msg)
            end
        end
    end
end

