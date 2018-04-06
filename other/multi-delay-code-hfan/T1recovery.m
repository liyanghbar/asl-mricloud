function y = T1recovery(beta,x)
T1 = beta(1);
M0 = beta(2);
y = M0*(1-exp(-x./T1));
end