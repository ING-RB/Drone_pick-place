classdef (Abstract) AddonMetadataReader < handle
    %ADDONMETADATAREADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        path
    end
    
    methods (Access=protected)
        function obj = AddonMetadataReader(path)
            obj.path = path;
        end
        
        function path = getPath(obj)
            path = obj.path;
        end
    end
    
    methods (Abstract)
        
        %basic info
        name = getName(obj);
        version = getVersion(obj);
        guid = getGuid(obj);
        authorStruct = getAuthor(obj);
        summary = getSummary(obj);
        description = getDescription(obj);
        createdInRelease = getCreatedInRelease(obj);
        screenshot = getScreenshot(obj);
        licenseStruct = getLicense(obj);
        
        %system requirements
        platformCompatibilityStruct = getPlatformCompatibility(obj);
        releaseCompatibilityStruct = getReleaseCompatibility(obj);
        
        %external requirements
        requiredProducts = getRequiredProducts(obj);
        requiredSupportPackages = getRequiredSupportPackages(obj);
        requiredAddons = getRequiredAddons(obj);
        requiredAdditionalSoftware = getRequiredAdditionalSoftware(obj);
        
        %contents
        includedApps = getIncludedApps(obj);
        revisionHistory = getRevisionHistory(obj);%consider removing
        fileList = getFileList(obj);
        
        %content paths
        docPath = getDocumentationPath(obj);
        installMapPath = getInstallMapPath(obj);
        gsgPath = getGettingStartedGuide(obj);
        
        %configuration
        javaClassPaths = getJavaClassPaths(obj);
        matlabPaths = getMATLABPaths(obj);
    end
end

