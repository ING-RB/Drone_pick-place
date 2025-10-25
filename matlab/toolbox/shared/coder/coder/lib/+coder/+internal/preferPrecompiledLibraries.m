function y = preferPrecompiledLibraries()
    %CODER.PREFERPRECOMPILEDLIBRARIES returns true of the MATLAB Code
    %generation configuration object setting, UsePrecompiledLibraries,
    %is set to 'Prefer' or if running in MATLAB.

    %   Copyright 2024 The MathWorks, Inc.

    %#codegen
    narginchk(0,0);
    if coder.target('MATLAB')
        y = true;
    else
        y = coder.internal.eml_option_eq('UsePrecompiledLibraries', 'Prefer');
    end
