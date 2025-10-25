classdef TypeDetection
% Type Detection Helper Class

% Copyright 2020 The MathWorks, Inc.

    properties (Constant)
        % Enums for TypeIDs.
        TypeID = getEnums();
        % Here '' represent non-types like Blank and Error
        Typenames = {'double','char','datetime','logical','','','','duration','hexadecimal','binary'};
    end
    
    methods (Static)
        function emptyType = getEmptyType(ect)
            import matlab.io.internal.TypeDetection;
            if ~isempty(ect) && strcmp(ect,'double')
                emptyType = TypeDetection.TypeID.NUMBER;
            else
                emptyType = TypeDetection.TypeID.STRING;
            end
        end
        
        function blanks = isBlank(typeIDs)
            import matlab.io.internal.TypeDetection;
            blanks =    (typeIDs == TypeDetection.TypeID.BLANK)|...
                        (typeIDs == TypeDetection.TypeID.ERROR)|...
                        (typeIDs == TypeDetection.TypeID.EMPTY)|...
                        (isnan(typeIDs));
        end
        
        function emptyies = isEmpty(typeIDs)
            import matlab.io.internal.TypeDetection;
            emptyies =  (typeIDs == TypeDetection.TypeID.BLANK)|...
                        (typeIDs == TypeDetection.TypeID.EMPTY);
        end
        
        function text = isText(typeIDs)
            import matlab.io.internal.TypeDetection;
            text =      (typeIDs == TypeDetection.TypeID.STRING);
        end
        
        function names = getTypeName(typeIDs)
            import matlab.io.internal.TypeDetection;
            names = TypeDetection.Typenames(typeIDs);
        end
        
        function ID = getTextTypeID()
            import matlab.io.internal.TypeDetection;
            ID = TypeDetection.TypeID.STRING;
        end
    end
end

function enum = getEnums()
import matlab.io.spreadsheet.internal.Sheet;
enum.NUMBER = matlab.io.spreadsheet.internal.Sheet.NUMBER;
enum.STRING = matlab.io.spreadsheet.internal.Sheet.STRING;
enum.DATETIME = matlab.io.spreadsheet.internal.Sheet.DATETIME;
enum.BOOLEAN = matlab.io.spreadsheet.internal.Sheet.BOOLEAN;
enum.EMPTY = matlab.io.spreadsheet.internal.Sheet.EMPTY;
enum.BLANK = matlab.io.spreadsheet.internal.Sheet.BLANK;
enum.ERROR = matlab.io.spreadsheet.internal.Sheet.ERROR;
% enum.DURATION = matlab.io.spreadsheet.internal.Sheet.DURATION;
end
