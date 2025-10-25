classdef TempCompressed < matlab.io.internal.filesystem.tempfile.TempFile
    % TempFile implementation for Compressed files.

    properties (SetAccess = private)
        Container %{mustBeUnderlyingType(Container,"matlab.io.internal.filesystem.tempfile.TempFile")}
    end

    properties (Constant)
        SupportedExtensions = ".gz";
    end

    methods
        function obj = TempCompressed(file,opts)
            arguments
                file(1,1) string
                opts(1,1) matlab.io.internal.filesystem.tempfile.TempFileOptions = matlab.io.internal.filesystem.tempfile.TempFileOptions()
            end
            obj = obj@matlab.io.internal.filesystem.tempfile.TempFile(file,opts.OriginalName);
            % Strip the extension
            [~,name,ext] = fileparts(obj.Filename);
            % Get a correctly typed version for the container
            % I.e.
            % if name = foo.csv.gz The container might be a local reference foo.csv
            % if name = foo.tar.gz The container is an archive, and should be treated as such.
            if ismissing(name)
                name = "";
            end
            path = obj.Path;
            % We need to add a separator only if Path doesn't ends with one
            % and name is not empty.
            if ~ismissing(path) && ~endsWith(path, "/") && ~isempty(name)
                name = "/" + name;
            end
            if ismissing(path)
                path = "";
            end
            obj.Container = matlab.io.internal.filesystem.tempfile.tempFileFactory(path+name,opts);
            % now, append the extension back onto the Original Name, or we won't be able to get to the right version

            if isa(obj.Container,"matlab.io.internal.filesystem.tempfile.TempContainer")
                % If the compressed data is in a container file, append GZ
                % back to the contents
                obj.Container.Contents = obj.Container.Contents + ext;
            end
            obj.Container.ResolvedName = obj.Container.ResolvedName + ext;
       
        end
    end
    methods (Static)
        function tf = isSupportedExtension(path)
            ext = matlab.io.internal.filesystem.tempfile.TempCompressed.SupportedExtensions;
            tf = endsWith(path, ext, IgnoreCase=true)...
                && ~endsWith(path, "tar.gz", IgnoreCase=true);
        end
    end

    methods (Access=protected)
        function doLocalCopy(obj,~)
            localName = obj.Container.createLocalCopy();
            obj.LocalName = gunzip(localName,obj.TempLocation);
        end
    end
end

%   Copyright 2024 The MathWorks, Inc.
