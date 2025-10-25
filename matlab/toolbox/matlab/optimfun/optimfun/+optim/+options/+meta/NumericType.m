classdef NumericType < optim.options.meta.OptionType
%

%NumericType metadata for any numeric double option
%
% NT = optim.options.meta.NumericType(shape,limits,inclusive,label,category)
% constructs a NumericType with the given label and category. All valid
% values must match the array shape described by shape and be within the
% the given limits (a 1x2 vector) with the following relation:
% 
% limits(1) <= valid values <= limits(2)
%
% The respective elements of inclusive (a 1x2 logical vector) determine
% whether the inequalties are strict (false) or not (true).
%
% NumericType extends optim.options.meta.OptionType.
%
% See also OPTIM.OPTIONS.META.OPTIONTYPE, OPTIM.OPTIONS.META.FACTORY

%   Copyright 2019-2024 The MathWorks, Inc.

    % Inherited constant properties
    properties(Constant) 
        TypeKey = 'numeric';               
        TabType = 'numeric';
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
        % Shape - what shape array (e.g. scalar, matrix, vector, ...)
        Shape (1,:) char
        
        % Limits - the lower/upper bounds for all values
        Limits (1,2) double
        
        % Inclusive - a logical array indicating whether the limits are
        % inclusive. This is used by the validation as well as the UI
        % widgets.
        Inclusive (1,2) logical
        
        % ShapeCheck - validator for shape
        ShapeCheck        
    end
    
    properties(Access=protected)
        % Property that holds a handle to the local/stateless function that
        % actually performs the checking.
        % NOTE: making the function stateless to avoid reference cycles
        % back to this class.
        CheckFcn
    end

    % Comparator function handles
    % These are here to simplify the validate() function. The logic is
    % worked out 1x in the constructor and then these functions are called
    % for each call to validate().
    properties(Access=private)
        % LowerComp - comparator for lower limit
        LowerComp
        % UpperComp - comparator for lower limit
        UpperComp
    end
    
    methods
        % Constructor
        function this = NumericType(shp,limits,inclusive,label,category)
           
            if inclusive(1)
                if ~isinf(limits(1))
                    lowerComp = @(x) x >= limits(1);
                else
                    lowerComp = @(x) true;
                end
            else
                lowerComp = @(x) x > limits(1);
            end
            if inclusive(2)
                if ~isinf(limits(2))
                    upperComp = @(x) x <= limits(2);
                else
                    upperComp = @(x) true;
                end
            else
                upperComp = @(x) x < limits(2);
            end

            this.Shape = shp;
            if strcmp(shp,'scalar')
                shapeCheck = @isscalar;
                widget = 'matlab.ui.control.NumericEditField';
                widgetData = {'HorizontalAlignment', 'left', ...
                    'Limits', limits, ...
                    'LowerLimitInclusive', inclusive(1), ...
                    'UpperLimitInclusive', inclusive(2)};
            else
                switch shp
                    case 'vector'
                        shapeCheck = @isvector;
                    case 'matrix'
                        shapeCheck = @ismatrix;
                    case 'range'
                        shapeCheck = @(x)ismatrix(x) && size(x,1) == 2;
                    otherwise
                        shapeCheck = @(x)true;
                end

                widget = 'matlab.ui.control.internal.model.WorkspaceDropDown';
                % NOTE: re-making the anonymous function here to avoid
                % creating a reference cycle to/from this class and the
                % Widget callback.
                widgetData = {'UseDefaultAsPlaceholder', true, ...
                    'FilterVariablesFcn',@(v)localNumericCheck(lowerComp,upperComp,shapeCheck,v)};
            end
            
            % Populate class members 
            this.CheckFcn = @(v)localNumericCheck(lowerComp,upperComp,shapeCheck,v);
            this.Limits = limits;
            this.Inclusive = inclusive;
            this.LowerComp = lowerComp;
            this.UpperComp = upperComp;
            this.ShapeCheck = shapeCheck;
            this.DisplayLabel = label;
            this.Category = category;
            this.Widget = widget;
            this.WidgetData = widgetData;
        end
        
        % validate - The function that validates a given value against the
        % type information baked into the class.
        function [value,isOK,errid,errmsg] = validate(this,name,value)
            errid = ''; errmsg = '';
            % Check value
            isOK = this.CheckFcn(value);
            if ~isOK
                % Call error handling
                [errid,errmsg] = this.handleError(name);
            else
                value = double(value);
            end
        end
    end
    
    methods(Access = private)
        % Error handler
        function [errid,errmsg] = handleError(this,name)
            % Local copy
            limits = this.Limits;
            % Convert to string for message
            limitStrs = {num2str(limits(1),'%-6.3g'), num2str(limits(2),'%-6.3g')};
            if strcmp(this.Shape,'scalar')
                if all(this.Inclusive)
                    errid = 'optim:options:meta:NumericType:validate:InvalidNumericType';
                    msgid = 'MATLAB:optimfun:options:meta:validation:NotAScalarDoubleRange';
                else
                    errid = 'optim:options:meta:NumericType:validate:InvalidNumericType';
                    if this.Inclusive(1)
                        msgid = 'MATLAB:optimfun:options:meta:validation:NotAScalarRightOpenRange';
                    elseif this.Inclusive(2)
                        msgid = 'MATLAB:optimfun:options:meta:validation:NotAScalarLeftOpenRange';
                    else
                        msgid = 'MATLAB:optimfun:options:checkfield:notInAnOpenRangeReal';
                    end
                end
            elseif strcmp(this.Shape,'vector')
                errid = 'optim:options:meta:NumericType:validate:InvalidNumericVectorType';
                msgid = 'MATLAB:optimfun:options:meta:validation:NotAVectorDoubleRange';
            elseif strcmp(this.Shape,'matrix')
                if all(this.Inclusive)
                    errid = 'optim:options:meta:NumericType:validate:InvalidNumericMatrixType';
                    msgid = 'MATLAB:optimfun:options:meta:validation:NotAMatrixDoubleRange';
                else
                    limitStrs = {};
                    if all(isinf(limits))
                        errid = 'optim:options:meta:NumericType:validate:InvalidMatrixType';
                        msgid = 'MATLAB:optimfun:optimoptioncheckfield:notAMatrix';
                    elseif limits(1) == 0 && isinf(limits(2))
                        % Check for positive?
                        errid = 'optim:options:meta:NumericType:validate:InvalidPosMatrixType';
                        msgid = 'MATLAB:optimfun:optimoptioncheckfield:notAPosMatrix';
                    end
                end
            elseif strcmp(this.Shape,'range')
                errid = 'optim:options:meta:NumericType:validate:InvalidRangeType';
                msgid = 'MATLAB:optimfun:options:checkfield:notARange';
                limitStrs = {};
            else % array
                errid = 'optim:options:meta:NumericType:validate:InvalidPosMatrixType';
                msgid = 'MATLAB:optimfun:optimoptioncheckfield:notAPosMatrix';
                limitStrs = {};
            end
            errmsg = getString(message(msgid, name, limitStrs{:}));
        end % function handleError()
    end % Private methods
    
end

% Function that does the checking action
function isOK = localNumericCheck(lowerBndComp,upperBndComp,shapeCheck,value)
isOK = ~isempty(value) && isreal(value) && isnumeric(value) && shapeCheck(value) && ...
    all(lowerBndComp(value),'all') && all(upperBndComp(value),'all');
end