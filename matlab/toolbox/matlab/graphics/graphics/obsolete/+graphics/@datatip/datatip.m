classdef datatip < matlab.mixin.SetGet & matlab.mixin.Copyable
%graphics.datatip class
%
%    graphics.datatip methods:



    methods  % constructor block
        function [hThis] = datatip(varargin)

        end  % datatip
        
        

    end  % constructor block

    methods (Hidden) % possibly private or hidden
    down = startDrag(hThis,hFig)
end  % possibly private or hidden 

end  % classdef

function localTextBoxButtonDownFcn(~,~,~,~)
end  % localTextBoxButtonDownFcn

