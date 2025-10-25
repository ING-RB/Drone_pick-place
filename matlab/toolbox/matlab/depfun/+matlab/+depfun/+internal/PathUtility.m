classdef PathUtility < handle
%

%   Copyright 2016-2020 The MathWorks, Inc.
    
    properties(Access = private)
        Environment
    end
    
    properties(Dependent,Access = private)
        FullToolboxRoot
        RelativeToolboxRoot
        PcmPath
    end
    
    % patterns for regexp (so we don't have to build the string every time)
    properties(Access = private)
        BaseDirectoryPattern
        RelativePathPattern
    end
    
    % constructor
    methods
        function obj = PathUtility
            
            % Use the Environment that is current at construction
            obj.Environment = matlab.depfun.internal.reqenv;
            
            fs = matlab.depfun.internal.requirementsConstants.FileSep;
            sepstr = '[\/\\]';

            obj.BaseDirectoryPattern = [strrep(regexptranslate('escape',...
                obj.FullToolboxRoot), ['\' fs],sepstr), ...
                sepstr, '(\w+)' sepstr '?'];
            
            pat = [strrep(regexptranslate('escape', ...
                obj.FullToolboxRoot),['\' fs],sepstr), ...
                sepstr, '(\S)+'];
            obj.RelativePathPattern = ...
                sprintf('[%s%s]%s',upper(pat(1)),lower(pat(1)),pat(2:end));
        end
    end
    
    % get
    methods
        function fulltbxrt = get.FullToolboxRoot(obj)
            fulltbxrt = obj.Environment.FullToolboxRoot;
        end
        
        function reltbxrt = get.RelativeToolboxRoot(obj)
            reltbxrt = obj.Environment.RelativeToolboxRoot;
        end
        
        function pcmpth = get.PcmPath(obj)
            pcmpth = obj.Environment.PcmPath;
        end
    end
    
    % public utility
    methods
        function tf = isFromUndeployableMatlabModule(obj,fpath,uncmptbx)
            tf = false;
            if ~isempty(fpath) && contains(fpath,obj.FullToolboxRoot)
                tf = ismember(filename2path(fpath), uncmptbx);
            end
        end

        function new_filename = rp2fp(obj,tbxDir,fileName)
            import matlab.depfun.internal.requirementsConstants
            
            mlrt = requirementsConstants.MatlabRoot;
            reltbxrt = obj.RelativeToolboxRoot;
            
            if iscell(fileName)
                isRP = cellfun('isempty', regexp(fileName,'^<matlabroot>'));
                FPitems = fileName(~isRP);
                RPitems = fileName(isRP);
                
                FPitems = strrep(FPitems,'<matlabroot>',mlrt);
                RPitems = strcat(fullfile(mlrt,reltbxrt,tbxDir,'/'),RPitems);
                
                new_filename = [FPitems; RPitems];
            else
                if isempty(regexp(fileName,'^<matlabroot>','ONCE'))
                    new_filename = strcat(fullfile(mlrt,reltbxrt,tbxDir,'/'),fileName);
                else
                    new_filename = strrep(fileName,'<matlabroot>',mlrt);
                end
            end
            
            new_filename = strrep(new_filename,'\','/');
        end
        
        function keep = keepOnPath(obj,pth)
            fs = matlab.depfun.internal.requirementsConstants.FileSep;
            
            % Find the entries that match 'toolbox/<something>/' (using
            % file separators appropriate for the platform, of course).
            % These are the entries we want to discard.
            keepNonTbx = ~obj.underDirectory(pth, obj.FullToolboxRoot);
            
            % Now, look for directories we must keep:
            %   * MATLAB modules in base MATLAB Runtime (numerics, core)
            %   * toolbox/local and its sub-directories
            %   * toolbox/compiler and its sub-directories
            nv = matlab.depfun.internal.requirementsConstants.pcm_nv;
            list = nv.MatlabModulesInSpecificRuntimeProducts(matlab.depfun.internal.requirementsConstants.base_runtimes);
            [~, idx] = intersect(pth, list, 'stable');
            keepML = false(size(pth));
            keepML(idx) = true;
            
            % Keep those entries that DID match; that means we keep
            % only those entries with a non-empty match. We only keep
            % the strings that contain 'toolbox/local/' somewhere.
            tbxCnL = regexp(pth, ['toolbox\' fs ...
                '((compiler\' fs ')|(local[\' fs ']?))']);
            keepCnL = ~cellfun('isempty', tbxCnL);
            
            % Apply logical index filter to pth cell array, removing the
            % entries for all components except toolbox/matlab.
            keep = keepNonTbx | keepML | keepCnL;
        end
        
        function path_item = parent_to_toolbox(obj,d)
            % Copied directly from SearchPath
            path_item = d;
            tbx_path = fullfile(obj.FullToolboxRoot, d);
            if exist(tbx_path,'dir') == 7
                path_item = tbx_path;
            end
        end
        
        function outstr = componentBaseDir(obj,instr)
            outstr = regexp(instr, obj.BaseDirectoryPattern, 'tokens');
        end
        
        function outstr = componentRelativePath(obj,instr)
            outstr = regexp(instr, obj.RelativePathPattern, 'tokens');
        end
        
        function b = pcmexist(obj)
            b = exist(obj.PcmPath,'file') == 2;
        end

        function pth = dir2path(obj, dir)
        % This function turns a directory full path into a path prefix suitable for
        % the MATLAB path. Since @, +, and private directories cannot appear
        % directly on the MATLAB path, this function removes them from the
        % returned path prefix.
            At_Plus_Private_Idx = at_plus_private_idx(dir);
            if ~isempty(At_Plus_Private_Idx)
                pth = dir(1:At_Plus_Private_Idx-1);
            else
                pth = dir;
            end
        end
    end
    
    methods (Static)
        function tf = underDirectory(apath, adir)
            import matlab.depfun.internal.requirementsConstants
            
            if ~endsWith(adir, {'/' requirementsConstants.FileSep})
                adir = [adir requirementsConstants.FileSep];
            end
            
            if ispc
                % Case insensitive on Windows
                apath = strrep(apath, '/', requirementsConstants.FileSep);
                tf = strncmpi(apath, adir, length(adir));
            else
                % Case sensitive on Unix
                tf = strncmp(apath, adir, length(adir));
            end
        end
        
        function tf = underMatlabroot(apath)
            tf = matlab.depfun.internal.PathUtility.underDirectory(apath, ...
                matlab.depfun.internal.requirementsConstants.MatlabRoot);
        end
        
        function result = stripMatlabroot(apath)
            import matlab.depfun.internal.requirementsConstants
            
            result = apath;
            if matlab.depfun.internal.PathUtility.underMatlabroot(apath)                
                mlroot_len = length(requirementsConstants.MatlabRoot);                
                result(1:mlroot_len) = '';                
            end
        end

        function result = stripToolboxroot(apath)
            import matlab.depfun.internal.requirementsConstants
            
            result = apath;
            if matlab.depfun.internal.PathUtility.underMatlabroot(apath)                
                mlroot_len = length([requirementsConstants.MatlabRoot 'toolbox/']);                
                result(1:mlroot_len) = '';
            end
        end
    end
end

% LocalWords:  pth
