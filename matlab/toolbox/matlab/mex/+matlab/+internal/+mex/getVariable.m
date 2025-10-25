function ret=getVariable(varargin)
%    FOR INTERNAL USE ONLY -- This function is intentionally undocumented
%    and is intended for use only with the scope of function in the MATLAB 
%    Engine APIs.  Its behavior may change, or the function itself may be 
%    removed in a future release.

% Copyright 2018 The MathWorks, Inc.

% GETVARIABLE returns a MATLAB variable from the base or global workspace.
    varname = varargin{1};
    %By default, it is base workspace.  Python Engine only supports base
    %workspace.
    workspaceType = 'base';
    if length(varargin) > 1
        workspaceType = varargin{2};
    end
    if strcmp(workspaceType, 'global')
        globalVarList = who('global');
        if ismember(varname, globalVarList)
            statement = ['global ' varname];
            %Rethrow the exception to generate MATLABExecutionException in C++ MEX
            try
                eval(statement);
            catch ex
                throw(ex)
            end
        else
            ME = MException('MATLAB:mex:CppMexGetVariableError', ...
            'Failed to get variable ''%s'' in ''%s'' workspace.',varname, workspaceType);
            throw(ME)
        end
		
        ret = eval(varname);
    else
            flag = evalin(workspaceType, ['exist(''' varname ''',''var'')']);
            if flag
	            ret = evalin(workspaceType, varname);
            else
                ME = MException('MATLAB:mex:CppMexGetVariableError', ...
				'Failed to get variable ''%s'' in ''%s'' workspace.',varname, workspaceType);
                throw(ME)
            end
    end

end
