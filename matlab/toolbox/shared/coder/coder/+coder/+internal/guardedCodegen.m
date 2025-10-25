function varargout = guardedCodegen(varargin)
    
    isinstalled = coderapp.internal.Products.MatlabCoder.installed;
    if ~isinstalled
        error(message('Coder:FE:MATLABCoderInstallRequired'));
    end
    [varargout{1:nargout}] = codegen(varargin{:});
end
