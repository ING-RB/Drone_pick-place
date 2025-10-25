function result = dependencyAnalysis(varargin)
% compiler.ui.internal.dependencyAnalysis is an adaptor
% between UIs of MATLAB Compiler products and the dependency analysis.
%
% Inputs
%   See required and optional inputs in the input parser section below.
%
% Outputs
%   Required files, products, support packages, etc.

% Copyright 2024 The MathWorks, Inc.

    p = inputParser;
    addRequired(p, 'Files', @iscellstr);                      % Entry points 
    % addParameter(p, 'Target', @ischar);                     % reserved for further refactoring
    addParameter(p, 'AdditionalItems', {}, @iscellstr);       % -a flags
    addParameter(p, 'AutoDetectDataFiles', true, @islogical); % -X flag's opposite
    addParameter(p, 'SupportPackages', {});                   % -Z flag
    parse(p, varargin{:});

    items      = p.Results.Files;
    dashA_list = p.Results.AdditionalItems;

    % Find containing directories of main file(s) and extra -a entries.
    % When any entry is a directory, find sub-directories and
    % files recursively under it.
    [updated_items, dashI_list] = preprocessItems(vertcat(items(:), dashA_list(:))');

    optional_inputs = {};
    if ~isempty(dashI_list)
        optional_inputs = [optional_inputs '-I' {dashI_list}];
    end

    % Congifure auto data file detection
    import matlab.depfun.internal.requirementsSettings
    orgDataDetec = requirementsSettings.isDataDetectionOn;
    resetRequirementsSettings = onCleanup(@()requirementsSettings.setDataDetection(orgDataDetec));
    requirementsSettings.setDataDetection(p.Results.AutoDetectDataFiles);

    % Pass on SupportPackages
    optional_inputs = [optional_inputs '-Z' {p.Results.SupportPackages}];

    % Call REQUIREMENTS with the hybrid Deploytool target, which means
    % 1. (MCR Target) Setup the MATLAB search path using the dependency database.
    % 2. (MATLAB Target) Only return dependencies written by user WITHOUT using the dependency database.
    % 3. (MATLAB Target) Required products are MATLAB products. This required
    %    product list is used to prompt possibly required support packages in
    %    deploytool.
    [parts, resources] = matlab.depfun.internal.requirements(updated_items, 'Deploytool', optional_inputs{:});

    % Two project-related checks:
    %  (1) Is under project root?
    %  (2) Is in project?
    result.files = struct('path', {parts.path}, 'problems', []);
    for k = 1:numel(parts)
        f = parts(k).path;
        result.files(k).problems = struct('NotUnderProjectRoot', ~matlab.project.isUnderProjectRoot(f), ...
                                          'NotInProject', ~matlab.project.isFileInProject(f));
    end

    result.support_packages = resources.supportpackages;
    % result.products = resources.products; % reserved
    % result.graph = []; % reserved
end

% ------------------------------------------------------------------------
% Local helper functions
% ------------------------------------------------------------------------
function [updated_items, more_dashI_dirs] = preprocessItems(items)
% This function finds additional -I directories and additional -a files.
% It also updates the original list by removing directories and adding
% files under those directories.

    updated_items = unique(items);
    exist_results = cell2mat(cellfun(@(f)exist(f,'file'), updated_items, 'UniformOutput', false));
    dirIdx = (exist_results == 7);
    fileIdx = (exist_results > 0) & ~dirIdx;
    dirs = updated_items(dirIdx);
    files = updated_items(fileIdx);
    % Don't error for non-existing items in this function. They will be properly
    % flagged in a later step.
    non_dir_items = updated_items(~dirIdx);
    % The updated list contains no directory.
    updated_items = non_dir_items;

    % Find sub-directories and files in them recursively.
    num_dirs = numel(dirs);
    sub_dirs = cell(1, num_dirs);
    sub_dir_files = cell(1, num_dirs);
    for d = 1:num_dirs
        % Convert relative path to full path
        if matlab.depfun.internal.PathNormalizer.isfullpath(dirs{d})
            base_dir = dirs{d};
        else
            base_dir = fullfile(pwd, dirs{d});
        end

        sub_dirs{d} = recursivelyFindSubDirContents(base_dir, 'dir');
        sub_dir_files{d} = recursivelyFindSubDirContents(base_dir, 'file');
    end
    sub_dirs = unique([sub_dirs{:}]);
    % Append files in those sub-directories to the updated list
    more_files = [sub_dir_files{:}];
    updated_items = unique([updated_items more_files]);

    matlab.depfun.internal.cacheExist();
    pathIdx = contains(files, filesep);
    % Combine containing directories (main files and -a files) and sub-directories
    % filename2path rules out +, @, private directories.
    dirs = strcat([dirs sub_dirs fileparts(files(pathIdx))], filesep);
    path_util = matlab.depfun.internal.PathUtility;
    more_dashI_dirs = unique(cellfun(@(d)path_util.dir2path(d), ...
                                        dirs, 'UniformOutput', false));
end

function contents = recursivelyFindSubDirContents(baseDir, type)
    contents = {};

    if ispc
        if strcmp(type, 'dir')
            cmd = ['dir /s /A:D /B "' baseDir '"\*'];
        elseif strcmp(type, 'file')
            cmd = ['dir /s /A-D /B "' baseDir '"\*'];
        end
    elseif isunix
        if strcmp(type, 'dir')
            cmd = ['find "' baseDir '" -type d'];
        elseif strcmp(type, 'file')
            cmd = ['find "' baseDir '" -type f'];
        end
    else
        return;
    end

    [failed, msg] = system(cmd);
    if ~failed && ~isempty(msg)
        results = textscan(msg, '%s', 'Delimiter', '\n');
        if ~isempty(results)
            contents = results{1}';
        end
    end
end

