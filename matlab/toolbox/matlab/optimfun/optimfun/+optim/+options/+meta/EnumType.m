classdef EnumType < optim.options.meta.OptionType
%

%EnumType metadata for an enumerated set of strings option
%
% ET = optim.options.meta.EnumType(values,label,category) constructs an
% EnumType with the given label and category. Valid values must be an exact
% match of one of the character arrays in the cell array values.
%
% EnumType extends optim.options.meta.OptionType.
%
% See also OPTIM.OPTIONS.META.OPTIONTYPE, OPTIM.OPTIONS.META.FACTORY

%   Copyright 2019 The MathWorks, Inc.

    % Inherited constant properties
    properties(Constant)
        TypeKey = 'enum';
        TabType = 'enum';
    end
    
    % Inherited properties
    properties(SetAccess = protected, GetAccess = public)
        Category     
        DisplayLabel
        Widget
        WidgetData        
    end
    
    % Instance properties - specific to enumerated list option types
    properties(SetAccess = private, GetAccess = public)
        % Values - The set of accepted values for this option. Must be a
        % cell array of char vectors
        Values;
    end
    
    methods
        % Constructor
        function this = EnumType(values,label,category)
            this.Values = values;
            this.DisplayLabel = label;
            this.Category = category;
            this.Widget = 'matlab.ui.control.DropDown';
            this.WidgetData = {'Items', values};
        end
        
        % validate - The function that validates a given value against the
        % type information baked into the class. 
        function [value,valid,errid,errmsg] = validate(this,name,value)
            value = optim.options.meta.prepStringForValidation(value);
            
            valid = ischar(value) && any(strcmpi(value,this.Values));
            errid = ''; errmsg = '';
            if valid
                % Store the lowercase only
                value = lower(value);
            else
                fmtdStrings = optim.options.meta.formatSetOfStrings(this.Values);                
                msgid = 'MATLAB:optimfun:optimoptioncheckfield:notAStringsType';
                errid = 'optim:options:meta:EnumType:validate:InvalidEnum';
                errmsg = getString(message(msgid, name, fmtdStrings));
            end
        end
    end
    
end

