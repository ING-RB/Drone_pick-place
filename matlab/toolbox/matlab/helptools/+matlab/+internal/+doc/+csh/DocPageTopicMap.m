classdef DocPageTopicMap < handle

    properties (Constant, Access=private)
        CacheKey = "targets"
    end

    properties (Access=private)
        ShortName string
        Group string
        Product struct
        HelpLocation
        TopicPath string
        HelpTargetsCache matlab.internal.doc.services.HelpSystemCache
    end
    
    methods
        function obj = DocPageTopicMap(shortname, group, validate)
            arguments
                shortname (1,1) string = ""
                group string = ""
                validate (1,1) logical = true
            end

            obj.HelpTargetsCache = matlab.internal.doc.services.HelpSystemCache;
            if shortname ~= "" && validate
                obj.Product = matlab.internal.doc.url.getDocPageProduct(shortname);
                if ~isempty(obj.Product)
                    shortname = obj.Product.ShortName;
                end
                obj.ShortName = shortname;
            else
                obj.ShortName = shortname;
                obj.Product = struct.empty;
            end

            obj.Group = group;
        end
        
        function docPage = mapTopic(obj, topicId)
            docPage = matlab.internal.doc.url.DocPage.empty;
            topicId = string(topicId);
            for i = length(topicId):-1:1
                docPage(i) = mapSingleTopic(obj, topicId(i));
            end
        end
        
        function hasTopic = topicExists(obj, id)
            arguments
                obj (1,1) matlab.internal.doc.csh.DocPageTopicMap
                id string
            end
            hasTopic = zeros(size(id));
            for i = 1:length(id)
                hasTopic(i) = singleTopicExists(obj, id(i));
            end
            hasTopic = logical(hasTopic);
        end

        function hasTopics = exists(obj)
            ensureHelpTargetsPopulated(obj);
            hasTopics = ~isempty(obj.HelpTargetsCache.Data);
        end
        
        function id = getId(obj)
            id = "";
            if obj.exists
                id = obj.ShortName;
                if obj.isValidGroup
                    id = id + "/" + obj.Group;
                end
            end
        end

        function prod = get.Product(obj)
            if isempty(obj.Product) && ~isempty(obj.ShortName) 
                obj.Product = matlab.internal.doc.url.getDocPageProduct(obj.ShortName);
            end
            prod = obj.Product;
        end
    end
    
    methods (Static)
        function obj = fromTopicPath(topicPath)
            [shortname,group] = matlab.internal.doc.csh.DocPageTopicMap.parseTopicPath(topicPath);
            obj = matlab.internal.doc.csh.DocPageTopicMap(shortname,group);
            obj.TopicPath = topicPath;
        end
    end
    
    methods (Access=private)
        function docPage = mapSingleTopic(obj, id)
            ensureHelpTargetsPopulated(obj);
            mapping = getMappingForId(obj, id);
            if ~isempty(mapping)
                docPage = obj.toDocPage(id, mapping);
                return;
            end
            
            % If we get here we might have a special case...
            relPath = matlab.internal.doc.csh.mapSpecialCaseTopic(obj.ShortName, id);
            if relPath ~= ""
                docPage = matlab.internal.doc.url.MwDocPage;
                docPage.Product = obj.Product;
                docPage.RelativePath = relPath;
                docPage.Origin = matlab.internal.doc.url.DocPageOrigin("TopicId", [obj.TopicPath, id]);
            else
                % TODO: Think more about how to represent a page not 
                %       found issue. Returning empty doesn't work because
                %       we need to find a DocPage instance for each input
                %       argument.
                docPage = matlab.internal.doc.url.DocPage;
                docPage.IsValid = false;
            end
        end    

        function mapping = getMappingForId(obj, id)
            mapping = [];
            ensureHelpTargetsPopulated(obj);
            checkGroup = isValidGroup(obj);
            
            allHelpTargets = obj.HelpTargetsCache.Data;
            for i = 1:length(allHelpTargets)
                helpTargets = allHelpTargets{i};
                mappings = matlab.internal.doc.csh.DocPageTopicMap.findMappingInHelpTargets(helpTargets, id);
           
                if ~isempty(mappings)
                    if checkGroup && isfield(mappings, 'group')
                        groups = string({mappings.group});
                        groupIdx = find(groups == obj.Group, 1);
                        if ~isempty(groupIdx)
                            mapping = mappings(groupIdx);
                            return;
                        end
                    elseif isempty(mapping)
                        mapping = mappings(1);
                        if ~checkGroup
                            % If we don't have a group to check against
                            % we're done. If we do, continue on to see if
                            % we get a better group match later.
                            return;
                        end
                    end     
                end
            end            
        end

        function hasTopic = singleTopicExists(obj, id)
            hasTopic = ~isempty(getMappingForId(obj, id));
        end

        function docPage = toDocPage(obj, id, mapping)
            docPage = matlab.internal.doc.url.MwDocPage;
            docPage.Product = obj.Product;
            docPage.Origin = matlab.internal.doc.url.DocPageOrigin("TopicId", [obj.TopicPath, id]);
            if isempty(docPage.Product)
                % If the product is not resolved correctly, use the
                % shortname and help location properties to create a
                % Product struct
                prod = struct('ShortName', obj.ShortName, ...
                              'HelpLocation', obj.HelpLocation);
                docPage.Product = prod;
            end
            docPage.RelativePath = mapping.path;
            if isfield(mapping, "page_format") && mapping.page_format == "standalone_csh"
                docPage.ContentType = "Standalone";
            end
        end

        function ensureHelpTargetsPopulated(obj)
            % The cache data will be empty if either it has never been
            % populated or if the cache is stale.
            if isempty(obj.HelpTargetsCache.Data)
                retrieveHelpTargets(obj);
            end
        end
        
        function retrieveHelpTargets(obj)
            allHelpTargets = {};
            if obj.ShortName == ""
                return;
            end
            
            files = matlab.internal.doc.csh.findDocCatalogFiles("cshapi_helptarget", obj.ShortName);
            
            for mappingFile = files
                cshData = jsondecode(fileread(mappingFile));
                if ~isempty(cshData) 
                    if isfield(cshData, "helptargets")
                        allHelpTargets{end+1} = cshData.helptargets; %#ok<AGROW>
                    end
                    if isfield(cshData, "helplocation")
                        obj.HelpLocation = cshData.helplocation;
                    end
                end
            end

            if ~isempty(allHelpTargets)
                obj.HelpTargetsCache.Data = allHelpTargets;
            end
        end
        
        function valid = isValidGroup(obj)
            valid = obj.Group ~= "" && obj.Group ~= "helptargets" && obj.Group ~= obj.ShortName;
        end
    end
    
    methods (Static,Access=protected)
        function [shortname,group] = parseTopicPath(topicPath)
            shortname = "";
            group = "";
            if startsWith(topicPath,"mapkey:")
                mapKey = extractAfter(topicPath,"mapkey:");
                [shortname,group] = matlab.internal.doc.csh.findMapKey(mapKey);
            elseif endsWith(topicPath,".map")
                % This is an old map file location. Parse it into a product and group.
                [shortname,group] = matlab.internal.doc.csh.DocPageTopicMap.parseMapFilePath(topicPath);
            else
                parts = split(topicPath, "/" | "\");
                if length(parts) > 2
                    return;
                else
                    shortname = string(parts(1));
                    if length(parts) == 2
                        group = string(parts(2));
                    end
                end     
            end
        end
        
        function [shortname,group] = parseMapFilePath(mapFilePath)
            % Use forward slashes to avoid confusion with backslash as an escape
            % character
            mapFilePath = strrep(mapFilePath, "\", "/");

            % Before we attempt to parse the file path, make some corrections for
            % old file paths that have been moved.
            mapFilePath = matlab.internal.doc.csh.DocPageTopicMap.correctMapFilePath(mapFilePath);

            % First, use our old Java code to parse this into a shortname and 
            % map file name (which will be the group)
            [shortname,group,relPath] = matlab.internal.doc.csh.DocPageTopicMap.parseMapFileLocation(mapFilePath);

            if isempty(shortname) && startsWith(relPath, "mapfiles/")
                % Handle some special cases for map files that previously were not
                % located within a product's help folder
                [shortname,group] = matlab.internal.doc.csh.DocPageTopicMap.handleMapfilesFolder(relPath);
            end
            
            if isempty(shortname)
                % Make one last attempt at finding the product shortname by
                % looking for a doccenter.properties file for the product.
                [shortname,group] = matlab.internal.doc.csh.DocPageTopicMap.findHelpFolder(mapFilePath);
            end
            
            if isempty(shortname)
                shortname = "";
                group = "";
            end
        end

        function mapFilePath = correctMapFilePath(mapFilePath)
            import matlab.internal.doc.csh.DocPageTopicMap.replaceFolders;
            % MATLAB documentation no longer lives in the techdoc folder
            mapFilePath = replaceFolders(mapFilePath, "techdoc", "matlab");
            % We no longer place documentation under the toolbox or base folder
            mapFilePath = replaceFolders(mapFilePath, ["help","toolbox"], "help");
            mapFilePath = replaceFolders(mapFilePath, "base", []);
            % Physical modeling products changed locations
            mapFilePath = replaceFolders(mapFilePath, ["physmod","drive"], ["physmod","sdl","drive"]);
            mapFilePath = replaceFolders(mapFilePath, ["physmod","mech"], ["physmod","sm","mech"]);
            mapFilePath = replaceFolders(mapFilePath, ["physmod","powersys"], ["physmod","sps","powersys"]);
        end

        function mapFilePath = replaceFolders(mapFilePath, folders, replacements)
            import matlab.internal.doc.csh.DocPageTopicMap.folderString;
            mapFilePath = strrep(mapFilePath, folderString(folders), folderString(replacements));
        end

        function folderStr = folderString(folders)
            if isempty(folders)
                folderStr = "/";
            else
                folderStr = sprintf("/%s", folders) + "/";
            end
        end
        
        function [shortname,group] = handleMapfilesFolder(pathFromDocRoot)
            mapFileName = regexp(pathFromDocRoot, "^mapfiles/(.*)\.map$", "tokens", "once");
            switch mapFileName
                case "creating_guis" 
                    shortname = "matlab"; group = "creating_guis";
                case "creating_plots"
                    shortname = "matlab"; group = "creating_plots";
                case "matlab_env_csh"
                    shortname = "matlab"; group = "env_csh";
                case "learn_matlab"
                    shortname = "matlab"; group = "learn_matlab";
                case "matlab_env"
                    shortname = "matlab"; group = "matlab_env";
                case "matlab_prog"
                    shortname = "matlab"; group = "matlab_prog";
                case "ref"
                    shortname = "matlab"; group = "matlab_ref";
                case "visualize"
                    shortname = "matlab"; group = "matlab_visualize";
                case "control"
                    shortname = "control"; group = "control";
                case "finderiv"
                    shortname = "finderiv"; group = "helptargets";
                case "simulink"
                    shortname = "simulink"; group = "helptargets";
                case "stateflow"
                    shortname = "stateflow"; group = "stateflow";
                case "xpc"
                    shortname = "xpc"; group = "xpc";
                otherwise
                    shortname = []; group = [];
            end
        end
        
        function [shortname,group] = findHelpFolder(mapFilePath)
            [curFolder,group] = fileparts(mapFilePath);
            shortname = [];
            while isempty(shortname) && ~isempty(curFolder)
                [parent,name] = fileparts(curFolder);
                if exist(fullfile(curFolder,'doccenter.properties'),'file')
                    shortname = name;
                elseif parent ~= curFolder
                    curFolder = parent;
                else
                    return;
                end
            end
        end
        
        function mapping = findMappingInHelpTargets(helpTargets, id)
            mapping = [];
            
            if strlength(id) >= namelengthmax
                mapping = matlab.internal.doc.csh.findLongTopicId(helpTargets, id);
                if ~isempty(mapping) 
                    return;
                end
            end
            
            if isfield(helpTargets, id)
                mapping = helpTargets.(id);
            else
                idField = matlab.lang.makeValidName(id);
                if ~strcmp(idField, id) && isfield(helpTargets, idField)
                    mapping = helpTargets.(idField);
                end
            end
        end        
    end

    methods (Static,Access=private)
        function [shortname,group,relPath] = parseMapFileLocation(mapFile)
            shortname = [];
            group = [];
            relPath = [];
           
            docPage = matlab.internal.doc.url.parseDocPage(mapFile);
            if ~isempty(docPage)
                if isa(docPage, "matlab.internal.doc.url.MwDocPage") && ~isempty(docPage.Product)
                    shortname = docPage.Product.ShortName;
                    [~,group] = fileparts(mapFile);
                else
                    relPath = join(docPage.RelativePath, "/");
                end
            end
        end
    end
end
