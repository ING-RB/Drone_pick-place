function [autoSwitch, userSpecifiedRenderer] = autoSwitchToPaintersForPrint(pj)
% This undocumented helper function is for internal use.

% AUTOSWITCHTOPAINTERSFORPRINT 
% Checks to see if we should use painters for output generation when
% producing vector output, based on heuristic implemented here
% Copyright 2014-2024 The MathWorks, Inc.

    autoSwitch = false; 
    % becomes false if we don't exit early. Early exit triggered by:
    %   not vector format
    %   renderer was manually set (mode is manual)
    %   renderer was specified in print command 
    %   renderer is already painters 
    userSpecifiedRenderer = true; 
    
    exportHndl = pj.Handles{1};
    isVectorFormat = length(pj.Driver) > 1 && ... 
                     (strncmp(pj.Driver(1:2), 'ps', 2) || ... 
                     any(strncmp(pj.Driver(1:3), {'eps', 'met', 'pdf', 'svg'}, 3)));
    
    if ~pj.temp.isJSD
    %  We won't "auto switch" if 
    %    ** not doing a vector format or
    %    ** renderer was specified in call to print, or 
    %    ** user set figure's renderer (renderermode is 'manual'),  or
    %    ** exporting from canvas and canvas OpenGL value was set by user
    %    **        (OpenGLMode is manual)
    %    ** renderer is already set to 'painters' 
        rendererProp = 'Renderer';
        if isa(exportHndl, 'matlab.graphics.primitive.Canvas') || ... 
                isa(exportHndl, 'matlab.graphics.primitive.canvas.JavaCanvas') || ...
                isa(exportHndl, 'matlab.graphics.primitive.canvas.HTMLCanvas')
            rendererProp = 'OpenGL';
        end
        if ~isVectorFormat || pj.rendererOption || ...
                strcmp(exportHndl.([rendererProp 'Mode']), 'manual') || ... 
                any(strcmp(exportHndl.(rendererProp), {'painters', 'off'})) || ...
                strcmp(pj.ParentFig.RendererMode, 'manual') 
            return;
        end
    else
        if ~isVectorFormat || pj.rendererOption
            return;
        end
    end
    
    % not returning early, checking contents w/in heuristic
    userSpecifiedRenderer = false; 

    % use the heuristic to decide whether or not switch
    % auto switch only if the scene isn't too complex 

    % when exporting, and not printing, we might have a specified set of
    % objects to export (print does entire figure). We only want to
    % consider that specified set when deciding whether to autoswitch 
    if (isfield(pj, 'temp') || isprop(pj, 'temp')) && isfield(pj.temp, 'exportInclude') && ...
            ~isempty(pj.temp.exportInclude)
        exportHndl = setdiff(pj.temp.exportInclude, exportHndl); 
    end
    
    % first check if any axes use depth sorting (only care if the axes
    % contents are visible since that would impact rendering)
    ax = findobjinternal(exportHndl, 'type', 'axes', 'SortMethod', 'depth', 'ContentsVisible', 'on');
    if ~isempty(ax)
        % depth sorting in use, don't autoswitch g1736840
        autoSwitch = false;
    else
        %  none of the axes were using depth sorting, but still need to
        %  check for more complex figures. For example, figs w/large surfaces 
        %  or large number of markers could result in time-consuming 
        %  output generation and large output files. 
        checker = matlab.graphics.internal.PrintPaintersChecker.getInstance();
        autoSwitch = ~checker.exceedsVertexLimits(exportHndl); 
    end
    % if we still think we can/should auto switch, check to see if the 
    % figure uses transparency and, if so, whether the output format
    % supports it (right now, PS/EPS don't support transparency 
    if autoSwitch && ~isempty(strfind(pj.Driver, 'ps'))
        % if transparency, don't autoswitch
        autoSwitch = ~hasTransparency(exportHndl, checker.DebugMode); 
    end
    
    % if we still think we can/should auto switch, check to see if there is
    % any lighting involved, and don't autoSwitch if there is
    if autoSwitch
        autoSwitch = ~checker.exceedsLightingLimits(exportHndl);
    end
    
    % if we still think we can/should auto switch, check to see if there is
    % any surface with texturemap facecolor exist, and don't autoSwitch if
    % it is going to be large output size (except PDF format) [g1651960]
    if autoSwitch && ~contains(pj.Driver, 'pdf')
        autoSwitch = ~checker.exceedsTextureLimits(exportHndl);
    end

    % if we still think we can/should auto switch, check to see if there is
    % trianglestrip/quadrilateral with texturemap/interp facecolor 
    % exceeds beyond certain limit[g1769901].
    if autoSwitch
        autoSwitch = ~checker.exceedsIntepolatedLimits(exportHndl);
    end
end

% helper function to look through objects and flag whether there are any
% visible objects using transparency
function hasTrans = hasTransparency(exportHndl, debugMode)
   hasTrans = false;
   k = findobjinternal(exportHndl, 'Visible', 'on');
   % these properties control transparency. if 1 it's fully opaque, 
   % otherwise there is some level of transparency, unless the associated 
   % color is 'none' 
   alphaProps = {'FaceAlpha', 'EdgeAlpha', 'MarkerFaceAlpha', 'MarkerEdgeAlpha'}; 
   colorProps = {'FaceColor', 'EdgeColor', 'MarkerFaceColor', 'MarkerEdgeColor'}; 
   for idx = 1:length(alphaProps) 
       
       % these are objs that have an Alpha prop but don't have obvious
       % corresponding Color prop (e.g. they have FaceAlpha but no FaceColor) 
       % To be safe, if any of these have an Alpha that is NOT 1 (i.e. NOT 
       % Opaque) we will assume transparency is in use 
       kAlphaWithNoColorProp = findobjinternal(k, '-property', alphaProps{idx}, ...
           '-not', alphaProps{idx}, 1, '-not', '-property', colorProps{idx}, '-depth', 0);
       if ~isempty(kAlphaWithNoColorProp)
           hasTrans = true;
           break;
       end
       
       % these are objs that have a Color prop corresponding to the Alpha
       % prop (e.g. FaceColor / FaceAlpha)
       kAlphaWithColorProp = findobjinternal(k, '-property', alphaProps{idx}, ...
           '-not', alphaProps{idx}, 1, '-property', colorProps{idx}, '-depth', 0);
       % check for color not being none 
       if ~isempty(kAlphaWithColorProp)
          kVals = get(kAlphaWithColorProp, colorProps{idx}); 
          if ~iscell(kVals)
             kVals = {kVals};
          end
          % if the associated <Color> property for these objects 
          % is not set to 'none' then we have transparency in use 
          % (if they're all set to 'none' then no color is displayed and it
          % doesn't matter that the associated <Alpha> property was not 1).
          if ~all(cellfun(@(x,y )strcmp(x,'none'), kVals))
             hasTrans = true; 
             break;  % no need to look further - we've found at least one
          end
       end
   end
   if debugMode 
       if hasTrans 
           fprintf('autoSwitchToPainters: transparency in use\n'); 
       else
           fprintf('autoSwitchToPainters: transparency not in use\n'); 
       end
   end
end
