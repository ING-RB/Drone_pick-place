classdef FileTransformResult < matlab.io.xml.internal.xslt.TransformResult
% FILETRANSFROMRESULT implements the matlab.io.xml.internal.xslt.TransformResult
% interface. Used when the output of the xslt function is to a file on disk.

% Copyright 2024 The MathWorks, Inc.

    properties (SetAccess=private, GetAccess=public)
        Result
    end

    properties (Dependent, SetAccess=private, GetAccess=public)
        Output
        URL
    end

    methods
        function obj = FileTransformResult(destination)
            arguments
                destination(1, 1) string {mustBeNonmissing}
            end

            import matlab.io.xml.transform.ResultFile

            if destination == ""
                % Create a unique name for a temporary file if destination
                % is a zero-length tet value.
                destination = strcat(tempname, ".html");
            else
                % Verify destination does not already exist as a Folder
                throwExceptionIfFolder(destination);

                [parentFolder, name, ext] = fileparts(destination);

                if parentFolder ~= ""
                    % Verify the destination's parent folder exists.
                    parentFolder = resolveParentFolder(parentFolder, destination);
                    filename = strcat(name, ext);
                    destination = fullfile(parentFolder, filename);
                else
                    % destination input argument was just a filename.
                    % Preprend the CWD to create the resolved destination.
                    destination = fullfile(pwd, destination);
                end
            end
            obj.Result = ResultFile(destination);
        end

        function output = get.Output(obj)
            output = matlab.io.internal.filesystem.createFileURL(obj.Result.Path);
        end

        function url = get.URL(obj)
            url = obj.Output;
        end
    end
end

function throwExceptionIfFolder(location)
    if isfolder(location)
        id = "MATLAB:io:common:file:ExistsAsFolder";
        error(message(id, location));
    end
end

function resolvedFolder = resolveParentFolder(parentFolder, filename)
    info = matlab.io.internal.filesystem.resolvePath(...
        parentFolder, ResolveSymbolicLinks=true, LocalPathFromFileScheme=true);
    if info.Type ~= "Folder"
        id = "MATLAB:io:common:file:ParentFolderNotFound";
        error(message(id, filename, parentFolder));
    end

    resolvedFolder = info.ResolvedPath;
end
