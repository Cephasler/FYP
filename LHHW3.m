function [x_a,Rco] = LHHW3(yo,W,P,T)

% y here refers to the flowrates (kmol/s) of each component
% t refers to the weight of catalyst past

ao = 8.037e-12;
Ea = 37369;
bo = 1.243e-12;
Eb = -68478;
R = 8.314;
eps = (1.15-3)*yo(2)/sum(yo(1:47));
vo = sum(yo(1:47))*1000*R*T/P; % in m^3/s

p = yo(1:47)/sum(yo(1:47))*P;
pco = p(2); %Pco
ph2 = p(1); %PH2
theta = yo(1)/yo(2);
a = ao*exp(-Ea/R/T);
b = bo*exp(-Eb/R/T);

x_a = 0;
for x = 0.01:0.000001:0.99

num = (pco*vo/1000/R/T)*x;
denom_1 = a*pco*(1-x)*(pco*(theta-2*x))/((1+eps*x)^2);
denom_2 = (1 + (b*pco*(1-x)/(1+eps*x)))^2;

W1 = num/(denom_1/denom_2);

if abs((W1 - W)/W) < 0.01
    x_a = x;
    break
else
    x_a = 0.999;
end

end


denom_1 = a*pco*(1-x_a)*(pco*(theta-2*x_a))/((1+eps*x_a)^2);
denom_2 = (1 + (b*pco*(1-x_a)/(1+eps*x_a)))^2;

Rco = -denom_1/denom_2;

end



