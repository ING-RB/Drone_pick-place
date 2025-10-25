function keyboardNavigationKeyPressFcn(this, f, evd)

%

%   Copyright 2021 The MathWorks, Inc.

% This keypress function handles the logic for keyboard navigation through
% the graphics hierarchy. The following key combinations govern the logic
% for keyboard navigation. 

% Tab : Forward navigation 
% Shift + tab : Backward navigation 
% Control + down : Drill down
% Control + up : Drill up 

shift_pressed = false;
control_pressed = false;

if(~isempty(evd.Modifier))
   shift_pressed = ismember(evd.Modifier, 'shift');
   control_pressed = ismember(evd.Modifier, 'control');
end

if(strcmp(evd.Key, 'tab') && shift_pressed)
    this.navigateBackward();
    
elseif (strcmp(evd.Key, 'tab') && ~shift_pressed)
    this.navigateForward();
    
elseif (strcmp(evd.Key, 'downarrow') && control_pressed)
    this.drillDown();
    
elseif (strcmp(evd.Key, 'uparrow') && control_pressed)
    this.drillUp();
    
end

end

