function addOnVersion = getEnabledOrMostRecentlyInstalledVersionUsingJavaApi(addOnIdentifier)
    %  getEnabledOrMostRecentlyInstalledVersionUsingJavaApi: Uses Java API
    %  to retrieve the version of the add-on that meets the following
    %  criteria
    %  1. Most recently enabled version of add-on
    %  2. In case there are no enabled versions, most recently
    %  installed version 
    %  Today, there is no way to query for (2) from MATLAB. Use
    %  java code to fetch the same
    
    %   Copyright: 2019 The MathWorks, Inc.
    
    import com.mathworks.addons_common.notificationframework.InstalledAddOnsCache;

    if (InstalledAddOnsCache.getInstance().hasEnabledVersion(addOnIdentifier)) 
        installedAddon = InstalledAddOnsCache.getInstance().retrieveEnabledAddOnVersion(addOnIdentifier);
    else 
        installedAddon = InstalledAddOnsCache.getInstance().getMostRecentlyInstalledVersion(addOnIdentifier);
    end 
    
    addOnVersion = string(installedAddon.getVersion);
end

