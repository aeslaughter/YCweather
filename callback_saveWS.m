function callback_saveWS(hObject,eventdata,varargin)
% CALLBACK_SAVEWS - saves tge current workspace to a *.mat file
%__________________________________________________________________________
% USAGE: callback_saveWS(hObject,eventdata,varargin)
%
% INPUT: 
%   hObject   = current object handle
%   eventdata = reserved for future use (MATLAB required, but not used)
%   varargin = empty (prompts user to save file)
%            = filename 
%
% OUTPUT: A MATLAB file (*.mat) that saves the settings for later retrival.
%
% PROGRAM OUTLINE:
% 1 - GATHER GUI DATA
% 2 - DETERMINE FILENAME
% 3 - CAPTURE OPEN PLOT INFORMATION
% 4 - UPDATE WINDOW POSITIONS
% 5 - SAVE THE FILE
%__________________________________________________________________________

try
% 1 - GATHER GUI DATA
     gui = findobj('Tag','YCweather');
     GUI = guidata(gui);
     
% 2 - DETERMINE FILENAME - either input or prompted
    if ~isempty(varargin);
        filename = varargin{1};
    else
        loc = GUI.settings.paths.saved;
        [file,pth] = uiputfile([loc,'*.mat'],'Save settings as...');
        if file == 0; return; end
        filename = [pth,file];
    end

% 3 - CAPTURE OPEN PLOT INFORMATION
    GUI.plot = []; % Clears existing plot information
    k = 1;
    figs = unique(GUI.weather);
    for i = 1:length(figs); if ishandle(figs(i));
        GUI.plot(k).data     = get(figs(i),'UserData'); % Figure variables
        GUI.plot(k).position = get(figs(i),'Position'); % Figure location
        k = k + 1;
    end,end

% 4 - UPDATE WINDOW POSITIONS - checks if the window is open, if it is then
%     this position is utilized otherwise use the stored value
    p = {'main','varwindow','preferences'};
    for i = 1:length(p);
        if ishandle(GUI.(p{i}));
            set(GUI.(p{i}),'Units','Normalized');
            GUI.settings.position.(p{i}) = get(GUI.(p{i}),'Position');
    end,end

% 5 - SAVE FILE 
    guidata(GUI.main,GUI);
    save(filename,'-mat','-struct','GUI');
    callback_recent(GUI.main,[],filename);
    
catch
    mes = ['Error saving *.mat file (callback_saveSLA.m), ',...
            'see errorlog.txt.'];
    errorlog(mes);
end
