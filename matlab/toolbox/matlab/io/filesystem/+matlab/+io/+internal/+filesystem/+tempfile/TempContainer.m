classdef TempContainer < matlab.io.internal.filesystem.tempfile.TempFile
    % TempFile implementation for Archive and Container files.
    properties (SetAccess = private)
        Container
        Password(1,1) string = missing
    end

    properties
        Contents(1,1) string
    end

    properties (Constant)
        SupportedExtensions = [".zip",".tar",".tar.gz",".tgz"];
    end

    methods
        function obj = TempContainer(container, contents, opts)
            arguments
                container(1,1) string
                contents(1,1) string
                opts(1,1) matlab.io.internal.filesystem.tempfile.TempFileOptions = matlab.io.internal.filesystem.tempfile.TempFileOptions()
            end
            import matlab.io.internal.filesystem.tempfile.tempFileFactory;

            containerObj = tempFileFactory(container,opts);
            obj = obj@matlab.io.internal.filesystem.tempfile.TempFile(...
                getResolvedName(containerObj.ResolvedName,contents),opts.OriginalName);
            obj.Container = containerObj;
            obj.Contents = urldecode(contents);
            obj.Password = opts.Password;
        end
    end

    methods (Access=protected)
        function doLocalCopy(obj, ~)
            localContainer = obj.Container.createLocalCopy();

            format = getFormatFromExtension(localContainer);

            [~,name] = fileparts(obj.Container.Filename);
            contents = obj.Contents;
            % TODO: add password support when extractArchive supports password with files list.
            localContents = extractArchive(localContainer,fullfile(obj.TempLocation,name),format,contents);

            if ~isscalar(localContents)
                originalContainer = extractBefore(obj.OriginalName,contents);
                error(message("MATLAB:io:common:validation:CannotExtractContents",originalContainer,contents))
            end
            obj.LocalName = localContents;
        end
    end

    methods (Static)
        function tf = isSupportedExtension(path)
            ext = matlab.io.internal.filesystem.tempfile.TempContainer.SupportedExtensions;
            tf = endsWith(path, ext, IgnoreCase=true);
        end
    end
end

function filesout = extractArchive(varargin)
import matlab.io.internal.archive.core.builtin.extractArchive

[varargin{1:nargin}] = convertStringsToChars(varargin{:});
filesout = string(extractArchive(varargin{:}));
end

function originalName = getResolvedName(originalName, contents)
if matlab.io.internal.vfs.validators.hasIriPrefix(originalName)
    originalName = originalName + "/" + contents;
else
    originalName = fullfile(originalName,contents);
end
end

function fmt = getFormatFromExtension(filename)
if endsWith(filename,["tar","tar.gz","tgz"],IgnoreCase=true)
    fmt = "tgz";
else
    fmt = "zip";
end
end
%   Copyright 2024 The MathWorks, Inc.
