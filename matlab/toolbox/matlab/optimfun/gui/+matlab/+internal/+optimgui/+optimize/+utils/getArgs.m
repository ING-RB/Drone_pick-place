function args = getArgs(fcnName,source)

% This function returns the arguments of a function file or local function as a cell array of char vectors
% If varargin is an argument, an empty cell is returned

% Copyright 2020 The MathWorks, Inc.

args = {};

if strcmp(source,'file')
    
    % Create mtree for source code.
    mtreeArgs = {fcnName,'-file'};
    
    % Trim off ".m" for later use
    [~,fcnName] = fileparts(fcnName);
elseif strcmp(source,'local')
    
    % Get handle to MLX document
    d = matlab.desktop.editor.getActive;
    
    % Grab code from MLX file
    mtreeArgs = {d.Text};
end

try
    Src = mtree(mtreeArgs{:});
catch
    
    % Error reading file - return
    return
end

% Search tree for the function of interest
fcnTree = mtfind(Src,'Fname.String',fcnName);

% Determine input-variable name.
InputsTree = Ins(fcnTree);

% If varargin is an argument or duplicate arguments exist, return empty cell
if ~isempty(InputsTree)
    args = InputsTree.List.strings;
    if any(strcmpi(args,'varargin')) || ...
           numel(unique(args)) < numel(args) 
        args = {};
    end
end
