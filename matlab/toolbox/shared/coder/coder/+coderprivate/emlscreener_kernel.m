function X = emlscreener_kernel(varargin)

%EMLSCREENER Analyze a function for Embedded MATLAB compliance

%   Copyright 2009-2023 The MathWorks, Inc.

% Process input arguments and construct empty EMLScreening object.
X = processArgs(varargin{:});

% Collect information about called functions.
X = collectInformation(X);

% Aggregate information for easier reporting.
X = postProcess(X);

end

function X = processArgs(filename,reportLocation,obfuscate)

assert(nargin>=1,'EML:Screener:MissingArguments','Missing Argument');
if nargin == 1
    reportLocation = 1;
end
if nargin <= 2
    obfuscate = 'no';
end

X = coderprivate.EMLScreening(filename,reportLocation, obfuscate);

end

function X = collectInformation(X)

path = which(X.pFilename);

if isempty(path)
    error('EML:Screener:FailedToFindInput','Input file "%s" not found.',X.pFilename);
end

M = coderprivate.MFileInfo('',path);
M = M.analyze();

% Maintain a worklist of MFileInfos
% Take if off the worklist.  Grab its list of Callees.
% See if they have already been analyzed.  If so, we are done.  Otherwise
% add them to the worklist
fcnMap = containers.Map();

    function b = analyzedFcn(path)
        b = fcnMap.isKey(path);
    end

    function addFcn(M)
        fcnMap(M.pPath) = M;
    end

addFcn(M);

W = cell(1,1000);
W{1} = M;
i = 1;
last = 2;
while i<last
    M = W{i};
    i = i + 1;
    
    callees = M.callees();
    caller = M.pName;
    for k = 1:numel(callees)
        ee = callees{k};
        resolved = which(ee,'in',caller); % Can I pass a full path here to which?
        if ~analyzedFcn(resolved)
            N = coderprivate.MFileInfo(ee,resolved);
            N = N.analyze();
            addFcn(N);
            W{last} = N;
            last = last + 1;
        end
    end
end

X.pFcnInfo = values(fcnMap);

end

function X = postProcess(X)
% Aggregate statistics once all called functions are known.

    function b = unsupportedEMLFilter(M)
        b = M.pIsShipping && ~M.pHasEMLSupport;
    end
    function b = supportedEMLFilter(M)
        b = M.pIsShipping && M.pHasEMLSupport;
    end
    function b = scriptFilter(M)
        b = M.pIsScript;
    end
    function b = MEXFilter(M)
        b = M.pIsMEXFile;
    end
    function b = unknownTypeFilter(M)
        b = ~M.pIsShipping && ~M.pIsMFile && ~M.pIsMEXFile;
    end
    function b = userFcnFilter(M)
        b = ~M.pIsShipping && M.pIsMFile;
        %         b = ~M.pIsShipping && ~M.pIsScript && M.pIsMFile;
    end
    function b = NeedsEMLPragma(M)
        b = ~M.pIsShipping && ~M.pHasEMLPragma;
    end
    function b = UsesClass(M)
        b = M.pUsesClass;
    end
    function b = UsesCellArray(M)
        b = M.pUsesCellArray;
    end

    function b = UsesFnHandle(M)
        b = M.pUsesFnHandle;
    end

    function b = UsesGlobal(M)
        b = M.pUsesGlobal;
    end

    function b = NestedFunctions(M)
        b = M.pNestedFunctions;
    end

    function S = applyFilter(f)
        mask = false(1,numel(X.pFcnInfo));
        for i = 1:numel(X.pFcnInfo)
            M = X.pFcnInfo{i};
            mask(i) = f(M);
        end
        S = X.pFcnInfo(mask);
        if ~isempty(S)
            SS = [S{:}];
            names = {SS(:).pName};
            [~,I] = unique(names);
            S = S(I);
        end
        
    end

X.pUserFcns = applyFilter(@userFcnFilter);
X.pUnsupportedEML = applyFilter(@unsupportedEMLFilter);
X.pSupportedEML = applyFilter(@supportedEMLFilter);
X.pScripts = applyFilter(@scriptFilter);
X.pMEXFile = applyFilter(@MEXFilter);
X.pUnknownFileType = applyFilter(@unknownTypeFilter);
X.pNeedsEMLPragma = applyFilter(@NeedsEMLPragma);
X.pUsesClass = applyFilter(@UsesClass);
X.pUsesFnHandle = applyFilter(@UsesFnHandle);
X.pUsesCellArray = applyFilter(@UsesCellArray);
X.pUsesGlobal = applyFilter(@UsesGlobal);
X.pNestedFunctions = applyFilter(@NestedFunctions);

% Number of lines
NrLines = 0;
for mm=1:numel(X.pFcnInfo)
    NrLines = NrLines + X.pFcnInfo{mm}.pNrLines;
end
X.pNrLines = NrLines;

% % Number of files
% NrFiles = 0;
% for mm=1:numel(X.pFcnInfo)
%     if ~X.pFcnInfo{mm}.pIsShipping && X.pFcnInfo{mm}.pIsMFile
%         NrFiles = NrFiles + 1;
%     end
% end
% X.pNrFiles = NrFiles;

% Add short description for every supported and unsupported function
ToolboxUsed = cell(1,0);
[X.pUnsupportedEML,ToolboxUsed] = AddInfo(X.pUnsupportedEML,ToolboxUsed);
[X.pSupportedEML,X.ToolboxUsed] = AddInfo(X.pSupportedEML,ToolboxUsed);

% X.pUnsupportedEML = AddInfo(X.pUnsupportedEML);
% X.pSupportedEML = AddInfo(X.pSupportedEML);

    function [x,ToolboxUsed] = AddInfo(x,ToolboxUsed)
        % Create list of toolbox/category to make sort easier
        ToolboxCatList = cell(1,numel(x));
        for ii=1:numel(x)
            [toolbox_name, oneline, category] = detect_toolbox(x{ii}.pName);
            
            % Add toolbox to list of toolboxes
            if ~isempty(toolbox_name)
                if ~ismember(toolbox_name,ToolboxUsed)
                    ToolboxUsed{end+1} = toolbox_name; %#ok<AGROW>
                end
            end
            
            x{ii}.pToolbox = toolbox_name;
            x{ii}.pCategory = sprintf('%s/%s', toolbox_name, category);
            x{ii}.pOneline = oneline;
            ToolboxCatList{ii} = x{ii}.pCategory;
            
            %             x{ii}.pName = sprintf('%s (%s/%s) - %s\n',...
            %                 x{ii}.pName, toolbox_name, category, oneline);
        end
        
        % Sort functions by toolbox & category
        [~, ind] = sort(ToolboxCatList);
        x = x(ind);
        
    end

% Get name and 1-line description for function
    function [toolbox_name, oneline, category] = detect_toolbox(word)
        
        toolbox_keyword = [filesep 'toolbox' filesep];
        toolbox_name = ''; oneline = ''; category = '';
        screen_directory = which(word);
        if ~isempty(screen_directory)
            % Look for '\toolbox\'
            if contains(screen_directory,toolbox_keyword)
                index_toolbox = strfind(screen_directory,toolbox_keyword);
                index_backslash = strfind(screen_directory,filesep);
                % Extract name between two '\' that follow \toolbox\
                index = find((index_backslash-index_toolbox(1))>0);
                if ~isempty(index) && ~isscalar(index)
                    toolbox_name = screen_directory(...
                        index_backslash(index(1))+1:index_backslash(index(2))-1);
                end
                
                % Extract name between two '\' that follow toolbox location
                if length(index) > 2
                    category = screen_directory(...
                        index_backslash(index(2))+1:index_backslash(index(3))-1);
                end
                
                
                % Get one line description
                oneline = get_description(word);
            end
        end
    end

    function oneline = get_description(word)
        % Extract one line description from the MATLAB help
        
        % Get the MATLAB help text for that function
        text = evalc(['help ' word]);
        % If help found for that function
        if ~isempty(text)
            % look for end of line character
            endoflines = regexp(text,'\n');
            % stop help at first end of line or take all if no end of line
            % However, some functions such as powerest start with "help
            % for" and actual help is on line 3
            if ~isempty(endoflines)
                oneline = text(1:endoflines(1)-1);
                if contains(oneline,'--- help for')
                    if length(endoflines) > 2
                        tmp = text(endoflines(2)+1:endoflines(3)-1);
                        if contains(tmp, upper(word))
                            oneline = tmp;
                        end
                    end
                end
            else
                oneline = text;
            end
        else
            oneline = '';
        end
    end

end

% LocalWords:  MFile Nr oneline
