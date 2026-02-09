function d = gui_plop(obj)
%GUI Properties
margin_left=10;
choices={'Tracking radii for a single loss probability';...
    'Vary the loss probabilities and see GRID results';
    'Start GRID'};

collumnNames={'tls','Tracking Radius','gap-frame','Min. Seg. L.',...
    'min. Length','Threshold'};

%Figure
d = figure('Position',[300 300 520 320],'Name','Plop Object Manipulation');

%Browse forward and backward in plops
btnfwd = uicontrol('Parent',d,...
    'Position',[290 290 20 25],...
    'String','>',...
    'Callback',@change_plop);

btnbwd = uicontrol('Parent',d,...
    'Position',[260 290 20 25],...
    'String','<',...
    'Callback',@change_plop);

%Create Table
w=(300-1)/6;
t=uitable('Parent',d,'Data',[],...
    'ColumnName',collumnNames,...
    'RowName',({}),...
    'ColumnWidth',{w,w,w,w,w,w},...
    'Position',[margin_left, 80, 300, 200],...
    'ColumnEditable',true(1,6),...
    'CellEditCallback',@TableEditCallback);

%Feedback-Text
ui.editFeedbackWin= uicontrol(d,...
    'Position',[2*margin_left+300 80 150 200],...
    'Style','Text',...
    'BackgroundColor',[1 1 1]);

%Dropdown
popup = uicontrol('Parent',d,'Style','popup',...
    'Position',[margin_left 40 300 25],...
    'String',choices);

%Execution
btn = uicontrol('Parent',d,...
    'Position',[margin_left 10 300 25],...
    'String','Execute',...
    'Callback',@execute_callback);


popSubRegion =  uicontrol('Parent',d,...
    'Style','popupMenu',...
    'Position',[2*margin_left+300 40 150 25],...
    'String',{''},...
    'Callback',@RegionMenuCB);

popSubRegionHandling =  uicontrol('Parent',d,...
    'Style','popupMenu',...
    'Position',[2*margin_left+300 10 150 25],...
    'String',{'Assign by first appearance', 'Split tracks at borders', 'Delete tracks touching borders', 'Use only tracks touching borders'},...
    'Callback',@RegionMenuCB);


%-------------------------------

%Fill table based on timelapse conditions in current batch file
updateTable(t,obj(1));
UpdateRegionMenu(popSubRegion,popSubRegionHandling,obj(1));

%Save Data in Figure
d.UserData.cidx=1;
for idx=1:numel(obj)
    obj(idx).txt_out=ui;
end

d.UserData.plops=obj;

end

%--------------------------------------------------------------------------
function execute_callback(source,event)
%Get plop-obj
obj=source.Parent.UserData.plops(source.Parent.UserData.cidx);

%Switch between commands
switch source.Parent.Children(4).Value
    case 1
        prompt = {'Enter Loss Probability'};
        title = 'Predict tracking radii';
        dims = [1 60];
        definput = {'1e-2'};
        cmd = inputdlg(prompt,title,dims,definput);
        
        obj=obj.run(eval(cmd{1}));
        if sum(obj.para.maxdisp>5.9)
            obj.txt_out.editFeedbackWin.String='Iteration Failed';
        end
    case 2
        %Get files
        %             [files,path]=uigetfile('Load multiple batch files:','MultiSelect','on');
        %             if ischar(files)
        %                 files={files};
        %             end
        %             ui.editFeedbackWin=source.Parent.Children(3);
        %             %Load batch and create plop object
        %             for idx=1:numel(files)
        %                 load([path files{idx}],'batch')
        %                 experiment(idx)=plop(batch);
        %                 experiment(idx).txt_out=ui;
        %             end
        %Define ploss
        experiment=source.Parent.UserData.plops;
        prompt = {'Enter Loss Probabilities'};
        title = 'Predict tracking radii';
        dims = [1 60];
        definput = {'linspace(0.001,0.01,2)'};
        cmd = inputdlg(prompt,title,dims,definput);
        p_loss=eval(cmd{1});
        for idx=1:numel(p_loss)
            [res{idx},tr{idx}]=plop.compare_constructs(experiment,1,p_loss(idx));
        end
        styles={'b','r','g','m','k','c','y'};
        f=figure;
        hold on
        for q=1:numel(res)
            h=res{q};
            for w=1:numel(h)
                stem(h(w).k,h(w).S./h(w).k,styles{w},'DisplayName',['ploss= ' num2str(p_loss(q))])
            end
        end
        ax=gca;
        ax.XScale='log';
        plotbrowser (f, 'on')
    case 3
        GRID(obj.data)
    case 4
end

%Save Object
source.Parent.UserData.plops(source.Parent.UserData.cidx)=obj;

%Update Table
updateTable(source.Parent.Children(6),obj);

end

%--------------------------------------------------------------------------
function change_plop(source,evt)
%Get current idx
c_idx=source.Parent.UserData.cidx;
%Get number of plops
max_idx=numel(source.Parent.UserData.plops);
%Change idx
switch source.String(1)
    case '>'
        c_idx=c_idx+1;
        if c_idx>max_idx
            c_idx=1;
        end
    case '<'
        c_idx=c_idx-1;
        if c_idx<1
            c_idx=max_idx;
        end
end
%Save current idx
source.Parent.UserData.cidx=c_idx;
%Update Table
updateTable(source.Parent.Children(6),source.Parent.UserData.plops(c_idx));
end
%--------------------------------------------------------------------------
function updateTable(tab_handle,obj)
%Update Table
T(:,1)=obj.para.tls;
T(:,2)=obj.para.maxdisp;
T(:,3)=obj.para.darkframe;
T(:,4)=obj.para.minSegLength;
T(:,5)=obj.para.shortest_track;
T(:,6)=obj.para.SNR;
tab_handle.Data=T;
end

%--------------------------------------------------------------------------
function TableEditCallback(source,~)
T=source.Parent.Children(6).Data;
obj=source.Parent.UserData.plops(source.Parent.UserData.cidx);
%Get Parameters from table
obj.para.tls=T(:,1)';
obj.para.maxdisp=T(:,2)';
obj.para.darkframe=T(:,3)';
obj.para.minSegLength=T(:,4)';
obj.para.shortest_track=T(:,5)';
obj.para.SNR=T(:,6)';
source.Parent.UserData.plops(source.Parent.UserData.cidx)=obj;
end

function RegionMenuCB(source,~)
obj=source.Parent.UserData.plops(source.Parent.UserData.cidx);

subRoiBorderHandlingHandle = source.Parent.Children(1);
subRoiBorderHandling = subRoiBorderHandlingHandle.String{subRoiBorderHandlingHandle.Value};

regionNumPopupHandle = source.Parent.Children(2);

batch = obj.batch;

if regionNumPopupHandle.Value == 1
    subRegionNum = [];
else
    subRegionNum = regionNumPopupHandle.Value-1;
end

ui.editFeedbackWin = source.Parent.Children(5);


for idx=1:numel(obj)
    obj(idx) = plop(batch, subRegionNum);
    obj(idx).subRoiBorderHandling = subRoiBorderHandling;
    obj(idx).txt_out = ui;
end

source.Parent.UserData.plops(source.Parent.UserData.cidx) = obj;
end


function UpdateRegionMenu(popMenuHandle,popSubRegionHandling,obj)
batch = obj.batch;

nMovies = length(batch);

nSubRegions = 0;
for movieIdx = 1:nMovies
    nSubRegions = max(nSubRegions, batch(movieIdx).results.nSubRegions);
end

if nSubRegions > 0
    popMenuHandle.Visible = 'on';
    popSubRegionHandling.Visible = 'on';
    popList = cell(nSubRegions+2,1);
    popList{1} = 'All regions';
    popList{2} = 'Region 1 (main-region)';
    for roiIdx = 2:nSubRegions+1
        popList{roiIdx+1} = ['Region ',num2str(roiIdx)];
    end
else
    popMenuHandle.Visible = 'off';
    popSubRegionHandling.Visible = 'off';
    popList = {''};
end

popMenuHandle.Value = 1;
popMenuHandle.String = popList;

end
