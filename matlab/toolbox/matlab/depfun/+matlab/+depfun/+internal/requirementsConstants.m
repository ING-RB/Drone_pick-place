classdef requirementsConstants
% This class provides constants frequently used by files in REQUIREMENTS.
% 
% Accessing a constant property is 0.000010 ms faster each time 
% than accessing a persistent variable. This is achieved by the caching 
% mechanism of MCOS; every constant property gets initialized only once.
%
% Different sets of relevant constants are grouped, so this file can be
% easily split, if some constants need to be shared by files outside
% REQUIREMENTS in the future.

%   Copyright 2014-2024 The MathWorks, Inc.

    properties (Constant)
        % TO DO: Move other frequently used common constants here.
        % For example, getenv('MW_TARGET_ARCH'), db locations, etc.
        
        % Comment out the following lines for now, because WHICH uses
        % hard-coded English strings.
        % They are not removed because they may be useful in the future in
        % case the WHICH result is internationalized.
%         BuiltInStr = getString(message('MATLAB:depfun:req:BuiltIn'));
%         lBuiltInStr = length(getString(message('MATLAB:depfun:req:BuiltIn')));
%         
%         BuiltInStrAndATrailingSpace = [getString(message('MATLAB:depfun:req:BuiltIn')) ' '];
%         lBuiltInStrAndATrailingSpace = length([getString(message('MATLAB:depfun:req:BuiltIn')) ' ']);
%         
%         MethodStr = getString(message('MATLAB:depfun:req:Method'));
%         lMethodStr = length(getString(message('MATLAB:depfun:req:Method')));
%         
%         IsABuiltInMethodStr = getString(message('MATLAB:ClassText:whichBuiltinMethod',''));     
%         lIsABuiltInMethodStr = length(getString(message('MATLAB:ClassText:whichBuiltinMethod','')));
%         
%         ConstructorStr = getString(message('MATLAB:ClassText:whichConstructor',''));
%         lConstructorStr = length(getString(message('MATLAB:ClassText:whichConstructor','')));
        
        BuiltInStr = 'built-in';
        lBuiltInStr = length('built-in');
        
        % This is solely for performance.
        BuiltInStrAndATrailingSpace = 'built-in ';
        lBuiltInStrAndATrailingSpace = length('built-in ');
        
        MethodStr = 'method';
        lMethodStr = length('method');
        
        IsABuiltInMethodStr = ' is a built-in method';
        lIsABuiltInMethodStr = length(' is a built-in method');
        
        ConstructorStr = ' constructor';
        lConstructorStr = length(' constructor');
    end
    
    properties (Constant)
        FileSep = filesep;        
        MatlabRoot = [matlabroot filesep];
        canonicalMatlabRootPattern = init_canonical_matlabroot_pattern();
        isPC = ispc;

        req_dir = fullfile(fileparts(mfilename('fullpath')));
        arch = initArch();

        pcm_db_prefix = 'pcm_';
        pcm_db_postfix = '_db';
    end
    
    properties (Constant)
        mcr_pid_min = 35000;
        mcr_pid_max = 35999;
        full_mcr_pid = 1000;
        base_mcr_pid_min = 35000;
        base_mcr_pid_max = 35100;
        base_toolbox_addin_pid_max = 35300;
        
        % Every deployed application depends on the smallest MCR,
        % which is MATLAB runtime - Numerics now.
        required_min_product_mcr = 35010;
        % Every target depends on MATLAB, except MCR target.
        required_min_product_other = 1;
        
        % MCR external product ids
        mcr_core_pid = 35000;
        mcr_non_graphics_pid = 35003;
        mcr_graphics_pid = 35002;
        mcr_numerics_pid = 35010;
        mcr_jmi_pid = 35011;
        mcr_raccel_pid = 35274;
        mcr_gpu_pid = 35380;
        base_runtimes = {35000, 35002, 35003,35010};
    end
    
    properties (Constant)
        matlabBuiltinClasses =  { ...
                'cell';'char';'double';'int8';'int16';'int32';'int64'; ... %'handle';
                'logical';'opaque';'single';'struct'; ...
                'uint8';'uint16';'uint32';'uint64' ...
                };
        matlabBuiltinClassSet = dictionary( ...
                string([ ...
                "cell";"char";"double";"int8";"int16";"int32";"int64"; ... %'handle';
                "logical";"opaque";"single";"struct"; ...
                "uint8";"uint16";"uint32";"uint64" ...
                ]), ...
                true(15,1));
        specialClassSet = {'gpuArray' 'distributed' 'codistributed' 'tall'};
    end

    properties (Constant)
        % The two lists below are ordered by precedence (high to low).
        analyzableMatlabFileExt = {'.mlapp' '.mlx' '.m'};
        executableMatlabFileExt = {['.' mexext] '.mlapp' '.mlx' '.p' '.m'};
        
        % The two lists below are orderred by reversed precedence (low to
        % high). They are useful when precedence is not important. Newly
        % introduced file types (higher precedence) do not exist as widely
        % as traditional file types (lower precedence). Checking file types
        % in this order benefits performance.
        analyzableMatlabFileExt_reverseOrder = {'.m' '.mlx' '.mlapp'};
        executableMatlabFileExt_reverseOrder = {'.m' '.p' '.mlx' '.mlapp' ['.' mexext]};
        
        % Size of the two lists regardless the order
        analyzableMatlabFileExtSize = 3;
        executableMatlabFileExtSize = 5;
        
        % regexp file extension pattern
        analyzableMatlabFileExtPat = '\.(m|mlx|mlapp)$';
        executableMatlabFileExtPat = ['\.(m|p|mlx|mlapp|' mexext ')$'];
        
        % Correspondent unordered fields in the WHAT result. (There are 
        % more fileds in the WHAT result, but REQURIEMENTS does not care.)
        whatFields = {'mex' 'mlapp' 'mlx' 'm' 'p'};
        
        % Data file extensions
        dataFileExt = {'.fig' '.mat'};
        dataFileExtSize = 2;
        
        % Stateflow file extension
        stateflowFileExt = '.sfx';
    end

    properties (Constant)
        isSimulinkCompilerInstalled = ~isempty(ver('simulinkcompiler'));
        isSimulinkCompilerAccessible = license('test','Simulink_Compiler') ...
            && matlab.depfun.internal.requirementsConstants.isSimulinkCompilerInstalled;
        
        % Simulink model file extension
        simulinkModelExt = {'.slx' '.mdl'};
        simulinkDataDictionaryExt = '.sldd';
        analyzableSimulinkFileExt = [matlab.depfun.internal.requirementsConstants.simulinkModelExt ...
            matlab.depfun.internal.requirementsConstants.simulinkDataDictionaryExt];
    end

    properties (Constant)
        pcm_nv = init_pcm_navigator();
    end

    % a array contains all undeployable built in functions 
    % takes ~1s to fill the list
    properties (Constant)
        undeployableBuiltins = initUndeployableBuiltins();
    end 
    
    properties (Constant)
        %web app unsupported functions
        WebAppMultiwindowUnsupportedList={
            'toolbox/matlab/uitools/uitools/dialog.m';...
            'toolbox/matlab/uitools/uitools/msgbox.m';...
            'toolbox/matlab/uitools/uitools/errordlg.m';...
            'toolbox/matlab/uitools/uitools/warndlg.m';...
            'toolbox/matlab/uitools/uitools/helpdlg.m';...
            'toolbox/matlab/uitools/uitools/listdlg.m';...
            'toolbox/matlab/uitools/uitools/questdlg.m';...
            'toolbox/matlab/uitools/uitools/inputdlg.m';...
            'toolbox/matlab/uitools/uitools/uisetcolor.m';...
            'toolbox/matlab/uitools/uitools/uisetfont.m';...
            'toolbox/matlab/uitools/uitools/uigetdir.m'};
       
        WebAppPrintingUnsupportedList={
            'toolbox/matlab/graphics/graphics/printing/print.m';...
            'toolbox/matlab/graphics/graphics/printing/printpreview.m'};

        PCTEnhancedMATLABFcns = {'parallel.Pool' 'parfeval' 'parfevalOnAll' 'mapreduce'};
    end

    properties (Constant)
        % MCR products that need to initialize JVM
        mcrProductsNeedJVM = init_mcrProductsNeedJVM();

        % MCR products that need to initialize HG
        mcrProductsNeedHG = init_mcrProductsNeedHG();
        
        % Components shipped with MATLAB Runtime Numerics
        componentsInNumerics = init_componentsInNumerics();
        
        % Components shipped with MATLAB
        componentsInMATLAB = init_componentsInMATLAB();
    end

    properties (Constant)
        DepIndicatedByNvPair = init_DepIndicatedByNvPair();
    end
end

function nv = init_pcm_navigator()
    if ismcc || ~isdeployed
        nv = matlab.depfun.internal.ProductComponentModuleNavigator();
    else
        nv = ''; % PCTWorker does not need to use the PCM database.
    end
end

function pat = init_canonical_matlabroot_pattern()
    pat = strrep([matlabroot filesep], filesep, '/');
    % Escape regexp-fooling characters in the full path to the
    % MATLAB root.
    pat =  regexptranslate('escape', pat);
    if ispc
        % If there's a drive letter in the path, replace it with [Xx],
        % which will regexp-match a drive letter of any case. 
        driveLetter = '^\w[:]';  % Pattern matching a drive letter.
        if ~isempty(regexp(pat, driveLetter, 'once'))
            pat = [ '[' upper(pat(1)) lower(pat(1)) ']:' pat(3:end) ];
        end
    end
end

function pid = init_mcrProductsNeedJVM()
    if ~isempty(matlab.depfun.internal.requirementsConstants.pcm_nv)
        % g2424976 - component matlab_java_core ships java/jar/jmi.jar, instead of component jmi
        pinfo = matlab.depfun.internal.requirementsConstants.pcm_nv.productShippingComponent('matlab_java_core','MCR');
        pid = [pinfo.extPID];
    else
        pid = [];
    end
end

function pid = init_mcrProductsNeedHG()
    if ~isempty(matlab.depfun.internal.requirementsConstants.pcm_nv)
        pinfo = matlab.depfun.internal.requirementsConstants.pcm_nv.productShippingComponent('matlab_graphics_hgbuiltins','MCR');
        pid = [pinfo.extPID];
    else
        pid = [];
    end
end

function clist = init_componentsInNumerics()
    if ~isempty(matlab.depfun.internal.requirementsConstants.pcm_nv)
        thisFolder = fileparts(mfilename('fullpath'));
        cache_file = fullfile(thisFolder, ['pcm_db_static_caches_' computer('arch') '.mat']);
        clist_struct = load(cache_file, 'mcr_numerics');
        clist = clist_struct.mcr_numerics;
    else
        clist = {};
    end
end

function clist = init_componentsInMATLAB()
    if ~isempty(matlab.depfun.internal.requirementsConstants.pcm_nv)
        thisFolder = fileparts(mfilename('fullpath'));
        cache_file = fullfile(thisFolder, ['pcm_db_static_caches_' computer('arch') '.mat']);
        clist_struct = load(cache_file, 'MATLAB');
        clist = clist_struct.MATLAB;
    else
        clist = {};
    end
end

% it takes ~1 to build the builtin list 
function l = initUndeployableBuiltins()
    l = {};
    if ~isempty(matlab.depfun.internal.requirementsConstants.pcm_nv)
        pcmNav = matlab.depfun.internal.requirementsConstants.pcm_nv;  
        % do SQL query the DB, <1s, it is fast
        % using pcm nav API to retrieve data indirectly is too slow, <10s
        query = ['SELECT Component.name ' ...
                 'FROM Component ' ...
                 'WHERE Component.Deployable = ''0'' ' ...
                 'AND Component.type = ' ...
                    '(SELECT Component_Type.id ' ...
                    'FROM Component_Type ' ...
                    'WHERE Component_Type.Name=''software'')'];
        pcmNav.doSql(query);
        undeployableComps = pcmNav.fetchRows();
        builtinFuncType = matlab.depfun.internal.MatlabType.BuiltinFunction;
        builtinClsType = matlab.depfun.internal.MatlabType.BuiltinClass;
        allBuiltins = keys(pcmNav.builtinRegistry);
        allBuiltinsOwningComp = values(pcmNav.builtinRegistry);
        %flatten
        undeployableComps = [undeployableComps{:}];
        % filter
        comps = ismember({allBuiltinsOwningComp.component}, undeployableComps);
        types_prefilt = [allBuiltinsOwningComp.type];
        types = (types_prefilt == builtinFuncType | types_prefilt == builtinClsType);
        filter = comps & types;
        % apply the filter
        l = allBuiltins(filter);
    end
end

function d = init_DepIndicatedByNvPair()
    d = dictionary();
    d(lower('ExecutionEnvironment=gpu')) = 'gpuArray';
    d(lower('ExecutionEnvironment=multi-gpu')) = 'gpuArray';
    d(lower('ExecutionEnvironment=parallel-gpu')) = 'gpuArray';
    d(lower('UseGPU=on')) = 'gpuArray';
end
