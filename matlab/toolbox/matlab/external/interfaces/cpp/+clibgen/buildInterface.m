function buildInterface(headerFiles,varargin)
% BUILDINTERFACE builds the interface file to the C++ Library.
%   BUILDINTERFACE (VALUE)
%   BUILDINTERFACE (VALUE, 'Option1',value1, 'Option2', value2...)
%
%   Input Arguments
%   ----------
%   InterfaceGenerationFiles   -- Files for generating interface. Specifies one or more header files
%                                 and/or source  files as a character vector, string array
%                                 or cellstr of character vector. Supported extensions
%                                 are .h, .hpp, .hxx, .cpp and .cxx.
%                                 Files without extension is also supported.
%   Possible options:
%
%   'Verbose'        --  Specifies whether to display warnings generated
%                        while building the interface to the command 
%                        window.
%                        false - (default) warnings are not displayed to 
%                                 the command window.
%                        true  - displays warnings to the command window.
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
%   'InterfaceName'  --  Specifies the name for the generated interface
%                        as a character vector or string scalar. For single
%                        header, the default value is the name of header.
%                        For multiple headers, specify the interface name
%                        which is a valid MATLAB name.
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
%                                        char/wchar_t/char16_t/char32_t pointers
%                                        as null-terminated C strings.
%                                        false - (default) MATLAB type and shape
%                                                of const character pointers
%                                                need definition.
%                                        true  - treats const character pointers
%                                                as C strings by specifying
%                                                MATLAB type as string and
%                                                shape as nullTerminated.
%
%   'DefinedMacros'   --  Specifies list of macros to use while parsing the 
%                         HeaderFiles.
%
%   'UndefinedMacros' --  Specifies the list of macros to cancel while parsing 
%                         the HeaderFiles.
%
%   'SupportingSourceFiles'     --  Specifies one or more source files as a character
%                                   vector, string array or cellstr of character
%                                   vector. Supported extensions are .cpp and .cxx
%
%   'AdditionalCompilerFlags'   --   Specifies the list(array of strings) of additional flags
%                                    that are appended to the compiler flags during the build stage.
%
%
%   'AdditionalLinkerFlags'     --   Specifies the list(array of strings) of linker flags that
%                                    are appended to the linker flags during the build stage.
%
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
%   Example:
%       clibgen.buildInterface("foo.hpp");
%
%       builds fooInterface.dll in subfolder 'foo' in current working
%       directory.
%
%       clibgen.buildInterface(["foo.hpp","bar.hpp"],...
%                                         Libraries="foo.lib",...
%                                         IncludePath="C:\foo\include",...
%                                         InterfaceName="myLibrary",...
%                                         Verbose=true,...
%                                         OutputFolder="C:\work");
%
%       builds myLibraryInterface.dll in C:\work\myLibrary
%       and displays any warning messages to the command window.
%
%       clibgen.buildInterface("myHeader.hpp",...
%                                         IncludePath="C:\myHeader\include",...
%                                         InterfaceName="myLibrary",...
%                                         Verbose=true,...
%                                         OutputFolder="C:\work");
%
%       builds myLibraryInterface.dll in C:\work\myLibrary
%       and displays any warning messages to the command window.
%
%       clibgen.buildInterface("foo.hpp",...
%                                         SupportingSourceFiles="foo.cpp",...
%                                         IncludePath="C:\foo\include",...
%                                         InterfaceName="myLibrary",...
%                                         Verbose=true,...
%                                         OutputFolder="C:\work");
%
%       builds myLibraryInterface.dll in C:\work\myLibrary
%       and displays any warning messages to the command window.
%
%       clibgen.buildInterface("foo.hpp",...
%                                         SupportingSourceFiles="foo.cpp",...
%                                         Libraries="foo.lib",...
%                                         IncludePath="C:\foo\include",...
%                                         InterfaceName="myLibrary",...
%                                         Verbose=true,...
%                                         OutputFolder="C:\work");
%
%       builds myLibraryInterface.dll in C:\work\myLibrary
%       for foo.hpp and displays any warning messages
%       to the command window.
%
%       clibgen.buildInterface("foo.h", SupportingSourceFiles="foo.c",...
%                                       CLinkage=true,...
%                                       IncludePath="C:\foo\include",...
%                                       InterfaceName="myLibrary",...
%                                       Verbose=true,...
%                                       OutputFolder="C:\work");
% 
%       builds myLibraryInterface.dll in C:\work\myLibrary without ...
%       name mangling issues and displays any warning messages to ...
%       the command window.
% 
%       clibgen.buildInterface("foo.hpp",...
%                                       DefinedMacros= "INTEGER_CODE=0", ...
%                                       IncludePath="C:\foo\include",...
%                                       InterfaceName="myLibrary",...
%                                       Verbose=true,...
%                                       OutputFolder="C:\work");
%
%       builds myLibraryInterface.dll in C:\work\myLibrary with macros defined
%       and displays any warning messages to the command window.
%
%
%   See also CLIBGEN.GENERATELIBRARYDEFINITION

%  Copyright 2018-2024 The MathWorks, Inc.

if(ispc)
    cc = mex.getCompilerConfigurations('C++', 'Selected');
    if(~isempty(cc) && contains(cc.ShortName, 'MinGW64SDK'))
        error(message('MATLAB:CPP:UnsupportedCompiler', cc.Name));
    end
end

% Create parser
% Validate the first input argument
if nargin < 1
    error(message('MATLAB:CPP:Filename'));
end

% Parse all the inputs
parser = inputParser;
parser.FunctionName = 'buildInterface';
clibgen.internal.cppsetup(parser);

try
    [parsedResults, feOpts] = clibgen.internal.cppparse(parser,headerFiles, varargin{:});

    if length(parsedResults.HeaderFiles) >0 && parsedResults.InterfaceName == ""
        error(message('MATLAB:CPP:MultiHeadersPackageName'));
    end
catch exception
    throwAsCaller(exception);
end

% Call clib.internal.cppbuild()after converting everything to string.
fields = fieldnames(parsedResults);
for index = 1:numel(fields)
    if strcmp(fields{index},'Verbose') || strcmp(fields{index},'TreatObjectPointerAsScalar') ...
            || strcmp(fields{index},'TreatConstCharPointerAsCString') ...
            || strcmp(fields{index},'GenerateDocumentationFromHeaderFiles') ...
            || strcmp(fields{index},'ReturnCArrays') ...
            || strcmp(fields{index},'CLinkage')
        parsedResults.(fields{index}) = logical(parsedResults.(fields{index}));
    elseif not (strcmp(fields{index},'Logger') || strcmp(fields{index},'RootPaths'))
        parsedResults.(fields{index}) = string(parsedResults.(fields{index}));
    end
end
try
    % Generate XML and interface code
    for i= 1:length(parsedResults.HeaderFiles)
        [Directory,~,~] = fileparts(parsedResults.HeaderFiles(i));
        if isempty(char(Directory))
            parsedResults.HeaderFiles(i) = string(fullfile(pwd,char(parsedResults.HeaderFiles(i))));
        end
    end
    directBuildHelper = clibgen.internal.DirectBuildHelper(parsedResults, feOpts);
    directBuildHelper.build;
catch ME
    if strcmp(ME.identifier, 'MATLAB:InputParser:ArgumentFailedValidation')
        error(message('MATLAB:CPP:ArgValidationFail',varargin{1}));
    else
        throwAsCaller(ME);
    end
end
end