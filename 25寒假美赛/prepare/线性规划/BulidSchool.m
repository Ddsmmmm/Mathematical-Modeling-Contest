%用蒙特卡洛法解决建校问题
clear;clc;
n = 1000;  %模拟次数
res_min = +inf;%建立学校的最小个数
res_x = 0;
for i = 1 : n
    x = randi([0,1],6,1);%生成一个6*1的01向量
    if((x(1) + x(2) + x(3) >= 1) && (x(4) + x(6) >= 1) && (x(3) + x(5) >= 1) && (x(2) + x(4) >= 1) &&(x(5) + x(6) >= 1) && (x(1) >= 1) && (x(2) + x(4) + x(6) >= 1))
        sum_x = sum(x);
        if(sum_x < res_min)
            res_x = x;
            res_min = sum_x; 
        end
    end
end
