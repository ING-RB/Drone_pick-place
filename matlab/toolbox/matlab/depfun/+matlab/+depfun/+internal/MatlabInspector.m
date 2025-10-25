classdef MatlabInspector < matlab.depfun.internal.MwFileInspector
% MatlabInspector Determine what files and classes a MATLAB function requires.
% Analyze the symbols used in a MATLAB function to determine which correspond
% to functions or class methods. 

% Copyright 2012-2024 The MathWorks, Inc.

    properties (Constant)
        KnownExtensions = initKnownExtensions();
    end
    
    properties (Access = private)
        MatlabFileParser
        OptionalKeywordDeps
    end

    methods
        
        function obj = MatlabInspector(objs, fcns, flags)
            % Pass on the input arguments to the superclass constructor
            obj@matlab.depfun.internal.MwFileInspector(objs, fcns, flags);
            
            obj.OptionalKeywordDeps = initOptionalKeywordDependencies();
            
            % Create a new parser each time to analyze all matlab files (.m, .mlapp, .mlx).
            matlab.depfun.internal.MatlabInspector.MFileParser('reset');
            obj.MatlabFileParser = matlab.depfun.internal.MatlabInspector.MFileParser('get');
        end

        function [symbolList, unknownType] = determineType(obj, name)
        % determineType Divide names into known and unknown lists. 
        
            symbolList = {};
            unknownType = {};
            
            % validate the file name before a further investigation
            if isValidMatlabFileName(name)
                symbol = resolveType(obj, name);
                if symbol.Type ~= ...
                              matlab.depfun.internal.MatlabType.NotYetKnown
                    symbolList = symbol;
                else
                    unknownType = symbol;
                end
            else
                % WHICH returns '' for files like .foo.m, though they 
                % may be on the path. As a result, if .foo.m is passed in
                % as a relative path, WHICH cannot find its full path.
                if isfullpath(name)
                    if matlab.depfun.internal.cacheExist(name, 'file')
                        fullpath = name;
                    end
                else
                    fullpath = fullfile(pwd, name);
                    if ~matlab.depfun.internal.cacheExist(fullpath, 'file')
                        error(message('MATLAB:depfun:req:NameNotFound',name))
                    end
                end
                
                [~,symName,~] = fileparts(name);
                symbol = matlab.depfun.internal.MatlabSymbol(symName, ...
                         matlab.depfun.internal.MatlabType.Extrinsic, fullpath);
                symbolList = symbol;
            end
        end
        
        function symbol = resolveType(obj, name)
        % resolveType Examine a name to determine its type
        % 
        % Defer to MatlabSymbol's more perfect knowledge about symbols to
        % determine the fully qualified name of each input identifier. An
        % identifier may refer to a file on the MATLAB path or may be the
        % package-qualified name of a method or a class.
          
            if ~ischar(name)
                error(message('MATLAB:depfun:req:NameMustBeChar', ...
                              1, class(name)))
            end
            
            % TODO: Check for dot-qualified names here, maybe. The
            % names may be file names, though, which might have dots 
            % in them.
                       
            % Determine if we've been passed a file name rather than a 
            % function name.
            % G886754: If it is M-code, look for its corresponding 
            % MEX file first.
            fullpath = '';
            mExtIdx = regexp(name,'\.m$','ONCE');
            if ~isempty(mExtIdx)
                MEXname = [name(1:mExtIdx) mexext];
                [fullpath, symName, fileType] = resolveFileName(MEXname);
            end
            
            if isempty(fullpath)
                [fullpath, symName, fileType] = resolveFileName(name);
            end
            
            % If we still haven't found it, look for the name on
            % the path, if possible, and determine the file name that
            % contains it.
            if isempty(fullpath)
                [fullpath, symName] = resolveSymbolName(name);
            end
            
            % Remove the m-file extension from symbol names, if present.
            % If we don't, it may confuse the analysis, leading us to
            % believe this is dot-qualified name. We know it isn't because
            % the name corresponds to a file name, which can't be
            % dot-qualified.
            symName = regexprep(symName, ...
                matlab.depfun.internal.requirementsConstants.analyzableMatlabFileExtPat, '');
           
            % Make a symbol corresponding to the input name; don't 
            % presume to know the type.
            symbol = matlab.depfun.internal.MatlabSymbol(symName, ...
                             fileType, fullpath);
            
            % G1401459: Trust the full path provided by the caller of REQUIREMENTS. 
            % In general, the WHICH result of a symbol is questionable.
            % That's why we have to ignore class methods (g1405818).
            if strcmp(fullpath, name)
                symbol.FullPathProvidedByUser = true;
            end
            
            % Ask the MatlabSymbol object to figure out its own type. This
            % operation is expensive, which is why it is not part of the 
            % constructor.
            if fileType == matlab.depfun.internal.MatlabType.NotYetKnown
                determineSymbolType(obj, symbol);
            end
        end

    end % Public methods
    
    methods (Static)
        
        function tf = knownExtension(ext)
        % knownExtension Is the extension "owned" by MATLAB? 
            tf = ismember(lower(ext), matlab.depfun.internal.MatlabInspector.KnownExtensions);
        end
        
        function varargout = MFileParser(option)
            persistent mparser
            
            switch option
                case 'get'
                    if isempty(mparser)
                        mparser = matlab.depfun.internal.MFileParser;
                    end
                    varargout{1} = mparser;
                case 'reset'
                    clear mparser
                otherwise
                    error(message('MATLAB:depfun:req:InvalidOption', option));
            end
        end
        
    end % Public static methods

    methods (Access = protected)
        
        function result = getSymbols(obj, w)
            result = parseFile(obj.MatlabFileParser, w);
            if ~isempty(obj.OptionalKeywordDeps) && ~isempty(result.keyword)
                keywordDeps = values(obj.OptionalKeywordDeps, result.keyword);
                keywordDeps = [keywordDeps{:}];
                for k = 1:numel(keywordDeps)
                    tmp(k).name = keywordDeps{k};%#ok
                    tmp(k).explicit_import = {};%#ok
                    tmp(k).wildcard_import = {};%#ok
                    tmp(k).location = struct('line',-1, 'column',-1);%#ok
                end
                result.symbol = [result.symbol; tmp'];
            end

            % G2486265, G2496470 - 21b Workaround for Parallel.Pool, parfeval,
            % parfevalOnAll, and mapreduce, which have been moved into MATLAB.
            % Use "parpool" in PCT instead.
            import matlab.depfun.internal.requirementsConstants
            if ~ismember('parpool', {result.symbol.name}) ...
               && any(ismember(requirementsConstants.PCTEnhancedMATLABFcns, ...
                               {result.symbol.name}))
                pct_sym.name = 'parpool';
                pct_sym.explicit_import = {};
                pct_sym.wildcard_import = {};
                pct_sym.location = struct('line',-1, 'column',-1);
                result.symbol = [result.symbol; pct_sym];
            end

            functionPragmaIdx = strcmp({result.pragma.pragma}, 'function');
            if any(functionPragmaIdx)
                include_sym = [result.pragma(functionPragmaIdx).argument];
                include_sym = regexprep(include_sym, requirementsConstants.analyzableMatlabFileExtPat, '');
                if any(ismember(requirementsConstants.PCTEnhancedMATLABFcns, include_sym))
                    pct_include.pragma = 'function';
                    pct_include.argument = {'parpool'};
                    pct_include.line = -1;
                    result.pragma = [result.pragma; pct_include];
                end
            end

            % inject datastore symbols
            if ~isempty(result.uri)
                for i = 1:numel(result.uri)
                    ds = matlab.internal.vfs.providerInfo(result.uri(i).uri);
                    if ~isempty(ds.identifier)
                        for dsi = 1:numel(ds.identifier)
                            ds_sym.name = char(ds.identifier{dsi});
                            ds_sym.explicit_import = {};
                            ds_sym.wildcard_import = {};
                            ds_sym.location.line = result.uri(i).line;
                            ds_sym.location.column = result.uri(i).position;
                            result.symbol = [result.symbol; ds_sym];
                        end
                    end
                end
            end

            % inject models
            if ~isempty(result.model)
                for i = 1:numel(result.model)
                    % account for 'goolenet-places365'
                    m = strsplit(result.model(i).model, '-');
                    m_sym.name = m{1};
                    
                    m_sym.explicit_import = {};
                    m_sym.wildcard_import = {};
                    m_sym.location.line = result.model(i).line;
                    m_sym.location.column = result.model(i).position;
                    result.symbol = [result.symbol; m_sym];
                end
            end

            % inject dependencies indicated by name-value pairs
            if ~isempty(result.nv_pair)
                for i = 1:numel(result.nv_pair)
                    nv_pair = lower([result.nv_pair(i).name '=' result.nv_pair(i).value]);
                    if isKey(requirementsConstants.DepIndicatedByNvPair, nv_pair)
                        nv_sym.name = char(requirementsConstants.DepIndicatedByNvPair(nv_pair));
                        nv_sym.explicit_import = {};
                        nv_sym.wildcard_import = {};
                        nv_sym.location.line = result.nv_pair(i).line;
                        nv_sym.location.column = result.nv_pair(i).column;
                        result.symbol = [result.symbol; nv_sym];
                    end
                end
            end
        end

        function delete(obj)
            obj.MatlabFileParser = [];
            matlab.depfun.internal.MatlabInspector.MFileParser('reset');
        end

    end % Protected methods
end

% ================= Local functions =========================

%------------------------------------------------------------
function [fullpath, fcnName, fileType] = resolveFileName(name)
% resolveFileName If the name is a file, return file and function
    import matlab.depfun.internal.cacheWhich;
    import matlab.depfun.internal.cacheExist;

    fullpath = '';
    fcnName = '';
    fileType = matlab.depfun.internal.MatlabType.NotYetKnown;
    ex = cacheExist(name, 'file');
    if ex == 2 || ex == 3 || ex == 6
        [~,origFile,origExt] = fileparts(name);
        % When readme and readme.m coexist in a folder,
        % if 'readme' is given, we return <full path to the
        % folder>/readme.m;
        % if '<full path to the
        % folder>/readme' is given, we return <full path to the
        % folder>/readme;
        if isempty(origExt) && isfullpath(name)
            % Windows is case insensitive, the input 'name' may contain 
            % mis-spelled cases. For example, the drive letter may be 
            % lower case or upper case. WHICH can correct the wrong case, 
            % based on test points in treqArguments.
            pth = cacheWhich([name '.']);
        else
            % If the input 'name' is a symobl, a relative path, 
            % or a full path of a file with extension, call WHICH without 
            % appending a '.'.
            pth = cacheWhich(name);
        end
        
        % Test for matching case by looking for the filename part of
        % the input name in the full path reported by which. If the cases
        % of the filename parts don't match, MATLAB won't call the
        % function, so we shouldn't include it in the Completion.        
        [~,foundFile,] = fileparts(pth);
        if strcmp(origFile, foundFile) == 1   % Case sensitive
            fullpath = pth;
            fcnName = foundFile;
        end
        
        if isempty(fullpath)
            % WHICH will annoyingly ignore non-MATLAB files without an
            % extension, unless explicitly told the file has no extension.
            % Extension or not, we know the file exists, because exists says it
            % does -- so add the empty extension if necessary.
            wname = name;
            if isempty(origExt)
                wname = [name '.'];
            end
            pth = cacheWhich(wname);
            [~,foundFile,] = fileparts(pth);
            if strcmp(origFile, foundFile) == 1   % Case sensitive
                fullpath = pth;
                fcnName = foundFile;
            end
        end
        
        % Check the extension -- if it is unknown, then this is an
        % Extrinsic file. Note: must use original extension here, because
        % WHICH returns empty for Extrinsic files.
        if ~isempty(origExt) && ...
           ~matlab.depfun.internal.MatlabInspector.knownExtension(origExt)
            fileType = matlab.depfun.internal.MatlabType.Extrinsic;
        end
    elseif ex == 7
        if isfullpath(name)
            fullpath = name;
        else
            % G1851154 - Workaround for g1851995
            % name is not fullpath
            % exist(fullfile(pwd, name), 'dir') returns 0, but
            % exist(name, 'dir') returns 7.
            error(message('MATLAB:depfun:req:NameNotFound', fullfile(pwd, name)));
        end
    end
end

%------------------------------------------------------------
function [fullpath, symName] = resolveSymbolName(symName)
% resolveSymbolName Given a full or partial symbol name, fully expand it.
% At this point, full expansion means locating the file that contains
% the symbol and canonicalizing the full path of that file according
% to the current platform. File / function name mapping is case 
% sensitive.
%
% Look for the symbol on the path and under MATLAB root. Make sure the
% returned file is not a directory.

    import matlab.depfun.internal.MatlabSymbol;
    import matlab.depfun.internal.cacheWhich;
    import matlab.depfun.internal.cacheExist;
    import matlab.depfun.internal.requirementsConstants;
    
    fullpath = '';
    partialPath = false;
    dotQualified = false;
            
    % Does the file name point to an existing file?
    if ~cacheExist(symName,'file')
        % No. Try to find the name with which.
        pth = cacheWhich(symName);
        
        % Three possible cases:
        %   * symName contains the trailing part of a partial file name.
        %   * symName contains a dot-qualified name of a function or class.
        %   * symName is garbage -- unresolvable.        

        start = length(pth) - length(symName);
        % If the WHICH-result contains the symName, symName was a partial
        % path.
        if start > 0 && strncmpi(pth(start:end),symName,length(symName))
            % Check case -- which inexplicably ignores case when looking for 
            % file names, but strfind performs a case-sensitive check. 
            if contains(pth, symName)
                partialPath = true;
            end
        elseif contains(symName, '.')
            dotQualified = true;
        end
        
        % If the symbol name is a partial path or a dot-qualified name, it
        % is valid and we can accept the WHICH-result as the path to the
        % defining file.
        if partialPath || dotQualified
            fullpath = pth;
        end
        % Didn't work. Look for the file under MATLAB root.
        if isempty(fullpath)
            pth = fullfile(matlabroot,symName);
            % Ensure file / function name case match.
            ex = cacheExist(pth, 'file');
            if (ex == 2 || ex == 6) && contains(pth, symName)
                fullpath = pth;
            else
                fullpath = '';
            end
        end
        
        % G883993: manage undocumented built-in
        if isempty(fullpath) && exist(symName,'builtin') == 5
            fullpath = cacheWhich(symName);
        end
    else             
        % Make sure file is specified with platform-conformant
        % path separators. (If not, WHICH and EXIST will perform
        % inconsistently.
        if ispc
            fullpath = strrep(symName,'/', requirementsConstants.FileSep);
        else
            fullpath = strrep(symName,'\', requirementsConstants.FileSep);
        end
        
        % Try to discover full path to file using which. If which
        % can't find the file, then just use what we were given.
        where = cacheWhich(fullpath);
        if ~isempty(where) 
            fullpath = where;
        end
        % If the full path does not contain a case sensitive match to
        % the function name, we didn't resolve the function, despite what 
        % WHICH and EXIST might think.
        match = contains(fullpath, symName);
        if ~match
            fullpath = '';
        end
    end

    % Check for invalid results -- we must find some file, and that
    % file must not be a directory.
    if isempty(fullpath)
        error(message('MATLAB:depfun:req:NameNotFound',symName))
    elseif exist(fullpath, 'dir') == 7
        error(message('MATLAB:depfun:req:NameIsADirectory',symName))
    end
    
    builtinStr = requirementsConstants.BuiltInStrAndATrailingSpace;
    if strncmp(fullpath,builtinStr,length(builtinStr))
        [~,symName,~] = fileparts(MatlabSymbol.getBuiltinPath(fullpath));
    else
        % Dot qualified names are their own symbols.
        if ~dotQualified
            [~,symName,~] = fileparts(fullpath);
        end
    end
end

%-------------------------------------------------------------
function extList = initKnownExtensions()
% Create a containers.Map with file extensions as keys, for fast lookup.
    import matlab.depfun.internal.requirementsConstants
    
    mext = mexext('all');
    extList = cellfun(@(e)['.' e], { mext.ext }, 'UniformOutput', false );
    extList = unique([ extList ...
                       requirementsConstants.dataFileExt ...
                       requirementsConstants.executableMatlabFileExt ]);
end

%--------------------------------------------------------------
function tf = isValidMatlabFileName(w)
% This function only judges a file with a MATLAB file extension.
    import matlab.depfun.internal.requirementsConstants
    tf = true;
    [~,fname,ext] = fileparts(w);
    if ismember(ext, ...
                requirementsConstants.executableMatlabFileExt_reverseOrder)
        % The rules for naming variable/function/file are almost the same.
        %     tf = ~isempty(regexp(fname,'^[a-z|A-Z]\w*$','ONCE'));
        % The only difference is that a variable cannot be a key word.
        % For example, end.m is a valid MATLAB file name, though 'end' is not 
        % a valid variable name because it is a key word.
        % 
        % ISVARNAME is implemented as 
        % "mxIsValidMatNamePart(str, n) && !inIsKeyword(str)"
        % Therefore, isValidMatlabFileName is equivalent to 
        % "isvarname(fname) || iskeyword(fname)".
        %
        % This part can be replaced when mxIsValidMatNamePart 
        % gets wrapped as a built-in. (G1103186)        
        tf = isvarname(fname) || iskeyword(fname);
    end
end

% LocalWords:  readme mis treq symobl canonicalizing ADirectory fname
