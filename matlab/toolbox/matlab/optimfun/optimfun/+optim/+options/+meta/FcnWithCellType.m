classdef FcnWithCellType < optim.options.meta.FcnType
%

%FcnWithCellType metadata for any function option that can also be a
%collection of functions in a cell or a function and other data in a cell.
%
% FcnWithCellType extends optim.options.meta.FcnType.
%
% See also OPTIM.OPTIONS.META.FCNTYPE, OPTIM.OPTIONS.META.FACTORY

%   Copyright 2019-2022 The MathWorks, Inc.

    methods
        % Constructor
        function this = FcnWithCellType(label,category,varargin)
            this = this@optim.options.meta.FcnType(label,category,varargin{:});
            if isempty(this.Values)
                this.Widget = 'matlab.ui.control.EditField';
                this.WidgetData = {};
            else
                this.Widget = 'matlab.ui.control.DropDown';
                this.WidgetData = {'Items', ['[]', this.Values]};
            end
        end
        
        % validate - The function that validates a given value against the
        % type information baked into the class. 
        function [value,isOK,errid,errmsg] = validate(this,name,value)
            
            % First check for a valid FcnType
            [newvalue,isOK,errid,errmsg] = validate@optim.options.meta.FcnType(this,name,value);
            
            if isOK % Valid FcnType - return
                value = newvalue;
            elseif iscell(value)
                if isempty(value) || ~this.CheckAgainstValues
                    isOK = true;
                    value = newvalue;
                    errid = '';
                    errmsg = '';
                else
                    % Check that cell array elements are valid
                    [isOK,errid,errmsg] = this.checkCellArrayElements(name,value);
                end
                % Note for the (~iscell(value) and invalid FcnType) case,
                % use the errid/errmsg returned from the call to
                % FcnType/validate
            end
        end
    end

    methods (Access = protected)

        function [isOK,errid,errmsg] = checkCellArrayElements(this,name,value)

            % Check that the first cell of value is a member of this.Values
            [isOK,errid,errmsg] = this.checkMemberOfValues(name,value{1});

            % Subclasses can extend this method as necessary
        end
    end
end