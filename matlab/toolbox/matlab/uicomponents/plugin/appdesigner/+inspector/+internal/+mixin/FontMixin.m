classdef FontMixin < handle	 & ...
        matlab.graphics.mixin.internal.GraphicsDataTypeContainer
    %
    
    %   Copyright 2017-2021 The MathWorks, Inc.
    
    properties(SetObservable = true)
        FontName matlab.internal.datatype.matlab.graphics.datatype.FontName
        FontSize internal.matlab.editorconverters.datatype.FontSize
        FontWeight internal.matlab.editorconverters.datatype.FontWeight
        FontAngle internal.matlab.editorconverters.datatype.FontAngle
    end
    
    methods
        function value = get.FontWeight(this)
            if isprop(this.OriginalObjects, "FontWeight")
                value = this.OriginalObjects.FontWeight;
            else
                value = [];
            end
        end
        
        function set.FontWeight(this, value)
            if ~this.InternalPropertySet
                for idx = 1:length(this.OriginalObjects)
                    if ~isequal(this.OriginalObjects(idx).FontWeight,value.getValue)
                        this.OriginalObjects(idx).FontWeight = value.getValue;
                    end
                end
            end
        end
        
        function value = get.FontAngle(this)
            if isprop(this.OriginalObjects, "FontAngle")
                value = this.OriginalObjects.FontAngle;
            else
                value = [];
            end
        end
        
        function set.FontAngle(this, value)
            if ~this.InternalPropertySet
                for idx = 1:length(this.OriginalObjects)
                    if ~isequal(this.OriginalObjects(idx).FontAngle,value.getValue)
                        this.OriginalObjects(idx).FontAngle = value.getValue;
                    end
                end
            end
        end

        function value = get.FontSize(this)
            if isprop(this.OriginalObjects, "FontSize")
                value = internal.matlab.editorconverters.datatype.FontSize(this.OriginalObjects.FontSize);
            else
                value = [];
            end
        end
        
        function set.FontSize(this, value)
            if ~this.InternalPropertySet
                val = double(value.getValue);
                for idx = 1:length(this.OriginalObjects)
                    if ~isequal(this.OriginalObjects(idx).FontSize, val)
                        this.OriginalObjects(idx).FontSize = val;
                    end
                end
            end
        end
    end
end
