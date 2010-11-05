function varargout = get_data(h_axes)
% GET_DATA extracts the data from the a variable
%__________________________________________________________________________
% USAGE: varargout = get_data(h_axes)
%
% INPUT: h_axes = handle of panel of primary/secondary axes panel or handle
%                 of a station panel. 
%
% OUPUT: varargout{1} = {X1,Y1,X2,Y2,...,Xn,Yn}
%        varargout{2} = Legend entries
%        varargout{3} = Yaxis label
%        varargout{4} = List of selected buttons
%
% PROGRAM OUTLINE:
% 1 - INTILIZE OUTPUT AND GET MENU HANDLE NAMES
% 2 - SEARCH ALL HANDLES AND STORE DATA STORED IN BUTTONS/LISTBOXES
%__________________________________________________________________________

% 1 - INTILIZE OUTPUT AND GET BUTTON/LISTBOX HANDLES
    C = {}; L = {}; ylab = ''; P = {};
    user = get(h_axes,'UserData');
    h = user.buttons;

% 2 - SEARCH BUTTONS FOR SELECTED ITEMS
     for i = 1:length(h);
        b = get(h(i),'UserData');

        if b.value == 1;
            C    = [C,b.time,b.data];
            ylab = getunit(b.unit,'tex');
            L    = build_legend(L,b.label,b.name);
            
            if isfield(b,'listitem');
                P = [P,{get(h(i),'Tag'),b.listitem}];
            else
                P = [P,get(h(i),'Tag')];
            end
    end,end

% 3 - SET OUTPUT
    varargout{1} = C;       varargout{3} = ylab; 
    varargout{2} = L;       varargout{4} = P;

%--------------------------------------------------------------------------
% SUBFUNCTION: build_legend
function out = build_legend(in,lab,name)
% BUILD_LEGEND constructs a cell array of legend entries and adjusts for
% the listbox inputs.
switch class(lab)
    case 'cell'
        for i = 1:length(lab); add{i} = [lab{i},' (',name,')']; end
        out = [in,add];
    case 'char'
        out = [in,[lab,' (',name,')']];
end
