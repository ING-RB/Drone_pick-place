classdef (Abstract) MwFileInspector < handle
% MwFileInspector is the abstract base class for concrete file inspector 
% sub-classes, which are used to analyze various types of MathWorks files.

% Copyright 2016-2024 The MathWorks, Inc.

    properties (SetAccess=protected)
        BuiltinListMap
        UnresolvedSymbols
    end
    
    properties (Access = protected)
        BuiltinMethodInfo
        PathUtility
        Rules
        SymbolResolver
        Target
        addDep
        addClassDep
        addComponentDep
        addPackageDep
        addExclusion
        addExpected
        fsCache
        pickUserFiles
        useDB
    end

    properties (Constant)
        BuiltinClasses = ...
            matlab.depfun.internal.requirementsConstants.matlabBuiltinClasses;
    end

    methods
        function analyzeSymbol(obj, client)
            if getenv('REQUIREMENTS_VERBOSE')
                disp(['Analyzing ' client.WhichResult]);
            end
            result = getSymbols(obj, client.WhichResult);
            evaluateSymbols(obj, result, client);
        end
        
        function determineSymbolType(obj, symbol)            
            try
                determineMatlabType(symbol);    
            catch exception
                % only catch the error thrown by meta.class.fromName()
                if strcmp(exception.identifier, 'MATLAB:class:InvalidSuperClass')
                    % add the file to the exclusion file, because its super class
                    % cannot be found on the path.
                    reason = struct('identifier', exception.identifier, ...
                                    'message', exception.message, ...
                                    'rule', '');
                    obj.addExclusion(symbol.WhichResult, reason);
                    symbol.Type = matlab.depfun.internal.MatlabType.Ignorable;
                else
                    rethrow(exception);
                end
            end

            % Only cache the type if the symbol is the entry point or class name.
            %
            % TODO: Add MCOSMethod to MatlabType, and make this code faster by
            % checking the type.
            if ~isempty(symbol.Symbol)
                dotIdx = strfind(symbol.Symbol,'.');
                baseSym = symbol.Symbol;
                if ~isempty(dotIdx)
                    baseSym = baseSym(dotIdx(end)+1:end);
                end
                if ~isempty(symbol.WhichResult)
                    % Remove extension, if any
                    noExt = symbol.WhichResult(1:end-numel(symbol.Ext));
                    loc = strfind(noExt, baseSym);
                    % Is the baseSym the last part of the baseFile?
                    if ~isempty(loc)
                        loc = loc(end);
                        if loc == numel(noExt) - numel(baseSym) + 1
                            cacheType(obj.fsCache, [symbol.WhichResult ' : ' baseSym], symbol.Type);
                        end
                    end
                end
            end
        end

    end % Public methods    
    
    methods (Abstract)
        %----------------------------------------------------------------
        % Each inspector must implement its own determineType method.
        [symbol, unknown_symbol] = determineType(obj, w);
    end % Abstract public methods
        
    methods (Access = protected)
        
        function obj = MwFileInspector(objs, fcns, flags)
            obj.BuiltinListMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.PathUtility = objs.pathutil;
            obj.Rules = objs.rules;
            obj.Target = objs.target;
            obj.SymbolResolver = matlab.depfun.internal.SymbolResolver();
            obj.UnresolvedSymbols = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.fsCache = objs.fsCache;
            obj.useDB = flags.useDB;
            % The clients of MatlabInspector are responsible for managing
            % the following passed-in function handles.
            obj.addDep = fcns.addDep;
            obj.addClassDep = fcns.addClassDep;
            obj.addComponentDep = fcns.addComponentDep;
            obj.addPackageDep = fcns.addPackageDep;
            obj.addExclusion = fcns.addExclusion;
            obj.addExpected = fcns.addExpected;
            obj.pickUserFiles = fcns.pickUserFiles;
            % Must construct new maps every time we build a new
            % MatlabInspector, because the maps depend on the MATLAB path, 
            % which could change between constructor calls.
            obj.BuiltinMethodInfo = buildMapOfFunctionsForBuiltinTypes;
        end

    end % Protected base class constructor
    
    methods (Access = protected)
        
       %--------------------------------------------------------------
       function methodData = lookupBuiltinClassWithMethod(obj, symObj)
            if isKey(obj.BuiltinMethodInfo, symObj.Symbol)
                methodData = obj.BuiltinMethodInfo(symObj.Symbol);
            else
                methodData = struct('name',{},'location',{},'proxy',{});
            end
        end

        %--------------------------------------------------------------
        function recordExpected(obj, file, reason)
            obj.addExpected(file, reason)
        end

        %--------------------------------------------------------------
        function recordExclusion(obj, file, reason)
            obj.addExclusion(file, reason)
        end
        
        %--------------------------------------------------------------
        function recordPrivateDependency(obj, client, sym)
            import matlab.depfun.internal.MatlabType
            
            cachedType = obj.fsCache.Type([sym.WhichResult ' : ' sym.Symbol]);
            if isempty(cachedType) || cachedType == MatlabType.NotYetKnown
                determineSymbolType(obj, sym);
            else
                sym.Type = cachedType;
            end
            
            if ~isempty(sym.ClassName)
                % All these private functions are functions, but in
                % order to properly classify them (to determine their
                % status as proxies or principals) we must register
                % the classes they might or might not belong to.
                registerClass(sym);
            end
            
            recordDependency(obj, client, sym);
        end

        %----------------------------------------------------------------
        function symList = recordDependency(obj, client, symbol)
            symList = obj.addDep(client, symbol);
        end
        
        %----------------------------------------------------------------
        function recordBuiltinDependency(obj, client, symObj)
            import matlab.depfun.internal.MatlabSymbol;
            import matlab.depfun.internal.MatlabType;
            import matlab.depfun.internal.requirementsConstants;
            
            % Is symObj an extension method?
            extMth = isExtensionMethod(symObj);
            
            % Check to see if overloads of the name exist for
            % builtin types -- if so, record dependencies on
            % those overloads. (These classes are already
            % registered, no need to register them again.)
            clsList = lookupBuiltinClassWithMethod(obj, symObj);
            for o=1:numel(clsList)
                % If we're processing an extension method, we must Allow 
                % the class dependency, even if the class is Expected. 
                % The allow function requires lists to be terminated 
                % with @!@.
                if extMth
                    allowLiteral(obj.Rules,obj.Target, 'COMPLETION', ...
                        { clsList(o).proxy, '@!@' });
                end
                
                % Record a dependency on the builtin class.
                bCls = MatlabSymbol(clsList(o).name, ...
                    MatlabType.BuiltinClass, ...
                    clsList(o).proxy);
                
                recordClassDependency(obj, client, bCls);
                
                % If the builtin class is sliceable, record a dependency 
                % on the method as well, since sliceable classes do not
                % proxy their methods.
                
                if isSliceable(bCls)
                    fileNames = cellfun(@(x)fullfile(clsList(o).location,strcat(symObj.Symbol,x)), ...
                        requirementsConstants.executableMatlabFileExt,'UniformOutput',0);
                    fileNamesExistIdx = cellfun(@(f)matlabFileExists(f),fileNames,'UniformOutput',0);
                    fileName = cell2mat(fileNames(find(cell2mat(fileNamesExistIdx),1)));
                    
                    if(~isempty(fileName))
                        bMth = MatlabSymbol(symObj.Symbol, ...
                            MatlabType.ClassMethod, ...
                            fileName);
                        recordDependency(obj, client, bMth);
                    end
                end
            end
        end
        
        %----------------------------------------------------------------        
        function recordClassDependency(obj, client, sym)
            obj.addClassDep(client, sym);
        end
        
        %----------------------------------------------------------------        
        function recordComponentDependency(obj, client, sym)
            obj.addComponentDep(client, sym);
        end

        %----------------------------------------------------------------        
        function recordPackageDependency(obj, client, pkglist)
            obj.addPackageDep(client, pkglist);
        end
        
        %----------------------------------------------------------------        
        function tf = isMatlabFile(obj, filename)
            userFile = obj.pickUserFiles(filename);
            if isempty(userFile)
                tf = true;
            else
                tf = false;
            end
        end
        
        %--------------------------------------------------------------
        function result = resolveSymbols(obj, parseResult, file)
            import matlab.depfun.internal.requirementsConstants
    
            [~,~,ext] = fileparts(file);
            if ismember(ext, requirementsConstants.executableMatlabFileExt_reverseOrder)
                result = obj.SymbolResolver.resolveSymbols(parseResult, file);
            else
                result = obj.SymbolResolver.resolveSymbols(parseResult);
            end
    
            if isstruct(parseResult)
                % TO-DO: Replace the following section with the file searching API.
                % Pragmas
                include_sym = {};
                functionPragmaIdx = strcmp({parseResult.pragma.pragma}, 'function');
                if any(functionPragmaIdx)
                    include_sym = [parseResult.pragma(functionPragmaIdx).argument];
                    include_sym = regexprep(include_sym, requirementsConstants.analyzableMatlabFileExtPat, '');
                end
                
                excludePragmaIdx = strcmp({parseResult.pragma.pragma}, 'exclude');
                exclude_sym = {};
                if any(excludePragmaIdx)
                    exclude_sym = [parseResult.pragma(excludePragmaIdx).argument];
                    exclude_sym = regexprep(exclude_sym, requirementsConstants.analyzableMatlabFileExtPat, '');
                    % Include override Exclude
                    exclude_sym = setdiff(exclude_sym, include_sym);
                end
        
                % Data files
                if matlab.depfun.internal.requirementsSettings.isDataDetectionOn()
                    num_datafile = numel(parseResult.file);
                    datafile = [parseResult.file];
                    datafile_line = {};
                    datafile_name = {};
                    datafile_path = {};
                    for i = 1:num_datafile
                        detected = datafile(i).file;
        
                        if ismember(detected, exclude_sym)
                            continue
                        end
                        
                        if contains(detected, '.')
                            % Extension is explicitly provided in the file name.
                            if existAsFile(detected)
                                w = matlab.depfun.internal.cacheWhich(detected);
                                if isempty(w)
                                    w = detected;
                                end
                                datafile_name = [datafile_name; detected]; %#ok
                                datafile_path = [datafile_path; w]; %#ok
                                datafile_line = [datafile_line; datafile(i).line]; %#ok
                            else
                                w = matlab.depfun.internal.cacheWhich(detected);
                                if ~isempty(w)
                                    datafile_name = [datafile_name; detected]; %#ok
                                    datafile_path = [datafile_path; w]; %#ok
                                    datafile_line = [datafile_line; datafile(i).line]; %#ok
                                end
                            end
                        else                            
                            % If you have reached this point, you don't
                            % really have much to lose.
                            found = false;
                            applicable_ext = [datafile(i).extension '.'];
                            % Check in pwd first
                            myPwd = pwd;
                            for j = 1:numel(applicable_ext)
                                candidate = [detected applicable_ext{j}];
                                if existAsFile(fullfile(myPwd, candidate))
                                    w = matlab.depfun.internal.cacheWhich(candidate);
                                    datafile_name = [datafile_name; candidate]; %#ok
                                    datafile_path = [datafile_path; w]; %#ok
                                    datafile_line = [datafile_line; datafile(i).line]; %#ok
                                    found = true;
                                    break
                                end
                            end
                            
                            if ~found
                                for j = 1:numel(applicable_ext)
                                    candidate = [detected applicable_ext{j}];
                                    if existAsFile(candidate)
                                        w = matlab.depfun.internal.cacheWhich(candidate);
                                        datafile_name = [datafile_name; candidate]; %#ok
                                        datafile_path = [datafile_path; w]; %#ok
                                        datafile_line = [datafile_line; datafile(i).line]; %#ok
                                        break
                                    end
                                end
                            end
                        end
                    end
                    
                    additional_result = struct('OriginalSymbol', datafile_name, ...
                                               'QualifiedSymbol', datafile_name, ...
                                               'FilePath', datafile_path, ...
                                               'PackageID', '', ...
                                               'IsBuiltin', false, ...
                                               'Type', 'UNKNOWN', ...
                                               'ClassType', 'N/A');
                    if ~isempty(additional_result)
                        result = [result; additional_result];
                    end
                end
            end
        end

        %--------------------------------------------------------------
        function evaluateSymbols(obj, parseResult, client)
        % evaluateSymbols  Evaluate symbols extracted from the client file
        %
        % Iterate over a list of symbols, looking for classes and functions.  A
        % symbol may be dot-qualified.  A class is identified when the symbol is
        % a class name or a dot-qualified static method or constant property
        % reference.  A function or script is identified when a symbol is not a
        % class, can be found on the path (as reported by WHICH), and can be
        % ruled out as a class method.

            import matlab.depfun.internal.MatlabSymbol;
            import matlab.depfun.internal.MatlabType;
            import matlab.depfun.internal.ClassSet;
            import matlab.depfun.internal.cacheWhich;
            import matlab.depfun.internal.cacheExist;
            import matlab.depfun.internal.requirementsConstants;

            file = client.WhichResult;
            
            result = obj.resolveSymbols(parseResult, file);
            
            symlist = {result.QualifiedSymbol};
            emptyQsymIdx = cellfun('isempty', symlist);
            symlist(emptyQsymIdx) = {result(emptyQsymIdx).OriginalSymbol};
            packageID = {result.PackageID};

            pathlist = {result.FilePath};
            builtinIdx = [result.IsBuiltin];

            externalAPIComponent = cell(1,0);
            
            builtinList = {};
            unresolvedSymList = {};
            ignoreIdx = false(size(symlist));
            % For every symbol
            for k = 1:length(symlist)
                if strcmp(pathlist{k}, 'Not on MATLAB path')
                    ignoreIdx(k) = 1;
                    continue;
                end

                if obj.useDB
                    % only analyze user files
                    if ~builtinIdx(k) && isMatlabFile(obj, pathlist{k})
                        % For the MCR target, the mapping from the
                        % user file to the required components is 
                        % not necessary. Required mcr products will
                        % be identified based on the final required
                        % file list.
                        ignoreIdx(k) = 1;
                        continue;
                    end
                end

                % Handling for static method
                if strcmp(result(k).Type, 'STATIC_METHOD')
                    % Chop the static method name to get the class name
                    chopIdx = strfind(symlist{k},'.');
                    if ~isempty(chopIdx)
                        symlist{k} = symlist{k}(1:chopIdx(end)-1);
                        result(k) = obj.SymbolResolver.resolveSymbols(symlist(k), file);
                        packageID{k} = result(k).PackageID;
                        pathlist{k} = result(k).FilePath;
                        builtinIdx(k) = result(k).IsBuiltin;                        
                    end
                end

                % Temporary adapter to convert the new symbol type and
                % class type to matlab.depfun.internal.MatlabType.
                % TO-DO: refactor matlab.depfun.internal.MatlabType
                symbolType = tempSymbolTypeAdaptor(result(k).Type, result(k).ClassType, builtinIdx(k), symlist{k});

                % g2732933 - Workaround for UDD classes that don't have 
                % an explicit class constructor.
                if builtinIdx(k) && strcmp(result(k).ClassType, 'UDD') && isempty(pathlist{k}) ...
                        && ~isempty(requirementsConstants.pcm_nv) ...
                        && ~isKey(requirementsConstants.pcm_nv.builtinRegistry, symlist{k})
                    dotIdx = strfind(symlist{k}, '.');
                    if isscalar(dotIdx)
                        pkgName = symlist{k}(1:dotIdx-1);
                        clsName = symlist{k}(dotIdx+1:end);
                    
                        pkg = what(['@' pkgName]);
                        if ~isempty(pkg)
                            clsDir = [pkg.path requirementsConstants.FileSep ['@' clsName]];
                            if cacheExist(clsDir, 'dir') && matlabFileExists([clsDir requirementsConstants.FileSep 'schema'])
                                symbolType = MatlabType.UDDClass;
                                builtinIdx(k) = 0;
                                %if the file exists, use it, otherwise make up a .m file
                                %g1038142
                                [fileExists,pathlist{k}]=matlabFileExists([clsDir requirementsConstants.FileSep clsName]);
                                if ~fileExists
                                    pathlist{k} = [clsDir requirementsConstants.FileSep clsName '.m'];
                                end
                            end
                        end
                    end
                end

                % Allow MatlabSymbol to make a guess at the symbol type
                % Then, figure out the real symbol type
                symObj = MatlabSymbol(symlist{k}, symbolType, pathlist{k});
                if symObj.Type == MatlabType.NotYetKnown
                    % g2858393
                    % Must check and report if there is any syntax error in the unclassified file here.
                    % Otherwise the unclassified file will be ignored, and the syntax error will not 
                    % be flagged.
                    if ~isempty(pathlist{k}) && ismember(symObj.Ext, requirementsConstants.analyzableMatlabFileExt)
                        mparser = matlab.depfun.internal.MatlabInspector.MFileParser('get');
                        [~] = parseFile(mparser, pathlist{k});
                    end

                    % Data files cannot be resolved.
                    if isempty(pathlist{k}) && existAsFile(symlist{k})
                        % TODO-replace this call with the new file
                        % searching API.
                        w = cacheWhich(symlist{k});
                        if ~isempty(w) && ~isMcode(w)
                            pathlist{k} = w;
                            symObj.WhichResult = w;
                            [~,~,symObj.Ext] = fileparts(w);
                        end
                    end
                    determineMatlabTypeBasedOnFileExtension(symObj);
                    
                    if symObj.Type == MatlabType.NotYetKnown
                        % workaround until g2733005 is done.
                        heuristicsForExternalAPI(symObj);
                    end

                    if symObj.Type == MatlabType.NotYetKnown
                        symObj.Type = MatlabType.Ignorable;
                    end
                end

                if isJavaAPI(symObj)
                    % Include jmi to support Java MATLAB Interface
                    % Include matlab_java_core since that is the
                    % component that ships jmi.jar.
                    externalAPIComponent = ...
                        union(externalAPIComponent, {'jmi','matlab_java_core'});
                elseif isDotNetAPI(symObj)
                    externalAPIComponent = ...
                        union(externalAPIComponent, 'dotnetcli');
                elseif isPythonAPI(symObj)
                    externalAPIComponent = ...
                        union(externalAPIComponent, 'pycli');
                elseif isCppAPI(symObj)
                    externalAPIComponent = ...
                        union(externalAPIComponent, 'cppcli');
                elseif builtinIdx(k)
                    % builtin functions from undeployable components
                    % add to unresolved list
                    if (obj.Target == matlab.depfun.internal.Target.MCR || ...
                        obj.Target == matlab.depfun.internal.Target.Deploytool) && ...
                        ismember(symlist{k}, requirementsConstants.undeployableBuiltins)
                        symObj.Type = MatlabType.Ignorable;
                        ignoreIdx(k) = 1;
                        unresolvedSymList = [unresolvedSymList symlist{k}]; %#ok
                        builtinIdx(k) = false;
                        continue;
                    end

                    % Might get duplicates, which will be unique-ified 
                    % out later. 
                    if ~isMethod(symObj)
                        builtinList{end+1} = symObj;  %#ok<AGROW>
                    end
                    if isClass(symObj)
                        symObj.ClassName = symObj.Symbol;
                        [~,symObj.ClassFile] = virtualBuiltinClassCTOR(symObj.ClassName);
                        if isempty(symObj.ClassFile)
                            symObj.ClassFile = [symObj.ClassName requirementsConstants.IsABuiltInMethodStr];
                        end
                        symObj.WhichResult = symObj.ClassFile;
                        add(symObj.classList, symObj);
                        recordClassDependency(obj, client, symObj);
                    else
                        % If the symbol overloads the name of a
                        % builtin method, record a dependency on
                        % the appropriate builtin class.
                        recordBuiltinDependency(obj, client, symObj);
                    end
                elseif isMethod(symObj)
                    if strcmpi(result(k).Type, 'STATIC_METHOD')
                        recordDependency(obj, client, symObj);
                    else
                        % ignore non-static class methods
                        ignoreIdx(k) = 1;
                    end
                elseif isUDDPackageFunction(symObj)
                    recordDependency(obj, client, symObj);
                elseif isClass(symObj)
                    symObj.ClassName = symObj.Symbol;
                    symObj.ClassFile = symObj.WhichResult;
                    add(symObj.classList, symObj);
                    recordClassDependency(obj, client, symObj);
                elseif isFunction(symObj)
                    % Symbol is a top-level function or package-based 
                    % function, or a script. Put the file name on the 
                    % list of files this file depends on.
                    recordDependency(obj, client, symObj);
                    % If symObj overloads a method of a built-in
                    % class, record that dependency (on the class and
                    % maybe the method) as well.
                    recordBuiltinDependency(obj, client, symObj);
                elseif isData(symObj)
                    recordDependency(obj, client, symObj);
                elseif isExtrinsic(symObj)
                    recordDependency(obj, client, symObj);
                elseif isSimulinkModel(symObj) || isSimulinkDataDictionary(symObj)
                    recordDependency(obj, client, symObj);
                else
                    % Ignorable
                    ignoreIdx(k) = 1;
                    unresolvedSymList = [unresolvedSymList symlist{k}]; %#ok
                end 
            end % for loop
            
            % save the builtin symbols invoked by client into the map
            if ~isempty(builtinList)
                obj.BuiltinListMap(file) = builtinList;
            end
            
            % save the unresolved symbols in the client in the map
            if ~isempty(unresolvedSymList)
                obj.UnresolvedSymbols(file) = unresolvedSymList;
            end
            
            % Recording client's dependency on components that own the 
            % the client's built-in and non-builtin symbols.
            keep = ~ignoreIdx;            
            if any(keep) || ~isempty(externalAPIComponent)
                pathlist = pathlist(keep);
                symlist = symlist(keep);
                builtinIdx = builtinIdx(keep);
                
                serviceList.builtin = symlist(builtinIdx);
                serviceList.file = pathlist(~builtinIdx);
                serviceList.component = externalAPIComponent;
                recordComponentDependency(obj, client, serviceList);

                pkglist = packageID(keep);
                pkg_idx = ~cellfun('isempty', pkglist);
                pkglist = unique(pkglist(pkg_idx));
                if ~isempty(pkglist)
                    recordPackageDependency(obj, client, pkglist);
                end
            end
        end % evaluateSymbols function
        
    end % Protected methods
    
    methods (Abstract, Access = protected)
        
        %----------------------------------------------------------------
        % Each inspector must implement its own getSymbols method.
        result = getSymbols(obj, w);
        
    end  % Abstract protected methods
        
end

% ================= Local functions =========================

%----------------------------------------------------------------
function fcnMap = buildMapOfFunctionsForBuiltinTypes
% buildMapOfFunctionsForBuiltinTypes Record full paths of builtin methods
%
%   map(function.m) -> list of class names and containing directories
%
%     fcnMap(f).name -> class name symbol, suitable for MatlabSymbol
%     fcnMap(f).location -> cell array of class directories, one per class
%         that overloads the function.
    import matlab.depfun.internal.cacheWhich;
    import matlab.depfun.internal.requirementsConstants;

    numTypes = length(matlab.depfun.internal.MatlabInspector.BuiltinClasses);
    fcnMap = containers.Map;
    % For each builtin type
    for k=1:numTypes
        % Get the name of a builtin type (from the static list)
        aType = matlab.depfun.internal.MatlabInspector.BuiltinClasses{k};
		
        % Find all the methods for that type
        whatResults = what(['@' aType]);
        if ~isempty(whatResults)
            % Some fields in the WHAT result may not always be available, e.g, mlx. 
            wfIdx = cellfun(@(f)isfield(whatResults,f), requirementsConstants.whatFields);
            wf = requirementsConstants.whatFields(wfIdx);
            
            whichResult = cacheWhich(aType);
            
            % For each directory containing methods of aType
            % Extended to all executable extensions.
            for n=1:length(whatResults)
                fcn = cellfun(@(f)(whatResults(n).(f))', wf, ...
                                   'UniformOutput', false);
                fcn = [ fcn{:} ]';
                % For each method in the directory
                for j=1:length(fcn)
                    [~,key,~] = fileparts(fcn{j});  % Strip off .m
                    
                    % Add an entry to each map. Each method name maps to
                    % a structure array. 
                    % 
                    % The name field stores the names of the classes that 
                    % overload the function.
                    %
                    % The location field is a cell array of locations where
                    % the overloading function occurs.
                    
                    fcnInfo.name =  aType;
                    fcnInfo.proxy = whichResult;
                    fcnInfo.location = whatResults(n).path;
                    if isempty(fcnInfo.proxy)
                        fcnInfo.proxy = [...
                         requirementsConstants.BuiltInStrAndATrailingSpace ...
                         '(' strrep(fcnInfo.location, '@', '') ')'];
                    end 
                    
                    if isKey(fcnMap, key)
                        fcnMap(key) = [ fcnMap(key) fcnInfo ];
                    else
                        fcnMap(key) = fcnInfo;
                    end
                end
            end
        end
    end
end

function tf = existAsFile(f)
    tf = false;
    ex = matlab.depfun.internal.cacheExist(f, 'file');
    if (ex > 0) && (ex ~= 7)                            
        tf = true;
    end
end
% LocalWords:  sliceable ified dotnetcli pycli mlx builtinList builtins