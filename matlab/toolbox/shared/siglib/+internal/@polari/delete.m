function delete(p)
% Delete instance of POLARPATTERN.

ax = destroyStuffThatGetsRestoredWhenPlotIsCalled(p);
destroyInstanceSpecificStuff(p,ax);
