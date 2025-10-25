classdef FileHandleGuard < handle

    properties (SetAccess = private)
        Filename(1,1) string
        FileID(1,1) double = -1
        ErrorMSG(1,1) string
        Mode(1,1) string
    end

    methods
        function obj = FileHandleGuard(name,mode,ord,encoding)
            arguments
                name(1,1) string
                mode(1,1) string
                ord(1,1) string
                encoding(1,1) string
            end

            obj.Filename = name;
            obj.Mode = mode;
            try
                [obj.FileID,obj.ErrorMSG] = fopen(name,mode,ord,encoding);
            catch ME
                if ME.identifier == "MATLAB:httpsError"
                    error(message("MATLAB:virtualfileio:stream:writeNotAllowed"));
                else
                    throwAsCaller(ME);
                end
            end
        end

        function tf = openSucceeded(obj)
            tf = obj.FileID > -1;
        end

        function delete(obj)
            import matlab.io.text.internal.write.closeAndORDelete
            if (obj.FileID > -1)
                closeAndORDelete(obj.FileID,obj.Filename)
            end
        end
    end
end

% Copyright 2023-2024 The MathWorks, Inc.