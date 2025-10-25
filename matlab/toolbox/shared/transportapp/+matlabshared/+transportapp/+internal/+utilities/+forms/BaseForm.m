classdef BaseForm
    %BASEFORM contains common properties used by both the appspace and
    %toolstrip form classes.

    % Copyright 2020 The MathWorks, Inc.

    properties
       % Contains the parent element on which the View for a given section
       % (toolstrip or appspace) is rendered.
       Parent = []

       % Handle to the mediator instance created in the SharedApp class.
       Mediator matlabshared.mediator.internal.Mediator

       % The interface name
       TransportName (1,1) string
    end
end