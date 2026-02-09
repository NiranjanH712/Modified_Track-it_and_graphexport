function [data]=gettimelapses(file)
%Translate excel file into data input for GRID

    %Read excel file
    sheet = xlsread(file);
    dim=size(sheet);
    sheet(dim(1)+1,:)=NaN;
    
    %Define Variable
    data={};
    
    %Extract all timelapses
    numberoftimelapses=dim(2)/2;
    for q=1:numberoftimelapses
        %Write q-th timelapse
        p=[];
        f=[];
        w=1;
        %Read all timepoints
        while not(isnan(sheet(w,2*q)))
            p(w)=sheet(w,2*q-1);
            f(w)=sheet(w,2*q);
            w=w+1;
        end
        %Save results
        data{q,1}=p';   %Time-Vector
        data{q,2}=f';   %Survival function
        data{q,3}=p(2)-p(1); %Timelapse condition
    end
    
    %Report
    disp([num2str(numberoftimelapses) ' timelapses with durations ' num2str(cell2mat(data(:,3))') 'seconds  found'])
    
end


