function []=data_viewer(data)
    %Prepare UserData field of figure
    %Create Figure and Save Data
    f=figure;
    ax=gca;
    %Exclusions variable
    excluded=data(:,2);
    for q=1:numel(excluded)
       excluded{q}=excluded{q}*0; 
    end
    ud=struct('data',{data},'excluded',{excluded},'ax',ax);
    f.UserData=ud;
    
    %Context Menu
    menuptr = uicontextmenu;
    ax.UIContextMenu=menuptr;
    m1 = uimenu(ax.UIContextMenu,'Label','Revoke all Exclusions','Callback',@revokerule);
    m2 = uimenu(ax.UIContextMenu,'Label','Restart GRID with this dataset','Callback',@gotoGRID);
    
    %Disable pan 
    disableDefaultInteractivity(ax);
    
    %Plot data
    plotSpec(ud);

end

% -------------------------------------------------------------------------
function plotSpec(ud)
    %get data
    data=ud.data;
    ax1=ud.ax;
    excluded=ud.excluded;
    
    %Axes Properties
    cla(ax1)
    set(ax1,'ButtonDownFcn',@exclude);
    hold(ax1,'on')
    ax1.XScale='log';
    ax1.YScale='log';
    xlabel('time (s)')
    ylabel('survival function')
    
    %Plot
    for m=1:size(data,1)
        %read m-th measured timelapse 
        p=cell2mat(data(m,1));         
        ftarg=cell2mat(data(m,2));
        excl=excluded{m};
        plot(ax1,p,ftarg./ftarg(1),'b.') 
        for w=1:numel(ftarg)
            if (excl(w)==1)
               plot(ax1,p(w),ftarg(w)./ftarg(1),'r+')  
            end
        end
    end
end

% -------------------------------------------------------------------------
function exclude(hObject, eventdata)
    if eventdata.Button==1
        %Get data
        data=hObject.Parent.UserData.data;
        excluded=hObject.Parent.UserData.excluded;

        %Rubberband box
        a=hObject.Parent.UserData.ax;
        point1 = get(a,'CurrentPoint');
        rbbox;
        point2 = get(a,'CurrentPoint');
        pos=[point1(1,1:2);point2(1,1:2)];

       
        %Get points
        for q=1:size(data,1)
            p=cell2mat(data(q,1));         
            ftarg=data{q,2}/data{q,2}(1);
            for w=1:numel(data{q,1})
                x=p(w);
                y=ftarg(w);
                if and(and(x>min(pos(:,1)),x<max(pos(:,1))),and(y>min(pos(:,2)),y<max(pos(:,2))))
                    excluded{q}(w)=1;
                end
            end
        end
        hObject.Parent.UserData.excluded=excluded;
        plotSpec(hObject.Parent.UserData)
    end
end

% -------------------------------------------------------------------------
function revokerule(source,~)
    %Clear exclusions variable
    excluded=source.Parent.Parent.UserData.excluded;
    for q=1:numel(excluded)
       excluded{q}=excluded{q}*0; 
    end
    source.Parent.Parent.UserData.excluded=excluded;
    plotSpec(source.Parent.Parent.UserData)
end

% -------------------------------------------------------------------------
function gotoGRID(source,~)
    %Create new data structure with exclusions deleted
    data=source.Parent.Parent.UserData.data;
    excluded=source.Parent.Parent.UserData.excluded;
    for m=1:size(data,1)
        %read m-th measured timelapse 
        p=cell2mat(data(m,1));         
        ftarg=cell2mat(data(m,2));   
        ftarg(excluded{m}==1)=[];
        p(excluded{m}==1)=[];
        data{m,1}=p;
        data{m,2}=ftarg;
    end
    
    idx=[];
    for m=1:size(data,1)
        if isempty(data{m,1})
            idx=[idx,m];
        end
    end
    data(idx,:)=[];
    
    GRID(data);
end