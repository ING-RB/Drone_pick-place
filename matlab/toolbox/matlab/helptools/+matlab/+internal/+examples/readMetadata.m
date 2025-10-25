function [metadata,dom] = readMetadata(id, componentDir)
%

%   Copyright 2020-2022 The MathWorks, Inc.

metadata = struct( ...
    'id', id, ...
    'component', '', ...
    'filename', '', ...
    'componentDir', '', ...
    'main', '', ...
    'extension', '', ...
    'files', '', ...
    'dirs', '', ...
    'products', '', ...
    'alternatives', '', ...
    'thumbnail', '', ...
    'thumbnailIsCheckedIn', false, ...
    'project', '');

tokens = regexp(id,'(\w+)-(\w+)','tokens','once');
metadata.component = tokens{1};
metadata.filename = tokens{2};

if endsWith(componentDir,'examples.xml') 
    examplesXml = componentDir;
    [componentDir, ~, ~] = fileparts(examplesXml);
    metadata.componentDir = componentDir;
else
    metadata.componentDir = componentDir;
    examplesXml = fullfile(metadata.componentDir,'examples.xml');
end

dom = matlab.internal.examples.getExampleDom(metadata.filename, examplesXml);
% Main file
mainNode = dom.getElementsByTagName('source').item(0);
metadata.main = getChar(mainNode);
metadata.extension = getChar(dom.getElementsByTagName('extension').item(0));

% Supporting files and subfolders.
fileNodes = dom.getElementsByTagName('file');
files = cell(fileNodes.getLength(),1);
for i = 1:fileNodes.getLength()
    fileNode = fileNodes.item(i-1);
    fileName = getChar(fileNode);
    if startsWith(fileName, 'html/')
        continue;
    end
    files{i,1} = struct( ...
        'filename', getChar(fileNode), ...
        'component', metadata.component, ...
        'componentDir', metadata.componentDir, ...
        'mexFunction', char(fileNode.getAttribute('mexFunction')), ...
        'timestamp', char(fileNode.getAttribute('timestamp')), ...
        'open', char(fileNode.getAttribute('open')));
end
files(cellfun('isempty',files)) = [];
metadata.files = files;

dirNodes = dom.getElementsByTagName('dir');
dirs = cell(dirNodes.getLength(),1);
for i = 1:dirNodes.getLength()
    dirNode = dirNodes.item(i-1);
    dirs{i,1} = struct( ...
        'dirname', getChar(dirNode), ...
        'component', metadata.component, ...
        'componentDir', metadata.componentDir, ...
        'timestamp', char(dirNode.getAttribute('timestamp')));
end
metadata.dirs = dirs;

productNodes = dom.getElementsByTagName('product');
products = [];
for i = 1:productNodes.getLength()
    productNode = productNodes.item(i-1);
    products{end+1} = getChar(productNode);
end
if ~isempty(products)
    metadata.products = strjoin(products, ',');
end

alternativeNodes = dom.getElementsByTagName('alternativeProduct');
alternatives = [];
for i = 1:alternativeNodes.getLength()
    alternativeNode = alternativeNodes.item(i-1);
    alternatives{end+1} = getChar(alternativeNode);
end
if ~isempty(alternatives)
    metadata.alternatives = strjoin(alternatives, ',');
end

% workFolder.
wf = getNodeValue(dom,'workFolder','char');
if ~isempty(wf)
    metadata.workFolder = wf;
end

% Callback.
cb = getNodeValue(dom,'callback','char');
if ~isempty(cb)
    metadata.callback = cb;
end

% Sandbox-published
sp = getNodeValue(dom,'sandboxPublished','logical');
if ~isempty(sp)
    metadata.sandboxPublished = true;
end

% Hide code
hc = getNodeValue(dom,'hideCode','logical');
if ~isempty(hc)
    metadata.hideCode = true;
end

% Thumbnail
tn = getNodeValue(dom,'thumbnail','char');
if ~isempty(tn)
    metadata.thumbnailIsCheckedIn = ~startsWith(tn, 'html/');
    metadata.thumbnail = regexprep(tn, '(?:data|html)/', '');
end

% Project
prNodes = dom.getElementsByTagName('project');
project = cell(prNodes.getLength(),1);
for i = 1:prNodes.getLength()
    prNode = prNodes.item(i-1);
    f = getChar(prNode);
    [filepath,name,ext] = fileparts(f);
    if isempty(filepath)
        supported = true;
        f = fullfile(componentDir,"projects",f+".zip");
    else
        supported = false;
        f = fullfile(matlabroot,f);
    end
    project{i} = struct( ...
        'name', name, ...
        'path', f, ...
        'supported', supported, ...
        'root', char(prNode.getAttribute('root')), ...
        'type', char(prNode.getAttribute('type')), ...
        'open', char(prNode.getAttribute('open')), ...
        'reference', char(prNode.getAttribute('reference')), ...
        'cmSystem', char(prNode.getAttribute('cmSystem')));
end
metadata.project = [project{:}];

end

function s = getNodeValue(dom,nodeName,nodeType)
s = [];
nodes = dom.getElementsByTagName(nodeName);
if nodes.getLength() ~= 1
    % TODO error?
    return;
else
    node = nodes.item(0);
    switch nodeType
        case 'char'
            s = getChar(node);
        case 'logical'
            % Don't actually check the node value, its presence indicates
            % the value was set.
            s = true;
    end
end
    
    
end

function s = getChar(n)
textNode = n.getFirstChild();
s = '';
if ~isempty(textNode)    
    s = char(textNode.getData);
end
end

