function returnedKeyBindings = getCurrentKeyBindings()
% This function returns key bindings for different actions in point cloud
% visualization

% Copyright 2022 The MathWorks, Inc.

persistent keyBindings;

if isempty(keyBindings)
    keyBindings = dictionary;
end

keyBindings("SwitchToPan") = "space";
keyBindings("RotateFromPoint") = "shift";
keyBindings("RotateByThirdAxis") = "t";
keyBindings("MoveForward") = "w";
keyBindings("MoveBackward") = "s";
keyBindings("MoveLeft") = "a";
keyBindings("MoveRight") = "d";
keyBindings("LookUp") = "uparrow";
keyBindings("LookDown") = "downarrow";
keyBindings("LookLeft") = "leftarrow";
keyBindings("LookRight") = "rightarrow";
keyBindings("RollClockwise") = "q";
keyBindings("RollAntiClockwise") = "e";
keyBindings("RotateModifier") = "shift";
keyBindings("ZoomIn") = "z";
keyBindings("ZoomOut") = "x";
keyBindings("XY") = "1";
keyBindings("YX") = "2";
keyBindings("XZ") = "3";
keyBindings("ZX") = "4";
keyBindings("YZ") = "5";
keyBindings("ZY") = "6";

returnedKeyBindings = keyBindings;

end