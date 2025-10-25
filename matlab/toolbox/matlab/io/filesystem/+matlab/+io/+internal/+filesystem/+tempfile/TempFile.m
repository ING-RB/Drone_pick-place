classdef TempFile < handle
    % TempFile interface class

    properties (SetAccess = protected)
        % User Supplied Name
        OriginalName(1,1) string
        % Resolved Path/NestedURL
        ResolvedName(1,1) string = missing;
        % LocalPath
        LocalName(1,1) string = missing;
    end

    properties (Access = private)
        PathObj
    end

    properties (Dependent)
        Filename
        Path
        Extension
    end

    properties (Constant, Access=protected)
        FolderManager = matlab.io.internal.filesystem.tempfile.TempFolderManager(["matlab","tempfiles"]);
    end

    properties (Dependent, Access=protected)
        TempLocation
    end

    methods
        function obj = TempFile(resolved,original)
            import matlab.io.internal.filesystem.pathObject;
            import matlab.io.internal.filesystem.createURLFromParts;
            obj.OriginalName = original;

            % Path utility can handle IRIs including HTTP/S URLs with
            % "?" query and/or "#" fragment components.
            obj.PathObj = pathObject(resolved,Type="auto");

            % Use Filename obtained from the PathObj to re-construct
            % ResolvedName without any "?" query and/or "#" fragment components.
            % Use empty for filename if missing.
            if ~ismissing(obj.PathObj.Name)
                name = obj.Filename;
            else
                name = "";
            end

            if startsWith(resolved,["http://";"https://"],"IgnoreCase",true)
                % For HTTP urls, we need to preserve the input, including
                % query and fragments.
                obj.ResolvedName = resolved;
            else
                % append name to parent path
                obj.ResolvedName = createURLFromParts(obj.PathObj.Parent, name);
            end
        end

        function delete(obj)
            if ~ismissing(obj.LocalName)
                delete(obj.LocalName);
            end
        end

        function val = get.TempLocation(obj)
            val = obj.FolderManager.TempFolderLocation;
        end

        function name = get.Filename(obj)
            name = obj.PathObj.Name;
            if ~ismissing(obj.PathObj.Extension)
                % If any spaces after the extension part, they can be ignored.
                name = strip(name, "right");
            end
        end

        function path = get.Path(obj)
            path = obj.PathObj.Parent;
        end

        function extn = get.Extension(obj)
            % Extension cannot have spaces, trim if any carried over spaces
            % from the original IRI.
            if ismissing(obj.PathObj.Extension)
                extn = "";
            else
                extn = strip(obj.PathObj.Extension);
            end
        end

        function name = createLocalCopy(obj)
            if ismissing(obj.LocalName)
                if isfolder(obj.ResolvedName)
                    error(message("MATLAB:io:filesystem:tempfile:FoldersNotSupported"))
                end
                try
                    obj.doLocalCopy(obj.ResolvedName);
                catch ME
                    % TODO: Add Custom Message for Failed to create local.
                    throw(ME)
                end
                % Ensure this is actually a local file path.
                if startsWith(obj.LocalName,"file:/",IgnoreCase=true)
                    obj.LocalName = matlab.io.internal.vfs.validators.LocalPath(obj.LocalName, ResolvePaths=false);
                end
            end
            name = obj.LocalName;
        end
    end

    methods (Access = protected, Sealed)
        function name = getUniqueLocalName(obj,name)
            name = matlab.io.internal.filesystem.tempfile.getUniqueTempName(obj.TempLocation,name);
        end
    end

    methods (Access = protected)
        function cleanupFile(obj)
            delete(obj.TemporaryFilePath);
        end
    end

    methods (Access=protected, Abstract)
        doLocalCopy(obj, resolvedName);
    end

end

%   Copyright 2024 The MathWorks, Inc.
