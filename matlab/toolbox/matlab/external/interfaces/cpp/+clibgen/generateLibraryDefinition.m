function generateLibraryDefinition(headerFiles,varargin)
% GENERATELIBRARYDEFINITION generates the definition file for a C++ library.
%   GENERATELIBRARYDEFINITION (VALUE)
%   GENERATELIBRARYDEFINITION(VALUE, 'Option1',value1, 'Option2', value2...)
% 
%   Input Arguments
%   ----------
%   InterfaceGenerationFiles       -- Files for generating interface. Specifies one or more header files
%                                     and/or source  files as a character vector, string array
%                                     or cellstr of character vector. Supported extensions
%                                     are .h, .hpp, .hxx, .cpp and .cxx.
%                                     Files without extension is also supported.
%
%   Possible options:
%
%   'Verbose'        --  Specifies whether to display warnings generated
%                        while building the definition file to the command 
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
%                         is generated specified as a character vector or 
%                         string scalar.
%                        Default value is the current working directory.
%
%   'InterfaceName' --   Specifies the name for the generated interface
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
%   'SupportingSourceFiles'   --   Specifies one or more source files as a character
%                        vector, string array or cellstr of character
%                        vector. Supported extensions are .cpp and .cxx
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
%   'OverwriteExistingDefinitionFiles' --  Specifies whether to overwrite the
%                                          existing definition files.
%                                          false - (default) Existing
%                                                    definition files are
%                                                    not overwritten.
%                                          true  - Existing definition files
%                                                   are overwritten.
%
%   'AdditionalCompilerFlags'           --   Specifies the list(array of strings) of additional flags
%                                            that are appended to the compiler flags during the build stage.
%
%
%   'AdditionalLinkerFlags'             --   Specifies the list(array of strings) of linker flags that
%                                            are appended to the linker flags during the build stage.
%
%   'RootPaths'      --   Specifies a dictionary of variable names and pathnames. The dictionary key is
%                         a variable name specified as a string. The dictionary value is a relative pathname,
%                         specified as a string. Use RootPaths to construct the value of the
%                         "InterfaceGenerationFiles" argument or the value of the name-value arguments
%                         "Libraries", "IncludePath", "OutputFolder", or "SupportingSourceFiles".

%
%   Example:
%       clibgen.generateLibraryDefinition("foo.hpp");
%
%       generates definefoo.m in current working directory.
% 
%       clibgen.generateLibraryDefinition(["foo.hpp","bar.hpp"],...
%                                         Libraries="foo.lib",...
%                                         IncludePath="C:\foo\include",...
%                                         InterfaceName="myLibrary",...
%                                         Verbose=true,...
%                                         OutputFolder="C:\work");
%
%       generates definemyLibrary.m in C:\work
%       and displays any warning messages to the command window.
%
%       clibgen.generateLibraryDefinition("myHeader.hpp",...
%                                         IncludePath="C:\myHeader\include",...
%                                         InterfaceName="myLibrary",...
%                                         Verbose=true,...
%                                         OutputFolder="C:\work");
%
%       generates definemyLibrary.m in C:\work
%       and displays any warning messages to the command window.
%
%       clibgen.generateLibraryDefinition("foo.hpp",...
%                                         SupportingSourceFiles="foo.cpp",...
%                                         IncludePath="C:\foo\include",...
%                                         InterfaceName="myLibrary",...
%                                         Verbose=true,...
%                                         OutputFolder="C:\work");
%
%       generates definemyLibrary.m in C:\work
%       and displays any warning messages to the command window.
%
%       clibgen.generateLibraryDefinition("foo.hpp",...
%                                         SupportingSourceFiles="foo.cpp",...
%                                         Libraries="foo.lib",...
%                                         IncludePath="C:\foo\include",...
%                                         InterfaceName="myLibrary",...
%                                         Verbose=true,...
%                                         OutputFolder="C:\work");
%
%       generates definemyLibrary.m in C:\work
%       and displays any warning messages to the command window.
%
%       clibgen.generateLibraryDefinition("foo.h", SupportingSourceFiles="foo.c",...
%                                       CLinkage=true,...
%                                       IncludePath="C:\foo\include",...
%                                       InterfaceName="myLibrary",...
%                                       Verbose=true,...
%                                       OutputFolder="C:\work");
% 
%       generates definemyLibrary.m in C:\work without name mangling ...
%       issues and displays any warning messages to the command window.
%
%       clibgen.generateLibraryDefinition("foo.cpp",...
%                                       InterfaceName="myLibrary",...
%                                       Verbose=true,...
%                                       OutputFolder="C:\work");
%
%       generates definemyLibrary.m in C:\work
%       and displays any warning messages to the command window.
%
%       clibgen.generateLibraryDefinition("foo.hpp",...
%                                       DefinedMacros= "INTEGER_CODE=0", ...
%                                       IncludePath="C:\foo\include",...
%                                       InterfaceName="myLibrary",...
%                                       Verbose=true,...
%                                       OutputFolder="C:\work");
%
%       generates definemyLibrary.m in C:\work with macros defined
%       and displays any warning messages to the command window.
%
%       rootpaths = dictionary;
%       rootpaths("rootpath") = "C:\foo";
%       clibgen.generateLibraryDefinition("<rootpath>/foo.hpp",...
%                                       IncludePath="<rootpath>/include",...
%                                       Libraries="<rootpath>/foo.lib",...
%                                       PackageName="mypackage",...
%                                       RootPaths=rootpaths,...
%                                       OutputFolder="C:\work");
%
%       generates definemypackage.m in C:\work with RootPaths property
%       which can be modified without other filePath properties if roopath
%       changes when definition file needs to rebuild.
%
%
%   See also CLIBGEN.BUILDINTERFACE

%  Copyright 2018-2023 The MathWorks, Inc.

% Check if the compiler is supported
if(ispc)
    cc = mex.getCompilerConfigurations('C++', 'Selected');
    if(~isempty(cc) && contains(cc.ShortName, 'MinGW64SDK'))
        error(message('MATLAB:CPP:UnsupportedCompiler', cc.Name));
    end
end

% Validate the first input argument
if nargin < 1
    error(message('MATLAB:CPP:Filename'));
end

% Parse all the inputs
parser = inputParser;
parser.FunctionName = 'generateLibraryDefinition';
clibgen.internal.cppsetup(parser);

try
    [parsedResults, feOpts] = clibgen.internal.cppparse(parser,headerFiles, varargin{:});

    interfaceDir = fullfile(parsedResults.OutputFolder, parsedResults.InterfaceName);
    if exist(interfaceDir, 'file') == 2
        % Error if there is a file with PackageName in OutputFolder
        error(message('MATLAB:CPP:FileExistsWithPackageName', interfaceDir));
    end
    w = warning('off', 'backtrace');
    onCleanup(@() warning(w));
    
    if length(parsedResults.HeaderFiles) >0 && parsedResults.InterfaceName == ""
        error(message('MATLAB:CPP:MultiHeadersPackageName'));
    end
catch exception
    throwAsCaller(exception);
end

% Call clib.internal.cppgenerate()after converting everything to string.
fields = fieldnames(parsedResults);
for index = 1:numel(fields)
    if strcmp(fields{index},'Verbose') || strcmp(fields{index},'TreatObjectPointerAsScalar') ...
            || strcmp(fields{index},'TreatConstCharPointerAsCString') ...
            || strcmp(fields{index},'GenerateDocumentationFromHeaderFiles') ...
            || strcmp(fields{index},'ReturnCArrays') ...
            || strcmp(fields{index},'OverwriteExistingDefinitionFiles') ...
            || strcmp(fields{index},'CLinkage')
        parsedResults.(fields{index}) = logical(parsedResults.(fields{index}));
    elseif not (strcmp(fields{index},'Logger') || strcmp(fields{index},'RootPaths'))
        parsedResults.(fields{index}) = string(parsedResults.(fields{index}));
    end
end

% Check if m file already exist
mFile = fullfile(char(parsedResults.OutputFolder),['define',char(parsedResults.InterfaceName),'.m']);

% Create a temporary unique name for definition files to remove only upon
% success, otherwise, restore the original name of the defintion files on
% error.
tmpMFile = mFile;
if (parsedResults.OverwriteExistingDefinitionFiles)
    % Only overwrite if both defintion files are writable
    % if definition file is readonly return error
    if FileExist(mFile)
        [~,mFileAttr,~] = fileattrib(mFile);
        if ~mFileAttr.UserWrite
            error(message('MATLAB:CPP:DefinitionFileReadOnly', mFile));
        end
    end
    % Move the files aside for deletion upon success
    uniqueStr=num2hex(datenum(datetime));
    tmpMFile = strcat(mFile, uniqueStr);
    if FileExist(mFile)
        movefile(mFile, tmpMFile, "f");
    end
end
    
% mFile file exists error message
if FileExist(mFile)
    error(message('MATLAB:CPP:DefinitionFileExists', mFile))
end

if isempty(parsedResults.Logger)
    logger = clibgen.internal.MessageLogger;
else
    logger = parsedResults.Logger;
end

try
    for i= 1:length(parsedResults.HeaderFiles)
        [Directory,~,~] = fileparts(parsedResults.HeaderFiles(i));
        if isempty(char(Directory))
            parsedResults.HeaderFiles(i) = string(fullfile(pwd,char(parsedResults.HeaderFiles(i))));
        end
    end
    [messageLog, totalCons, numNeedDef] = clibgen.internal.cppgenerate(parsedResults,feOpts);
    
    %Display messages
    logger.HeaderMessages = messageLog;
    logger.totalConstructs = totalCons;
    logger.undefinedConstructs = numNeedDef;
    if parsedResults.Verbose && ~isempty(logger.HeaderMessages)
        if matlab.internal.display.isHot
            warning(message('MATLAB:CPP:WarningsFromHeader_link', logger.getHeaderMessages));
        else
            warning(message('MATLAB:CPP:WarningsFromHeader', logger.getHeaderMessages));
        end
    end
    
    % Remove temporary definition file created when Overwrite true
    if (parsedResults.OverwriteExistingDefinitionFiles)
        if FileExist(tmpMFile)
            delete(tmpMFile);
            disp(message('MATLAB:CPP:ReportDeletedFile', mFile).getString);
        end
    end
catch ME
    % Restore temporary definition file created when Overwrite is true
    if FileExist(tmpMFile) && parsedResults.OverwriteExistingDefinitionFiles
        movefile(tmpMFile, mFile, "f");
    end
    throwAsCaller(ME);
end
definitionFile = "define" + parsedResults.InterfaceName + ".m";

% Check for nothing to call condition
if logger.totalConstructs == 0
    delete(mFile);
    delete(fullfile(parsedResults.OutputFolder,parsedResults.InterfaceName + "Data.xml"));
    error(message('MATLAB:CPP:NoConstructsFoundCheckFiles'));
end

% Compiler used
disp(message('MATLAB:CPP:CompilerUsed', mex.getCompilerConfigurations('C++', 'Selected').Name).getString);

% Message that the definition file and XML is generated.
if matlab.internal.display.isHot
    disp(message('MATLAB:CPP:FilesGenerated_link' , fullfile(parsedResults.OutputFolder,definitionFile), definitionFile, ...
    num2str(logger.totalConstructs)).getString);
else
    disp(message('MATLAB:CPP:FilesGenerated' , fullfile(parsedResults.OutputFolder,definitionFile), ...
        num2str(logger.totalConstructs)).getString);
end

% Display message for number of fully defined constructs
numConstructsDefined = logger.totalConstructs-logger.undefinedConstructs;
disp(message('MATLAB:CPP:ConstructsDefined', num2str(numConstructsDefined)).getString);

% Display message to indicate whether definition is required
if(numNeedDef > 0)
    if matlab.internal.display.isHot
        disp(message('MATLAB:CPP:ConstructsNeedDefinition_link', ...
            num2str(logger.undefinedConstructs), ...
            fullfile(parsedResults.OutputFolder,definitionFile), definitionFile, ...
            num2str(logger.undefinedConstructs)).getString);
    else
        disp(message('MATLAB:CPP:ConstructsNeedDefinition', ...
            num2str(logger.undefinedConstructs), ...
            fullfile(parsedResults.OutputFolder,definitionFile), ...
            num2str(numConstructsDefined)).getString);
    end
end
[~, definitionFile, ~] = fileparts(definitionFile);
disp(message('MATLAB:CPP:BuildCmd', definitionFile).getString);

if ~parsedResults.Verbose && ~isempty(logger.HeaderMessages)
    disp(message('MATLAB:CPP:UseVerboseMode').getString);
end
% Warning if no C++ symbols to call
if numConstructsDefined == 0 && numNeedDef > 0
    warning(message('MATLAB:CPP:NoConstructsCheckDefinition'));
end
end

%% Check if a file exists
function Ex = FileExist(FileName)
dirFile = dir(FileName);
if length(dirFile) == 1
    Ex = ~(dirFile.isdir);
else
    Ex = false;
end
end
