classdef MlappinstallMetadataReader < matlab.internal.addons.metadata.AddonMetadataReader
    
    properties
    end
    
    methods(Access=private)
        function info = getAppInfo(obj)
           info = mlappinfo(obj.getPath());
        end
    end
    
    methods
        function obj = MlappinstallMetadataReader(path)
            obj = obj@matlab.internal.addons.metadata.AddonMetadataReader(path);
        end
        
        %basic info
        function name = getName(obj)
            name = string(obj.getAppInfo().name);
        end
        
        function version = getVersion(obj)
            version = string(obj.getAppInfo().version);
        end
        
        function guid = getGuid(obj)
            guid = string(obj.getAppInfo().guid);
        end
        
        function authorStruct = getAuthor(obj)
            authorStruct.name = string(obj.getAppInfo().AuthorName);
            authorStruct.contact = string(obj.getAppInfo().AuthorContact);
            authorStruct.organization = string(obj.getAppInfo().authorOrganization);
        end
        
        function summary = getSummary(obj)
            summary = string(obj.getAppInfo().summary);
        end
        
        function description = getDescription(obj)
            description = string(obj.getAppInfo().description);
        end
        
        function createdInRelease = getCreatedInRelease(obj)
            %may need to remove parentheses
            createdInRelease = string(obj.getAppInfo().createByMATLABRelease);
        end
        
        function screenshot = getScreenshot(obj)
            image = mlappGetAppScreenshot(obj.getPath());
            if ~isempty(image)
                characters = char(uint64(image));
                screenshot = strcat(characters');
            else
                screenshot = [];
            end
        end
        
        function licenseStruct = getLicense(obj)
            %plain mlappinstall files don't have licenses
            licenseStruct = [];
        end
        
        %system requirements
        function platformCompatibilityStruct = getPlatformCompatibility(obj)
            platformCompatibilityStruct.win = 'true';
            platformCompatibilityStruct.linux = 'true';
            platformCompatibilityStruct.mac = 'true';
            platformCompatibilityStruct.MATLABOnline = 'true';
        end
        
        %empty struct means any release, no restrictions
        function releaseCompatibilityStruct = getReleaseCompatibility(obj)
            releaseCompatibilityStruct = [];
        end
        
        %external requirements
        function requiredProducts = getRequiredProducts(obj)
            reqProducts = obj.getAppInfo().requiredProducts;
            sizeOfProducts = size(reqProducts,2);
            requiredProducts =  struct('name', cell(sizeOfProducts), 'version', cell(sizeOfProducts), 'identifier', cell(sizeOfProducts));
            for i=1:sizeOfProducts(1)
                %idientifiers and versions appear as -1 so i don't know
                %which is which
                product = reqProducts{i};
                requiredProducts(i).name = string(product{2});
                requiredProducts(i).version = string(product{1});
                requiredProducts(i).identifier = string(product{3});
            end
        end
        
        function requiredSupportPackages = getRequiredSupportPackages(obj)
            requiredSupportPackages = [];
        end
        
        function requiredAddons = getRequiredAddons(obj)
            requiredAddons = [];
        end
        
        function requiredAdditionalSoftware = getRequiredAdditionalSoftware(obj)
            requiredAdditionalSoftware = [];
        end
        
        %contents
        function includedApps = getIncludedApps(obj)
            includedApps = [];
        end
        
        function revisionHistory = getRevisionHistory(obj)
            revisionHistory = [];
        end
        
        function fileList = getFileList(obj)
            fileList = string(obj.appMetadata.getAppEntries());
        end
        
        %configuration
        function javaClassPaths = getJavaClassPaths(obj)
            javaClassPaths = [];
        end
        
        function matlabPaths = getMATLABPaths(obj)
            matlabPaths = [];
        end
        
        function docPath = getDocumentationPath(obj)
            docPath = '';
        end
        
        function installMapPath = getInstallMapPath(obj)
            installMapPath = '';
        end
        
        function gsgPath = getGettingStartedGuide(obj)
            gsgPath = '';
        end
    end
end

