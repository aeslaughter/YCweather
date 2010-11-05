function callback_search(hObject,eventdata)
% CALLBACK_SEARCH uses the keywords entered in the daily logs text files
% and searchs for a user supplied keyword
%__________________________________________________________________________
% USAGE: callback_search(hObject,eventdata)
%
% INPUT: hObject = current gui object (not used in this program)
%        eventdata = MATLAB reseved value 
%
% OUTPUT: none
%
% PROGRAM OUTLINE:
% 1 - EXTRACT THE GUI INFORMATION AND KEYWORDS
% 2 - LOCATE MATCHING DAILY LOGS
% 3 - BUILD THE LIST OF RESULTS
% FINDMATCH locates matching strings in the daily logs.
% OPENFUNCTION operates when the user selects a result.
%__________________________________________________________________________

% 1 - EXTRACT THE GUI INFORMATION AND KEYWORDS
    GUI = guidata(hObject);
    h   = guihandles(hObject);
    station = getselected(hObject,'all');
    str = get(h.search,'String');
    keywords = textscan(str,'%s','delimiter',',');
    keywords = keywords{1};
    pth = [GUI.settings.paths.database,GUI.season,'\'];

% 2 - LOCATE MATCHING DAILY LOGS
    L = {};
    for i = 1:length(station);
       loc = [pth,station{i},'\DailyLogs\'];
       files = dir([loc,'*.txt']); 
       if ~isempty(files);
           L = findmatch(L,station{i},loc,files,keywords);       
    end,end

% 3 - BUILD THE LIST OF RESULTS
    if isempty(L);
        mes = ['No matches located for: ',str,'.'];
        msgbox(mes,'Search...','warn');
    else
        set(h.results,'String',L,'Callback',{@openfunction},'UserData',...
            L,'Value',1);
    end

%--------------------------------------------------------------------------
function L = findmatch(L,station,loc,files,keywords)
% FINDMATCH locates matching strings in the daily logs.

k = length(L);
for i = 1:length(files);
    fid = fopen([loc,files(i).name]);
    C = textscan(fid,'%s','delimiter',', \n');
    fclose(fid);

    for j = 1:length(keywords)
        idx = strmatch(keywords{j},C{:});
        if ~isempty(idx);
            [p,n] = fileparts(files(i).name);
            L{k+1} = [station,': ',n];
            k = k + 1;
end,end,end

%--------------------------------------------------------------------------
function openfunction(hObject,eventdata)
% OPENFUNCTION operates when the user selects a result.

idx = get(hObject,'value');
user = get(hObject,'UserData');
S = textscan(user{idx},'%s','delimiter',':'); data = S{1};
log_viewer(hObject,data{1},floor(datenum(data{2})));





