function tf = ppStructMethods(methodID)
    % Returns true if ppstruct has to be generated for given methodID

    %   Copyright 2022 The MathWorks, Inc.
    
    %#codegen

    tf = false;
    tf = tf || methodID == coder.internal.interpolate.interpMethodsEnum.SPLINE;
    tf = tf || methodID == coder.internal.interpolate.interpMethodsEnum.PCHIP;
    tf = tf || methodID == coder.internal.interpolate.interpMethodsEnum.MAKIMA;

end