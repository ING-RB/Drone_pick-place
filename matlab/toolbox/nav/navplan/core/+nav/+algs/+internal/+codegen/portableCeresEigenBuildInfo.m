function portableCeresEigenBuildInfo(buildInfo,buildConfig)
%This function is for internal use only. It may be removed in the future.

% portableCeresEigenBuildInfo performs following operations
%       (1) headers: includes all ceres-solver and eigen header files.
%       (2) sources: includes all ceres-solver source cpp files.
%       (3) compile flags: add all required compile flags.
%       (4) defines: defines all required compile time constants.

% Copyright 2022-2024 The MathWorks, Inc.

% Verify if the current host is the target
isHost = buildConfig.isMatlabHostTarget();

% gnuCompilerOnWin is true while using MinGW64 compiler on windows
gnuCompilerOnWin = ispc && contains(buildConfig.ToolchainInfo.Name, {'gcc','g++','gnu', 'mingw'},'IgnoreCase',true);
% intelCompilerOnWin is true while using any intel studio compiler like
% INTELC19MSVS2019, INTELC20MSVS19, INTELC18MSVS2017 etc.
intelCompilerOnWin = ispc && contains(buildConfig.ToolchainInfo.Name, {'intel'},'IgnoreCase',true);
if gnuCompilerOnWin || intelCompilerOnWin
    % only visual studio compilers are supported on windows
    error(message('nav:navalgs:factorgraph:UnsupportedWindowsCompiler'));
end

% Always build with full sources (for both host and target codegen)
buildInfo.addSourcePaths({fullfile(matlabroot,'toolbox', ...
                                   'shared','ceres','builtins','libsrc','cerescodegen')});
buildInfo.addSourceFiles({'cerescodegen_api.cpp','factor_graph.cpp','imu_factor.cpp', 'common_factors_2.cpp', 'utilities.cpp', 'marginal_factor.cpp'});

% Add factor graph builtin headers.
builtinPath = fullfile(matlabroot, 'extern', 'include', 'ceres');
buildInfo.addIncludePaths(builtinPath);
builtinHeaderFiles = dir(fullfile(builtinPath, '*.hpp'));
arrayfun(@(s)buildInfo.addIncludeFiles(fullfile(s.folder,s.name)), ...
    builtinHeaderFiles, 'UniformOutput', false);

% Define _USE_MATH_DEFINES for math definitions.
buildInfo.addDefines('_USE_MATH_DEFINES', 'OPTS');
% Define to export symbols from ceres
buildInfo.addDefines('CERES_BUILDING_SHARED_LIBRARY', 'OPTS');
% Define to silence deprecation warning similar to ceres builtins
buildInfo.addDefines('_SILENCE_CXX17_NEGATORS_DEPRECATION_WARNING');
% Define to set the maximum message severity level to be logged similar to
% ceres builtins. This is needed to generate consistent verbose during
% normal run and code-generation.
buildInfo.addDefines('MAX_LOG_LEVEL=1');

% For minimal header search during packNGo eigen requires the following
% define which is supposed to be defined by compiler.
arch = computer("arch");

% ceres-solver requires c++14 standard. During mex and sfun
% targets c++11 language standard is used by default
% (g2663719). so we need to explicitly specify the required c++
% language standard during mex generation. In all the other
% cases coder uses c++14 by default.
addCppStandardFlag = false;
if any(strcmp(buildConfig.CodeGenTarget, {'mex','sfun'}))
    % if the codegen target is 'mex' or 'sfun'
    if ispc
        % 'win64' platform
        if gnuCompilerOnWin
            % MinGW
            % add cpp standard flag only while using MinGW
            % compiler on windows
            addCppStandardFlag = true;
        end
    else
        if strcmp(arch,'glnxa64') || strcmp(buildConfig.CodeGenTarget, 'mex')
            % on 'glnxa64' or on 'maci64' only during mex generation
            % add cpp standard flag
            addCppStandardFlag = true;
        end
    end
end

if addCppStandardFlag
    % add required cpp standard flag
    cppStandardFlag = '-std=c++14';
    buildInfo.addCompileFlags(cppStandardFlag,'CPP_OPTS');
end

% Disable expected compiler warnings while building ceres using visual
% studio compilers on windows and mac platforms. Disable warnings only when
% the target is current host machine.
if ispc && (~gnuCompilerOnWin) && (~intelCompilerOnWin) && isHost
    % Disable signed/unsigned int conversion warnings.
    buildInfo.addCompileFlags("/wd4018");
    % Disable warning about using struct/class for the same symbol.
    buildInfo.addCompileFlags("/wd4099");
    % Disable warning about unreferenced formal parameter
    buildInfo.addCompileFlags("/wd4100");
    % Disable warning about conditional expression is constant
    buildInfo.addCompileFlags("/wd4127");
    % Disable warning about int64 to int32 conversion.
    buildInfo.addCompileFlags("/wd4244");
    % Disable warning about usage of STL types in DLL interfaces
    buildInfo.addCompileFlags("/wd4251");
    % Disable warning about conversion from 'size_t' to 'int'
    buildInfo.addCompileFlags("/wd4267");
    % Disable warning about hiding previous local declaration
    buildInfo.addCompileFlags("/wd4456");
    % Disable warning about the insecurity of using "std::copy".
    buildInfo.addCompileFlags("/wd4996");
    % Disable performance warning about int-to-bool conversion.
    buildInfo.addCompileFlags("/wd4800");
    % Add compilation flag to address number of sections exceeded object
    % file format limit
    buildInfo.addCompileFlags("/bigobj");

% Disable expected warnings while building ceres on mac platform
elseif ismac && isHost
    % Disable warning about inconsistent missing override
    buildInfo.addCompileFlags("-Wno-inconsistent-missing-override");
end

% Shared robotics 3rdparty source folder
externalSourcePath = fullfile(matlabroot, 'toolbox', 'shared',...
    'robotics', 'externalDependency');

% ceres and eigen header only libraries are required for FactorIMU.
% Extract all eigen header file names recursively with .h extension and
% extensionless.
eigenIncludePath = fullfile(externalSourcePath, 'eigen', 'include');
eigenHeaderFiles = [dir(fullfile(eigenIncludePath, 'eigen3','Eigen', '**', '*'));...
    dir(fullfile(eigenIncludePath, 'eigen3','unsupported', '**', '*'))];
eigenHeaderFiles = eigenHeaderFiles(~[eigenHeaderFiles.isdir]);

% Add eigen includes to buildInfo
buildInfo.addIncludePaths({fullfile(externalSourcePath, 'eigen', 'include', 'eigen3')});
arrayfun(@(s)buildInfo.addIncludeFiles(fullfile(s.folder,s.name)), ...
    eigenHeaderFiles, 'UniformOutput', false);

% Find all ceres files recursively.
% (it contains only .h headers)
ceresPublicIncludePath = fullfile(externalSourcePath, 'ceres', arch, 'include');
ceresPublicHeaderFiles = dir(fullfile(ceresPublicIncludePath, '**', '*.h'));
ceresInternalIncludePath = fullfile(externalSourcePath, 'ceres', arch, 'internal');
ceresInternalHeaderFiles = dir(fullfile(ceresInternalIncludePath, '**', '*.h'));
ceresIncludeFiles = [ceresPublicHeaderFiles; ceresInternalHeaderFiles];

% Add ceres includes to buildInfo
buildInfo.addIncludePaths(unique({ceresPublicIncludePath,ceresInternalIncludePath,...
    fullfile(ceresPublicIncludePath,'ceres','internal','miniglog')}));
arrayfun(@(s)buildInfo.addIncludeFiles(fullfile(s.folder,s.name)), ceresIncludeFiles, 'UniformOutput', false);

% Add ceres sources to buildInfo
ceresInternalSourceFiles = dir(fullfile(ceresInternalIncludePath, '**', '*.cpp'));
buildInfo.addSourcePaths({ceresInternalSourceFiles.folder});
arrayfun(@(s)buildInfo.addSourceFiles(s.name), ceresInternalSourceFiles, 'UniformOutput', false);

% Add license files.
buildInfo.addNonBuildFiles(fullfile(externalSourcePath,"eigen","eigen.notice"));
buildInfo.addNonBuildFiles(fullfile(externalSourcePath,"eigen","eigen_BSD.rights"));
buildInfo.addNonBuildFiles(fullfile(externalSourcePath,"eigen","eigen_MPL2.rights"));
buildInfo.addNonBuildFiles(fullfile(externalSourcePath,"ceres",arch,"ceres-solver.rights"));
end
