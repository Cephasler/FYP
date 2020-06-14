hyServer= actxserver('Hysys.Application');
hyCase= hyServer.Activedocument; 
% Call HYSYS solver
hySolver= hyCase.Solver;

% Call the current HYSYS case flowsheet
hyFlowsheet= hyCase.Flowsheet;

% Access the material streams of the HYSYS
hyMatStreams = hyFlowsheet.MaterialStreams;

% Access operations of the HYSYS case
hyOperations = hyFlowsheet.Operations;

% Access energy streams of the HYSYS case
hyEneStreams= hyFlowsheet.EnergyStreams;

% the above codes are must to connect to HYSYS
% You can use the below codes when needed

% hySolver.CanSolve=0; %inactivate HYSYS to set all below data

P = hyMatStreams.Item('Rfeed').PressureValue; %in kPa
T = hyMatStreams.Item('Rfeed').TemperatureValue; %in C
F = hyMatStreams.Item('Rfeed').MolarFlowValue; %in kmol/s
Vap_frac = hyMatStreams.Item('Rfeed').VapourFractionValue;
M = hyMatStreams.Item('Rfeed').MassFlowValue; %in kg/s
gas_flow = hyMatStreams.Item('Rfeed').StdGasFlowValue; %in m3/s

cells = {'B1' 'B2' 'B3' 'B4' 'B5' 'B6' 'B7' 'B8' 'B9' 'B10' 'B11' 'B12' 'B13' 'B14' 'B15' 'B16' 'B17' 'B18' 'B19' 'B20'...
     'B21' 'B22' 'B23' 'B24' 'B25' 'B26' 'B27' 'B28' 'B29' 'B30' 'B31' 'B32' 'B33' 'B34' 'B35' 'B36' 'B37' 'B38'...
     'B39' 'B40' 'B41' 'B42' 'B43' 'B44' 'B45' 'B46' 'B47'};

Rfeed_flow = zeros(1,47);

for i = 1:47
Rfeed_flow(i) = hyOperations.Item('RFeed').Cell(char(cells(i))).CellValue;
end

cat_load = 245; %kg per m3
vol = 2000; %m3
cat_wt = vol*cat_load;
yo = Rfeed_flow;
SV = 0.035;
W = gas_flow*60*1000/SV/1000;
P1 = P*1000;
T1 = T+273.15;

[co_conv,Rco] = LHHW3(yo,W,P1,T1);

alpha = 0.85;
gamma = [0.05 2 2 alpha.*exp(-0.25*[5:12])]; %o/p from n=2 to 12
R(2) = Rco;
R(5) = -(1-alpha)^2*Rco;
for i = 6:16
    R(i) = R(5)*alpha^(i-5)/(1+gamma(i-5));
end

for i = 37:47
    R(i) = R(5)*alpha^(i-36)*gamma(i-36)/(1+gamma(i-36));
end

for i = 17:34
    R(i) = R(5)*alpha^(i-5);
end

R(35) = R(5)*alpha^(31); %c32
R(36) = R(5)*alpha^(35); %c36

Rprod_flow = zeros(1,47);

for i = 5:47
    Rprod_flow(i) = W*R(i) + Rfeed_flow(i);    
end

Rprod_flow(1) = 2*W*R(2) + Rfeed_flow(1);
Rprod_flow(2) = W*R(2) + Rfeed_flow(2);
Rprod_flow(3) = Rfeed_flow(3);
Rprod_flow(4) = -W*R(2) + Rfeed_flow(4);

Fnew = sum(Rprod_flow);
Rprod_frac = Rprod_flow/Fnew;
syn_conv = (sum(Rfeed_flow(1:2))-sum(Rprod_flow(1:2)))/sum(Rfeed_flow(1:2));

hyOperations.Item('Reactor Comp').Cell('E2').CellValue = co_conv; 
hyMatStreams.Item('Rproduct').PressureValue = P; %in kPa
hyMatStreams.Item('Rproduct').TemperatureValue = T; %in C
hyMatStreams.Item('Rproduct').MassFlowValue = M; %in kg/s

for i = 1:47
hyOperations.Item('Reactor Comp').Cell(char(cells(i))).CellValue = Rprod_frac(i); 
% assigning the composition values of the stream by updating the cells in spreadsheet first
end

H_f = [0,-110530,-393510,-241818,-74520,-83820,-104680,-125790,-146760,-166940,-187650,-208750,-228740,-249460,-270430,-290720,-311770,-332440,-353110,-374170,-394450,-415120,-435790,-456460,-477800,-498500,-519200,-540000,-560700,-581400,-602100,-622800,-643500,-664200,-697200,-788500,52510,20230,-500,-21620,-41670,-62890,-81940,-103500,-124700,-144900,-165400];
H_r = zeros(1,43); %stored in J/mol
num = [1:30 32 36 2:12];
for i = 5:47
    H_r(i-4) = H_f(i-4) + num(i-4)*H_f(4) - num(i-4)*H_f(2); %ignore H2 since 0 J/mol heat of form
end

Rprod_change = Rprod_flow(5:47) - Rfeed_flow(5:47);
H_gen = -sum(Rprod_change*1000 .* H_r)/1000; %in kW to be transferred to HYSYS, -ve to cancel off -ve to show heat taken out of reaction

hyEneStreams.Item('Rxn Heat').HeatFlowValue = H_gen;

hySolver.CanSolve=1; %activate HYSYS to run
