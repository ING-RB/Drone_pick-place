function manageOutportSensorBlocksWithFrameOut(subsysh, sensorBlkh, selectedOutputs)
%MANAGEINPORT Grows output ports and connect sensor outputs, frame blocks
%and outports

%   Copyright 2022 The MathWorks, Inc.

subsysBlockPath  = getfullname(subsysh);

% Get the existing outports
outPortsh = find_system(subsysh,'SearchDepth',1,'LookUnderMasks','on','FollowLinks','on','BlockType','Outport');
% find all frame blocks
frameBlkh = find_system(subsysh,'IncludeCommented','on','LookUnderMasks','on','FollowLinks','on','BlockType','S-Function');
% delete all lines and outports under the mask
delete_line(find_system(subsysh,'Followlinks','on','LookUnderMasks', 'all','Searchdepth',1,'FindAll','on','type','line'));
% This can be caused due to issue in promotion. Enough number of frame
% blocks are not available for full connection. Ensure that all outputs of sensor blocks are selected while 
% promoting the block 
% The warning is only intended for internal users. 
if numel(selectedOutputs) > numel(frameBlkh)
    warning(message('matlab_sensors:general:OutportsExceeded'));
end
% If required number of outputs are greater than available outport blocks, add outport blocks
if numel(selectedOutputs) > numel(outPortsh)
    for i = 1:numel(outPortsh)
        set_param(outPortsh(i),'Name',['out',num2str(i)]);
    end
    for i = numel(outPortsh)+1:numel(selectedOutputs)
        frameBlkPos = get_param(frameBlkh(numel(outPortsh)+1),'Position');
        outH = add_block('built-in/Outport',[subsysBlockPath '/out' num2str(i)],'MakeNameUnique','on');
        set_param(outH,'position',[frameBlkPos(1)+200,(i*60)+15,frameBlkPos(1)+220,(i*60)+15+15]);
    end
    % If required number of outputs are less than available outport blocks, delete excess outport blocks
elseif numel(selectedOutputs) < numel(outPortsh)
    startIndexBlocksToDelete = numel(selectedOutputs)+1;
    numBlocksToDelete = numel(outPortsh) - startIndexBlocksToDelete;
    for i = 1:startIndexBlocksToDelete-1
        set_param(outPortsh(i),'Name',['out',num2str(i)]);
    end
    for i =startIndexBlocksToDelete:startIndexBlocksToDelete+ numBlocksToDelete
        delete_block(outPortsh(i));
        set_param(frameBlkh(i),'Commented','on');
    end
else
    %No need to add or delete port if number of outports are same as
    %selected outputs
end

% Refresh list of output ports
outputHandle = find_system(subsysh,'SearchDepth',1,'LookUnderMasks','on','FollowLinks','on','BlockType','Outport');

% Connect sensor outputs, frame blocks and outpots
sensorBlockPortHandle = get_param(sensorBlkh,'PortHandles');
% If spf = 1, skip frame block to avoid unnneccessery code and sample time
% limitations
if ~strcmpi(get_param(subsysh,'spf'),'1')
    for i = 1:numel(selectedOutputs)
        set_param(frameBlkh(i),'Commented','off');
        framPorth = get_param(frameBlkh(i),'PortHandles');
        add_line(subsysBlockPath,sensorBlockPortHandle.Outport(i),framPorth.Inport(1),'autorouting','smart');
        set_param(outputHandle(i),'Name',selectedOutputs{i});
        outputPortH = get_param(outputHandle(i),'PortHandles');
        add_line(subsysBlockPath,framPorth.Outport(1),outputPortH.Inport(1),'autorouting','smart');
    end
else
    for i = 1:numel(selectedOutputs)
        set_param(frameBlkh(i),'Commented','on');
        set_param(outputHandle(i),'Name',selectedOutputs{i});
        outputPortH = get_param(outputHandle(i),'PortHandles');
        add_line(subsysBlockPath,sensorBlockPortHandle.Outport(i),outputPortH.Inport(1),'autorouting','smart');
    end
end
end
