function opts = getFrontEndOptions(varargin)
%GETFRONTENDOPTIONS Returns default options for calling the C/C++
%   front-end.

%   Copyright 2013-2025 The MathWorks, Inc.

persistent PLATFORMS;
persistent HWNAMES;
persistent DIALECTS;
if isempty(PLATFORMS) || isempty(HWNAMES) || isempty(DIALECTS)
    PLATFORMS = {'none', 'windows', 'linux', 'mac'};
    HWNAMES = {'x86', 'x86_64', 'generic32', 'generic16', 'generic8'};
    DIALECTS = {'none', 'gnu', 'msvc', 'clang', 'mingw64'};
end

% Specify the supported input arguments
persistent argParser;
if isempty(argParser)
    argParser = inputParser();
    supportedLanguages = {'c', 'c90', 'c99', 'c11', 'c17', 'c18', 'c23', 'c++', 'cxx', 'c++03', 'cxx03', 'c++11', 'cxx11', 'c++14', 'cxx14', 'c++17', 'cxx17', 'c++20', 'cxx20', 'c++23', 'cxx23'};
    argParser.addOptional('lang',            'c',   @(x)((ischar(x)||isStringScalar(x)) && any(strcmpi(x,supportedLanguages))));
    argParser.addOptional('addMWInc',        false, @(x)(islogical(x)||(x==1)||(x==0)));
    argParser.addOptional('useMexSettings',  false, @(x)(islogical(x)||(x==1)||(x==0)));

    argParser.addOptional('compInfoFromCoder', [], @(x)(isempty(x) || isa(x, 'mex.CompilerConfiguration')));
    
    argParser.addOptional('targetCpu', [],...
        @(x)(isa(x, 'internal.cxxfe.util.TargetOptions')||((ischar(x)||isStringScalar(x)) && any(strcmpi(x, HWNAMES)))));
    
    argParser.addOptional('targetOS', 'none',...
        @(x)((ischar(x)||isStringScalar(x)) && any(strcmpi(x, PLATFORMS))));
    
    argParser.addOptional('dialect', 'none',...
        @(x)((ischar(x)||isStringScalar(x)) && startsWith(lower(x), DIALECTS)));

    argParser.addOptional('overrideCompilerFlags', '', @(x)(ischar(x)||isStringScalar(x)));
end

% Delegate argument checking to the input parser
argParser.parse(varargin{:});

% Use a variable for shorter path access!
args = argParser.Results;
args.lang = lower(convertStringsToChars(args.lang));
args.targetCpu = convertStringsToChars(args.targetCpu);
args.targetOS = convertStringsToChars(args.targetOS);
args.dialect = lower(convertStringsToChars(args.dialect));
args.overrideCompilerFlags = convertStringsToChars(args.overrideCompilerFlags);
if strncmpi(args.lang, 'c++', 3)
    args.lang(1:3) = 'cxx';
end

if args.useMexSettings
    opts = internal.cxxfe.util.getMexFrontEndOptions('lang', args.lang, 'addMWInc', args.addMWInc, ...
                                                     'compInfoFromCoder', args.compInfoFromCoder, ...
                                                     'overrideCompilerFlags', args.overrideCompilerFlags);
    return
end

% Set the hardware configuration
if ischar(args.targetCpu)
    hwInfo = internal.cxxfe.util.TargetOptions(args.targetCpu);
    targetName = args.targetCpu;
    if strcmpi(targetName, 'x86_64') && strcmpi(args.targetOS, 'windows')
        hwInfo.LongNumBits = 32;
    end
else
    if isempty(args.targetCpu)
        hwInfo = internal.cxxfe.util.TargetOptions();
    else
        hwInfo = args.targetCpu;
    end
    targetName = 'custom';
end

% Construct the default options according to the provided language
langInfo  = internal.cxxfe.util.LanguageOptions(args.lang);

if hwInfo.LongLongNumBits > 0
    langInfo.AllowLongLong = true;
end
if hwInfo.PointerNumBits==hwInfo.IntNumBits
    langInfo.SizeTypeKind = 'uint';
    langInfo.PtrDiffTypeKind = 'int';
elseif hwInfo.PointerNumBits==hwInfo.LongNumBits
    langInfo.SizeTypeKind = 'ulong';
    langInfo.PtrDiffTypeKind = 'long';
elseif hwInfo.PointerNumBits==hwInfo.ShortNumBits    
    langInfo.SizeTypeKind = 'uint';
    langInfo.PtrDiffTypeKind = 'short';
elseif hwInfo.PointerNumBits > hwInfo.LongNumBits
    langInfo.SizeTypeKind = 'ulonglong';
    langInfo.PtrDiffTypeKind = 'longlong';
end

% Rough estimate of the best alignment
if langInfo.AllowLongLong
    langInfo.MaxAlignment = hwInfo.LongLongNumBits / hwInfo.CharNumBits;
else
    langInfo.MaxAlignment = hwInfo.LongNumBits / hwInfo.CharNumBits;
end

opts = internal.cxxfe.FrontEndOptions(hwInfo, langInfo);

% Use the generic header files

% Root path to the generic set of header files.
rootInc = fullfile(matlabroot,'polyspace','verifier','cxx');

isForCxx = strncmpi(opts.Language.LanguageMode, 'cxx', 3);
if isForCxx
    opts.Preprocessor.SystemIncludeDirs{end+1} = fullfile(rootInc, 'include', 'include-libcxx');
    % The generic headers use decltype().
    opts.Language.LanguageExtra{end+1} = '--enable_decltype'; 
    opts.Language.LanguageExtra{end+1} = '--typeinfo_in_std_namespace';
    opts.Language.LanguageExtra{end+1} = '--uliterals';

    opts.Language.LanguageExtra{end+1} = '-tused';
end

% This directory is in the path whatever the language/dialect
opts.Preprocessor.SystemIncludeDirs{end+1} = fullfile(rootInc, 'include', 'include-libc');

if ismember(args.lang, {'c', 'cxx', 'cxx03'})
    opts.Preprocessor.Defines{end+1} = '__STRICT_ANSI__';
end

if strcmpi(targetName, 'x86')
    opts.Preprocessor.Defines{end+1} = '__MW_I386__';
elseif strcmpi(targetName, 'x86_64')
    opts.Preprocessor.Defines{end+1} = '__MW_X86_64__';
end

if ismember(args.targetOS, { 'linux', 'mac' })
    opts.Preprocessor.Defines{end+1} = '__OS_LINUX';
end

[dialectName, dialectVer] = extractDialectInfo(args.dialect);

if dialectName=="gnu" || dialectName=="mingw"
    if isForCxx            
        opts.Language.LanguageExtra{end+1} = '--g++';
    else
        opts.Language.LanguageExtra{end+1} = '--gcc';
    end

    if dialectName == "mingw"
        defaultDialectVer = [8 1 0];
    else
        defaultDialectVer = [4 7 0];
    end
    [majorVer, minorVer, patchLevel] = getDialectVersion(dialectVer, defaultDialectVer);

    gnuVersion = majorVer * 10000 + minorVer * 100 + patchLevel;
    opts.Language.LanguageExtra(end+1:end+2) = { '--gnu_version'; sprintf('%d', gnuVersion) };
    
    if strcmp(args.targetOS, 'mac') 
        opts.Language.LanguageExtra{end+1} = '--restrict';
    end

    opts.Preprocessor.Defines{end+1} = '__MW_GNU__';
    if isForCxx
        % Need the following define for using GNU on non-linux OS
        opts.Preprocessor.Defines{end+1} = '_GNU_SOURCE';
    end

    if ~ispc()
        opts.Target.LongDoubleNumBits = 128;
    end
    opts.Language.WcharTypeKind = 'int';

    if dialectName=="mingw"
        opts.Language.LanguageExtra{end+1} = '--mingw64';
        if isForCxx
            opts.Language.LanguageExtra{end+1} = '--wchar_t_keyword';
        else
            opts.Preprocessor.Defines{end+1} = '_WCHAR_T_DEFINED=1';
        end
        opts.Language.WcharTypeKind = 'ushort';
    end

elseif dialectName=="clang"

    [majorVer, minorVer, patchLevel] = getDialectVersion(dialectVer, [4 0 0]);

    clangVersion = majorVer * 10000 + minorVer * 100 + patchLevel;
    opts.Language.LanguageExtra(end+1:end+2) = { '--clang_version'; sprintf('%d', clangVersion) };

    opts.Language.LanguageExtra{end+1} = '--clang';
    opts.Language.LanguageExtra(end+1:end+2) = {'--gnu_version'; '40800'};
    opts.Language.LanguageExtra{end+1} = '--restrict';
    if clangVersion < 30500 || ~ismember(opts.Language.LanguageMode, {'cxx11', 'cxx14', 'cxx17', 'cxx20'})
        opts.Preprocessor.Defines{end+1} = '_LIBCPP_HAS_NO_VARIADICS';
        opts.Preprocessor.Defines{end+1} = '_LIBCPP_HAS_NO_RVALUE_REFERENCES';
    end

elseif dialectName=="msvc"
    opts.Language.LanguageExtra{end+1} = '--microsoft';

    mVer = '1900';
    msStd = [];
    if numel(dialectVer) > 0
        switch dialectVer(1)
          case 19
            mVer = '1923'; % Highest known update for VS2019.
            if isForCxx
                msStd = '--ms_c++20';
            end
          case 17
            mVer = '1919'; % Potentially highest update for VS2017.
            if isForCxx
                msStd = '--ms_c++17';
            end
          case 15
            mVer = '1910';
          case 14
            mVer = '1900';
          case 12
            mVer = '1800';
          case 11
            mVer = '1700';
          case 10
            mVer = '1600';
          case 9
            mVer = '1500';
          case 8
            mVer = '1400'; 
          case 7
              if numel(dialectVer)>1 && dialectVer(2)==1
                  mVer = '1310';
              else
                  mVer = '1300';
              end
          case 6
            mVer = '1200';
        end
    end

    opts.Language.LanguageExtra{end+1} = ['--microsoft_version=', mVer];
    if ~isempty(msStd)
        opts.Language.LanguageExtra{end+1} = msStd;
    end

    if strcmpi(targetName, 'x86')
        % If _M_IX86 is not already defined, provide a default configuration that defines it as well as _MT and _X86_.
        opts.Preprocessor.Defines = [opts.Preprocessor.Defines; {'_M_IX86=600'; '_X86_'; '_M_IX86_FP'}]; 
    elseif strcmpi(targetName, 'x86_64')
        % If _M_X64 is not already defined, provide a default configuration that defines it as well as _MT and _M_AMD64.
        opts.Preprocessor.Defines = [opts.Preprocessor.Defines; {'_M_X64'; '_M_AMD64'; '_M_IX86_FP'}];
    end
else
    % No specific dialect
    if isForCxx
        opts.Preprocessor.Defines(end+1) = {'_LIBCPP_COMPILER_GENERIC_POLYSPACE'};
        if ismember(opts.Language.LanguageMode, {'cxx11', 'cxx14', 'cxx17', 'cxx20'})
             opts.Preprocessor.Defines(end+1) = {'_LIBCPP_HAS_C_ATOMIC_IMP'};
        end
    end
end

% Add all the known MW include directories
if args.addMWInc
    opts.Preprocessor.IncludeDirs = {...
        fullfile(matlabroot, 'extern', 'include');  ...
        fullfile(matlabroot, 'simulink', 'include') ...
        };
end

end

%% ------------------------------------------------------------------------
function [majorVer, minorVer, patchLevel] = getDialectVersion(dialectVer, defaultDialectVer)

majorVer = defaultDialectVer(1);
minorVer = defaultDialectVer(2);
patchLevel = defaultDialectVer(3);
numVer = numel(dialectVer);
if numVer > 0
    majorVer = dialectVer(1);
    if numVer > 1
        minorVer = dialectVer(2);
        if numVer > 2
            patchLevel = dialectVer(3);
        end
    end
end

end

%% ------------------------------------------------------------------------
function [dialectName, dialectVer] = extractDialectInfo(dialect)

dialectName = 'none';
dialectVer = [];

tok = regexpi(dialect, '([a-z]+)([\d\.]+)?', 'tokens');
if ~isempty(tok) && ~isempty(tok{1})
    dialectName = tok{1}{1};
    if ~isempty(tok{1}{2})
        tok = strsplit(tok{1}{2}, '.');
        tok(cellfun(@isempty, tok)) = [];
        dialectVer = zeros(1, numel(tok));
        for ii = 1:numel(tok)
            dialectVer(ii) = sscanf(tok{ii}, '%d');
        end
    end
end

% The '64' in 'mingw64' is not part of the dialect version.
if (dialectName == "mingw") && ~isempty(dialectVer) && dialectVer(1) == 64
    dialectVer(1) = [];
end

end

% LocalWords:  lang cxxfe cxx maci linux EDG libc libcxx defs GLIBCXX mingw uliterals wchar ushort
% LocalWords:  microsoft predef msvc typeinfo decltype tused ulong ulonglong VARIADICS RVALUE FP
% LocalWords:  longlong LIBCPP GXX va GNUC WCHAR LDBL GTHREAD BUILTINS DENORM
% LocalWords:  utils
