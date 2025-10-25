classdef DataCursorBehavior < matlab.graphics.internal.HGBehavior & ...
        matlab.graphics.mixin.internal.GraphicsDataTypeContainer
% This is an undocumented class and may be removed in a future release.

% Copyright 2012-2024 The MathWorks, Inc.

properties (Constant)
    %NAME Property (read only)
    Name = 'DataCursor';
end

properties
    StartDragFcn = [];
    EndDragFcn = [];
    UpdateFcn = [];
    CreateFcn = [];
    StartCreateFcn = [];
    UpdateDataCursorFcn = [];
    MoveDataCursorFcn = [];
    %CREATENEWDATATIP Property takes true/false 
    CreateNewDatatip = false;
    Interpreter matlab.internal.datatype.matlab.graphics.datatype.TextInterpreter = 'tex';
end

properties (SetObservable=true)
    %ENABLE Property takes true/false
    Enable = true;
end

properties (Transient)
    %SERIALIZE Property 
    Serialize = true;
end


methods 
    function [ret] = dosupport(~,hTarget)
        % Support double handle inputs
        hTarget = handle(hTarget);
        
        % axes or axes children
        ret = isa(hTarget, 'matlab.graphics.mixin.AbstractAxesParentable') ...
            || isa(hTarget, 'matlab.graphics.axis.AbstractAxes') ...
            || isgraphics(hTarget, 'axes');
    end
end 

end  % classdef

