classdef LogicalType < optim.options.meta.OptionType
%

%LogicalType metadata for any logical option
%
% LT = optim.options.meta.LogicalType(label,category) constructs a
% LogicalType with the given label and category. All valid values must be
% logical scalars (true/false).
%
% LogicalType extends optim.options.meta.OptionType.
%
% See also OPTIM.OPTIONS.META.OPTIONTYPE, OPTIM.OPTIONS.META.FACTORY

%   Copyright 2019 The MathWorks, Inc.

    % Inherited constant properties
    properties(Constant)
        TypeKey = 'logical';  
        TabType = {'logical', 'scalar'};
    end
    
    % Inherited properties
    properties(SetAccess = protected, GetAccess = public)
        Category             
        DisplayLabel
        Widget
        WidgetData          
    end

    methods
        % Constructor
        function this = LogicalType(label,category)
            this.DisplayLabel = label;
            this.Category = category;
            this.Widget = 'matlab.ui.control.CheckBox';
            this.WidgetData = {'Text', ''};
        end
        
        % validate - The function that validates a given value against the
        % type information baked into the class.
        function [value,isOK,errid,errmsg] = validate(~,name,value)
            errid = ''; errmsg = '';
            isOK =  isscalar(value) && islogical(value);
            if ~isOK
                msgid = 'MATLAB:optimfun:optimoptioncheckfield:NotLogicalScalar';
                errid = 'optim:options:meta:LogicalType:validate:NotLogicalScalar';
                errmsg = getString(message(msgid, name));
            end
        end
    end
    
end