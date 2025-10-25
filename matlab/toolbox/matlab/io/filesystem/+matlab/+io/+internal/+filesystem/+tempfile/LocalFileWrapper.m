classdef LocalFileWrapper < matlab.io.internal.filesystem.tempfile.TempFile
    % TempFile implementation/wrapper for local files

    methods
        function obj = LocalFileWrapper(name,opts)
            arguments
                name(1,1) string
                opts(1,1) matlab.io.internal.filesystem.tempfile.TempFileOptions = matlab.io.internal.filesystem.tempfile.TempFileOptions()
            end

            obj = obj@matlab.io.internal.filesystem.tempfile.TempFile(...
                matlab.io.internal.filesystem.tempfile.LocalFileWrapper.getURLFromPath(name),...
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
            if ~isfile(resolvedName)
                name = obj.OriginalName;
                if ismissing(name)
                    name = "";
                end
                error(message("MATLAB:io:filesystem:tempfile:FileNotFound",name));
            end
            obj.LocalName = resolvedName;
        end
    end

    methods (Static)
        function name = getURLFromPath(name)
            if ~matlab.io.internal.filesystem.isAbsolutePathNoIO(name)
                % relative path URLs must be Absolute paths, fullfile is safe here.
                name = fullfile(pwd,name);
            end

            if ~matlab.io.internal.vfs.validators.hasIriPrefix(name)
                % Turn it into file:// path
                name = matlab.io.internal.filesystem.createFileURL(name);
            end
        end
    end
end

%   Copyright 2024 The MathWorks, Inc.
