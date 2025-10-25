function packageToolbox(toolboxProjectLocationOrOptions, outputFilename)
%PACKAGETOOLBOX Package a toolbox project 
%   PACKAGETOOLBOX(PROJECTFILE) packages the PROJECTFILE into a MATLAB 
%   toolbox (MLTBX) of the same name.  PROJECTFILE can be either a 
%   relative or absolute path to the toolbox project (PRJ).  
%
%   PACKAGETOOLBOX(PROJECTFILE, OUTPUTFILE) packages the PROJECTFILE into a  
%   MATLAB toolbox file (MLTBX) at the location of the OUTPUTFILE.      
%   PROJECTFILE and OUTPUTFILE can be either a relative or absolute path.
%   If the OUTPUTFILE does not have the extension .mltbx, it will be
%   appended automatically.   
%
%   PACKAGETOOLBOX(OPTS) packages a project into a MATLAB toolbox file
%   using the options specified by the matlab.addons.toolbox.ToolboxOptions
%   object OPTS.
%
%   See also matlab.addons.toolbox.ToolboxOptions,
%   matlab.addons.toolbox.toolboxVersion, matlab.addons.toolbox.installToolbox, 
%   matlab.addons.toolbox.installedToolboxes, matlab.addons.toolbox.uninstallToolbox

%   Copyright 2016-2022 The MathWorks, Inc.
    
    narginchk(1,2);
    
    % Support for ToolboxOptions input
    if isa(toolboxProjectLocationOrOptions, 'matlab.addons.toolbox.ToolboxOptions')
        if nargin == 1
            matlab.addons.toolbox.internal.packageFromOptions(toolboxProjectLocationOrOptions);
        else
            error(message('MATLAB:toolbox_packaging:packaging:NoOutputWithOptions'));
        end
    else

        % Verify the projectFile exists 
        validateattributes(toolboxProjectLocationOrOptions, ...
            {'char','string'},{'scalartext'}, ...
            'matlab.addons.toolbox.packageToolbox','ProjectFile',1)
        toolboxProjectLocation = char(toolboxProjectLocationOrOptions);
        if exist(toolboxProjectLocation, 'file') ~= 2
            error(message('MATLAB:toolbox_packaging:packaging:ToolboxFileNotFound',toolboxProjectLocation));
        end
        
        opts = matlab.addons.toolbox.ToolboxOptions(toolboxProjectLocation);

        % Validate 2nd input
        if nargin > 1
            validateattributes(outputFilename, ...
                {'char','string'},{'scalartext'}, ...
                'matlab.addons.toolbox.packageToolbox','OutputFile',2)
            outputFilename = char(outputFilename);
            validateattributes(outputFilename,{'char'},{'nonempty'}, ...
                'matlab.addons.toolbox.packageToolbox','OutputFile',2)
        
            % If the output file doesn't specify an mltbx extension, we will
            % automatically tack one on
            [fol, justName, ext] = fileparts(outputFilename);
            if ~strcmpi(ext,'.mltbx')
                outputFilename = [outputFilename '.mltbx'];
            end
            
            % Now make sure the folder exists to write the MLTBX
            if (~exist(fol,'dir') && ~isempty(fol))
                mkdir(fol);
            end
            
            %check for invalid characters in the name -- assume folder is fune
            %since previous block already created it
            if isempty(justName) || ~isempty(regexp(justName, '/\[*:?"<>|]', 'once'))
                msg = message('MATLAB:toolbox_packaging:packaging:OutputNameInvalid', outputFilename).getString();
                error(message( ...
                    'MATLAB:toolbox_packaging:packaging:PackagingError', ...
                    toolboxProjectLocation, ...
                    msg))
            end
            
            %use this output file name for the artifact, uses default otherwise
            opts.OutputFile = outputFilename;
        end
    
        matlab.addons.toolbox.internal.packageFromOptions(opts);
        
    end
end
