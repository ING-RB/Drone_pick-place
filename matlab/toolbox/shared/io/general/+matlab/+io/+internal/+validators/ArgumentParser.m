classdef ArgumentParser < handle & matlab.mixin.internal.Scalar
% Encapsulation of function interface that allows composition of functions
% NV pair sets are combined through concatination. This class provides
% the capability to partial/case-insensitve match names from multiple sets.
%
% fi = matlab.io.internal.validators.ArgumentParser(PARAMETERS,ALIASES)
%      PARAMETERS is a string array of parameter names accepted by the
%      function. ALIASES is optional, and must be of type 
%      matlab.io.internal.functions.ParameterAlias
%   
%  ArgumentParser Methods:
%
%  results = canonicalizeNames(obj,names)
%      returns a struct containing: 
%           CanonicalNames: the canonical names used by the function after partial
%                           matching, case-correction, and alias matching. 
%           NonMatched:     Names of parameters which weren't recognized at
%                           all. 
%           AmbiguousMatch: A struct array with fields:
%
%               idx:            The index of the original name which was
%                               ambiguous
%               names:          Canonical names of parameters which might
%                               have matched
%
% [paramStruct, otherArgs] = extractArgs(obj,...parameters...)
%      Returns parameters of the function as a struct whose field names are
%      the associated parameter names and field values are the parameter
%      values passed in. Arguments which did not match any of the parameter
%      names are returned as a cell array, otherArgs. The names of
%      parameters are expected to be canonicalized.
%
% [Args1,Args2,...,ArgsN,otherArgs] = splitArgs(ObjArray,...parameters...)
%      Splits the name-value pairs into the associated function interfaces
%      in ObjArray. ObjArray is an array of ArgumentParsers. The number
%      of output arguments must match the number of elements in ObjArray
%      plus one--for otherArgs. The i-th Args output is a struct with
%      parameter names from the i-th element of ObjArray as fieldnames. The
%      names of parameters in extractArgs are expected to be canonicalized.
%
%    Example, define two function interfaces and dispatch parsed results to
%             each function:
%    
%    % Create two function interfaces
%    import matlab.io.internal.validators.*
%    fi1 = ArgumentParser(["Param1" "PartialMatch"]);
%    fi2 = ArgumentParser(["Param2" "PartialMatchBreaks"]);
% 
%    % Composing function interfaces is achieved via concatination.
%    fi_combined = [fi1 fi2];
%
%    % Match the names against individual functions
%    res1 = fi1.canonicalizeNames(["Par" "Partial"]);
%    res1.PartialMatches
%
%    res2 = fi2.canonicalizeNames(["Par" "Partial"]);
%    res2.PartialMatches
%
%    % Now match against the combined list. 
%    % Notice the combined list cannot resolve "Partial" between
%    % "PartialMatch" and "PartialMatchBreaks"
%
%    resC = fi_combined.canonicalizeNames(["Par" "Partial"]);
%    resC.PartialMatches
% 
%    % Split the arguments into the associated functions
%    
%    [Args1,Args2,notMatched] = fi_combined.splitArgs("Param2",2,...
%                                                     "Param1",1,...
%                                                     "NotParam",0)
%
%    % These arguments could now be passed into functions as structs, or
%    % using utility functions, passed as nv-pairs.
%    func1(Args1);
%    Args2 = struct2args(Args2) % this is imported from the validators package above
%    func2('RequiredArg',Args2{:});
%    
% See Also: matlab.io.internal.validators.struct2args, 
%           matlab.io.internal.validators.validateNVPairs    

% Copyright 2018-2020 The MathWorks, Inc.

    properties (SetAccess='private')
        ParameterNames
        Aliases(1,:) matlab.io.internal.functions.ParameterAlias = matlab.io.internal.functions.ParameterAlias.empty(1,0);
    end
    
    methods
        function obj = ArgumentParser(names,aliases)
            obj.ParameterNames = names;
            names = sort(obj.ParameterNames);
            duplicates = names(1:end-1) == names(2:end);
            names(duplicates) = [];
            obj.ParameterNames = names;
            if nargin > 1 && ~isempty(aliases)
                obj.Aliases = aliases;
                if any(~any(names(:)==[aliases.CanonicalName]))
                    error(message('MATLAB:textio:textio:AliasNotInParameterSet'))
                end
            end
        end
                
        function [paramStruct, otherArgs] = extractArgs(obj,varargin)
        % Extracts any argments known by this interface, and sets the
        % others aside. Parameter names are expected to be canonicalized
        % already. (i.e. partial matching needs to have already been done.)
        inputNames = varargin(1:2:end)';
        [inputNames{:}] = convertStringsToChars(inputNames{:});
        inputNames = convertCharsToStrings(inputNames);
        allNames = obj.ParameterNames;
        
        % Does implicit expansion to find the matches
        matches = (inputNames(:) == allNames(:)');
        paramStruct = struct();
        for n = matches(:,any(matches,1))
            k = find(n,1,'last');
            paramStruct.(inputNames(k)) = varargin{2*k};
        end
        
        % None of the values matches the names
        nonMatches = ~any(matches,2);
        numArgs = nnz(nonMatches);
        % Rebuild the other args for non-matches items
        otherArgs = cell(1,numArgs);
        otherArgs(1:2:2*numArgs) = cellstr(inputNames(nonMatches));
        values = varargin(2:2:end)';
        otherArgs(2:2:2*numArgs) = values(nonMatches);
        end
        
        function results = canonicalizeNames(obj, names)
        % Used to match names from partial matches, and replace aliases
        % with the corrected canonical names
        names = convertCharsToStrings(names);
        results.CanonicalNames = names;
        allNames = obj.ParameterNames;

        % indices of the non-empty, non-missing elements
        nonZero = find(strlength(names) > 0);
        
        % Initialize the struct fields
        results.NonMatched = strings(0); 
        results.AmbiguousMatch = struct('idx',{},'names',{});
        
        for kk = nonZero
            names(kk) = obj.Aliases.getCanonicalName(names(kk));
            matches = matchPartial(allNames,names(kk));
            
            % If multiple matches were found, pick the exact match over a
            % different partial match
            if nnz(matches) > 1
                exactMatch = strcmpi(allNames,names(kk));
                if nnz(exactMatch) == 1
                    results.CanonicalNames(kk) = allNames(exactMatch);
                else
                    results.AmbiguousMatch(end+1) = struct('idx',kk,'names',allNames(matches)); %#ok<*AGROW>
                end   
            elseif nnz(matches) ~= 1
                results.NonMatched(end+1) = names(kk);
            else % one (at worst) partial match
                results.CanonicalNames(kk) = allNames(matches);
            end
        end
        end
                
        function [varargout] = splitArgs(obj,varargin)
        % This function splits all the arguments of the interfaces into
        % separate sets of NV Pairs.
        % e.g. for an interface combining three functions, f1, f2, f3:
        % [args1,args2,args3,extraArgs] = ifc.splitArgs(...)
        % 
        % if ~isempty(extraArgs), error('Unknown Argument'), end
        % f1(args1);
        % f2(args2);
        % f3(args3);
      
        nout = numel(obj)+1;
        nargoutchk(nout,nout);
        for i = 1:nout-1
            [varargout{i},varargin] = obj(i).extractArgs(varargin{:});
        end
        varargout{nout} = varargin;
        end
    end
    
    %% Setters for private properties
    methods 
        function set.ParameterNames(obj,names)
        names = convertCharsToStrings(names(:)');
        if ~isstring(names) || ~all(strlength(names) > 0)
            error(message('MATLAB:textio:textio:InvalidStringOrCellStringProperty','ParameterNames'))
        end
        obj.ParameterNames = names;
        end
    end 

end

function matches = matchPartial(allNames,name)
matches = startsWith(allNames,name,'IgnoreCase',true);
end
