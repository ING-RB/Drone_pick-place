classdef FcnType < optim.options.meta.OptionType
%

%FcnType metadata for any function option
%
% FT = optim.options.meta.FcnType(label,category) constructs a FcnType with
% the given label and category. The validation is fixed for all instances:
% cell arrays are not allowed and there are no "built-in" functions that
% will appear in the tab-complete list.
%
% FT = optim.options.meta.FcnType(label,category,values) constructs a
% FcnType with the given label and category. The validation will not allow
% cell arrays. The "built-in" functions given in values will appear in the
% tab-complete list.
%
% FT = optim.options.meta.FcnType(label,category,values,checkValues)
% constructs a FcnType. If checkValues is true, the validation will check
% against the set given in values.
%
% FcnType extends optim.options.meta.OptionType.
%
% See also OPTIM.OPTIONS.META.OPTIONTYPE, OPTIM.OPTIONS.META.FACTORY

%   Copyright 2019 The MathWorks, Inc.

    % Inherited constant properties
    properties(Constant)
        TypeKey = 'fcn';    
        TabType = {{'function_handle'}, {'@(x) isempty(x)'}};
    end
    
    % Inherited properties
    properties(SetAccess = protected, GetAccess = public)
        Category     
        DisplayLabel
        Widget
        WidgetData
    end
    
    % Instance properties - specific to function option types
    properties(SetAccess = private, GetAccess = public)
        % Values - The set of accepted values for this option.
        Values = '';

        % CheckAgainstValues - logical indicating whether to check against
        % the set of valid functions in Values. Default to false.
        CheckAgainstValues = false;        
    end
    
    
    methods
        % Constructor
        function this = FcnType(label,category,values,checkValues)
            this.DisplayLabel = label;
            this.Category = category;
            if nargin > 2
                this.Values = values;
                if nargin > 3
                    this.CheckAgainstValues = checkValues;
                end
            end
            this.Widget = 'matlab.ui.control.EditField';
            this.WidgetData = {};
        end
        
        % validate - The function that validates a given value against the
        % type information baked into the class. 
        function [value,isOK,errid,errmsg] = validate(this,name,value)

            isOK = true;
            errid = '';
            errmsg = '';
            if ~isempty(value)
                % If the value is a string, convert to char or cellstr - preserving case
                value = optim.options.meta.prepStringForValidation(value);

                isOK =  ischar(value) || isa(value, 'function_handle');
                if ~isOK
                    errid = 'optim:options:meta:FcnType:validate:InvalidFcnType';
                    errmsg = getString(message('MATLAB:optimfun:optimoptioncheckfield:notAFunction', name));
                else
                    if this.CheckAgainstValues
                        % Check that the value is a member of this.Values
                        [isOK,errid,errmsg] = this.checkMemberOfValues(name,value);
                    end
                end
            end
        end
    end
    
    methods(Access=protected) % Subclasses can call
        function [isOK,errid,errmsg] = checkMemberOfValues(this,name,value)
            isOK = true; 
            errid = ''; 
            errmsg = '';
            
            % Extra checking for set of possible functions (this.Values)
            if isa(value,'function_handle')
                value = func2str(value);
            end
            if ~any(strcmp(value,this.Values))
                % Format strings for error message
                validStrings = optim.options.meta.formatSetOfStrings(this.Values);
                isOK = false;
                errid = 'optim:options:meta:FcnType:validate:InvalidFcnType';
                msgid = 'MATLAB:optimfun:optimoptioncheckfield:notAStringsType';
                errmsg = getString(message(msgid,name,validStrings));
            end
        end
    end
    
end