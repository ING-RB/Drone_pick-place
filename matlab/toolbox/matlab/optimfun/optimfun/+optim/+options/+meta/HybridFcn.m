classdef HybridFcn < optim.options.meta.FcnWithCellType
%

%HybridFcn metadata for hybrid function options.
%
% HybridFcn extends optim.options.meta.FcnWithCellType.
%
% See also OPTIM.OPTIONS.META.FCNWITHCELLTYPE, OPTIM.OPTIONS.META.FACTORY

%   Copyright 2022 The MathWorks, Inc.

    methods
        % Constructor
        function this = HybridFcn(solvers)

            % Call superclass constructor
            label = optim.options.meta.label('HybridFcn');
            category = optim.options.meta.category('Algorithm');
            values = solvers;
            checkValues = true;
            this = this@optim.options.meta.FcnWithCellType(label,category,values,checkValues);
        end
    end

    methods (Access = protected)

        function [isOK,errid,errmsg] = checkCellArrayElements(this,name,value)

            % Call superclass method for default error id and message
            [isOK,errid,errmsg] = checkCellArrayElements@optim.options.meta.FcnWithCellType(this,name,value);
            
            % Cell array input must be of the form {solver, options}, where
            % options is an optimoptions object or optimset struct. Valid solver is
            % already determined by superclass
            isOK = isOK && numel(value) == 2 && (isstruct(value{2}) || isa(value{2}, 'optim.options.SolverOptions'));
            if ~isOK
                errid = 'optim:options:meta:HybridFcn:validate:InvalidHybridFcnCellType';
                msgid = 'MATLAB:optimfun:options:meta:validation:NotAHybridFcnCellType';
                validStrings = optim.options.meta.formatSetOfStrings(this.Values);
                errmsg = getString(message(msgid,validStrings));
            end
        end
    end
end