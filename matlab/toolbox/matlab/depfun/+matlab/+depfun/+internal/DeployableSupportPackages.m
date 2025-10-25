classdef DeployableSupportPackages < handle
%

%   Copyright 2015-2020 The MathWorks, Inc.
    
    % Class for getting the list of Support Packages that support
    % matlab.addons.internal.SupportPackageInfoBase interface
    
    properties (Access = private) 
       supportPackageList; 
    end

    methods
        function obj=DeployableSupportPackages()
        
            % store the instances in a map facilitate lookup by name
            obj.supportPackageList = containers.Map;
        
            packages = meta.package.fromName( 'matlab.addons.internal' );
            classes = packages.ClassList;
            for i = 1:length(classes)
                if(~classes(i).Abstract) % skip the abstract class
                    % need to check that is has matlab.addons.internal.SupportPackageInfoBase
                    % as a superclass
                    if(length(classes(i).SuperclassList) == 1 ...
                            &&  strcmp(classes(i).SuperclassList.Name, 'matlab.addons.internal.SupportPackageInfoBase'))
                        % need to account for class in matlabroot already being loaded but scoped from the path in depfun         
                        try
                            tmpClass = feval(classes(i).Name);
                        catch E
                            continue
                        end
                        % Although we should never hit this, the possibility exists that 
                        % two classes could have the same "name"
                        % Check to see if the name is already a key in the map
                        if(obj.supportPackageList.isKey(tmpClass.name))
                            % If it is, warn there are two class implementations that have the same name
                            error(message( ...
                                'MATLAB:depfun:DeployableSupportPackages:DuplicateNames', ...
                                class(obj.supportPackageList(tmpClass.name)), classes(i).Name))
                        else
                            % Otherwise, add it to the map
                            obj.supportPackageList(tmpClass.name) = tmpClass;
                        end
                        
                    end
                end
            end
        end
        
        function supportPkgList = getSupportPackageList(obj)
            supportPkgList = obj.supportPackageList.values;
        end
        
        function supportPkg = getSupportPackage(obj, name)
            supportPkg = [];
            
            if(obj.supportPackageList.isKey(name))
                supportPkg = obj.supportPackageList(name);
            end
            
        end
        
        function supportPkgList = determineSupportPackages(obj, fileList, productList)

            supportPkgList = {};

            % Get the list of deployable support packages
            pkgs = obj.getSupportPackageList();

            % For each support package see if it's used by the files or products
            pkgCnt = length(pkgs);
            includedPkg = 1;

            for pkgItr=1:pkgCnt

                dependentFlag = pkgs{pkgItr}.filesOrProductsUseSupportPackage(fileList, productList);

                % only return the support package if the flag is set to true
                if(dependentFlag)
                    supportPkgList(includedPkg) =  pkgs(pkgItr);
                    includedPkg = includedPkg + 1;
                end
            end
        end
    end

    
end

% LocalWords:  addons
