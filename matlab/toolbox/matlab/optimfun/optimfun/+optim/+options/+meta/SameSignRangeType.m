classdef SameSignRangeType < optim.options.meta.NumericType
%

%SameSignRangeType metadata for any function option that is a
%specialization of NumericType that has Shape = range and requires each
%endpoint of the range to be the same sign.
%
% SameSignRangeType extends optim.options.meta.NumericType.
%
% See also OPTIM.OPTIONS.META.NUMERICTYPE, OPTIM.OPTIONS.META.FACTORY

%   Copyright 2020-2024 The MathWorks, Inc.

    methods
        % Constructor
        function this = SameSignRangeType(limits,inclusive,label,category)
            this = this@optim.options.meta.NumericType('vector',limits,inclusive,label,category);

            % Override the widget filter function
            numericCheckFcn = this.CheckFcn;
            % WidgetData is a cell array in P-V pair format. The
            % FilterVariablesFcn is expected to be the last element set.
            % Rather than parse the P-V pairs, just overwrite the last element
            this.WidgetData{end} = @(v)localSameSignRangeCheck(numericCheckFcn,v);
            this.CheckFcn = @(v)localSameSignRangeCheck(numericCheckFcn,v);
        end

        % validate - The function that validates a given value against the
        % type information baked into the class.
        function [value,isOK,errid,errmsg] = validate(this,name,value)
            errid = '';
            errmsg = '';
            isOK = this.CheckFcn(value);
            if ~isOK
                errid = 'optim:options:meta:NumericType:validate:InvalidSameSignRangeType';
                errmsg = getString(message('MATLAB:optimfun:options:checkfield:notSameSignRange', ...
                    name));
            else
                % Make sure the result is stored as double
                value = double(full(value));
            end
        end

    end
end

function isOK = localSameSignRangeCheck(baseCheckFcn,value)
% First check for a valid range NumericType
isOK = baseCheckFcn(value);
% Augment checking for same sign
isOK = isOK && numel(value) == 2 && (value(1) <= value(2)) && ...
    (all(value >= 0) || all(value <= 0) );
end