%CODER.EXTERNALDEPENDENCY Define an interface to an external library
%
%   CODER.EXTERNALDEPENDENCY is an abstract class which defines the
%   interface methods for using an external library with MATLAB Coder.
%
%   The following methods must be implemented by classes which derive from
%   this base class. All of these methods are static.
%
%   getDescriptiveName(bldcfg) Given the build configuration specified by
%   the input 'bldcfg' parameter, returns the name to be associated with
%   the external dependency. The input 'bldcfg' parameter is an object of
%   class coder.BuildConfig. Used for usage and error reporting.
%
%   isSupportedContext(bldcfg) Given the build configuration specified by
%   the input 'bldcfg' parameter, determines if this external dependency is
%   supported. The input 'bldcfg' parameter is an object of class
%   coder.BuildConfig. The method should return 'true' if the external
%   dependency is supported in the given context; it should return 'false'
%   if the external dependency is not supported in the given context. If a
%   value of 'false' is returned, a generic error message will be reported
%   using the name returned by the 'getDescriptiveName' method. To report a
%   specific error message, throw an error message explaining why the
%   external dependency is not supported. It is highly recommended that
%   specific messages be thrown, rather than relying on the default
%   message.
%
%   updateBuildInfo(buildInfo,bldcfg) Given the build configuration
%   specified by the input 'bldcfg' parameter, update the RTW.BuildInfo
%   object, a handle to which is provided by the 'buildInfo' parameter. The
%   input 'bldcfg' parameter is an object of class coder.BuildConfig. This
%   method is called after code has been generated and the RTW.BuildInfo
%   object has been populated with the standard information. This method
%   should add to the RTW.BuildInfo object all information needed to
%   successfully link to the external library represented by the
%   ExternalDependency class.
%
%   See also coder.ceval, coder.cinclude, coder.BuildConfig, RTW.BuildInfo.

%   Copyright 2012-2019 The MathWorks, Inc.

classdef (HandleCompatible) ExternalDependency %#codegen
    methods (Access=public)
        function this = ExternalDependency
            coder.allowpcode('plain');
        end
    end
    methods (Abstract, Static)
        n = getDescriptiveName(bldcfg);
        
        b = isSupportedContext(bldcfg);
        
        updateBuildInfo(buildInfo, bldcfg);
    end
end
