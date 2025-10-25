function headerName = getCHeaderName(libHeader)
    % MATLAB Code Generation Private Function

    % This function is used for retrieving header name 
    % depending on the target of code generation.
    % The input argument must be a valid C header file name
    % without '.h' suffix.

    % Note that this function always returns
    % C header name either in C-syntax (example: <stdio.h>)
    % or in CPP-syntax (example: <cstdio>).

    % Please note that there is similar function named
    % coder.internal.getCLibName to retrieve C/CPP library name.

    % Example usage:
    % To define a C file-stream object, instead of using old style,
    % use new approach by making use of these coder.internal functions.
    % Old approach:
    %   fd = coder.opaquePtr('FILE', 'NULL', 'HeaderFile', '<stdio.h>');
    % Recommended new approach:
    %   cHeader = coder.internal.getCHeaderName('stdio');
    %   cDataType = coder.internal.getCLibName('FILE');
    %   fd = coder.opaquePtr(cDataType, 'NULL', 'HeaderFile', cHeader);

    % Copyright 2022-2023 The MathWorks, Inc.

    %#codegen

    % We are using same toolbox function for both standalone codegen
    % as well as for model simulation.
    % In standalone code generation mode, we want generated code
    % to be compliant with MISRA standard, however for simulation mode
    % the focus is not on MISRA standard compliant code generation.
    % For example, in JIT MEX based simulation, we are generating LLVMIR code
    % instead of C/CPP code.
    % This check is based on coder.target(), and ensures that we are applying
    % MISRA compliance rules only for standalone code generation mode.
    % This is required because some of targets such as 'Sfun'(simulation mode)
    % is not able to handle generated MISRA compliant C++/LLVMIR code
    % leading into unexpected behaviours.
    if coder.target('C++') && ~coder.target('Sfun') % CPP codegen, but not in simulation mode
        headerName = ['<c' libHeader '>']; % example <cstdio>
    else % C codegen
        headerName = ['<', libHeader, '.h>']; % example <stdio.h>
    end
end
