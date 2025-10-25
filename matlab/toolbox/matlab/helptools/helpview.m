function helpview(path, varargin)
%HELPVIEW Displays an HTML file in the Help browser.
%
%SYNTAX
%
%  helpview(short_name, topic_id)
%
%ARGUMENTS
%
%  short_name
%    Short name for a product or installed support package. For example,
%      matlab
%      beagleboard
%
%  topic_id
%    The topic_id is an identifying string in the documentation source
%    for the HTML section to open. Coordinate with the writer to define
%    the ID, which the writer should include in an anchor element. IDs 
%    must be unique within a product.
%
%  'docid', example_id, docid_target
%    When the first argument is the string 'docid', locate the docid link
%    target using example_id (normally this is where the docid link is
%    seen) and docid_target (this is the string next to 'docid:' in the link),
%    and open the target doc page.
%
%EXAMPLES
%
%    helpview('matlab','panning');
%    helpview('matlab','matlab_data_types');

%   Copyright 1984-2021 The MathWorks, Inc.

if nargin < 1
    error(message('MATLAB:helpview:NotEnoughInputArgs'));
end

if isstring(path) && isscalar(path)
    path = char(path);
end

stringInputs = cellfun(@(x)isstring(x) && isscalar(x), varargin);
if any(stringInputs)
    varargin(stringInputs) = cellfun(@char, varargin(stringInputs), 'UniformOutput', false);
end

if ~ischar(path) || strcmp(path, '')
    error(message('MATLAB:helpview:InvalidFirstArg'));
end

% Get input parameters separated from size and location
% Note:  this is to be backwards compatible
[inputArgs, csh_size, csh_location] = getInputArgs(varargin);

% If the first argument is the string 'docid', call the internal function
% for openining docid links.
if strcmp(path, 'docid')
    example_id = inputArgs{1};
    docid_target = inputArgs{2};
    matlab.internal.doc.opendocid(example_id, docid_target);
    return;
end

docPageTopicMap = matlab.internal.doc.csh.DocPageTopicMap.fromTopicPath(path);

if ~exists(docPageTopicMap) && ~startsWith(path,"mapkey:")
    % Direct path to a documentation file.
    help_path = normalize_path(path);
elseif isempty(inputArgs)
    error(message('MATLAB:helpview:TopicIdRequired'));
else
    topic_id = inputArgs{1};
    inputArgs(1) = [];

    doc_page = mapTopic(docPageTopicMap, topic_id);
    if isempty(doc_page) || ~doc_page.IsValid
        errorId = 'MATLAB:helpview:TopicPathDoesNotExist';
        errorMsg = getString(message('MATLAB:helpview:TopicIdDoesNotExist', topic_id, path));
        error(errorId, '%s', errorMsg);
    else
        % Call the help viewer.
        displayDocPage(doc_page(1), csh_size, csh_location, getString(message('MATLAB:helpview:Title')));
        return;
    end
end

doc_page = matlab.internal.doc.url.parseDocPage(help_path);
if isempty(doc_page) || ~doc_page.IsValid
    errorId = 'MATLAB:helpview:PathDoesNotExist';
    errorMsg = getString(message('MATLAB:doc:HelpErrorPageNotFound', help_path));
    error(errorId, '%s', errorMsg);
else
    % Call the help viewer.
    displayDocPage(doc_page, csh_size, csh_location, getString(message('MATLAB:helpview:Title')));
    return;
end

%--------------------------------------------------------------------------

function normal_path = normalize_path(path)
    if (strfind(path, 'http') == 1)
       normal_path = path; 
       return;
    end
    
    % Ensures that path uses the correct separator
    % for the current platform.
    %
    normal_path = regexprep(path, '[\\/]', filesep);

%--------------------------------------------------------------------------

function [inputArgs, csh_size, csh_location] = getInputArgs(originalInputs)

% init parameters
csh_size = [];
inputArgs = [];
csh_location = [];

i = 1;
while i <= length(originalInputs)
    if ~ischar(originalInputs{i})
       % avoid non character
       inputArgs{end+1} = originalInputs{i};
    elseif strcmp(originalInputs{i}, 'position')
        i = i + 1;
        if i > length(originalInputs)
            error(message('MATLAB:helpview:UnspecifiedPosition'));
        elseif ~(length(originalInputs{i}) == 4)
            error(message('MATLAB:helpview:InvalidPosition'));
        else
            % [left bottom width height]
            scrsz = get(0,'ScreenSize');
            v = originalInputs{i};
            csh_size = [v(3) v(4)];
            % watch out for small screen size, otherwise use default
            if (scrsz(4)-v(2)-v(4)) > -1 
               csh_location = [v(1) (scrsz(4)-v(2)-v(4))];
            elseif (scrsz(4)-v(4)) > -1
               csh_location = [v(1) (scrsz(4)-v(4))]; 
            end
        end
    elseif strcmp(originalInputs{i}, 'size')
        i = i + 1;
        if i > length(originalInputs)
            error(message('MATLAB:helpview:UnspecifiedSize'));
        else
            csh_size = originalInputs{i};
        end
    elseif strcmp(originalInputs{i}, 'location')
        i = i + 1;
        if i > length(originalInputs)
            error(message('MATLAB:helpview:UnspecifiedLocation'));
        else
            csh_location = originalInputs{i};
        end
    else
        inputArgs{end+1} = originalInputs{i};
    end
    i = i + 1;
end

% validate size
if ~isempty(csh_size)
    if ~(length(csh_size) == 2)
            error('MATLAB:helpview:InvalidSize', '%s', getString(message('MATLAB:helpview:SizeMustBeWidthHeight'))); 
    elseif min(csh_size) < 1
        error('MATLAB:helpview:InvalidSize', '%s', getString(message('MATLAB:helpview:SizeMustBePositive')));
    end
end

% validate location
if ~isempty(csh_location)
    if ~(length(csh_location) == 2)
        error('MATLAB:helpview:InvalidLocation', '%s', getString(message('MATLAB:helpview:LocationMustBeXY')));
    elseif min(csh_location) < 0
        error('MATLAB:helpview:InvalidLocation', '%s', getString(message('MATLAB:helpview:LocationMustBePositive')));
    end
end

%--------------------------------------------------------------------------

function displayDocPage(docPage, size, location, title)
    % Use the appropriate viewer, based on the DocPage content type.
    launcher = matlab.internal.doc.ui.DocPageLauncher.getLauncherForDocPage(docPage);
    if ~isempty(size)
        launcher.Size = size;
    end
    if ~isempty(location)
        launcher.Location = location;
    end        
    launcher.Title = title;
    launcher.openDocPage();

% End of helpview.m
