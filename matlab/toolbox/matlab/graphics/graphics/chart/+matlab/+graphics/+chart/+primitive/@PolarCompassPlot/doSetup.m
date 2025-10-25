function doSetup(obj)

obj.Type = 'compassplot';
addDependencyConsumed(obj, {'colororder_linestyleorder'});
addDependencyConsumed(obj, {'xyzdatalimits'});

% Link the Data properties to the corresponding channels
internalModeStorage = true;
obj.linkDataPropertyToChannel('ThetaData', 'Theta', internalModeStorage);
obj.linkDataPropertyToChannel('RData', 'R', internalModeStorage);

% Disable brushing
setInteractionHint(obj, 'DataBrushing', false);
end