% x=1:750;
% y=zeros(1,750);
% 
% for i=1:750
%     y(i)=mean(distanceBetweenDeal(find(distanceBetweenDeal(:,9)>i),3));
% end

   
plot(x,y)

zero = length(distanceBetweenDeal(:,9));
btw0250 = find(distanceBetweenDeal(:,9)>=0 & distanceBetweenDeal(:,9)<250);
btw250500 = find(distanceBetweenDeal(:,9)>=250 & distanceBetweenDeal(:,9)<500);
btw500750 = find(distanceBetweenDeal(:,9)>=500 & distanceBetweenDeal(:,9)<750);


mean(distanceBetweenDeal(btw0250,3))
mean(distanceBetweenDeal(btw250500,3))
mean(distanceBetweenDeal(btw500750,3))
