classdef Mediator < dynamicprops
    %MEDIATOR - Facilitates publisher/subscriber communication in MATLAB.
    
    %   Mediator manages the communication between the Publisher and
    %   the Subscribers. All publishers and subscribers know about only the
    %   Mediator and they are unaware of each other's existence.     
    %   A publisher will let the mediator know which ‘properties’ they want
    %   to publish.
    %   Subscribers will listen to the 'properties' of their interest from
    %   the mediator by adding listeners to it.
    %
    % Usages:
    %       % Instantiate a mediator object 
    %       mediatorObj = matlabshared.mediator.internal.Mediator;
    %
    % To see the entire workflow, refer to the main.m file in the location:
    % $(matlabroot)\toolbox\shared\testmeaslib\general\examples\mediator

    % Copyright 2016-2018 The MathWorks, Inc.
    
    events
        Subscribe
        Unsubscribe
    end
    
    methods        
        function connect(obj)
            obj.notify('Subscribe');
        end
        
        function disconnect(obj)
            obj.notify('Unsubscribe');
        end
    end
    
end

