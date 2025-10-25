classdef driverBlock < matlabshared.sensors.utils.driverUtilFiles
    % driverBlock is the main class which has properties and methods required to generate a MATLAB sensor system object.
    % Example:
    % Create the driver object
    % blockName = 'SensorbBlock3p';
    % blockType = 'source';
    % peripheral = 'I2C';
    % drvObj = createDriverBlock('Name',blockName,'BlockType',blockType,'Peripheral',peripheral);
    %
    % % Add mask description for the block mask
    % maskDescription = 'Block outputs pressure and temperature values.';
    % addMaskDescription(drvObj,maskDescription);
    %
    % % Add 3p header files folder and source files folder info
    % % Will include all header files in the folder
    % addHeaderPath(drvObj,'headerpath');
    % addSourcePath(drvObj,'sourcepath');
    % addSourceFile(drvObj,{'Adafruit_BME680.cpp','bme68x.c'});
    %
    % % Create the output of the block
    % pressureOutput = createOutput(drvObj,'PressureOutput','Datatype','single','Size',1);
    % temperatureOutput = createOutput(drvObj,'TemperatureOutput','Datatype','single','Size',1);
    % addOutput(drvObj,pressureOutput,temperatureOutput)
    %
    % % Map the C code arguments to corresponding M arguments
    % % Output should be passed as a input argument, if not the code will error
    % cInputArgumentstoStepFcn = {'float *inputPressure','float *inputTemperature'};
    % mInputArgumentsToCStepFcn = {pressureOutput,temperatureOutput};
    % addInputStepArguments(drvObj,cInputArgumentstoStepFcn,mInputArgumentsToCStepFcn);
    %
    % % Generate system object and c function template in the current folder
    % generateSensorBlockAndTemplateHooks(drvObj);

    methods (Access = 'public')
        % Constructor
        function obj = driverBlock(name,type,peripheral)
            arguments
                name char
                type char
                peripheral char
            end
            if ~(strcmpi(type,'source')||strcmpi(type,'sink'))      
                error(message('matlab_sensors:blockcreation:BlockTypeError').getString);  
            end
            if ~(strcmpi(peripheral,'I2C')||strcmpi(peripheral,'SPI')||strcmpi(peripheral,'CAN'))
                error(message('matlab_sensors:blockcreation:PeripheralError').getString);  
            end
            obj.Name = name;
            obj.BlockType = type;
            obj.Peripheral = peripheral;
        end
        %add char validation
        function addMaskDescription(obj,descr)
            %adds Mask Description
            descr = convertStringsToChars(descr);
            obj.MaskDescription = descr;
        end

        function addHeaderFile(obj,file)
            %add header files to the object
            if(iscell(file))
                for i=1:length(file)
                    if (~isempty(obj.HeaderFile))
                        if(find(ismember(obj.HeaderFile,file{i})))                         
                            error(message('matlab_sensors:blockcreation:OneOrMoreFile').getString);
                        end
                    end
                end
                for i=1:length(file)
                    obj.HeaderFile{end+1} = file{i};
                    getIncludeFiles(obj,file{i});
                end
            elseif(ischar(file))
                if(find(ismember(obj.HeaderFile,file)))
                    error(message('matlab_sensors:blockcreation:FileExists').getString);
                else
                    obj.HeaderFile{end+1} = file;
                    getIncludeFiles(obj,file);
                end
            end
        end

        function deleteHeaderFile(obj,fileName)
            %delete header file 1 by 1
            idx = 0; %#ok<*NASGU>
            if(~ischar(fileName))
                error(message('matlab_sensors:blockcreation:FileNameChar').getString);
            end
            result=ismember(string(obj.HeaderFile),fileName);
            if((length(result==1)>0))
                idx = find(ismember(obj.HeaderFile,fileName));
                obj.HeaderFile(idx) = []; %#ok<*FNDSB>
            else
                error('File %s is not present',fileName);
            end
        end

        function addSourceFile(obj,file)
            %add Source file
            if(iscell(file))
                for i=1:length(file)
                    if(~isempty(obj.SourceFile))
                        if(find(ismember(obj.SourceFile,file{i})))
                            error(message('matlab_sensors:blockcreation:OneOrMoreFile').getString);
                        end
                    end
                end
                for i=1:length(file)
                    obj.SourceFile{end+1} = file{i};

                end
            elseif(ischar(file))
                if(find(ismember(obj.SourceFile,file)))
                    error(message('matlab_sensors:blockcreation:FileExists').getString);
                else
                    obj.SourceFile{end+1} = file;
                end
            end
        end

        function deleteSourceFile(obj,fileName)
            %deletes source file one by one
            idx = 0;
            if(~ischar(fileName))
               error(message('matlab_sensors:blockcreation:FileNameChar').getString);
            end
            if(ismember(obj.SourceFile,fileName))
                idx = find(ismember(obj.SourceFile,fileName));
                obj.SourceFile(idx) = [];
            else
                error('File %s is not present',fileName);
            end
        end

        function addHeaderPath(obj,path)
            %add header path
            if(ischar(path))
                if(find(ismember(obj.HeaderPath,path)))
                    error(message('matlab_sensors:blockcreation:PathExists').getString);
                else
                    obj.HeaderPath{end+1} = path;
                end
            else
                error(message('matlab_sensors:blockcreation:PathNameChar').getString);
            end
        end

        function addSourcePath(obj,path)
            %add header path
            if(ischar(path))
                if(find(ismember(obj.SourcePath,path)))
                    error(message('matlab_sensors:blockcreation:PathExists').getString);
                else
                    obj.SourcePath{end+1} = path;
                end
            else
               error(message('matlab_sensors:blockcreation:PathNameChar').getString);
            end
        end

        function deleteHeaderPath(obj,path)
            %deleteHeaderPath delete an existing path added to the block
            %   obj = deleteHeaderPath(obj,i) deletes the path
            %   from the HeaderPaths property of the driverBlock
            %   object obj.
            idx = 0;
            if(~ischar(path))
                error(message('matlab_sensors:blockcreation:PathNameChar').getString);
            end
            if(find(ismember(obj.HeaderPath,path)))
                idx = find(ismember(obj.HeaderPath,path));
                obj.HeaderPath(idx) = [];
            else
                error('Path %s is not present',path);
            end
        end

        function h = createInput(obj,inputName,varargin)             %#ok<*INUSL>
            inputName = char(inputName);
            h = matlabshared.sensors.utils.InputOutput(inputName,varargin{:});


        end

        function addInput(obj,varargin)
            for i=1:nargin-1
                obj.Inputs{i}={varargin{i}};
            end
        end

        function h = createOutput(obj,outputName,varargin)
            outputName = convertStringsToChars(outputName);
            h = matlabshared.sensors.utils.InputOutput(outputName,varargin{:});
        end

        function addOutput(obj,varargin)
            for i=1:nargin-1
                obj.Outputs{i}={varargin{i}};
            end
        end

        function deleteOutput(obj,fileName)
            %delete header file 1 by 1
            idx = 0; %#ok<*NASGU>
            x= any(cellfun(@isequal, obj.Outputs{1}, repmat({fileName}, size(obj.Outputs{1}))));
            if(x)
                idx = cellfun(@isequal, obj.Outputs{1}, repmat({fileName}, size(obj.Outputs{1})));
                obj.Outputs{1}(idx) = []; %#ok<*FNDSB>
            else
                error('File %s is not present',fileName);
            end
        end

        function addSetupHeaderFile(obj,file)
            obj.SetupHeaderFile = file;
        end

        function h = createProperty(obj,propertyName,varargin)
            propertyName = convertStringsToChars(propertyName);
            h = matlabshared.sensors.utils.Property(propertyName,varargin{:});
        end
        function addProperty(obj,varargin)
            for i=1:nargin-1
                obj.Masks{i}={varargin{i}};
            end
        end

        function l = getFunctionsList(obj)
            for i=1:length(obj.HeaderFile)
                parse(obj,obj.HeaderFile{i});
            end
            %add simpler method maybe for file search?
            for i = 1:length(obj.HeaderPath)
                if(obj.HeaderPath{i}(end) ~= '\')
                    for j =1:length(obj.IncludeFiles)
                        x = [obj.HeaderPath{i} '\'];
                        y = [x obj.IncludeFiles{j}];
                        if isfile(y)
                            parseInclude(obj,y);
                        end
                    end
                else
                    for j =1:length(obj.IncludeFiles)
                        x = obj.HeaderPath{i};
                        y = [x obj.IncludeFiles{j}];
                        if isfile(y)
                            parseInclude(obj,y);
                        end
                    end
                end
            end
            obj.FunctionBlock = obj.FunctionBlock';
            l = obj.FunctionBlock;
        end

        %Adds function to setup block
        function addSetupFunctions(obj,fName)
            if ~iscell(fName)
                fName = {fName};
            end
            for i=1:length(fName)
                %                 if ~any(ismember(obj.FunctionBlock,fName{i}))
                %                     error('Function not present');
                %                 end
                if any(ismember(obj.SetupFunction,fName{i}))
                    error('%s Function already included',fName{i});
                end
            end

            for i=1:length(fName)
                obj.SetupFunction{end+1} = fName{i};
                s{i} = fName{i}(1:end);
                s{i} = strtrim(s{i});
                %                 s{i} = strrep(s{i},' *','*');
                if(~any(ismember(obj.FunctionBlock,s{i})))
                    obj.FunctionBlock{end+1} = s{i};
                    [a,b,c] = parseFunction(obj,s{i});
                    j = matlabshared.sensors.utils.FunctionStruct(b,a,c);
                    if isempty(obj.setupFnMap)
                        obj.setupFnMap =j;
                        obj.fnMap(s{i}) = j;
                    else
                        var1 =  obj.setupFnMap.inpArgs;
                        var2 = obj.fnMap('Setup()').inpArgs;
                        obj.setupFnMap =j;
                        obj.fnMap('Setup()') = j;
                        obj.fnMap(s{i})=obj.fnMap('Setup()');
                        obj.fnMap('Setup()') = [];
%                         remove(obj.fnMap, 'Setup()');
                        obj.setupFnMap.inpArgs = var1;
                        %                         obj.fnMap(s{i}).inpArgs = var2;
                    end

                end
            end
        end

        function deleteSetupFunction(obj,fName)
            idx = 0;
            if(~ischar(fName))
                error(message('matlab_sensors:blockcreation:FileNameChar').getString);
            end
            if(ismember(obj.SetupFunction,fName))
                idx = find(ismember(obj.SetupFunction,fName));
                obj.SetupFunction(idx) = [];
            else
                error('Function "%s" is not a Setup Function',fName);
            end
        end

        function [list,setupIndex,stepIndex] = getStepAndSetupIndex(obj,setupFunctionName,stepFunctionName)
            list=getFunctionsList(obj);
            setupIndex=find(ismember(list,setupFunctionName));
            stepIndex=find(ismember(list,stepFunctionName));
        end

        function addStepFunctions(obj,fName)
            if ~iscell(fName)
                fName = {fName};
            end
            for i=1:length(fName)
                if any(ismember(obj.StepFunction,fName{i}))
                    error('%s Function already included',fName{i});
                end
            end
            for i=1:length(fName)
                obj.StepFunction{end+1} = fName{i};
                s{i} = fName{i}(1:end);
                s{i} = strtrim(s{i});
                %                 s{i} = strrep(s{i},' *','*');
                if(~any(ismember(obj.FunctionBlock,s{i})))
                    obj.FunctionBlock{end+1} = s{i};
                    [a,b,c] = parseFunction(obj,s{i});
                    j = matlabshared.sensors.utils.FunctionStruct(b,a,c);
                    if isempty(obj.stepFnMap)
                        obj.stepFnMap =j;
                        obj.fnMap(s{i}) = j;
                    else
                        var1 =  obj.stepFnMap.inpArgs;
                        var2 = obj.fnMap('Step()').inpArgs;
                        obj.stepFnMap =j;
                        obj.fnMap('Step()') = j;
                        obj.fnMap(s{i})=obj.fnMap('Step()');
                        obj.fnMap('Step()')=[];
                        obj.stepFnMap.inpArgs = var1;
                    end
                    %                     obj.fnMap(s{i}) = j;
                end
            end
        end

        function deleteStepFunction(obj,fName)
            idx = 0;
            if(~ischar(fName))
               error(message('matlab_sensors:blockcreation:FileNameChar').getString);
            end
            if(ismember(obj.StepFunction,fName))
                idx = find(ismember(obj.StepFunction,fName));
                obj.StepFunction(idx) = [];
            else
                error('Function "%s" is not a Step Function',fName);
            end
        end

        function addReleaseFunctions(obj,fName)
            if ~iscell(fName)
                fName = {fName};
            end
            for i=1:length(fName)
                if ~any(ismember(obj.FunctionBlock,fName{i}))
                    error(message('matlab_sensors:blockcreation:FunctionNotExists').getString);
                end
                if any(ismember(obj.ReleaseFunction,fName{i}))
                    error('%s Function already included',fName{i});
                end
            end
            for i=1:length(fName)
                obj.ReleaseFunction{end+1} = fName{i};
            end
        end

        function deleteReleaseFunction(obj,fName)
            idx = 0;
            if(~ischar(fName))
                error(message('matlab_sensors:blockcreation:FunctionNameChar').getString);
            end
            if(ismember(obj.ReleaseFunction,fName))
                idx = find(ismember(obj.ReleaseFunction,fName));
                obj.ReleaseFunction(idx) = [];
            else
                error('Function "%s" is not a Release Function',fName);
            end
        end

        %Add validation to check number of passed arguments equal to that
        %of original function
        function addInputArguments(obj,fName,arguments)
            if ~iscell(arguments)
                arguments = {arguments};
            end
            if (~any(ismember(obj.StepFunction,fName))&&(~any(ismember(obj.SetupFunction,fName))))
                error(message('matlab_sensors:blockcreation:FunctionNotExists').getString);
            end
            val = obj.fnMap(fName);
            for i=1:length(arguments)

                val.inpArgs{end+1} = arguments{i};
                if isa(arguments{i},'Property')
                    if(arguments{i}.Visible)
                        idx = getObjectArrayElementIndexByName(arguments{i}.Name,obj.Masks);
                        if isequal(idx,0)
                            obj.Masks{end+1} = arguments{i};
                        end
                    elseif(arguments{i}.Tunable)
                        idx = getObjectArrayElementIndexByName(arguments{i}.Name,obj.Internals);
                        if isequal(idx,0)
                            obj.Internals{end+1} = arguments{i};
                        end
                    else
                        idx = getObjectArrayElementIndexByName(arguments{i}.Name,obj.Constants);
                        if isequal(idx,0)
                            obj.Constants{end+1} = arguments{i};
                        end
                    end
                else
                end
            end
            obj.fnMap(fName) = val;
        end

        function addInputStepArguments(obj,cArguments,arguments)
            if ~iscell(arguments)
                arguments = {arguments};
            end
            if ~iscell(cArguments)
                cArguments = {cArguments};
            end
            for i=1:length(cArguments)
                if i == length(cArguments)
                    obj.stepInArg = [obj.stepInArg,cArguments{i}];
                else
                    obj.stepInArg = [obj.stepInArg,cArguments{i},','];
                end
            end
            if(isempty(obj.stepFnMap))
                fName = 'Step()';
                s{1} = fName(1:end);
                s{1} = strtrim(s{1});
                %                 s{1} = strrep(s{1},' *','*');
                if(~any(ismember(obj.FunctionBlock,s{1})))
                    obj.FunctionBlock{end+1} = s{1};
                    [a,b,c] = parseFunction(obj,s{1});
                    j = matlabshared.sensors.utils.FunctionStruct(b,a,c);
                    obj.fnMap(s{1}) = j;
                    obj.stepFnMap =j;
                end
            else
                s{1}= obj.StepFunction{1};
            end
            val = obj.stepFnMap;
            val3 = obj.fnMap(s{1});
            for i=1:length(arguments)
                val.inpArgs{end+1} = arguments{i};
                %                 val3.inpArgs{end+1} = arguments{i};
                if isa(arguments{i},'Property')
                    if(arguments{i}.Visible)
                        idx = getObjectArrayElementIndexByName(arguments{i}.Name,obj.Masks);
                        if isequal(idx,0)
                            obj.Masks{end+1} = arguments{i};
                        end
                    elseif(arguments{i}.Tunable)
                        idx = getObjectArrayElementIndexByName(arguments{i}.Name,obj.Internals);
                        if isequal(idx,0)
                            obj.Internals{end+1} = arguments{i};
                        end
                    else
                        idx = getObjectArrayElementIndexByName(arguments{i}.Name,obj.Constants);
                        if isequal(idx,0)
                            obj.Constants{end+1} = arguments{i};
                        end
                    end
                else
                end
            end
            obj.stepFnMap = val;
            obj.fnMap(s{1}) = val;
        end

        function addInputSetupArguments(obj,cArguments,arguments)
            if ~iscell(arguments)
                arguments = {arguments};
            end
            if ~iscell(cArguments)
                cArguments = {cArguments};
            end
            %%
            for i=1:length(cArguments)
                if i == length(cArguments)
                    obj.setupInArg = [obj.setupInArg,cArguments{i}];
                else
                    obj.setupInArg = [obj.setupInArg,cArguments{i},','];
                end
            end
            if(isempty(obj.setupFnMap))
                fName = 'Setup()';
                s{1} = fName(1:end);
                s{1} = strtrim(s{1});
                %                 s{1} = strrep(s{1},' *','*');
                if(~any(ismember(obj.FunctionBlock,s{1})))
                    obj.FunctionBlock{end+1} = s{1};
                    [a,b,c] = parseFunction(obj,s{1});
                    j = matlabshared.sensors.utils.FunctionStruct(b,a,c);
                    obj.fnMap(s{1}) = j;
                    obj.setupFnMap =j;
                end
            else
                s{1}= obj.SetupFunction{1};
            end
            val = obj.setupFnMap;
            val3 = obj.fnMap(s{1});
            for i=1:length(arguments)
                val.inpArgs{end+1} = arguments{i};
                %                 val3.inpArgs{end+1} = arguments{i};
                if isa(arguments{i},'Property')
                    if(arguments{i}.Visible)
                        idx = getObjectArrayElementIndexByName(arguments{i}.Name,obj.Masks);
                        if isequal(idx,0)
                            obj.Masks{end+1} = arguments{i};
                        end
                    elseif(arguments{i}.Tunable)
                        idx = getObjectArrayElementIndexByName(arguments{i}.Name,obj.Internals);
                        if isequal(idx,0)
                            obj.Internals{end+1} = arguments{i};
                        end
                    else
                        idx = getObjectArrayElementIndexByName(arguments{i}.Name,obj.Constants);
                        if isequal(idx,0)
                            obj.Constants{end+1} = arguments{i};
                        end
                    end
                else
                end
            end
            obj.setupFnMap = val;
            obj.fnMap(s{1}) = val;
        end
        % Improve function to delete all input arguments instead of one by
        % one
        function deleteInputArgument(obj,fName,argName)
            arguments
                obj
                fName char
                argName char
            end
            val = obj.fnMap(fName);
            if(getObjectArrayElementIndexByName(argName,val.inpArgs))
                index = getObjectArrayElementIndexByName(argName,val.inpArgs);
                val.inpArgs(index) = [];
                if isa(val,'Property')
                    if(getObjectArrayElementIndexByName(argName,obj.Masks))
                        idx = getObjectArrayElementIndexByName(argName,obj.Masks);
                        obj.Masks(idx) = [];
                    elseif(getObjectArrayElementIndexByName(argName,obj.Internals))
                        idx = getObjectArrayElementIndexByName(argName,obj.Internals);
                        obj.Internals(idx) = [];
                    elseif(getObjectArrayElementIndexByName(argName,obj.Constants))
                        idx = getObjectArrayElementIndexByName(argName,obj.Constants);
                        obj.Constans(idx) = [];
                    end
                else
                    if(getObjectArrayElementIndexByName(argName,obj.Inputs))
                        idx = getObjectArrayElementIndexByName(argName,obj.Inputs);
                        obj.Inputs(idx) = [];
                    end
                end
            else
                error('No input arguments named %s associated with %s',argName,fname);
            end
            obj.fnMap(fName) = val;
        end
        %Add validation to check number of passed arguments equal to that
        %of original function
        function addReturnArgument(obj,fName,arguments)
            if ~iscell(arguments)
                arguments = {arguments};
            end
            if ~any(ismember(obj.FunctionBlock,fName))
                error(message('matlab_sensors:blockcreation:FunctionNotExists').getString);
            end
            for i=1:length(arguments)
                if ~(isa(arguments{i},'Output') || isa(arguments{i},'Property'))
                     error(message('matlab_sensors:blockcreation:ReturnTypeOfOutputPropertyClass').getString);
                end
            end
            for i=1:length(arguments)
                x = arguments{i}.DataType;
                x = strrep(x,'*','');
                x = strtrim(x);
                if~(isKey(obj.dataTypeMap,x) || ...
                        isKey(obj.enMap,x))               
                    error(message('matlab_sensors:blockcreation:ArgumentType').getString);
                end
            end
            val = obj.fnMap(fName);
            %Add validation for invalid or unmatched data types
            for i=1:length(arguments)
                if(~(strcmp(val.retType,arguments{i}.DataType) || strcmp(val.retType,obj.dataTypeMap(arguments{i}.DataType))))
                    %warning('Data type %s for expected type %s',arguments{i}.DataType,val.retType)
                end
                val.retArg = arguments(i);
                if isa(arguments{i},'Property')
                    if(arguments{i}.Visible)
                        idx = getObjectArrayElementIndexByName(arguments{i}.Name,obj.Masks);
                        if isequal(idx,0)
                            obj.Masks{end+1} = arguments{i};
                        end
                    elseif(arguments{i}.Tunable)
                        idx = getObjectArrayElementIndexByName(arguments{i}.Name,obj.Internals);
                        if isequal(idx,0)
                            obj.Internals{end+1} = arguments{i};
                        end
                    else
                        idx = getObjectArrayElementIndexByName(arguments{i}.Name,obj.Constants);
                        if isequal(idx,0)
                            obj.Constants{end+1} = arguments{i};
                        end
                    end
                else
                end
            end
            obj.fnMap(fName) = val;
        end

        % Improve function to delete all return arguments for a single function instead of one by
        % one
        function deleteReturnArgument(obj,fName,argName)
            arguments
                obj
                fName char
                argName char
            end
            val = obj.fnMap(fName);
            if(getObjectArrayElementIndexByName(argName,val.retArg))
                index = getObjectArrayElementIndexByName(argName,val.retArg);
                val.retArg(index) = [];
                if isa(val,'Property')
                    if(getObjectArrayElementIndexByName(argName,obj.Masks))
                        idx = getObjectArrayElementIndexByName(argName,obj.Masks);
                        obj.Masks(idx) = [];
                    elseif(getObjectArrayElementIndexByName(argName,obj.Internals))
                        idx = getObjectArrayElementIndexByName(argName,obj.Internals);
                        obj.Internals(idx) = [];
                    elseif(getObjectArrayElementIndexByName(argName,obj.Constants))
                        idx = getObjectArrayElementIndexByName(argName,obj.Constants);
                        obj.Constans(idx) = [];
                    end
                else
                    if(getObjectArrayElementIndexByName(argName,obj.Outputs))
                        idx = getObjectArrayElementIndexByName(argName,obj.Outputs);
                        obj.Outputs(idx) = [];
                    end
                end
            else
                error('No return arguments named %s associated with %s',argName,fname);
            end
            obj.fnMap(fName) = val;
        end

        function generateSensorBlockAndTemplateHooks(obj)
            generateSystemObjectFile(obj);
        end
    end
    methods(Access = 'private')
        function generateSystemObjectFile(obj)
            %generate the main matlab system object file
            % To do add print functions for non tunable mask parameters
            blockName = obj.Name;
            fileName = [blockName '.m'];
            obj.SetupHeaderFile = [blockName '.h'];
            [~,headerFileName] = fileparts(obj.SetupHeaderFile);
            propTunable = '';
            propertyInitNonTunable = '';
            for i = 1:numel(obj.Masks)
                if isa(obj.Masks{i}{1},'matlabshared.sensors.utils.Property')
                    if isKey(obj.enMap,obj.Masks{i}{1}.DataType)
                        value = obj.Masks{1}{i};
                        sz = extractBetween(value.Size,'[',']');
                        sz = sz{1};
                        propTunable = sprintf([propTunable '%s (%s) %s = %s.%s;\n'],value.Name,sz,value.DataType,value.DataType,value.InitValue);
                    else
                        propTunable = sprintf([propTunable '%s;\n'],obj.Masks{i}{1}.Name);
                    end
                    propertyInitNonTunable = sprintf([propertyInitNonTunable 'obj.%s = %s(%s);\n'],obj.Masks{i}{1}.Name,obj.Masks{i}{1}.DataType,obj.Masks{i}{1}.InitValue);
                end
            end
            propTunable=strtrim(propTunable);
            propertyInitNonTunable=strtrim(propertyInitNonTunable);
            propInternal = '';
            propertyInitInternal = '';
            for i = 1:numel(obj.Internals)
                if isKey(obj.enMap,obj.Internals{i}.DataType)
                    sz = extractBetween(obj.Internals{i}.Size,'[',']');
                    sz = sz{1};
                    propInternal = sprintf([propInternal '%s (%s) %s = %s.%s;\n'],obj.Internals{i}.Name,sz,obj.Internals{i}.DataType,obj.Internals{i}.DataType,obj.Internals{i}.InitValue);
                else
                    propInternal = sprintf([propInternal '%s;\n'],obj.Internals{i}.Name);
                end
                value = obj.Internals{i};
                if contains(value.DataType ,'*')||contains(obj.dataTypeMap(value.DataType) ,'*')
                    propertyInitInternal = sprintf([propertyInitInternal 'obj.%s = coder.opaque(''%s'');\n'],value.Name,value.DataType);
                else
                    propertyInitInternal = sprintf([propertyInitInternal 'obj.%s = %s(%s);\n'],value.Name,value.DataType,value.InitValue);
                end
            end
            propInternal=strtrim(propInternal);
            propertyInitInternal=strtrim(propertyInitInternal);
            propConst = '';
            propertyInitConstant = '';
            for i = 1:numel(obj.Constants)
                if isKey(obj.enMap,obj.Constants{i}.DataType)
                    sz = extractBetween(obj.Constants{i}.Size,'[',']');
                    sz = sz{1};
                    propConst = sprintf([propConst '%s (%s) %s = %s.%s;\n'],obj.Constants{i}.Name,sz,obj.Constants{i}.DataType,obj.Constants{i}.DataType,obj.Constants{i}.InitValue);
                else
                    propConst = sprintf([propConst '%s;\n'],obj.Constants{i}.Name);
                end
                value = obj.Constants{i};
                if contains(value.DataType ,'*') || contains(obj.dataTypeMap(value.DataType) ,'*')
                    propertyInitConstant = sprintf([propertyInitConstant 'obj.%s = coder.opaque(''%s'');\n'],value.Name,value.DataType);
                else
                    propertyInitConstant = sprintf([propertyInitConstant 'obj.%s = %s(%s);\n'],value.Name,value.DataType,value.InitValue);
                end
            end
            propConst=strtrim(propConst);
            propertyInitConstant=strtrim(propertyInitConstant);
            if isempty(obj.SetupFunction)
                setupName = ['void setupFunction(',obj.setupInArg,')'];
                addSetupFunctions(obj,{setupName});
            end
            if isempty(obj.StepFunction)
                stepName = ['void stepFunction(',obj.stepInArg,')'];
                addStepFunctions(obj,{stepName});
            end
            setupCoderCEval = '';
            for i = 1:numel(obj.SetupFunction)
                setupCoderCEval = sprintf([setupCoderCEval '%s\n'],getFunctionCall(obj,obj.SetupFunction{i}));
                setupFunctionName = obj.SetupFunction{i};
            end
            setupCoderCEval=strtrim(setupCoderCEval);
            stepCoderCEval = '';
            for i = 1:numel(obj.StepFunction)
                stepCoderCEval = sprintf([stepCoderCEval '%s\n'],getFunctionCall(obj,obj.StepFunction{i}));
                stepFunctionName = obj.StepFunction{i};
            end
            stepCoderCEval=strtrim(stepCoderCEval);
            releaseCoderCEval = '';
            for i = 1:numel(obj.ReleaseFunction)
                releaseCoderCEval = sprintf([releaseCoderCEval '%s\n'],getFunctionCall(obj,obj.ReleaseFunction{i}));
            end
            releaseCoderCEval=strtrim(releaseCoderCEval);
            if strcmpi(obj.BlockType,'source')
                if numel(obj.Outputs)>0
                    if numel(obj.Outputs)<2
                        propOut = obj.Outputs{1}{1}.Name;
                        stepOutInit = sprintf('%s = %s(zeros(1,%s));\n',obj.Outputs{1}{1}.Name,obj.Outputs{1}{1}.DataType,char(extractAfter(extractBetween(obj.Outputs{1}{1}.Size,'[',']'),',')));

                    else
                        propOut = ['[' obj.Outputs{1}{1}.Name];
                        stepOutInit = sprintf('%s = %s(zeros(1,%s));\n',obj.Outputs{1}{1}.Name,obj.Outputs{1}{1}.DataType,char(extractAfter(extractBetween(obj.Outputs{1}{1}.Size,'[',']'),',')));
                        for i = 2:length(obj.Outputs)
                            propOut = sprintf([propOut ',%s'],obj.Outputs{i}{1}.Name);
                            %                             stepOutInit = sprintf([stepOutInit '%s = %s(%s);\n'],obj.Outputs{1}{1}.Name,obj.Outputs{1}{1}.DataType,obj.Outputs{1}{1}.InitValue);
                            stepOutInit = sprintf([stepOutInit '%s = %s(zeros(1,%s));\n'],obj.Outputs{i}{1}.Name,obj.Outputs{i}{1}.DataType,char(extractAfter(extractBetween(obj.Outputs{i}{1}.Size,'[',']'),',')));
                        end
                        propOut =[propOut ']'];
                        propOut = strtrim(propOut);
                        stepOutInit = strtrim(stepOutInit);
                    end
                    propOut = [propOut ' = '];
                else
                    propOut = '';
                    stepOutInit = '';
                end
                fixedOutput = '';
                complexOutput = '';
                sizeOutput = '';
                validateOutput = '';
                outputNames = '';
                for i = 1:numel(obj.Outputs)
                    fixedOutput = sprintf([fixedOutput 'varargout{%d} = true;\n'],uint8(i));
                    outputNames = sprintf([outputNames 'varargout{%d} = ''%s'';\n'],uint8(i),obj.Outputs{i}{1}.Name);
                    complexOutput = sprintf([complexOutput 'varargout{%d} = false;\n'],uint8(i));
                    sizeOutput = sprintf([sizeOutput 'varargout{%d} = %s;\n'],uint8(i),obj.Outputs{i}{1}.Size);
                    validateOutput = sprintf([validateOutput 'varargout{%d} = ''%s'';\n'],uint8(i),obj.Outputs{i}{1}.DataType);
                end
                fixedOutput=strtrim(fixedOutput);
                outputNames=strtrim(outputNames);
                complexOutput=strtrim(complexOutput);
                sizeOutput=strtrim(sizeOutput);
                validateOutput=strtrim(validateOutput);
                sourceFile ='';
                for i = 1:numel(obj.SourceFile)
                    sourceFileLocation = sprintf(['''%s'''],char(obj.SourcePath{1}));
                    sourceFile = [sourceFile 'addSourceFiles(buildInfo,'''  char(obj.SourceFile{i})   ''',' sourceFileLocation ');'];
                    %                     sourceFile = sprintf([sourceFile 'addSourceFiles(buildInfo,' '''%s'''  ',' sourceFileLocation ');\n'],char(obj.SourceFile{i}));
                end
                sourceFile = [sourceFile 'addSourceFiles(buildInfo,''' [blockName '.cpp'] ''',' sourceFileLocation ');'];
                obj.SourceFile{end+1} = [blockName '.cpp'];
                headerPaths ='';
                for i= 1:numel(obj.HeaderPath)
                    %                      buildInfo.addIncludePaths(fullfile(spkgrootDir,'thirdparty\vl53l0x\platform\inc'));
                    headerPaths = sprintf([headerPaths 'buildInfo.addIncludePaths(', '''%s''',');\n'],obj.HeaderPath{i});
                end
                processTemplateFile(obj,fullfile(matlabshared.sensors.internal.getSensorRootDir,'+matlabshared','+sensors','+utils',strcat(obj.Peripheral,'Source.m')),fileName,...
                    {strcat(obj.Peripheral,'Source'),blockName,...
                    'BLOCK_MASK_DESCR',obj.MaskDescription,...
                    'PROPERTIES_TUNABLE',propTunable,...
                    'PROPERTIES_NONTUNABLE','',...
                    'PROPERTIES_PRIVATE',sprintf('%s\n%s',propConst,propInternal),...
                    'VARIABLE_INIT',sprintf('%s\n%s\n%s',propertyInitNonTunable,propertyInitConstant,propertyInitInternal),...
                    'SETUP_CODER_CINCLUDE',['coder.cinclude(''' headerFileName '.h'');'],...
                    'SETUP_CODER_CEVAL',setupCoderCEval,...
                    'STEP_RETURN_PARAM',propOut,...
                    'STEP_OUPUT_INIT',stepOutInit,...
                    'STEP_CODER_CEVAL',stepCoderCEval,...
                    'RELEASE_CODER_CEVAL',releaseCoderCEval,...
                    'NUM_INPUT',num2str(numel(obj.Inputs)),...
                    'NUM_OUTPUT',num2str(numel(obj.Outputs)),...
                    'OUTPUT_FIXED',fixedOutput,...
                    'OUTPUT_NAME',outputNames,...
                    'OUTPUT_COMPLEX',complexOutput,...
                    'OUTPUT_SIZE',sizeOutput,...propTunabl
                    'OUTPUT_DATATYPE',validateOutput,...
                    'HEARDERPATHS',headerPaths,...
                    'SOURCEFILE',sourceFile...
                    })
                fileName1 = fullfile(obj.HeaderPath{:}, [blockName '.h']);
                fileName2 = fullfile(obj.SourcePath{:}, [blockName '.cpp']);
                includeFileName = ['"' fileName1 '"'];
                processTemplateFile(obj,fullfile(matlabshared.sensors.internal.getSensorRootDir,'+matlabshared','+sensors','+utils','Hook.h'),fileName1,{'##SETUP_FUNCTION_NAME##',[setupFunctionName ';'], '##STEP_FUNCTION_NAME##',[stepFunctionName ';']});
                processTemplateFile(obj,fullfile(matlabshared.sensors.internal.getSensorRootDir,'+matlabshared','+sensors','+utils','Hook.cpp'),fileName2,{'##SETUP_FUNCTION_NAME##',setupFunctionName, '##STEP_FUNCTION_NAME##',stepFunctionName,'##HEADER_FILE##',includeFileName});
            else
                propIn = '';
                for i = 1:numel(obj.Inputs)
                    propIn = sprintf([propIn ',%s'],obj.Inputs{i}{1}.Name);
                end
                propIn=strtrim(propIn);

                fixedInput = '';
                validateInput = '';
                for i = 1:numel(obj.Inputs)
                    fixedInput = sprintf([fixedInput 'varargout{%d} = true;\n'],uint8(i));
                    validateInput = sprintf([validateInput 'validateattributes(%s,{''%s''},{''scalar''},'''',''%s'');\n'],obj.Inputs{i}{1}.Name,obj.Inputs{i}{1}.DataType,obj.Inputs{i}{1}.Name);
                end
                fixedInput=strtrim(fixedInput);
                validateInput=strtrim(validateInput);
                sourceFile ='';
                for i = 1:numel(obj.SourceFile)
                    sourceFileLocation = sprintf(['''%s'''],char(obj.SourcePath{1}));
                    sourceFile = [sourceFile 'addSourceFiles(buildInfo,'''  char(obj.SourceFile{i})   ''',' sourceFileLocation ');'];
                    %                     sourceFile = sprintf([sourceFile 'addSourceFiles(buildInfo,' '''%s'''  ',' sourceFileLocation ');\n'],char(obj.SourceFile{i}));
                end
                sourceFile = [sourceFile 'addSourceFiles(buildInfo,''' [blockName '.cpp'] ''',' sourceFileLocation ');'];
                processTemplateFile(obj,fullfile(matlabshared.sensors.internal.getSensorRootDir,'+matlabshared','+sensors','+utils',strcat(obj.peripheral,'Sink.m')),fileName,...
                    {'SYSTEM_OBJECT_NAME',blockName,...
                    'BLOCK_MASK_DESCR',obj.MaskDescription,...
                    'PROPERTIES_TUNABLE',propTunable,...
                    'PROPERTIES_NONTUNABLE','',...
                    'PROPERTIES_PRIVATE',sprintf('%s\n%s',propConst,propInternal),...
                    'VARIABLE_INIT',sprintf('%s\n%s\n%s',propertyInitNonTunable,propertyInitConstant,propertyInitInternal),...
                    'SETUP_CODER_CINCLUDE',['coder.cinclude(''' headerFileName '.h'');'],...
                    'SETUP_CODER_CEVAL',setupCoderCEval,...
                    'STEP_INPUT_PARAM',propIn,...
                    'STEP_CODER_CEVAL',stepCoderCEval,...
                    'RELEASE_CODER_CEVAL',releaseCoderCEval,...
                    'NUM_INPUT',num2str(numel(obj.Inputs)),...
                    'NUM_OUTPUT',num2str(numel(obj.Outputs)),...
                    'INPUT_FIXED',fixedInput,...
                    'VALIDATE_INPUT',validateInput,...
                    'HEADERFILE',[headerFileName '.h'],...
                    'SOURCEFILE',sourceFile...
                    })

            end
            h = matlab.desktop.editor.openDocument(fullfile(pwd,fileName));
            h.smartIndentContents;
            h.save;
            h.close;
        end
    end
end
