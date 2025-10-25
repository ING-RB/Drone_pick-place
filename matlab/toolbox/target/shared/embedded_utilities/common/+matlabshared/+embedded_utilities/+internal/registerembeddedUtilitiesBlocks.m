function registerembeddedUtilitiesBlocks(blk)
%REGISTEREMBEDDEDUTILITIESBLOCK

% Copyright 2022 The MathWorks, Inc.

% The blocks can be used for non -coder target based workflows as well. 
% Register using codertarget infra only if functions related to codertarget
% exist

fcnPath = which('codertarget.utils.getModelForBlock');
if isempty(fcnPath)
    return;
end
mdlName = codertarget.utils.getModelForBlock(blk);

if isequal(get_param(mdlName, 'BlockDiagramType'), 'library') || ...
        ~codertarget.target.isCoderTarget(getActiveConfigSet(mdlName)) || ...
        codertarget.resourcemanager.isblockregistered(blk)
    return
else
    codertarget.resourcemanager.registerblock(blk);
end

DataBlockType = get_param(blk, 'MaskType');
% Remove the spaces from the mask to create appropriate name
DataBlockName = extractAfter(DataBlockType,...
        'matlabshared.embedded_utilities.blocks.');
% register or get the coder target parameter for the Data blocks
if codertarget.resourcemanager.isregistered(blk, DataBlockName, 'DataBlocks')
    Data = codertarget.resourcemanager.get(blk, DataBlockName, 'DataBlocks');
else
    codertarget.resourcemanager.register(blk, DataBlockName, 'DataBlocks', []);
    Data = {};
end
codertarget.resourcemanager.increment(blk, DataBlockName, ['num' DataBlockName]);
codertarget.resourcemanager.set(blk, DataBlockName, 'DataBlocks', Data);
end