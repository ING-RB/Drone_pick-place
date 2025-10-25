function probStruct = createProblemStruct(solverName,defaultSolver,useValues)
%

%CREATEPROBLEMSTRUCT Create problem structure for different solvers
%   Create problem structure for 'solverName'. If defaultSolver is [] then 'fmincon' is assumed to
%   be the default solver. The optional third argument is used to populate the problem structure
%   'probStruct' with the values from 'useValues'.
%
%   Private to OPTIMTOOL

%   Copyright 2005-2023 The MathWorks, Inc.

% Perform check for global optim toolbox
if optim.internal.utils.hasGlobalOptimizationToolbox
    enableAllSolvers = true;
else
    enableAllSolvers = false;
end

gadsSolvers = {'ga','patternsearch','gamultiobj','simulannealbnd','particleswarm','surrogateopt'};

% If called with one argument and the argument is a string
if nargin == 1 && nargout <= 1 && isequal(solverName,'solvers')
    probStruct = matlab.internal.optimfun.utils.createSolverStruct(enableAllSolvers);
    return;
end

if nargin < 3
    useValues = [];
end

if nargin < 2 || isempty(defaultSolver)
    defaultSolver = 'fmincon';
end

if ~enableAllSolvers && any(strcmpi(solverName,gadsSolvers))
    warning('MATLAB:createProblemStruct:invalidSolver',...
        getString(message('MATLAB:optimfun:createProblemStruct:invalidSolver', upper( solverName ), upper( defaultSolver ))));
    solverName = defaultSolver;
end
% The fields in the structure are in the same order as they are passed to
% the corresponding solver.
switch solverName
    case 'fmincon' %1
        probStruct = struct('objective',[],'x0',[], ...
            'Aineq',[],'bineq',[],'Aeq',[],'beq',[], ...
            'lb',[],'ub',[],'nonlcon',[]);
    case 'fminunc' %2
        probStruct = struct('objective',[],'x0',[]);
    case 'lsqnonlin' %3
        probStruct = struct('objective',[],'x0',[], ...
            'lb',[],'ub',[],'Aineq',[],'bineq',[], ...
            'Aeq',[],'beq',[],'nonlcon',[]);
    case 'lsqcurvefit' %4
        probStruct = struct('objective',[],'x0',[], ...
             'xdata',[],'ydata',[],'lb',[],'ub',[], ...
             'Aineq',[],'bineq',[],'Aeq',[],'beq',[],'nonlcon',[]);
    case 'linprog' %5
        probStruct = struct('f',[],'Aineq',[],'bineq',[], ...
            'Aeq',[],'beq',[],'lb',[],'ub',[],'x0',[]);
    case 'quadprog' %6
        probStruct = struct('H',[],'f',[],'Aineq',[], ...
            'bineq',[],'Aeq',[],'beq',[],'lb',[],'ub',[],'x0',[]);
    case 'fgoalattain' %7
        probStruct = struct('objective',[],'x0',[], ...
            'goal',[],'weight',[], ...
            'Aineq',[],'bineq',[],'Aeq',[],'beq',[], ...
            'lb',[],'ub',[],'nonlcon',[]);
    case 'fminimax' %8
        probStruct = struct('objective',[],'x0',[], ...
            'Aineq',[],'bineq',[],'Aeq',[],'beq',[], ...
            'lb',[],'ub',[],'nonlcon',[]);
    case 'fseminf' %9
        probStruct = struct('objective',[],'x0',[], ...
            'ntheta',[],'seminfcon',[], ...
            'Aineq',[],'bineq',[],'Aeq',[],'beq',[], ...
            'lb',[],'ub',[]);
    case 'fminsearch' %10
        probStruct = struct('objective',[],'x0',[]);
    case 'fzero' %11
        probStruct = struct('objective',[],'x0',[]);
    case 'fminbnd' %12
        probStruct = struct('objective',[],'x1',[],'x2',[]);
    case 'fsolve' %13
        probStruct = struct('objective',[],'x0',[]);
    case 'lsqlin' %14
        probStruct = struct('C',[],'d',[],'Aineq',[], ...
            'bineq',[],'Aeq',[],'beq',[],'lb',[],'ub',[],'x0',[]);
    case 'lsqnonneg' %15
        probStruct = struct('C',[],'d',[]);
    case 'ga' %16
        probStruct = struct('fitnessfcn',[],'nvars',[], ...
            'Aineq',[],'bineq',[],'Aeq',[],'beq',[], ...
            'lb',[],'ub',[],'nonlcon',[],'intcon',[],'rngstate',[]);
    case 'patternsearch' %17
        probStruct = struct('objective',[],'x0',[], ...
            'Aineq',[],'bineq',[],'Aeq',[],'beq',[], ...
            'lb',[],'ub',[],'nonlcon',[],'rngstate',[]);
    case 'simulannealbnd' %18
        probStruct = struct('objective',[],'x0',[], ...
            'lb',[],'ub',[],'rngstate',[]);
    case 'gamultiobj' %19
        probStruct = struct('fitnessfcn',[],'nvars',[], ...
            'Aineq',[],'bineq',[],'Aeq',[],'beq',[], ...
            'lb',[],'ub',[],'nonlcon',[],'intcon',[],'rngstate',[]);
    case {'particleswarm'} % 20
        probStruct = struct('objective',[],'nvars',[],'lb',[],'ub',[],'rngstate',[]);
    case 'intlinprog'
        probStruct = struct('f',[],'intcon',[],'Aineq',[],'bineq',[], ...
            'Aeq',[],'beq',[],'lb',[],'ub',[],'x0',[]);
    case {'surrogateopt'} % 20
        probStruct = struct('objective',[],'lb',[],'ub',[],'intcon',[], ... 
            'Aineq',[],'bineq',[],'Aeq',[],'beq',[],'rngstate',[]);
    case 'paretosearch' % 21
        probStruct = struct('objective',[],'nvars',[], ...
            'Aineq',[],'bineq',[],'Aeq',[],'beq',[], ...
            'lb',[],'ub',[],'nonlcon',[],'rngstate',[]);
    case 'coneprog' % 22
        probStruct = struct('f',[],'socConstraints',[],'Aineq',[],'bineq',[], ...
            'Aeq',[],'beq',[],'lb',[],'ub',[]);
    case 'all'
        probStruct = struct('objective',[],'x0',[],'f',[],'H',[], ...
            'lb',[],'ub',[],'nonlcon',[], 'x1',[],'x2',[], ...
            'Aineq',[],'bineq',[],'Aeq',[],'beq',[], ...
            'xdata',[],'ydata',[],'goal',[],'weight',[], ...
            'C',[],'d',[],'ntheta',[],'seminfcon',[], 'fastfcn',[]);
        if enableAllSolvers
            probStruct.nvars =[];
            probStruct.fitnessfcn = [];
            probStruct.rngstate = [];
            probStruct.intcon = [];
        end
        solverName = defaultSolver;
   otherwise
        error('MATLAB:createProblemStruct:UnrecognizedSolver',...
            getString(message('MATLAB:optimfun:createProblemStruct:UnrecognizedSolver')));
end
% Add the 'solver' field in the structure.
probStruct.solver = solverName;

% Copy the values from the struct 'useValues' to 'probStruct'.
if ~isempty(useValues)
    copyfields = fieldnames(probStruct);
    Index = ismember(copyfields,fieldnames(useValues));
    for i = 1:length(Index)
        if Index(i)
            probStruct.(copyfields{i}) = useValues.(copyfields{i});
        end
    end
end
