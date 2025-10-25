classdef Painter3D < handle
    %This class is for internal use only. It may be removed in the future.
    
    %Painter3D setup the axis perspective for 3D plotting
    
    %   Copyright 2018-2024 The MathWorks, Inc.
    
    methods
        function obj = Painter3D(ax, setupPerspective)
            %Painter3D constructor, if the optional input setupPerspective
            %is true, set the ax to a pre-defined view and lighting
            %configuration
            
            if setupPerspective
                % set the axis ratios
                pbaspect(ax, [1 1 1]);
                daspect(ax, [1 1 1]);
                
                % set the grid and light
                grid(ax, 'on');
                light(ax, 'position', [1 0 1]);
            end
            
            % control the view angle and plot position within figure
            [az, el] = view(ax);
            if az == 0 && el == 90
                % change to 3d view if current view is 2d top-down
                view(ax, 3);
            end
        end
    end
end

