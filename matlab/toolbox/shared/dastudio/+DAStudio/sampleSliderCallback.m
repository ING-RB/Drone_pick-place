function [success,msg] = sampleSliderCallback(h, hDlg, tag) 
    success = true;
    msg = '';
    hDlg.getWidgetValue(tag)
    disp(['sliderCallback is called from ', tag, '!']);
end