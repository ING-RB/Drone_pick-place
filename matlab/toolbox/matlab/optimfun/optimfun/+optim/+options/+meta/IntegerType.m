classdef IntegerType < optim.options.meta.OptionType
%

%IntegerType metadata for any integer option
%
% IT = optim.options.meta.IntegerType(limits,label,category) constructs a
% IntegerType with the given label and category. The numeric values in
% limits (a 1x2 vector) will be enforced for validation with the following
% relation:
% 
% limits(1) <= valid values <= limits(2)
%
% Note: this is only for scalar integer values. Integer arrays would need a
% new OptionType subclass or a change to this one.
%
% IntegerType extends optim.options.meta.OptionType.
%
% See also OPTIM.OPTIONS.META.OPTIONTYPE, OPTIM.OPTIONS.META.FACTORY

%   Copyright 2019-2020 The MathWorks, Inc.

    % Inherited constant properties
    properties(Constant)
        TypeKey = 'integer';
        TabType = 'integer';
    end
    
    % Inherited properties
    properties(SetAccess = protected, GetAccess = public)
        Category     
        DisplayLabel
        Widget
        WidgetData
    end
    
    % Instance properties - specific to numeric option types
    properties(SetAccess = private, GetAccess = public)        
        % Limits - the lower/upper bounds for all values
        Limits (1,2) double
        
        % Inclusive - a logical array indicating whether the limits are
        % inclusive. These are needed for the UI widgets.
        % These are always true.
        Inclusive (1,2) logical = [true true];
    end
    
    methods
        % Constructor
        function this = IntegerType(limits,label,category)
            this.Limits = limits;
            this.DisplayLabel = label;
            this.Category = category;
            this.Widget = 'matlab.ui.control.NumericEditField';
            this.WidgetData = {'HorizontalAlignment', 'left', ...
                'Limits', limits, ...
                'LowerLimitInclusive', true, ...
                'UpperLimitInclusive', true};
        end
        
        % validate - The function that validates a given value against the
        % type information baked into the class.
        function [value,isOK,errid,errmsg] = validate(this,name,value)
            errid = ''; errmsg = '';
            isOK = isscalar(value) && isreal(value) && isnumeric(value) && (floor(value) == value) && ...
            	value >= this.Limits(1) &&  value <= this.Limits(2);
              
            if ~isOK
                % Special case for non-negative integers (e.g. MaxIter)
                if this.Limits(1) == 0 && isinf(this.Limits(2))
                    msgid = 'MATLAB:optimfun:optimoptioncheckfield:notANonNegInteger';
                    errid = 'optim:options:meta:IntegerType:validate:NotANonNegIntegerType';
                    args = {};
                else
                    % General message including range in message
                    msgid = 'MATLAB:optimfun:options:meta:validation:NotAnIntegerType';
                    errid = 'optim:options:meta:IntegerType:validate:NotAnIntegerType';
                    args = cellstr(string(this.Limits));
                end
                errmsg = getString(message(msgid, name, args{:}));
            else
                value = double(value);
            end
        end
    end
    
end