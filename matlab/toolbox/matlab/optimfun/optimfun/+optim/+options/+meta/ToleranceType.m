classdef ToleranceType < optim.options.meta.OptionType
%

%ToleranceType metadata for any tolerance option
%
% TT = optim.options.meta.ToleranceType(label) constructs a ToleranceType
% with the given label. The category and validation is fixed for all
% instances.
%
% ToleranceType extends optim.options.meta.OptionType.
%
% See also OPTIM.OPTIONS.META.OPTIONTYPE, OPTIM.OPTIONS.META.FACTORY

%   Copyright 2019 The MathWorks, Inc.

    properties(Constant)
        TypeKey = 'numeric';
        TabType = {'numeric','scalar','>=0'};
    end
    
    % Inherited properties
    properties(SetAccess = protected, GetAccess = public)
        Category = getString(message('MATLAB:optimfun:options:meta:categories:Tolerances'));
        DisplayLabel
        Widget
        WidgetData
    end
    
    % Instance properties - specific to numeric option types
    % NOTE that this does not mean NumericType since there is no
    % inheritence here.
    properties(SetAccess = private, GetAccess = public)
        % Shape - what shape array. Used by a front-end (e.g. GUI)
        % NOTE: scalarness is enforced explicitly in the validate() method
        % which is a mini-code optimization.
        Shape (1,:) char = 'scalar';
        
        % Limits - the lower/upper bounds for all values. This is used by
        % the validation as well as the UI widgets.
        Limits (1,2) double = [0 Inf];
        
        % Inclusive - a logical array indicating whether the limits are
        % inclusive. This is used by the validation as well as the UI
        % widgets.
        Inclusive (1,2) logical = [true false];
    end
    
    methods
        % Constructor
        function this = ToleranceType(label)
            this.DisplayLabel = label;
            this.Widget = 'matlab.ui.control.NumericEditField';
            this.WidgetData = {'HorizontalAlignment', 'left', ...
                            'Limits', [0 Inf], ...
                            'LowerLimitInclusive', true, ...
                            'UpperLimitInclusive', false};
        end
        
        % validate - The function that validates a given value against the
        % type information baked into the class.
        function [value,valid,errid,errmsg] = validate(~,name,value)  
            valid = isscalar(value) && isnumeric(value) && isreal(value) && value >= 0;
            errid = ''; errmsg = '';
            if ~valid
                if ischar(value)
                    msgid = 'MATLAB:optimfun:optimoptioncheckfield:nonNegRealStringType';
                    errid = 'optim:options:meta:ToleranceType:validate:StringNotAToleranceType';
                else
                    msgid = 'MATLAB:optimfun:optimoptioncheckfield:notAnonNegReal';
                    errid = 'optim:options:meta:ToleranceType:validate:NotAToleranceScalar';
                end
                errmsg = getString(message(msgid, name));
            else
                value = double(full(value));
            end
        end
    end
    
end