function [parsedResults,feOpts] = cppparse(parser,headerFiles, varargin)
%CPPPARSE parses and validates the inputs to clibgen.generateLibraryDefinition and
%   clibgen.buildInterface.
%
%   Input Arguments
%   -----------------
%
%   parser         --   inputParser object.
%                      
%                    
%   headerFiles    --   Specifies one or more header files and/or source files as a
%                       character vector, string array or cellstr of character
%                       vector. Supported extensions are .h, .hpp, .hxx,
%                       .cpp  and .cxx.
%                       file without extension is also supported.
%                      
%   Possible options for varargin:
%
%                   --   Specifies the 'silent' flag to suppress success
%                        message or warnings to the command window.
%
%   'Libraries'     --   Specifies full path to the library name specified
%                        as a character vector, string array or cellstr of
%                        character vectors. Default value is empty.
%
%   'IncludePath'   --   A character vector, string array or cellstr
%                        of character vectors of complete path of
%                        the include folders to include during compilation
%                        of the header file. Default value is empty.
%
%   'OutputFolder'  --   Specifies the location where the definition file
%                        is generated specified as
%                        a character vector or string scalar.
%                        Default value is the current working directory.
%
%   'InterfaceName' --   Specifies the name for the generated interface
%                        library as a character vector or string
%                        scalar. For single header, the default value is
%                        the name of header. For multiple headers, specify
%                        the interface name which is a valid MATLAB name.
%
%   'CLinkage'      --  Specifies whether to parse and build .h header files
%                        as C header files to avoid name mangling issues.
%                        false - (default) treats .h header files passed
%                        under InterfaceGenerationFiles option as CPP
%                        header files.
%                        true  - treats .h header files passed
%                        under InterfaceGenerationFiles option as C
%                        header files. C header files are included with
%                        extern "C" blocks in the generated interface code
%                        which will help avoid name mangling issues when
%                        linked against a C library.
%
%   'TreatObjectPointerAsScalar'     --  Specifies whether to treat shape of
%                                        all object pointers as scalar.
%                                        false - (default) shape of object
%                                                 pointers needs definition.
%                                        true  - treats shape of object
%                                                 pointers as scalar.
%
%   'TreatConstCharPointerAsCString' --  Specifies whether to treat all const
%                                        char pointers as null-terminated C
%                                        strings.
%                                        false - (default) MATLAB type and shape
%                                                 of const char pointers need
%                                                 definition.
%                                        true  - treats const char pointers as
%                                                 C strings by specifying MATLAB
%                                                 type as string and shape as
%                                                 nullTerminated.
%
%   'DefinedMacros'   --  Specifies list of macros to use while parsing the 
%                         HeaderFiles.
%
%   'UndefinedMacros' --  Specifies the list of macros to cancel while parsing 
%                         the HeaderFiles.
%
%   'GenerateDocumentationFromHeaderFiles' --  Specifies whether to generate
%                                              documentation from header files
%                                              for display using the MATLAB help
%                                              and doc commands.
%                                              true  - (default) generates
%                                                       documentation from
%                                                       comments in C++ header
%                                                       files.
%                                              false - ignores C++ comments and
%                                                       only generates
%                                                       documentation of MATLAB
%                                                       and C++ type mappings.
%
%   'ReturnCArrays' --  Specifies whether to return non-object C arrays.
%                       true  - (default) returns C arrays (clib.array.*)
%                                for non-object C arrays.
%                       false - returns numeric MATLAB arrays for non-object
%                                C arrays.
%
%   'SupportingSourceFiles'   --   Specifies one or more source files as a character
%                                  vector, string array or cellstr of character
%                                  vector. Supported extensions are .cpp and .cxx
%
%   'RootPaths'      --   Specifies a dictionary of variable names and pathnames. The dictionary key is
%                         a variable name specified as a string. The dictionary value is a relative pathname,
%                         specified as a string. Use RootPaths to construct the value of the
%                         "InterfaceGenerationFiles" argument or the value of the name-value arguments
%                         "Libraries", "IncludePath", "OutputFolder", or "SupportingSourceFiles".
%
%   Output Arguments
%   -----------------
%   
%   parsedResults      -- A struct containing names and values of inputs that
%                         match the function input scheme populated by the parse
%                         method of inputParser.
%
%   compilerHeadersPath -- A character vector of the location of system
%                          include headers based on the selected compiler.

%   Copyright 2018-2024 The MathWorks, Inc.

% Parse the inputs
try   
    % g1645018 : Validate the header file input as it is not part of input parser arguments
    clibgen.internal.validateHeaders(parser, headerFiles);
    parse(parser,varargin{:});
    parsedResults = clibgen.internal.validateRootPathKeysAndUpdatePaths(parser, headerFiles);
catch ME
    throwAsCaller(ME)
end

% Setup paths
parsedResults = clibgen.internal.setupParsePaths(parsedResults);
parsedResults = clibgen.internal.setupBuildPaths(parsedResults);

% Get the front end options
compilerConfig = mex.getCompilerConfigurations('C++', 'Selected');
if isempty(compilerConfig)
    if matlab.internal.display.isHot
        error(message("MATLAB:mex:NoCompilerFound_link"));
    else
        error(message("MATLAB:mex:NoCompilerFound"));
    end
end
feOpts = clibgen.internal.getFrontEndOptions(parsedResults.HeaderFiles, ...
    parsedResults.IncludePath,parsedResults.DefinedMacros, ...
    parsedResults.UndefinedMacros,compilerConfig.Details.CompilerFlags, ...
    parsedResults.AdditionalCompilerFlags);

% Setup lib / dll compiled libraries
if ispc
    parsedResults.Libraries = clibgen.internal.setupLibDll(parsedResults.Libraries, parsedResults.HeaderFiles, compilerConfig.Manufacturer);
end

% Setup interface name
parsedResults = clibgen.internal.setupInterfaceName(parsedResults);

% Check headers / sources
clibgen.internal.checkSourceFiles(parsedResults.HeaderFiles, parsedResults.SupportingSourceFiles);
clibgen.internal.checkCLinkage(parsedResults.HeaderFiles, ...
    parsedResults.SupportingSourceFiles, parsedResults.CLinkage);

% As a last step in parsing, update relative paths from absolute paths
parsedResults = clibgen.internal.updateRelativePathsFromAbsolutePaths(parsedResults);

end
