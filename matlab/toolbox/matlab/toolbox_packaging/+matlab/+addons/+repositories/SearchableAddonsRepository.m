classdef SearchableAddonsRepository < handle
    
    methods (Abstract)
        
        % Determine whether the repository contains a specified add-on
        % Returns true or false
        value = hasAddon(obj, guid)
        
        % Get all the versions for a specified add-on
        % Returns a character array
        versions = getAddonVersions(obj, guid)
        
        % Gets the download URL for a specified add-on
        % Returns a character array or string
        url = getAddonURL(obj, guid, version)
        
        % Gets the detail page URL for a specified add-on
        % Returns a character array or string
        url = getAddonDetailsURL(obj, guid, version)
        
        % Gets the name of this repository
        % Returns a character array or string
        name = getRepositoryName(obj)
        
    end
end