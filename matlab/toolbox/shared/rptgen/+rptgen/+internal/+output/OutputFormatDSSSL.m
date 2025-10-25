classdef OutputFormatDSSSL < rptgen.internal.output.OutputFormat
    %OUTPUTFORMATDSSSL Defines DSSSL format
    
    %   Copyright 2020 The MathWorks, Inc.
    
    properties
        Backend string = ""
        V1Name string = ""
    end
    
    methods
        
        function obj =  OutputFormatDSSSL(newID,defaultVisible, ...
                theDescription, defaultExtension,imageHG,imageSL, ...
                imageSF,jadeBackend,v1Name)
            obj@rptgen.internal.output.OutputFormat(newID,defaultVisible, ...
                theDescription,defaultExtension,imageHG,imageSL,imageSF);
            obj.Backend = jadeBackend;
            obj.V1Name = v1Name;
        end
        
        function setBackend(obj,v), obj.Backend = v; end
        function v = getBackend(obj), v = obj.Backend; end
        
        function setV1Name(obj,v), obj.V1Name = v; end
        function v = getV1Name(obj), v = obj.V1Name; end
        
    end
end

