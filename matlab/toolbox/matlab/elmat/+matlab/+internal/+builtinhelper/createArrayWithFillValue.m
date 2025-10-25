function obj = createArrayWithFillValue(varargin)
%createArrayWithFillValue  Use fill value to create array of specified size
%   This function provides support for classes that redefine parenAssign and other special cases.
%   It should only be called from the builtin createArray function.

% Arguments:
% ----------
% * dims:              2/more size inputs for output array
% * fillValue:         Prototype/fill value to create the array.
% * convertToValue:    If convertFillValue is true, convert fillValue to be like this value
% * numElements:       Number of elements in output array
% * Logical flags:
%   1. valueFromCaller:        Is fillValue from the caller or was it created
%   2. applyFillValue:         Should fillValue be applied or used as a prototype
%   3. convertFillValue:       Must fill value be converted before being applied
%   4. classIsScalar:          Is target class scalar
%   5. customParenAssign:      Does target class redefine parenAssign
%   6. fillValueCopyable:      Does class of fillValue define copy method
%   7. convertToValueCopyable: Does class of convertToValue define copy method

% Copyright 2023 The MathWorks, Inc.

narginchk(6, Inf);

dims                   = varargin(1:end-4);
fillValue              = varargin{end-3};
convertToValue         = varargin{end-2};
numElements            = varargin{end-1};
valueFromCaller        = varargin{end}(1);
applyFillValue         = varargin{end}(2);
convertFillValue       = varargin{end}(3);
classIsScalar          = varargin{end}(4);
customParenAssign      = varargin{end}(5);
fillValueCopyable      = varargin{end}(6);
convertToValueCopyable = varargin{end}(7);

try
    % Convert fillValue to be like the prototype if both are specified
    if convertFillValue
        convertToValueFromCaller = true;
        assert(valueFromCaller);

        try
            % Create empty array with same properties as convertToValue
            temp = firstElementOf(convertToValue, convertToValueFromCaller);
            temp = createViaParenAssign(temp);
        catch e
            % Call constructor to report error about invalid fill value
            feval(class(convertToValue), fillValue);
            % Otherwise report error from index assignment
            rethrow(e);
        end

        try
            % Assign fill value to convert it to be like the convertToValue
            temp(1) = createCopy(fillValue, valueFromCaller, fillValueCopyable);
        catch e
            % Try calling the constructor if parenAssign fails
            rhs = feval(class(convertToValue), fillValue);

            if isscalar(rhs)
                % Constructor supports inputs that are not supported by parenAssign
                rethrow(e);
            elseif isequal(class(fillValue), class(convertToValue))
                error(message('MATLAB:createArray:invalidFillValue'));
            else
                error(message('MATLAB:createArray:invalidFillValueForClass', class(convertToValue)));
            end
        end

        temp      = preserveSparsity(temp, convertToValue);
        fillValue = preserveComplexity(temp, convertToValue);
        fillValueCopyable = convertToValueCopyable;
        valueFromCaller = false;
        clear temp;
    end

    % Check size of specified/converted fill value
    if applyFillValue && ~isscalar(fillValue)
        if valueFromCaller
            error(message('MATLAB:createArray:invalidFillValue'));
        else
            error(message('MATLAB:createArray:invalidFillValueForClass', class(fillValue)));
        end
    end

    if numElements == 0
        % Create empty array of the correct size.
        try
            obj = firstElementOf(fillValue, valueFromCaller);
            obj = createViaParenAssign(obj);
            obj = reshape(obj, dims{:});
        catch
            obj = feval([class(fillValue), '.empty'], dims{:});
        end

        if issparse(fillValue) && ~issparse(obj)
            obj = sparse(obj);
        end

        obj = preserveComplexity(obj, fillValue);

        return
    end

    if applyFillValue
        if customParenAssign
            % Use repmat, even if class is copyable.
            if convertFillValue
                % Fill value has already been copied
                assert(~valueFromCaller);
            else
                % Create copy to prevent modifying original handle object.
                temp = createCopy(fillValue, valueFromCaller, fillValueCopyable);

                % Create new fillValue via index assignment to preserve custom indexing behavior.
                temp      = createViaParenAssign(temp, {1});
                temp      = preserveSparsity(temp, fillValue);
                fillValue = preserveComplexity(temp, fillValue);
                valueFromCaller = false;
                clear temp;
            end
        elseif fillValueCopyable
            obj = createArrayWithCopies(fillValue, valueFromCaller, fillValueCopyable, numElements, dims);
            return
        end

        if numElements == 1
            obj = fillValue;
        else
            obj = repmat(fillValue, dims{:});

            % If repmat created multiple references, try make copies
            if isHandleObject(obj) && (numel(obj) > 1) && any(fillValue == obj(2:end), 'all')
                obj = createArrayWithCopies(fillValue, valueFromCaller, fillValueCopyable, numElements, dims);
            end

            obj = preserveComplexity(obj, fillValue);
        end

        checkForHandleReferences(obj, fillValue, valueFromCaller, fillValueCopyable);

        return
    end

    % Create scalar prototype value from fillValue
    if isscalar(fillValue)
        prototype = fillValue;
    elseif isempty(fillValue)
        try
            % Try calling ClassName.createArray([1 1])
            defaultValue = feval([class(fillValue), '.createArray'], [1 1]);
        catch e
            try
                % Try calling the default constructor
                defaultValue = feval(class(fillValue));
            catch e
                e = addCause(MException(message('MATLAB:createArray:invalidDefaultConstructor', ...
                                                class(fillValue))), e);
                throw(e);
            end
        end

        if ~isscalar(defaultValue)
            error(message('MATLAB:createArray:invalidDefaultConstructor', class(fillValue)));
        end

        % Convert scalar defaultValue to be like the original fillValue
        prototype = createArray(Like = fillValue, FillValue = defaultValue);
    else
        % Use first element of fillValue
        [prototype, valueFromCaller] = firstElementOf(fillValue, valueFromCaller);
        prototype = preserveComplexity(prototype, fillValue);
    end

    % SPECIAL CASES:
    if classIsScalar
        % Call default constructor
        assert(numElements == 1); % Should error in C++
        obj = feval(class(prototype));

        if ~isscalar(obj)
            error(message('MATLAB:createArray:invalidDefaultConstructor', class(prototype)));
        end

        obj = preserveComplexity(obj, prototype);

        return
    end

    if isOldObject(prototype)
        % For old objects, call default constructor for each element.
        className = class(prototype);
        prototype = feval(className);

        if ~isscalar(prototype)
            error(message('MATLAB:createArray:invalidDefaultConstructor', className));
        end

        obj(dims{:}) = prototype;

        for idx = 1:(numel(obj)-1)
            obj(idx) = feval(className);
        end

        obj = preserveComplexity(obj, prototype);

        return
    end

    if customParenAssign
        % Use array indexing to get default value
    elseif fillValueCopyable
        obj = createArrayWithCopies(prototype, valueFromCaller, fillValueCopyable, numElements, dims);
        return;
    end

    % Use index assignment to create array with default values
    if numElements == 1
        % Create 2-element array with prototype in 2nd element
        % (parenAssign will put default value in first element)
        obj = createViaParenAssign(prototype, {2,1});

        % Just use first element
        obj = obj(1,1);
    elseif isHandleObject(prototype) && ~fillValueCopyable
        % Create column vector with prototype in element N+1
        % (parenAssign will put default value in first N elements)
        obj = createViaParenAssign(prototype, {numElements+1, 1});

        % Delete last element and reshape to correct size
        obj(end) = [];
        obj = reshape(obj, dims{:});
    else
        % Create array and copy first element to last element
        obj = createViaParenAssign(prototype, dims);
        obj(end) = createCopy(obj(1,1), true, fillValueCopyable);
    end

    obj = preserveSparsity(obj, prototype);
    obj = preserveComplexity(obj, prototype);

    checkForHandleReferences(obj, prototype, valueFromCaller, fillValueCopyable);

catch e
    % Throw error as caller to hide helper function
    assert(~isempty(e.stack), "Expected to at least see helper function on the stack");
    if strcmp(e.stack(1).file, which('matlab.internal.builtinhelper.createArrayWithFillValue'))
        % Error originated in the helper function
    else
        % Create new error to preserve call stack
        e = addCause(MException(message('MATLAB:createArray:genericError')), e);
    end
    throwAsCaller(e);
end

end % function

function obj = createViaParenAssign(fillValue, dims)
% Create new array via index assignment (parenAssign)
    arguments
        fillValue
        dims = {1:0};
    end

    try
        obj(dims{:}) = fillValue;
    catch e
        e = addCause(MException(message('MATLAB:createArray:parenAssignError', class(fillValue))), ...
                     MException(e.identifier, e.message));
        throwAsCaller(e);
    end

    if isHandleObject(fillValue) && (numel(obj) > 1) && any(obj(1:end-1) == fillValue, 'all')
        error(message('MATLAB:createArray:parenAssignReturnsRef', class(fillValue)));
    end
end

function result = isHandleObject(obj)
% Check if object is an instance of a class that is copyable
    result = isa(obj, 'handle');
    if result && isa(obj, 'handle.handle')
        hClass = classhandle(obj);
        result = strcmp(hClass.Handle, 'on');
    end
end

function result = isOldObject(obj)
% Check if object is an instance of an old class
    result = isempty(metaclass(obj));
end

function [obj, valueFromCaller] = firstElementOf(fillValue, valueFromCaller)
% Get first element if fillValue is an array.  Otherwise just return the fillValue.
    if numel(fillValue) > 1
        obj = fillValue(1);

        if metaclass(obj) ~= metaclass(fillValue)
            error(message('MATLAB:createArray:subsrefChangesClass', class(fillValue), class(obj)));
        end

        if ~isscalar(obj)
            error(message('MATLAB:createArray:subsrefReturnsNonScalar', class(fillValue)));
        end

        if isHandleObject(obj)
            if all(obj ~= fillValue, 'all')
                valueFromCaller = false;
            end
        else
            valueFromCaller = false;
        end
    else
        obj = fillValue;
    end
end

function obj = createCopy(fillValue, valueFromCaller, fillValueCopyable)
% Create copy of fillValue and check for handle references.
% If fillValue is not copyable, try calling the constructor.
    obj = fillValue;

    if valueFromCaller && isHandleObject(fillValue)
        if fillValueCopyable
            obj = copy(fillValue);
        else
            % Call constructor to create a copy
            try
                obj = feval(class(fillValue), fillValue);
            catch e
                error(message('MATLAB:createArray:handleClassNotCopyable', class(fillValue)));
            end
        end
        checkForHandleReferences(obj, fillValue, valueFromCaller, fillValueCopyable);
    end
end

function obj = createArrayWithCopies(fillValue, valueFromCaller, fillValueCopyable, numElements, dims)
% Create array with copies of fillValue and check for handle references.
    obj = createCopy(fillValue, valueFromCaller, fillValueCopyable);

    if numElements > 1
        for idx = 2:numElements
            obj(idx) = createCopy(fillValue, true, fillValueCopyable);
        end
        obj = reshape(obj, dims{:});
    end
end

function checkForHandleReferences(obj, fillValue, valueFromCaller, fillValueCopyable)
    if isHandleObject(fillValue)
        if ((valueFromCaller  && any(obj    == fillValue,  'all')) || ...
            ((numel(obj) > 1) && any(obj(1) == obj(2:end), 'all')))
            % Multiple references to same object
            if fillValueCopyable
                error(message('MATLAB:createArray:handleClassCopyReturnsRef', ...
                              class(fillValue)));
            else
                error(message('MATLAB:createArray:handleClassNotCopyable', ...
                              class(fillValue)));
            end
        end
    end
end

function obj = preserveComplexity(obj, fillValue)
    if (isnumeric(fillValue) && ~isreal(fillValue) && isreal(obj))
        obj = complex(obj);
    end
end

function obj = preserveSparsity(obj, fillValue)
    if issparse(fillValue) && ~issparse(obj)
        obj = sparse(obj);
    elseif issparse(obj) && ~issparse(fillValue)
        obj = full(obj);
    end
end

% LocalWords: sn builtinhelper
