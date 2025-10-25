classdef NameValueParserInterface < handle
    %This class is for internal use only. It may be removed in the future.
    
    %NameValueParserInterface Abstract parent class name-value parsers
    
    %   Copyright 2016-2020 The MathWorks, Inc.
    
    %#codegen
    
    properties (SetAccess = immutable)
        
        %Names - Cell array of parameter names (as char vectors)
        Names
        
        %Defaults - Default values for the parameters listed in Names
        Defaults
        
    end
    
    methods (Abstract)
        
        %parse Parses a comma-separated list of Name-Value pairs. 
        %   The parsed values can be accessed using the parameterValue
        %   method
        parse(obj, varargin)
        
        %parameterValue Returns the parsed parameter value for NAME
        %   This value is either the one provided in the input
        %   arguments to PARSE or the one given in OBJ.Defaults.
        value = parameterValue(obj, name)
        
        %copy Returns a deep copy of the object
        newobj = copy(obj)
        
    end
    
    methods
        
        function obj = NameValueParserInterface(names, defaults)
            %NameValueParserInterface Constructor
            obj.Names = names;
            obj.Defaults = defaults;
        end
        
    end
    
    methods(Static, Hidden)
        
        function props = matlabCodegenNontunableProperties(~)
            % Let the coder know about non-tunable parameters
            props = {'Names'};
        end
        
    end  
end
