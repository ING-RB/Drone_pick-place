function varargout = evalinGlobalScope(model, exprToEval)
    %This function is for internal use only. It may be removed in the future.
    
    %EVALINGLOBALSCOPE Evaluate expression in global scope
    %   If the MODEL input is empty, the expression will always be evaluated in the
    %   base workspace. Otherwise, the expression will be passed along to the
    %   evalinGlobalScope_internal function.
    
    %   Copyright 2018-2024 The MathWorks, Inc.
    
    if isempty(model)
        % Always evaluate in base workspace
        [varargout{1:nargout}] = evalin('base', exprToEval);
    else
        % Pass expression to standard evalinGlobalScope function
        % The standard evalinGlobalScope function is replaced with
        % resolveInGlobalScope function in R2024a
        [varargout{1:nargout}] = Simulink.data.resolveInGlobal(model, exprToEval);
    end
end

