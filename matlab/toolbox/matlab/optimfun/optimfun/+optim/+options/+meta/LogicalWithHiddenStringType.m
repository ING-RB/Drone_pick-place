classdef LogicalWithHiddenStringType < optim.options.meta.LogicalType
%    
%LogicalWithHiddenStringType combination logical with fallback enumerated list of strings
%
% This is a composite class. It subclasses LogicalType so that it appears
% to be a LogicalType (i.e. isa( . , 'LogicalType') = true ). Therefore,
% this type is for options where it is desired that the documented behavior
% is true/false, but also supports undocumented string values.
%
% E.g. options.EnableFeasibilityMode = {true,false,'always'} where end-users
% understand the option as boolean and 'always' is an undocumented feature.
%
% LET = optim.options.meta.LogicalWithHiddenStringType(label,category,values)
% constructs a LogicalWithHiddenStringType with the given label and category. Valid
% values must be either a logical scalar (true/false) or an exact match of
% one of the character arrays in the cell array values.
%
% LogicalWithHiddenStringType extends optim.options.meta.LogicalType.
%
% See also OPTIM.OPTIONS.META.OPTIONTYPE, OPTIM.OPTIONS.META.FACTORY
% 
% Copyright 2021 The MathWorks, Inc.

    properties(Access = private)
        % For added validation
        EnumType
    end
    
    methods
        function this = LogicalWithHiddenStringType(label,category,values)
            % Base-class constructor
            this@optim.options.meta.LogicalType(label,category);
            % Construct the EnumType
            this.EnumType = optim.options.meta.EnumType(values,'','');
        end
    end
    
    methods
        function [value, isOK, errid, errmsg] = validate(this,name,value)
            [value,isOK,errid,errmsg] = validate@optim.options.meta.LogicalType(this,name,value);
            if ~isOK
                % Invalid logical, check the enum values
                [value,valid,id,msg] = this.EnumType.validate(name,value);
                if valid
                    % Enum values check out. Send back valid message.
                    errid = id;
                    errmsg = msg;
                    isOK = true;
                end
                % NOTE: if both checks fail, return the error from the
                % logical check, since that's the default behavior for
                % options of this "type".
            end
        end
            
    end
end