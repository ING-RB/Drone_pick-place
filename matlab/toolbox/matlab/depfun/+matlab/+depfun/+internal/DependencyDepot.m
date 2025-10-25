classdef DependencyDepot < handle
%

%   Copyright 2012-2024 The MathWorks, Inc.

    properties
        dbName
        Target
    end
    
    properties (Access = private)
        SqlDBConnObj 
        Language2ID
        ID2Language        
        FileSep = filesep;
        MatlabRoot = matlabroot;
        tableData = init_db_table_data;
        fileClassifier  % Simple file classification based on file extension
        isPC
        Environment
        Vertex2FileID;
        Principal2FileID;
        Principals
    end
    
	methods
        
        function obj = DependencyDepot(DBName, readonly)
            % Input must be a string
            if ~ischar(DBName)
                error(message('MATLAB:depfun:req:InvalidInputType', ...
                    1, class(DBName), 'char'))
            end
            
            % fullpath of the database
            obj.dbName = DBName;

            % Create a database connector object.
            try 
                obj.SqlDBConnObj = matlab.depfun.internal.database.SqlDbConnector;
            catch ME
                error(message(...
                    'MATLAB:depfun:req:InvalidDatabaseConnectionObj',...
                    ME.message))
            end

            % create a new database if it doesn't exist yet.
            created = false;
            if ~exist(obj.dbName,'file')
                created = true;
                obj.SqlDBConnObj.createDatabase(obj.dbName);
            end

            if(nargin > 1 && readonly == true)
                % connect read-only
                obj.SqlDBConnObj.connectReadOnly(obj.dbName);                
            else
                % connect to the database as read/write
                obj.SqlDBConnObj.connect(obj.dbName);
            end
             
            % if we just created the database, initialize the tables.
            if created
                if(ispc)
                    % the default blocksize for NTFS is 4K
                    % if this is a PC set the blocksize of the DB to 4K
                    % this needs to be done before the first table is created. 
                    obj.SqlDBConnObj.doSql('PRAGMA page_size=4096', false);
                end
                obj.createTables();
            end
            
            % we're never going to try to recover the DB if something goes wrong
            % just shut all this stuff off
            obj.SqlDBConnObj.doSql('PRAGMA synchronous=OFF;', false);
            obj.SqlDBConnObj.doSql('PRAGMA journal_mode=OFF;', false);
            obj.SqlDBConnObj.doSql('PRAGMA temp_store=MEMORY;', false); 
            
            obj.fileClassifier = matlab.depfun.internal.FileClassifier;
            obj.isPC = ispc;
            obj.Environment = matlab.depfun.internal.reqenv;
            obj.Vertex2FileID = containers.Map('KeyType', 'uint64', 'ValueType', 'double');
            obj.Principal2FileID = containers.Map('KeyType', 'char', 'ValueType', 'double');
        end
        
        function delete(obj)
            obj.disconnect();
        end

        function disconnect(obj)
            if ~isempty(obj.SqlDBConnObj)
                obj.SqlDBConnObj.disconnect();
            end
        end
        
        function result = fetchNonEmptyRow(obj)
        % Fetch a row that is not expected to be empty.
        % If it is empty, report an error.
            result = obj.SqlDBConnObj.fetchRow();
            if isempty(result)
                error(message('MATLAB:depfun:req:EmptyFetchResult'))
            end
        end
        
        function result = fetchNonEmptyRows(obj)
        % Fetch a set of rows that is not expected to be empty.
        % If it is empty, report an error.
            result = obj.SqlDBConnObj.fetchRows();
            if isempty(result)
                error(message('MATLAB:depfun:req:EmptyFetchResultList'))
            end
        end
        
        function result = fetchRow(obj)
            result = obj.SqlDBConnObj.fetchRow();
        end
        
        function result = fetchRows(obj)
            result = obj.SqlDBConnObj.fetchRows();
        end
        
        function doSql(obj, sqlCmd)
            obj.SqlDBConnObj.doSql(sqlCmd);
        end
        
        function startID = recordFileData(obj, symList, vertexID)
        % Bulk insert the files that the symbols represent, using their
        % vertex info to properly assign file IDs. If no vertexIDs are
        % provided, the files will be labelled from obj.maxFileID to obj.maxFileID +
        % length(symlist) - 1. The fileID of the first inserted file is
        % returned as startID.
            
            BuiltinClassID = ...
                int32(matlab.depfun.internal.MatlabType.BuiltinClass);

            BuiltinFunctionID = ...
                int32(matlab.depfun.internal.MatlabType.BuiltinFunction);
            
            MatlabID = obj.Language2ID('MATLAB');
            CppID = obj.Language2ID('CPP');
            
            numSym = length(symList);

            % if vertexIDs were provided, determine which of those vertices 
            % are already in the Vertex2FileID map
            if(nargin == 3)
                inMap = obj.Vertex2FileID.isKey(num2cell(vertexID));
            else
                inMap = false(numSym, 1);
            end
            
            numNew = nnz(~inMap);
            newSymList = symList(~inMap);

            % determine the first available fileID to use. If nothing has
            % been inserted into the file table yet, try to find the last 
            % used fileID in the mapping
            obj.SqlDBConnObj.doSql('SELECT COALESCE(max(ID), 0) FROM File');
            startID = double(obj.SqlDBConnObj.fetchRow());
            if(~isempty(obj.Vertex2FileID))
                allMapped = obj.Vertex2FileID.values;
                allMapped = [allMapped{:}];
                startID = max([allMapped, startID]);
            end

            startID = startID + 1;
            fileID = startID : startID + numNew - 1;
            
            % add any new vertices to the mapping 
            if(nargin == 3 && numNew > 0)
                newMap = containers.Map(vertexID(~inMap), fileID);
                obj.Vertex2FileID = [obj.Vertex2FileID; newMap];
            end
                        
            Type = [newSymList.Type];
            TypeID = int32(Type);
            
            LanguageID = ones(1, numNew) .* MatlabID;
            BuiltinIdx = logical(TypeID==BuiltinClassID | ...
                                 TypeID==BuiltinFunctionID);
            LanguageID(BuiltinIdx) = CppID;

            % for transplantability, only save relative path to the matlabroot 
            WhichResult = strrep({newSymList.WhichResult}, ...
                                 [obj.MatlabRoot obj.FileSep], '');

            % canonical path
            WhichResult = strrep(WhichResult, obj.FileSep, '/');
            Symbol = {newSymList.Symbol};
            
            % Insert the files into the file table; bulk insert for 
            % performance.
            obj.SqlDBConnObj.insert('File', 'ID', fileID, ...
                'Path', WhichResult, 'Language', LanguageID, ...
                'Type', TypeID, 'Symbol', Symbol);
        end

        function recordProxyData(obj, symList)
        % Fill in the Proxy_Principal table. Each row in the table
        % represents a single proxy -> principal relationship. There are at
        % least as many rows in the table as there are principals. There
        % may be more rows, if multiple proxies represent the same
        % principals.
        %
        % To fill in the table, we create two vectors of the same size,
        % proxyID and principalID. Since we're creating the table here, we
        % can deduce the IDs a priori, which is much faster than querying
        % the database.
        % 

            % stores only the new principals that are not yet in the file table
            principalSymbols = matlab.depfun.internal.MatlabSymbol.empty(1,0);
            proxyID = [];
            principalID = [];
            vertexID = 0;
            expandedProxy = containers.Map('KeyType','char',...
                                           'ValueType','logical');
                                      
            % TODO: Consider moving this loop into a method owned by
            % Completion. buildTraceList may need something like it.
            for symbol = symList
                pList = principals(symbol);
                if ~isempty(pList)
                    % Store proxy names as full paths without extension, 
                    % so we can detect, for example, when a .p and .m file 
                    % represent the same principals.
                    %
                    % Why does this matter? Because the file list in the
                    % database cannot have duplicate entries. Therefore,
                    % the files in the principal list must be unique.
                    %
                    % In the case of a built-in, try to find the class
                    % directory on the path and use that for a key.
                    proxyName = proxyLocation(symbol);
                    proxyFileID = obj.Vertex2FileID(vertexID);
                    
                    % only new principals that aren't already in the
                    % proxy_principal table need to get added
                    if(~isempty(obj.Principal2FileID))
                        inMap = obj.Principal2FileID.isKey({pList.WhichResult});
                        pList = pList(~inMap);
                    end  
                    
                    if isKey(expandedProxy, proxyName)
                        % Find the IDs of the principals (already
                        % assigned) by finding the locations of the
                        % principals in the principalSymbols list.
                        newPrincipals = zeros(1,numel(pList));
                        principalPaths = {principalSymbols.WhichResult};
                        for n=1:numel(pList)
                            matchP = strcmp(pList(n).WhichResult, ...
                                            principalPaths);
                            id = find(matchP);
                            newPrincipals(n) = id;
                        end
                        newProxy = ones(1,numel(pList)) .* proxyFileID;
                    else
                        % Remember that we've expanded this proxy already.
                        expandedProxy(proxyName) = true;

                        % Remember the IDs of the proxy and its principals.
                        % This code assumes files are inserted into the
                        % database in the same order as they appear in the
                        % array.
                        pCount = numel(principalSymbols);
                        numPList = numel(pList);
                        newPrincipals = (1:numPList) + pCount;
                        newProxy = ones(1,numPList) .* proxyFileID;
   
                        principalSymbols = [principalSymbols pList]; %#ok
                    end
                    proxyID = [proxyID newProxy];  %#ok
                    principalID = [ principalID newPrincipals ]; %#ok
                end
                vertexID = vertexID + 1;
            end
            
            % Add the principals to the file table. By definition, the
            % principal set and the proxy set have an empty intersection.
            if ~isempty(principalSymbols)
                startID = recordFileData(obj, principalSymbols);
                
                % match the principalIDs to those written in the file table
                principalID = principalID + startID - 1;
                
                % Bulk insert
                obj.SqlDBConnObj.insert('Proxy_Principal', ...
                                        'Proxy', proxyID, ...
                                        'Principal', principalID);
            end
        end

        function recordDependency(obj, target, graph)
        % Write the level-0 dependency to the database

            obj.Target = target;

            % Insert file information to table File            
            % modifications for performance, g904544
            % (1) cache Language table
            cacheLanguageTable(obj);

            % If the graph is empty, stop. Do nothing else.
            if isempty(graph) || graph.VertexCount == 0
                return;
            end

            % (2) use bulk insert
            % retrieve data from each vertex in the graph
            vertexIDs = graph.VertexIDs()';
            symList = partProperty(graph, 'Data', 'Vertex');
            symList = [symList.symbol];

            % Fill in the file table
            obj.recordFileData(symList, vertexIDs);

            obj.clearTable('Level0_Use_Graph');
            % Insert level-0 dependency to table Level0_Use_Graph
            obj.recordEdges(graph, 'Level0_Use_Graph');

            % Insert principal/proxy data.
            obj.recordProxyData(symList);
        end

        function recordClosure(obj, graph)
            % Insert transitive closure to table Proxy_Closure
            obj.recordEdges(graph, 'Proxy_Closure');            
        end
        
        function recordFileToComponentMap(obj, fileToComponents)
        % Records required components for each file

            if isempty(fileToComponents)
                return;
            end
            
            fileList = keys(fileToComponents);
            % newReqs is a cell array. Each element is a cell
            % array of required components of each file.            
            newReqs = values(fileToComponents, fileList);
            
            obj.SqlDBConnObj.doSql('SELECT Name FROM Required_Components;');
            % if the dfdb is being created from scratch, recordedReqs should be empty
            recordedReqs = obj.SqlDBConnObj.fetchRows();

            toRecord = setdiff([newReqs{:}], [recordedReqs{:}]); 
            obj.SqlDBConnObj.insert('Required_Components', 'Name', toRecord);
            
            obj.SqlDBConnObj.doSql('SELECT ID, Name FROM Required_Components;');
            tmp = obj.SqlDBConnObj.fetchRows();
            ids = cell2mat(cellfun(@(r)r{1},tmp,'UniformOutput',false))';
            componentList = cellfun(@(r)r{2},tmp,'UniformOutput',false)';
                    
            % Replace component name with component ID
            for k = 1:numel(componentList)
                newReqs = cellfun(@(c)regexprep(c, ...
                               ['^' componentList{k} '$'], num2str(ids(k))), ...
                               newReqs, 'UniformOutput', false);
            end                        
            
            fileList = matlab.depfun.internal.PathNormalizer.normalizeFiles(fileList, true);
            fileID = double(cell2mat(cellfun(@(p)obj.findOrInsertFile(p), ...
                          fileList, 'UniformOutput', false)));
            
            % preallocation for performance
            num_rows = sum(cellfun(@(a)numel(a),newReqs));
            fileID_componentID = zeros(num_rows,2);
            count = 0;
            for k = 1:numel(fileList)
                num_component = numel(newReqs{k});
                fileID_componentID(count+1:count+num_component, :) = ...
                    [ ones(num_component,1).*fileID(k) ...
                      str2double(newReqs{k})' ];
                count = count + num_component;
            end
            
            obj.SqlDBConnObj.insert('File_Components', ...
                                    'File', fileID_componentID(:,1), ...
                                    'Component', fileID_componentID(:,2));
                                
            obj.SqlDBConnObj.doSql('PRAGMA index_info(File_Components_Index);');
            if(isempty(obj.SqlDBConnObj.fetchRows()))
                obj.SqlDBConnObj.doSql([...
                    'CREATE INDEX File_Components_Index ON ' ...
                    'File_Components(File)']);
            end
        end

        function recordFileToBuiltinMap(obj, fileToBuiltins)
            import matlab.depfun.internal.requirementsConstants
            
            if isempty(fileToBuiltins)
                return;
            end
            
            fileList = keys(fileToBuiltins);
            % calledBuiltins is a cell array. Each element is a cell
            % array of called builtins in each file.            
            calledBuiltins = values(fileToBuiltins, fileList);

            fileList = matlab.depfun.internal.PathNormalizer.normalizeFiles(fileList, true);
            fileID = double(cell2mat(cellfun(@(p)obj.findOrInsertFile(p), ...
                          fileList, 'UniformOutput', false)));
            
            % Ignore built-ins in mcr numerics
            ignoreList = requirementsConstants.pcm_nv.builtinShippedByProduct('mcrproducts/mcr_numerics');
            
            % preallocation for performance
            num_rows = sum(cellfun(@(a)numel(a),calledBuiltins));
            flatten_fileID = zeros(num_rows,1);
            flatten_builtinSymbol = cell(num_rows,1);
            count = 0;
            for k = 1:numel(fileList)
                tmp = unique(cellfun(@(c)c.Symbol,calledBuiltins{k},'UniformOutput',false))';
                tmp = setdiff(tmp, ignoreList);
                if ~isempty(tmp)
                    num_builtin = numel(tmp);
                    flatten_fileID(count+1:count+num_builtin) = ...
                        ones(num_builtin,1).*fileID(k);                    
                    flatten_builtinSymbol(count+1:count+num_builtin) = tmp;
                    count = count + num_builtin;
                end
            end
            if count < num_rows
                flatten_fileID(count+1:end) = [];
                flatten_builtinSymbol(count+1:end) = [];
            end
            
            if ~isempty(flatten_fileID)
                obj.SqlDBConnObj.insert('File_Builtins', ...
                                        'File', flatten_fileID, ...
                                        'Builtin', flatten_builtinSymbol);
            end
        end

        function updateComponentDependencyTables(obj, ...
                                      requiredComponents, fileToComponents)
            obj.clearComponentDependencyTables();
            
            obj.SqlDBConnObj.insert('Required_Components', ...
                                    'Name', requiredComponents);
 
            obj.SqlDBConnObj.insert('File_Components', ...
                                    'File', fileToComponents(:,1), ...
                                    'Component', fileToComponents(:,2));
            obj.SqlDBConnObj.doSql([...
                'CREATE INDEX File_Components_Index ON ' ...
                'File_Components(File)']);
        end

        function updateFileBuiltinTable(obj, fileID, builtins)
            obj.clearTable('File_Builtins');
            
            obj.SqlDBConnObj.insert('File_Builtins', ...
                                    'File', fileID, ...
                                    'Builtin', builtins);
        end
        
        function result = getRequiredComponents(obj, varargin)
            if numel(varargin) == 0
                obj.SqlDBConnObj.doSql('SELECT Name From Required_Components ORDER BY ID ASC;');
                result = decell(obj.SqlDBConnObj.fetchRows());
            end
        end
        
        function result = getFileToComponents(obj, request)
            obj.SqlDBConnObj.doSql('SELECT File, Component From File_Components;');
            tmp = obj.SqlDBConnObj.fetchRows();            
            switch request
                case 'file'
                    result = cell2mat(cellfun(@(r)r{1},tmp,'UniformOutput',false))';
                case 'component'
                    result = cell2mat(cellfun(@(r)r{2},tmp,'UniformOutput',false))';
                otherwise
                    result = [];
            end
        end
        
        function result = getFileToBuiltins(obj, request)
            obj.SqlDBConnObj.doSql('SELECT File, Builtin From File_Builtins;');
            tmp = obj.SqlDBConnObj.fetchRows();            
            switch request
                case 'file'
                    result = cell2mat(cellfun(@(r)r{1},tmp,'UniformOutput',false))';
                case 'builtin'
                    result = cellfun(@(r)r{2},tmp,'UniformOutput',false)';
                otherwise
                    result = [];
            end
        end

        function [graph, file2Vertex] = getDependency(obj, target) %#ok<INUSD>
        % Return level-0 dependency and FilePath2Vertex mapping
        % graph = getDependency(obj [,target])

            % make sure the caches required by createGraphAndAddEdges are
            % initialized properly
            matlab.depfun.internal.cacheExist();
            matlab.depfun.internal.cacheWhich();
            
            % create a graph based on File and Level0_Use_Graph tables
            [graph, file2Vertex] = obj.createGraphAndAddEdges('Level0_Use_Graph');
        end

        function graph = getClosure(obj, target) %#ok<INUSD>
        % Return full closure
        % graph = getClosure(obj [,target])

            % create a graph based on File and Proxy_Closure tables
            graph = obj.createGraphAndAddEdges('Proxy_Closure');
        end

        function fileList = getFile(obj, target) %#ok<INUSD>
        % fileList = getFile(obj [, target])

            obj.SqlDBConnObj.doSql('SELECT ID, Path from File;');
            % bulk select
            rawList = obj.SqlDBConnObj.fetchRows();
            num_files = numel(rawList);
            % pre-allocation for the struct array
            fileList(num_files).fileID = [];
            fileList(num_files).path = '';
            for i = 1:num_files
                fileList(i).fileID = rawList{i}{1};
                if matlab.depfun.internal.PathNormalizer.isfullpath(rawList{i}{2})
                    fileList(i).path = rawList{i}{2};
                else
                    fileList(i).path = [strrep(obj.MatlabRoot,obj.FileSep,'/') '/' rawList{i}{2}];
                end
            end
        end

        function tf = requires(obj, client, service)
        % Does the client require the service? Client or service may be a 
        % "set" -- the other argument must be a scalar. Data type: numeric
        % IDs or string file names.

            if iscell(client) && iscell(service)
                error(message('MATLAB:depfun:req:DuplicateArgType', ...
                              class(client), 1, 2, class(client)))
            end

            if isnumeric(client)
                clientID = client;
            else
                clientID = lookupPathID(obj, client);
            end
            if isnumeric(service)
                serviceID = service;
            else
                serviceID = lookupPathID(obj, service);
            end

            if ~isscalar(serviceID)
                serviceSet = sprintf('%d,', serviceID);
                serviceSet(end) = []; % Chop off trailing comma
                q = sprintf(['SELECT Dependency FROM Proxy_Closure ' ...
                             'WHERE Client = %d AND Dependency IN (%s)'], ...
                            clientID, serviceSet);
                targetID = serviceSet;
            else
                clientSet = sprintf('%d,', clientID);
                clientSet(end) = []; % Chop off trailing comma
                q = sprintf(['SELECT Dependency FROM Proxy_Closure ' ...
                             'WHERE Client IN (%s) AND Dependency = %d'], ...
                            clientSet, serviceID);
                targetID = serviceID;
            end
            obj.SqlDBConnObj.doSql(q);
            inClosure = cellfun(@(r)r{1}, obj.SqlDBConnObj.fetchRows);
            tf = ismember(targetID, inClosure);
        end

        function [list, notFoundList] = requirements(obj, files)
            if ~iscell(files)
                files = { files };
            end
            
            % G1135834: Workaround for the BIBI issue in Bsignal.
            % Clients are always m-files. No dependencies are recorded
            % under p-files. Thus, query m-files corresponding to p-files.
            pfileIdx = ~cellfun('isempty', regexp(files, '\.p$'));
            mFiles = regexprep(files(pfileIdx), '\.p$', '.m');
            files = union(files, mFiles);
            
            % convert to SQL-friendly canonical path relative to matlabroot
            normalized_path = matlab.depfun.internal.PathNormalizer.normalizeFiles(files, true);
            notFoundList = struct([]);

            % g1207598 ssegench
            % Create a couple temp tables to hold results
            % Table: tempPathList
            %    Holds the initial list of paths. 
            %    This table is used twice.
            %     (1) Populate tempFileList with the file ids for the initial set of files
            %     (2) Identify which of the initial set of files do not have ids (not in the DB)
            % Table: tempFileList
            %    Holds the list of file ids of dependent files
            %    This table is populated in 4 steps
            %     (1) Add the file ids for the initial set of files passed into 
            %         this function (requirements) 
            %     (2) Add any file ids that are proxies for files already in this table
            %     (3) Add the dependencies for the files already in this table
            %     (4) Add the principals for any proxies that are in this table
            %    At this point, the table contains a non-unique list of all the dependent 
            %     files for the initial list of paths, including the file ids (if they exist)
            %     for the initial list. The unique list of attributes for these files can now 
            %     be retrieved from the database with a single select statement.
            % The benefit to this approach is two fold. 
            %   - It eliminates a significant amount of marshaling of data back and forth between 
            %     MATLAB and the database. We don't need to convert a cell array of cell arrays of ints 
            %     into an array, only to iterate over that array, passing those ints back 
            %     into the database.
            %   - It allows the attributes for the files to be retrieved in a single select 
            %     statement. The previous implementation iterated over a list and retrieved the 
            %     dependencies (with their attributes) for each file. If there were a lot of 
            %     overlap in the dependencies, the process would retrieve the same file multiple 
            %     times. 
            tempPathTableName = 'tempPathList';
            createTempTable(obj, tempPathTableName, {'path TEXT'});
            tempPathTableDrop = onCleanup(@() obj.SqlDBConnObj.doSql(['DROP TABLE ' tempPathTableName ';']));
            
            tempFileTableName = 'tempFileList';
            createTempTable(obj, tempFileTableName, {'id int'});
            tempFileTableDrop = onCleanup(@() obj.SqlDBConnObj.doSql(['DROP TABLE ' tempFileTableName ';'])); 
            
            obj.SqlDBConnObj.doSql([...
                'CREATE INDEX Temp_File_Index ON ' ...
                 tempFileTableName '(id)']);
            
             
            %put the path list into the temp table
            % sqlite has a limit (500) on the number of terms in the insert
            maxInsertCount = 500;
            if(numel(normalized_path) <=maxInsertCount)
                pathInsertStmt = sprintf( ...
                    ['INSERT INTO ' tempPathTableName ...
                    ' (path)' ...
                    ' VALUES (''%s'');'], strjoin(normalized_path, '''), ('''));
                obj.SqlDBConnObj.doSql(pathInsertStmt);
            else
               % insert in batches of maxInsertCount in size 
               startIndex = 1;
               endIndex = maxInsertCount;
               lastBatch = false; 
               while true
                   if(endIndex < numel(normalized_path))
                        tmpPath = normalized_path(startIndex : endIndex);
                   else 
                        tmpPath = normalized_path(startIndex : end);
                        lastBatch = true;
                   end
                   pathInsertStmt = sprintf( ...
                    ['INSERT INTO ' tempPathTableName ...
                    ' (path)' ...
                    ' VALUES (''%s'');'], strjoin(tmpPath, '''), ('''));
                    obj.SqlDBConnObj.doSql(pathInsertStmt);
                    
                    if(lastBatch)
                        break;
                    end
                    
                    startIndex = startIndex + maxInsertCount;
                    endIndex = endIndex + maxInsertCount;
               end
                
            end
            
            % populate the temp id table with the ids that exist for the paths
            idInsertStmt = ['INSERT INTO ' tempFileTableName ...
                ' (id)' ...
                ' SELECT ID FROM File a, ' tempPathTableName ' b' ...
                ' WHERE a.path = b.path;'];
            obj.SqlDBConnObj.doSql(idInsertStmt);
            
            % add to the id table any proxies
             idInsertStmt = ['INSERT INTO ' tempFileTableName ...
                ' (id)' ...
                ' SELECT Proxy FROM Proxy_Principal a, ' tempFileTableName ' b' ...
                ' WHERE a.Principal = b.id;'];
            obj.SqlDBConnObj.doSql(idInsertStmt);

            % get the list of not Found Files
            
            obj.SqlDBConnObj.doSql(['SELECT path ' ...
                             ' FROM ' tempPathTableName ' a' ...
                             ' WHERE not exists' ...
                                 ' (SELECT 1 FROM File b' ...
                                 '  WHERE a.path = b.Path);']);
            notFoundFiles = obj.SqlDBConnObj.fetchRows();
           
            for i = 1:numel(notFoundFiles)
                % notFoundFiles has the normalized path
                % need to put the original file in the list
                if ~isempty(char(notFoundFiles{i}))
                    notFound = files{strcmp(notFoundFiles{i}, normalized_path)};
                    notFoundList(end+1).name = 'N/A'; %#ok<AGROW>
                    notFoundList(end).type = 'N/A';
                    notFoundList(end).path = strrep(notFound, obj.FileSep, '/');
                    notFoundList(end).language = 'N/A';
                end
            end
            
            % Back to the dependencies.
            % Add all of them to the table.
             idInsertStmt = ['INSERT INTO ' tempFileTableName ...
                ' (id)' ...
                ' SELECT Dependency ' ...
                             'FROM Proxy_Closure '  ...
                             'WHERE exists (select 1 from ' tempFileTableName ' b ' ...
                             'Where Proxy_Closure.Client = b.id);'];
            obj.SqlDBConnObj.doSql(idInsertStmt);
           
            % add the principals
            idInsertStmt = ['INSERT INTO ' tempFileTableName ...
                ' (id)' ...
                ' SELECT Principal ' ...
                             ' FROM Proxy_Principal '  ...
                             ' WHERE exists (select 1 from ' tempFileTableName ' b ' ...
                             ' Where Proxy_Principal.Proxy = b.id);'];
            obj.SqlDBConnObj.doSql(idInsertStmt);            
                 
            % The tempFileTable now contains the list of all the dependent files.
            % One query to select attributes (symbol, type, etc.) for the unique list.
            
            % The below constants represent the order of columns in the select statement below.
            % Update these appropriately if the select statement changes.
            symbolCol = 1;
            typeCol = 2;
            pathCol = 3;
            languageCol = 4;
            
            obj.SqlDBConnObj.doSql(['SELECT Symbol, Type, Path, Language ' ...
                             ' FROM File  WHERE exists (select 1 from ' tempFileTableName ' b ' ...
                             ' Where File.Id = b.id);']);
                
            fileInfo = obj.SqlDBConnObj.fetchRows();
            
            
            % build the trace list below
            total_num_dep = length(fileInfo);

            if ~isempty(fileInfo)
                if isempty(obj.ID2Language)
                    cacheLanguageTable(obj);
                end
            end
            
            % pre-allocation for the dependency list
            if total_num_dep > 0
                list(total_num_dep).name = '';
                list(total_num_dep).type = '';
                list(total_num_dep).path = '';
                list(total_num_dep).language = '';                
            else
                list = struct([]);
            end
            
            for i = 1:total_num_dep
                % convert typeID and langID to string
                type = char(matlab.depfun.internal.MatlabType(fileInfo{i}{typeCol}));                
                lang = obj.ID2Language(fileInfo{i}{languageCol});

                % build trace list
                list(i).name = fileInfo{i}{symbolCol};
                list(i).type = type;
                if matlab.depfun.internal.PathNormalizer.isfullpath(fileInfo{i}{pathCol})
                    list(i).path = fileInfo{i}{pathCol};
                else
                    list(i).path = [strrep(obj.MatlabRoot, ...
                                    obj.FileSep,'/') '/' fileInfo{i}{pathCol}];
                end
                list(i).language = lang;
            end
            
            % combine DepList and NotFoundList
            % Files on the MatlabFile list are valid existing files based on the
            % WHICH result in PickOutUserFiles() in Completion.m, so they
            % should be on the return list, though they might not be in the
            % call closure table. (For example, files on the Inclusion list 
            % are often not found in the call closure table.)
            list = [list notFoundList];
        end
        
        function cList = requiredComponents(obj, files)
        % Returns a list of required components of given files.
            
            cList = {};
            
            % Get File ID
            % convert to canonical path relative to matlabroot
            normalized_path = matlab.depfun.internal.PathNormalizer.normalizeFiles(files, true);
            normalized_path_str = sprintf('''%s'',', normalized_path{:});
            % Remove the trailing ','
            normalized_path_str = normalized_path_str(1:end-1);
            query = sprintf('SELECT ID FROM FILE WHERE PATH IN (%s);', ...
                            normalized_path_str);
            obj.SqlDBConnObj.doSql(query);
            file_id = cell2mat(decell(obj.SqlDBConnObj.fetchRows()));
            
            if ~isempty(file_id)
                % Convert File ID to Proxy ID
                obj.SqlDBConnObj.doSql('CREATE TEMP TABLE FileID (f);');
                cleanup = onCleanup(@()obj.SqlDBConnObj.doSql('DROP TABLE FileID;'));
                obj.SqlDBConnObj.insert('FileID', 'f', file_id);
                
                query = ['   SELECT IFNULL(Proxy_Principal.Proxy, FileID.f) ' ...
                         '     FROM FileID ' ...
                         'LEFT JOIN Proxy_Principal ' ...
                         '       ON FileID.f = Proxy_Principal.Principal;'];
                obj.SqlDBConnObj.doSql(query);
                proxy_id = decell(obj.SqlDBConnObj.fetchRows());

                % Get required components of all proxies.
                proxy_id_str = sprintf('%d,',proxy_id{:});
                proxy_id_str = proxy_id_str(1:end-1);
                query = ['    SELECT DISTINCT Required_Components.Name ' ...
                         '      FROM Required_Components ' ...
                         'INNER JOIN Proxy_Component_Closure ' ...
                         '        ON Required_Components.ID = Proxy_Component_Closure.Component ' ...
                         ' WHERE Proxy_Component_Closure.Proxy IN (' proxy_id_str ');'];
                obj.SqlDBConnObj.doSql(query);
                cList = decell(obj.SqlDBConnObj.fetchRows());
            end
        end
        
        function result = getflattenGraph(obj, request)
        % retrieve file list and level-0 call closure from the database
            switch request
                case 'file'
                    obj.SqlDBConnObj.doSql('SELECT ID, Path FROM File ORDER BY ID ASC;');
                    tmp = obj.SqlDBConnObj.fetchRows();
                    ids = cell2mat(cellfun(@(r)r{1},tmp,'UniformOutput',false))';
                    paths = cellfun(@(r)r{2},tmp,'UniformOutput',false)';
                    result = {ids, paths};
                case 'type'
                    obj.SqlDBConnObj.doSql('SELECT Type FROM File ORDER BY ID ASC;');
                    result = cell2mat(decell(obj.SqlDBConnObj.fetchRows()));
                case 'symbol'
                    obj.SqlDBConnObj.doSql('SELECT Symbol FROM File ORDER BY ID ASC;');
                    result = decell(obj.SqlDBConnObj.fetchRows());
                case 'call_closure'            
                    obj.SqlDBConnObj.doSql('SELECT Client, Dependency FROM Level0_Use_Graph;');
                    tmp = obj.SqlDBConnObj.fetchRows();                    
                    client = cell2mat(cellfun(@(r)r{1},tmp,'UniformOutput',false))';
                    dependency = cell2mat(cellfun(@(r)r{2},tmp,'UniformOutput',false))';
                    result = [client dependency];
                otherwise
                    result = [];
            end
        end
        
        function recordFlattenGraph(obj, target, FileList, ...
                                    TypeID, Symbol, CallClosure, TClosure)
        % Write the flatten graph to the database
        
            obj.Target = target;

            % Insert file information to table File            
            % modifications for performance, g904544
            % (1) cache Language table
            cacheLanguageTable(obj);
            
            BuiltinClassID = int32(matlab.depfun.internal.MatlabType.BuiltinClass);
            BuiltinFunctionID = int32(matlab.depfun.internal.MatlabType.BuiltinFunction);
            
            MatlabID = obj.Language2ID('MATLAB');
            CppID = obj.Language2ID('CPP');
            
            % (2) use bulk insert
            % retrieve data from each vertex in the graph
            numFile = length(FileList);            
            FileID = 1:numFile;
            
            LanguageID = ones(1, numFile) .* MatlabID;
            BuiltinIdx = logical(TypeID==BuiltinClassID | TypeID==BuiltinFunctionID);
            LanguageID(BuiltinIdx) = CppID;
            
            % write to the database; insert the data at once
            obj.SqlDBConnObj.insert('File', 'ID', FileID, ...
                'Path', FileList, 'Language', LanguageID, ...
                'Type', TypeID, 'Symbol', Symbol);
            
            % insert level-0 call closure to Level0_Use_Graph
            obj.SqlDBConnObj.insert('Level0_Use_Graph', ...
                'Client', CallClosure(:,1), 'Dependency', CallClosure(:,2));
            
            % Insert full closure edges into Proxy_Closure table. Since this 
            % can be a long list, be careful about memory usage. Don't ask the
            % closure object for more memory than MATLAB can provide. Pay
            % attention to both the total amount of memory available and the
            % largest contiguous block.

            % To further increase performance, turn off journaling for this
            % series of SQL commands. Drawback: system failure during this 
            % time will result in a corrupt database. Saving throw:
            % the database isn't complete yet, and is just as unusable as if it
            % were corrupt.

            edgeCount = TClosure.EdgeCount;
            vID = feval(TClosure.VertexIdType,0); %#ok<NASGU>
            vIdData = whos('vID');
            edgeBytes = vIdData.bytes * 2;
            offset = 0;
            
            % Disable automatic transaction for pragma statement
            obj.SqlDBConnObj.doSql('PRAGMA journal_mode = OFF', false);

            % Make something up. Something reasonable. On non-Windows machines,
            % set this value so that we try to allocate enough memory to get
            % all the edges at once. This will likely succeed, but see the 
            % code in the the loop below that reduces this value if we get
            % an out of memory error.
            mem.MaxPossibleArrayBytes = edgeCount * edgeBytes * 4;

            while (offset < edgeCount)
                % How much memory is available? MATLAB is only willing to
                % answer this question on Windows.
                if obj.isPC
                    mem = memory;
                end
                % Take a chunk a little bit less than one-third the size 
                % of the largest available; we'll use the rest expanding 
                % the IDs to int64.
                maxArray = floor(mem.MaxPossibleArrayBytes / 3.14159);
                % How many edges fit into that chunk?
                maxEdges = maxArray / edgeBytes;

                % Get all the edges that will fit.
                try
                    edges = TClosure.EdgeRange(offset, maxEdges);
                    % Convert zero-based graph vertex IDs to one-based database 
                    % vertex IDs. Here's the first copy, and a possible widening.
                    edges = edges + 1;
                    edges = int64(edges);  % Database can't handle uint32.
                    % Write the edges into the database Proxy_Closure table.
                    % Making another copy.
                    obj.SqlDBConnObj.insert('Proxy_Closure', ...
                       'Client', edges(:,1), 'Dependency', edges(:,2));
                    % Hopefully return the memory to MATLAB for reuse in the 
                    % next iteration.
                    clear edges
                catch ex
                    % Was this an out of memory error? Reduce
                    % memory demand and try again.
                    if strcmp(ex.identifier, 'MATLAB:nomem')
                        if ~obj.isPC
                            mem.MaxPossibleArrayBytes = ... 
                                mem.MaxPossibleArrayBytes * .75;
                        end
                        if mem.MaxPossibleArrayBytes < edgeBytes
                            rethrow(ex);
                        end
                        continue;
                    else
                        % Not out of memory -- rethrow it.
                        rethrow(ex);
                    end
                end

                % Increment the starting offset (distance from the first
                % element).
                offset = offset + maxEdges;
            end

            % For performance, create a coverage index for Proxy_Closure.
            % This is expensive (it almost doubles the size of the database),
            % but it makes queries Proxy_Closure queries much faster.
            obj.SqlDBConnObj.doSql([...
                'CREATE INDEX Proxy_Closure_Index ON ' ...
                'Proxy_Closure(Client,Dependency)']);

            % g1092063 - ssegench
            % whichNonBuiltin does a lookup on the file table using the
            % symbol column. Over networks (in particular in BaT against
            % the build environment) this query was particularly slow (4+ seconds). 
            % Adding an index to get rid of the full table scan improved
            % performance by a factor of 10.
            obj.SqlDBConnObj.doSql([...
                'CREATE INDEX File_Symbol_Index ON ' ...
                'File(Symbol)']);
            
            % ssegench
            % add index for looking up proxy by principal
             obj.SqlDBConnObj.doSql([...
                'CREATE INDEX Proxy_Principal_Principal_Index ON ' ...
                'Proxy_Principal(Principal)']);
            

            % Disable automatic transaction for pragma statement
            obj.SqlDBConnObj.doSql('PRAGMA journal_mode = ON', false);
        end
        
        function recordExclusion(obj, target, file)
        % save in Exclusion_List based on 'target' for 'file'
            related_tables = {'Exclusion_List', 'Exclude_File'};
            cellfun(@(t)obj.clearTable(t), related_tables);
        
            if ~ischar(target)
                % convert matlab.depfun.internal.Target to string
                target = matlab.depfun.internal.Target.str(target);
            end
            
            obj.SqlDBConnObj.doSql(sprintf('SELECT ID FROM Target WHERE Name = ''%s'';', target));
            targetID = obj.fetchNonEmptyRow();
            
            obj.SqlDBConnObj.insert('Exclude_File', 'Path', file);
            
            file = matlab.depfun.internal.PathNormalizer.normalizeFiles(file, true);
            num_file = numel(file);
            for i = 1:num_file              
                obj.SqlDBConnObj.doSql(sprintf(...
                    'SELECT ID from Exclude_File where Path = ''%s'';', ...
                    file{i}));

                fileID = obj.SqlDBConnObj.fetchRow();                

                % Insert the file into the Exclude_File table if necessary
                if isempty(fileID)
                    obj.SqlDBConnObj.doSql(sprintf(...
                        'INSERT INTO Exclude_File (Path) VALUES (''%s'');',...
                        file{i}));
                    
                    obj.SqlDBConnObj.doSql(sprintf(...
                        'SELECT ID FROM Exclude_File WHERE Path = ''%s'';',...
                        file{i}));

                    fileID = obj.SqlDBConnObj.fetchRow();
                end

                obj.SqlDBConnObj.doSql(sprintf(...
          'INSERT INTO Exclusion_List (Target, File) VALUES (%d, %d);', ...
                    targetID, fileID));
            end
        end
        
        function fileList = getExclusion(obj, target)
        % Read the exclusion_list for Target
        % straight forward read from the exclusion_list matched with the target
            fileList = {};
            obj.SqlDBConnObj.doSql('SELECT name FROM sqlite_master WHERE type=''table'' AND name=''Exclusion_List'';');
            if(strcmp(obj.SqlDBConnObj.fetchRow(),'Exclusion_List'))        
                if ~ischar(target)
                    % convert matlab.depfun.internal.Target to string
                    target = matlab.depfun.internal.Target.str(target);
                end
                obj.SqlDBConnObj.doSql(sprintf(...
                    'SELECT ID FROM Target WHERE Name = ''%s'';', target));
                targetID = obj.fetchNonEmptyRow();
        
                obj.SqlDBConnObj.doSql(sprintf([ ...
                    'SELECT Exclude_File.Path ' ...
                    'FROM Exclusion_List, Exclude_File ' ...
                    'WHERE Exclusion_List.File = Exclude_File.ID ' ...
                    'AND Exclusion_List.Target = %d;'], targetID));
                fileList = decell(obj.SqlDBConnObj.fetchRows());
            end
        end

        function reclaimEmptySpace(obj)
        % Minimize the size of the database by rebuilding it. An expensive
        % operation.
            obj.SqlDBConnObj.doSql('VACUUM');   
        end
        
        function tf = isPrincipal(obj, files)
            if isempty(obj.Principals)
                query = ['SELECT File.Path FROM Proxy_Principal, File ' ...
                         '  WHERE File.ID = Proxy_Principal.Principal;'];
                obj.SqlDBConnObj.doSql(query);
                obj.Principals = decell(obj.SqlDBConnObj.fetchRows());
            end

            if ~iscell(files)
                files = { files };
            end
            
            % convert to canonical path relative to matlabroot
            normalized_path = matlab.depfun.internal.PathNormalizer.normalizeFiles(files, true);            
            tf = ismember(normalized_path, obj.Principals);
        end
        
        function recordPrincipals(obj, proxy, principal)
        % Populate the Proxy_Principal table.
        % proxy contains the names or file IDs of proxies.
        % principal contains names or file IDs of principals.
        
            % Find file ID for the proxy
            if isnumeric(proxy)
                proxyID = proxy;
            elseif ischar(proxy)
                proxy_normalized = matlab.depfun.internal.PathNormalizer.normalizeFiles(proxy, true);
                proxyID = cell2mat(cellfun(@(p)obj.findOrInsertFile(p), ...
                          proxy_normalized, 'UniformOutput', false));
            else
                error(message('MATLAB:depfun:req:InvalidInputType', ...
                              1, class(proxy), 'a string or a number'));
            end

            % Find file ID for principals
            if isnumeric(principal)
                principalID = principal;
            elseif ischar(principal)
                principal_normalized = matlab.depfun.internal.PathNormalizer.normalizeFiles(principal, true);
                principalID = cell2mat(cellfun(@(p)obj.findOrInsertFile(p), ...
                              principal_normalized, 'UniformOutput', false));
            else
                error(message('MATLAB:depfun:req:InvalidInputType', ...
                              2, class(principal), 'cell or numeric array'));
            end

            % Record the proxy-principal pairs
            obj.SqlDBConnObj.insert('Proxy_Principal', ...
                             'Proxy', proxyID, 'Principal', principalID);
        end
        
        function result = getProxyPrincipal(obj)
            obj.SqlDBConnObj.doSql('SELECT Proxy, Principal FROM Proxy_Principal;');
            tmp = obj.SqlDBConnObj.fetchRows();
            proxy =  cell2mat(cellfun(@(r)r{1},tmp,'UniformOutput',false))';
            principal =  cell2mat(cellfun(@(r)r{2},tmp,'UniformOutput',false))';            
            result = [proxy principal];
        end
    end

    methods(Access = private)

        function id = lookupPathID(obj, files)
            files = matlab.depfun.internal.PathNormalizer.normalizeFiles(files, true);
            fileSelector = sprintf('Path = ''%s''', files{1});
            if ~isscalar(files)
                fileSelector = [fileSelector ' ' ...
                                sprintf(' OR Path = ''%s''', files{:})];
            end

            obj.SqlDBConnObj.doSql(...
                sprintf('SELECT ID FROM File WHERE %s;', fileSelector));
            id = obj.SqlDBConnObj.fetchRow();
        end

        function [lang, type, sym] = getFileData(obj, pth)
            sym = '';
            [lang, type] = obj.fileClassifier.classify(pth);
            if strcmp(lang,'MATLAB')
                [~,sym] = fileparts(pth);
            end
            if isKey(obj.Language2ID, lang)
                lang = obj.Language2ID(lang);
            else
                error(message('MATLAB:depfun:req:InternalBadLanguage', ...
                              lang, obj.dbName))
            end
        end

        function id = findOrInsertFile(obj, pth)
            select = sprintf('SELECT ID from File where Path = ''%s'';', pth);
            obj.SqlDBConnObj.doSql(select);
            id = obj.SqlDBConnObj.fetchRow();
            if isempty(id)
                [lang, type, sym] = getFileData(obj, pth);
                q = sprintf(...
                    ['INSERT INTO File (Path, Language, Type, Symbol) ' ...
                     'VALUES (''%s'', %d, %d, ''%s'')'], pth, lang, ...
                    int32(type), sym);
                obj.SqlDBConnObj.doSql(q);
                obj.SqlDBConnObj.doSql(select);
                id = obj.SqlDBConnObj.fetchRow();
                if isempty(id)
                    op = sprintf('INSERT File: ''%s''', pth);
                    error(message('MATLAB:depfun:req:InternalDBFailure', ...
                                  op, obj.dbName))
                end
            end
        end

        function clearTable(obj, table)
        % Clear an existing table. For performance, drop and recreate
        % the table.
            obj.destroyTable(table);
            obj.createTable(table);
        end
        
        function createTempTable(obj, table, cols)
        % Create a temporary table
        % cols is a cellarray 
        % cols = {'id INT' 'path TEXT'} will yield a 2 column table
            query = ['CREATE TEMP TABLE ' table ' ( ' ...
                      strjoin(cols, ', ') ')'];
            obj.SqlDBConnObj.doSql(query);
          
        end
        
        function createTable(obj, table)
        % Create a table, using the column definitions in the tableData
        % map.
            if isKey(obj.tableData, table)
                cols = obj.tableData(table);
                query = ['CREATE TABLE ' table ' ( ' ...
                         strjoin(cols, ', ') ')'];
                obj.SqlDBConnObj.doSql(query);
            end
        end
        
        function clearFileTables(obj)
        % Clear the file table and all the tables that depend on it.
            fileTables = {'File', 'Proxy_Closure', 'Level0_Use_Graph'};
            cellfun(@(t)obj.clearTable(t), fileTables);
        end
        
        function clearComponentDependencyTables(obj)
        % Clear the file table and all the tables that depend on it.
            fileTables = {'Required_Components', 'File_Components'};
            cellfun(@(t)obj.clearTable(t), fileTables);
        end

        function destroyTable(obj, tablename)
        % Destroy an existing table. Don't try to destroy tables that don't
        % exist, since that makes SQLite angry.
            obj.SqlDBConnObj.doSql(['SELECT name FROM sqlite_master WHERE type=''table'' AND name=''' tablename ''';']);
            if(strcmp(obj.SqlDBConnObj.fetchRow(),tablename))
                obj.SqlDBConnObj.doSql(['DROP TABLE ' tablename ';']);
            end
        end
        
        function destroyAllTables(obj)
        % Destroy all known tables by applying the destroyTable method.
            tables = keys(obj.tableData);
            cellfun(@(t)obj.destroyTable(t), tables);         
        end

        function createTables(obj)
            % Create tables
            
            tables = keys(obj.tableData);
            cellfun(@(t)obj.createTable(t), tables);
            
            % Initialize tables
            
            % table Language(id, name).
            obj.SqlDBConnObj.doSql('INSERT INTO Language (Name) VALUES(''MATLAB'');');
            obj.SqlDBConnObj.doSql('INSERT INTO Language (Name) VALUES(''CPP'');');
            obj.SqlDBConnObj.doSql('INSERT INTO Language (Name) VALUES(''Java'');');
            obj.SqlDBConnObj.doSql('INSERT INTO Language (Name) VALUES(''NET'');');
            obj.SqlDBConnObj.doSql('INSERT INTO Language (Name) VALUES(''Data'');');

            % table Symbol_Type(id, type)
            % consistent with types defined in matlab.depfun.internal.MatlabType
            allTypes = enumeration('matlab.depfun.internal.MatlabType');
            allTypes_char = arrayfun(@(t)char(t), allTypes, ...
                                     'UniformOutput', false);
            allTypes_int = int32(allTypes);            
            obj.SqlDBConnObj.insert('Symbol_Type', ...
                                    'Name', allTypes_char, ...
                                    'Value', allTypes_int);
            
            % table Proxy_Type(id, type)
            proxy_type = {...
                'MCOSClass','UDDClass','OOPSClass','BuiltinClass'};
            insert_cmd = ['INSERT INTO Proxy_Type (Type) ' ...
                          '  SELECT Symbol_Type.Value ' ...
                          '  FROM Symbol_Type ' ...
                          '  WHERE Symbol_Type.Name = ''proxy_type'';'];
            cellfun(@(p)obj.SqlDBConnObj.doSql( ...
                    regexprep(insert_cmd, 'proxy_type', p)), proxy_type);
            
            % table Target(id, name) -- same order as numerical values in
            % matlab.depfun.internal.Target.
            allTargets = arrayfun(@(t)char(t), ...
                           enumeration('matlab.depfun.internal.Target'),...
                           'UniformOutput',false);
            obj.SqlDBConnObj.insert('Target', 'Name', allTargets);
        end
        
        function cacheLanguageTable(obj)
            % initialize the map
            obj.Language2ID = containers.Map('KeyType', 'char', ...
                                             'ValueType', 'double');
            obj.ID2Language = containers.Map('KeyType', 'double', ...
                                             'ValueType', 'char');
            
            % load the table into the map
            obj.SqlDBConnObj.doSql('SELECT COUNT(*) from Language;');
            num_lang = obj.SqlDBConnObj.fetchRow();
            for k = 1:num_lang
                obj.SqlDBConnObj.doSql(...
                    sprintf('SELECT Name from Language where ID = %d;', k));
                Language = obj.SqlDBConnObj.fetchRow();
                obj.Language2ID(Language) = k;
                obj.ID2Language(k) = Language;
            end
        end
        
        function recordEdges(obj, graph, table)
            edges = graph.EdgeVectors;
            % convert vertexID to fileID using mapping if it exists
            if(~isempty(obj.Vertex2FileID))
                clientFID = obj.Vertex2FileID.values(num2cell(edges(:, 1)));
                dependencyFID = obj.Vertex2FileID.values(num2cell(edges(:, 2)));
                clientFID = [clientFID{:}];
                dependencyFID = [dependencyFID{:}];
            else
                clientFID = double(edges(:,1) + 1);
                dependencyFID = double(edges(:,2) + 1);
            end
            
            % insert the data at once
            obj.SqlDBConnObj.insert(table, ...
                'Client', clientFID, 'Dependency', dependencyFID);
        end
        
        function [graph, file2Vertex] = createGraphAndAddEdges(obj, table)
        % create a graph based on the File table
    
            % improvements for performance, g904544
            % (1) cache Language table
            if isempty(obj.ID2Language)
                cacheLanguageTable(obj);
            end
        
            % map from file path to vertex ID to be used to interact with
            % the graph outside of dependency depot
            file2Vertex = containers.Map('KeyType', 'char', ...
                                         'ValueType', 'uint64');
            % temporary map from file ID to vertex ID to read in edges 
            file2VertexID = containers.Map('KeyType', 'double', ...
                                           'ValueType', 'uint64');
                                       
            % (2) use bulk select for performance
            obj.SqlDBConnObj.doSql('SELECT ID, Path, Type, Symbol FROM File;');
            files = obj.SqlDBConnObj.fetchRows();
            num_files = numel(files);
            % if there were no files recorded in the File table, return an empty graph
            if(num_files == 0)
                graph = matlab.internal.container.graph.Graph('Directed', true);
                return
            end
            
            % preallocation
            fileID = zeros(num_files,1);
            sym(num_files).symbol = [];
         
            vertexID = 0;
            for i = 1:num_files
                fileID(i) = files{i}{1};
                Path = files{i}{2};
                TypeID = files{i}{3};
                Type = matlab.depfun.internal.MatlabType(TypeID);
                Symbol = files{i}{4};
                
                % unless the type is a built in, denormalize the path so it
                % contains the full path that WHICH would return
                if ~isBuiltin(Type) || exist(fullfile(matlabroot, Path),'file')
                    Path = matlab.depfun.internal.PathNormalizer.denormalizeFiles(Path);
                elseif isBuiltin(Type) && contains(Path, 'built-in (')
                    Path = strrep(Path, '(', ['(' matlabroot filesep]);
                    Path = strrep(Path, '/', filesep);
                end
                
                % If the current file is a proxy, add className and
                % classFile to the symbol, so that we don't need to spend
                % time to re-compute them.
                if isClass(Type)
                    cur_sym = matlab.depfun.internal.MatlabSymbol(Symbol, Type, Path, Symbol, Path);
                    matlab.depfun.internal.MatlabSymbol.classList.add(cur_sym);
                else
                    % If the current file is a principal, add className and
                    % classFile to the symbol, so that we don't need to spend
                    % time to re-compute them.
                    obj.SqlDBConnObj.doSql(['SELECT File.Symbol, File.Path ' ...
                                            'FROM File, Proxy_Principal ' ...
                                            'WHERE Proxy_Principal.Principal = ' num2str(fileID(i)) ...
                                            '  AND File.ID = Proxy_Principal.Proxy;']);
                    tmp = obj.SqlDBConnObj.fetchRows();
                    if ~isempty(tmp)
                        class_name = tmp{1}{1};
                        class_file = tmp{1}{2};
                        if exist(fullfile(matlabroot, class_file),'file')
                            class_file = matlab.depfun.internal.PathNormalizer.denormalizeFiles(class_file);
                        end
                        cur_sym = matlab.depfun.internal.MatlabSymbol(Symbol, Type, Path, class_name, class_file);
                    else
                        cur_sym = matlab.depfun.internal.MatlabSymbol(Symbol, Type, Path);
                    end
                end
                
                % only create vertices for proxys and add principals to the
                % map for later use in recordProxyData
                if(isPrincipal(cur_sym))
                    obj.Principal2FileID(Path) = fileID(i);
                else
                    sym(vertexID + 1).symbol = cur_sym;
                    file2Vertex(Path) = vertexID;
                    file2VertexID(fileID(i)) = vertexID;
                    obj.Vertex2FileID(vertexID) = fileID(i);
                    vertexID = vertexID + 1;
                end
            end
            % get rid of the empty preallocated symbols
            sym = sym(1:length([sym.symbol]));
           
            % create a new graph
            graph = matlab.internal.container.graph.Graph('Directed', true);
            % add nodes to the graph
            addVertex(graph, sym);
              
            % add edges to the graph based on the specified table            
            obj.SqlDBConnObj.doSql(['SELECT Client, Dependency from ' table ';']);
            edges = obj.SqlDBConnObj.fetchRows();
            num_edges = numel(edges);
            clientFileID = zeros(num_edges,1);
            dependencyFileID = zeros(num_edges,1);
            for i = 1:num_edges
                % read in an edge
                clientFileID(i) = edges{i}{1};
                dependencyFileID(i) = edges{i}{2};
            end
            % convert from fileId to vertexId           
            clientVID = file2VertexID.values(num2cell(clientFileID));
            dependencyVID = file2VertexID.values(num2cell(dependencyFileID));
            
            % add the edge to the graph
            addEdge(graph, [clientVID{:}], [dependencyVID{:}]);          
        end
    end
end

% local helper function(s)
function output = decell(input)
    rows = numel(input);
    output = cell(rows,1);
    for i = 1:rows
        output{i} = input{i}{1};
    end
end

% LocalWords:  NTFS symlist transplantability dfdb preallocation SQLITE ASC Bsignal ssegench sqlite
% LocalWords:  lang Dep
