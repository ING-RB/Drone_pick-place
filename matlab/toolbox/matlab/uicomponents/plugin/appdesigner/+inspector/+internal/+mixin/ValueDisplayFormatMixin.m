classdef ValueDisplayFormatMixin < handle
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Copyright 2017-2020 The MathWorks, Inc.
    
    properties(SetObservable = true)
        ValueDisplayFormat internal.matlab.editorconverters.datatype.DisplayFormat
    end
    
    methods
        function val = get.ValueDisplayFormat(obj)
            val = obj.OriginalObjects.ValueDisplayFormat; %#ok<*MCNPN>
        end
        
        function set.ValueDisplayFormat(obj, val)
            for idx = 1:length(obj.OriginalObjects)
                if ~isequal(obj.OriginalObjects(idx).ValueDisplayFormat, val.getFormat)
                    obj.OriginalObjects(idx).ValueDisplayFormat = val.getFormat; %#ok<*MCNPR>
                end
            end
        end
    end
end
