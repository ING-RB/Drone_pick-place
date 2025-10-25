classdef CommonUtilities
%

%   Copyright 2019-2020 The MathWorks, Inc.
    
    methods(Static)
        
        %returns a list of subdirectories found recursively from the root
        %input folder. The Subdirectories will be returned in BFS order.
        function BFSSubDirectories = findSubdirectoriesByBFS(rootFolder)
            subfoldersToSearch = {rootFolder};
            subfolderCollection = {rootFolder};
            while(numel(subfoldersToSearch)>0)
                %add all subfolders to the output list
                temp_subdirs=matlab.depfun.internal.format.CommonUtilities.subdirectories(subfoldersToSearch{1});
                subfolderCollection = [subfolderCollection; temp_subdirs];
                %add all subfolders to be checked for further subfolders
                subfoldersToSearch(1)=[];
                subfoldersToSearch = [subfoldersToSearch; temp_subdirs];
            end
            BFSSubDirectories=subfolderCollection;
        end
        
        %Returns a list of all the directories within a folder. This
        %function is not recursive.
        function subDirectories = subdirectories(folderName)
            allDirectories = dir(folderName);
            isub = [allDirectories(:).isdir];
            subDirectories = {allDirectories(isub).name}';
            subDirectories(ismember(subDirectories,{'.','..'})) = [];
            subDirectories = cellfun(@(x) fullfile(folderName, x), subDirectories, 'UniformOutput',false);
        end
        
        %gets support packages without running required files and products
        function [supportpackagelist]=findSupportPackages(depfilelist, depproductlist)
            
            % for storing the topOnly results so we only call it once
            topOnlyResults = {};
            
            supportpackagelist = {};
            
            % Get the list of deployable support packages
            deployableSupportPkgs = matlab.depfun.internal.DeployableSupportPackages;
            pkgs = deployableSupportPkgs.getSupportPackageList();
            
            
            % For each support package see if it's used by the files or products
            pkgCnt = length(pkgs);
            includedPkg = 1;
            
            for pkgItr=1:pkgCnt
                if(isempty(topOnlyResults)) % only call toponly once
                    topOnlyResults = matlab.depfun.internal.format.CommonUtilities.getTopOnlyResults(depfilelist);
                end
                dependentFlag = pkgs{pkgItr}.filesOrProductsUseSupportPackage(topOnlyResults, depproductlist);
                
                % additions to check for 3rd party dependencies
                tpInstalls = length(pkgs{pkgItr}.thirdPartyName);
                
                tpData = {};
                % if there are find the name, url and download url for each one
                for tpI = 1:tpInstalls
                    tpData(tpI, :) = {pkgs{pkgItr}.thirdPartyName{tpI} pkgs{pkgItr}.thirdPartyURL{tpI} ''};
                    
                end
                
                % only return the support package if the flag is set to true
                if(dependentFlag)
                    supportpackagelist(includedPkg,:) = { pkgs{pkgItr}.name pkgs{pkgItr}.displayName pkgs{pkgItr}.baseProduct 'true' tpInstalls tpData};
                    includedPkg = includedPkg + 1;
                end
            end
        end
        
        function topOnlyResults = getTopOnlyResults(depfilelist)
            
            % turn off the "no mcode" warnings
            warnstatus = warning('OFF','MATLAB:depfun:req:NoCorrespondingMCode');
            restoreWarnState = onCleanup(@()warning(warnstatus));
            
            p = matlab.depfun.internal.Completion(depfilelist, matlab.depfun.internal.Target.All, true);
            
            pParts = p.parts;
            
            fileCnt = length(pParts);
            topOnlyResults = cell(1, fileCnt);
            for fileItr = 1:fileCnt
                topOnlyResults{fileItr} = pParts(fileItr).path;
            end
            
        end
    end
end

% LocalWords:  BFS subfolders toponly mcode
