classdef FilesystemBucket < handle
    %FILESYSTEMBUCKET

    % Copyright 2023, MathWorks Inc.
    
    properties (Access = private)
        Uid string
        BucketPath string
        Metadata struct
    end

    methods
        function obj = FilesystemBucket (uid, path, metadata)
            arguments
                uid (1,:) string {mustBeText}
                path (1,:) string {mustBeText}
                metadata struct
            end

            obj.Uid = uid;
            obj.BucketPath = path;
            obj.Metadata = metadata;
        end

        function path = getPath (obj)
            % Gets the path to this bucket

            path = obj.BucketPath;
        end

        function [success, path] = addFolder (obj, folderName)
            path = fullfile(obj.BucketPath, folderName);
            success = true;
            if ~logical(exist(path, 'dir'))
                success = mkdir(path);
            end
        end

        function fileExists = hasFile(obj, filepath)
            path = fullfile(obj.BucketPath, filepath);
            fileExists = logical(exist(path, 'file'));
        end

        function value = getMetadataField (obj, fieldname)
            % Gets the value out of the metadata, if not found an empty
            % string will be returned instead

            if isfield(obj.Metadata, fieldname)
                value = obj.Metadata.(fieldname);
            else
                value = '';
            end
        end

        function expired = isExpired (obj)
            % determines if this bucket has expired

            expired = obj.getMetadataField('expires') < datetime('now');
        end

        function isPresent = containsFile (obj, filepath)
            % determines if a file is present within this bucket
            
            isPresent = isfile(fullfile(obj.BucketPath, filepath));
        end
    end
end

