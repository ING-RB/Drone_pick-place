function spmd_feval( varargin )
% SPMD_FEVAL - the basis of SPMD block execution
    
% Copyright 2008-2024 The MathWorks, Inc.
    import matlab.internal.capability.Capability

    persistent PCT_INSTALLED_AND_LICENSED
    if isempty(PCT_INSTALLED_AND_LICENSED)
        % NOTE - spmd always calls into PCT so it is valid to checkout a PCT
        % license here.
        PCT_INSTALLED_AND_LICENSED = matlab.internal.parallel.isPCTInstalled && ...
            matlab.internal.parallel.isPCTLicensed;
        % Ensure this function doesn't show up in error stacks / debugger.
        if Capability.isSupported(Capability.Debugging)
            matlab.lang.internal.maskFoldersFromStack(string(which(mfilename)));
        end
    end

    try
        if PCT_INSTALLED_AND_LICENSED
            spmdlang.spmd_feval_impl( varargin{:} );
        else
            error(message('MATLAB:spmd:NoPCT'));
        end
    catch err
        throwAsCaller(err); 
    end
end
