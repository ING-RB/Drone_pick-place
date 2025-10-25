function out = runtimeLoad(varargin)
%#codegen

%   Copyright 2020 The MathWorks, Inc.

if coder.target('MATLAB')
    out = load(varargin{:});
else
    coder.internal.assert(coder.internal.isConst(varargin), 'Coder:builtins:Explicit',...
        'all inputs to runtime load must be constant');
    [structInfo, fname] = coder.const(@feval, 'coder.internal.runtimeLoadCompiletimePrep',...
        coder.internal.get_eml_option('CodegenBuildContext'), varargin{:});

    coder.updateBuildInfo('addNonBuildFiles', fname);%is the full path the right choice here?
    coder.const(structInfo);
    fid = fopen(fname);
    coder.internal.assert(fid~=-1, 'Coder:toolbox:CoderReadCouldNotOpen');
    fileCloser = onCleanup(@()(fclose(fid)));
    throwErrorsFlag = true;
    errorHandler = coder.internal.RuntimeLoadErrorHandler(throwErrorsFlag);
    out = coder.internal.runtimeLoadImpl(fid, structInfo, errorHandler);
    
    
    %FIXME: add checksum to make sure data is what we expected / the right
    %length
    
    %FIXME: add runtimeLoad version information to data files
end

end


