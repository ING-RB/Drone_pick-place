function [status,cmdOut] = build(srcFile, importLibPath, sourceFiles , includePath, outputDir, definedMacros, undefinedMacros, userCompilerFlags, userLinkerFlags, verbose, buildExecutable)
%BUILD Build an interface library
%   BUILD(IMPORTLIBPATH, INCLUDEPATH, OUTPUTDIR, PKGNAME)
%   Generates an interface library by linking against user's import
%   library.
%
%   SRCFILE          -- Specifies full path to the source file. Specified as a 
%                       character vector or a string.
%                    
%   IMPORTLIBPATH    -- A cellstr containing the complete path to the user's import library.
%                       
%   SOURCEFILES      -- A cellstr containing the list of .CPP files contains definitions required by SRCFILE
%                       that needs to be compiled and linked with SRCFILE
%
%   INCLUDEPATH      -- A cellstr containing the complete path of the directories
%                       to include during compilation.
%
%   OUTPUTDIR        -- Specifies the location for generating the interface library.
%                       This location also contains the source .CPP file used to
%                       generate the interface library. Specified as a
%                       character vector or a string.
%
%   MACROS           -- String array of defined macros for building.
%
%   UNDEFINEDMACROS  -- String array of undefined macros for building.
%
%   BUILDEXECUTABLE  -- Determines whether an executable or a library needs to
%                       be generated. Specified as a logical.
%
%   USERCOMPILERFLAGS  -- String add additional compiler flags to build the
%                         interface library and the supporting sourcefiles.
%
%   USERLINKERFLAGS    -- String add additional linker flags to build the
%                         interface library and the supporting sourcefiles.
%
%   VERBOSE            -- Boolean to show compiler and linker commands in
%                         the command window.
%
%
%   BUILD uses the selected C++ MEX compiler to build a
%   library or an executable based on the ISEXECUTABLE flag. 

%   Copyright 2018-2023 The MathWorks, Inc.

% Check if inputs are string
if(isstring(outputDir))
    outputDir = outputDir.char();
end

% check if buildExecutable is logical
if(~islogical(buildExecutable))
    err('Expected logical');
end
 
% Assuming that the source file provided is full path
[~,srcFileName,~] = fileparts(srcFile); 
dataFileName = [regexprep(srcFileName, 'Interface$', 'Data') '.xml'];

% Get Compiler Information
compilerConfig = mex.getCompilerConfigurations('C++', 'Selected');
arch = computer('arch');

% Display an error if there is no compiler found
isCompilerInstalled(compilerConfig, arch);


% Get the information from Compiler Configuration Object for 
details           = compilerConfig.Details;
compiler          = details.CompilerExecutable;
linker            = details.LinkerExecutable;
compFlags         = fixesc(details.CompilerFlags);
linkFlags         = fixesc(details.LinkerFlags);
compOptimFlags    = fixesc(details.OptimizationFlags);
linkOptimFlags    = fixesc(details.LinkerOptimizationFlags);

space           = ' ';
sourceFilesObj  = [];
dllNames        = {};

if(strcmp(arch, 'win64'))
    
    % Set Environment. This is required only for Windows Compilers (MSVC and MinGW)
    systemDetails  = details.SystemDetails;
    restoreMatlab  = protectEnvAddition('matlab', matlabroot);
    restorePath    = protectEnvAddition('path', systemDetails.SystemPath);
    restoreInclude = protectEnvAddition('include', systemDetails.IncludePath);
    restoreLib     = protectEnvAddition('lib', systemDetails.LibraryPath);
    
end
cmdFilesList = "";
if(buildExecutable)
    
    outputFlag  = '';
    objectFlag  = '';
    compileFlag = '';
    outputObj   = ''; %#ok<*NASGU>
    outputFile  = '';
    
    if(strcmp(arch, 'win64'))
        outputObj  = ['"' outputDir, filesep, srcFileName, '.obj', '"'];
        outputFile = ['"' outputDir, filesep, srcFileName, '.exe', '"'];
        if(strcmp(compilerConfig.Manufacturer, 'Microsoft')||...
            strcmp(compilerConfig.Manufacturer, 'Intel')) % For MSVC and Intel compilers
            outputFlag  = '/Fe';
            objectFlag  = '/Fo';
            compileFlag = '/c';
        elseif (strcmp(compilerConfig.Manufacturer, 'GNU')) % For MinGW g++
            outputFlag  = '-static -o';
            objectFlag  = '-o';
            compileFlag = '-c';
        end
    else
        outputObj   = ['"' outputDir, filesep, srcFileName, '.o', '"'];
        outputFile  = ['"' outputDir, filesep, srcFileName, '"'];
        outputFlag  = '-o';
        objectFlag  = '-o';
        compileFlag = '-c';
    end
    srcFile = ['"'  srcFile '"'];
    compExe = [compiler, space, compileFlag, space, compFlags, space, compOptimFlags, space, srcFile, space, objectFlag, outputObj];
    [status, ~] = system(compExe);
    if(status == 0)
        if strcmp(arch,'maca64')
            % For maca64 environment compiled source file needs to be
            % linked with object file using linker flag '-arch arm64'
            macaEnv = '-arch arm64';
            linkExe = [compiler, space, macaEnv, space, outputObj, space, outputFlag, outputFile];
        else
            linkExe = [compiler, space, outputObj, space, outputFlag, outputFile];
        end
        
        [status, ~] = system(linkExe);
        if(status ~=0)
         disp('Failed to generate executable');
        end
    end

else % Building library
    buildLog = "";
    if(~ismissing(userCompilerFlags))
        userCompilerFlags = char(userCompilerFlags);
    else
        userCompilerFlags = '';
    end
    if(~ismissing(userLinkerFlags))
        userLinkerFlags = char(userLinkerFlags);
    else
        userLinkerFlags = '';
    end
    % Add path to include MatlabDataArray.hpp to includePath
    includePath{end+1} = fullfile(matlabroot, 'extern', 'include');   
    % Add path to libMatlabDataArray to importLibPath.
    if (strcmp(arch, 'glnxa64'))
        importLibPath{end+1} = fullfile(matlabroot, 'extern', 'bin', arch, 'libMatlabDataArray.so');
    elseif(strcmp(arch,'win64'))
        if (strcmp(compilerConfig.Manufacturer, 'Microsoft') ||...
            strcmp(compilerConfig.Manufacturer, 'Intel'))
            importLibPath{end+1} = fullfile(matlabroot,'extern','lib',arch,'microsoft','libMatlabDataArray.lib');
        elseif (strcmp(compilerConfig.Manufacturer, 'GNU'))
            importLibPath{end+1} = fullfile(matlabroot, 'extern', 'lib', arch, 'mingw64', 'libMatlabDataArray.lib');
        end
    elseif ismac
        importLibPath{end+1} = fullfile(matlabroot, 'extern', 'bin', arch, 'libMatlabDataArray.dylib');
    end
    includeDirs = setIncludeDirs(includePath);
    compileOnlyFlag = '';
    compileOutput   = '';
    linkType        = '';
    linkOutput      = '';
    finalOutput     = '';
    finalObj        = '';
    sourceCompiledObj  = [];
    microsoftLibrariesAddedWithDll = false;
    microsoftDllExistsinLibraries = false;

    if(strcmp(arch, 'win64'))
        
        interfaceBinary = [srcFileName, '.dll'];
        finalOutput  = ['"', outputDir, filesep, interfaceBinary, '"'];
        finalObj     = ['"', outputDir, filesep, srcFileName, '.obj', '"'];
        for i = 1:length(sourceFiles)
            if ~isempty(sourceFiles{i})
                if ~strcmp(sourceFiles{i}(1), '"') % Create separate .obj file for each source file
                    [~,sourceFileName,~] = fileparts(sourceFiles{i});
                    sourceFilesObj{i} = [outputDir, filesep, sourceFileName,'.obj'];
                end
            end
        end
        
        % Check for DLL's and matched ".lib" files in Libraries option
        if strcmp(compilerConfig.Manufacturer, 'Microsoft')
            for i = 1:length(importLibPath)
                [~,filename,ext] = fileparts(importLibPath{i});
                if strcmpi(ext,'.dll') && ~microsoftDllExistsinLibraries
                    microsoftDllExistsinLibraries = true;
                else
                    if ~microsoftLibrariesAddedWithDll && strcmpi(ext,'.lib') ...
                            && ~strcmp(filename,'libMatlabDataArray') && microsoftDllExistsinLibraries
                        nameMatched = compareLibNameWithDll(filename,importLibPath);
                        if nameMatched
                            microsoftLibrariesAddedWithDll = true;
                        end
                    end
                end
            end
        end
        if(strcmp(compilerConfig.Manufacturer, 'Microsoft')||...
           strcmp(compilerConfig.Manufacturer, 'Intel')) % For MSVC and Intel compilers
            
            compileOnlyFlag  = ' /c ';
            compileOutput    = ' /Fo';
            linkType         = '';
            linkOutput       = '/OUT:';
            cLanguageFlag    = ''; %no additional flags required to compile .c files as C files for Microsoft / Intel compilers
            
            importLibraryPath = [];
            for i = 1:length(importLibPath)
                if ~isempty(importLibPath{i}) % For header-only libraries this will be empty.
                    if(~strcmp(importLibPath{i}(1), '"')) % Check if path is enclosed within double quotes
                        importLibraryPath = [importLibraryPath '"' importLibPath{i} '"' ' ']; %#ok<*AGROW>
                    end
                end
            end
            definedMacros = char(strjoin("/D" + definedMacros));
            undefinedMacros = char(strjoin("/U" + undefinedMacros));
        elseif(strcmp(compilerConfig.Manufacturer, 'GNU')) % For MinGW g++
            
            compileOnlyFlag  = ' -c ';
            compileOutput    = ' -o ';
            linkType         = '-static';
            linkOutput       = ' -o ';
            cLanguageFlag    = ' -xc ';
            
            importLibraryPath  = setLinkLibPath(importLibPath, arch);
             definedMacros = char(strjoin("-D" + definedMacros));
             undefinedMacros = char(strjoin("-U" + undefinedMacros));
        end
        
    elseif(strcmp(arch, 'glnxa64')) % For Linux g++
        
        interfaceBinary = [srcFileName, '.so'];
        finalOutput = ['"', outputDir, filesep, interfaceBinary, '"'];
        finalObj    = ['"', outputDir, filesep, srcFileName, '.o', '"'];
        
        compileOnlyFlag  = ' -c ';
        compileOutput    = ' -o ';
        linkType         = '';
        linkOutput       = ' -o ';
        cLanguageFlag    = ' -xc ';
        
        importLibraryPath  = setLinkLibPath(importLibPath, arch);
        definedMacros = char(strjoin("-D" + definedMacros));
        undefinedMacros = char(strjoin("-U" + undefinedMacros));
        for i = 1:length(sourceFiles)
            if ~isempty(sourceFiles{i})
                if ~strcmp(sourceFiles{i}(1), '"')
                    [~,sourceFileName,~] = fileparts(sourceFiles{i});
                    sourceFilesObj{i} = [outputDir, filesep, sourceFileName,'.so'];
                end
            end
        end
    elseif ismac % For Mac OSX Xcode Clang++
        
        interfaceBinary = [srcFileName, '.dylib'];
        finalOutput    = ['"', outputDir, filesep, interfaceBinary, '"'];
        finalObj       = ['"', outputDir, filesep, srcFileName, '.o', '"'];
        
        compileOnlyFlag  = ' -c ';
        compileOutput    = ' -o ';
        linkType         = ' ';
        linkOutput       = ' -o ';
        cLanguageFlag    = ' -xc ';
        importLibraryPath = [];
        for i = 1:length(importLibPath)
            if ~isempty(importLibPath{i}) % For header-only libraries this will be empty.
              if(~strcmp(importLibPath{i}(1), '"'))
                    importLibraryPath = [importLibraryPath '"' importLibPath{i} '"' ' '];
              end
            end
        end
        definedMacros = char(strjoin("-D" + definedMacros));
        undefinedMacros = char(strjoin("-U" + undefinedMacros));
        for i = 1:length(sourceFiles)
            if ~isempty(sourceFiles{i})
                if ~strcmp(sourceFiles{i}(1), '"')
                    [~,sourceFileName,~] = fileparts(sourceFiles{i});
                    sourceFilesObj{i} = [outputDir, filesep, sourceFileName,'.o'];
                end
            end
        end
    end
    srcFile = ['"'  srcFile '"'];
    compCmd = [compiler, compileOnlyFlag, compFlags, space, compOptimFlags, space,...
               definedMacros, space, undefinedMacros, space, includeDirs, space, userCompilerFlags, space...
               srcFile, compileOutput, finalObj];
    [status, cmdOut, cmdFilesList] = executionHelper(compCmd, srcFile, cmdFilesList);
    buildLog = appendBuildLog(status, cmdOut, compCmd, buildLog);
    if status~= 0
        % check for Missing header guards error in InterfaceGeneration
        % files
        [missingHeaderGuard, cmdOut] = checkRedefinitionError(compilerConfig.Manufacturer, cmdOut, true);
        if ~missingHeaderGuard
            % Enabling bigobj for Visual Studio Compiler if sections exceed object
            % file format limit
            if (strcmp(arch, 'win64') && (strcmp(compilerConfig.Manufacturer, 'Microsoft')))
                if (contains(cmdOut,'C1128'))
                    bigobj = '/bigobj';
                    compCmd = [compCmd,space,bigobj];
                    disp(message('MATLAB:CPP:EnablingBigobjFlag').getString);
                    [status, cmdOut, cmdFilesList] = executionHelper(compCmd, srcFile, cmdFilesList);
                    buildLog = appendBuildLog(status, cmdOut, compCmd, buildLog);
                end
            end
        end
    end

    % Compile Source Files to create object fies
    if (~isempty(sourceFiles) && (status == 0))
        for index = 1:length(sourceFiles)
            if (status == 0)
                sourceCompCmd = '';
                [~,~,ext] = fileparts(sourceFiles{index});
                if ~strcmp(ext,'.c')
                    sourceCompCmd = [compiler, compileOnlyFlag, compFlags, space, compOptimFlags, space,...
                                    definedMacros, space, undefinedMacros, space,  userCompilerFlags, space, includeDirs, space,...
                                    '"', sourceFiles{index}, '"', space, compileOutput, '"', sourceFilesObj{index},'"'];
                else
                   compPlatFlags = '';
                   if strcmp(arch,'maca64')
                       % For maca64 environment ".c" source file's needs to be
                       % compiled with the flag '-arch arm64'
                       compPlatFlags = '-arch arm64';
                   end
                   sourceCompCmd =  [compiler, compileOnlyFlag, space, cLanguageFlag, space, compOptimFlags, space,...
                                    compPlatFlags, space, definedMacros, space, undefinedMacros, space,  userCompilerFlags, space, includeDirs, space,...
                                    '"', sourceFiles{index}, '"', space, compileOutput, '"', sourceFilesObj{index},'"'];
                end
                [status, cmdOut, cmdFilesList] = executionHelper(sourceCompCmd, sourceFilesObj{index}, cmdFilesList);
                buildLog = appendBuildLog(status, cmdOut, sourceCompCmd, buildLog);
                if status ~= 0 % check for redefinition compiler error
                    [~, cmdOut] = checkRedefinitionError(compilerConfig.Manufacturer, cmdOut, false);
                else
                    sourceCompiledObj   = [sourceCompiledObj '"' sourceFilesObj{index} '"' ' ']; % Enclose each compiled source file with in double quotes
                end
            end
        end
    end
    dependentLibs = strings;
    for libs = 1:length(importLibPath)-1 % skipping MATLAB Data Array library
        if ~isempty(importLibPath{libs})
            [~,libName,ext] = fileparts(importLibPath{libs});
            dependentLibs(libs) = [libName ext];
        end
    end

    % create bundle to embed into the interface binary
    % This bundle contains the metadata to be embedded into the
    % interface library
    if(status == 0)
        [status, cmdOut, additionalLinkerFalgs] = createBundle(dataFileName, interfaceBinary, outputDir, arch, dependentLibs);
    end

    if(status == 0)
        % Look for the libraries dependencies relative to the location of the calling library
        % on Mac and Linux OS.
        if ismac
            rpath = '-Wl,-rpath,@loader_path/';
        elseif isunix
                % On linux, '\' is needed to specify $ORIGIN.
                rpath = '-Wl,-rpath,\$ORIGIN';
        else
            rpath = '';
        end

        % check the bitness of the user provided library file
        libFile32Bit  = is32BitLibraryFile(importLibPath, arch, compilerConfig.Manufacturer, compiler, outputDir);
        if ~isempty(libFile32Bit)
            delAdditionalFiles(outputDir, srcFileName, dataFileName, buildExecutable, sourceFilesObj, '');
            error(message('MATLAB:CPP:InvalidLibraryFileNot64Bit',libFile32Bit));
        end

        % If DLL files exists in Libraries then extract ".lib" from DLL
        % files
        if microsoftDllExistsinLibraries
            % If ".lib" files found for provided DLL's then create the
            % interface DLL by linking all the ".lib" files
            if microsoftLibrariesAddedWithDll
                importLibraryPath = extractLibFromImportLib(importLibPath);
                linkCmd = [linker, space, linkFlags, space, linkType, space, finalObj, space, sourceCompiledObj, space,...
                        importLibraryPath, space, rpath, linkOptimFlags, space, userLinkerFlags, space, linkOutput, finalOutput, space, additionalLinkerFalgs];
                [status, cmdOut, cmdFilesList] = executionHelper(linkCmd, finalOutput, cmdFilesList);
                buildLog = appendBuildLog(status, cmdOut, linkCmd, buildLog);
                if status ~= 0
                    microsoftLibrariesAddedWithDll = false;
                    importLibPath = removeFailedLibs(importLibPath);
                end
            end
            % linking failed or no ".lib" files found for the provided DLL
            % files
            if ~microsoftLibrariesAddedWithDll
                linkingFailed = false; %flag to display message to the user
                if status ~= 0
                    linkingFailed = true;
                end
                % Generate ".lib" files for all the provided DLL files
                [importLibraryPath,dllNames, invalidDllFile] = generateLibraries(importLibPath, outputDir, linkingFailed);
                % Failed to add export symbol in DLL file will generate an error
                if ~isempty(invalidDllFile)
                    % Delete the temporarily created files
                    delAdditionalFiles(outputDir, srcFileName, dataFileName, buildExecutable, sourceFilesObj, dllNames, cmdFilesList);
                    error(message('MATLAB:CPP:InvalidDLLFile',invalidDllFile));
                else
                    linkCmd = [linker, space, linkFlags, space, linkType, space, finalObj, space, sourceCompiledObj, space,...
                         importLibraryPath, space, rpath, linkOptimFlags, space, userLinkerFlags, space, linkOutput, finalOutput, space, additionalLinkerFalgs ];
                    [status, cmdOut, cmdFilesList] = executionHelper(linkCmd, finalOutput, cmdFilesList);
                    buildLog = appendBuildLog(status, cmdOut, linkCmd, buildLog);
                end
            end
        else
            linkCmd = [linker, space, linkFlags, space, linkType, space, finalObj, space, sourceCompiledObj, space,...
                importLibraryPath, space, rpath, space, linkOptimFlags, space, userLinkerFlags, space, linkOutput, finalOutput, space, additionalLinkerFalgs];
            [status, cmdOut, cmdFilesList] = executionHelper(linkCmd, finalOutput, cmdFilesList);
            buildLog = appendBuildLog(status, cmdOut, linkCmd, buildLog);            
        end
        if(status ~= 0)
            % Checks multiple definition error
            if (strcmp(compilerConfig.Manufacturer, 'Microsoft'))
                if (contains(cmdOut,'LNK2005'))
                   cmdOut = [cmdOut, message('MATLAB:CPP:MultipleRedefinitionError').getString];
                elseif (contains(cmdOut,'LNK2019'))
                    cmdOut = [cmdOut, message('MATLAB:CPP:UnresolvedExternalsymbols').getString];
                end
            elseif (strcmp(compilerConfig.Manufacturer, 'GNU'))
                if (contains(cmdOut,'multiple definition'))
                    cmdOut = [cmdOut, message('MATLAB:CPP:MultipleRedefinitionError').getString];
                elseif (contains(cmdOut,'undefined reference'))
                    cmdOut = [cmdOut, message('MATLAB:CPP:UnresolvedExternalsymbols').getString];
                end
            elseif (strcmp(compilerConfig.Manufacturer, 'Apple'))
                if (contains(cmdOut,'duplicate symbol'))
                    cmdOut = [cmdOut, message('MATLAB:CPP:MultipleRedefinitionError').getString];
                elseif (contains(cmdOut,'Undefined symbols'))
                    cmdOut = [cmdOut, message('MATLAB:CPP:UnresolvedExternalsymbols').getString];
                end
            end
        end
    end
end
if(verbose)
    disp(message('MATLAB:CPP:CppInterfaceBuildLog').getString())
    disp(buildLog);
    disp("---")
end
% Delete artifacts
delAdditionalFiles(outputDir, srcFileName, dataFileName, buildExecutable, sourceFilesObj, dllNames, cmdFilesList);
end

function [status, cmdOut, additionalLinkerFlags] = createBundle(dataFileName, interfaceBinary, outputDir, arch, libs)
% This function creates a resource bundle and then add it to the interface file using the 
% usResourceCompiler
%
%   DATAFILENAME     -- BIN formatted xml file that contains data for the library interface
%   INTERFACEBINARY  -- Interface library
%   OUTPUTDIR        -- The directory in which the interface library exists
%   ARCH             -- Architecture
%   LIBS             -- User provided dependent libraries

    cc = mex.getCompilerConfigurations("C++", "Selected");
    ismingw = contains(cc.ShortName, "mingw", IgnoreCase=true);
    prevOrigDir = cd(outputDir);
    finishup = onCleanup(@()(cd(prevOrigDir)));
    currentDir = pwd;
    space = " ";
    additionalLinkerFlags = " ";
    % create bundle manifest
    symbolicName = ['clib.' extractBefore(dataFileName, 'Data.xml')];
    manifestFile = 'manifest.json';
    if (libs ~= "")
        libs = '["' + strjoin(libs,'","') + '"]';
    else
        libs = '[]';
    end
    fid = fopen(manifestFile, 'w');
    str = [ '{\n' ...
    '  "bundle.symbolic_name" : "' symbolicName '",\n'...
    '  "MATLAB.definition" : "' dataFileName '",\n'... 
    '  "MATLAB.clibapi" : 1,\n'...
    '  "mw" : {\n'...
    '  \t"clib" : {\n' ...
    '  \t\t"definition" : "' dataFileName '",\n'...
    '  \t\t"format" : "BIN",\n'...
    '  \t\t"clibapi" : 3,\n'...
    '  \t\t"libraries" :' char(libs) '\n' ...
    '  \t\t}\n' ...
    '  \t}\n' ...
    '}\n'
    ];
    fprintf(fid, str);
    fclose(fid);
    
    % call resource compiler
    resourceCompLoc = ['"' fullfile(matlabroot, 'bin', arch, 'usResourceCompiler3') '"'];
    srcFileName = extractBefore(interfaceBinary, 'Interface.');
    outputFileName = [srcFileName '.zip'];
    bundleOutputZipFile = fullfile(currentDir, outputFileName);
    quotes= """";
    % Create the bundle containing the meta-data that needs to be embedded to the interface library
    bundleCmd = [ resourceCompLoc ' --manifest-add ' manifestFile ' --bundle-name matlabdata'  '  --res-add ' dataFileName ' --out-file ' char(quotes) bundleOutputZipFile char(quotes)];
    [status, cmdOut] = system(bundleCmd);

    %Get the additional linker flags to embed the meta-data bundle into the
    %library
    rcfile = fullfile(currentDir, srcFileName+"meta_rc.rc");
    resfile = fullfile(currentDir, srcFileName+"meta_res.res");
    if(status==0)
        if ispc && ~ismingw
            %If selected compiler is VS or intel compiler, create the
            %resource file
            [status, cmdOut] = createWindowsResourceFile(rcfile, resfile, bundleOutputZipFile);
        end
    end
    additionalLinkerFlags = char(getAdditionalLinkerFlags(bundleOutputZipFile, resfile, ismingw));

end

% Create the resource file. 
% This function is applicable only on Win64 and for VS and Intel compilers
% only.
function [status, cmdOut] = createWindowsResourceFile(rcfile, resfile, bundleOutputZipFile)
    outdir = char(pwd);
    if(any(int32(pwd)>127))
        % if the outDir is a nonAscii characters, rc does not work well
        % with non-ascii characters. To workaround the limitation, create a
        % temp-directory MATLAB's tempdir and run the rc command in this
        % temporary directory.
        [~,pkgName,~] = fileparts(outdir);
        newOutDir = string(tempdir) + filesep + pkgName;
        if(isfolder(newOutDir))
            rmdir(newOutDir,'s');
        end
        mkdir(newOutDir);
        origDir = cd(newOutDir);
        cdBack = onCleanup(@()cd(origDir));
        copyfile(bundleOutputZipFile, pwd);
        [~,x, extn] = fileparts(bundleOutputZipFile);
        newBundleFile= fullfile(pwd,[x extn] );
        [status, cmdOut] = createWindowsResourceFile(rcfile, resfile, newBundleFile);
    else
        quotes = """";
        space = " ";
        escapebundleOutputZipFile = replace(bundleOutputZipFile, "\", "\\\\");
        fid = fopen(rcfile, 'w');
        cleanup = onCleanup(@()fclose(fid));
        str = ...
            "#define US_RESOURCE 300 " + newline + ...
            "US_RESOURCES US_RESOURCE " + quotes + escapebundleOutputZipFile + quotes + newline ;
        fprintf(fid, str);

        % rc.exe is the resource-compiler part of the windows SDK.
        % All machines with VS must have windows SDK installed
        % rc.exe will also be avaialble.
        rccmd = "rc /fo " + quotes + resfile + quotes + space + quotes + rcfile + quotes;
        [status, cmdOut] = system(rccmd);
    end
end

% Get additional linker flags based on the bundle zip file and the
% resource file(win64, VS, intel compilers)
function additionalLinkerFlags = getAdditionalLinkerFlags(bundleOutputZipFile, resFile, ismingw)
    space = " ";
    quotes = """";
    additionalLinkerFlags = "";
    if ismac
        additionalLinkerFlags = "-sectcreate __TEXT us_resources" + space + quotes + bundleOutputZipFile + quotes ;
    elseif isunix || ismingw 
        % The linker falgs are the same for Linux platform and
        % for MinGW compiler on win64
        additionalLinkerFlags = "-Wl,--format=binary -Wl," + quotes +bundleOutputZipFile + quotes + space + "-Wl,--format=default" + space;
        % Add -z noexecstack on linux only
        if isunix
            additionalLinkerFlags = additionalLinkerFlags + "-Wl,-z,noexecstack" + space;
        end
    else
        additionalLinkerFlags = quotes + resFile + quotes;
    end
end

% This function returns the final include path string appended with the 
% include flag
function includeDirs = setIncludeDirs(includePath)

includeDirs = [];
includeFlag = '-I';

if (iscellstr(includePath)) %#ok<ISCLSTR>
    includeDirs = cellfun(@(x) [includeFlag,'"',x,'"'], includePath, 'UniformOutput', false);
    includeDirs = strjoin(includeDirs);
end
end

% Checks multiple definition error
function [reDefinitionErr, errorLogs] = checkRedefinitionError(compilerConfig, errorLogs, isFailureInInterfaceGenFile)
    reDefinitionErr = false;
    if (strcmp(compilerConfig, 'Microsoft'))
        fileName = fileNamesInErrorForMicrosoft(errorLogs);
        if isFailureInInterfaceGenFile && contains(errorLogs,'C2011') %C2011 - multiple redefinition error
            reDefinitionErr = true;
            errorLogs = [errorLogs, message('MATLAB:CPP:MissingHeaderGuard',fileName).getString];
        elseif (~isFailureInInterfaceGenFile && (contains(errorLogs,'C2011') || contains(errorLogs,'C2084'))) % C2084- redefining same symbol
            reDefinitionErr = true;
            errorLogs = [errorLogs, message('MATLAB:CPP:RedefinitionInSourceFiles',fileName).getString];
        end
    elseif (strcmp(compilerConfig, 'Intel'))
        if (contains(errorLogs,'redeclaration of'))
            fileName = fileNamesInErrorForIntel(errorLogs);
            if isFailureInInterfaceGenFile
                reDefinitionErr = true;
                errorLogs = [errorLogs, message('MATLAB:CPP:MissingHeaderGuard',fileName).getString];
            else
                reDefinitionErr = true;
                errorLogs = [errorLogs, message('MATLAB:CPP:RedefinitionInSourceFiles',fileName).getString];
            end
        end
    elseif (strcmp(compilerConfig, 'GNU') || strcmp(compilerConfig, 'Apple'))
        if (contains(errorLogs,'redefinition of'))
            fileName = fileNamesInErrorForLinuxMac(errorLogs);
            if isFailureInInterfaceGenFile
                reDefinitionErr = true;
                errorLogs = [errorLogs, message('MATLAB:CPP:MissingHeaderGuard',fileName).getString];
            else
                reDefinitionErr = true;
                errorLogs = [errorLogs, message('MATLAB:CPP:RedefinitionInSourceFiles',fileName).getString];
            end
        end
    end
end

function linkLibPath = setLinkLibPath(importLibPath, arch)
linkLibPath = [];
for i =  1: length(importLibPath)
    if ~isempty(char(importLibPath{i}))
        [pathstr,name,ext] = fileparts(importLibPath{i});
        if ~(strcmp(ext, ".a"))
            if isempty(pathstr)
                pathstr ='.';
            end
            if(strcmp(arch, 'glnxa64'))
                nameExt = [name, ext];
                idx = strfind(nameExt, '.so');
                res = nameExt(4:idx-1); % Get the name lib<NAME>.so
                name = ['-l', res];
            elseif(strcmp(arch, 'win64'))
                nameExt = [name, ext];
                idx = strfind(nameExt, '.lib');
                res = nameExt(1:idx-1);
                name = ['-l', res];
            end
             linkLibPath = [ linkLibPath, ' ' , '-L"', pathstr, '" ',name];
        else
            %.a files are passed as additional input argument and not with
            % '-lname -Lpath convention
            
            linkLibPath = [linkLibPath ' ' '"' importLibPath{i} '"'];
        end

       
    end
end
end

% This function returns the list of class names that will throw the
% redefinition error in VisualStudio Compiler
function files = fileNamesInErrorForMicrosoft(cmdOut)
 files = '';
 splitError = splitlines(cmdOut);
 for i = 1:length(splitError)
      if contains(splitError{i},'C2011') || contains(splitError{i},'C2084')
          headerFile = extractBefore(splitError{i},"(");
          [~,fileName,ext] = fileparts(headerFile);
          if isempty(files)
              files = [fileName ext];
          else
              if ~contains(files,[fileName ext])
                files =  [fileName ext ', ' files];
              end
          end
      end
  end
end

% This function returns the list of class names that will throw the
% redefinition error in Intel Compiler
function files = fileNamesInErrorForIntel(cmdOut)
 files = '';
 splitError = splitlines(cmdOut);
 for i = 1:length(splitError)
      if contains(splitError{i},'redeclaration of')
          headerFile = extractBefore(splitError{i},"(");
          [~,fileName,ext] = fileparts(headerFile);
          if isempty(files)
              files = [fileName ext];
          else
              if ~contains(files,[fileName ext])
                files =  [fileName ext ', ' files];
              end
          end
      end
  end
end

% This function returns the list of class names that will throw the
% redefinition error in Linux and Mac
function files = fileNamesInErrorForLinuxMac(cmdOut)
  files = '';
  splitError = splitlines(cmdOut);
  for i = 1:length(splitError)
      if contains(splitError{i},'redefinition of')
          headerFile = extractBefore(splitError{i},"error");
          [~,fileName,ext] = fileparts(headerFile);
          fullfile = [fileName extractBefore(ext,":")];
          if isempty(files)
             files = fullfile;
          else
              if ~contains(files,fullfile)
                 files =  [fullfile ', ' files];
              end
          end
      end
  end
end

% This function extracts all the ".lib" files from Libraries
function importLibraryPath = extractLibFromImportLib(importLibPath)
  importLibraryPath = [];
  for i = 1:length(importLibPath)
      [~,~,ext] = fileparts(importLibPath{i});
      if ~strcmpi(ext,'.dll')
          importLibraryPath = [importLibraryPath '"' importLibPath{i} '"' ' '];
      end
  end
end

% This function will remove all the '.lib' files that matches the DLL names
function libPathWithDLLs = removeFailedLibs(importLibPath)
   dllNames = {};
   libPathWithDLLs = {};
   % Get the names of all the provided DLL files
   for index = 1:length(importLibPath)
       [~,filename,ext] = fileparts(importLibPath{index});
       if strcmpi(ext,'.dll')
           dllNames{end+1} = [filename ext];
       end
   end
   % copy all the Dll files and ".lib" files (that doesn't match DLL name)
   for index = 1:length(importLibPath)
       [~,filename,ext] = fileparts(importLibPath{index});
       if strcmpi(ext,'.lib')
           if strcmpi(dllNames, [filename '.dll']) == 0
               libPathWithDLLs{end+1} = importLibPath{index};
           end
       else
           libPathWithDLLs{end+1} = importLibPath{index};
       end
   end
end

% This function checks if the ".lib" files match the provided DLL files
function nameMatched = compareLibNameWithDll(libFileName, importLibPath)
    nameMatched = false;
    for i = 1:length(importLibPath)
        [~,filename,ext] = fileparts(importLibPath{i});
        if strcmpi(ext,'.dll') && strcmpi(libFileName,filename)
            nameMatched = true;
            break;
        end
    end
end

% This function extract each DLL file and pass to next block to generate
% lib file
function [importLibraryPathWithDll,dllNames, invalidDllFile] = generateLibraries(importLibPath, outputDir, linkingFailed)
    generatedLib = {};
    dllNames = {};
    importLibraryPathWithDll = [];
    % Iterate through all the Libraries and generate libraries only for the
    % DLL files
    for i = 1:length(importLibPath)
        [~,filename,ext] = fileparts(importLibPath{i});
        if strcmpi(ext,'.dll')
            % If linking of the found ".lib" files failed then send message to
            % the user
            if linkingFailed
                disp(message('MATLAB:CPP:CreatingLibFromDLL',[filename ext]).getString);
            end
            [libFromDLL,invalidDllFile] = generateDEFFile(importLibPath{i},outputDir);
            if ~isempty(invalidDllFile)
                % Generate Missing exports error if only one DLL file is
                % provided
                if length(importLibPath) == 2
                    return;
                end
                invalidDllFile = '';
            else
                generatedLib{end+1}  = libFromDLL;
                dllNames{end+1} = filename;
            end
        else
            % copies the ".lib" files
            generatedLib{end+1} = importLibPath{i};
        end
    end
    for index = 1:length(generatedLib)
        importLibraryPathWithDll = [importLibraryPathWithDll '"' generatedLib{index} '"' ' '];
    end
end

% Generate the DEF file
function [libFromDLL,invalidDllFile] = generateDEFFile(dllFile,outputDir)
   link    = 'link';
   dump    = '/dump';
   exports = '/EXPORTS';
   output  = '/out:';
   space   = ' ';
   libFromDLL = '';
   defFileTxt = [outputDir, filesep, 'defFile', '.txt'];
   defFile = ['"' defFileTxt '"' ' '];
   dllFileWithQuotes = ['"' dllFile '"'];
   % This will not throw any error, if DLL is invalid then
   % it will generate an empty DEF file
   defFileCmd = [link, space, dump, space, exports, space, dllFileWithQuotes, space, output, defFile];
   [~,~] = system(defFileCmd);
   [~,dllFileName,~] = fileparts(dllFile);
   [libFromDLL,invalidDllFile] = generateLibFromDLL(defFile,outputDir,dllFileName);
   % Delete the temporarily created DEF file
   if (exist(defFileTxt,'file') ~= 0)
       delete(defFileTxt);
   end
end

% Using the DEF file generate the ".lib" file for the DLL
function [libFromDLL, invalidDllFile] = generateLibFromDLL(defFile,outputDir,dllFileName)
    export     = 'EXPORTS';
    lib        = 'LIB';
    outDir     = 'out:';
    machine    = 'machine:x64';
    definition ='def:';
    space      = ' ';
    backSlash  = '/';
    writeToFile= false;
    libFromDLL = '';
    invalidDllFile = '';
    library = 'LIBRARY';
    library = [library, space, upper(dllFileName)];
    exportedSymbols = clibgen.internal.getSymbolsFromDEFFile(defFile);
    if isempty(exportedSymbols)
        invalidDllFile = [dllFileName '.dll'];
        return;
    end
    % create a temporary file to copy symbol signatures from DEF
    % file
    cppConstructFileTxt = [outputDir, filesep, 'CPPConstructs', '.txt'];
    cppConstructsFileId = fopen(cppConstructFileTxt,'w');
    fprintf(cppConstructsFileId,'%s\n',library);
    fprintf(cppConstructsFileId,'%s\n',export);
    fprintf(cppConstructsFileId,'%s\n',exportedSymbols);
    fclose(cppConstructsFileId);
    libFromDLL = [outputDir, filesep, dllFileName, '.lib'];
    cppConstructFile = ['"' cppConstructFileTxt '"' ' '];
    libFromDLL = ['"' libFromDLL '"' ' '];
    libCmd = [lib, space, backSlash, definition, cppConstructFile, space, backSlash, outDir, ...
        libFromDLL, space, backSlash, machine];
    [~,~] = system(libCmd);
    % Delete the temporarily created file that has function signaturess
    if (exist(cppConstructFileTxt,'file') ~= 0)
         delete(cppConstructFileTxt);
    end
    if ~isempty(libFromDLL)
         libFromDLL = strrep(libFromDLL,'"','');
    end
end

% Function to check if it is 32-bit library file
function libraryFile32Bit = is32BitLibraryFile(libraryFiles, arch, compConfigManufacturer, compiler, outputDir)
    libraryFile32Bit = '';
    space = ' ';
    for lib = 1:length(libraryFiles) - 1 % skipping MATLAB Data Array library
        if isempty(libraryFiles{lib})
            continue;
        end
        libFile = ['"' libraryFiles{lib} '"'];
        if ispc
            if strcmp(compConfigManufacturer, 'Microsoft') % Microsoft Visual Studio
                if is32BitWindowsLibFile(libFile,outputDir)
                    libraryFile32Bit = libFile;
                end
            elseif strcmp(compConfigManufacturer, 'GNU') % MinGW
                mingwComp = compiler;
                objDump = replace(mingwComp,'g++','objdump');
                fileCmd = [objDump,space,'-f',space,libFile];
                [status,output] = system(fileCmd);
                if status ~= 0 % If status fails then skip checking bitness
                    return;
                end
                if ~contains(output,'i386:x86-64') % For 64-bit libraries, architecture is i386:x86-64
                    libraryFile32Bit = libFile;
                end
            end
        else
            x = 'file'; % file cmd tells if .so or .dylib file is 32-bit or 64-bit
            fileCmd = [ x, space, libFile ];
            [status,output] = system(fileCmd);
            if status ~= 0 % If status fails then skip checking bitness
                return;
            end
            if strcmp(arch, 'glnxa64')
                is32Bit = strtrim(string(extractBetween(output,"ELF","LSB")));
                if strcmp(is32Bit,"32-bit")
                    libraryFile32Bit = libFile;
                end
            elseif ismac
                if ~contains(output,"64-bit")
                    libraryFile32Bit = libFile;
                end
            end
        end
    end
end

% Function that checks whether provided Windows library fle is 32bit or 64 bit
function is32Bit = is32BitWindowsLibFile(libFile,outputDir)
    is32Bit = false;
    link = 'link';
    dump = '/dump';
    headers = '/headers';
    space      = ' ';
    outDir     = '/out:';
    % Create temproray file to extract header info
    headerInfoFile = [outputDir, filesep, 'headerFile', '.txt'];
    headerInfoFile = ['"' headerInfoFile '"' ' '];
    hInfoCmd = [link, space, dump, space, headers, space, libFile, ...
        space, outDir, headerInfoFile];
    [status,~] = system(hInfoCmd);
    if status ~= 0 % If status fails then skip checking bitness
        return;
    end
    headerInfoFile = strrep(headerInfoFile,'"','');
    headerFileDetails = splitlines(string(fileread(headerInfoFile)));
    headerFileDetails = strtrim(headerFileDetails(headerFileDetails ~= ""));
    machineType = find(contains(headerFileDetails,"machine"));
    for i = 1:length(machineType)
        if contains(headerFileDetails(machineType(i)),'14C') % machine type for 32bit lib file is "14C machine (x86)"
            is32Bit = true;
            break;
        end
    end
    % Delete the temporarily created file that has header information
    if (exist(headerInfoFile,'file') ~= 0)
        delete(headerInfoFile);
    end
end

% Delete any additional files that were generated during the compilation 
% and linking process
function delAdditionalFiles(outputDir, srcFileName, dataFileName, buildExecutable, sourceFilesObj, dllNames, cmdFilesList)

prevOrigDir = cd(outputDir);
finishup = onCleanup(@()(cd(prevOrigDir)));
currentDir = pwd;
libName      = [srcFileName, '.lib'];
winObjName   = [srcFileName, '.obj'];
manifestName = [srcFileName, '.dll.manifest'];
expName      = [srcFileName, '.exp'];
unixObjName  = [srcFileName, '.o'];
pkgName = extractBefore(srcFileName, 'Interface');
srcFileName  = [srcFileName, '.cpp'];

resfile = fullfile(currentDir, pkgName + "meta_res.res");
rcfile = fullfile(currentDir, pkgName + "meta_rc.rc");
bundleZipfile = fullfile(currentDir, [extractBefore(srcFileName,"Interface.") '.zip']);
if(isfile(libName))
    delete(libName);
end
if(isfile(winObjName))
    delete(winObjName);
end
if(isfile(manifestName))
    delete(manifestName);
end
if(isfile(expName))
    delete(expName);
end
if(isfile(unixObjName))
    delete(unixObjName);
end
if(isfile(srcFileName))
    delete(srcFileName);
end
if(isfile(dataFileName))
    delete(dataFileName);
end
for ind = 1:length(cmdFilesList)
    if(isfile(cmdFilesList(ind)))
        delete(cmdFilesList(ind));
    end
end


if(~buildExecutable)
    if(isfile('manifest.json'))
        delete('manifest.json');
    end
    if(isfile(resfile))
        delete(resfile)
    end
    if(isfile(rcfile))
        delete(rcfile)
    end
    if(isfile(bundleZipfile))
        delete(bundleZipfile)
    end
end

% Deletes temporarily created object files for each user specified source files
for i = 1:length(sourceFilesObj)
    [~,sourceFileName,ext] = fileparts(sourceFilesObj{i});
    sourceFileName = [sourceFileName,ext];
    if (isfile(sourceFileName) ~= 0)
        delete(sourceFileName);
    end
end
% Delete temorarily created ".lib" and ".exp" files for each DLL file
for i = 1:length(dllNames)
    libName = [dllNames{i} '.lib'];
    if (isfile(libName))
        delete(libName);
    end
    expName = [dllNames{i} '.exp'];
    if (isfile(expName))
        delete(expName);
    end
end
end

% Fix the format of the escape sequence
function fixed=fixesc(input)
fixed=strrep(input,'\','\\');
fixed=strrep(fixed,'%','%%');
end

% This function is used to set the environment for the duration of 
% compilation and linking
function restore=protectEnvAddition(var,add)
if isempty(add)
    restore=[];
else
    oldvalue=getenv(var);
    restore=onCleanup(@()setenv(var,oldvalue));
    new= regexprep(add,'%(\w+)%','${getenv($1)}');  %replace %envname% with its value
    setenv(var,new);
end
end

% Determine if compiler configuration is valid and not empty
% Display an error if the compiler configuration is empty
function isCompilerInstalled(compilerConfig, arch)

%release = ['R' version('-release')];
if(isempty(compilerConfig))
  if(strcmp(arch, 'win64'))
    if matlab.internal.display.isHot
        error(message('MATLAB:mex:NoCompilerFound_link_Win64'));
    else
       error(message('MATLAB:mex:NoCompilerFound_Win64')); 
    end
  else
    if matlab.internal.display.isHot
        error(message('MATLAB:mex:NoCompilerFound_link'));
    else
        error(message('MATLAB:mex:NoCompilerFound'));
    end
  end
end
end

% Append the cmdOut to the buildLog. The buildLog is shown to the 
% user when "Verbose" flag is set 
function buildLog = appendBuildLog(status, cmdOut, cmd, buildLog)
if(status == 0)
    buildLog = buildLog + string(cmd) + newline + string(cmdOut);
else
    buildLog = buildLog + string(cmd);
end
buildLog = buildLog + newline;
end

% Execution Helper executes the command 
% On Windows creates a batch file if the command string exceeds 8000
% characters limit. Windows command line limit is 8191  characters.
% on unix/mac runs the command using 'system', the command string is unchanged
function [status, cmdOut, cmdFilesList] = executionHelper(cmd, outputFile, cmdFilesList)

if ispc && length(cmd)>8000 && all(int32(char(cmd))<=127)
    [outputFolder, batchFilePrefix, ~] = fileparts(replace(outputFile,'"',''));
    batchFilePrefix= string(fullfile(outputFolder, batchFilePrefix));
    cmdFileName = batchFilePrefix + "Cmd.bat";
    fid = fopen(cmdFileName, "w");
    cleanup = onCleanup(@()fclose(fid));
    fprintf(fid, "%s", "@echo off" + newline);
    fprintf(fid, "%s \n", cmd);
    cmdFilesList = [cmdFilesList ; cmdFileName];
    cmd = string(cmdFileName);

end
    [status, cmdOut] = system(cmd);
end
