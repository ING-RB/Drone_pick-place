classdef resolveLocation
%RESOLVELOCATION Returns the absolute path for the input
%   PATH = MATLAB.IO.INTERNAL.FILESYSTEM.RESOLVELOCATION(INPUT, OPTIONS), for a
%   valid input, returns the absolute path, and optionally the target of
%   symbolic links and read-write permissions and last modified date for the input.
%
%   INPUT can be a string array, a character vector, or a cell array of
%   character vectors.
%
%   PATH is an object of type resolveLocation with fields ResolvedPath,
%   Type, Readable, Writable, LastModified. Readable, Writable, and 
%   LastModified are only populated when the optional "GetAttributes" is
%   supplied as true. This is a performance consideration. Symbolic links
%   are resolved to their target when the optional "ResolveSymbolicLink" is
%   supplied as true. The permissions returned are for the target when
%   symbolic links are resolved.
%
%   Example
%   -------
%   % Find the absolute path for "resolveLocation.m" when pwd is
%   [matlabroot]/toolbox/matlab/io/filesystem/+matlab/+io/+internal/+filesystem
%   resolvedPath = matlab.io.internal.filesystem.resolveLocation("resolveLocation.m")
%
%   See also MATLAB.IO.INTERNAL.FILESYSTEM.RELATIVEPATH
%
%   Note: This function is intended for internal MathWorks use only

%   Copyright 2023-2024 The MathWorks, Inc.

    properties
        ResolvedPath (:, 1) string
        Type (:, 1) string
        Readable (:, 1)
        Writable (:, 1)
        LastModified (:, 1) datetime
        Size (:, 1) double
    end

    methods
        function obj = resolveLocation(input, options)
            arguments
                input (:, :)
                options.ResolveSymbolicLink logical = false
                options.GetAttributes logical = false
            end

            resolveSymbolicLink = false;
            getPermissions = false;

            fields = string(fieldnames(options));
            if ~isempty(fields)
                if isfield(options, "ResolveSymbolicLink") && options.ResolveSymbolicLink
                    resolveSymbolicLink = true;
                end

                if isfield(options, "GetAttributes") && options.GetAttributes
                    getPermissions = true;
                end
            end

            if getPermissions
                P = matlab.io.internal.filesystem.resolvePathWithAttributes(input, ResolveSymbolicLinks=resolveSymbolicLink);
            else
                P = matlab.io.internal.filesystem.resolvePath(input, ResolveSymbolicLinks=resolveSymbolicLink);
            end

            if any(isempty([P.ResolvedPath]))
                obj.ResolvedPath = missing;
            else
                [obj.ResolvedPath] = [P.ResolvedPath]';
            end
            if any(isempty([P.Type]))
                obj.Type = missing;
            else
                [obj.Type] = [P.Type]';
            end
            if getPermissions
                if any(isempty([P.Size]))
                    obj.Size = 0;
                else
                    [obj.Size] = [P.Size]';
                end
            end

            if ~getPermissions
                obj.Readable = repmat(missing, size(obj.ResolvedPath, 1), size(obj.ResolvedPath, 2));
                obj.Writable = repmat(missing, size(obj.ResolvedPath, 1), size(obj.ResolvedPath, 2));
                obj.LastModified = repmat(NaT, size(obj.ResolvedPath, 1), size(obj.ResolvedPath, 2));
            else
                [obj.Readable] = [P.Readable]';
                [obj.Writable] = [P.Writable]';
                [obj.LastModified] = datetime.fromMillis([P.LastModified]');
            end
        end
    end

end
