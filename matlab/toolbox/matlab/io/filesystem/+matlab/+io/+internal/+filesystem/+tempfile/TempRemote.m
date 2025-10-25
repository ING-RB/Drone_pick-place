classdef TempRemote < matlab.io.internal.filesystem.tempfile.TempFile
    % TempFile implementation for remote locations

    methods
        function obj = TempRemote(path, opts)
            arguments
                path(1,1) string {mustBeNonzeroLengthText}
                opts(1,1) matlab.io.internal.filesystem.tempfile.TempFileOptions = matlab.io.internal.filesystem.tempfile.TempFileOptions()
            end
            if ~isremote(path)
                error(message("MATLAB:io:filesystem:tempfile:ExpectedRemote", path))
            end
            obj = obj@matlab.io.internal.filesystem.tempfile.TempFile(path,opts.OriginalName)
        end
    end

    methods (Access=protected)
        function doLocalCopy(obj, resolved)
            if isfolder(resolved)
                error(message("MATLAB:io:filesystem:tempfile:FoldersNotSupported"))
            end

            if ~ismissing(obj.Filename)
                [~,name,ext] = fileparts(obj.Filename);
            else
                name = matlab.lang.internal.uuid();
                ext = "";
            end

            localName = obj.getUniqueLocalName(name+ext);
            try 
                copyfile(resolved, localName);
            catch ME
                if matches(ME.identifier,"MATLAB:virtualfileio:stream:"+["permissionDenied","fileNotFound"]);
                    % Provides a better error message if the reason the file was
                    % not found due to invalid env variables.
                    matlab.io.internal.vfs.validators.validateCloudEnvVariables(obj.OriginalName);
                end
                if matches(ME.identifier,"MATLAB:COPYFILE:ReadPermissionError")
                    error("MATLAB:virtualfileio:stream:permissionDenied",obj.OriginalName);
                end
                throw(ME)
            end
            obj.LocalName = localName;
        end
    end

    methods (Static)
        function tf = isremote(path)
            tf = isremote(path);
        end
    end
end

function tf = isremote(path)
import matlab.io.internal.vfs.validators.hasIriPrefix;
tf = hasIriPrefix(path) && ~isFileURL(path);
end

function tf = isFileURL(path)
tf = startsWith(path,"file:/",IgnoreCase=true);
end
%   Copyright 2024 The MathWorks, Inc.
