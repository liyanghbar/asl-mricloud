function result = asl_1compartment_model_T1appEqualT1b (beta,x,alpha,lambda,tau,T1t)
% Purpose: This is based on ASL genetic 1 compartment model.Here, we assign 
%          T1app equals T1b
% Author:Hongli Fan
% Date:  10/20/2017
%Input:
%	beta   --  parameter of the function, must have 2 element
%              the first element is initial value for BAT
%              the second element is initial value for CBF
%	x      --  input vector, must have one column
%	alpha  --  labelling efficiency
%	lambda --  tissue/blood partition coefficient
%Output:
%	result --  corresponding function value, 
%             has the same dimension as x

delta = beta(1);
f = beta(2);
w = x;
T1app=T1t;
for i=1:length(x)
    if w(i)+tau<=delta
        Mb= 0;
    else
        Mb= 2*alpha*f/6000/lambda*T1app*(exp(min(delta-w(i),0)/T1app)-exp((delta-w(i)-tau)/T1app))*exp(-delta/T1t);
    end
    result(i)=Mb;
    result=result(:);
end