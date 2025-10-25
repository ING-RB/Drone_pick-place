function out = invokeBinaryComparison(fcnInfo, varargin)
%invokeBinaryComparison Invokes GE, LT etc.

% Copyright 2016-2022 The MathWorks, Inc.

% This prevents this frame and anything below it being added to the gather
% error stack.
stack = createInvokeStack(fcnInfo.Name);
markerFrame = matlab.bigdata.internal.InternalStackFrame(stack); %#ok<NASGU>

try
    args = invokeInputCheck(fcnInfo, varargin{:});

    % Check if we're comparing a tall array with an in-memory scalar or
    % in-memory char vector. If so, keep track of the small operand used in
    % the comparison and use special primitives for potential row-indexing
    % optimization afterwards. If the small operand is an in-memory char
    % vector, it's coverted to a string scalar to perform an elementwise
    % comparison if the tall array doesn't have a char input.
    [isSmallOperand, smallOperand, isTallFirst, args{:}] = iCheckForValidSmallOperand(args{:});

    % If any input is datetime, duration, string, or categorical and the
    % other input might be a char array then we must treat the operation as
    % slicewise (each row of the char array counts as one element).
    clzs = cellfun(@tall.getClass, args, 'UniformOutput', false);
    mightHaveCharInput = any(cellfun(@isempty, clzs) | strcmp(clzs, "char"));
    treatAsSlicewise = mightHaveCharInput ...
        && any(ismember({'datetime', 'duration', 'string', 'categorical'}, clzs));
    
    fcn = str2func(fcnInfo.Name);
    
    if treatAsSlicewise
        out = slicefun(fcn, args{:});
    else
        if isSmallOperand
            % For now, row-indexing optimization can only be applied to
            % tall arrays created from ParquetDatastore, these can only
            % have string variables. Thus, we can always apply an
            % elementwise operation.
            out = smallTallComparison(fcn, smallOperand, isTallFirst, args{:});
        else
            out = elementfun(fcn, args{:});
        end
    end
    
    out = invokeOutputInfo(fcnInfo, out, args);
catch E
    matlab.bigdata.internal.throw(E);
end
end

function [tf, smallOperand, isTallFirst, arg1, arg2] = iCheckForValidSmallOperand(arg1, arg2)
% Check whether we're comparing a tall array against a "small" operand,
% that is, an in-memory scalar or char vector, and the order of the
% arguments.
% Some restrictions apply, these are restrictions of matlab.io.RowFilter:
% 1. NaNs and missing values are not supported in tabular row optimization.
% 2. Supported datatypes for the small operand: numeric, string, logical,
% datetime, duration scalars, or character vectors. Unsupported datatypes:
% categorical, calendarDuration, table, timetable, cell.
smallOperand = [];
isTallFirst = [];
tf = false;

if istall(arg1)
    if istall(arg2)
        % Comparison between two tall arrays, return.
        return;
    end
    % Convert in-memory char vectors to string scalars to perform
    % elementwise comparisons if possible.
    arg2 = iMaybeConvertToString(arg1, arg2);
    smallOperand = arg2;
    isTallFirst = true;
else
    % Convert in-memory char vectors to string scalars to perform
    % elementwise comparisons if possible.
    arg1 = iMaybeConvertToString(arg2, arg1);
    smallOperand = arg1;
    isTallFirst = false;
end

% Check for RowFilter restrictions.
isNonMissingScalar = isscalar(smallOperand) && ~ismissing(smallOperand);
allAllowedTypes = matlab.bigdata.internal.adaptors.getAllowedTypes();
unsupportedSmallTypes = ["calendarDuration" "categorical" "table" "timetable" "cell"];
supportedSmallTypes = setdiff(allAllowedTypes, unsupportedSmallTypes);
isSupportedSmallType = ismember(class(smallOperand), supportedSmallTypes);
tf = isNonMissingScalar && isSupportedSmallType;

end

function smallArg = iMaybeConvertToString(tallArg, smallArg)
tallArgClass = tall.getClass(tallArg);
tallArgMightBeChar = strcmp(tallArgClass, 'char') || isempty(tallArgClass);
if (ischar(smallArg) && isrow(smallArg)) && ~tallArgMightBeChar
    smallArg = string(smallArg);
end
end
