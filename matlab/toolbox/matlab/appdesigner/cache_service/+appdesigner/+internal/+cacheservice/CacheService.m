classdef CacheService < handle
    %CACHESERVICE

    % Copyright 2023-2024 The MathWorks, Inc.

    properties (Access = private, Constant)
        DefaultMetadataFilename = '__metadata__.json';
    end

    properties (Access = private)
        TempdirFileWriter = appdesigner.internal.cacheservice.TempdirFileWriter();
    end

    methods (Access = private)
        function obj = CacheService ()
            if ~isdeployed
                appdesigner.internal.async.AsyncTask(@obj.removeExpiredEntries).run();
            end
        end
    end

    methods (Static)
        function obj = instance ()
            persistent cacheServiceInstance;

            if isempty(cacheServiceInstance)
                cacheServiceInstance = appdesigner.internal.cacheservice.CacheService();
            end

            obj = cacheServiceInstance;
        end

        function funcHandle = getComponentInitFunctionHandle(compInitPath)
            fullfilePath = compInitPath;

            if isdeployed() && ~startsWith(compInitPath, "inmem:///")
                % In deployed mode, mfile reader would fail when trying to
                % access a file out of CTF.
                % As a workaround here, copy it to inmem
                % Todo: we may need to change our proposal for compiling CTF:
                %  include pre-genrated comonent init code into CTF for this
                % reason and secrity - g3436631.
                inmemRoot = "inmem:///appdesigner/component_init_cache/";
                if ~isfolder(inmemRoot)
                    mkdir(inmemRoot);
                end

                [~, name, ext] = fileparts(compInitPath);
                fullfilePath = fullfile(inmemRoot, name + ext);

                copyfile(compInitPath, fullfilePath, "f");
            end

            % Need security audit: g3436629
            funcHandle = appdesigner.internal.cacheservice.getMAPPComponentInitHandle(char(fullfilePath));
        end
    end

    methods (Access = public)
        function methodPath = addComponentInitFunction (obj, uid, fileContent)
            % add a new function into the mappcache namespace

            arguments
                obj appdesigner.internal.cacheservice.CacheService
                uid string
                fileContent string
            end

            methodPath = obj.TempdirFileWriter.getInitFilePath(uid);
            [path, ~, ~] = fileparts(methodPath);

            if ~isfolder(path)
                mkdir(path);
            end

            obj.TempdirFileWriter.writeContent(methodPath, fileContent);
        end

        function [isPresent, path] = hasComponentInitFunction (obj, uid)
            % determine if a mappcache function exists

            arguments
                obj appdesigner.internal.cacheservice.CacheService
                uid string
            end

            [isPresent, path] = obj.TempdirFileWriter.hasInitFile(uid);
        end

        function clearCache (obj)
            % Clears the cache of all app cache artifact folders

            folderList = obj.getCacheAppList();

            for i = 1:length(folderList)
                obj.clearBucket(folderList{i});
            end
        end

        function bucketApi = getBucket(obj, uid, metadata)
            % Retrieve a bucket from the cache, creates a new one if what was found
            % has expired or none was found.

            arguments
                obj appdesigner.internal.cacheservice.CacheService
                uid (1,:) string
                metadata struct = struct('expires',datetime('now') + days(30))
            end

            rootDir = obj.TempdirFileWriter.getCacheRoot();
            path = fullfile(rootDir, uid);

            if isfolder(path)
                metadata = obj.readMetadataByUid(uid);

                if metadata.expires > datetime('now')
                    bucketApi = appdesigner.internal.cacheservice.FilesystemBucket(uid, path, metadata);
                else
                    obj.clearBucket(uid);
                    bucketApi = obj.createBucket(uid, metadata);
                end
            else
                bucketApi = obj.createBucket(uid, metadata);
            end
        end

        function clearBucket(obj, uid)
            % Remove an app artifact bucket from the cache
            % false return means the bucket was not found

            arguments
                obj appdesigner.internal.cacheservice.CacheService
                uid (1,:) string
            end

            path = fullfile(obj.TempdirFileWriter.getCacheRoot(), uid);

            if isfolder(path)
                rmdir(path, 's');
            end
        end

        function res = getAppViewCacheFilePath(obj, figFilePath)
            % Return App View Cache File Path if it exists

            arguments
                obj appdesigner.internal.cacheservice.CacheService
                figFilePath (1,:) string
            end
            res = '';

            [~, ~, ext] = fileparts(figFilePath);
            % TODO: Add function which performs the plain text app check
            if ~strcmpi(ext, '.m')
               return
            end

            try
                viewJSONCacheFile = fullfile(appdesigner.internal.artifactgenerator.ClientGenerator.ClientCacheSubFolder, ...
                    appdesigner.internal.artifactgenerator.ClientGenerator.ClientCacheFileName);

                uid = appdesigner.internal.cacheservice.generateUidFromFilepath(figFilePath);

                cacheBucket = obj.getBucket(uid);
                if ~isempty(cacheBucket)
                    res = fullfile(cacheBucket.getPath(), viewJSONCacheFile);
                end
            catch me
                % no -op. Catch exception to avoid breaking app runtime
            end
        end
    end

    methods (Access = private)
        function bucketApi = createBucket(obj, uid, metadata)
            % Creates a new artifact bucket to store cache data

            arguments
                obj appdesigner.internal.cacheservice.CacheService
                uid (1,:) string {mustBeText}
                metadata struct = struct
            end

            rootDir = obj.TempdirFileWriter.getCacheRoot();

            path = fullfile(rootDir, uid);

            bucketApi = [];

            if ~isfolder(path)
                mkdir(path);
                metadata = obj.createBucketMetadata(metadata);
                obj.writeMetadata(uid, metadata);
                bucketApi = appdesigner.internal.cacheservice.FilesystemBucket(uid, path, metadata);
            end
        end

        function folderList = getCacheAppList (obj)
            % gets a list of all folders in the cache

            children = dir(obj.TempdirFileWriter.getCacheRoot());

            indicies = [children(:).isdir];

            folderList = {children(indicies).name}';

            folderList(ismember(folderList, {'.', '..'})) = [];
        end

        function removeExpiredEntries (obj)
            % iterates all cache entries, removes anything that has
            % expired. If meta is unreadable the entry is removed.

            folders = obj.getCacheAppList();

            now = datetime('now');

            for i = 1:length(folders)
                uid = folders{i};

                try
                    meta = obj.readMetadataByUid(uid);
                    if now > meta.expires
                        obj.clearBucket(uid);
                    end
                catch
                    obj.clearBucket(uid);
                end
            end
        end

        function meta = createBucketMetadata (~, metadata)
            % creates the struct to write as metadata

            metadata.created = datetime('now');

            meta = metadata;
        end

        function writeMetadata (obj, uid, metadata)
            % writes the required metadata file

            path = fullfile(obj.TempdirFileWriter.getCacheRoot(), uid, obj.DefaultMetadataFilename);
            writestruct(metadata, path, 'FileType', 'json');
        end

        function meta = readMetadataByUid (obj, uid)
            % reads the metadata xml file back to struct

            path = fullfile(obj.TempdirFileWriter.getCacheRoot(), uid, obj.DefaultMetadataFilename);
            meta = readstruct(path, 'FileType', 'json');
        end
    end
end

