classdef ValidationHelper
%

% Copyright 2020-2024 The MathWorks, Inc.

    methods
        function H = ValidationHelper(validation)
            if isstruct(validation)
                %% PKG TODO:MCOS-8656 We either add a ResolvedClassName in the type struct or we manipulate the struct in C++ code to add a field when we retrieve the type struct.
                H.ClassName = validation.class;

                if feature("packages")
                    H.Context = validation.context;
                end

                if isempty(validation.dimensions)
                    H.CodedSize = [];
                else
                    H.CodedSize = GetCodedDimensions(validation.dimensions);
                end
                H.Functions = validation.validators;
            elseif isa(validation, "matlab.metadata.Validation")
                if isempty(validation.Class)
                    H.ClassName = '';
                else
                    H.ClassName = validation.Class.Name;
                end

                if feature("packages")
                    H.Context = validation.Context;
                end

                if isempty(validation.Size)
                    H.CodedSize = [];
                else
                    H.CodedSize = GetCodedSize(validation.Size);
                end
                H.Functions = validation.ValidatorFunctions;
            end
        end
    end

    methods
        function [value, ex] = validateClass(H, value)
            % PKG TODO: MCOS-8655 retrofit _convert_to_class to accept an ExecutionContext.
            ex = [];
            className = H.ClassName;
            if isempty(className)
                return;
            end

            if ~isa(value, className)
                try
                    if feature("packages")
                        value = builtin('_convert_to_class', className, value, H.Context);
                    else
                        value = builtin('_convert_to_class', className, value);
                    end
                catch me
                    msg = message('MATLAB:type:PropSetClsMismatch', className);
                    ex = MException('MATLAB:validation:UnableToConvert', msg.getString);
                end
            end
        end

        % g1984150 TODO: Remove this workaround and change the call site to use validateClass.
        function [value, ex] = validateClassForDataTypeUseCase(H, value)
            ex = [];
            className = H.ClassName;
            if isempty(className) || isa(value, className)
                return;
            end

            try
                if strcmp(className, "matlab.graphics.illustration.legend.Text") && isempty(value) && isa(value, "matlab.graphics.GraphicsPlaceholder")
                    value = matlab.graphics.illustration.legend.Text.empty;
                else
                    % PKG TODO: retrofict _convert_to_class to take an ExecutionContext
                    if feature("packages")
                        value = builtin('_convert_to_class', className, value, H.Context);
                    else
                        value = builtin('_convert_to_class', className, value);
                    end
                end
            catch me
                msg = message('MATLAB:type:PropSetClsMismatch', className);
                ex = MException('MATLAB:validation:UnableToConvert', msg.getString);
            end
        end

        function [value, ex] = validateSize(H, value)
            ex = [];
            if isempty(H.CodedSize)
                return;
            end

            try
                sz = H.CodedSize;
                if matlab.lang.internal.isMatchingSize(size(value), sz)
                    return;
                elseif hasZeroOrUnfixedDimension(sz) && isequal(size(value),[0,0])
                    indices = char(GetDimensions(sz));
                    if isa(value, 'function_handle')
                        eval(['value=' 'function_handle.empty(' indices ');']);
                    else
                        eval(['value=' 'reshape(value,' indices ');']);
                    end
                else
                    indices = char(GetSubscripts(sz));

                    % This is equivalent to doing something like:
                    %    temp(1:1, 1:2) = value; value = temp;
                    % Check out g3393252 for why we do this.
                    eval(['a_temp_variable' indices '=value; value=a_temp_variable;']);
                end
            catch me
                msgString = matlab.internal.validation.Exception.getSizeSpecificMessage(me,GetSizeStruct(sz));
                ex = MException('MATLAB:validation:IncompatibleSize', msgString);
            end
        end

        function ex = validateUsingValidationFunctions(H, value)
            ex = [];
            vfcns = H.Functions;
            for i=1:numel(vfcns)
                fcn = vfcns{i};
                try
                    fcn(value);
                catch ex
                    ex = checkForDependencyError(ex,fcn);
                    return;
                end
            end
        end
    end

    properties
        ClassName
        Context
        CodedSize
        Functions
    end
end

% Special error checking for value dependency.
% Example of a dependency error:
%       arguments
%           x
%           y {mustBeGreaterThan(y,x)}
%       end
%
% This incurs a value dependency error because mustBeGreaterThan depends on x.
% This error is checkable because the FE generated function handles for the
% dependency cases are always anonymous function handle, e.g.,
%       @(y,x)mustBeGreaterThan(y,x)
% So a single nargin check is sufficient.
%
% Return the same exception if it is not a dependency error.
function ex = checkForDependencyError(ex, fcn)
    arguments
        ex (1,1) {mustBeA(ex, "MException")}
        fcn (1,1) {mustBeA(fcn, "function_handle")}
    end

    % If ex is not a minrhs error, it cannot be a dependency error.
    if ~strcmp(ex.identifier,"MATLAB:minrhs")
        return;
    end

    % The dependency error only makes sense if the function handle
    % is anonymous.
    fcns = functions(fcn);
    if strcmp(fcns.type , 'anonymous') && nargin(fcn) > 1
        errorID = 'MATLAB:function_metadata:ValidateDependencyNotSupported';
        ex = MException(errorID,message(errorID));
    end
end

% Use a local isprop because the shipping isprop is slow and using it introduces a
% dependency on matlab_toolbox_datatypes.
function tf = isprop(obj, propName)
    tf = any(strcmp(properties(obj), propName));
end

function S = GetSizeStruct(sz)
% Returns a struct which represents the dimensions from coded size.
% The returned value is suitable as input to create size specific error message.
% E.g. (2,-1) => struct("dim", {2,'*'});
    S = struct;
    for i=1:numel(sz)
        if sz(i) == -1
            S(i).dim = '*';
        else
            S(i).dim = sz(i);
        end
    end
end

function indices = GetSubscripts(sz)
% Returns a string which represents the subscript indices from coded size.
% The returned value is suitable to be used by subscripted assignments.
% E.g. [2,-1] => "(1:2, :)"
    indices = "";
    for i=1:numel(sz)
        if sz(i) == -1
            indices(i) = ":";
        else
            indices(i) = "1:" + string(sz(i));
        end
    end

    indices = join(indices, ',');
    indices = "(" + indices + ")";
end


function indices = GetDimensions(sz)
% Returns a string which represents the dimensions from coded size.
% The returned value is suitable as inputs to reshape to create different sizes of empty arrays.
% E.g. (2,:) => "(2, 0)"
    indices = "";
    for i=1:numel(sz)
        if sz(i) == -1
            indices(i) = 0;
        else
            indices(i) = string(sz(i));
        end
    end

    indices = join(indices, ',');
end

function codedSize = GetCodedSize(sz)
% Returns a coded size vector from meta.ArrayDimension.
% The returned value is suitable to check if an array's size matched the declared size.
% E.g. (2,:) => (2, -1)
    if isempty(sz)
        codedSize = [];
        return;
    end
    codedSize = zeros(size(sz));

    for i=1:numel(sz)
        szi = sz(i);
        if isa(szi, 'matlab.metadata.FixedDimension')
            codedSize(i) = double(szi.Length);
        elseif isa(szi, 'matlab.metadata.UnrestrictedDimension')
            codedSize(i) = -1;
        end
    end
end

function codedSize = GetCodedDimensions(sz)
% Returns a coded size vector from a cell array represent size.
% The returned value is suitable to check if an array's size matched the declared size.
% E.g. (2,:) => (2, -1)
    codedSize = zeros(size(sz));
    if isempty(sz)
        codedSize = [];
    else
        for i = 1:numel(sz)
            if isa(sz{i}, 'char')
                codedSize(i) = -1;
            else
                codedSize(i) = double(sz{i});
            end
        end
    end
end

function tf = isScalarSize(sz)
    for i=1:numel(sz)
        if sz(i) ~= 1
            tf = false;
            return;
        end
    end
    tf = true;
end

function tf = isFixedSize(sz)
    for i=1:numel(sz)
        if sz(i) == -1
            tf = false;
            return;
        end
    end
    tf = true;
end

function tf = hasZeroOrUnfixedDimension(sz)
% Return true if the dimension has : or 0 in it.
    for i=1:numel(sz)
        if sz(i) == 0 || sz(i) == -1
            tf = true;
            return;
        end
    end
    tf = false;
end
