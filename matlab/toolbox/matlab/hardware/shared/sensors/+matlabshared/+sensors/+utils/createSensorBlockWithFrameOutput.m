function createSensorBlockWithFrameOutput(blkh,varargin)
% Create subsystem containing sensor block specified by block handle blkh,
% and frame block and updates masks accordingly
%
% Note : Ensure that all block outputs are selected for block specified by
% blkh before executing the command
%
% createSubsysForFrameOutput(blkh,'Name','LSM6DSL'), creates a subsystem
% named LSM6DSL containing sensor block and frame block and updates masks
%
% createSubsysForFrameOutput(blkh,'ExcludedParams','I2CModule'), creates a
% subsystem containing sensor blocks and frame block and updates masks. The
% 'I2CModule' of the sensor block will be promoted but will be hidden on
% top mask

%   Copyright 2022 The MathWorks, Inc.
try
    newbdSubsysName = '';
    newbd = '';
    p = inputParser;
    % System object block, This value can be block path(gcb) or block handle
    addRequired(p,'handle',@(x)validateattributes(x,{'double','char','string'},{'nonempty'}));
    % Name of the block as needs to be shown in the library
    addParameter(p,'Name','',@(x)validateattributes(x,{'char','string'},{'nonempty'}));
    % The parameter names that is set as 'IsGraphical' false in system object
    % should not be visibile in the mask
    addParameter(p,'ExcludedParams','',@(x)validateattributes(x,{'cell'},{'nonempty'}));
    addParameter(p,'ModelType','Library');
    addParameter(p,'ModelName','sensorFrameOut',@(x)validateattributes(x,{'char','string'},{'nonempty'}));
    parse(p,blkh,varargin{:});
    % Validate model type 
    validatestring(p.Results.ModelType,{'library','model'});
    % Validate the block specified
    blkh = getValidHandle(p.Results.handle);
    nameOfBlock = p.Results.Name;
    excludedParams = p.Results.ExcludedParams;
    % Get details of sensor block
    temp = get(blkh);
    sensorBlock.Handle = temp.Handle;
    sensorBlock.Name = temp.Name;
    sensorBlock.Parent = temp.Parent;
    sensorBlock.FullPath = [sensorBlock.Parent,'/',sensorBlock.Name];
    if ~isempty(Simulink.Mask.get(blkh).BaseMask)
        error(message('matlab_sensors:general:ExpectedSystemObjectBlockH'))
    end
    % Create a new model
    newbd = new_system;
    newModelName = get_param(newbd,'Name');
    if isempty(nameOfBlock)
        subsys.Name = 'Subsystem sensor block';
    else
        subsys.Name = nameOfBlock;
    end
    % add the sensor block to the model
    sensorBlock.handle = add_block(sensorBlock.FullPath, [newModelName '/' sensorBlock.Name]);
    sensorBlock.Name = 'Base sensor block';
    set_param(sensorBlock.handle,'Name',sensorBlock.Name);
    % Get the block outputs of the base sensor block
    ports = get_param(sensorBlock.handle,"Ports");
    numOut =  ports(2);
    frameBlkh = zeros(1,numOut);
    frameBlkName = cell(1,numOut);
    % Add frame blocks for all outputs
    for index = 1:numOut
        frameBlkFullName = [newModelName,'/Frame block',num2str(index)];
        frameBlkName{index} = ['Frame block',num2str(index)];
        frameBlkh(index) = add_block('embeddedblocksInternallib/Frame block',frameBlkFullName,'CopyOption','nolink');
        pos = get_param(sensorBlock.handle,'Position');
        set_param(frameBlkFullName,'position',[pos(1)+250,(index*60)+10,pos(1)+350,(index*60)+10+40]);
    end
    if ~bdIsLoaded(p.Results.ModelName)
        newbdSubsys = new_system(p.Results.ModelName,p.Results.ModelType);
        newbdSubsysName = get_param(newbdSubsys,'Name');
    else
        newbdSubsysName = p.Results.ModelName;
    end
    % Add a subsytem
    subsys.Handle = add_block('built-in/Subsystem',[newbdSubsysName, '/', subsys.Name]);
    % Copy contents to subsystem
    Simulink.BlockDiagram.copyContentsToSubsystem(newModelName,subsys.Handle)
    % Close the previous model created
    close_system(newbd,false);
    % Get the handle of sensor object and frame objects in the subsystem
    numOut = numel(frameBlkName);
    for index = 1:numOut
        % Get handle of all frame blocks
        frameBlkh(index) = find_system(subsys.Handle,'LookUnderMasks','on','FollowLinks','on','Name',frameBlkName{index});
    end
    % Get handle of all sensor blocks
    sensorHandle = find_system(subsys.Handle,'LookUnderMasks','on','FollowLinks','on','Name',sensorBlock.Name);
    % Promote parameters
    promoteParameters(subsys.Handle,sensorHandle);
    initFcn = get_param(sensorHandle,'InitFcn');
    if ~isempty(initFcn)
        set_param(subsys.Handle,'InitFcn',initFcn);
    end
    % Hide the mask content
    set_param(subsys.Handle,"TreatAsAtomicUnit",'on');
    set_param(subsys.Handle,'MaskHideContents','on');
    % Open the library
    open_system(newbdSubsysName);
catch ME
    close_system(newbd,false);
    close_system(newbdSubsysName,false);
    throwAsCaller(ME);
end

%% validate input handle
    function validhandle = getValidHandle(blkh)
        if ischar(blkh) || isstring(blkh)
            validhandle = getSimulinkBlockHandle(blkh);
        else
            validhandle = blkh;
        end
        if ~ishandle(validhandle)
            error(['Invalid handle "' blkh '".']);
        end
    end

%% promote Parameters
    function promoteParameters(CurrentBlockH, sensorBlockH, varargin)
        narginchk(2,4);
        % Exclude this one from promoting
        excludeParameters = {'SimulateUsing'};
        CurrentBlockMask = Simulink.Mask.create(CurrentBlockH);
        sensorBlockMask = Simulink.Mask.get(sensorBlockH);
        % Get lower block mask
        ParamsList = get_param(sensorBlockH,'MaskNames');
        if ~isempty(excludeParameters)
            b = ismember(ParamsList,excludeParameters);
            ParamsList(b) = [];
        end
        % Copy mask layout with respect to groups
        Dlgctrl = copyBlockLayout(sensorBlockMask,CurrentBlockMask);
        % Promote parameters
        cellfun(@(x) promote(CurrentBlockMask,sensorBlockH,x,Dlgctrl(ismember({Dlgctrl.name},x))),ParamsList);
        % Add mask initialization
        CurrentBlockMask.SelfModifiable = 'on';
        CurrentBlockMask.Initialization = "matlabshared.sensors.simulink.internal.sensorFrameOutMaskInit(gcbh)";
        CurrentBlockMask.Description = [CurrentBlockMask.Description,char(message('matlab_sensors:blockmask:spfBlockDesc').getString)];
    end

%% Sub functions for promoteParameters
    function promote(CurrentBlockMask,LowerBlockH,ParameterName,ContainerName)
        % Get lower block properties
        LowerBlockProp = get(LowerBlockH);
        % Get lower block mask
        LowerBlockMask = Simulink.Mask.get(LowerBlockH);
        [idx,idxb] = ismember(ParameterName,{LowerBlockMask.Parameters.Name});
        if idx
            % Before promoting Sampletime promote frame paramaters
            if (strcmpi(ParameterName,'SampleTime'))
                promoteFrameParameters(CurrentBlockMask,ContainerName);
            end
            % Form name value pair except 'Type','TypeOptions','Callback','Container','DialogControl'
            propertylist = properties(LowerBlockMask.Parameters(idxb));
            propertylist(ismember(propertylist,{'Type','TypeOptions','Callback','Container','DialogControl'})) = [];
            % Value-pair cell
            valuepair = cellfun(@(x){x,LowerBlockMask.Parameters(idxb).(x)},propertylist,'UniformOutput',false);
            valuepair = [valuepair{:,1}];
            % Add callback to handle visibility of parameters.
            if (isfield(LowerBlockProp,'BlockType')&& strcmp(LowerBlockProp.BlockType,'MATLABSystem')) || isempty(Simulink.Mask.get(LowerBlockProp.Handle))
                valuepair{end+1} = 'Callback';
                valuepair{end+1} = sprintf('matlabshared.sensors.simulink.internal.sensorFrameOutParamsCallback(gcbh,''%s'');\n',ParameterName);
            end
            % Add a parameter to upper mask with type promote
            h = addParameter(CurrentBlockMask,'Type','promote',...
                'TypeOptions',{sprintf('%s/%s',get_param(LowerBlockH,'Name'),ParameterName)},...
                valuepair{:},...
                'Container',ContainerName.ctrl);
            if strcmpi(ParameterName,'QueueSizeFactor') || strcmpi(ParameterName,'Bitrate') || any(ismember(excludedParams,ParameterName))
                h.Hidden = 'on';
            end
            % Change the row to current
            dlg = getDialogControl(CurrentBlockMask,ParameterName);
            if ~isa(dlg,'Simulink.dialog.parameter.CheckBox')
                dlg.PromptLocation = 'left';
            end
            % To add buttons
            containerdlg = getDialogControl(CurrentBlockMask,ContainerName.ctrl);
            % Add browser
            if isequal(ParameterName,'DatasetName')
                Callback = ['[f,p] = uigetfile(''*.tgz'',''Select dataset'');' newline ...
                    'if f ~= 0' newline ...
                    char(9) 'set_param(gcb,''DatasetName'',fullfile(p,f));' newline ...
                    'end'];
                h = addDialogControl(CurrentBlockMask,'Type','pushbutton',...
                    'Name','browser',...
                    'Prompt','Browse...',...
                    'Callback',Callback,...
                    'Row','current'...
                    );
                h.moveTo(containerdlg);
            end
        end
    end

%% Sub functions for promoteParameters
    function organizeDescriptionGroupPanel(CurrentBlockMask,Dlgs)
        if isequal(Dlgs.Name,'DescGroupVar')
            CurrentBlockMask.Type = Dlgs.Prompt;
            CurrentBlockMask.Description = Dlgs.DialogControls(1).Prompt;
        end
    end

%% Sub functions for promoteParameters
    function dlgctrl = copyBlockLayout(LowerBlockMask,CurrentBlockMask)
        % Lower block mask
        DlgControls = getDialogControls(LowerBlockMask);
        dlgctrl = getAllDialogControls(CurrentBlockMask,[],DlgControls);
    end

%% Sub functions for promoteParameters
    function dlgctrl = getAllDialogControls(CurrentBlockMask,ParentDialogControl,LowerMaskDlgs)

        dlgctrl = [];

        for i = 1:numel(LowerMaskDlgs)
            if isa(LowerMaskDlgs(i),'Simulink.dialog.Container')
                if isempty(ParentDialogControl)
                    ParentDialogControl = CurrentBlockMask;
                end
                if isequal(LowerMaskDlgs(i).Name,'DescGroupVar')
                    organizeDescriptionGroupPanel(CurrentBlockMask,LowerMaskDlgs(i));
                else

                    switch class(LowerMaskDlgs(i))
                        case 'Simulink.dialog.Group'
                            valuepairtype = {'Type','group'};
                        case 'Simulink.dialog.TabContainer'
                            valuepairtype = {'Type','tabcontainer'};
                        case 'Simulink.dialog.Panel'
                            valuepairtype = {'Type','panel'};
                        case 'Simulink.dialog.Tab'
                            valuepairtype = {'Type','tab'};
                        case 'Simulink.dialog.CollapsiblePanel'
                            valuepairtype = {'Type','collapsiblepanel'};
                        otherwise
                            valuepairtype = [];
                    end
                    % Value-pair cell
                    % Exclude 'DialogControls'
                    propnames = properties(LowerMaskDlgs(i));
                    propnames(ismember(propnames,{'DialogControls','AlignPrompts','Tooltip','Row'})) = [];
                    valuepair = cellfun(@(x){x,LowerMaskDlgs(i).(x)},propnames,'UniformOutput',false);
                    valuepair = [valuepair{:,1}];
                    valuepair = [valuepairtype valuepair]; %#ok<AGROW>
                    % Add a dialog
                    h = addDialogControl(ParentDialogControl,valuepair{:});
                    % Recurse to add dialog containers and get info about dialog
                    % controls
                    for j = 1:numel(LowerMaskDlgs(i).DialogControls)
                        dlgctrl = [dlgctrl getAllDialogControls(CurrentBlockMask,...
                            h,...
                            LowerMaskDlgs(i).DialogControls(j))]; %#ok<AGROW>
                    end
                end
            else
                % Return dialog controls info
                dlgctrl = struct('ctrl',ParentDialogControl.Name,'name',LowerMaskDlgs.Name);
            end
        end
    end

%% promote frame block parameters to top mask
    function promoteFrameParameters(subsysBlockMask,ContainerName)
        framBlockMask = Simulink.Mask.get(frameBlkh(1));
        propertylist = properties(framBlockMask.Parameters(1));
        propertylist(ismember(propertylist,{'Type','TypeOptions','Callback','Container','DialogControl'})) = [];
        % Value-pair cell
        valuepair = cellfun(@(x){x,framBlockMask.Parameters(1).(x)},propertylist,'UniformOutput',false);
        valuepair = [valuepair{:,1}];
        numFrameBlks = numel(frameBlkh);
        txt = cell(1,numFrameBlks);
        for i = 1:numFrameBlks
            frameBlockName = get_param(frameBlkh(i),'Name');
            txt{i} = sprintf('%s/spf',frameBlockName);
        end
        % many to one promotion
        h = addParameter(subsysBlockMask,'Type','promote','TypeOptions',txt,valuepair{:},'Container',ContainerName.ctrl);
        h.Tunable = 'off';
        h.Callback = 'matlabshared.sensors.simulink.internal.sensorFrameOutParamsCallback(gcbh,''spf'')';
        h.Prompt = message('matlab_sensors:blockmask:spf').getString;
        h.DialogControl.PromptLocation = "left";
        h.Value = '1';
    end
end