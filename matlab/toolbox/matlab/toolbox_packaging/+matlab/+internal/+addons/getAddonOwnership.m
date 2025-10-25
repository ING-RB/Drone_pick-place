function ownersMap = getAddonOwnership(absPaths)
%GETADDONOWNERSHIP Determine owning Add-Ons for a list of absolute paths.
%   Given a list of one or more absolute paths this method will return
%   a containers.Map object mapping the given absolute paths (char) to a
%   struct containing basic information for the owning AddOn.  If a given
%   file is not owned by an AddOn it will not appear in the returned
%   container.
%
%   GETADDONOWNERSHIP(ABSPATHS) returns a containers.Map(char, struct)
%   mapping the given absolute paths to their owning AddOns, if any.  The
%   returned ADDONDATA information structs have fields as defined for the 
%   matlab.internal.addons.getAddonInstallations command.
%
%   See also containers.Map, matlab.internal.addons.getAddonInstallations.

%   Copyright 2020 MathWorks, Inc.

    arguments
        absPaths(1,:) string {mustBeNonempty}
    end

    if ~usejava('jvm')
        error([mfilename ' requires an available Java VM!']);
    end
    
    ownersMap = containers.Map('KeyType', 'char', 'ValueType', 'any');

    addOnsToUse = matlab.internal.addons.getAddonInstallations();
    if ~isempty(addOnsToUse)
        
        % Iterate given absolute paths and find out if any of them reside
        % under the installation folder for any of the installed AddOns.
        % NOTE: We expect to be working with absolute paths here, so we do
        % not need to care about enabled/disabled state; we want to remain
        % ignorant of that mechanism if possible.
        for i=1:length(absPaths)
            nextPath = string(absPaths(i));
            for j=1:length(addOnsToUse)
                installedPath = addOnsToUse(j).InstallationFolder;
                if startsWith(nextPath, installedPath)
                    ownersMap(nextPath) = addOnsToUse(j);
                end
            end
        end
    end    
end

