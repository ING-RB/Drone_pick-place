classdef ExcludeZeroType < optim.options.meta.NumericType
%

%ExcludeZeroType metadata for any numeric double option that has a range
%that would otherwise include 0, and then excludes 0
%
% EZT = optim.options.meta.ExcludeZeroType(shape,limits,inclusive,label,category)
% constructs an ExcludeZeroType (a subclass of NumericType) with the given
% label and category. All valid values must match the array shape described
% by shape and be within the the given limits (a 1x2 vector) with the
% following relation:
% 
% limits(1) <= valid values <= limits(2)
%
% and
%
% valid values ~= 0
%
% The respective elements of inclusive (a 1x2 logical vector) determine
% whether the inequalties are strict (false) or not (true).
%
% ExcludeZeroType extends optim.options.NumericType
%
% See also OPTIM.OPTIONS.META.NUMERICTYPE, OPTIM.OPTIONS.META.FACTORY

%   Copyright 2019 The MathWorks, Inc.

    methods
        % Constructor - just forward
        function this = ExcludeZeroType(shp,limits,inclusive,label,category)
            this = this@optim.options.meta.NumericType(shp,limits,inclusive,label,category);
        end
        
        % validate - The function that validates a given value against the
        % type information baked into the class.
        function [value,isOK,errid,errmsg] = validate(this,name,value)
            % Check value as numeric first
            [value,isOK,errid,errmsg] = validate@optim.options.meta.NumericType(this,name,value);
            if isOK && isa(value,'double') && any(value(:) == 0)
                isOK = false;
                errid = 'optim:options:meta:ExcludeZeroType:InvalidZeroValue';
                errmsg = getString(message('MATLAB:optimfun:options:meta:validation:InvalidZeroValue',name));
            end
        end
    end
end