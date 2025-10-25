classdef AppSessionCache < handle
    %This function is for internal use only. It may be removed in the future.

    %AppSessionCache stores the current session name and saved state

    %   Copyright 2023-2024 The MathWorks, Inc.

    properties
        %HasSessionPath Check whether the session has been saved before
        HasAppCache
        % Cache file name and its location
        AppCacheFileName
        AppCacheFileFullPath
        % handle to cache file matfile obj
        MATFileObj
        % CacheData Content
        CacheData
        % handle to metadata file matfile obj
        Metadataobj
        % ROS bag details
        ROSBagFullPath
        % Location of Cache Folder
        AppCacheLocation
        % Path to the Cache Folder
        CacheFolderPath
        % Path to the MetaData File
        MetaDataFilePath
    end

    properties (Constant)
        % Sub Folder that contains cache files
        SubFolderName = "rosbagViewer";
        % Name of the MetaData File
        MetaDataFileName = 'rosbagViewerSessionMetadata.mat'
    end

    methods
        function obj = AppSessionCache(fullbagname)
            %AppSessionCache constructor
            
            obj.ROSBagFullPath = fullbagname;
            % Define properties for paths to reduce "fullfile" calls. 
            obj.AppCacheLocation = ros.internal.utils.getCacheFolderLocation();
            obj.CacheFolderPath = fullfile(obj.AppCacheLocation, obj.SubFolderName);
            obj.MetaDataFilePath = fullfile(obj.CacheFolderPath, obj.MetaDataFileName);
            
            % Verify if there is a cache file available for this rosbag
            [status, cacheFilename, noOfSessions] = obj.hasCacheFile(fullbagname);
            obj.HasAppCache = status;
            if status
                % A cache already exists 
                obj.AppCacheFileName = cacheFilename;
                obj.AppCacheFileFullPath = fullfile(obj.CacheFolderPath, obj.AppCacheFileName);
                obj.MATFileObj = matfile(obj.AppCacheFileFullPath, "Writable", true);
                obj.CacheData = obj.getCacheFileDetails;
            else
                % A new cache must be created
                obj.AppCacheFileName = ['rosbagViewerSessionCache_' num2str(noOfSessions+1) '.mat'];
                obj.AppCacheFileFullPath = fullfile(obj.CacheFolderPath, obj.AppCacheFileName);
            end
        end

        function createCacheFile(obj)
            %createCacheFile when called will create a cache file

            if ~exist(obj.CacheFolderPath, 'dir')
                %create folder
                mkdir(obj.CacheFolderPath);
                %create metadata
                obj.createMetadataFile();
            elseif ~exist(obj.MetaDataFilePath, 'file')
                obj.createMetadataFile();
            end
            obj.updateMetadata();
            obj.MATFileObj = matfile(obj.AppCacheFileFullPath, "Writable", true);
            obj.MATFileObj.BagInfo = struct();
            obj.MATFileObj.LayoutInfo = struct();
            obj.MATFileObj.VisualizerInfo = struct();
            obj.MATFileObj.BookmarkData = table();
            obj.MATFileObj.Tags = {};
        end

        function out = getCacheFileDetails(obj)
            %getCacheFileDetails return the data in the cache file

            out.bagInfo = obj.MATFileObj.BagInfo;
            out.layoutInfo = obj.MATFileObj.LayoutInfo;
            out.visualizerInfo = obj.MATFileObj.VisualizerInfo;
            out.bookmarkData = obj.MATFileObj.BookmarkData;
            if ~any(contains(fields(obj.MATFileObj), 'Tags')) %to support backward compatibility
                obj.MATFileObj.Tags = {};
            end
            out.tags = obj.MATFileObj.Tags;

        end

        function updateCacheFile(obj, dataIn)
            %updateCacheFile will update the app session cache file with new data
            try
                obj.MATFileObj.BagInfo = dataIn.RosbagInfo;
                obj.MATFileObj.LayoutInfo = dataIn.Layout;
                obj.MATFileObj.VisualizerInfo = dataIn.VisualizerInfo;
                obj.MATFileObj.BookmarkData = dataIn.BookmarkData;
                obj.MATFileObj.Tags = {dataIn.TagsData};
            catch ME %#ok<NASGU>
                return;
            end
        end

        function [status, cacheFileName, noOfCache] = hasCacheFile(obj, bagloc)

            %hasCacheFile returns the status if the Cache file is avialable
            %along with the contents of metadata.

            noOfCache = 0;
            cacheFileName ='';
            status = false;
            if exist(obj.MetaDataFilePath, 'file')
                metadataContent = obj.getMetadataContent();
                noOfCache = numel(metadataContent.BagInfo);

                if any(strcmp(metadataContent.BagInfo, bagloc))
                    status = true;
                    index = strcmp(metadataContent.BagInfo, bagloc);
                    avcachname = metadataContent.CacheName;
                    cacheFileName = avcachname{index};
                else
                    status = false;
                end
            end

        end %End hasCachefile

        function createMetadataFile(obj)
            % createMetadataFile create a metadatafile

            obj.Metadataobj = matfile(obj.MetaDataFilePath, "Writable", true);
            obj.Metadataobj.BagInfo = {};
            obj.Metadataobj.CacheName = {};
        end

        function updateMetadata(obj)
            % updateMetadata update the contents in metadata file

            %temp variable is used because Linear indexing is not supported.
            metadataobj  = obj.Metadataobj;
            temp = metadataobj.BagInfo;
            temp{end+1} = obj.ROSBagFullPath;
            metadataobj.BagInfo = temp;
            temp = metadataobj.CacheName;
            temp{end+1} = obj.AppCacheFileName;
            metadataobj.CacheName = temp;
        end

        function out = getMetadataContent(obj)
            % getMetadataContents returns the contents from metadata file

            obj.Metadataobj = matfile(obj.MetaDataFilePath, "Writable", true);
            out.BagInfo = obj.Metadataobj.BagInfo;
            out.CacheName = obj.Metadataobj.CacheName;
        end

    end % End Method
end% End Class

