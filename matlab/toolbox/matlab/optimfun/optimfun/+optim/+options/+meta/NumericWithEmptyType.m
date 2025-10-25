classdef NumericWithEmptyType < optim.options.meta.NumericType
%    
    
%NumericWithEmptyType combination Numeric with an allowance for empty
%
% This class subclasses NumericType so that it appears to be a
% NumericType (i.e. isa( . , 'NumericType') = true ). Therefore, this
% type is for options where it is desired that the documented behavior is
% for double values, but with an allowance for empty (which NumericType
% does not permit).
%
% NumericWithEmptyType extends optim.options.meta.NumericType.
%
% See also OPTIM.OPTIONS.META.OPTIONTYPE, OPTIM.OPTIONS.META.NUMERICTYPE

%   Copyright 2019 The MathWorks, Inc.
    
    methods
        function this = NumericWithEmptyType(shp,limits,inclusive,label,category)
            % Base-class constructor
            this = this@optim.options.meta.NumericType(shp,limits,inclusive,label,category);
        end
    end
    
    methods
        function [value, isOK, errid, errmsg] = validate(this,name,value)
            
            isOK = true; errid = ''; errmsg = '';
            % Allow empty: only call NumericType's validate if non-empty
            if ~isempty(value)
                [value,isOK,errid,errmsg] = validate@optim.options.meta.NumericType(this,name,value);
            end
        end
            
    end
end