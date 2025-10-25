classdef MltbxMetadataReader < matlab.internal.addons.metadata.AddonMetadataReader
    %mltbx reader rename
    methods(Access =  private)
        function properties = getProperties(obj) 
            mltbx = obj.getPath();
            properties = mlAddonGetProperties(mltbx);
        end
        
        function systemRequirements = getSystemRequirements(obj) 
            mltbx = obj.getPath();
            systemRequirements = mlAddonGetSystemRequirements(mltbx);
        end   
        
        function configuration = getConfiguration(obj) 
            mltbx = obj.getPath();
            configuration = mlAddonGetConfiguration(mltbx);
        end
    end
    
    methods
        %todo: call super
        function obj = MltbxMetadataReader(path)
            obj = obj@matlab.internal.addons.metadata.AddonMetadataReader(path);
        end
        
        %basic info
        function name = getName(obj)
            name = string(obj.getProperties().name);
        end
        
        function version = getVersion(obj)
            version = string(obj.getProperties().version);
        end
        
        function guid = getGuid(obj)
            guid = string(obj.getProperties().GUID);
        end
        
        function authorStruct = getAuthor(obj)
            properties = obj.getProperties();
            authorStruct.name = properties.authorName;
            authorStruct.contact = properties.authorContact;
            authorStruct.organization = properties.authorOrganization;
        end
        
        function summary = getSummary(obj)
            summary = string(obj.getProperties().summary);
        end
        
        function description = getDescription(obj)
            description = string(obj.getProperties().description);
        end
        
        function createdInRelease = getCreatedInRelease(obj)
            createdInRelease = string(obj.getProperties().MATLABRelease);
        end
        
        function screenshot = getScreenshot(obj)
            mltbx = obj.getPath();
            screenshot = string(mlAddonGetScreenshot(mltbx));
        end
        
        function licenseStruct = getLicense(obj)
            mltbx = obj.getPath();
            licenseStruct = mlAddonGetLicense(mltbx);
        end
        
        %system requirements
        function platformCompatibilityStruct = getPlatformCompatibility(obj)
            platformCompatibilityStruct = obj.getSystemRequirements().platformCompatibility;
        end
        
        %empty struct means any release
        function releaseCompatibilityStruct = getReleaseCompatibility(obj)
            releaseCompatibilityStruct = obj.getSystemRequirements().releaseCompatibility;
        end
        
        %external requirements
        function requiredProducts = getRequiredProducts(obj)
            requiredProducts = obj.getSystemRequirements().productDependency;
        end
        
        function requiredSupportPackages = getRequiredSupportPackages(obj)
            requiredSupportPackages = obj.getSystemRequirements().supportPackageDependency;
        end
        
        function requiredAddons = getRequiredAddons(obj)
            requiredAddons = obj.getSystemRequirements().addonDependency;
        end
        
        function requiredAdditionalSoftware = getRequiredAdditionalSoftware(obj)
            %no-up as we don't have a builtin for this
            requiredAdditionalSoftware = [];
        end
        
        %contents
        function includedApps = getIncludedApps(obj)
            mltbx = obj.getPath();
            includedApps = mlAddonGetAppInstallList(mltbx);
        end
        
        function revisionHistory = getRevisionHistory(obj)
            mltbx = obj.getPath();
            revisionHistory = mlAddonGetRevisionHistory(mltbx);
        end
        
        function fileList = getFileList(obj)
            mltbx = obj.getPath();
            fileList = string(mlAddonGetFileList(mltbx))';
        end
        
        %configuration
        function javaClassPaths = getJavaClassPaths(obj)
            configuration = obj.getConfiguration();
            javaClassPaths = string(configuration.javaClassPaths)';
        end
        
        function matlabPaths = getMATLABPaths(obj)
            configuration = obj.getConfiguration();
            matlabPaths = string(configuration.matlabPaths)';
        end
        
        function docPath = getDocumentationPath(obj)
            configuration = obj.getConfiguration();
            docPath = configuration.infoXMLPath;
        end
        
        function installMapPath = getInstallMapPath(obj)
            configuration = obj.getConfiguration();
            installMapPath = configuration.installMapPath;
        end
        
        function gsgPath = getGettingStartedGuide(obj)
            configuration = obj.getConfiguration();
            gsgPath = configuration.gettingStartedDocPath;
        end
    end
end

