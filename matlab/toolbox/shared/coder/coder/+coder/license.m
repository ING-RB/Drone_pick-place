function license(varargin)
%CODER.LICENSE performs license checkout at code generation time and at run time.
%
%   CODER.LICENSE('checkout', 'aToolboxLicense') checks out the MATLAB
%   toolbox license specified by aToolboxLicense at code generation time.
%   If you generate a MEX, this function also records that license in
%   generated MEX metadata so the MEX will also checkout the license
%   during MEX initialization.
%
%   Example:
%       coder.license('checkout','Communication_Toolbox');
%
%   CODER.LICENSE('checkout', 'aToolboxLicense or anotherToolboxLicense')
%   specifies a list of licenses to check, separated by OR. This form of
%   CODER.LICENSE call checks out a license at code generation time and at
%   MEX run time, as above, but the codegen and runtime checkouts independently
%   scan the list of licenses to discover if one of the specified licenses
%   is in use by the MATLAB session. If any license is already in use,
%   CODER.LICENSE uses the first license in the list which is in use. If no
%   license is in use, CODER.LICENSE checks out the first available license
%   in the list.
%
%   Example:
%       coder.license('checkout','Signal_Toolbox or Optimization_Toolbox');
%
%   CODER.LICENSE('checkout', 'aLicenseString', 'aMessageIdentifier')
%   uses the supplied message identifier instead of the default message.
%   The message must have one string hole, which displays aLicenseString.
%   aLicenseString might be a single toolbox license key, or a list of
%   license keys separated by OR.
%
%   Example:
%       coder.license('checkout','LTE_HDL_Toolbox', 'whdl:whdl:NoLicenseAvailable');
%
%   This is a code generation function. In MATLAB, CODER.LICENSE raises
%   an error, because it has no direct MATLAB replacement.
%
%   CODER.LICENSE must be a top-level expression. CODER.LICENSE does not
%   return a value indicating whether or not the license checkout
%   succeeded.
%
%   If the license checkout fails during code generation, the failure is
%   treated as a semantic error and code generation fails.
%
%   If the license checkout fails during MEX initialization, the MEX throws
%   a runtime error with the message id specified by the optional message
%   identifier, or the default EMLRT:runTime:MexFunctionNeedsLicense.
%
%   CODER.LICENSE('test', ...) is used to test the CODER.LICENSE command
%   and it performs no useful action.

%   Copyright 2022 The MathWorks, Inc.
coder.internal.assert(false, 'Coder:MATLAB:CoderLicenseNotUsableByMATLAB');
