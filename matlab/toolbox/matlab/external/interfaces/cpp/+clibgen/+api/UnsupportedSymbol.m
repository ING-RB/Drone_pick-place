classdef UnsupportedSymbol < handle
    properties(GetAccess=public, SetAccess=private)
        Reason          string
        FilePath        string
    end
    methods
        function obj = UnsupportedSymbol(fileName, filePath, lineNum, reason)
            obj.Reason = strtrim(reason);
            if matlab.internal.display.isHot
                text = '<a href="matlab:opentoline(''%s'',%s)">%s</a>';
                obj.FilePath = sprintf(text, fileName, lineNum, fileName + ":"+ lineNum);
            else
                text = "%s:%s";
                obj.FilePath = sprintf(text, fileName, lineNum);
            end
        end
    end
end