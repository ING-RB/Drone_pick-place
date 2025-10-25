classdef SearchPath < handle
% SearchPath manages the source code search path for the requirements function.

%   Copyright 2013-2023 The MathWorks, Inc.

    properties
        % Only internally used for building component-level dfdb 
        Components

        % Limit the MATLAB path to just these directories. The PathLimit
        % directories must be on the MATLAB path (extras cause no error,
        % but have no effect -- that is, if a PathLimit directory is not on
        % the path, it is not added). Preserve the order of the directories
        % on the MATLAB path -- ignore the order in which they appear in
        % the PathLimit list.
        PathLimit
    end

    properties (Dependent = true)
        % A string suitable for passing to MATLAB's PATH function. A read-only
        % property.
        PathString
    end
    
    properties (SetAccess = private)
        % The list of search locations, in order. A cell array of strings.
        % PathString is computed from PathList.
        PathList
    end

    properties (Access = private)
        % The set functions need to behave differently when called from the
        % constructor.
        Constructed

        % List of extra directories to be added to the PathList during
        % "assembly." A structure with two fields: atStart, atEnd, each of
        % which contains a cell array. 
        IncludePath
        
        PathUtility

        Target
        
        % PCM navigator
        pcm_nv
    end

    methods (Access = private)
        
        function r = find_dir(obj, d, mustExist)
        % Look for d (a directory) on the PathList. It must be there.
        % Return d's index on the PathList.
            r = 0;
            idx = strcmp(d, obj.PathList);
            if any(idx)
                r = find(idx);
            elseif mustExist
                error(message('MATLAB:depfun:req:NonExistSearchDir', d))
            end
        end

        function n = position(obj, directoryList)
        % Look for the directories in directoryList on the PathList. 
        % Return a vector of their locations on the list. Position 0 means
        % not on the list.
            n = cellfun(@(d)find_dir(obj, d, false), directoryList);
        end

        function removeUndeployableMatlabModuleFromPath(obj)
        % Remove uncompilable toolboxes from the path.
            
            % Extract the list of undeployable MATLAB modules from the PCM database.
            undeployableMatlabModule = obj.pcm_nv.getUndeployableMatlabModule();

            % Remove uncompilable toolbox directories and sub-directories
            % off the MATLAB path.
            pth = regexprep(obj.PathList, '[\/\\]', filesep);
            [~,keep] = setdiff(pth, undeployableMatlabModule, 'stable');
            obj.PathList = obj.PathList(keep);
        end
        
        function assemble_path(obj, include)
        % Put the path together. Start with the MATLAB path, add the include
        % items and remove the exclude items.

            % Split the path into a cell array of strings. Use of pathsep
            % accommodates platform-specific path formatting.
            pth = regexp(path, ['[^' pathsep ']+'], 'match');
            origPath = pth;
            
            % Limit the path, if PathLimit is not empty
            path_limit = obj.PathLimit;         
            
            if ~isempty(path_limit)
                % Determine if any of the path_limit items represent
                % partial paths beginning at the toolbox root. Split the
                % path_limit list into two -- tbx_path contains full paths
                % of path_limit items originating in matlab/toolbox, and
                % path_limit contains the remaining obj.PathLimit items
                % that do not.
                [tbx_path, path_limit] = realize_toolbox_path(path_limit); 
                
                % Include the children of any toolbox roots
                tbx_children = include_children(tbx_path);
                
                % Recompose the path_limit list to consist of full paths to
                % toolbox roots and their children and any remaining
                % original path limit directories.
                path_limit = [tbx_path tbx_children path_limit];
                path_limit = unique(path_limit, 'stable');  % No duplicates

                % Limit the PathLimit items to those that are already on the
                % MATLAB path. realized is a logical index indicating which
                % members of path_limit were found on the MATLAB path.
                [path_items, match] = realize_partial_path(path_limit);
                path_limit = path_items(match);
                
                % Expand the list of path_limit items to include any
                % subdirectories of the original list. Only include those
                % sub-directories which are already on the MATLAB path.
                path_limit = include_children(path_limit);
               
                % Filter for duplicates again, since include_children might
                % have added a duplicate.
                path_limit = unique(path_limit,'stable');
            end
            
            if ~isempty(obj.Components) || ...
                    ~isempty(obj.PathLimit)
                % If Components not equal to the AllComponents constant,
                % this path should span ONLY the listed components. So,
                % remove all components from the base MATLAB path,
                % trusting that the include list will have the required
                % component directories. (Never remove toolbox/matlab.)
                
                pth = pth(obj.PathUtility.keepOnPath(pth));
            end

            % Assemble the path from these path item sets:
            %   * pth: The MATLAB path, with component directories removed
            %          as indicated by -c.
            %
            %   * path_limit: Component-specific directories to add back
            %          to the path. Determined by -p. May be empty.
            %
            %   * include: Component-specific dependent directories 
            %          retrieved from the database.
            %
            %   * exclude: Directories excluded by the given target and
            %          component list.
            %
            %   * obj.IncludePath: User-specified include directories. Add
            %          at the beginning or end of the path, as directed by
            %          user.
            %
            % The directories in the path_limit and include sets must be
            % added to the path in the relative order in which they appear
            % on the MATLAB path.
            
            % Initialize obj.PathList
            obj.PathList = pth;
            
            % Filter the path_limit items against the exclude list. (Make
            % sure their file separators lean the right way.) And remove
            % from the path_limit list any path_items already on the
            % PathList.
            if ~isempty(path_limit)
                path_limit = path_limit(~ismember(path_limit, obj.PathList));
            end

            % Add the path_limit items to the PathList. Thus, the next step
            % will remove path_limit as well as PathList duplicates from
            % the include list.
            obj.PathList = [obj.PathList path_limit];
            
            % Remove from the include list any path items 
            % already on the PathList. (MATLAB gets angry if you put 
            % duplicate items on the path.)
            include = include(~ismember(include, obj.PathList));
            
            % Require that the remaining include list items actually exist
            % as directories. MATLAB cries out in protest at any attempt to
            % add non-existent directories to the path. We wait until this
            % point to filter because ISDIR is an expensive operation, and
            % include has been reduced to minimum size by previous steps.
            % (ISDIR ignores file separator direction.)
            %
            % We do not need to filter path_limit or PathList items because
            % they are drawn from the MATLAB path and the file system. The
            % SearchPath constructor checks that +I and -I path items
            % exist.
            keep = cellfun(@isfolder, include);
            include = include(keep);
            
            % Add the include items to the PathList. Note
            % that include trumps exclude, so never filter the include
            % items against the exclude list.
            obj.PathList = unique([obj.PathList include], 'stable');
            
            % Remove from the PathList any items that are not on the
            % original MATLAB path. These removed items will later be added
            % to the end of the path.
            [invaders, iLoc]= setdiff(obj.PathList, origPath);
            obj.PathList(iLoc) = [];
            
            % Reorder the PathList so that all path items have the same
            % relative order they did on the MATLAB path. This ensures that
            % path_limit and include items maintain their relative order.
            %
            % The MATLAB path is supposed to be free of duplicates, so
            % no need for 'UniformOutput', false here. We can pass the
            % strcmp result right to find.
            order = cellfun(@(d)find(strcmp(d,origPath)), obj.PathList);
           
            [~,k] = sort(order);
            obj.PathList = obj.PathList(k);
            
            % Add back the path_limit and include path items that were not
            % on the original MATLAB path.
            obj.PathList = [ obj.PathList invaders ];
            
            % Add the include paths, if specified, to the path.
            add(obj, obj.IncludePath.atStart, false);
            add(obj, obj.IncludePath.atEnd, true);
            
            % Remove uncompilable toolboxes and sub-directories 
            % from obj.PathList.
            obj.removeUndeployableMatlabModuleFromPath();
            
            % Finally, make sure the assemble list has no duplicates. 
            % Performing this operation on the entire list allows +I to 
            % override (modify) the position of a directory in the list, 
            % actually moving it to the front if it is already on the path.
            %
            % Doing this last ensures that the file separators have been
            % normalized, so that directories cannot differ only by
            % file separator direction.
            obj.PathList = unique(obj.PathList,'stable');
        end
        
        function idx = findDirAndItsSubDirsOnPath(~, p, d)
            if ischar(p)
                p = {p};
            end

            % For example, a/b/c, a/bd, a/b/c/d, a/b are on the path
            % if we are looking for a/b and its sub-dirs,
            % a/bd should not be picked up.
            d_sep = [d matlab.depfun.internal.requirementsConstants.FileSep];
            idx = strcmp(p, d) | strncmp(p, d_sep, length(d_sep));
        end
        
        function initialize_path(obj)
            [plist, clist] = specifiedScope(obj);
            path_entries = obj.deployablePathEntries(plist, clist);
            assemble_path(obj, path_entries);
        end

        function [plist, clist] = specifiedScope(obj)
        % Based on PathLimit and Components, return
        %    plist - a list of specified products,
        %    clist - a list of specified components
        % to keep in the scoped MATLAB search path.
        % 
        % An empty list means nothing is specified.
            
            % Components specified with -c flag for internal usage.
            clist = obj.Components;

            % Process PathLimit, which can be 
            % * toolbox name, e.g. images (most common use case)
            % * a partial path relative to $MATLABROOT/toolbox, e.g. shared/dsp/vision/simulink/utilities
            % * a full path under $MATLABROOT/toolbox, e.g. $MATLABROOT/toolbox/shared/dsp/vision/simulink/utilities
            plist = {};
            for k = 1:numel(obj.PathLimit)
                item = '';
                
                % * a full path under $MATLABROOT/toolbox, e.g. $MATLABROOT/toolbox/shared/dsp/vision/simulink/utilities
                if isfullpath(obj.PathLimit{k})
                    if obj.PathUtility.underDirectory(obj.PathLimit{k}, ...
                            [matlab.depfun.internal.requirementsConstants.MatlabRoot 'toolbox' matlab.depfun.internal.requirementsConstants.FileSep]) ...
                        && exist(obj.PathLimit{k},'dir')==7
                        item = obj.PathUtility.stripToolboxroot(obj.PathLimit{k});
                    end
                elseif ~isempty(realize_toolbox_path(obj.PathLimit(k)))                   
                    % toolbox name, e.g. images
                    % * a partial path relative to $MATLABROOT/toolbox, e.g. shared/dsp/vision/simulink/utilities
                    item = obj.PathLimit{k};
                end

                % Ignore it, if it is not a folder under $MATLABROOT/toolbox.
                if isempty(item)
                    continue;
                end

                % toolbox name, e.g. images
                pinfo = obj.pcm_nv.productInfo(item);
                if ~isempty(pinfo)
                    plist{end+1} = item; %#ok
                    continue;
                end

                % * a partial path relative to $MATLABROOT/toolbox, e.g. shared/dsp/vision/simulink/utilities
                d = realize_toolbox_path(obj.PathLimit(k));
                if ~isempty(d)
                    cname = obj.pcm_nv.componentOwningFile(d{1});
                    if ~isempty(cname)
                        clist{end+1} = cname; %#ok
                    end
                end
            end

            oom_pairs = oom_component_data;            
            idx = ismember(oom_pairs(:,1), [plist clist]);
            additional_clist = oom_pairs(idx,2)';
            clist = unique([clist additional_clist]);
        end

        function entries = deployablePathEntries(obj, plist, clist)
            entries = {};
            if ~isempty(plist)
                result = cellfun(@(p)obj.pcm_nv.componentShippedByProduct(p), plist, ...
                                  'UniformOutput',false);
                result  = [result{:}];
                clist = [clist result];
            end

            if ~isempty(clist)
                entries = obj.pcm_nv.scopedMatlabModuleListForDfdbComponent(clist)';
                if ~isempty(entries)
                    entries = strcat(matlab.depfun.internal.requirementsConstants.MatlabRoot, unique(entries));
                end
            end
        end
    end

    methods
        function s = SearchPath(target, varargin)
        % Create a SearchPath object. 
        %
        %   target: must be 'MCR' for now.
        %       
        %   -p { directory list }: Drop all toolboxes from the path, then 
        %       the specified directories to the path. Limits the path to
        %       these directories and their sub-directories. Makes analysis
        %       quicker and more accurate. Directories in this list may be
        %       relative paths. If the relative path appears to originate
        %       in matlab/toolbox, then the effect is to add the toolbox's
        %       directories back to the path.  -p {'comm'}, for example,
        %       adds the Communication Toolbox back to the path.
        %       Directories are added to the path in the same order in
        %       which they appeared in the original path (before toolbox
        %       directories were removed).
        %
        %  -I { directory list }: Add the directories to the end of the
        %       MATLAB path. The directories may be specified as relative
        %       paths, but they must be relative to the current directory
        %       -- they are not tested for origin in matlab/toolbox. Use +I
        %       to add directories to the front of the path.
        %
        %  -c { component list}: Modify the path according to the include
        %       exclude list of the given component. Data for the component
        %       must be present in the database.
        %      
        % s = SearchPath('MCR') 
        %   MCR-specific path, all toolboxes, default database.
        %
        % s = SearchPath('MCR', '-p', 'matlab'}
        %   MCR-specific path, MATLAB toolbox only, default database.
        %
        % s = SearchPath('MCR', '-p', 'images')
        %   MCR-specific path, Image Processing toolbox only, default database.
        %
        % s = SearchPath('MCR', '-p', {'images', 'stats' });
        %   MCR-specific path, Image and Statistics toolboxes, default database.
        %
        % s = SearchPath('MCR', '-p', {'images', 'stats'}, ...
        %                '-i', { '/some/directory' })
        %   MCR-specific path, Image and Statistics toolboxes, an include
        %   directory.
        %
        % s = SearchPath('MCR', '-p', {'images', 'stats'}, 
        %                '-c', 'compiler');
        %   MCR-specific path, Images and Statistics toolbox directories on
        %   the path, Compiler component dependencies on the path.
               
            % Not fully initialized yet. Must set first, so property set
            % functions behave properly.
            s.Constructed = false;
        
            % Validate number of inputs
            narginchk(1, 8);
            
            % Target must be a character string
            if ~ischar(target)
                error(message('MATLAB:depfun:req:InvalidInputType', ...
                    1, class(target), 'char'))
            end
            
            % Set include path cell arrays to empty.
            s.IncludePath.atStart = {};
            s.IncludePath.atEnd = {};
            
            % Initialize PathUtility
            s.PathUtility = matlab.depfun.internal.PathUtility;
            
            % Process variable argument list. Argument interpretation based on
            % both position and type -- tricky code, but better usability.
            
            idx = 1;
            include_path_end_idx = 0; 
            include_path_start_idx = 0;
            while idx <= numel(varargin)
                
                % Always look for a string -- each valid argument group
                % must begin with a string.
                if ~ischar(varargin{idx})
                    error(message('MATLAB:depfun:req:InvalidInputType', ...
                        idx, class(varargin{idx}), 'character'))
                end
                
                % Case does not matter for -p and -I switches. Safe to call
                % lower since we detect non-character arguments just above.
                ps = lower(varargin{idx});   % Parse Switch
                switch ps
                    case '-p'
                        if idx+1 > numel(varargin)
                            error(message(...
                                'MATLAB:depfun:req:MissingPathArg', ...
                                idx, varargin{idx}))
                        end
                        idx = idx + 1;
                        % Path Limit validity checking performed by 
                        % set.PathLimit.
                        s.PathLimit = varargin{idx};
                    case '-i'
                        % Consistent with '-I' in mcc.
                        idx = idx + 1;
                        if idx <= numel(varargin)
                            incDir = varargin{idx};
                            if ischar(incDir), incDir = { incDir }; end
                            s.IncludePath.atStart = incDir;
                            include_path_start_idx = idx;
                        else
                            error(message(...
                             'MATLAB:depfun:req:InvalidSearchDirectory', ''))
                        end
                    case '+i'
                        % Add directories to the end of the path.
                        idx = idx + 1;
                        if idx <= numel(varargin)
                            incDir = varargin{idx};
                            if ischar(incDir), incDir = { incDir }; end
                            s.IncludePath.atEnd = incDir; 
                            include_path_end_idx = idx;
                        else
                            error(message(...
                             'MATLAB:depfun:req:InvalidSearchDirectory', ''))
                        end
                    case '-c'
                        idx = idx + 1;
                        s.Components = varargin{idx};
                    otherwise                        
                        error(message('MATLAB:depfun:req:InvalidOption', varargin{idx}));
                end
                idx = idx + 1;
            end

            s.pcm_nv = matlab.depfun.internal.requirementsConstants.pcm_nv;

            % IncludePath must be empty or a string or a cell array.
            if isfield(s.IncludePath, 'atStart') ...
                    && ~ischar(s.IncludePath.atStart) ...
                    && ~iscell(s.IncludePath.atStart)
                error(message('MATLAB:depfun:req:InvalidIncludePathType', ...
                    include_path_start_idx, class(s.IncludePath.atStart)))
            end
            
            if isfield(s.IncludePath, 'atEnd') ...
                    && ~ischar(s.IncludePath.atEnd) ...
                    && ~iscell(s.IncludePath.atEnd)
                error(message('MATLAB:depfun:req:InvalidIncludePathType', ...
                    include_path_end_idx, class(s.IncludePath.atEnd)))
            end   
            
            function revise_include_paths(obj, location)
            % Make sure include paths exist, and if they're partials on the
            % MATLAB path, expand them to full paths. Remove non-existent
            % paths from the include list (without warning or error).
                dirList = obj.IncludePath.(location);
                existing = cellfun(@(d)exist(d, 'dir') == 7, dirList);

                % Empty include path: error! It is OK to try and add
                % non-existent directories to the list -- they just
                % won't show up (but it is only an error if the directory
                % name is actually empty).
                if any(~existing)
                     if any(cellfun('isempty',dirList))
                        error(message(...
                            'MATLAB:depfun:req:InvalidSearchDirectory', ''))
                    end
                end

                obj.IncludePath.(location) = dirList(existing);

                [pathItems, realized] = realize_partial_path(dirList);
                obj.IncludePath.(location)(realized) = pathItems(realized);
            end
            
            if isfield(s.IncludePath, 'atStart')
                revise_include_paths(s, 'atStart');           
            end
            
            if isfield(s.IncludePath, 'atEnd')
                revise_include_paths(s, 'atEnd');           
            end
  
            % Theoretically MATLAB target can be supported as well.
            % Let us know if there is a use case for MATLAB.
            if matlab.depfun.internal.Target.parse(target) ~= ...
                matlab.depfun.internal.Target.MCR
                error(message('MATLAB:depfun:req:InvalidTarget', ...
                    target, 'MCR'));
            end
            s.Target = target;
                        
            % Get the target-specific path from the database
            initialize_path(s);
            
            % Object has been constructed.
            s.Constructed = true;
        end
        
        function add(obj, directoryList, atEnd)
        % Add a one or more directories to the search path. The directories
        % must exist (and be directories). Don't allow duplicates. If a
        % directory we're adding already exists in the path list, keep them
        % in the original order on the path.
        
            % Add to the end by default.
            if nargin == 2
                atEnd = true;
            end
            
            % Uniform processing: directory list always a cell array.
            if ischar(directoryList)
                directoryList = { directoryList };
            end
            
            if ~iscell(directoryList)
                error(message('MATLAB:depfun:req:InvalidInputType', 2, ...
                    class(directoryList), 'cell array'))
            end

            % Don't allow duplicates in the directory list.
            directoryList = unique(directoryList, 'stable');

            % Determine if any directories are already on the PathList; if
            % they are, keep them in the order-sensitive context.
            % See help document of MCC for details.
            [~,~,rm] = intersect(obj.PathList, directoryList);
            directoryList(rm) = [];
            
            % TODO: Filter directoryList against exclude list?
            
            function add_dir(d, atEnd)
                if exist(d, 'dir') == 7
                    if atEnd
                        obj.PathList{end+1} = d;
                    else
                        obj.PathList = [ d obj.PathList ];
                    end
                else
                    error(message('MATLAB:depfun:req:NonExistDir', d))
                end
            end
            
            % If adding to the front of the list, reverse the directory
            % list first to maintain its original order. (Otherwise the
            % last element of the directory list ends up at the very front
            % of the path -- the list is added in reverse order.)
            if atEnd == false
                directoryList = directoryList(end:-1:1);
            end
            
            cellfun(@(d)add_dir(d, atEnd), directoryList);
        end

        % Property set/get methods
        
        function str = get.PathString(obj)
        % Merge the strings in PathList into a single pathsep-separated
        % string suitable for passing to MATLAB's path function.

            str = ''; % Always assign to output variables
            
            if ~isempty(obj.PathList)
                % Create a cell array where each entry begins with pathsep.
                fmtStr = [pathsep '%s'];
                str = cellfun(@(p)sprintf(fmtStr, p), obj.PathList, ...
                          'UniformOutput', false);

                % Concatenate them into a single string.
                str = [ str{:} ];

                % Chop off the first pathsep, since it has no purpose.
                str = str(2:end);
            end
        end
                
        function set.PathLimit(obj, pathItems)
        % Set the PathLimit list. Recalculate the path based on the new
        % component list. 
        
            % The list must not be empty. This catches empty character
            % strings as well as empty cell arrays.
            if isempty(pathItems)
                error(message('MATLAB:depfun:req:InvalidSearchDirectory',''))
            end
            
            % Convert character array to cell array
            if ischar(pathItems) && isvector(pathItems)
                pathItems = { pathItems };
            % Not a character string? Better be a cell array of strings
            elseif ~iscell(pathItems)
                error(message('MATLAB:depfun:req:InvalidPathLimitType', ...
                    class(pathItems)))
            else
                strItems = cellfun(@ischar, pathItems);
                if ~all(strItems)
                    offenders = find(~strItems);
                    error(message('MATLAB:depfun:req:InvalidPathLimitType', ...
                        class(pathItems{offenders(1)})))
                end
            end
            
            % TODO: Complain about path items that aren't on MATLAB's path?
            
            % No wild cards here. Must set this field before setting
            % s.Components, because set.Components calls initialize_path,
            % which references PathLimit.
            obj.PathLimit = pathItems;
            
            if obj.Constructed %#ok -- set first in constructor
                initialize_path(obj);
            end
        end
        
        function set.Components(obj, componentList)
        % Set the component list. Recalculate the path based on the new
        % component list.

            % The rest of the machinery expects the list to be a cell
            % array. We allow it to be a singleton for convenience, but
            % convert it here to a cell array.
            if ~iscell(componentList)
                componentList = { componentList };
            end
            obj.Components = componentList;
            
            if obj.Constructed  %#ok -- set first in constructor
                initialize_path(obj);
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Local functions

function [path_list, partial] = realize_toolbox_path(partial)
% If a partial path exists relative to the toolbox root, return the
% corresponding full path. partial is a cell array of strings.

    % Replace partial paths that originate in matlab/toolbox with their
    % full paths. Remove the realized paths from the input list of partial
    % paths.
    pthutil = matlab.depfun.internal.PathUtility;
    path_list = cellfun(@(d)pthutil.parent_to_toolbox(d), partial, ...
        'UniformOutput', false);
    unchanged = strcmp(path_list, partial);
    partial = partial(unchanged);
end

function [path_items, match] = realize_partial_path(partial)
% Look for MATLAB path entries that match the input paths. Paths may be
% partial or full. Replace the input partial paths with their matches. 
% Leave unmatched partials alone and matched or unmatched full paths alone. 
% Also return a logical index indicating which partials and full paths 
% matched.
    ps = pathsep;
    % The MATLAB path always uses platform-specific file separators.
    % Convert the partial path to use platform-specific separators or else
    % the partial path items might not match.
    partial = strrep(partial,'\','/');  % Normalize to one true separator

    % Escaped platform-specific; each partial becomes part of a regular
    % expression, escape required.
    partial = strrep(partial,'/',['\' filesep]); 

    % REGEXP will return empty for directories that don't match anything on 
    % the path string. Make sure to use the platform-specific path separator,
    % or REGEXP will match way too much.
    path_items = cellfun(@(d) ...
         regexp(path,['(^|' ps ')[^' ps ']*' d '(' ps '|$)'],...
                'match','once'), ...
        partial, 'UniformOutput', false);

    % Locate partial path items that were found on the MATLAB path
    match = ~cellfun('isempty',path_items);

    % Remove extra semi-colons (path separators). These are an
    % artifact of the regular expression match; noise, at this
    % point.
    path_items = strrep(path_items,ps,'');

    % Replace empty path_items (these were not found on the MATLAB
    % path) with the corresponding input partial paths.
    path_items(~match) = partial(~match);
end

function data = flatten(data)
% flatten Flatten a cell array (remove all nesting).

    if iscell(data)
        data = cellfun(@flatten,data,'UniformOutput',false);
        if any(cellfun(@iscell,data))
            data = [data{:}];
        end
    end
end

function path_items = include_children(parents)
% Given a list of parent directories, construct a list that consists of
% those parents and all their children which are on the MATLAB path.

    % TODO: escape all regexp chars. valid in a file name
    parents = strrep(parents,'\','\\');
    
    fs = matlab.depfun.internal.requirementsConstants.FileSep;
    pth = regexp(path, pathsep, 'split');
    
    function kids = find_children(p)
        % Chop off terminal file separator so we can replace it with 
        % uniform, platform-specific file separator.
        if p(end) == fs
            p(end) = [];
        end
    
        % Find all the children of this parent which are on the path (all
        % the directories which have this parent as a proper prefix).          
        found = regexp(pth, [p '\' fs],'once');
        
        % Locate partial path items that were found on the MATLAB path
        kids = {};
        if ~isempty(found)
            keep = ~cellfun('isempty',found);
            kids = pth(keep);  
        end
    end

    % Assemble a cell array of cell arrays of children
    path_items = cellfun(@(p)find_children(p), parents, ...
                         'UniformOutput', false);
    
    % Remove escapes, since we must return actual, valid path items.
    parents = replace(parents, '\\', '\');
    
    % Flatten all the directories -- parents and children -- into a single
    % cell array.
    path_items = flatten([ path_items parents ]);
end
                      
% LocalWords:  d's undeployable tbx pth dirs WAAAAAY rexp filerdesign filterdesign Sql
