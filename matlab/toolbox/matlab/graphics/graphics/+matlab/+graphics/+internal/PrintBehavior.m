classdef PrintBehavior < matlab.graphics.internal.HGBehavior
% This is an undocumented class and may be removed in a future release.

% Copyright 2013-2022 The MathWorks, Inc.

properties (Constant)
    %NAME Property
    Name = 'Print';
end

properties
    PrePrintCallback = [];
    PostPrintCallback = [];
    
    %WARNONCUSTOMRESIZEFCN Property should be either 'on/off' string
    WarnOnCustomResizeFcn = 'on';

    % CheckDataDescriptorBehavior 'on' tells the print and export code
    % to skip the object when applying style changes if the object
    % has a *disabled* DataDescriptor behavior. Set the value to 'off'
    % to apply printing style changes to an object even if the
    % DataDescriptor behavior is disabled.
    CheckDataDescriptorBehavior = 'on';
end


properties (Transient)
    %SERIALIZE Property 
    Serialize = true;
end

methods 
    function set.WarnOnCustomResizeFcn(obj,value)
        % values = 'on/off'
        validatestring(value,{'on','off'},'','WarnOnCustomResizeFcn');
        obj.WarnOnCustomResizeFcn = value;
    end
    
    function thisSerialize = saveobj(this)
        if this.Serialize
            thisSerialize = this;
        else
            thisSerialize = [];
        end
    end

end   % set and get functions 

methods
    function ret = dosupport(~,hTarget)
        % only allowed on Figure, Axes, and ScribeGrid
        ret = ishghandle(hTarget, 'Figure') || ...
            isgraphics(hTarget,'matlab.graphics.axis.AbstractAxes') || ...
            ishghandle(hTarget, 'Legend') || ...
            (ishghandle(hTarget) && ...
            (isa(hTarget, 'matlab.graphics.shape.internal.ScribeGrid') || ...
            isa(hTarget, 'matlab.graphics.chart.Chart') || ...
            isa(hTarget, 'matlab.graphics.controls.AxesToolbar') || ...
            isa(hTarget, 'bigimageshow') || ...
            isa(hTarget, 'matlab.graphics.shape.internal.PointDataTip')) || ...
            isa(hTarget, 'matlab.graphics.primitive.world.CompositeMarker'));
            
    end
end  

end  % classdef

