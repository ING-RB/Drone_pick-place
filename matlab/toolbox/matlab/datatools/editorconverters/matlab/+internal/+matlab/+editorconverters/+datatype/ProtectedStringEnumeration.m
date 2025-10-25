classdef ProtectedStringEnumeration
    % This is an interface for data types that want to have their editor be
    % shown with dropdown menu of text values, where new entries cannot be
    % added.
    
    % Similar to StringEnumeration, forces client validation so editing values
    % is not allowed.
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties
        EnumeratedValues
        Value
    end
    
    methods
        function this = ProtectedStringEnumeration(value, varargin)
            % Standardize on working with chars/cellstrs for easy pass-through
            % to the client
            this.Value = convertStringsToChars(value);
            
            if nargin > 1
                this.EnumeratedValues = convertStringsToChars(varargin{1});
            end
        end
        
        function b = char(this)
            b = char(this.Value);
        end
        
        function b = string(this)
            b = string(this.Value);
        end
    end
end
