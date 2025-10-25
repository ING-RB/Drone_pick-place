classdef SearchableListableAddonsRepository < matlab.addons.repositories.SearchableAddonsRepository
    
    methods (Abstract)
        % Gets the name of this repository
        % Returns a character array or string
        [addonInfo, complete, stateObject] = getAllAddonIds(obj, searchText, stateObject)
        
        [metadata] = getAddonMetadata(obj, guid, version);
        
    end
end
