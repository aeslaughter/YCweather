function callback_recent(hObject,~,varargin)
% CALLBACK_RECENT builds and maintains the open recent list in file menu
%__________________________________________________________________________
% USAGE: callback_recent(hObject,eventdata,varargin)
%
% INPUT: hObject = calling objects handle (within Program Control)
%        eventdata = not used, MATLAB required
%        varargin = filename of item being added or excluded when used as
%           handle to the filemenu (i.e. building the menu)
%
% PROGRAM OUTLINE:
% 1 - PREPARE THE GUI
% 2 - BUILD THE LIST OF RECENT FILES
% 3 - REMOVE LIST ITEMS THAT DO NOT EXIST
% 4 - REMOVE OPEN RECENT MENU IF NO FILES EXISTS
% 5 - BUILD CALLBACKS FOR EACH FILE IN LIST
% 6 - APPEND LIST WITH A NEW FILE
% 7 - OVERWRITE CURRENT FILE WITH THE UPDATED LIST
%__________________________________________________________________________

% 1 - PREPARE THE GUI
    h = guihandles(hObject);            % Program Control handles
    delete(get(h.recent,'Children'));   % Remove any existing menus
    set(h.recent,'Visible','on');       % Make list visible

% 2 - GATHER/CREATE LIST OF RECENT FILES
    if ~ispref('YCweather','recent');
        setpref('YCweather','recent',{});
    end
    list = getpref('YCweather','recent');
        
% 3 - REMOVE LIST ITEMS THAT DO NOT EXIST
    idx = zeros(length(list),1);
    for i = 1:length(list);
        if exist(list{i},'file'); idx(i) = 1; end
    end
    list = list(logical(idx));
        
% 4 - REMOVE OPEN RECENT MENU IF NO FILES EXISTS
    if isempty(list); set(h.recent,'Visible','off');end

% 5 - BUILD CALLBACKS FOR EACH FILE IN LIST
if isempty(varargin);
    for i = 1:length(list);
        [~,nm,ext] = fileparts(list{i});
        uimenu(h.recent,'Label',[nm,ext],'Callback',...
            {'callback_readWS',list{i}});
    end

% 6 - APPEND LIST WITH A NEW FILE
else
    list = [varargin{1};list];
end

% 7 - OVERWRITE CURRENT FILE WITH THE UPDATED LIST
    setpref('YCweather','recent',unique(list));
