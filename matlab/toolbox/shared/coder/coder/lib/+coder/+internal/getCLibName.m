function libraryName = getCLibName(libName)
    % MATLAB Code Generation Private Function

    % This function is used for retrieving library name 
    % depending on the target of code generation.
    % The input argument must be valid C library data-type or method name.

    % Note that this function always returns
    % C library name either in C-syntax (example: printf)
    % or in CPP-syntax (example: std::printf).

    % Please note that there is similar function named
    % coder.internal.getCHeaderName to retrieve C/CPP header name.

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

    % Map C library-name into corresponding CPP namespace library-name.
    % Note that all C libraries will be in std namespace when included via
    % <cFILE_NAME>(e.g. <cstdio>) syntax.
    % So it is not necessary to maintain any dictionary to map C-name into
    % CPP-name, moreover such a list will be too long. 
    % For example, one such list exist in
    % matlab/src/cgir_xform/dom_c/CReservedWords.cpp file.
    % However there are some specific C library-name (example: 'struct tm')
    % which needs to be mapped into CPP namesapce specifically (example: std::tm),
    % so we are maintaing such a limited map-table to lookup.

    ClibToCPPmap = struct(...
                         'struct_tm', 'std::tm', ...
                         'struct_timespec', 'std::timespec');

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
    if coder.target('C++') && ~coder.target('Sfun') % CPP codegen, but not in Simulation mode
        % At first look into map and then fall-back into std namespace.
        % Replace whitespaces with underscope since we stored C-name in
        % struct map-table after replacing whitespace with underscope.

        % Note: C library's method-name (such as printf, memset) won't have
        % whitespace. However some data-type such as 'struct tm' has
        % whitespace.

        libName = strrep(libName, ' ', '_');
        if isfield(ClibToCPPmap, libName)
            libraryName = ClibToCPPmap.(libName);
        else
            libraryName = ['std::' libName];
        end
    else % C codegen
        libraryName = libName; % example memset
    end
end
