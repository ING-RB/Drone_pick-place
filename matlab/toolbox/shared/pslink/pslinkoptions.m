function opts = pslinkoptions(arg)
%PSLINKOPTIONS  Create/alter Polyspace options object.
%
%   OPTS = PSLINKOPTIONS(CDR) creates a Polyspace options
%   object OPTS for the specified coder, which contains default values
%   for each option. The argument CDR can be 'ec' for the options specific
%   to Embedded Coder or 'tl' for the options specific to TargetLink.
%
%   OPTS = PSLINKOPTIONS(MODEL) returns the options object associated with
%   the Simulink model MODEL.
%
%   OPTS = PSLINKOPTIONS(SFCN) returns the options object associated with
%   the S-function SFCN.
%   S-function support and the associated options are available only when
%   installed on R2016a or later versions.
%
%
%   OPTIONS:
%
%   VerificationMode [{'CodeProver'} | 'BugFinder']
%   Specify which Polyspace product to use on the generated code:
%   'CodeProver' - Run a verification with Polyspace Code Prover.
%   'BugFinder' - Run an analysis with Polyspace Bug Finder.
%
%   ResultDir - {'C:\PolySpace_Results\results_$ModelName$'} specifies the
%   folder where Polyspace writes its results. This can be either
%   an absolute path or a path relative to the current folder. The
%   text $ModelName$ is replaced with the name of the original model.
%
%   AddSuffixToResultDir - [{false} | true] causes Polyspace
%   to modify output results folder by appending a unique number instead of
%   overwriting an existing folder.
%
%   EnableAdditionalFileList - [{false} | true] Specify whether additional
%   files should be verified. Additional files should be specified in the
%   AdditionalFileList option
%
%   AdditionlFileList - {0x1 cell} Specify the list of additional files to
%   be verified.
%
%   ModelRefVerifDepth - [{'Current model only'} | '1' | '2' | '3' | 'All']
%   Maximum depth of referenced model to be verified. This setting is used
%   by Polyspace for Embedded Coder only.
%
%   ModelRefByModelRefVerif - [{false} | true] Verify all model/referenced
%   model hierarchies in the same code verification or independently, one at
%   a time. This setting is used by Polyspace for Embedded Coder
%   only.
%
%   ModelRefDesignMinMaxVerif - [{'None'} | 'Check' | 'CheckAndAssume']
%   Verify that design min/max value specifications on inputs and
%   outputs of model references are respected.
%
%   InputRangeMode - [{'DesignMinMax'} | 'FullRange'] causes Polyspace
%   to use input range defined in workspace/block or treat inputs as
%   full-range values.
%
%   ParamRangeMode - ['DesignMinMax' | {'None'}] causes Polyspace
%   to use value of parameters specified in code or range defined in
%   workspace/block.
%
%   OutputRangeMode - ['DesignMinMax' | {'None'}] Apply assertions to
%   outputs, based on range defined in workspace/block.
%
%   AutoStubLUT - [false | {true}] verify the model without analyzing the
%   Lookup Tables code, or analyze all code. 
%
%   OpenProjectManager - [{false} | true]
%   Open Polyspace Job Monitor or the Polyspace interface to monitor your
%   analysis and review the results.
%
%   VerificationSettings - [{'PrjConfig'} | 'PrjConfigAndMisraAGC' | 'PrjConfigAndMisra' | 'MisraAGC' | 'Misra' | 'PrjConfigAndMisraC2012' | 'MisraC2012']
%   Specify checking of coding rules for verification:
%   'PrjConfig' - Inherit all options from project configuration and run complete verification.
%   'PrjConfigAndMisraAGC' -  Inherit all options from project configuration, enable MISRA AC AGC rule checking, and run complete verification.
%   'PrjConfigAndMisra' -  Inherit all options from project configuration, enable MISRA rule checking, and run complete verification.
%   'MisraAGC' - Enable MISRA AC AGC rule checking, and run compilation phase only.
%   'Misra' -  Enable MISRA rule checking, and run compilation phase only.
%   'PrjConfigAndMisraC2012' -  Inherit all options from project configuration, enable MISRA C 2012 rule checking, and run complete verification.
%   'MisraC2012' - Enable MISRA C 2012 rule checking, and run compilation phase only.
%   This setting is used by Polyspace for C code only
%
%   CxxVerificationSettings - [{'PrjConfig'} | 'PrjConfigAndMisraCxx' | 'PrjConfigAndJSF' | 'MisraCxx' | 'JSF']
%   Specify checking of coding rules for verification:
%   'PrjConfig' - Inherit all options from project configuration and run complete verification.
%   'PrjConfigAndMisraCxx' -  Inherit all options from project configuration, enable MISRA C++ rule checking, and run complete verification.
%   'PrjConfigAndJSF' -  Inherit all options from project configuration, enable JSF C++ rule checking, and run complete verification.
%   'MisraCxx' - Enable MISRA C++ rule checking, and run compilation phase only.
%   'JSF' -  Enable JSF C++ rule checking, and run compilation phase only.
%   This setting is used by Polyspace for C++ code only
%
%   CheckConfigBeforeAnalysis - ['Off' | {'OnWarn'} | 'OnHalt']
%   Select the level of check configuration while running the verification
%   'Off' - Check only errors
%   'OnWarn' - Halt on errors, display a message on warnings
%   'OnHalt' - Halt on errors and warnings
%
%   EnablePrjConfigFile - [{false} | true]
%   Enable the use of a Polyspace configuration file with the current model.
%   Use with PrjConfigFile option.
%
%   PrjConfigFile - [{''}| Full path to a Polyspace project file]
%   Associate a Polyspace configuration file with the current model.
%
%   VerifAllSFcnInstances - [false |{true}]
%   true - Verify all instances of the S-function pointed to by SFCN
%   false - Verify only the S-function instance pointed to by SFCN
%   This setting is used by Polyspace only for S-Function analysis.
%
%
%   See also PSLINKRUN, POLYSPACEPACKNGO, PSLINKRUNCROSSRELEASE.

%
% Copyright 2011-2022 The MathWorks, Inc.
%

narginchk(1, 1);

% Check for Simulink to be installed before using this function
simulinkVersion = ver('Simulink');
if ~isempty(simulinkVersion)
    arg = convertStringsToChars(arg);
    opts = pslink.Options(arg);
else
    error('pslink:simulinkNotAvailable', DAStudio.message('polyspace:gui:pslink:simulinkNotAvailable', mfilename))
end

% LocalWords:  Polyspace CDR ec tl Spooler Verif PSLINKRUN Prj AGC
