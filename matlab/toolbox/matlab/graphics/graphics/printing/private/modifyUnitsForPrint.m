function objUnitsModified = modifyUnitsForPrint(...
    modifyRevertFlag, varargin)
% MODIFYUNITSFORPRINT Modifies or restores a figure's axes and other
% object's units for printing. This undocumented helper function is for
% internal use.
    objUnitsModified = ...
        matlab.graphics.internal.mlprintjob.modifyUnitsForPrint(...
            modifyRevertFlag, varargin{:});
end


