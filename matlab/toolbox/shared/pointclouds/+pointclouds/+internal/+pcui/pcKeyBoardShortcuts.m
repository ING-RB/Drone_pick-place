function pcKeyBoardShortcuts(hFigure, keyBindings, keyPressed, keyModifier, stepProps)
% This function implements the keyboard shortcuts for point cloud
% visualization

% Copyright 2022 The MathWorks, Inc.


keyPressed = string(keyPressed);
keyModifier = string(keyModifier);

currentAxes = hFigure.CurrentAxes;
udata = pointclouds.internal.pcui.utils.getAppData(currentAxes, 'PCUserData');

% For move operations, move by by 10% of the distance between camera
% position and camera target
moveStepSize = stepProps.MoveStepSize;

% This defines the step size for panning. The format is 
% [panStepSize panAngleMin panAngleMax]. panStepSize is the percentage step
% size of max and min of the data limits.
panStepProperties = stepProps.PanStepProperties;
% horizontalPan is a boolean that tells whether to pan horizontally or
% vertically
horizontalPan = stepProps.HorizontalPan;
% panDirection tells whether to pan in positive direction or negative
panDirection = stepProps.PanDirection;

% This defines the step size for rotating the scene. The format is
% [rotateStepSize rotateAngleMin rotateAngleMax]. rotateStepSize is the
% percentage step size of max and min of the data limits.
rotateStepProperties = stepProps.RotateStepProperties;
% horizontalRotate is a boolean that tells whether to rotate horizontally or
% vertically
horizontalRotate = stepProps.HorizontalRotate;
% rotateDirection tells whether to rotate in positive direction or negative
rotateDirection = stepProps.RotateDirection;

rollAngle = stepProps.RollAngle;
zoomFactor = stepProps.ZoomFactor;

hManager = uigetmodemanager(hFigure);

if ~isempty(hManager.CurrentMode) && ...
        strcmp(hManager.CurrentMode.Name, 'Exploration.Rotate3d')

    if keyPressed == keyBindings("SwitchToPan")
        % Switch to Pan mode from rotate mode

        zoom(currentAxes,'off');
        pan(currentAxes,'on');
        rotate3d(currentAxes,'off');
        udata.SwitchedFromRotate = true;
        
    elseif keyPressed == keyBindings("RotateFromPoint")
        % Switch to rotate from point
        
        if udata.rotateFromCenter
            udata.rotateFromCenter = false;
            udata.changeModeOnRelease = true;
        else
            udata.changeModeOnRelease = false;
        end

    elseif keyPressed == keyBindings("RotateByThirdAxis")
        % Rotate by third axis (By default you can rotate by two axis)
        cameratoolbar(hFigure, 'SetMode', 'roll');

    elseif keyPressed == keyBindings("MoveForward")

        pointclouds.internal.pcui.moveForwOrBack(moveStepSize, currentAxes);
        
    elseif keyPressed == keyBindings("MoveBackward")

        pointclouds.internal.pcui.moveForwOrBack(-moveStepSize, currentAxes);        
        
    elseif keyPressed == keyBindings("MoveRight")

        pointclouds.internal.pcui.moveLeftOrRight(moveStepSize, currentAxes);

    elseif keyPressed == keyBindings("MoveLeft")

        pointclouds.internal.pcui.moveLeftOrRight(-moveStepSize, currentAxes);

    elseif keyPressed == keyBindings("LookUp")

        if keyModifier == keyBindings("RotateModifier")
            pointclouds.internal.pcui.rotateScene(rotateStepProperties,...
                ~horizontalRotate, rotateDirection, currentAxes);
        else
            pointclouds.internal.pcui.lookAround(panStepProperties,...
                ~horizontalPan, panDirection, currentAxes);
        end          

    elseif keyPressed == keyBindings("LookDown")
        
        if keyModifier == keyBindings("RotateModifier")
            pointclouds.internal.pcui.rotateScene(rotateStepProperties,...
                ~horizontalRotate, -rotateDirection, currentAxes);      
        else
            pointclouds.internal.pcui.lookAround(panStepProperties,...
                ~horizontalPan, -panDirection, currentAxes);
        end        

    elseif keyPressed == keyBindings("LookRight")
        
        if keyModifier == keyBindings("RotateModifier")
            pointclouds.internal.pcui.rotateScene(rotateStepProperties,...
                horizontalRotate, rotateDirection, currentAxes);      
        else
            pointclouds.internal.pcui.lookAround(panStepProperties,...
                horizontalPan, panDirection, currentAxes);
        end

    elseif keyPressed == keyBindings("LookLeft")

        if keyModifier == keyBindings("RotateModifier")
            pointclouds.internal.pcui.rotateScene(rotateStepProperties,...
                horizontalRotate, -rotateDirection, currentAxes);      
        else
            pointclouds.internal.pcui.lookAround(panStepProperties,...
                horizontalPan, -panDirection, currentAxes);
        
        end        

    elseif keyPressed == keyBindings("RollClockwise")

        camroll(currentAxes, rollAngle);

    elseif keyPressed == keyBindings("RollAntiClockwise")

        camroll(currentAxes, -rollAngle);

    elseif keyPressed == keyBindings("ZoomIn")

        camzoom(currentAxes, zoomFactor);

    elseif keyPressed == keyBindings("ZoomOut")

        camzoom(currentAxes, 1/zoomFactor); 

    elseif keyPressed == keyBindings("XY") || keyPressed == ("numpad" + keyBindings("XY"))
        % "numpad" check is for numeric keypads

        pointclouds.internal.pcui.setView('XY', currentAxes);
        
    elseif keyPressed == keyBindings("YX") || keyPressed == ("numpad" + keyBindings("YX"))

        pointclouds.internal.pcui.setView('YX', currentAxes);
        
    elseif keyPressed == keyBindings("XZ") || keyPressed == ("numpad" + keyBindings("XZ"))

        pointclouds.internal.pcui.setView('XZ', currentAxes);
        
    elseif keyPressed == keyBindings("ZX") || keyPressed == ("numpad" + keyBindings("ZX"))

        pointclouds.internal.pcui.setView('ZX', currentAxes);
        
    elseif keyPressed == keyBindings("YZ") || keyPressed == ("numpad" + keyBindings("YZ"))

        pointclouds.internal.pcui.setView('YZ', currentAxes);
        
    elseif keyPressed == keyBindings("ZY") || keyPressed == ("numpad" + keyBindings("ZY"))

        pointclouds.internal.pcui.setView('ZY', currentAxes);        
        
    end    
end

pointclouds.internal.pcui.utils.setAppData(currentAxes, 'PCUserData', udata);
end