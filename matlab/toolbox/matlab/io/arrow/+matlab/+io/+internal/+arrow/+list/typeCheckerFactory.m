function typeChecker = typeCheckerFactory(data)
%TYPECHECKERFACTORY Creates a Typechecker object.

% Copyright 2022 The MathWorks, Inc.

    import matlab.io.internal.arrow.list.ClassTypeChecker
    import matlab.io.internal.arrow.list.CharTypeChecker
    import matlab.io.internal.arrow.list.LogicalTypeChecker
    import matlab.io.internal.arrow.list.NumericTypeChecker
    import matlab.io.internal.arrow.list.DatetimeTypeChecker
    import matlab.io.internal.arrow.list.CategoricalTypeChecker
    import matlab.io.internal.arrow.list.TableTypeChecker
    import matlab.io.internal.arrow.list.TimetableTypeChecker
    import matlab.io.internal.arrow.error.ExceptionType
    import matlab.io.internal.arrow.error.ExceptionFactory

    if isPrimitiveType(data)
        typeChecker = ClassTypeChecker(class(data));
    elseif isnumeric(data)
        typeChecker = NumericTypeChecker(class(data));
    elseif islogical(data)
        typeChecker = LogicalTypeChecker();
    elseif ischar(data)
        typeChecker = CharTypeChecker(Width=size(data, 2));
    elseif isdatetime(data)
        typeChecker = DatetimeTypeChecker(HasTimeZone=~isempty(data.TimeZone));
    elseif iscategorical(data)
        typeChecker = CategoricalTypeChecker(IsOrdinal=isordinal(data), Categories=categories(data));
    elseif istable(data)
        typeChecker = TableTypeChecker.build(data);
    elseif istimetable(data)
        typeChecker = TimetableTypeChecker.build(data);
    else
        exceptionType = ExceptionType.InvalidDataType;
        ExceptionFactory.throw(exceptionType, class(data));
    end
end

function tf = isPrimitiveType(data)
    tf = isstring(data)   || ...
         isduration(data) || ...
         iscell(data);
end
