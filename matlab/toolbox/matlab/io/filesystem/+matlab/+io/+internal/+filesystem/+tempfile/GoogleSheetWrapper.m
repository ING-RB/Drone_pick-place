classdef GoogleSheetWrapper < matlab.io.internal.filesystem.tempfile.TempFile
    % TempFile implementation/wrapper for Google Sheets URL

    methods
        function obj = GoogleSheetWrapper(url,opts)
            arguments
                url(1,1) string
                opts(1,1) matlab.io.internal.filesystem.tempfile.TempFileOptions = matlab.io.internal.filesystem.tempfile.TempFileOptions()
            end

            obj = obj@matlab.io.internal.filesystem.tempfile.TempFile(...
                url,...
                opts.OriginalName);
        end

        function delete(obj)
            % Clear the temp name so the TempFile delete(obj) doesn't remove the file
            obj.LocalName = missing;
        end
    end

    methods (Access = protected)
        function doLocalCopy(obj, resolvedName)
            % Copy does nothing in this case
            obj.LocalName = resolvedName;
        end
    end
end

%   Copyright 2024 The MathWorks, Inc.
