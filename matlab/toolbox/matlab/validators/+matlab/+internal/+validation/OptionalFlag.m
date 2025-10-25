classdef (Abstract) OptionalFlag
% Internal use only.
% This class provides basic optional flags support until we
% have enums that support text identifiers with special characters
% in them.
%
% To use it, create a subclass that defines a Constant property 'Flags'.
% The property's value is a string array of flags.
%
% Example:
%
%    classdef Selectable < matlab.internal.validation.OptionalFlag
%        properties(Constant)
%            Flags = ["abc", "xyz", "support-hypen-as-you-can-see"]
%        end
%    end
%
%    Here is how you can use Selectable in validation, like this:
%
%    function foo(x,y,options)
%        arguments
%            x,y
%            options.Choice (1,1) Selectable  
%        end
%    end
%
%    
%    >> foo(1,2,"Choice",'x')
%    >> foo(1,2,"Choice",'hmm')
%    Error using foo
%    Invalid name-value argument 'Choice'. 'hmm' is invalid. Value must be 'abc', 'xyz', or 'support-hypen-as-you-can-see'.
    
%   Copyright 2020 The MathWorks, Inc.  

    properties(Constant, Abstract)
        Flags (1,:) string
    end
    
    properties
        Flag (1,1) string
    end

    methods
        function flagObj = OptionalFlag(flag)
            flagObj.Flag = validatestring(flag,flagObj.Flags);
        end
    
        % future:
        % (1) Use MFS to make sure p1,p2 are from compatible classes
        % (2) Support inexact case and truncated string matching
        
        function tf = strcmp(p1, p2)
            arguments
                p1 string
                p2 string
            end
            tf = strcmp(p1,p2);
        end
        
        function tf = eq(p1, p2)
            arguments
                p1 string
                p2 string
            end
            tf = p1 == p2;
        end
        
        function str = string(obj)
            str = obj.Flag;
        end
    
        function str = char(obj)
            str = char(obj.Flag);
        end
    end
end

