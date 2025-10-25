classdef basicDictionaryType < coder.type.Base
%MATLAB Code Generation Private Class


%   Copyright 2023 The MathWorks, Inc.

properties
    keys
    values
    written
    allocatedSZ
    usedSZ
    first
    last
    next
    prev
end


methods (Access=protected)
    function obj = initialize(obj, ~)
        if ~strcmp(obj.keys.ClassName, 'cell')
            %this is an empty basicDictionary, used in newtype
            %let it slide
            return
        end
        if strcmp(obj.keys.Cells{1}.ClassName, 'string')
            stringType = coder.typeof("");
            stringType.StringLength = Inf;
            obj.keys = coder.typeof({stringType}, [1,Inf]);
        else
            obj.keys = coder.typeof(obj.keys, [1, Inf]);
        end
        if strcmp(obj.values.Cells{1}.ClassName, 'string')
            stringType = coder.typeof("");
            stringType.StringLength = Inf;
            obj.values = coder.typeof({stringType}, [1,Inf]);
        else
            obj.values = coder.typeof(obj.values, [1, Inf]);
        end        
        obj.written = coder.typeof(obj.written, [1, Inf]);
        obj.next = coder.typeof(obj.next, [1, Inf]);
        obj.prev = coder.typeof(obj.prev, [1, Inf]);
    end
end

end
