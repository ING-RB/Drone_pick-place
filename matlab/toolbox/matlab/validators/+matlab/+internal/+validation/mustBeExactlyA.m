function mustBeExactlyA(A,C)
%MUSTBEEXACTLYA Validate that value comes from one of the specified classes
%   MUSTBEEXACTLYA(A,C) compares A with a list of class names in C and throws an
%   error if the class of A is not exactly one of the classes. 
%   C can be a string array, a character vector, or a cell array of character vectors.
%
%   MATLAB uses class relationships to determine if A is an object of a class.
%
%   Class support:
%   All MATLAB classes
%
%   Copyright 2020-2024 The MathWorks, Inc.

    arguments
        A
        C {mustBeNonzeroLengthTextOrClassID}
    end
    
    % empty C, including {} and empty string, makes any value valid
    if isempty(C)
        return;
    end

    if isa(C, "classID")
        if any(C == classID(A), "all")
            return;
        end
    else
        C = string(C);
        if matlab.internal.validation.ExecutionContextWrapper.hasPackagesFeature
            % MCOS-8653
            callerContextWrapper = matlab.internal.validation.ExecutionContextWrapper(matlab.lang.internal.ExecutionContext.caller);
            %ctxt = matlab.lang.internal.ExecutionContext.caller;
            %itxt = introspectionContext(ctxt);
            classid_a = classID(A);
            for i=1:numel(C)
                classid_c = callerContextWrapper.resolveClass(C(i));
                if classid_a == classid_c
                    return;
                end
            end
        else
            if any(strcmp(class(A), C),"all")
                return;
            end
        end
    end

    if numel(C) <= 6
        msgIDs = [...
                "MATLAB:validators:OneType",...
                "MATLAB:validators:TwoTypes",...
                "MATLAB:validators:ThreeTypes",...
                "MATLAB:validators:FourTypes",...
                "MATLAB:validators:FiveTypes",...
                "MATLAB:validators:SixTypes"...
                ];
        messageObject = message(msgIDs(numel(C)), C{1:end});
        throwAsCaller(MException(message('MATLAB:validators:mustBeExactlyA', messageObject.getString)));
    else
        formattedList = matlab.internal.validation.util.createPrintableList(C);
        throwAsCaller(MException(message('MATLAB:validators:mustBeExactlyA', formattedList)));
    end
end

function mustBeNonzeroLengthTextOrClassID(classes)
    if isa(classes, "classID")
        return;
    end

    if matlab.internal.validation.util.isNontrivialText(classes)
        return;
    end

    throwAsCaller(MException(message('MATLAB:validators:mustBeNonzeroLengthTextOrClassID')));
end



% LocalWords:  validators
