function y=pasl_model_3P(beta,x,T1b,TI,lambda,labeff,flip_angle)
%Author:Hongli Fan
%Date: Oct 11th,2017
%Purpose: pulsed ASL model

%Input
%	beta       --  parameter of the function, must have 3 elements
%                  the first element is initial value for BAT
%                  the second element is initial value for bolus duration
%                  the third element is initial value for CBF
%	x          --  input vector, time point
%	T1b        --  blood T1
%	lambda     --  tissue/blood partition coefficient
%	labeff     --  labelling efficiency
%	flip_angle --  flip angle
%Output
%-----
%y:for specific parameter, the corresponding value

if size(x,1)==1
    x=x(:);
end

delta_a  = beta(1);
delta_d  = delta_a+beta(2);
f        = beta(3);

T1app=T1b;   % assumption

fa         = flip_angle/180*pi;
R1app_eff  = 1/T1app-log(cos(fa))/TI;
delta_R    = 1/T1b-R1app_eff;


for i  =  1:length(x)
     if x(i) < delta_a
        y(i)  = 0;
    elseif x(i) < delta_d
       delta_M  = -2*f*labeff/6000/lambda/delta_R*exp(-1/T1b*x(i))*(1-exp(delta_R*(x(i)-delta_a)));
       y(i)     = delta_M*sin(fa);
    else
       delta_M  = -2*f*labeff/6000/lambda/delta_R*exp(-1/T1b*delta_d)*(1-exp(delta_R*(x(i)-delta_a)))*exp(-R1app_eff*(x(i)-delta_d)); 
       y(i)     = delta_M*sin(fa);
    end
end
y = y(:);
end