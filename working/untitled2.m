clear B C
for x=2:(numel(A.time)-1)
    
    if strcmp(A.status{x},'Start') && strcmp(A.status{x+1},'End')
       B(x)=diff([A.time(x) A.time(x+1)]);
    end
end


C=minutes(B');
C(C==0) = [];
plot(C)