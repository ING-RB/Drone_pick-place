classdef EnumWithCellType < optim.options.meta.EnumType
%

%EnumWithCellType combination enum with combo cell & other type
%
% This is a composite class. It subclasses EnumType so that it appears to
% be a EnumType (i.e. isa( . , 'EnumType') = true ). Therefore, this type
% is for options where it is desired that the documented behavior is
% accepting string values, but can also accept a cell with enum and another
% type specified by the caller.
%
% ECT = EnumWithCellType(values,othertype,indicator,label,category)
% constructs a EnumWithCellType with the given label and category. Valid
% values must be an exact match of one of the character arrays in the cell
% array input "values" or a cell array whose 1st element is a match of
% values{indicator} and the whose 2nd element must be a valid value for
% othertype (which must be an instance of optim.options.meta.OptionType).
%
% Example: 
% Make an EnumWithCellType for SubproblemAlgorithm. The cell should only be
% valid when SubproblemAlgorithm is 'ldl-factorization' and then it should
% accept its pivot tolerance.
%
%    import optim.options.meta.* 
%    pivtol = ToleranceType('Pivot tolerance');
%    subprobAlg = EnumWithCellType({'cg','direct','ldl-factorization'}, ...
%                           pivtol,[false false true],'Subproblem
%                           Algorithm','Algorithm settings');
%
% EnumWithCellType extends optim.options.meta.EnumType.
%
% See also OPTIM.OPTIONS.META.OPTIONTYPE, OPTIM.OPTIONS.META.ENUMTYPE

%   Copyright 2019-2022 The MathWorks, Inc.

    properties(Access = private)
        % For added validation
        OtherType % optim.options.meta.OptionType;
        
        % ValidCellEnum the subset of the base class values
        % (EnumType.Values) that are permitted for cell array inputs
        ValidCellEnum % cellstr

        % Type for custom error id/message about cell syntax. This depends
        % on the OtherType properties (positive integer, positive real, etc).
        % Default to the most common use-case here (PosInteger for lbfgs),
        % but override in constructor if necessary. See validate() method
        % for how this property is used dynamically to form the cell syntax
        % msgid and errid.
        CellErrorType = 'PosInteger';
    end
    
    methods
        function this = EnumWithCellType(values,othertype,idx,label,category,cellErrorType)
            % Base-class constructor
            this@optim.options.meta.EnumType(values,label,category);
            % Hold reference to other type
            this.OtherType = othertype;
            % Grab subset of values that are permitted for cell inputs
            this.ValidCellEnum = values(idx);
            % If passed, set CellErrorMessage
            if nargin > 5
                this.CellErrorType = cellErrorType;
            end
        end
    end
    
    methods
        function [value, isOK, errid, errmsg] = validate(this,name,value)
            
            % Check the most common case first 
            if ~iscell(value)  
                [value,isOK,errid,errmsg] = validate@optim.options.meta.EnumType(this,name,value);
            else
                % Check cell syntax
                errid = ''; errmsg = '';
                isOK = false; % Assume the worst                
                if numel(value) == 2 && ...  % 2 element cell
                   (ischar(value{1}) || isStringScalar(value{1})) && ... % 1st element is the Enum
                   any(strcmpi(value{1},this.ValidCellEnum))  % Must be from the subset of EnumType.Values
               
                    % Check contents of the 2nd cell against the OtherType
                    [~,isOK] = this.OtherType.validate(name,value{2});
                end
                if ~isOK
                    % Throw custom message about cell syntax. Note, the
                    % message should be in the optimoptioncheckfield
                    % catalog and its entry name should follow the pattern
                    % below. The message should contain one hole for the
                    % valid enum selections.
                    msgid = "MATLAB:optimfun:optimoptioncheckfield:notAString" + ...
                        this.CellErrorType + "CellType";
                    errid = "optim:options:meta:EnumWithCellType:validate:InvalidEnumWith" + ...
                        this.CellErrorType + "CellType";
                    formattedList = optim.options.meta.formatSetOfStrings(this.ValidCellEnum);
                    errmsg = getString(message(msgid,name,formattedList));
                end
            end
        end            
    end
end