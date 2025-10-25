classdef SolverTypeMap
    %SolverTypeMap data structure to map problem types to solvers
    %
    % SolverTypeMap constructs a data structure that serves as a lookup of
    % valid solvers given pairs of objective and constraint types.
    %
    % Access:
    % Once constructed, the SolverTypeMap instance can be accessed using
    % parentheses reference.
    %
    %   s = SolverTypeMap();
    %   s(objectiveType,constraintsType)
    %
    % where objective type is a character array of a valid objective type name
    % and constraintsType is cellstr of valid constraint type names. See below
    % for valid types.
    %
    % Objective Types must be one of the following:
    %     Unsure
    %     Linear
    %     Quadratic
    %     LeastSquares
    %     Nonlinear
    %     Nonsmooth
    %
    % Constraint Types must be a cellstr of one or more of the following:
    %     Unsure
    %     None
    %     LowerBounds
    %     UpperBounds
    %     LinearInequality
    %     LinearEquality
	%     SecondOrderCone
    %     NonlinearConstraintFcn
    %     IntegerConstraint
    %
    % See also matlab.internal.optimgui.optimize.OptimizeConstants, matlab.internal.optimgui.optimize.Optimize
    
    % Copyright 2020-2023 The MathWorks, Inc.
    
    % Design notes:
    % - It would be nicer to build the list on the fly. However, it would be
    % slower (not by a ton) and have about as much duplication across cases
    %
    % - To avoid duplication, one could build the lists from "pieces" existing
    % elsewhere (e.g. from descriptive data structures about each solver).
    % However, this would be very difficult since we also need to sort the
    % results in order of preference. How do we do that?
    
    properties(Constant)
        ObjectiveKeys = {'Unsure';
                        'Linear';
                        'Quadratic';
                        'LeastSquares';
                        'Nonlinear';
                        'Nonsmooth'};

        ObjectiveKeyIconNames = {'';
                                 'plotLinearWide';
                                 'plotQuadraticWide';
                                 'plotLeastSquaresWide';
                                 'plotNonlinearWide';
                                 'plotNonsmoothWide'};
        
        ConstraintKeys = {'Unsure';
                        'None';
                        'LowerBounds';
                        'UpperBounds';
                        'LinearInequality';
                        'LinearEquality';
                        'SecondOrderCone';
                        'NonlinearConstraintFcn';
                        'IntegerConstraint'};

        ConstraintKeyIconNames = {'';
                                 'constraintNone';
                                 'constraintLowerBounds';
                                 'constraintUpperBounds';
                                 'constraintLinearInequality';
                                 'constraintLinearEquality';
                                 'secondOrderConeConstraint';
                                 'constraintNonlinear';
                                 'constraintInteger'};
        
        MasterList      = matlab.internal.optimgui.optimize.solverbased.models.SolverTypeMap.buildMasterList();
        ObjectiveLists  = matlab.internal.optimgui.optimize.solverbased.models.SolverTypeMap.buildObjectiveLists();
        ConstraintLists = matlab.internal.optimgui.optimize.solverbased.models.SolverTypeMap.buildConstraintLists();
        
        UnlicensedOptim  = {'unlicensed_optim'};
        UnlicensedGlobal = {'unlicensed_global'};
        Nonexistent      = {'NA'};
    end
    
    % Instance members - these are "filtered" versions of the above
    % depending on the licenses available
    properties
        % License checks - at the first construction of one of these
        % objects (with the app), we'll check for what licenses are present
        HasOptim;
        HasGlobal;
        
        % Instance versions of the above
        masterList;
        objectiveLists;
        constraintLists;
    end
    
    methods
        function this = SolverTypeMap()
            this.HasOptim  = optim.internal.utils.hasOptimizationToolbox;
            this.HasGlobal = optim.internal.utils.hasGlobalOptimizationToolbox;
            
            % Initialize the instance lists using license filter
            this.masterList = this.licenseFilter(matlab.internal.optimgui.optimize.solverbased.models.SolverTypeMap.MasterList);
            this.objectiveLists = this.licenseFilter(matlab.internal.optimgui.optimize.solverbased.models.SolverTypeMap.ObjectiveLists);
            this.constraintLists = this.licenseFilter(matlab.internal.optimgui.optimize.solverbased.models.SolverTypeMap.ConstraintLists);
        end
        
        function varargout = subsref(this, s)
            % Make sure that subs is the parens only, otherwise forward
            % to builtin indexing
            
            if isscalar(s) && strcmp(s(1).type,'()')
                % Unpack keys from subs struct
                keys = s.subs;
                assert(numel(keys) == 2, ...
                    'matlab:internal:optimgui:optimize:models:SolverTypeMap:parenReference:InvalidNumKeys',...
                    'SolverTypeMap reference requires 2 keys to return a solver list');
                
                % Instead, always pass constraint keys in as a cell array
                multiConstraints = numel(keys{2}) > 1;
                %If numel of cell array is 1, extract char vector
                if numel(keys{2}) == 1
                    keys{2} = keys{2}{1};
                end
                
                % Start with constraints
                if ~multiConstraints && strcmp(keys{2},'Unsure')
                    if strcmp(keys{1},'Unsure')
                        % NOTE: this is never empty - just return
                        list = this.masterList;
                    else
                        list = this.objectiveLists.(keys{1});
                        if isempty(list) || all(strcmp(list,'lsqnonneg'))
                            % This is a license-related issue since there   
                            % is at least one solver somewhere for each
                            % objective between MATLAB & Optim.
                            % Pad the list with the only possible choices.
                            % Note: do not pad for Linear since none are really valid
                            if ~strcmp(keys{1},'Linear')
                                list = [list; {'fminsearch';'fminbnd'}];
                            else
                                list = this.UnlicensedOptim;
                            end
                        end
                    end
                else
                    % First, look up using license-filtered lists
                    objLists = this.objectiveLists;
                    constrsLists = this.constraintLists;
                    list = this.constraintLookup(keys,objLists,constrsLists,multiConstraints,this.HasOptim);
                    
                    % Check against license issues
                    if isempty(list)
                        % Now do lookup without license filters (using
                        % static lists) and compare
                        objLists = this.ObjectiveLists;
                        constrsLists = this.ConstraintLists;
                        list = this.constraintLookup(keys,objLists,constrsLists,multiConstraints,this.HasOptim);
                        list = this.findNeededLicense(list);
                    end
                end
                varargout{1} = list;
            else % More than 1 level indexing or non-paren indexing
                % Forward to builtin indexing
                [varargout{1:nargout}] = builtin('subsref',this,s);
            end % if - paren indexing only
        end
    end
    
    methods (Access = private)
        % Apply license-check and filter available choices based on it.
        function list = licenseFilter(this,list)
            % Check for multiple lists
            structOfLists = isstruct(list);
            % First check for Optim
            if ~this.HasOptim
                % Remove by finding the intersection with MATLAB solvers.
                % If optim is not available, then Global should not work
                % either, even if it's installed.
                solvers = this.matlabSolvers();
                if ~structOfLists
                    list = intersect(list,solvers(:,1),'stable');
                else
                    % Check all lists
                    keys = fieldnames(list);
                    for k = keys'
                        thisKey = k{1};
                        list.(thisKey) = intersect(list.(thisKey),solvers(:,1),'stable');
                    end
                end
            elseif ~this.HasGlobal
                % Remove Global solvers from the list
                solvers = this.globalSolvers();
                if ~structOfLists
                    list = setdiff(list,solvers(:,1),'stable');
                else
                    % Check all lists
                    keys = fieldnames(list);
                    for k = keys'
                        thisKey = k{1};
                        list.(thisKey) = setdiff(list.(thisKey),solvers(:,1),'stable');
                    end
                end
            end
        end

        function status = findNeededLicense(this,list)
        % Check the list and find which toolbox license is needed
            if ~isempty(list)
                status = this.UnlicensedGlobal;
                % Only need to check if we have neither toolbox ---
                % If we have MATLAB & Optim - must need global (default)
                if ~this.HasOptim
                   % Check which toolbox is needed.
                   % - we only need to check to see if an optim solver is
                   %   on the list. otherwise, return the (already set)
                   %   Global msg.
                   solvers = this.optimSolvers();
                   if any(contains(list,solvers(:,1)))
                       status = this.UnlicensedOptim;
                   end
                end
            else
                status = this.Nonexistent;
            end
        end
        
    end % Private helpers

    methods(Static)
        
        function list = constraintLookup(keys,objLists,constrsLists,multiConstraints,hasOptim)
        % Given a selection of constraints, determine the solver list
        
            import matlab.internal.optimgui.optimize.solverbased.models.SolverTypeMap
            if ~multiConstraints
                list = constrsLists.(keys{2});
            else
                list = SolverTypeMap.mergeConstraintLists(constrsLists,keys);
            end
            
            if ~strcmp(keys{1},'Unsure')
                % Both are set - use our "magic" optim knowledge to
                % narrow the list
                list = SolverTypeMap.lookupByConstraints(keys,list,objLists,hasOptim);
            end
        end        
        
        function list = mergeConstraintLists(constrsLists,keys)
        % Merge a set of lists of solvers - using set intersection
            constrs = keys{2};
            list = constrsLists.(constrs{1});
            for k = 2:numel(constrs)
                list = intersect(list, constrsLists.(constrs{k}), 'stable');
            end
        end
        
        function list = lookupByConstraints(keys,list,objLists,hasOptim)
        % Determine a 
            % Go case by case on the objective - "Unsure" is already handled
            objFilteredList = objLists.(keys{1});
            switch keys{1}
                case 'Linear'
                    % Simple intersect with 2 exceptions - none and nonlinear
                    hasNonlin = any(strcmp(keys{2},'NonlinearConstraintFcn'));
                    if strcmp(keys{2}, 'None')                       
                        % Return NA with this combination
                        list = matlab.internal.optimgui.optimize.solverbased.models.SolverTypeMap.Nonexistent;
                        
                    % When the constraint list contains "NonlinearConstraintFcn", the
                    % constraint list wins here since specialized linear
                    % solvers only permit certain constraints.
                    % Otherwise, take the overlap
                    elseif ~hasNonlin
                        hasInteger = any(strcmp(keys{2},'IntegerConstraint'));
                        if ~hasInteger
                            objFilteredList(strcmp(objFilteredList,'intlinprog')) = [];
                        end
                        if ~any(strcmp(keys{2},'SecondOrderCone')) 
                            objFilteredList(strcmp(objFilteredList,'coneprog')) = [];
                        elseif hasInteger  % Integer & SOC == bail
                            return
                        end                        
                        % Simple intersect
                        list = intersect(list, objFilteredList, 'stable');
                    end
                case {'Quadratic','LeastSquares'}
                    % Simple intersect with 2 exceptions - nonlinear &
                    % discrete
                    
                    % When the constraint list contains "NonlinearConstraintFcn", the
                    % constraint list wins here since specialized linear
                    % solvers only permit certain constraints.
                    % Otherwise, take the overlap
                    
                    % Split out discrete since we have to remove
                    % intlinprog
                    if any(strcmp(keys{2},'IntegerConstraint'))
                        list(strcmp(list,'intlinprog')) = [];
                    elseif any(strcmp(keys{2},'SecondOrderCone'))
                        list(strcmp(list,'coneprog')) = [];
                    elseif ~any(strcmp(keys{2},'NonlinearConstraintFcn'))
                        % Simple intersect
                        list = intersect(list, objFilteredList, 'stable');
                    end
                    
                    % Some extra handling for LeastSquares if optim toolbox
                    % solvers are available
                    if strcmp(keys{1}, 'LeastSquares') && hasOptim
                        if ~any(strcmp(keys{2}, 'IntegerConstraint'))
                            list = unique(['lsqnonlin'; 'lsqcurvefit'; list], 'stable');
                            if any(contains(keys{2}, 'Linear'))
                                list = unique([list; 'fmincon'], 'stable');
                            end
                        end
                    end
                case {'Nonlinear','Nonsmooth'}
                    % Simple intersect
                    list = intersect(list, objFilteredList, 'stable');
            end
        end
        
        function list = buildConstraintLists()
            list.IntegerConstraint = {'intlinprog';
                'surrogateopt';
                'gamultiobj';
                'ga'};
            
            list.NonlinearConstraintFcn = {'fmincon';
                'lsqnonlin';
                'lsqcurvefit';
                'patternsearch';
                'surrogateopt';
                'fgoalattain';
                'fminimax';
                'paretosearch';
                'gamultiobj';
                'ga'};
            
            list.SecondOrderCone = {'coneprog';
                'fmincon';
                'lsqnonlin';
                'lsqcurvefit';
                'patternsearch';
                'surrogateopt';
                'fgoalattain';
                'fminimax';
                'paretosearch';
                'gamultiobj';
                'ga'};
            
            list.LinearInequality = {'fmincon';
                'lsqnonlin';
                'lsqcurvefit';
                'intlinprog';
                'linprog';
                'quadprog';
                'coneprog';                
                'lsqlin';
                'patternsearch';
                'surrogateopt';
                'fgoalattain';
                'fminimax';
                'paretosearch';
                'gamultiobj';
                'ga'};
            
            list.LinearEquality = {'fmincon';
                'lsqnonlin';
                'lsqcurvefit';
                'intlinprog';
                'linprog';
                'quadprog';
                'coneprog';                
                'lsqlin';
                'patternsearch';
                'surrogateopt';
                'fgoalattain';
                'fminimax';
                'paretosearch';
                'gamultiobj';
                'ga'};
            
            list.LowerBounds = {'fmincon';
                'lsqnonlin';
                'lsqcurvefit';
                'linprog';
                'intlinprog';
                'quadprog';
                'coneprog';                
                'lsqlin';
                'patternsearch';
                'surrogateopt';
                'fgoalattain';
                'fminimax';
                'paretosearch';
                'gamultiobj';
                'lsqnonneg';
                'fminbnd';
                'particleswarm';
                'ga';
                'simulannealbnd'};
            
            list.UpperBounds = {'fmincon';
                'lsqnonlin';
                'lsqcurvefit';
                'linprog';
                'intlinprog';
                'quadprog';
                'coneprog';                
                'lsqlin';
                'patternsearch';
                'surrogateopt';
                'fgoalattain';
                'fminimax';
                'paretosearch';
                'gamultiobj';
                'fminbnd';
                'particleswarm';
                'ga';
                'simulannealbnd'};
            
            list.None = {'lsqnonlin';
                'lsqcurvefit';
                'fminunc';
                'fsolve';
                'quadprog';
                'lsqlin';
                'patternsearch';
                'paretosearch';
                'fminsearch';
                'gamultiobj';
                'particleswarm';
                'ga';
                'fzero';
                'simulannealbnd'};
        end
        
        function list = buildObjectiveLists()
            list.Nonsmooth = {'patternsearch';
                'surrogateopt';
                'fminsearch';
                'particleswarm';
                'paretosearch';
                'gamultiobj';
                'ga';
                'simulannealbnd';
                'fminbnd'};
            
            list.Nonlinear = {'fmincon';
                'fminunc';
                'fsolve';
                'patternsearch';
                'surrogateopt';
                'fminsearch';
                'paretosearch';
                'gamultiobj';
                'fgoalattain';
                'fminimax';
                'fminbnd';
                'particleswarm';
                'fzero';
                'ga';
                'simulannealbnd'};
            
            list.LeastSquares = {'lsqnonlin';
                'lsqcurvefit';
                'lsqlin';
                'lsqnonneg'};
            
            list.Quadratic = {'quadprog'};
            
            list.Linear = {'linprog';
                           'intlinprog';
                           'coneprog'};
        end
        
        function list = buildMasterList()
            import matlab.internal.optimgui.optimize.solverbased.models.SolverTypeMap
            list = [SolverTypeMap.matlabSolvers;
                    SolverTypeMap.optimSolvers;
                    SolverTypeMap.globalSolvers];
            % Sort by rank - and return solvers only
            list = sortrows(list,2);
            list = list(:,1);
        end
        
        function listAndRank = optimSolvers()
            listAndRank = { 'fmincon',      1;
                            'lsqnonlin',    2;
                            'lsqcurvefit',  3;
                            'fminunc',      4;
                            'fsolve',       5;
                            'intlinprog',   6;
                            'linprog',      7;
                            'quadprog',     8;
                            'coneprog',     9;
                            'lsqlin',       10;
                            'fgoalattain',  16;
                            'fminimax',     17};            
        end
        
        function listAndRank = globalSolvers()
            listAndRank = { 'patternsearch',11;
                            'surrogateopt', 12;
                            'paretosearch', 14;
                            'gamultiobj',   15;
                            'particleswarm',20;
                            'ga',           22;
                            'simulannealbnd',23};               
        end
        
        function listAndRank = matlabSolvers()
            listAndRank = { 'fminsearch',   13;
                            'lsqnonneg',    18;
                            'fminbnd',      19;
                            'fzero',        21};   
        end
        
        
    end % Static methods
end % class SolverTypeMap