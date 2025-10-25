%pointclouds.internal.pcui.utils Utility methods for point cloud viewers

% Copyright 2019 The MathWorks, Inc.
classdef utils
    
    methods (Static)
        %------------------------------------------------------------------
        function setAppData(hgHandle, propertyName, data)
            
            if ~isprop(hgHandle, propertyName)
                property = hgHandle.addprop(propertyName);
                
                property.Hidden     = true;
                property.Transient  = true;
            end
            
            hgHandle.(propertyName) = data;
        end
        
        %------------------------------------------------------------------
        function data = getAppData(hgHandle, propertyName)
            
            if isprop(hgHandle, propertyName)
                data = hgHandle.(propertyName);
            else
                data = [];
            end
        end
    end
end