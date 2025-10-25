classdef FontSizeMixin < handle
    % This class has the definition for FontSize

    % Copyright 2021 The MathWorks, Inc.

    properties
        FontSize internal.matlab.editorconverters.datatype.FontSize
    end

    methods
        function value = get.FontSize(this)
            value = internal.matlab.editorconverters.datatype.FontSize(this.OriginalObjects.FontSize); %#ok<*MCNPN> 
        end

        function set.FontSize(this, value)
            if ~this.InternalPropertySet
                val = double(value.getValue);
                for idx = 1:length(this.OriginalObjects)
                    if ~isequal(this.OriginalObjects(idx).FontSize, val)
                        this.OriginalObjects(idx).FontSize = val; %#ok<*MCNPR> 
                    end
                end
            end
        end
    end
end