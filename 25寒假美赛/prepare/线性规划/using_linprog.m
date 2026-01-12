
%使用线性规划的一般函数linprog

f = [-40;-30];
A = [1 1;-1 0;0 -1;240 120];
b = [6 -1 -1 1200]';
Aeq = [];
beq = [];
lb = [0;0];
ub = [+inf,+inf];
[x,val] = linprog(f,A,b,Aeq,beq,lb,ub);
