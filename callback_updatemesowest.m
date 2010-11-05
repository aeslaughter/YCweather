function callback_updatemesowest(hObject,~,varargin)
% CALLBACK_UPDATEMESOWEST

% 1 - Gather GUI data
    GUI = guidata(hObject);

% 2 - GATHER MESOWEST HANDLES
    if isempty(varargin)
        h = findobj('-regexp','Tag','_mesowest','-not','Type','uipanel');
    else
        h = varargin{1};
    end
    disp('Updating MesoWest data, please wait...');

% 3 - UPDATE MESOWEST DATA
    for i = 1:length(h);
        hObject = h(i);
        info = get(hObject,'UserData');
        test = strfind(get(hObject,'Tag'),'_mesowest');
        
        % Test that data is not already available
        if min(info.Time) <= GUI.time(1) && max(info.Time) >= GUI.time(2);
            disp here; return; 
        end
        
        %  Update the data
        if get(hObject,'Value') == 1 && ~isempty(test);
            X = mesowest(info.subfolder,GUI.time,info.season);
            name = [X.display,timelabel(X.Time)];
            set(hObject,'UserData',X,'String',name);
        end
    end
    disp('Complete.');