classdef OutputFormatDB2DOM < rptgen.internal.output.OutputFormat
    %OUTPUTFORMATDB2DOM Defines db2dom format
    
    %   Copyright 2020 The MathWorks, Inc.
    
    methods
        
        function obj =  OutputFormatDB2DOM(newID,defaultVisible, ...
                theDescription, defaultExtension,imageHG,imageSL,imageSF)
    	obj@rptgen.internal.output.OutputFormat(newID,defaultVisible, ...
            theDescription,defaultExtension,imageHG,imageSL,imageSF);
        end
        
    end
end

