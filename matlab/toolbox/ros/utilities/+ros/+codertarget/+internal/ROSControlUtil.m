classdef ROSControlUtil < ros.codertarget.internal.ROSControlUtilBase
    %This class is for internal use only. It may be removed in the future.

    %  ROSControlUtil class containing specific functions for
    %  ros_control configuration.
    %
    %  Sample use:
    %    ctrlConfig = ros.codertarget.internal.ROSControlUtil;

    %    Copyright 2024 The MathWorks, Inc.

    methods (Static)
        function copyControllerPluginFiles(pkgRoot,pkgName,srcFolder)
            % COPYCONTROLLERPLUGINFILES Copies all the ros_control related
            % plugin and configuration files to the generated ROS package
            % folder

            pkgFolder = fullfile(pkgRoot,'src',pkgName);
            % Copy controller.xml plugin file
            copyfile(fullfile(srcFolder,'controllers.xml'),pkgFolder,'f');
            % Create 'config' folder for example controller configuration
            % and copy controllers.yaml
            configFolder = fullfile(pkgFolder,'config');
            if ~isfolder(configFolder)
                mkdir(configFolder);
            end
            copyfile(fullfile(srcFolder,'controllers.yaml'),...
                fullfile(configFolder,'controllers.yaml'),'f');
            if isfile(fullfile(srcFolder,'controller_params.cfg'))
                % Create 'cfg' folder for dynamic reconfiguration and copy the
                % generated *.cfg file
                dynamicParamCfgFolder = fullfile(pkgFolder,'cfg');
                if ~isfolder(dynamicParamCfgFolder)
                    mkdir(dynamicParamCfgFolder);
                end
                copyfile(fullfile(srcFolder,'controller_params.cfg'),...
                    fullfile(dynamicParamCfgFolder,'controller_params.cfg'),'f');
            end
        end

        function ret = getROSControlInterfaces()
            jsonFile = fullfile(toolboxdir('ros'),'codertarget','templates','ros_control_interfaces.json');
            ret = jsondecode(fileread(jsonFile));
        end

        function rosControlPrjInfo = getROSControlProjectInfo(rosProjectInfo,bDir)
            import ros.codertarget.internal.ROSControlUtil
            rosControlPrjInfo.ModelName = rosProjectInfo.ModelName;
            % Due to max length identifier truncation, maximum length of
            % this must be less than MaxIdLength-2 (<modelName>_P, in total as MaxIdLength)
            modelMaxParamLength = get_param(rosControlPrjInfo.ModelName,'MaxIdLength')-2;
            rosControlPrjInfo.ModelParamName = rosControlPrjInfo.ModelName(1:min(length(rosControlPrjInfo.ModelName),modelMaxParamLength));
            cinfo = load(fullfile(bDir,'codeInfo.mat'));
            rosControlPrjInfo.ModelClass = rosProjectInfo.ModelClassName;
            interfaces = ROSControlUtil.getROSControlInterfaces();
            rosctrlSettings = ROSControlUtil.getROSControlSettings(rosProjectInfo.ModelName);
            rosControlPrjInfo.ClassName = rosctrlSettings.ClassName;   
            rosControlPrjInfo.ProjectName = ...
                ros.codertarget.internal.ProjectTool.getValidPackageName(rosProjectInfo.ModelName);    
            interfaceTable = [rosctrlSettings.InportTable;rosctrlSettings.OutportTable];
            hwInterfaceTypes = unique(interfaceTable(:,4));
            allResources = [interfaces.InputResources; interfaces.OutputResources];

            rosControlPrjInfo.InitFcn = getFunctionCall(cinfo.codeInfo.InitializeFunctions);
            rosControlPrjInfo.TermFcn = getFunctionCall(cinfo.codeInfo.TerminateFunctions);  
            rosControlPrjInfo.StepFcn = getFunctionCall(cinfo.codeInfo.OutputFunctions);
            rosControlPrjInfo.RootIOAccessFormat = ROSControlUtil.getRootIOAccessFormat(cinfo);
            rootIOAccessorMap = containers.Map();
            rootIOAccessorMap('Inport') = @getInportStructExpr;
            rootIOAccessorMap('Outport') = @getOutportStructExpr;
            % Create a unique list of all hardware interfaces
            for k = 1:numel(hwInterfaceTypes)
                rosControlPrjInfo.HardwareInterfaces(k).Type = hwInterfaceTypes{k};
                interfaceIndex = contains({allResources.Name},hwInterfaceTypes{k});
                rosControlPrjInfo.HardwareInterfaces(k).VarName = ...
                    allResources(interfaceIndex).CppVarname;
                rosControlPrjInfo.HardwareInterfaces(k).Classname = ...
                    allResources(interfaceIndex).Classname;
                rosControlPrjInfo.HardwareInterfaces(k).Header = ...
                    allResources(interfaceIndex).Header;
            end
            rosControlPrjInfo.JointNamesCSList = char(strjoin(unique([rosctrlSettings.InportTable(:,3); rosctrlSettings.OutportTable(:,3)]),', '));
            % Map each inport/outport to a given interface
            for k = 1:height(interfaceTable)
                thisRow = interfaceTable(k,:);
                rosControlPrjInfo.JointInterfaces(k).BlockPath = [rosProjectInfo.ModelName,'/',char(thisRow(2))];
                rosControlPrjInfo.JointInterfaces(k).JointName = ['"',char(thisRow(3)),'"'];
                rosControlPrjInfo.JointInterfaces(k).InterfaceType = char(thisRow(4));
                rosControlPrjInfo.JointInterfaces(k).Port = char(thisRow(1));
                blockType = get_param(rosControlPrjInfo.JointInterfaces(k).BlockPath,'BlockType');
                rosControlPrjInfo.JointInterfaces(k).PortType = blockType;
                
                idx = contains({rosControlPrjInfo.HardwareInterfaces.Type},char(thisRow(4)));
                rosControlPrjInfo.JointInterfaces(k).HwInterfaceVarName = rosControlPrjInfo.HardwareInterfaces(idx).VarName;
                rosControlPrjInfo.JointInterfaces(k).HwInterfaceClass = rosControlPrjInfo.HardwareInterfaces(idx).Classname;
                portNum = str2double(rosControlPrjInfo.JointInterfaces(k).Port);
                accessorFcn = rootIOAccessorMap(blockType);
                rosControlPrjInfo.JointInterfaces(k).FieldName = ...
                    accessorFcn(portNum);
            end
            %{
                1. Get a list of enabledParams - create an array of 
                2. Compare with the SID of enabledParams with codeInfo to get
                   codeInfo.Parameters indices
                3. Trim the codeInfo.Parameters to just the enabledParams
                4. Read info from the codeInfo.Parameters and create the
                   DynamicParams projectInfo structure
                   struct('Name','','DataType','','MaxVal','','MinVal','',
                    'Description','','DefaultValue','')
            %}
            enabledParams = rosctrlSettings.ParamTable([rosctrlSettings.ParamTable{:,4}],:,:,:);
            allParamSIDs = {cinfo.codeInfo.Parameters.SID};
            rosControlPrjInfo.DynamicParams = repmat(...
                struct('Name','','DataType','','MaxVal','','MinVal','',...
                'Description','','DefaultValue',''),height(enabledParams),1);
            for k=1:height(enabledParams)
                blkName = [enabledParams{k,2},'/',enabledParams{k,1}];
                prmName = enabledParams{k,3};
                thisSid = Simulink.ID.getSID(blkName);
                idx = strcmp(allParamSIDs,thisSid);
                paramCodeInfo = getCodeInfoForBlockParameter(idx, prmName);
                rosControlPrjInfo.DynamicParams(k).Name = paramCodeInfo.Implementation.ElementIdentifier;
                retDtype = getParamDataType(paramCodeInfo);
                rosControlPrjInfo.DynamicParams(k).DataType = retDtype;
                rosControlPrjInfo.DynamicParams(k).DefaultValue = getDefaultParamValue(blkName,prmName,retDtype);
                % There isn't a simple method to get the min-max values
                % from Simulink Model - so keep it empty for first
                % submission
                rosControlPrjInfo.DynamicParams(k).MaxVal = '';
                rosControlPrjInfo.DynamicParams(k).MinVal = '';
                rosControlPrjInfo.DynamicParams(k).Description = ...
                    getString(message('ros:slros:roscontrol:DynParamDescr',...
                    rosControlPrjInfo.DynamicParams(k).Name,blkName));
            end

            function ret = getDefaultParamValue(blk,prm,dtypeStruct)
				% Parameter value can be an expression, that may contain
				% out-of-scope variables, populate numeric and logical 
				% defaults accordingly
                ret = dtypeStruct.default;
                paramValStr = get_param(blk,prm);
                prmValDbl = str2double(paramValStr);
                switch (dtypeStruct.cfg)
                    case {'double_t','int_t'}
                        if ~isnan(prmValDbl)
                            ret = paramValStr;
                        end
                    case {'bool_t'}
                        % Set the boolean values accordingly
                        if ~isnan(prmValDbl)
                            % the value is a numeric scalar - '0' or '1'
                            ret = num2str(any(prmValDbl));
                        elseif ismember(paramValStr,{'true','false'})
                            % the value is a literal - 'true' or 'false'
                            ret = num2str(eval(paramValStr));
                        end
                end
            end

            function paramCodeInfo = getCodeInfoForBlockParameter(idx,prmName)
                % A single block can have multiple tunable parameters, so
                % search for the parameter name using 'GraphicalName'
                % property
                paramCodeInfoArray = cinfo.codeInfo.Parameters(idx);
                paramCodeInfo = paramCodeInfoArray(arrayfun(@(x)...
                    contains(x.GraphicalName,prmName,IgnoreCase=true),paramCodeInfoArray));
                assert(~isempty(paramCodeInfo),'Code information metadata cannot be empty!');
            end

            function ret = getParamDataType(prm)
                if isa(prm.Type,'coder.types.Matrix')
                    dtype = prm.Type.BaseType.Name;
                else
                    dtype = prm.Type.Name;
                end
                switch (dtype)
                    case 'double'
                        ret.cfg = 'double_t';
                        ret.yaml = 'double';
                        ret.cpp = 'double';
                        ret.default = '0.0';
                        ret.yamldefault = '0.0';
                    case {'int8','uint8','int16','uint16','int32','uint32','int64','uint64'}
                        ret.cfg = 'int_t';
                        ret.yaml = 'int';
                        ret.cpp = 'int';
                        ret.default = '0';
                        ret.yamldefault = '0';
                    case {'logical','boolean'}
                        ret.cfg = 'bool_t';
                        ret.yaml = 'bool';
                        ret.cpp = 'bool';
                        ret.default = '0';
                        ret.yamldefault = 'false';
                    case 'char'
                        ret.cfg = 'str_t';
                        ret.yaml = 'string';
                        ret.cpp = 'std::string';
                        ret.default = '"MW_STR"';
                        ret.yamldefault = '"MW_STR"';
                end
            end

            function ret = getInportStructExpr(portNum)
                impl = cinfo.codeInfo.Inports(portNum).Implementation;
                rosControlPrjInfo.InputType = sprintf('extern %s %s;',...
                    impl.BaseRegion.Type.Identifier,...
                    impl.BaseRegion.Identifier);
                ret = [impl.BaseRegion.Identifier,'.',impl.ElementIdentifier];
            end
            function ret = getOutportStructExpr(portNum)
                impl = cinfo.codeInfo.Outports(portNum).Implementation;
                rosControlPrjInfo.OutputType = sprintf('extern %s %s;',...
                    impl.BaseRegion.Type.Identifier,...
                    impl.BaseRegion.Identifier);
                ret = [impl.BaseRegion.Identifier,'.',impl.ElementIdentifier];
            end
        end

        function pkgInfo = setROSControlPkgInfo(modelName,pkgInfo,srcFiles,incFiles)
            pkgInfo.Dependencies = unique([pkgInfo.Dependencies, ...
                {'controller_interface','dynamic_reconfigure','hardware_interface',...
                'pluginlib','realtime_tools','tf'}]);
            pkgInfo.LibSourceFiles = srcFiles;
            pkgInfo.LibIncludeFiles = incFiles;
            pkgInfo.CppLibraryName = modelName;
            pkgInfo.LibFormat = 'SHARED';
        end

        function generateROSControlFiles(rosProjectInfo, bDir, buildInfo)
            import ros.codertarget.internal.ROSControlUtil
            modelInfo = ROSControlUtil.getROSControlProjectInfo(rosProjectInfo,bDir);
            templFolder = fullfile(toolboxdir('ros'),'codertarget','templates');
            templateFile = fullfile(templFolder,'controller_host.h.tmpl');
            
            % Generate <modelname>_ctrlr_host.cpp and <modelname>_ctrlr_host.h
            sourceFileName = [rosProjectInfo.ModelName,'_ctrlr_host'];
            loc_createOutput(modelInfo,templateFile,...
                fullfile(bDir,[sourceFileName,'.h']));
            templateFile = fullfile(templFolder,'controller_host.cpp.tmpl');
            loc_createOutput(modelInfo,templateFile,...
                fullfile(bDir,[sourceFileName,'.cpp']));
                
            % Generate controllers.xml for ros_control package
            templateFile = fullfile(templFolder,'controllers.xml.tmpl');
            loc_createOutput(modelInfo,templateFile,...
                fullfile(bDir,'controllers.xml'));
            % Generate controllers.yaml for ros_control package
            templateFile = fullfile(templFolder,'controllers.yaml.tmpl');
            loc_createOutput(modelInfo,templateFile,...
                fullfile(bDir,'controllers.yaml'));

            if ROSControlUtil.hasROSControlReconfigureParams(rosProjectInfo.ModelName)
                % Generate controller_params.cfg
                templateFile = fullfile(templFolder,'controller_params.cfg.tmpl');
                loc_createOutput(modelInfo,templateFile,...
                    fullfile(bDir,'controller_params.cfg'));
            end
            buildInfo.addIncludeFiles([sourceFileName,'.h']);
            buildInfo.addSourceFiles([sourceFileName,'.cpp']); 
            buildInfo.addDefines('_SL_ROS_CONTROL_PLUGIN_')
        end
    end
end

% -------------------------------------------------------------------------
% Local functions
% -------------------------------------------------------------------------
function loc_createOutput(data,tmplFile,outFile)
%Load the given template and render the data in it.

    tmpl = ros.internal.emitter.MLTemplate;
    tmpl.loadFile(tmplFile);
    tmpl.outFile = outFile;
    tmpl.render(data, 2);
    % smart-indent and beautify the generated header and C++ files
    isaMexFileOnPath = 3;
    if (isaMexFileOnPath == exist('c_beautifier','file')) && ...
            (endsWith(outFile,'.cpp') || endsWith(outFile,'.h'))
        c_beautifier(outFile);
    end
end