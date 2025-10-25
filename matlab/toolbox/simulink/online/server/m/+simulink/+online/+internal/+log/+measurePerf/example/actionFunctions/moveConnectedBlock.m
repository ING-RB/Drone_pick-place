% Action function: the function that control a series of designated operations
% in a model of simulink online. It's used as a tool to measure network delay.

% This example action function uses the simulink model sldemo_fuelsys
% the function will choose a certain block at the model and move the 
% block to a certain position and then move it back.

function moveConnectedBlock 

    pos = get_param('sldemo_fuelsys/Engine_Speed_Selector', 'Position');
    newPos = pos + 100;
    a = datestr(now,'HH:MM:SS.FFF');
    fprintf('This message is sent at time %s\n', a);
    set_param('sldemo_fuelsys/Engine_Speed_Selector', 'Position', newPos);
    pause(1);
    lastPos = newPos - 100;
    set_param('sldemo_fuelsys/Engine_Speed_Selector', 'Position', lastPos);
    b = datestr(now,'HH:MM:SS.FFF');
    fprintf('This message is sent at time %s\n', b);

end