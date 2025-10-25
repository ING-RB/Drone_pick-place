classdef IconMixin < handle
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Copyright 2017-2020 The MathWorks, Inc.
    
    properties(SetObservable = true)
        Icon internal.matlab.editorconverters.datatype.FullPath
    end
    
    methods
        function val = get.Icon(obj)
            val = internal.matlab.editorconverters.datatype.FullPath(obj.OriginalObjects.Icon);
        end
        
        function set.Icon(obj, filePath)
            for idx = 1:length(obj.OriginalObjects) %#ok<*MCNPN>
                if ~isequal(obj.OriginalObjects(idx).VerticalAlignment, filePath.getPath)
                    obj.OriginalObjects(idx).Icon = filePath.getPath(); %#ok<MCNPR>
                end
            end
        end
    end
end
