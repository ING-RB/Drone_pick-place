classdef MatrixStructType < optim.options.meta.OptionType
%

%MatrixStructType metadata for any option that accepts a matrix or a scalar
%struct with matrix fields.
%
% NT = optim.options.meta.MatrixStructType(label,category) constructs a
% MatrixStructType with the given label and category. All valid values must
% be a double matrix or a struct whose fields contain double matrices.
%
% MatrixStructType extends optim.options.meta.OptionType.
%
% See also OPTIM.OPTIONS.META.OPTIONTYPE, OPTIM.OPTIONS.META.FACTORY

%   Copyright 2019-2024 The MathWorks, Inc.

    % Inherited constant properties
    properties(Constant)
        TypeKey = 'matstruct';     
        TabType = {{'numeric','2d'},{'struct','scalar'}};
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
        function this = MatrixStructType(label,category)
            this.DisplayLabel = label;
            this.Category = category;
            this.Widget = 'matlab.ui.control.internal.model.WorkspaceDropDown';
            this.WidgetData = {'UseDefaultAsPlaceholder', true, ...
                        'FilterVariablesFcn', @check};
        end
        
        % validate - The function that validates a given value against the
        % type information baked into the class. 
        function [value,valid,errid,errmsg] = validate(~,name,value)
            errmsg = '';
            [valid,errid,msgid,structField,value] = check(value);
            if ~valid
                if ~isempty(structField)
                    errmsg = getString(message(msgid, name + "." + structField));
                else
                    errmsg = getString(message(msgid, name));
                end
            end
        end
    end
end

function [isvalid,errid,msgid,structField,value] = check(value)
% Core checking for matrix-struct option type.

% check valid matrix-struct input
isvalid = true;
errid = '';
msgid = '';
structField = '';
if isstruct(value)
    % check valid struct input
    structFields = fieldnames(value);
    for i = 1:numel(structFields)
        val = value.(structFields{i});
        if ~(isnumeric(val) && isreal(val) && all(isfinite(val(:))))
            isvalid = false;
            structField = structFields{i};
            msgid = 'MATLAB:optimfun:options:checkfield:nonRealEntries';
            errid = 'optim:options:meta:MatrixStructType:validate:NonRealEntries';
            return;
        else
            value.(structFields{i}) = double(value.(structFields{i}));
        end
    end
elseif isnumeric(value) && ismatrix(value)
    if ~(isreal(value) && all(isfinite(value(:))))
        isvalid = false;
        msgid = 'MATLAB:optimfun:options:checkfield:nonRealEntries';
        errid = 'optim:options:meta:MatrixStructType:validate:NonRealEntries';
    else
        value = double(value);
    end
else
    isvalid = false;
    msgid = 'MATLAB:optimfun:options:checkfield:notAStructOrMatrix';
    errid = 'optim:options:meta:MatrixStructType:validate:NotAStructOrMatrix';
end
end
