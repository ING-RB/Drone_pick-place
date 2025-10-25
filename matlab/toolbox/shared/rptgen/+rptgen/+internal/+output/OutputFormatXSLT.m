classdef OutputFormatXSLT < rptgen.internal.output.OutputFormat
    %OUTPUTFORMATDB2XSLT Defines xslt (html/rtf) format
    
    %   Copyright 2020 The MathWorks, Inc.
    
    methods
        
        function obj =  OutputFormatXSLT(newID,defaultVisible, ...
                theDescription, defaultExtension,imageHG,imageSL,imageSF)
            obj@rptgen.internal.output.OutputFormat(newID,defaultVisible, ...
                theDescription,defaultExtension,imageHG,imageSL,imageSF);
        end
        
    end
end

