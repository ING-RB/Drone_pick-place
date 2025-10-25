function clfHelper(fig)
webgraphicsrestrictionState = feature('webgraphicsrestriction');
webgraphicsrestrictionCleanup = onCleanup(@() feature('webgraphicsrestriction',webgraphicsrestrictionState));
feature('webgraphicsrestriction',false)
clf(fig);
end