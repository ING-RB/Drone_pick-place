function getBusDefnForStruct(emptyStruct, model, busNamePrefix)
%This function is for internal use only. It may be removed in the future.


%getBusDefnForStruct - Create Simulink bus object corresponding to a gazebo Struct message
%
%    getBusDefnForStruct(MSG) returns an array of Simulink.Bus objects
%    corresponding to Struct message MSG and any nested messages inside it.
%    MSG should be an empty message, since the only way to determine if a
%    property is a variable-length array is to check if its value is [].
%
%    Note:
%    * This function creates the bus objects in the global scope.
%
%
%    * If the struct message has variable-size array properties, these are
%      converted to fixed-length arrays (with length of 128), and the
%      associated metadata element is added to the bus object.
%

%   Copyright 2019-2022 The MathWorks, Inc.

% Good test for this function:
%include a good test Struct to test the function

%retain original bus prefix name
    if nargin < 3
        busNamePrefix = 'SL_Bus_';
    end

    map = containers.Map;
    processBus(emptyStruct, model, map,busNamePrefix);
    requiredBusesCellArray = values(map);
    requiredBuses = [requiredBusesCellArray{:}];

    for i = 1:numel(requiredBuses)
        bus = requiredBuses(i).Bus;
        elemInfo = robotics.slcore.internal.bus.BusItemInfo(bus.Description );
        msgType = elemInfo.MsgType;
        busname = robotics.slcore.internal.bus.Util.messageTypeToBusName(msgType, model,busNamePrefix);
        robotics.slcore.internal.util.assigninGlobalScope(model, busname, bus);
    end

end

%%
function processBus(emptyStruct, model,map,busNamePrefix)
    if isempty(emptyStruct)
        % nothing to do
        return;
    end

    % should not be making any recursive calls with arrays of messages
    assert(numel(emptyStruct)==1);
    msgType = emptyStruct.MessageType;

    if isKey(map, msgType)
        % nothing to do
        return;
    end

    canonicalOrder = fieldnames(emptyStruct);

    busElements = Simulink.BusElement.empty;

    superClass = superclasses(emptyStruct);

    for i =1:length(canonicalOrder)
        propertyName = canonicalOrder{i};

        if strcmp(propertyName,'MessageType')
            continue;
        end

        elemName = propertyName;

        elem = Simulink.BusElement;
        elem.Name = elemName;
        elem.Dimensions = 1;
        elem.SampleTime = -1;
        elem.Complexity = 'real';
        elem.SamplingMode = 'Sample based';
        elem.Min = [];
        elem.Max = [];
        elem.DocUnits = '';
        elem.Description = '';
        elemInfo = robotics.slcore.internal.bus.BusItemInfo;

        data = emptyStruct.(propertyName);

        isLogicalOrNumericType = isa(data,'logical') || isa(data,'numeric');
        isStringType = isa(data, 'char');
        isGazeboMessage = strcmp(superclasses(data), superClass);

        %--------------------------------------------------------------------------
        % Handle primitive and complex message properties

        if isLogicalOrNumericType
            if isa(data,'logical')
                elem.DataType = 'boolean';
            elseif isa(data, 'int64') || isa(data, 'uint64')
                elem.DataType = 'double';
                elemInfo.Int64Type = class(data);
                robotics.internal.warningNoBacktrace(...
                    message('robotics:robotslgazebo:busconvert:Int64NotSupported', ...
                            propertyName, msgType, class(data), 'double'));
            else
                elem.DataType = class(data);
            end

        elseif isStringType
            elem.DataType = 'uint8';
            elemInfo.PrimitiveStringType = 'string';

        elseif isGazeboMessage
            datainstance = getDataInstance(data);
            assert(isprop(datainstance, 'MessageType'));
            messageType = datainstance.MessageType;
            dataTypeStr = robotics.slcore.internal.bus.Util.messageTypeToDataTypeStr(messageType, model,busNamePrefix);
            elem.DataType = dataTypeStr;
            elemInfo.MsgType = messageType;
            processBus(datainstance, model, map,busNamePrefix); % recursive call

        else
            assert(false);
        end

        %------------------------------------------------------------------
        % Add metadata related to variable vs. fixed-length arrays

        isVarsizeArray = isempty(data) || isStringType;
        if isVarsizeArray
            elemInfo.IsVarLen = true;
            elem.DimensionsMode = 'Variable';
            % SL buses require non-zero value for dimensions, so set it to 1
            % for now. Conversion from Variable-length to Fixed-length array
            % is set to maximum length of 128
            elem.Dimensions = max(numel(data), elemInfo.VariableBusDefaultLength);
            elem.Description = elemInfo.toDescription();
            % Add the array and the corresponding SL_Info element to the bus
            busElements(end+1) = elem;%#ok<AGROW>

        else
            elemInfo.IsVarLen = false;
            elem.DimensionsMode = 'Fixed';
            elem.Dimensions = max(numel(data),1);
            elem.Description = elemInfo.toDescription();
            busElements(end+1) = elem; %#ok<AGROW>
        end

    end

    businfo = robotics.slcore.internal.bus.BusItemInfo;
    businfo.MsgType = msgType;
    mybus = Simulink.Bus;
    mybus.HeaderFile = '';
    mybus.Description = businfo.toDescription();
    mybus.DataScope = 'Auto';
    mybus.Alignment = -1;
    mybus.Elements = busElements;

    map(msgType) = struct('MessageType', msgType, 'Bus', mybus); %#ok<NASGU>

end

%%
function datainstance = getDataInstance(data)
    if isempty(data)
        datainstance = feval(class(data));
    else
        datainstance = data(1);
    end
end
