%

%   Copyright 2013-2025 The MathWorks, Inc.

%-----------------------------------------------------------------------------
% CAUTION: any modification in this file should be implemented similarly in
%          polyspace/src/psprofile/cli/psprofcmd_instrument/PsConfigureUtils.cpp
%-----------------------------------------------------------------------------

function [opts, compCmd] = getMexFrontEndOptions(varargin)
%GETMEXFRONTENDOPTIONS Returns default options for calling the C/C++
%   front-end.

% Specify the supported input arguments
persistent argParser;
if isempty(argParser)
    argParser = inputParser();
    argParser.addOptional('lang',                  'c',   @(x)((ischar(x)||isStringScalar(x)) && any(strcmpi(x,{'c','c++', 'cxx'}))));
    argParser.addOptional('addMWInc',              false, @(x)(islogical(x)||(x==1)||(x==0)));
    argParser.addOptional('compInfoFromCoder',     [],    @(x)(isempty(x) || isa(x, 'mex.CompilerConfiguration')));
    argParser.addOptional('overrideCompilerFlags', '',    @(x)(ischar(x)||isStringScalar(x)));
    argParser.addOptional('compInfoFromPsConfigure', [], ...
        @(x)(isempty(x) || (isfield(x, 'sysHeaderDirs') && isfield(x, 'sysCompDefines'))));
end

% Delegate argument checking to the input parser
argParser.parse(varargin{:});

% Use a variable for shorter path access!
args = argParser.Results;
args.lang = lower(convertStringsToChars(args.lang));
args.overrideCompilerFlags = convertStringsToChars(args.overrideCompilerFlags);
if strcmpi(args.lang, 'c++')
    args.lang = 'cxx';
end

% This part deals with extracting compiler information from the
% mex setup or from the supported set of compilers.

currCompInfo = [];
overrideCompilerFlags = args.overrideCompilerFlags;
isInfoFromPsConfigure = ~isempty(args.compInfoFromPsConfigure);
if isInfoFromPsConfigure
    currCompInfo = args.compInfoFromPsConfigure;
    args.addMWInc = true;
else
    if isempty(args.compInfoFromCoder)
        % Retrieve the current mex compiler settings.
        currCompInfo = internal.cxxfe.util.getMexCompilerInfo('lang', args.lang, ...
            'overrideCompilerFlags', overrideCompilerFlags);
    else
        % The compiler configuration comes from the model settings (or more precisely
        % from the code generation panel settings). This compiler information
        % isn't necessarily the same as the current mex -setup.
        if isa(args.compInfoFromCoder, 'mex.CompilerConfiguration')
            currCompInfo = internal.cxxfe.util.getMexCompilerInfo(...
                'lang', args.lang,...
                'compInfoFromCoder', args.compInfoFromCoder, ...
                'overrideCompilerFlags', overrideCompilerFlags);
        end
    end

    % Always throw an error if no system include directory found
    if isempty(currCompInfo) || ~isa(currCompInfo, 'internal.cxxfe.mexcfg.MexCompilerInfo') || ...
            isempty(currCompInfo.sysHeaderDirs) ||...
            isempty(currCompInfo.sysCompDefines)
        error(message('cxxfe_mi:utils:NoMexCompilerForLang', args.lang));
    end

    % currCompInfo is a structure when passed to "compInfoFromPsConfigure"
    % or is an internal.cxxfe.mexcfg.MexCompilerInfo object otherwise.
    % Could transform the object to a structure for consistency but it
    % would not change anything below in the logic of testing
    % "isfield(currCompInfo, 'targetSettings')", then keep it as-is...
end

if isfield(currCompInfo, 'compCmd') || isprop(currCompInfo, 'compCmd')
    compCmd = currCompInfo.compCmd;
else
    compCmd = [];
end

% Set the hardware configuration
hasTargetSettings = isfield(currCompInfo, 'targetSettings');
if hasTargetSettings
    hwInfo = internal.cxxfe.util.TargetOptions();
    if isfield(currCompInfo.targetSettings, 'Endianness')
        hwInfo.Endianness = currCompInfo.targetSettings.Endianness;
    end
    hwInfo.CharNumBits = currCompInfo.targetSettings.CharNumBits;
    hwInfo.ShortNumBits = currCompInfo.targetSettings.ShortNumBits;
    hwInfo.IntNumBits = currCompInfo.targetSettings.IntNumBits;
    hwInfo.LongNumBits = currCompInfo.targetSettings.LongNumBits;
    if isfield(currCompInfo.targetSettings, 'LongLongNumBits')
        hwInfo.LongLongNumBits = currCompInfo.targetSettings.LongLongNumBits;
    end
    if isfield(currCompInfo.targetSettings, 'ShortLongNumBits')
        hwInfo.ShortLongNumBits = currCompInfo.targetSettings.ShortLongNumBits;
    end
    hwInfo.FloatNumBits = currCompInfo.targetSettings.FloatNumBits;
    hwInfo.DoubleNumBits = currCompInfo.targetSettings.DoubleNumBits;
    if isfield(currCompInfo.targetSettings, 'LongDoubleNumBits')
        hwInfo.LongDoubleNumBits = currCompInfo.targetSettings.LongDoubleNumBits;
    end
    hwInfo.PointerNumBits = currCompInfo.targetSettings.PointerNumBits;
else
    if strcmp(computer('arch'), 'win32')
        targetName = 'x86';
    else
        targetName = 'x86_64';
    end
    hwInfo = internal.cxxfe.util.TargetOptions(targetName);
    if strcmp(computer('arch'), 'win64')
        hwInfo.LongNumBits = 32;
    end
end

% Construct the default options according to the provided language
langInfo  = internal.cxxfe.util.LanguageOptions(args.lang);

if hasTargetSettings
    langInfo.MinStructAlignment = currCompInfo.targetSettings.MinStructAlignment;
    langInfo.MaxAlignment = currCompInfo.targetSettings.MaxAlignment;
    if isfield(currCompInfo.targetSettings, 'WcharTypeKind')
        langInfo.WcharTypeKind = currCompInfo.targetSettings.WcharTypeKind;
    end
    langInfo.PlainCharsAreSigned = currCompInfo.targetSettings.PlainCharsAreSigned;
    langInfo.AllowShortLong = currCompInfo.targetSettings.AllowShortLong;
    langInfo.AllowLongLong = currCompInfo.targetSettings.AllowLongLong;
    langInfo.AllowMultibyteChars = currCompInfo.targetSettings.AllowMultibyteChars;
    langInfo.PlainBitFieldsAreSigned = currCompInfo.targetSettings.PlainBitFieldsAreSigned;
else
    if hwInfo.ShortLongNumBits > 0 && hwInfo.ShortLongNumBits >= hwInfo.IntNumBits
        langInfo.AllowShortLong = true;
    end
    if hwInfo.LongLongNumBits > 0
        langInfo.AllowLongLong = true;
    end

    % Rough estimate of the best alignment
    if langInfo.AllowLongLong
        langInfo.MaxAlignment = hwInfo.LongLongNumBits / hwInfo.CharNumBits;
    else
        langInfo.MaxAlignment = hwInfo.LongNumBits / hwInfo.CharNumBits;
    end
end

if hasTargetSettings && ...
        isfield(currCompInfo.targetSettings, 'PtrDiffTypeKind') && ...
        isfield(currCompInfo.targetSettings, 'SizeTypeKind')
    if currCompInfo.targetSettings.PtrDiffTypeKind ==  "long_long"
        langInfo.PtrDiffTypeKind = 'longlong';
    else
        langInfo.PtrDiffTypeKind = currCompInfo.targetSettings.PtrDiffTypeKind;
    end
    if currCompInfo.targetSettings.SizeTypeKind ==  "ulong_long"
        langInfo.SizeTypeKind = 'ulonglong';
    else
        langInfo.SizeTypeKind = currCompInfo.targetSettings.SizeTypeKind;
    end
else
    if hwInfo.PointerNumBits==hwInfo.IntNumBits
        langInfo.SizeTypeKind = 'uint';
        langInfo.PtrDiffTypeKind = 'int';
    elseif hwInfo.PointerNumBits==hwInfo.LongNumBits
        langInfo.SizeTypeKind = 'ulong';
        langInfo.PtrDiffTypeKind = 'long';
    elseif hwInfo.PointerNumBits==hwInfo.ShortNumBits
        langInfo.SizeTypeKind = 'uint';
        langInfo.PtrDiffTypeKind = 'short';
    elseif langInfo.AllowShortLong && (hwInfo.PointerNumBits==hwInfo.ShortLongNumBits) && ...
            (hwInfo.LongLongNumBits ~= hwInfo.ShortLongNumBits)
        langInfo.SizeTypeKind = 'ushortlong';
        langInfo.PtrDiffTypeKind = 'shortlong';
    elseif hwInfo.PointerNumBits > hwInfo.LongNumBits
        langInfo.SizeTypeKind = 'ulonglong';
        langInfo.PtrDiffTypeKind = 'longlong';
    end
end

opts = internal.cxxfe.FrontEndOptions(hwInfo, langInfo);

% Use the header files resolved by the mex.Configuration
opts.Preprocessor.SystemIncludeDirs = [opts.Preprocessor.SystemIncludeDirs; currCompInfo.sysHeaderDirs(:)];
opts.Preprocessor.Defines = [opts.Preprocessor.Defines; currCompInfo.sysCompDefines(:)];
if args.addMWInc
    opts.Preprocessor.IncludeDirs = [opts.Preprocessor.IncludeDirs; currCompInfo.mwHeaderDirs(:)];
end
if isfield(currCompInfo, 'languageExtra')
    opts.Language.LanguageExtra = [ opts.Language.LanguageExtra ; currCompInfo.languageExtra(:) ];
end
if isfield(currCompInfo, 'unDefines')
    opts.Preprocessor.UnDefines = [opts.Preprocessor.UnDefines; currCompInfo.unDefines(:)];
end
if isfield(currCompInfo, 'preIncludes')
    opts.Preprocessor.PreIncludes = [opts.Preprocessor.PreIncludes; currCompInfo.preIncludes(:)];
end
opts.Preprocessor.SystemIncludeDirs = unique(opts.Preprocessor.SystemIncludeDirs, 'stable');
opts.Preprocessor.IncludeDirs = unique(opts.Preprocessor.IncludeDirs, 'stable');

isForCxx = strncmpi(opts.Language.LanguageMode, 'cxx', 3);
if isForCxx
    opts.Language.LanguageExtra{end+1} = '-tused';
end

% Need to detect INTEL compiler first
intelVersionDefine = '__INTEL_COMPILER=';
intelVersionIdx = strncmp(opts.Preprocessor.Defines, ...
    intelVersionDefine, numel(intelVersionDefine));
isIntel = any(intelVersionIdx);
intelDPCVersionDefine = '__INTEL_LLVM_COMPILER=';
intelDPCVersionIdx = strncmp(opts.Preprocessor.Defines, ...
    intelDPCVersionDefine, numel(intelDPCVersionDefine));
isIntelDPC = any(intelDPCVersionIdx);
isAnyIntel = isIntel || isIntelDPC;

% If __GNUC__ is defined, remove it (and __GNUC_MINOR__ & __GNUC_PATCHLEVEL__) and
% set --gcc (in C, or --g++ in C++) and --gnu_version instead.
gnucMajorIdx = strncmp(opts.Preprocessor.Defines, '__GNUC__=', 9);
clangMajorIdx = strncmp(opts.Preprocessor.Defines, '__clang_major__=', 16);
isClang = any(clangMajorIdx) && ~isAnyIntel;
if any(gnucMajorIdx)
    if isForCxx
        opts.Language.LanguageExtra{end+1} = '--g++';
    else
        opts.Language.LanguageExtra{end+1} = '--gcc';
    end

    gnucMajor = opts.Preprocessor.Defines{gnucMajorIdx};
    gnucMajor = sscanf(gnucMajor(10:end), '%d');

    gnucMinorIdx = strncmp(opts.Preprocessor.Defines, '__GNUC_MINOR__=', 15);
    if any(gnucMinorIdx)
        gnucMinor = opts.Preprocessor.Defines{gnucMinorIdx};
        gnucMinor = sscanf(gnucMinor(16:end), '%d');
    else
        gnucMinor = 0;
    end
    gnucPatchLevelIdx = strncmp(opts.Preprocessor.Defines, '__GNUC_PATCHLEVEL__=', 20);
    if any(gnucPatchLevelIdx)
        gnucPatchLevel = opts.Preprocessor.Defines{gnucPatchLevelIdx};
        gnucPatchLevel = sscanf(gnucPatchLevel(21:end), '%d');
    else
        gnucPatchLevel = 0;
    end

    opts.Preprocessor.Defines(gnucMajorIdx | gnucMinorIdx | gnucPatchLevelIdx) = [];

    gnuVersion = gnucMajor * 10000 + gnucMinor * 100 + gnucPatchLevel;
    if gnuVersion < 30200
        % This is the minimum for EDG.
        gnuVersion = 30200;
    end
    if isClang && gnuVersion < 40800
        % Although Clang is defining a gcc version number (4.2.1), this
        % version number does not really reflects its supported features
        gnuVersion = 40800;
    end

    if ~isForCxx && gnuVersion >= 70000
        % EDG doesn't register types like _Float32/_Float32x/_Float64/...
        % then just skip the inclusion of bits/floatn.h
        opts.Preprocessor.Defines{end+1} = '_BITS_FLOATN_H=1';
    end

    opts.Language.LanguageExtra(end+1:end+2) = { '--gnu_version'; sprintf('%d', gnuVersion) };

    % GCC like compilers have the following implicit define which must be
    % removed to let EDG parses:
    %     __has_include(STR)=__has_include__(STR)
    opts.Preprocessor.Defines(startsWith(opts.Preprocessor.Defines, '__has_include(')) = [];

    if isForCxx
        % Infer the c++ version from the define
        setCxxVersionFromDefine(opts);

        % If __GXX_RTTI is defined, remove it and set --rtti instead.
        idx = strncmp(opts.Preprocessor.Defines, '__GXX_RTTI=', 11);
        idx2 = strncmp(opts.Preprocessor.Defines, '__cpp_rtti=', 11);
        hasGxxRtti = any(idx);
        hasCppRtti = any(idx2);
        if hasGxxRtti || hasCppRtti
            opts.Language.LanguageExtra{end+1} = '--rtti';
            if hasGxxRtti
                opts.Preprocessor.Defines(idx) = [];
                % Need to update the index after removal
                if hasCppRtti
                    idx2 = strncmp(opts.Preprocessor.Defines, '__cpp_rtti=', 11);
                end
            end
            if hasCppRtti
                opts.Preprocessor.Defines(idx2) = [];
            end
        else
            opts.Language.LanguageExtra{end+1} = '--no_rtti';
        end

        % If __EXCEPTIONS is defined, remove it and set --exceptions instead.
        idx = strncmp(opts.Preprocessor.Defines, '__EXCEPTIONS=', 13);
        idx2 = strncmp(opts.Preprocessor.Defines, '__cpp_exceptions=', 17);
        hasExcept = any(idx);
        hasCppExcept = any(idx2);
        if hasExcept || hasCppExcept
            opts.Language.LanguageExtra{end+1} = '--exceptions';
            if hasExcept
                opts.Preprocessor.Defines(idx) = [];
                % Need to update the index after removal
                if hasCppExcept
                    idx2 = strncmp(opts.Preprocessor.Defines, '__cpp_exceptions=', 17);
                end
            end
            if hasCppExcept
                opts.Preprocessor.Defines(idx2) = [];
            end
        else
            opts.Language.LanguageExtra{end+1} = '--no_exceptions';
        end
    else
        % If __GNUC_GNU_INLINE__ is defined, remove it and set --gcc89_inlining instead.
        idx = strncmp(opts.Preprocessor.Defines, '__GNUC_GNU_INLINE__=', 20);
        if any(idx)
            opts.Language.LanguageExtra{end+1} = '--gcc89_inlining';
            opts.Preprocessor.Defines(idx) = [];
        end
    end

    clangMajorIdx = strncmp(opts.Preprocessor.Defines, '__clang_major__=', 16);
    if any(clangMajorIdx)
        % Add clang support
        opts.Language.LanguageExtra{end+1} = '--clang';

        % Get version number.
        clangMajor = opts.Preprocessor.Defines{clangMajorIdx};
        clangMajor = sscanf(clangMajor(17:end), '%d');

        clangMinorIdx = strncmp(opts.Preprocessor.Defines, '__clang_minor__=', 16);
        if any(clangMinorIdx)
            clangMinor = opts.Preprocessor.Defines{clangMinorIdx};
            clangMinor = sscanf(clangMinor(17:end), '%d');
        else
            clangMinor = 0;
        end
        clangPatchLevelIdx = strncmp(opts.Preprocessor.Defines, '__clang_patchlevel__=', 21);
        if any(clangPatchLevelIdx)
            clangPatchLevel = opts.Preprocessor.Defines{clangPatchLevelIdx};
            clangPatchLevel = sscanf(clangPatchLevel(22:end), '%d');
        else
            clangPatchLevel = 0;
        end

        clangVersion = clangMajor * 10000 + clangMinor * 100 + clangPatchLevel;
        if ismac()
            % __clang_major__, __clang_minor__ and __clang_patchlevel__ are
            % corresponding to the apple numbering, and not the EDG numbering
            % (I.e, Apple clang 5.0.0 is based on LLVM clang 3.3).
            % Converts the Apple version number to clang version number.
            % See https://en.wikipedia.org/wiki/Xcode#Xcode_7.0_-_11.x_(since_Free_On-Device_Development)
            % Follow the same version as in matlab/polyspace/configure/compiler_configuration/clang.xml
            if clangVersion >= 150000
                clangVersion = 160000;
            elseif clangVersion >= 140300
                clangVersion = 150000;
            elseif clangVersion >= 140000
                clangVersion = 140000;
            elseif clangVersion >= 130300
                clangVersion = 130000;
            elseif clangVersion >= 130000
                clangVersion = 120000;
            elseif clangVersion > 120000
                clangVersion = 110000;
            elseif clangVersion == 120000
                clangVersion = 100000;
            elseif clangVersion > 110000
                clangVersion = 90000;
            elseif clangVersion == 110000
                clangVersion = 80000;
            elseif clangVersion > 100000
                clangVersion = 70000;
            elseif clangVersion == 100000
                clangVersion = 60000;
            elseif clangVersion >= 90100
                clangVersion = 50000;
            elseif clangVersion >= 90000
                clangVersion = 40000;
            elseif clangVersion >= 80000
                clangVersion = 30500;
            elseif clangVersion >= 50000
                clangVersion = 30300;
            else
                clangVersion = 30200;
            end
        else
            opts.Preprocessor.Defines(clangMajorIdx | clangMinorIdx | clangPatchLevelIdx) = [];
        end

        opts.Language.LanguageExtra(end+1:end+2) = {'--clang_version'; sprintf('%d', clangVersion)};

        % Clang workarounds

        % clang has the 'restrict' keyword.
        opts.Language.LanguageExtra{end+1} = '--restrict';

        % If we set __BLOCKS__, the maci system headers will include definitions such as:
        % "
        % void    *bsearch_b(const void *, const void *, size_t,
        %             size_t, int (^)(const void *, const void *)) __OSX_AVAILABLE_STARTING(__MAC_10_6, __IPHONE_3_2);
        % "
        % which cannot be parsed by EDG (see the '^' token).
        opts.Preprocessor.Defines(strncmp('__BLOCKS__=', opts.Preprocessor.Defines, 9)) = [];

        if clangVersion < 30500 || ismember(opts.Language.LanguageMode, {'cxx', 'cxx03'})
            % Workarounds for parse errors in headers. The problem seems to be with the _LIBCPP_INLINE_VISIBILITY
            % macro. However, setting it to empty allows parsing the headers, but leads to link errors with the
            % instrumented code, so we define the _LIBCPP_HAS_NO_VARIADICS and _LIBCPP_HAS_NO_RVALUE_REFERENCES
            % macros to prevent parsing the problematic parts of the files.
            %
            % functional_base
            % "/Applications/Xcode5.0.2.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/../lib/c++/v1/__functional_base",
            % line 299: error: a function declarator with a trailing return type must be preceded by a simple "auto" type specifier
            % |  __invoke(_Fp&& __f, _A0&& __a0, _Args&& ...__args)
            % |  ^
            opts.Preprocessor.Defines{end+1} = '_LIBCPP_HAS_NO_VARIADICS=1';

            % iterator
            % "/Applications/Xcode5.0.2.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/../lib/c++/v1/iterator",
            % line 1786: error: a function declarator with a trailing return type must be preceded by a simple "auto" type specifier
            % |  begin(_Cp& __c) -> decltype(__c.begin())
            % |  ^
            opts.Preprocessor.Defines{end+1} = '_LIBCPP_HAS_NO_RVALUE_REFERENCES=1';
        end
        %        opts.Preprocessor.Defines{end+1} = '_LIBCPP_HAS_NO_TRAILING_RETURN';

        % Unsupported/unrecognized predefined macro
        opts.Preprocessor.Defines{end+1} = '__building_module(x)=0';
        opts.Preprocessor.Defines{end+1} = '__has_warning(x)=0';
    end

    if ~isfield(currCompInfo, 'targetSettings')
        if ~ispc()
            if computer("arch") == "maca64"
                % Be sure long double is well configured on mac ARM (g2917448)
                opts.Target.LongDoubleNumBits = 64;
            else
                opts.Target.LongDoubleNumBits = 128;
            end
        end
        opts.Language.WcharTypeKind = 'int';
    end

    % Filter-out some defines that are automatically set by EDG based on the command line options.
    opts.Preprocessor.Defines(strncmp('__VERSION__=', opts.Preprocessor.Defines, 12)) = [];
    opts.Preprocessor.Defines(strncmp('__GNUG__=', opts.Preprocessor.Defines, 9)) = [];
    opts.Preprocessor.Defines(strncmp('__GNUC_STDC_INLINE__=', opts.Preprocessor.Defines, 21)) = [];
    opts.Preprocessor.Defines(strncmp('__SIZE_TYPE__=', opts.Preprocessor.Defines, 14)) = [];
    opts.Preprocessor.Defines(strncmp('__PTRDIFF_TYPE__=', opts.Preprocessor.Defines, 17)) = [];
    opts.Preprocessor.Defines(strncmp('__WINT_TYPE__=', opts.Preprocessor.Defines, 14)) = [];
    opts.Preprocessor.Defines(strncmp('__CHAR16_TYPE__=', opts.Preprocessor.Defines, 16)) = [];
    opts.Preprocessor.Defines(strncmp('__CHAR32_TYPE__=', opts.Preprocessor.Defines, 16)) = [];

    % Special case for mingw64
    if any(strncmp(opts.Preprocessor.Defines, '__MINGW64__=', 11))
        % Some unsupported built-in
        opts.Preprocessor.Defines(strncmp(opts.Preprocessor.Defines, '__FXSR__', 8)) = [];

        % g1625418/g3402041: If __declspec(x) is not sniffed, add it anyway in order to parse MinGW headers.
        if isInfoFromPsConfigure
            opts.Preprocessor.Defines{end+1} = '__declspec(x)=__attribute__((x))';
        end

        if isForCxx
            opts.Language.LanguageExtra{end+1} = '--wchar_t_keyword';

            % g2905718 Fake built-ins for MinGW because of g2588767.
            opts.Language.LanguageExtra{end+1} = '--has_builtin=_InterlockedCompareExchangePointer';
            opts.Language.LanguageExtra{end+1} = '--has_builtin=_InterlockedExchangePointer';
        else
            % NOTE(eroy): WcharTypeKind could be inferred from the macro
            % "__SIZEOF_WCHAR_T__=d"
            opts.Preprocessor.Defines{end+1} = '_WCHAR_T_DEFINED=1';
            opts.Preprocessor.Defines{end+1} = 'wchar_t=unsigned short';
        end
        opts.Language.WcharTypeKind = 'ushort';

        opts.Language.LanguageExtra{end+1} = '--mingw64';
        if ~isfield(currCompInfo, 'targetSettings')
            opts.Target.LongDoubleNumBits = 128;
        end
    end

    % g3328303 Support ARM and some other built-ins in Gcc and clang modes.
    tmwBuiltins = fullfile(matlabroot, 'polyspace', 'verifier', 'extensions', 'tmw_builtins');
    opts.Preprocessor.SystemIncludeDirs{end+1} = tmwBuiltins;
    opts.Preprocessor.PreIncludes{end+1} = fullfile(tmwBuiltins, 'tmw_builtins.h');
    if any(strncmp(opts.Preprocessor.Defines, '__ARM_ARCH=', 11))
        opts.Language.LanguageExtra{end+1} = '--half_float_types';
    end
end

% If __LCC__ is defined, set --lcc.
% NOTE: could remove this logic but still keep it as-is to have parity
% with polyspace/src/psprofile/cli/psprofcmd_instrument/PsConfigureUtils.cpp
% in case polyspace-configure "sniffed" a LCC build...
lccIdx = strncmp(opts.Preprocessor.Defines, '__LCC__=', 8);
if any(lccIdx)
    opts.Language.LanguageExtra{end+1} = '--lcc';
    opts.Language.LanguageExtra{end+1} = '--c99_bool_is_keyword';
    if ~isfield(currCompInfo, 'targetSettings')
        opts.Target.LongDoubleNumBits = 128;
    end
end

% If _MSC_VER is defined, remove it and set --microsoft and --microsoft_version instead.
mscVerIdx = strncmp(opts.Preprocessor.Defines, '_MSC_VER=', 9);
mscVer = [];
if any(mscVerIdx)
    if ~isClang
        opts.Language.LanguageExtra{end+1} = '--microsoft';

        mVer = opts.Preprocessor.Defines{mscVerIdx};
        mVer(1:9) = [];
        opts.Preprocessor.Defines(mscVerIdx) = [];
        opts.Language.LanguageExtra{end+1} = ['--microsoft_version=', mVer];

        mscVer = sscanf(mVer, '%d');

        % If _MSC_FULL_VER is defined, remove it and set --microsoft_build_number instead.
        idx = strncmp(opts.Preprocessor.Defines, '_MSC_FULL_VER=', 14);
        if any(idx)
            mBuildNum = opts.Preprocessor.Defines{idx};
            mBuildNum(1:14) = [];
            mBuildNum(1:numel(mVer)) = [];
            opts.Language.LanguageExtra{end+1} = ['--microsoft_build_number=', mBuildNum ];
            opts.Preprocessor.Defines(idx) = [];
        end
    end

    if isForCxx
        % Infer the c++ version from the define
        setCxxVersionFromDefine(opts, mscVer, isClang);

        % If __cplusplus_cli is defined, remove it and set --cppcli instead.
        idx = strncmp(opts.Preprocessor.Defines, '__cplusplus_cli=', 16);
        if any(idx)
            opts.Language.LanguageExtra{end+1} = '--cppcli';
            opts.Preprocessor.Defines(idx) = [];
        end

        % If _CPPRTTI is defined, remove it and set --rtti instead.
        idx = strncmp(opts.Preprocessor.Defines, '_CPPRTTI=', 9);
        if any(idx)
            opts.Language.LanguageExtra{end+1} = '--rtti';
            opts.Preprocessor.Defines(idx) = [];
        end

        % If _NATIVE_NULLPTR_SUPPORTED is defined, remove it and set --nullptr instead.
        idx = strncmp(opts.Preprocessor.Defines, '_NATIVE_NULLPTR_SUPPORTED=', 26);
        if any(idx)
            opts.Language.LanguageExtra{end+1} = '--nullptr';
            opts.Preprocessor.Defines(idx) = [];
        end

        % If _WCHAR_T_DEFINED is defined, remove it and set --wchar_t_keyword instead.
        idx = strncmp(opts.Preprocessor.Defines, '_WCHAR_T_DEFINED=', 17);
        if any(idx)
            opts.Language.LanguageExtra{end+1} = '--wchar_t_keyword';
            opts.Preprocessor.Defines(idx) = [];
        end

        if isempty(mscVer) || mscVer < 1900
            opts.Language.LanguageExtra{end+1} = '--no_uliterals';
        end
        opts.Language.LanguageExtra{end+1} = '--typeinfo_in_global_namespace';
    end

    % If _CHAR_UNSIGNED is defined, set --unsigned_chars.
    idx = strncmp(opts.Preprocessor.Defines, '_CHAR_UNSIGNED=', 15);
    if any(idx)
        opts.Language.LanguageExtra{end+1} = '--unsigned_chars';
    end

    % Filter-out some defines that are automatically set by EDG based on the command line options.
    opts.Preprocessor.Defines(strncmp('__cplusplus=', opts.Preprocessor.Defines, 12)) = [];
    opts.Preprocessor.Defines(strncmp('_MSC_EXTENSIONS=', opts.Preprocessor.Defines, 16)) = [];
    opts.Preprocessor.Defines(strncmp('_WIN32=', opts.Preprocessor.Defines, 7)) = [];
    opts.Preprocessor.Defines(strncmp('_INTEGRAL_MAX_BITS=', opts.Preprocessor.Defines, 19)) = [];
    opts.Preprocessor.Defines(strncmp('_NATIVE_WCHAR_T_DEFINED=', opts.Preprocessor.Defines, 24)) = [];
    opts.Preprocessor.Defines(strncmp('__EDG__=', opts.Preprocessor.Defines, 8)) = [];
    opts.Preprocessor.Defines(strncmp('__EDG_VERSION__=', opts.Preprocessor.Defines, 16)) = [];

    % Workarounds for Intel compiler (check "old" version first, then check
    % the new DPC version based on LLVM)
    % NOTE: Intel2023 is already based on LLVM but defines __INTEL_COMPILER, then
    %       the "old" settings are applied similarly. For Intel2024, __INTEL_COMPILER
    %       is no longer defined, only __INTEL_LLVM_COMPILER is defined.
    %       Apply the same settings to the "old" and "new" versions, then adjust
    %       the "old" version number to match the same logic as the "new".
    if isAnyIntel
        % Need to recompute the indexes because some defines have been
        % removed!
        intelVersionIdx = strncmp(opts.Preprocessor.Defines, ...
            intelVersionDefine, numel(intelVersionDefine));
        intelDPCVersionIdx = strncmp(opts.Preprocessor.Defines, ...
            intelDPCVersionDefine, numel(intelDPCVersionDefine));

        if isIntel
            intelVersion = opts.Preprocessor.Defines{intelVersionIdx};
            intelVersion = sscanf(intelVersion(numel(intelVersionDefine)+1:end), '%d');
            if ~isempty(intelVersion)
                intelVersion = intelVersion*10000;
            end
        else
            intelVersion = opts.Preprocessor.Defines{intelDPCVersionIdx};
            intelVersion = sscanf(intelVersion(numel(intelDPCVersionDefine)+1:end), '%d');
        end
        if ~isempty(intelVersion)
            if intelVersion <= 12000000
                if isForCxx
                    opts.Language.LanguageExtra{end+1} = '--no_nullptr';
                end
                opts.Preprocessor.UnDefines{end+1} = '_MSC_EXTENSIONS';
            elseif intelVersion >= 17000000
                % There is a bug in the Intel's headers, see:
                % https://software.intel.com/en-us/forums/intel-c-compiler/topic/799630
                opts.Preprocessor.Defines{end+1} = 'ldexpf=__MS_ldexpf';
                if intelVersion == 18000000 && isForCxx
                    % There is a bug in the Intel's headers, see:
                    % https://software.intel.com/en-us/forums/intel-c-compiler/topic/752371
                    opts.Preprocessor.Defines{end+1} = '__DFP754_H_INCLUDED=1';
                end
            end
            if intelVersion >= 16000000
                % since 16.0, no longer checks header files for intrinsic
                % function declarations. Since this may make the EDG-parser
                % fail, force the generation of function prototypes
                opts.Preprocessor.Defines{end+1} = '__INTEL_COMPILER_USE_INTRINSIC_PROTOTYPES=1';
            end
            if isIntelDPC
                opts.Preprocessor.Defines{end+1} = '_CRT_SECURE_NO_WARNINGS';
            end
        end
    end

    % Workarounds for Visual Studio
    if ~isempty(mscVer)
        if isForCxx
            if mscVer <= 1500
                % Visual Studio 8.0
                opts.Preprocessor.UnDefines{end+1} = '_MSC_EXTENSIONS';
            elseif mscVer >= 1920
                % Visual Studio 2019 and updates
                if isAnyIntel
                    % Those macros enable some features that are not well emitted
                    % by cp_gen_be that causes mex to fail for Intel+MSVC headers
                    opts.Preprocessor.Defines{end+1} = '_HAS_CONDITIONAL_EXPLICIT=0';
                    opts.Preprocessor.Defines{end+1} = '_HAS_EXACT_COMPOUND_REQUIREMENT=0';
                    opts.Preprocessor.Defines{end+1} = '_HAS_NODISCARD=0';
                end
            end
        else
            if mscVer >= 1800
                opts.Language.LanguageMode = 'c99';
            end
        end
    end
end

if strcmp(opts.Language.LanguageMode, 'c')
    % If __STDC_VERSION__ is defined, set --c99 or --c11 when appropriate.
    stdcVersionIdx = strncmp(opts.Preprocessor.Defines, '__STDC_VERSION__=', 17);
    if any(stdcVersionIdx)
        stdcVersion = opts.Preprocessor.Defines{stdcVersionIdx};
        stdcVersion = sscanf(stdcVersion(18:end), '%d');
        if stdcVersion >= 202311
            opts.Language.LanguageMode = 'c23';
        elseif stdcVersion >= 201710
            opts.Language.LanguageMode = 'c17';
        elseif stdcVersion >= 201112
            opts.Language.LanguageMode = 'c11';
        elseif stdcVersion >= 199901
            opts.Language.LanguageMode = 'c99';
        end

        % Filter-out the __STDC_VERSION__ define if EDG is going to set it automatically based on
        % the command line options.
        if ~any(mscVerIdx) && (~any(gnucMajorIdx) || strcmp(opts.Language.LanguageMode, 'c'))
            opts.Preprocessor.Defines(stdcVersionIdx) = [];
        end
    end
end

if args.addMWInc 
    opts.Preprocessor.Defines = [opts.Preprocessor.Defines; currCompInfo.mwCompDefines(:)];
end 

if ((~isInfoFromPsConfigure) || ...
    (isfield(currCompInfo, 'languageExtra') && ...
     any(strcmp(currCompInfo.languageExtra, '--syntax_extensions_compiler'))))
    return
end

% Match other supported compilers/dialects based on well known compiler implicit defines.
% Some dialects can be enabled in addition to one EDG builtin dialect. For example:
% The TI C2000 compiler has its own non-ANSI extensions and provides a --gcc option
% that also enables gcc's extensions.

compilerDefinesXmlFile = fullfile(matlabroot, 'polyspace', 'configure', 'compiler_defines.xml');
parser = matlab.io.xml.dom.Parser;
xmlData = parser.parseFile(compilerDefinesXmlFile);
xmlDoc = xmlData.getDocumentElement();

% Cache all the dialect nodes
dialect2Node = containers.Map('KeyType', 'char', 'ValueType', 'any');
dialectNodes = xmlDoc.getElementsByTagName('dialect');
for ii = 1:getLength(dialectNodes)
    node = dialectNodes.item(ii-1);
    if node.hasAttribute('name')
        dialect2Node(node.getAttribute('name')) = node;
    end
end

dialect = '';
compiler = '';

% Cache all define names for dialects with an 'and' attribute. If compiler_defines
% has nodes like
%    <define name="__foo" dialect="great" and="1"/>
%    <define name="__bar" dialect="great" and="1"/>
% then dialect 'great' is matched only if all define nodes for 'great' are
% matched. That is, if both '__foo' and '__bar' are in Preprocessor.Defines.
dialect2required = containers.Map('KeyType', 'char', 'ValueType', 'any');
defineNodes = xmlData.evaluate('./define', matlab.io.xml.dom.XPathResult.ORDERED_NODE_SNAPSHOT_TYPE);
numDefineNodes = defineNodes.getSnapshotLength();
for ii = 1:numDefineNodes
    defineNodes.snapshotItem(ii - 1);
    defineNode = defineNodes.getNodeValue();
    if defineNode.hasAttribute('dialect') && ...
        defineNode.hasAttribute('and') && istrue(defineNode.getAttribute('and'))
        dialectName = defineNode.getAttribute('dialect');
        name = defineNode.getAttribute('name');
        if dialect2required.isKey(dialectName)
            names = dialect2required(dialectName);
            dialect2required(dialectName) = [names, name];
        else
            dialect2required(dialectName) = {name};
        end
    end
end

% Go through the list of well known defines.
for ii = 1:numDefineNodes
    defineNodes.snapshotItem(ii - 1);
    defineNode = defineNodes.getNodeValue();
    name = defineNode.getAttribute('name');
    defIdx = strncmp(opts.Preprocessor.Defines, [name '='], numel(name) + 1);
    if ~any(defIdx)
        continue
    end

    % If the define was found and matches a specific compiler, we have a compiler match.
    if defineNode.hasAttribute('compiler')
        dialect = '';
        compiler = defineNode.getAttribute('compiler');
        break
    end

    if ~defineNode.hasAttribute('dialect') || ...
        ~matchAllDefinesForDialect(defineNode, opts.Preprocessor.Defines, dialect2required)
        continue
    end

    % If the define was found and matches one of multiple dialects, go through the list of
    % well known defines that are specific to those dialects.
    dialects = strsplit(defineNode.getAttribute('dialect'), ',');
    for jj = 1:numel(dialects)
        if ~dialect2Node.isKey(dialects{jj})
            continue
        end
        dialectNode = dialect2Node(dialects{jj});
        dialectDefineNodes = dialectNode.getElementsByTagName('define');

        numDialectDefineNodes = dialectDefineNodes.getLength();
        for kk = 1:numDialectDefineNodes
            defineNode = dialectDefineNodes.item(kk - 1);
            name = defineNode.getAttribute('name');
            defIdx = strncmp(opts.Preprocessor.Defines, [name '='], numel(name) + 1);
            if ~any(defIdx)
                continue
            end

            % If the define was found, we have a compiler match.
            dialect = dialects{jj};
            if defineNode.hasAttribute('compiler')
                compiler = defineNode.getAttribute('compiler');
                break
            end
        end
    end
    if ~isempty(compiler)
        break
    end

    % If no define was found, we have a dialect match only.
    % Go through the remaining defines in order to look for a better
    % (e.g. compiler) match.
    if isempty(dialect) && isscalar(dialects)
        dialect = dialects{1};
    end
end

if ~(isempty(dialect) && isempty(compiler))
    syntaxExtensionsRoot = fullfile(matlabroot, 'polyspace', 'verifier', 'extensions');
    if isfile(fullfile(syntaxExtensionsRoot, [dialect '.xml']))
        if ~isempty(dialect)
            opts.Language.LanguageExtra = [opts.Language.LanguageExtra; {'--syntax_extensions_compiler'; dialect}];
        end
        if ~isempty(compiler)
            opts.Language.LanguageExtra = [opts.Language.LanguageExtra; {'--syntax_extensions_target'; compiler}];
        end
        syntaxExtensionsXmlFile = fullfile(syntaxExtensionsRoot, 'extensions.xml');
        opts.Language.LanguageExtra = [opts.Language.LanguageExtra; {'--syntax_extensions_file'; syntaxExtensionsXmlFile}];
    end
end
end


%% ------------------------------------------------------------------------
function ret = matchAllDefinesForDialect(node, defines, dialect2required)
% If node has an 'and' attribute, then all defines for that dialect must be
% matched.
ret = true; % Ok if no 'and' attribute present.
if node.hasAttribute('and') && istrue(node.getAttribute('and'))
    ret = false;
    dialect = node.getAttribute('dialect');
    if dialect2required.isKey(dialect)
        requiredDefines = dialect2required(dialect);
        for ii = 1:numel(requiredDefines)
            name = requiredDefines{ii};
            defIdx = strncmp(defines, [name '='], numel(name) + 1);
            if ~any(defIdx)
                return
            end
        end
        ret = true;
    end
end
end

%% ------------------------------------------------------------------------
function ret = istrue(attrVal)
    ret = strcmp(attrVal, '1') || strcmp(attrVal, 'true');
end

%% ------------------------------------------------------------------------
function setCxxVersionFromDefine(opts, mscVer, isClang)

if nargin < 3
    isClang = false;
end
if nargin < 2
    forMsvc = false;
    mscVer = [];
else
    forMsvc = true;
end

% The c++ standard version
cplusplusVer = 0;

% Infer the version from the _MSVC_LANG macro for Intel/MSVC
if forMsvc
    idx = find(strncmp(opts.Preprocessor.Defines, '_MSVC_LANG=', 11), 1);
    if ~isempty(idx)
        verStr = opts.Preprocessor.Defines{idx};
        cplusplusVer = sscanf(verStr(12:end), '%d');
    end
end

% Infer the version from the __cplusplus macro For GNU/CLANG
% (or MSVC/INTEL if _MSVC_LANG is not found)
idx = find(strncmp(opts.Preprocessor.Defines, '__cplusplus=', 12), 1);
if cplusplusVer == 0 && ~isempty(idx)
    verStr = opts.Preprocessor.Defines{idx};
    cplusplusVer = sscanf(verStr(13:end), '%d');
end
opts.Preprocessor.Defines(idx) = [];

if cplusplusVer >= 202302
    opts.Language.LanguageMode = 'cxx23';
    if forMsvc && ~isClang
        opts.Language.LanguageExtra{end+1} = '--ms_c++latest';
    end
elseif cplusplusVer >= 202002
    opts.Language.LanguageMode = 'cxx20';
    if forMsvc && ~isClang
        opts.Language.LanguageExtra{end+1} = '--ms_c++20';
    end
elseif cplusplusVer >= 201703
    opts.Language.LanguageMode = 'cxx17';
    if forMsvc && ~isClang
        if cplusplusVer >= 201705
            opts.Language.LanguageExtra{end+1} = '--ms_c++20';
        else
            opts.Language.LanguageExtra{end+1} = '--ms_c++17';
        end
        % Need to activate latest feature depending on C++ version
        if cplusplusVer > 201703
            opts.Language.LanguageExtra{end+1} = '--ms_c++latest';
        end
    else
        if cplusplusVer > 201703
            % gcc/clang c++2a mode
            opts.Language.LanguageMode = 'cxx20';
        end
    end
% g2505726: Even though _MSVC_LANG=201402L with MSVC2015, we must not set --ms_c++14 (EDG forbids it).
elseif (cplusplusVer >= 201402) && (~forMsvc || (~isempty(mscVer) && (mscVer >= 1903)))
    opts.Language.LanguageMode = 'cxx14';
    if forMsvc && ~isClang
        opts.Language.LanguageExtra{end+1} = '--ms_c++14';
    end
elseif cplusplusVer >= 201103
    opts.Language.LanguageMode = 'cxx11';
elseif cplusplusVer==199711
    % C++03 is pretty similar to C++98 and passing this option to EDG
    % will disable all features not supported in this mode
    opts.Language.LanguageMode = 'cxx03';
else
    % Visual Studio 2015 and later (for version >= 1903, EDG
    % automatically sets the standard). Force c++11 if no other
    % standard has been already specified
    if forMsvc && ~isempty(mscVer) && mscVer >= 1900 && mscVer < 1903
        opts.Language.LanguageMode = 'cxx11';
    end
end

end

% LocalWords:  lang cxxfe cxx maci linux EDG libc libcxx defs GLIBCXX ushortlong shortlong floatn
% LocalWords:  microsoft predef msvc typeinfo decltype tused ulong ulonglong Ps intel ldexpf DFP cp
% LocalWords:  longlong LIBCPP GXX va GNUC WCHAR LDBL GTHREAD BUILTINS DENORM NODISCARD psprofile
% LocalWords:  utils Dirs Endianness unDefines Ps Dirs Endianness unDefines Ps psprofcmd mexcfg
% LocalWords:  PATCHLEVEL EDGcpfe Dirs Endianness unDefines PATCHLEVEL EDGcpfe currCompInfo maca
% LocalWords:  rtti patchlevel LLVM bsearch OSX IPHONE VARIADICS RVALUE Xcode MinGW DPC declspec
% LocalWords:  Toolchains xctoolchain usr declarator Fp Cp GNUG STDC PTRDIFF builtins
% LocalWords:  WINT mingw FXSR wchar eroy ushort MSC cli cppcli CPPRTTI
% LocalWords:  uliterals gcc's
