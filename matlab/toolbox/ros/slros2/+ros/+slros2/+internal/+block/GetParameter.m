classdef GetParameter < matlab.System
    %This class is for internal use only. It may be removed in the future.

    %GetParameter Class for ROS 2 Get Parameter block

    %   Copyright 2022-2023 The MathWorks, Inc.

    %#codegen

    properties (Nontunable)
        %ParameterName Name
        %   This system object will use ParameterName as specified in both
        %   simulation and code generation. In particular, it will not add a
        %   "/" in front of the name, as that forces the topic to be in the
        %   absolute namespace.
        ParameterName = 'my_namespace.my_param'

        %ParameterType Data type
        %   This is the data type of the Value output. Possible values are
        %   double, int64, boolean, string. This data type is only valid in
        %   Simulink. For the corresponding MATLAB data type string, refer
        %   to the ParameterTypeML property.
        %   Default: 'double'
        ParameterType = 'double'

        %ParameterMaxArrayLength Maximum length
        %   This parameter only applies if the user specifies an array data type.
        %   The Value output of the Get Parameter block will always be a
        %   fixed-size array with this size. Any array that has more
        %   elements than this parameter will be truncated.
        %   Default: 16
        ParameterMaxArrayLength = 16

        %ParameterInitialValue - Initial value
        %   The initial value is used as output if the parameter with the
        %   given name does not exist on model launch, or if the parameter
        %   data type does not match.
        %   If error conditions occur during runtime, the last received
        %   value is used instead of this initial value.
        %   Default: 0.0
        ParameterInitialValue = 0.0

        %SampleTime - Sample time for source block
        %   Default: -1 (inherited)
        SampleTime = -1
    end

    properties (Constant, Hidden)
        %MessageCatalogName - Name of the block
        %
        %   This property is used by the NodeDependent base class to
        %   customize error messages with the block name.
        %   Due a limitation in Embedded MATLAB code-generation with UTF-8 characters,
        %   use English text instead of message("ros:slros2:blockmask:GetParamMaskTitle").getString
        MessageCatalogName = 'ROS 2 Get Parameter'
    end

    % The following should ideally not show up in the MATLAB System block
    % dialog. However, setting them as 'Hidden' will prevent them from
    % being accessible via set_param & get_param.
    %
    %   ModelName is needed for managing the node instance
    %   BlockId is needed to generate a unique identifier in codegen
    properties (Nontunable)
        %ModelName - Name of Simulink model
        ModelName = 'untitled'

        %BlockId - Simulink Block Identifier
        %   Used to generate unique identifier for the block during code
        %   generation. This should be obtained using Simulink.ID.getSID()
        %   on the library block (*not* the MATLAB system block). The
        %   SID has the format '<modelName>:<blocknum>'
        BlockId = 'param_'
    end

    properties (Nontunable, Hidden)
        %ParameterTypeML - The ROS 2 parameter type as MATLAB data type
        %   To avoid always converting back and forth between the two
        %   representations, the system object converts it once whenever
        %   the ParameterType is set.
        ParameterTypeML = 'double'
    end

    properties (SetAccess = immutable, GetAccess = protected)
        %SampleTimeHandler - Object for validating sample time settings
        SampleTimeHandler
    end

    % These are the options for the drop down lists
    % The properties are constant, hidden, and transient based on the
    % system object documentation
    properties (Constant, Hidden, Transient)
        %ParameterTypeSet - Drop down choices for parameter data type

        % Note: Simulink does not support string-arrays
        % https://www.mathworks.com/help/simulink/ug/simulink-strings.html
        ParameterTypeSet = matlab.system.StringSet({'double','int64','boolean',...
            'uint8[]', 'double[]', 'int64[]', 'boolean[]'});
    end

    properties (Access = ...
            {?ros.slros2.internal.block.GetParameter, ...
            ?matlab.unittest.TestCase})
        ROS2NodeHandle = []
        LastParamGetValue = []
        LastValidOutput = []
        LastInvalidLen = []
        LastInvalidDType = []
    end

    properties(Constant, Access = protected)
        %HeaderFile - Name of header file with declarations for variables and types
        %   It is referred to in code emitted by setupImpl and stepImpl.
        HeaderFile = ros.slros.internal.cgen.Constants.InitCode.HeaderFile
    end

    methods
        function obj = GetParameter(varargin)
            %GetParameter Standard constructor

            % Enable code to be generated even if this file is p-coded
            coder.allowpcode('plain');

            % Support name-value pair arguments when constructing the object.
            setProperties(obj, nargin, varargin{:});

            % Initialize sample time validation object
            obj.SampleTimeHandler = robotics.slcore.internal.block.SampleTimeImpl;
        end

        function set.ParameterMaxArrayLength(obj, val)
            %set.ParameterMaxArrayLength Set the maximum permissible array size
            %   The input can be any numeric data type, as long as it's an
            %   integer and within the limits of the uint32 data type. The
            %   maximum array length has to be positive.

            validateattributes(val, {'numeric'}, {'real','positive',...
                'nonempty','scalar','nonnan','integer',...
                '<=', intmax('uint32')}, ...
                '', 'ParameterMaxArrayLength');
            obj.ParameterMaxArrayLength = uint32(val);
        end

        function set.ParameterInitialValue(obj, val)
            %set.ParameterInitialValue Set the initial value
            %   Validate the user input based on the data type of the ROS
            %   parameter.
            
            argName = 'ParameterInitialValue';
            mlDType = obj.ParameterTypeML; %#ok<MCSUP>
            if isScalarDataType(obj)
                attr = 'scalar';
            else
                attr = 'vector';
            end
            switch(mlDType)
                case 'uint8'
                    val = convertStringsToChars(val);
                    if ischar(val)
                        % convert char[] to uint8[]
                        val = uint8(val);
                    end
                    % Validate byte-arrays differently
                    validateattributes(val,{'numeric'},...
                        {'real','integer','<=', intmax('uint8'), ...
                        '>=', intmin('uint8'),'vector'},'',argName);

                case 'int64'
                    % Make sure that value is within int64 data type limits.
                    validateattributes(val, {'numeric'}, ...
                        {'nonempty','real',attr,'integer', '<=', intmax('int64'), ...
                        '>=', intmin('int64')},'',argName);
                case 'logical'
                    % Allow numeric inputs as long as they can be
                    % interpreted as logical.

                    % Excluding nan inputs, since they cannot be cast to a
                    % logical
                    validateattributes(val, {'numeric','logical'}, ...
                        {'nonempty','real',attr,'nonnan'}, '', ...
                        argName);
                case 'double'
                    % Any other numeric data type can be represented as a
                    % double.
                    validateattributes(val, {'numeric','logical'},...
                        {'nonempty','real',attr}, ...
                        '', argName);
                otherwise
                    error(message('ros:slros:getparam:InitialDataTypeNotValid',mlDType));
            end
            obj.ParameterInitialValue = cast(val,mlDType);
        end

        function set.SampleTime(obj, sampleTime)
            %set.SampleTime Validate sample time specified by user
            obj.SampleTime = obj.SampleTimeHandler.validate(sampleTime); %#ok<MCSUP>
        end

        function set.ParameterName(obj, val)
            %set.ParameterName Set the parameter name
            %   The name is validated based on standard ROS Naming rules,
            %   and an error is thrown if the parameter or namespace of the
            %   parameter does not conform to the standard.

            validateattributes(val, {'char'}, {'nonempty'}, '', 'ParameterName');
            if coder.target("MATLAB")
                if ~all(cellfun(@(x)isvarname(x),strsplit(val,'.')))
                    diag = MSLDiagnostic([],message('ros:slros2:blockmask:GetParamInvalidName',val));
                    reportAsError(diag);
                end
            end
            obj.ParameterName = val;
        end

        function set.ParameterType(obj, val)
            %set.ParameterType Set the parameter type
            %   This is already a drop down, so no separate data type
            %   validation is necessary.
            %   Convert the Simulink data type into the corresponding
            %   MATLAB data type.

            obj.ParameterTypeML = obj.simulinkToMatlab(val); %#ok<MCSUP>
            obj.ParameterType = val;

        end

        function mlDataType = simulinkToMatlab(~, slDataType )
            %simulinkToMatlab Convert Simulink data type to MATLAB data type

            slDataType = strrep(slDataType,'[]','');
            switch slDataType
                case {'double','int64','uint8'}
                    mlDataType = slDataType;
                case 'boolean'
                    mlDataType = 'logical';
                otherwise
                    error(message('ros:slros:getparam:DataTypeSourceNotValid',slDataType));
            end

        end

        function set.ModelName(obj, val)
            %set.ModelName Set model name property
            validateattributes(val, {'char'}, {'nonempty'}, '', 'ModelName');
            obj.ModelName = val;
        end

        function set.BlockId(obj, val)
            %set.BlockId Set block ID property

            validateattributes(val, {'char'}, {'nonempty'}, '', 'BlockId');
            obj.BlockId = val;
        end
    end

    %% Methods that are implementations of abstract NodeDependent mixin
    methods (Access = protected)

        function name = modelName(obj)
            name = obj.ModelName;
        end
    end

    methods (Access = protected)

        function ret = isScalarDataType(obj)
            ret = ~contains(obj.ParameterType,'[]');
        end
        function flag = isInactivePropertyImpl(obj, prop)
            if strcmp(prop, 'ParameterMaxArrayLength')
                flag = isScalarDataType(obj);
            else
                flag = false;
            end
        end

        function sts = getSampleTimeImpl(obj)
            %getSampleTimeImpl Return sample time specification

            sts_base = obj.SampleTimeHandler.createSampleTimeSpec();

            % Add allow constant sample time to inherited
            if sts_base.Type == "Inherited"
                sts = createSampleTime(obj, "Type", "Inherited", "Allow", "Constant");
            else
                sts = sts_base;
            end
        end

        function setupImpl(obj)
            %setupImpl Model initialization call
            %   setupImpl is called when model is being initialized at the
            %   start of a simulation.

            %setupImpl Perform one-time setup of system object
            if coder.target('MATLAB')
                % Only run simulation setup if it is not in code generation
                % process
                isCodegen = ros.codertarget.internal.isCodegen;
                if ~isCodegen
                    % Executing in MATLAB interpreted mode
                    modelState = ros.slros.internal.sim.ModelStateManager.getState(obj.ModelName, 'create');
                    % The following could be a separate method, but system
                    % object infrastructure doesn't appear to allow it
                    if isempty(modelState.ROSNode) || ~isValidNode(modelState.ROSNode)
                        uniqueName = ros.slros.internal.block.ROSPubSubBase.makeUniqueName(obj.ModelName);
                        modelState.ROSNode = ros2node(uniqueName, ...
                            ros.ros2.internal.NetworkIntrospection.getDomainIDForSimulink, ...
                            'RMWImplementation', ...
                            ros.ros2.internal.NetworkIntrospection.getRMWImplementationForSimulink);
                    end
                    modelState.incrNodeRefCount();
                    obj.ROS2NodeHandle = modelState.ROSNode;
                    if isScalarDataType(obj)
                        initVal = obj.ParameterInitialValue;
                    else
                        initialValue = obj.ParameterInitialValue;
                        len = min(length(initialValue),obj.ParameterMaxArrayLength);
                        initVal = initialValue(1:len);
                    end
                    setSingleParameter(obj.ROS2NodeHandle,obj.ParameterName,initVal);
                    obj.LastValidOutput = {obj.ParameterInitialValue, uint32(length(obj.ParameterInitialValue))};
                end
            elseif coder.target('RtwForRapid')
                % Rapid Accelerator. In this mode, coder.target('Rtw')
                % returns true as well, so it is important to check for
                % 'RtwForRapid' before checking for 'Rtw'
                coder.internal.errorIf(true, 'ros:slros2:codegen:RapidAccelNotSupported', 'ROS2 Parameter');

            elseif coder.target('Rtw')
                coder.cinclude(ros.slros2.internal.cgen.Constants.NodeInterface.CommonHeader);
                % Null terminated string
                prmName = [obj.ParameterName, 0];
                blkId = obj.BlockId;
                initVal = convertStringsToChars(obj.ParameterInitialValue);
                maxLength = obj.ParameterMaxArrayLength;                
                coder.ceval([blkId,'.initParam'], coder.rref(prmName));
                if isScalarDataType(obj)
                    coder.ceval([blkId '.setInitialValue'],initVal);
                else
                    initLen = uint32(length(initVal));
                    % Truncate the initial value in generated code if it is
                    % longer than the maximum length
                    if initLen > maxLength
                        initLen = maxLength;
                        truncatedValue = initVal(1:maxLength);
                        coder.ceval([blkId,'.setInitialValue'], coder.rref(truncatedValue), ...
                            initLen);
                    else
                        coder.ceval([blkId,'.setInitialValue'], coder.rref(initVal), ...
                            initLen);
                    end
                end
            elseif  coder.target('Sfun')
                % 'Sfun'  - Simulation through CodeGen target
                % Do nothing. MATLAB System block first does a pre-codegen
                % compile with 'Sfun' target, & then does the "proper"
                % codegen compile with Rtw or RtwForRapid, as appropriate.

            else
                % 'RtwForSim' - ModelReference SIM target
                % 'MEX', 'HDL', 'Custom' - Not applicable to MATLAB System block
                coder.internal.errorIf(true, 'ros:slros:sysobj:UnsupportedCodegenMode', coder.target);
            end
        end

        % Release node handle
        function releaseImpl(obj)
            if coder.target('MATLAB')
                % release implementation is only required for simulation
                isCodegen = ros.codertarget.internal.isCodegen;
                if ~isCodegen
                    st = ros.slros.internal.sim.ModelStateManager.getState(obj.ModelName);
                    st.decrNodeRefCount();
                    obj.ROS2NodeHandle = [];
                    if  ~st.nodeHasReferrers()
                        ros.slros.internal.sim.ModelStateManager.clearState(obj.ModelName);
                    end
                end
            end
        end


        function varargout = stepImpl(obj)
            %stepImpl System Object step call
            len = uint32(1);
            mlDType = obj.ParameterTypeML;
            maxLen =  obj.ParameterMaxArrayLength;
            if coder.target("MATLAB")
                % Only run simulation setup if it is not in code generation
                % process
                isCodegen = ros.codertarget.internal.isCodegen;
                if ~isCodegen
                    % Interpreted execution
                    value = getParameter(obj.ROS2NodeHandle,obj.ParameterName);
                    if isequal('uint8',mlDType)
                        % accept char for uint8[]
                        isValidType = isa(value,'char') || isa(value,mlDType);
                    else
                        isValidType = isa(value,mlDType);
                    end
                    useLastValue = ~isValidType || isequal(value,obj.LastParamGetValue);
                    blk = gcb;
                    if useLastValue
                        dType = class(value);
                        varargout = obj.LastValidOutput;
                        if ~isValidType && ~isequal(obj.LastInvalidDType,dType)
                            diag = MSLDiagnostic([],message('ros:slros2:blockmask:GetParamInvalidDataType',...
                                blk,mlDType,dType));
                            reportAsWarning(diag);
                            obj.LastInvalidDType = dType;
                        end
                    else
                        obj.LastInvalidDType = [];
                        obj.LastParamGetValue = value;
                        % Reshape to row
                        if iscolumn(value)
                            value = value.';
                        end
                        if iscell(value)
                            value = cast(cell2mat(value),mlDType);
                        else
                            value = cast(value,mlDType);
                        end
                        if isScalarDataType(obj)
                            varargout{1} = value;
                        else
                            recvdLen = uint32(length(value));
                            if maxLen < recvdLen
                                value = value(1:maxLen);
                                if ~isequal(recvdLen,obj.LastInvalidLen)
                                    diag = MSLDiagnostic([],message('ros:slros2:blockmask:GetParamTruncateVal',...
                                        obj.ParameterName,maxLen,recvdLen,blk));
                                    reportAsWarning(diag);
                                    obj.LastInvalidLen = recvdLen;
                                end
                            elseif maxLen > recvdLen
                                value(recvdLen+1:maxLen) = cast(0,mlDType);
                            end                      
                            len = min(recvdLen,maxLen);
                        end
                        varargout{1} = value;
                        varargout{2} = len;
                        obj.LastValidOutput = varargout;                    
                    end
                else
                    if isScalarDataType(obj)
                        paramValue = cast(0,mlDType);
                        value = coder.nullcopy(paramValue);
                    else
                        paramValue = zeros(1,maxLen,mlDType);
                        value = coder.nullcopy(paramValue);
                    end
                    varargout{1} = value;
                    varargout{2} = len;
                end
            elseif coder.target("Rtw")
                % Initializing paramValue with ParameterMaxArrayLength zeros ensures
                % that we don't have to take care of zero padding in the C++ code.
                blkId = obj.BlockId;
                if isScalarDataType(obj)
                    paramValue = cast(0,mlDType);
                    value = coder.nullcopy(paramValue);
                    coder.ceval([blkId,'.getParameter'],coder.wref(value));
                else
                    paramValue = zeros(1,maxLen,mlDType);
                    value = coder.nullcopy(paramValue);
                    coder.ceval([blkId,'.getParameter'], maxLen, ...
                        coder.wref(value),coder.wref(len));
                end
                varargout{1} = value;
                varargout{2} = len;
            end
        end

        % We don't save SimState, since there is no way save & restore
        % the GetParameter object. However, saveObjectImpl and loadObjectImpl
        % are required since we have private properties.
        function s = saveObjectImpl(obj)
            % The errorIf() below will ensure that FastRestart cannot be used
            % in a model with ROS blocks
            coder.internal.error('ros:slros:nodedependent:SimStateNotSupported', ...
                obj.MessageCatalogName);
            s = saveObjectImpl@matlab.System(obj);
        end

        function [out1,out2] = getOutputNamesImpl(~)
            % Return output port names for System block
            out1 = 'Value';
            out2 = 'Length';
        end


        function num = getNumInputsImpl(~)
            %getNumInputsImpl Get number of inputs
            num = 0;
        end

        function num = getNumOutputsImpl(obj)
            %getNumOutputsImpl Get number of outputs
            %   The number of outputs is configurable based on the checkbox
            %   value of "Show ErrorCode output".

            % Value and Length
            if isScalarDataType(obj)
                num = 1;
            else
                num = 2;
            end
        end

        function varargout = getOutputSizeImpl(obj)
            %getOutputSizeImpl Get output size
            % The other output parameters (array length) will
            % always be scalar
            maxLen = double([1 obj.ParameterMaxArrayLength]);
            if isScalarDataType(obj)
                varargout = {1, [1 1]};
            else
                varargout = {maxLen, [1 1]};
            end
        end

        function varargout = isOutputFixedSizeImpl(~)
            varargout =  {true, true};
        end

        function varargout = getOutputDataTypeImpl(obj)
            %getOutputDataTypeImpl Get data type of outputs
            %   The data type of the value is determined by user. The error
            %   code is always a uint8. The length of the receive
            varargout = {obj.ParameterTypeML 'uint32'};
        end

        function varargout = isOutputComplexImpl(~)
            %isOutputComplexImpl Are outputs complex-valued
            varargout = {false, false};
        end

        function maskDisplay = getMaskDisplayImpl(obj)
            %getMaskDisplayImpl Customize the mask icon display
            %   This method allows customization of the mask display code. Note
            %   that this works both for the base mask and for the
            %   mask-on-mask.

            % Override the default system object mask with blank white icon with no-labels
            numOutputs = obj.getNumOutputsImpl;
            [outputNames{1:numOutputs}] = obj.getOutputNamesImpl;

            portLabelText = {};
            for i = 1:length(outputNames)
                portLabelText = [portLabelText ['port_label(''output'', ' num2str(i) ', ''' outputNames{i} ''');']]; %#ok<AGROW>
            end
            if length(obj.ParameterName) > 16
                paramNameText = ['text(83, 12, ''' obj.ParameterName ''', ''horizontalAlignment'', ''right'');'];
            else
                paramNameText = ['text(45, 12, ''' obj.ParameterName ''', ''horizontalAlignment'', ''center'');'];
            end
            maskDisplay = { ...
                ['plot([110,110,110,110],[110,110,110,110]);', newline], ... % Fix min and max x,y co-ordinates for autoscale mask units
                ['plot([0,0,0,0],[0,0,0,0]);', newline],...
                'color(''black'')', ...
                paramNameText, ...
                portLabelText{:}};
        end
    end

    methods(Static, Access = protected)
        function simMode = getSimulateUsingImpl
            %getSimulateUsingImpl Restrict simulation mode to interpreted execution
            simMode = 'Interpreted execution';
        end

        function flag = showSimulateUsingImpl
            %showSimulateUsingImpl Do now show simulation execution mode drop down in block mask
            flag = false;
        end

        % Note that this is ignored for the mask-on-mask
        function header = getHeaderImpl
            %getHeaderImpl Create mask header
            %   This only has an effect on the base mask.
            header = matlab.system.display.Header(mfilename('class'), ...
                'Title', message('ros:slros2:blockmask:GetParamMaskTitle').getString, ...
                'Text', message('ros:slros2:blockmask:GetParamMaskDescription').getString, ...
                'ShowSourceLink', false);
        end

        % Note that this is ignored for the mask-on-mask
        % This function is important for the promotion of parameters to
        % work correctly.
        function groups = getPropertyGroupsImpl(~)
            %getPropertyGroupsImpl Create property display groups.
            %   This only has an effect on the base mask.

            paramGroup = matlab.system.display.Section(...
                'Title', message('ros:slros2:blockmask:ParamContainerTitle').getString,...
                'PropertyList', {'ParameterName','ParameterType','ParameterMaxArrayLength','ParameterInitialValue'});
            otherGroup = matlab.system.display.Section(...
                'Title', message('ros:slros:blockmask:ParametersHeadingPrompt').getString,...
                'PropertyList', {'SampleTime', 'ModelName', 'BlockId'});
            groups = [paramGroup,otherGroup];
        end
    end
end
