classdef Manifest
    % Manifest Summary of this class goes here
    %   Detailed explanation goes here

%   Copyright 2012-2020 The MathWorks, Inc.
    
    properties (Access = private)
        DependencyGraph
        Target
        RootSet
        ClassList
    end
    
     methods
        function obj = Manifest(files, target)
        % MANIFEST Record target-specific file dependencies in a Manifest
            % Allow files (special case) to be a single string
            if ~iscell(files)
                if ischar(files)
                    files = { files };
                end
            end
            % Parse the target name into a Target object
            tgt = matlab.depfun.internal.Target.parse(target);
            if (tgt == matlab.depfun.internal.Target.Unknown)
                error(message('MATLAB:depfun:req:BadTarget', target))
            end
            obj.RootSet = files;
            obj.Target = target;
            c = matlab.depfun.internal.Completion(files, tgt);
            obj.DependencyGraph = calltree(c);
            obj.ClassList = knownClasses(matlab.depfun.internal.MatlabSymbol.classList);
        end

        function saveas(obj, name, matfile) %#ok  (used in EVAL)
        % SAVEAS Save the manifest object as a variable of the given name.
            eval([name ' = obj;']);
            save(matfile, name);
        end

        function [list, vertexID] = files(obj)
        % FILES List full paths of all the files in the Manifest
            if ~isempty(obj.DependencyGraph) && ...
               obj.DependencyGraph.VertexCount > 0
                vertexID = obj.DependencyGraph.VertexIDs;
                symbol = partProperty(obj.DependencyGraph,'data', vertexID);
                symbol = [ symbol.symbol ]; % Compress cells to structure array
                keep = symbolFilter(symbol);
                symbol = symbol(keep);
                vertexID = vertexID(keep);
                list = { symbol.WhichResult };
            else
                list = {};
                vertexID = [];
            end
        end

        function relocate(obj, origin, destination)
        % RELOCATE Rename the files in the Manifest; maintain relationships.
        % This method modifies the graph object stored in the Manifest.
        %    origin: Cell array of files to move
        %    destination: New location (path) for moved files.
        % origin and destination must be the same length.
        
            % When renaming nodes, write the new names to the WhichResult
            % field of the symbol data.
            [original, vertexID] = files(obj);
            % Intersect sorts, so we must apply permutation to both
            % vertexID list and destination, or files will become misnamed.
            [~,ia,ib] = intersect(origin, original);
            vertexID = vertexID(ib);
            destination = destination(ia);
            for k=1:numel(vertexID)
                v = obj.DependencyGraph.vertex(vertexID(k));
                v.Data.symbol.WhichResult = destination{k};
            end
        end
        
        function parts = requirements(obj, fileList)
        % REQUIREMENTS Return the requirements of one or more files.
        %
        %    obj: Manifest describing file requirements.
        %
        %    fileList: Files for which to return requirements. A cell array 
        %      of strings, each of which will be compared, using string,
        %      against the full paths of the files in the Manifest.
        %
        % The fileList may be empty, in which case the returned parts list
        % will be empty. The parts list will also be empty if the requested 
        % file does not exist in the manifest.
            
            % Demand two inputs. If you want information about all the files
            % call files(obj) instead.
            if nargin ~= 2
                error(message('MATLAB:depfun:req:BadInputCount', 2, nargin, ...
                              'requirements'))
            end
            % Find the roots of the requirement set in the graph
            parts = {};

            % If there's nothing to do...
            if isempty(obj.DependencyGraph)
                return;
            end

            if ischar(fileList)
                fileList = { fileList };
            end
			
            % Initialize caches, since they are indirectly 
            % used by principals().
            % Cannot use matlab.depfun.internal.initCaches because it 
            % removes the classList in MatlabSymbol, which breaks
            % principals().
            matlab.depfun.internal.cacheWhich();
            matlab.depfun.internal.cacheExist();
            matlab.depfun.internal.cacheEdge();
            matlab.depfun.internal.cacheIsExcluded();
            matlab.depfun.internal.cacheIsExpected();
            getPrivateFiles();
			
            rootList = [];
            for k=1:numel(fileList)
                root = findIf(obj.DependencyGraph, ...
                    @(id, v, p) ...
                          any(~isempty(strfind(p.symbol.WhichResult, ...
                                               fileList{k}))), ...
                        'Vertex');
                rootList = [rootList root];
            end
            
            % Get the IDs of all the children of all the roots.
            vertexID = depthFirstTraverse(obj.DependencyGraph, rootList);
            
            % If there were multiple roots, vertexID will be a cell array.
            % Each entry in the cell array will contain the vertices below
            % the corresponding root. Flatten the cell array into a single
            % list of vertices.
            if iscell(vertexID)
                vertexID = vertcat( vertexID{:} );
            end
            
            % Remove duplicates
            vertexID = unique(vertexID);
            
            % Get the paths, return a cell array of strings
            symbol = partProperty(obj.DependencyGraph,'data',vertexID);
            if ~isempty(symbol)
                % Compress cells to structure array
                symbol = [ symbol.symbol ];
                keep = symbolFilter(symbol);
                symbol = symbol(keep);
                parts = { symbol.WhichResult };
                
                % Fetch principals of each symbol
                for k = 1:numel(symbol)
                    s = symbol(k);
                    clsName = s.ClassName;
                    if ismember(clsName, obj.ClassList)
                        plist = getClassFiles(clsName);
                        if ~isempty(plist)
                            % Remove the symbol from the list of principals
                            self = strcmp(s.WhichResult, plist);
                            plist = plist(~self); 
                            parts = [parts plist]; %#ok
                        end
                    end
                end
            end
        end
    end
end

function keep = symbolFilter(symbol)
    % Filter out built-ins, as they are expected in MATLAB Runtime.
    keep = arrayfun(@(s)(~isBuiltin(s) && ...
        matlab.depfun.internal.cacheExist(s.WhichResult, 'file') ~= 0), symbol);
end

function files = getClassFiles(className)

    import matlab.depfun.internal.requirementsConstants
    
    fs = requirementsConstants.FileSep;
    files = {};
    whatName = strrep(className,'.','/');
    whatResult = what(whatName);
    classDirs = strcat({whatResult.path}, fs);
    
    % WHAT may find extraneous directories -- toss them out of the club. A
    % class directory must have at least one @-sign in it.
    keep = contains(classDirs, [fs '@']);
    classDirs = classDirs(keep);
    whatResult = whatResult(keep);
    
    % Some fileds in the WHAT result may not always be available, e.g, mlx. 
    wfIdx = cellfun(@(f)isfield(whatResult,f), requirementsConstants.whatFields);
    wf = requirementsConstants.whatFields(wfIdx);

    % Full paths to all files
    for k=1:numel(classDirs)
        clsDir = classDirs{k};
        wr = whatResult(k);
        
        dirFiles = cellfun(@(f)(wr.(f))', wf, 'UniformOutput', false);
        dirFiles = [ dirFiles{:} ];
        
        % dirFiles must be a row vector or stcat will fail.
        files = [files{:} strcat(clsDir, dirFiles)];
    
        % Get private files, and prepend <classDir>/private to each.
        pvtFiles = getPrivateFiles(clsDir);        
        if ~isempty(pvtFiles)
            pvtDir = fullfile(clsDir, 'private');
            files = [files strcat([pvtDir fs], pvtFiles')]; %#ok
        end
    end
end


