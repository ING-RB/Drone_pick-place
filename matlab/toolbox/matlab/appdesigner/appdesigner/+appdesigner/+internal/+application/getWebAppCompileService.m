function service = getWebAppCompileService()
%GETWEBAPPCOMPILESERVICE function to return the ApplicationCompilerService.
%
%This is a separate standalone function to allow us the opportunity to
%differentiate between calls to compile for destop vs. web

% Copyright 2020 The MathWorks, Inc.
       service = com.mathworks.toolbox.compiler_mdwas.services.WebAppCompilerService;
end