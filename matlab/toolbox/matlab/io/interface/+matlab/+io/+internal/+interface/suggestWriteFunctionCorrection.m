function suggestWriteFunctionCorrection(data, writeFunctionName)
%SUGGESTWRITEFUNCTIONCORRECTION Inspect the input arguments passed to a
% given write function, and then suggest a correction ("Did you mean?") if
% the data passed to the write function is supported by another write
% function.

% Copyright 2019-2022 The MathWorks, Inc.

    import matlab.io.internal.interface.isSupportedWriteMatrixType
    if istable(data)
        suggestedWriteFunction = "writetable";
    elseif istimetable(data)
        suggestedWriteFunction = "writetimetable";
    elseif isSupportedWriteMatrixType(data)
        suggestedWriteFunction = "writematrix";
    elseif iscell(data)
        suggestedWriteFunction = "writecell";
    elseif isstruct(data)
        suggestedWriteFunction = "writestruct";
    elseif isa(data, "dictionary")
        suggestedWriteFunction = "writedictionary";
    else
        switch writeFunctionName
            case "writetable"
                msg = message("MATLAB:table:write:FirstArgumentIsTable");
            case "writetimetable"
                msg = message("MATLAB:table:write:FirstArgument", "timetable");
            case "writecell"
                msg = message("MATLAB:table:write:FirstArgument", "cell array");
            case "writestruct" 
                 msg = message("MATLAB:table:write:FirstArgument", "struct");
            case "writedictionary" 
                 msg = message("MATLAB:table:write:FirstArgument", "dictionary");
            case "writematrix"
                inputDataType = "";
                if (issparse(data)); isSparseType = "sparse"; else; isSparseType = ""; end
                if (~isreal(data)); isComplexType = "complex"; else; isComplexType = ""; end
                extraDataTypeInfo = [isSparseType, isComplexType];
                extraDataTypeInfo = extraDataTypeInfo(extraDataTypeInfo~="");
                for dataType = extraDataTypeInfo
                    if ~(inputDataType == "")
                        inputDataType = inputDataType + " ";
                    end
                    inputDataType = inputDataType + dataType;
                end
                if ~isempty(extraDataTypeInfo)
                  inputDataType = "(" + inputDataType + ")";  
                end
                msg = message("MATLAB:table:write:UnsupportedTypeIn", class(data) + inputDataType);
            otherwise
                msg = message("MATLAB:table:write:UnknownWriteFunction", writeFunctionName);
        end
        throwAsCaller(MException(msg));
    end
    
    me = MException(message("MATLAB:table:write:UnsupportedInputType", class(data), suggestedWriteFunction));
    c = matlab.lang.correction.ReplaceIdentifierCorrection(writeFunctionName, suggestedWriteFunction);
    me = addCorrection(me, c);
    throwAsCaller(me);
end
