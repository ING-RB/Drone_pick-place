classdef OutputFormatFOP < rptgen.internal.output.OutputFormatXSLT
    %OUTPUTFORMATFOP Defines fop format
    
    %   Copyright 2020 The MathWorks, Inc.
    
    properties
        Renderer string = ""
    end
    
    methods
        
        function obj =  OutputFormatFOP(newID,defaultVisible, ...
                theDescription, defaultExtension,imageHG,imageSL,imageSF, ...
                fopRenderer)
            obj@rptgen.internal.output.OutputFormatXSLT(newID,defaultVisible, ...
                theDescription,defaultExtension,imageHG,imageSL,imageSF);
            obj.Renderer = fopRenderer;
        end
        
        function setRenderer(obj,v), obj.Renderer = v; end
        function v = getRenderer(obj), v = obj.Renderer; end
        
    end
end

