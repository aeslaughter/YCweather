function callback_openlog(hObject,eventdata)
% CALLBACK_OPENIMAGE opens an image viewer for each station selected;
%__________________________________________________________________________
% USEAGE: callback_openlog(hObject,eventdata)
%
% INPUT: hObject = handle of calling object
%        eventdata = not used, MATLAB requied
%__________________________________________________________________________
try
% Open a viewer window for each station selected
    GUI = guidata(hObject);             % Program guidata

% Determine the selected stations
    use = getselected(hObject);
    if isempty(use); disp('No station selected.'); return; end
    
% Open a viewer for each station 
    for i = 1:length(use);
        log_viewer(hObject,use{i});
    end

catch
    mes = ['An error occured opening daily log (callback_openlog.m), ',...
            'see errorlog.txt.'];
    errorlog(mes);
end
