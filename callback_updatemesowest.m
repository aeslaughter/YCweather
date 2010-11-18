function callback_updatemesowest(hObject,~,varargin)
% CALLBACK_UPDATEMESOWEST

% 1 - UPDATE ALL STATIONS IF TEST == TRUE
    test = false;
    if varargin{1} == true;
        varargin = {};
        test = true;
    end

    
% 1 - Gather GUI data
    GUI = guidata(hObject);

% 2 - GATHER MESOWEST HANDLES
    if isempty(varargin);
        h = findobj('-regexp','Tag','_mesowest','-not','Type','uipanel');
    else
        h = varargin{1};
    end

% 3 - UPDATE MESOWEST DATA
    for i = 1:length(h);
        info = get(h(i),'UserData');

        % Test that data is not already available
        if min(info.Time) <= GUI.time(1) && ...
                max(info.Time) >= GUI.time(2) && ...
                ~isempty(info.variables);
            return; 
        end
        
        %  Update the data
        if get(h(i),'Value') == 1 || test;
            X = mesowest(info.subfolder,info.display,GUI.time,info.season);
            name = [X.display,timelabel(X.Time)];
            set(h(i),'UserData',X,'String',name);
        end
    end
