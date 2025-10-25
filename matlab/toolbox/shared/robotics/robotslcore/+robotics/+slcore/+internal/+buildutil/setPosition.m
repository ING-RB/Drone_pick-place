function setPosition(bdname, new_pos)
    %This class is for internal use only. It may be removed in the future.

    % setPosition callback is executed during the model resave phase
    
    %   Copyright 2018 The MathWorks, Inc.
    
    fprintf('setPosition: Setting position for %s\n',bdname);

    set_param(bdname, 'Location', new_pos);
    
    % Need to call "pause" because ZoomFactor setting does not get applied
    % if called immediately (Read the info in g1425510). Unfortunately,
    % there is no easy way as mentioned in geck: The set_params are sent to
    % the Qt thread asynchronously so there is no guarantee of the timing
    % of the commands. MG2.syncOnGuiPingPong is a utility used in
    % shared_dastudio component.
    MG2.syncOnGuiPingPong;
    MG2.syncOnGuiPingPong;

    set_param(bdname, 'ZoomFactor', 'FitSystem');
    MG2.syncOnGuiPingPong;
    
    % Print output during build
    cur_pos = get_param(bdname,'Location');
    cur_zoom = get_param(bdname, 'ZoomFactor');
    
    fprintf('setPosition: New position for %s: [%d %d %d %d], ZoomFactor: %s\n', ...
        bdname, cur_pos(1), cur_pos(2), cur_pos(3), cur_pos(4), cur_zoom);
end