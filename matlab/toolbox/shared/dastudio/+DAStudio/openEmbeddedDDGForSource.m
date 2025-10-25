function comp = openEmbeddedDDGForSource(studio, source, id, title, dockposition, dockoption)
% studio - the simulink studio you want to put this component
% source - the source object for ddg
% id - string id to identify this component - generally picked by user
% title - title for the docked component
% dockposition - one of these 'Top', 'Bottom', 'Left', 'Right'
% dockoption - one if these 'Stacked' or 'Tabbed'

comp = GLUE2.DDGComponent(studio, id, source);
studio.registerComponent(comp);
studio.moveComponentToDock(comp, title, dockposition, dockoption);
