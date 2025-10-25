function iptSetPointerBehavior(varargin)
%iptSetPointerBehavior Store pointer behavior in HG object.
%   iptSetPointerBehavior(h, pointerBehavior) stores the specified "pointer
%   behavior" in the specified Handle Graphics object, h.  If h is an array
%   of objects, then the same pointer behavior is stored in each one. 
%
%   A pointer behavior is a structure of function handles that interact with a
%   figure's pointer manager (see iptPointerManager) to control what happens
%   when the figure's mouse pointer moves over and then exits the object.
%
%   iptSetPointerBehavior(h, []) clears the pointer behavior from the Handle
%   Graphics object or objects.
%
%   Pointer Behavior Function Handles
%   ---------------------------------
%
%   enterFcn
%   
%       Called when the mouse pointer moves over the object.
%
%   traverseFcn
%
%       Called once when the mouse pointer moves over the object, and called
%       again each time the mouse moves within the object. 
%
%   exitFcn
%
%       Called when the mouse pointer leaves the object.
%
%   Each of these three structure fields can also be [], in which case no
%   action is taken.
%
%   In the most common use of iptSetPointerBehavior, only the enterFcn is
%   necessary, so you can also use the syntax iptSetPointerBehavior(h,
%   enterFcn).  This syntax creates a pointer behavior in which traverseFcn
%   and exitFcn are both [].
%
%   EXAMPLE 1
%   =========
%   Make the mouse pointer be a fleur whenever it is over a specific
%   object. When the mouse pointer moves off the object, restore the original
%   figure pointer. This scenario requires only an enterFcn. Note that the
%   pointer manager takes care of restoring the original figure pointer. 
%
%       hPatch = patch([.25 .75 .75 .25 .25], [.25 .25 .75 .75 .25], 'r');
%       xlim([0 1])
%       ylim([0 1])
%   
%       enterFcn = @(figHandle, currentPoint) set(figHandle, 'Pointer', 'fleur');
%       iptSetPointerBehavior(hPatch, enterFcn);
%       iptPointerManager(gcf);
%
%   EXAMPLE 2
%   =========
%   Make the mouse pointer vary depending on where it is within the
%   object. In this scenario, enterFcn and exitFcn are empty, and
%   traverseFcn handles the position-specific behavior.
%   
%       hPatch = patch([.25 .75 .75 .25 .25], [.25 .25 .75 .75 .25], 'r'); 
%       xlim([0 1])
%       ylim([0 1])
%   
%       pointerBehavior.enterFcn    = [];
%       pointerBehavior.exitFcn     = [];
%       pointerBehavior.traverseFcn = @overMe;
%   
%       % overMe is an example function that varies the mouse pointer
%       % depending on the location of the mouse within the object.  Edit
%       % overMe to see the details.
%   
%       iptSetPointerBehavior(hPatch, pointerBehavior);
%       iptPointerManager(gcf);
%   
%   EXAMPLE 3
%   =========
%   Change the figure's title when the mouse pointer is over the object. In
%   this scenario, enterFcn and exitFcn are used to achieve the desired side
%   effect, and traverseFcn is []. 
%   
%       hPatch = patch([.25 .75 .75 .25 .25], [.25 .25 .75 .75 .25], 'r');
%       xlim([0 1])
%       ylim([0 1])
%   
%       pointerBehavior.enterFcn = ...
%            @(figHandle, currentPoint) set(figHandle, 'Name', 'Over patch');
%       pointerBehavior.exitFcn  = ...
%            @(figHandle, currentPoint) set(figHandle, 'Name', '');
%       pointerBehavior.traverseFcn = [];
%   
%       iptSetPointerBehavior(hPatch, pointerBehavior);
%       iptPointerManager(gcf);
%   
%   See also iptGetPointerBehavior, iptPointerManager.

%   Copyright 2005-2013 The MathWorks, Inc.

% Preconditions (all checked):
%     Two input arguments
%         Images:iptSetPointerBehavior:tooFewInputs
%         Images:iptSetPointerBehavior:tooManyInputs
%
%     HG handles are valid
%         Images:iptSetPointerBehavior:invalidHandle
%
%     Valid Pointer behavior struct or function handle
%         Images:iptSetPointerBehavior:invalidType
%         Images:iptSetPointerBehavior:badPointerBehaviorStruct
%        
% Postconditions:
%     The HG object will contain a valid pointer behavior struct that can be
%     retrieved by iptGetPointerBehavior.
%
% Information Hiding:
%     This routine (together with iptGetPointerBehavior) hides the specific
%     mechanism used to store and retrieve the pointer behavior.

[h, pointerBehavior] = parseInputs(varargin{:});

% Store the pointer behavior in the HG object's 'iptPointerBehavior' appdata.
for k = 1:numel(h)
    setappdata(h(k), 'iptPointerBehavior', pointerBehavior);
end

%======================================================================
function [h, pointerBehavior] = parseInputs(varargin)

% Assert that the number of input arguments is valid.
narginchk(2, 2);

% Error if the first input argument is not a valid HG handle.
h = varargin{1};
if ~all(ishghandle(h(:)))    
    error(message('imageslib:iptPointer:invalidHandleMultipleInput'))          
end

second_arg = varargin{2};

if isempty(second_arg)
    pointerBehavior = second_arg;
    
else
    % The second argument isn't empty, so validate it.
    
    if ~(isa(second_arg, 'function_handle') || isa(second_arg, 'struct'))
        error(message('imageslib:iptPointer:invalidType'))
    end
    
    if isa(second_arg, 'function_handle')
        % The second input argument is a function handle.  Treat it as enterFcn.
        % Make traverseFcn and exitFcn be empty.
        pointerBehavior.enterFcn = second_arg;
        pointerBehavior.traverseFcn = [];
        pointerBehavior.exitFcn = [];
    else
        % The second input argument is a struct.  Make sure it is a valid 
        % pointer behavior.
        pointerBehavior = second_arg;
        if ~isValidPointerBehavior(pointerBehavior)
            error(message('imageslib:iptPointer:invalidPointerBehavior'))
        end
    end
end

