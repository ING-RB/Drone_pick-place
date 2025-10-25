function options = createSolverOptions(solverName, varargin)
%

%CREATESOLVEROPTIONS Create a solver options object
%
%   OPTIONS = CREATESOLVEROPTIONS(SOLVERNAME, 'PARAM', VALUE, ...) creates
%   the specified solver options object. Any specified parameters are set
%   in the object.
%
%   See also OPTIMOPTIONS

%   Copyright 2012-2022 The MathWorks, Inc.

persistent optionsFactory

% Create the optionsFactory map
if isempty(optionsFactory)

    % Get meta-classes for all Optimization options
    allClasses = optim.internal.findSubClasses(...
        'optim.options', 'optim.options.SolverOptions');

    % Loop through each meta-class and extract the information for the
    % optionsFactory
    numClasses = length(allClasses);
    isGlobal = false(numClasses, 1);
    isMATLAB = false(numClasses, 1);
    solverNames = cell(numClasses, 1);
    optionConstructors = cell(numClasses, 1);
    for i = 1:numClasses
        thisClassName = allClasses(i).Name;
        
        % Extract the class name from the full package name and make it lower case.
        % Also, remove trailing "options" and insert into cell array
        solverNames{i} = lower(erase(extractAfter(thisClassName,'optim.options.'),'Options'));
        % Track the MATLAB solvers
        isMATLAB(i) = isMATLABsolver(solverNames{i});
        
        % Create a function handle to the constructor
        optionConstructors{i} = str2func(thisClassName);

        % Determine whether the options class requires the Global
        % Optimization Toolbox
        srcFile = which(thisClassName);
        isGlobal(i) = ~isempty(regexp(srcFile, 'globaloptim', 'once'));
    end
    
    % We check to see if there is an installation of Global Optimization
    % Toolbox here. Furthermore, we assume that these toolbox files will
    % not be removed between calls to this function.

    % Create map
    if optim.internal.utils.hasGlobalOptimizationToolbox
        idxAvailableSolvers = ~isMATLAB;
    else
        idxAvailableSolvers = ~(isGlobal | isMATLAB);
    end
    
    % There must be some available solvers to construct the map, otherwise
    % we get a bad error from Map.
    assert(any(idxAvailableSolvers),message('MATLAB:optimfun:options:createSolverOptions:NoSolversAvailable'));
    optionsFactory = containers.Map(solverNames(idxAvailableSolvers), optionConstructors(idxAvailableSolvers));

end

% Get creation function from factory
try
    optionsCreationFcn = optionsFactory(lower(solverName));
catch ME
    % handle unsupported solvers
    if isMATLABsolver(solverName)
        upperSolver = upper(solverName);
        error(message('MATLAB:optimfun:options:createSolverOptions:MatlabSolversUnsupported', ...
            upperSolver, upperSolver));
    elseif isGlobalSolver(solverName)
        error(message('MATLAB:license:NoFeature',solverName,'GADS_Toolbox'))
    else
        error(message('MATLAB:optimfun:options:createSolverOptions:InvalidSolver'));
    end
end

% Create the options
switch lower(solverName)
    case 'linprog'
        % Throw a more detailed error if a user tries to set old
        % option LargeScale.

        % Get the p-v pairs. Remove the first input if it is an options
        % object.
        pvPairs = varargin;
        if ~isempty(varargin) && isa(varargin{1},'optim.options.SolverOptions')
            pvPairs(1) = [];
        end

        % Loop through the parameter names and not the values.
        for i = 1:2:length(pvPairs)
            if ischar(pvPairs{i}) || (isstring(pvPairs{i}) && isscalar(pvPairs{i}))
                if strcmpi(pvPairs{i}, 'LargeScale')
                    error(message('MATLAB:optimfun:options:createSolverOptions:LargeScaleUnsupported'));
                end
            end
        end
end
% create options
options = optionsCreationFcn(varargin{:});

%--------------------------------------------------------------------------
function TF = isMATLABsolver(solver)

TF = any(strcmpi(solver, optim.options.OptionAliasStore.MATLABSolvers));


function TF = isGlobalSolver(solver)

TF = any(strcmpi(solver, optim.options.OptionAliasStore.AllGlobalSolvers));