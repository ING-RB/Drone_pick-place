classdef LogicalWithEnumType < optim.options.meta.LogicalType
%    
    
%LogicalWithEnumType combination logical with fallback enumerated list of strings
%
% This is a composite class. It subclasses LogicalType so that it appears
% to be a LogicalType (i.e. isa( . , 'LogicalType') = true ). Therefore,
% this type is for options where it is desired that the documented behavior
% is true/false, but has legacy behavior accepting string values.
%
% LET = optim.options.meta.LogicalWithEnumType(label,category,values)
% constructs a LogicalWithEnumType with the given label and category. Valid
% values must be either a logical scalar (true/false) or an exact match of
% one of the character arrays in the cell array values.
%
% NOTE: the valid character arrays must be ordered with the value that
% corresponds to "true" first, and the value corresponding to "false" 2nd.
%
% LogicalWithEnumType extends optim.options.meta.LogicalType.
%
% See also OPTIM.OPTIONS.META.OPTIONTYPE, OPTIM.OPTIONS.META.FACTORY

%   Copyright 2019 The MathWorks, Inc.

    properties(Access = private)
        % For added validation
        EnumType
    end
    
    methods
        function this = LogicalWithEnumType(label,category,values)
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
                    % Enum values check out. Send back valid message and
                    % convert to logical.
                    errid = id; errmsg = msg; isOK = true;
                    value = strcmp(value,this.EnumType.Values{1});
                end
                % NOTE: if both checks fail, return the error from the
                % logical check, since that's the default behavior for
                % options of this "type".
            end
        end
            
    end
end