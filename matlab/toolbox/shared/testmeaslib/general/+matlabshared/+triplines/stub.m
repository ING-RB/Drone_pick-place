function varargout = stub(spkgName, spkgBaseCode, pkgFnName, supportedPlatforms, varargin)
    %STUB    Default stub implementation for support package triplines
    %
    % Syntax:
    %    [varargout{1:nargout}] = matlabshared.triplines.stub(spkgName, spkgBaseCode, pkgFnName, supportedPlatforms, varargin);
    %
    % Parameters:
    %    spkgName           : Name of the support package
    %    spkgBaseCode       : The 'basecode' specified in your support_package_registry.xml
    %    pkgFnName          : The packaged function name (e.g. spkg.myFunction) to be called by the stub
    %    supportedPlatforms : The platforms supported by your support package (e.g. "PCWIN64", "GLNXA64", "MACI64")
    %    
    % Add a stub function (e.g.
    % toolbox/instrument/instrument/stubs/ividev.m) in a stubs folder that
    % is on the path of the parent toolbox. 
    %    * Include help in the stub function (MATLAB file).
    %    * Include tab completion in stubs/resources/functionSignatures.json
    %
    % This stub supports functions with variable number of inputs and
    % outputs.
    %
    % EXAMPLE:
    %     spkgName = "Instrument Control Toolbox Support Package for IVI and VXIplug&play Drivers";
    %     spkgBaseCode = "IVIANDVXIPNP";
    %     pkgFnName = "spkg." + mfilename;
    %     supportedPlatforms = "PCWIN64";
    %
    %     try
    %         [varargout{1:nargout}] = matlabshared.triplines.stub(spkgName, spkgBaseCode, pkgFnName, supportedPlatforms, varargin);
    %     catch e
    %         throwAsCaller(e);
    %     end
    %

    %   Copyright 2021 The MathWorks, Inc.
    if ischar(spkgName)
        spkgName = string(spkgName);
    end
    
    if ischar(spkgBaseCode)
        spkgBaseCode = string(spkgBaseCode);
    end
    
    if ischar(pkgFnName)
        pkgFnName = string(pkgFnName);
    end
    
    if ischar(supportedPlatforms)
        supportedPlatforms = string(supportedPlatforms);
    end
        
    validPlatforms = ["PCWIN64", "GLNXA64", "MACI64"];
    validateattributes(spkgName, {'string'}, {'scalartext', 'nonempty'});
    validateattributes(spkgBaseCode, {'string'}, {'scalartext', 'nonempty'});
    validateattributes(pkgFnName, {'string'}, {'scalartext', 'nonempty'});
    validatestring(supportedPlatforms, validPlatforms);

    fnNameSplit = split(pkgFnName, ["\", "."]);
    fnName = fnNameSplit(end);
    platform = string(computer());
    if ~any(strcmp(platform, supportedPlatforms))
        id = 'testmeaslib:Triplines:PlatformNotSupported';
        me = MException(id, getString(message(id, fnName, platform, supportedPlatforms)));
        throwAsCaller(me);
    end

    % Check if the support package has been installed
    w = which(pkgFnName);
    if isempty(w)
        id = 'testmeaslib:Triplines:SupportPackageNotInstalled';
        me = MException(id, getString(message(id, spkgName, spkgBaseCode)));
        throwAsCaller(me);
    end

    try
        inputs = varargin{1};
        varargout = cell(1,nargout(pkgFnName));
        if numel(inputs) == 0
            eval("[varargout{:}] = feval(@" + pkgFnName + ");");
        else
            eval("[varargout{:}] = feval(@" + pkgFnName + ", inputs{:});");
        end
    catch e
        throwAsCaller(e);
    end
end

% LocalWords:  spkg fn MACI ividev IVI Iplug scalartext basecode IVIANDVXIPNP
